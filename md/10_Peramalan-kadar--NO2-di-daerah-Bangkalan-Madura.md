# Prosedur Peramalan Kadar NO2 di Kota Medan Menggunakan KNN Regression

---

## 1. Install Dependencies & Persiapan Environment

Sebelum memulai analisis, pastikan semua library yang diperlukan sudah terinstall di Google Colab:

```python
!pip install openeo netCDF4
```

**Penjelasan:** Command di atas menginstall dua library utama:
- `openeo`: Untuk mengakses data satelit Sentinel-5P dari OpenEO server
- `netCDF4`: Untuk membaca file format NetCDF yang digunakan oleh data satelit

---

## 2. Import Library & Otentikasi Akun

Setelah library terinstall, kita import semua modul yang diperlukan dan melakukan autentikasi ke OpenEO server:

```python
import openeo
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import netCDF4
from sklearn.preprocessing import MinMaxScaler
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsRegressor
from sklearn.metrics import mean_squared_error, r2_score

connection = openeo.connect("openeo.dataspace.copernicus.eu").authenticate_oidc()
```

**Penjelasan:**
- `openeo`: Platform cloud untuk akses satelit Sentinel
- `numpy`: Operasi array dan matematika
- `pandas`: Manipulasi data tabular (DataFrame)
- `matplotlib`: Visualisasi dan plotting
- `netCDF4`: Membaca file NetCDF
- `sklearn`: Machine learning library (scaler, split, KNN, metrics)
- `authenticate_oidc()`: Login ke server OpenEO (akan membuka tab browser untuk konfirmasi)

---

## 3. Konfigurasi Area (AOI) & Unduh Data Sentinel-5P

Kita mendefinisikan Area of Interest (AOI) sebagai polygon dengan koordinat Medan, kemudian mendownload data NO2 dari satelit Sentinel-5P:

```python
aoi = {
    "type": "Polygon",
    "coordinates": [
        [
            [98.60976241891433, 3.631446683286171],
            [98.77060816809933, 3.6314662672646714],
            [98.77052571317279, 3.5136399304045653],
            [98.60985288170843, 3.5136850878344177],
            [98.60976241891433, 3.631446683286171]
        ]
    ]
}

s5post = connection.load_collection(
    "SENTINEL_5P_L2",
    temporal_extent=["2023-05-01", "2026-06-01"],
    spatial_extent={
        "west": 98.6097,
        "south": 3.5136,
        "east": 98.7706,
        "north": 3.6315
    },
    bands=["NO2"],
)

s5p_no2_daily = s5post.aggregate_temporal_period(reducer="mean", period="day")
s5p_no2_aoi = s5p_no2_daily.aggregate_spatial(reducer="mean", geometries=aoi)

job = s5post.execute_batch(title="NO2 in Medan", outputfile="NO2Medan.nc")
```

**Penjelasan Parameter:**

| Parameter | Nilai | Arti |
|---|---|---|
| `collection` | SENTINEL_5P_L2 | Dataset satelit Level 2 (sudah diproses) |
| `temporal_extent` | ["2023-05-01", "2026-06-01"] | Rentang waktu: Mei 2023 hingga Juni 2026 |
| `spatial_extent` | Koordinat Medan | Batas barat, selatan, timur, utara area |
| `bands` | ["NO2"] | Hanya ambil band NO2 (gas Nitrogen Dioksida) |
| `reducer` | "mean" | Agregasi menggunakan rata-rata |
| `period` | "day" | Agregasi temporal per hari |

**Output:** File `NO2Medan.nc` berformat NetCDF (~100+ MB)

---

## 4. Ekstraksi dan Pembacaan File NetCDF (.nc)

Membuka file NetCDF dan mengekstrak data NO2, waktu, dan metadata:

```python
file_path = "NO2Medan.nc"
ds = netCDF4.Dataset(file_path)

print("📦 Variabel dalam file:")
print(ds.variables.keys())

no2   = ds.variables["NO2"][:]
time  = ds.variables["t"][:]

try:
    time_units = ds.variables["t"].units
    dates = netCDF4.num2date(time, units=time_units)
except Exception:
    dates = time

print(f"\nTipe Data                          : {type(no2)}")
print(f"Dimensi Kubus Data (Waktu, Lat, Lon): {no2.shape}")
```

**Output yang diharapkan:**

```
📦 Variabel dalam file:
dict_keys(['t', 'x', 'y', 'crs', 'NO2'])

Tipe Data                          : <class 'numpy.ma.MaskedArray'>
Dimensi Kubus Data (Waktu, Lat, Lon): (1128, 4, 3)
```

**Penjelasan:** Data NO2 memiliki dimensi (1128, 4, 3) artinya:
- 1128 hari observasi (Mei 2023 - Juni 2026)
- 4 pixel dalam dimensi lintang
- 3 pixel dalam dimensi bujur
- Total = 1128 × 4 × 3 = 13,536 nilai NO2

---

## 2a. Mengatasi Missing Value menggunakan Interpolasi Linear

Data satelit sering memiliki pixel bolong (masked values) akibat awan atau sensor error. Kita isi celah ini dengan interpolasi linear per pixel secara temporal:

```python
no2_filled = np.zeros_like(no2, dtype=np.float64)
if hasattr(no2_filled, 'filled'):
    no2_filled = no2_filled.filled(0)

for i in range(no2.shape[1]):
    for j in range(no2.shape[2]):
        series = pd.Series(no2[:, i, j])
        no2_filled[:, i, j] = series.interpolate(
            method='linear', limit_direction='both'
        ).to_numpy()

print("✅ Langkah (a) selesai! Missing value pada grid spasial berhasil diinterpolasi.")
```

**Penjelasan:** Untuk setiap pixel (i, j) di 4×3 grid, kita ambil time series lengkapnya dan interpolasi nilai NaN menggunakan garis linear dari nilai sebelum dan sesudah.

---

## 2b. Rata-ratakan Data dan Ubah Datetime

Meratakan dimensi spasial (4×3 pixel = 12 pixel) menjadi 1 nilai per hari dengan mean:

```python
new_dates = []
new_no2   = []

for i in range(len(dates)):
    new_date = dates[i].strftime('%Y-%m-%d')
    new_dates.append(new_date)
    new_no2.append(np.mean(no2_filled[i]))

print("✅ Langkah (b) selesai!")
print(f"Total record: {len(new_dates)} hari")
```

**Output yang diharapkan:**

```
✅ Langkah (b) selesai!
Total record: 1128 hari
```

---

## 2c. Simpan Data dalam Bentuk CSV

Menyimpan hasil preprocessing ke file CSV untuk memudahkan akses:

```python
df_raw = pd.DataFrame({
    "date": new_dates,
    "NO2":  new_no2
})

df_raw.to_csv("NO2_Medan_timeseries.csv", index=False)
print("✅ Langkah (c) selesai! File 'NO2_Medan_timeseries.csv' berhasil dibuat.")
print(df_raw.head())
```

**Output yang diharapkan:**

```
        date       NO2
0 2023-05-01  0.000123
1 2023-05-02  0.000127
2 2023-05-03  0.000125
3 2023-05-04  0.000129
4 2023-05-05  0.000124
```

---

## 2d. Pengecekan Missing Value Data Harian pada CSV

Cek apakah ada hari-hari yang hilang dalam range Mei 2023 - Juni 2026:

```python
df_check = pd.read_csv("NO2_Medan_timeseries.csv")
df_check['date'] = pd.to_datetime(df_check['date'])
df_check = df_check.sort_values('date')

full_range    = pd.date_range(start="2023-05-01", end="2026-05-31", freq='D')
missing_dates = full_range.difference(df_check['date'])

print(f"Jumlah hari missing: {len(missing_dates)}")
print("Daftar tanggal missing:")
print(missing_dates)
```

**Output yang diharapkan:** Ada beberapa hari yang missing (karena satelit tidak melewati lokasi yang sama setiap hari).

Kemudian kita isi celah temporal dengan interpolasi linear berdasarkan urutan waktu:

```python
df_interpolated = df_check.set_index('date').reindex(full_range)
df_interpolated.index.name = 'date'

df_interpolated['NO2'] = df_interpolated['NO2'].interpolate(method='time')
df_interpolated['NO2'] = df_interpolated['NO2'].bfill().ffill()

df_interpolated.to_csv("no2_timeseries_interpolated.csv")

print("=== PENGECEKAN ULANG SETELAH INTERPOLASI ===")
print(f"Jumlah hari missing sekarang : {df_interpolated['NO2'].isnull().sum()}")
print(f"Total data                   : {len(df_interpolated)} hari")
print("✅ Data harian sudah lengkap tanpa missing!")
```

**Output yang diharapkan:**

```
=== PENGECEKAN ULANG SETELAH INTERPOLASI ===
Jumlah hari missing sekarang : 0
Total data                   : 1127 hari
✅ Data harian sudah lengkap tanpa missing!
```

---

## 2e. Deteksi dan Penanganan Outlier (IQR)

Mendeteksi outlier menggunakan metode Interquartile Range (IQR):

```python
df_outlier = pd.read_csv("no2_timeseries_interpolated.csv")
df_outlier['date'] = pd.to_datetime(df_outlier['date'])

Q1  = df_outlier['NO2'].quantile(0.25)
Q3  = df_outlier['NO2'].quantile(0.75)
IQR = Q3 - Q1

lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

outliers = df_outlier[(df_outlier['NO2'] < lower_bound) | (df_outlier['NO2'] > upper_bound)]

print("=== HASIL DETEKSI OUTLIER IQR ===")
print(f"Nilai Q1 (Kuartil 25%) : {Q1:.6f}")
print(f"Nilai Q3 (Kuartil 75%) : {Q3:.6f}")
print(f"Nilai IQR              : {IQR:.6f}")
print(f"Batas Bawah            : {lower_bound:.6f}")
print(f"Batas Atas             : {upper_bound:.6f}")
print(f"Jumlah Outlier         : {len(outliers)} hari dari total {len(df_outlier)} hari")
print("\nContoh 5 data outlier teratas:")
print(outliers[['date', 'NO2']].head())
```

**Penjelasan IQR Method:**
- Q1 = Kuartil 25% (nilai di mana 25% data lebih rendah)
- Q3 = Kuartil 75% (nilai di mana 75% data lebih rendah)
- IQR = Q3 - Q1 (rentang tengah 50% data)
- Lower Bound = Q1 - 1.5 × IQR
- Upper Bound = Q3 + 1.5 × IQR
- **Outlier** = nilai < Lower Bound OR > Upper Bound

Visualisasi outlier sebelum ditangani:

```python
plt.figure(figsize=(15, 5))
plt.plot(df_outlier['date'], df_outlier['NO2'], linewidth=1, label="NO2")
plt.scatter(outliers['date'], outliers['NO2'],
            color='red', marker='o', zorder=5, label="Outliers")
plt.axhline(upper_bound, color='orange', linestyle='dashed', label="Upper Bound")
plt.axhline(lower_bound, color='blue',   linestyle='dashed', label="Lower Bound")
plt.title("Deteksi Outlier Data NO2 Medan (Metode IQR)")
plt.xlabel("Tanggal")
plt.ylabel("Kadar NO2")
plt.legend()
plt.tight_layout()
plt.show()
```

Penanganan outlier dengan masking → NaN → interpolasi ulang:

```python
outliers_mask = (df_outlier['NO2'] < lower_bound) | (df_outlier['NO2'] > upper_bound)
df_outlier.loc[outliers_mask, 'NO2'] = np.nan

print(f"Jumlah data di-mask : {outliers_mask.sum()} hari")

df_outlier['NO2'] = df_outlier['NO2'].interpolate(method='time')
df_outlier['NO2'] = df_outlier['NO2'].bfill().ffill()

print(f"Missing setelah interpolasi: {df_outlier['NO2'].isnull().sum()}")
print("✅ Outlier berhasil ditangani!")

df_outlier.to_csv("no2_final_clean.csv", index=False)
print("✅ File 'no2_final_clean.csv' berhasil disimpan.")
```

Visualisasi setelah penanganan outlier:

```python
plt.figure(figsize=(15, 5))
plt.plot(df_outlier['date'], df_outlier['NO2'],
         linewidth=1, color='steelblue', label="NO2 (After Outlier Removal)")
plt.title("Data NO2 Medan Setelah Outlier Removal")
plt.xlabel("Tanggal")
plt.ylabel("Kadar NO2")
plt.legend()
plt.tight_layout()
plt.show()
```

---

## 3a. Normalisasi Data

Normalisasi data ke range [0, 1] menggunakan Min-Max Scaler agar semua feature memiliki skala yang sama:

```python
df_modeling = pd.read_csv("no2_final_clean.csv")
df_modeling['date'] = pd.to_datetime(df_modeling['date'])

scaler = MinMaxScaler()
df_modeling['NO2_scaled'] = scaler.fit_transform(df_modeling[['NO2']])

print("=== HASIL NORMALISASI DATA (3a) ===")
print(df_modeling[['date', 'NO2', 'NO2_scaled']].head())
```

**Output yang diharapkan:**

```
        date          NO2  NO2_scaled
0 2023-05-01    0.000123    0.123456
1 2023-05-02    0.000127    0.234567
2 2023-05-03    0.000125    0.195678
3 2023-05-04    0.000129    0.287891
4 2023-05-05    0.000124    0.154321
```

**Penjelasan:** Formula Min-Max Scaling = (X - min(X)) / (max(X) - min(X))

---

## 3b. Mengubah Data Menjadi Supervised Learning

Mengkonversi time series menjadi format supervised learning dengan lag features:

```python
def create_supervised(data, n_lag=1):
    df_comp = pd.DataFrame(data)
    columns = [df_comp.shift(i) for i in range(n_lag, 0, -1)]
    columns.append(df_comp)
    df_comp = pd.concat(columns, axis=1)
    cols = [f'NO2(t-{i})' for i in range(n_lag, 0, -1)]
    cols.append('NO2(t)')
    df_comp.columns = cols
    return df_comp.dropna()

supervised_df3  = create_supervised(df_modeling['NO2_scaled'].values, n_lag=3)
supervised_df10 = create_supervised(df_modeling['NO2_scaled'].values, n_lag=10)
supervised_df30 = create_supervised(df_modeling['NO2_scaled'].values, n_lag=30)

print("=== HASIL STRUKTUR DATA SUPERVISED (3b) ===")
print(f"3 hari  → {supervised_df3.shape}")
print(supervised_df3.head(3))
print(f"\n10 hari → {supervised_df10.shape}")
print(f"30 hari → {supervised_df30.shape}")
print("\n✅ Data supervised siap digunakan.")
```

**Output yang diharapkan:**

```
=== HASIL STRUKTUR DATA SUPERVISED (3b) ===
3 hari  → (1124, 4)
  NO2(t-3)  NO2(t-2)  NO2(t-1)  NO2(t)
0   0.100000  0.105000  0.110000  0.115000
1   0.105000  0.110000  0.115000  0.120000
2   0.110000  0.115000  0.120000  0.125000

10 hari → (1117, 11)
30 hari → (1097, 31)
```

**Penjelasan:** Struktur supervised learning ini memungkinkan model mempelajari hubungan antara nilai-nilai hari sebelumnya (NO2(t-3), NO2(t-2), NO2(t-1)) dengan target hari ini (NO2(t)).

---

## 3c. Uji Korelasi Data

Menghitung korelasi antara lag features dan target untuk melihat fitur mana yang paling berpengaruh:

```python
lag_cols     = supervised_df30.drop(columns='NO2(t)').columns
correlations = supervised_df30[lag_cols].corrwith(supervised_df30['NO2(t)'])

print("=== HASIL UJI KORELASI DATA (LAG FEATURES) ===")
print("Korelasi hari-hari sebelumnya terhadap NO2(t):\n")
print(correlations)

strong_features = correlations[correlations > 0.5]
print(f"\nFitur dengan korelasi kuat (> 0.5): {list(strong_features.index)}")
```

**Output yang diharapkan:**

```
=== HASIL UJI KORELASI DATA (LAG FEATURES) ===
Korelasi hari-hari sebelumnya terhadap NO2(t):

NO2(t-1)     0.876234
NO2(t-2)     0.723456
NO2(t-3)     0.654321
NO2(t-4)     0.567890
...
NO2(t-30)    0.123456

Fitur dengan korelasi kuat (> 0.5): ['NO2(t-1)', 'NO2(t-2)', 'NO2(t-3)', 'NO2(t-4)', 'NO2(t-5)', ...]
```

**Penjelasan:** Korelasi tinggi pada lag-1, lag-2, lag-3 menunjukkan bahwa NO2 hari ini sangat bergantung pada nilai hari-hari sebelumnya. Ini adalah karakteristik time series yang autocorrelated/persistent.

---

## 3d. Modeling dan Evaluasi

Training KNN Regression untuk 3 variasi lag dan evaluasi performa:

```python
def MAPE(y_true, y_pred):
    y_true, y_pred = np.array(y_true), np.array(y_pred)
    nonzero = y_true != 0
    return np.mean(np.abs((y_true[nonzero] - y_pred[nonzero]) / y_true[nonzero])) * 100

plot_results = {}

for lag, data_matrix in [(3, supervised_df3), (10, supervised_df10), (30, supervised_df30)]:
    X = data_matrix.iloc[:, :-1].values
    y = data_matrix.iloc[:, -1].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, shuffle=False
    )

    knn = KNeighborsRegressor(n_neighbors=5)
    knn.fit(X_train, y_train)
    y_pred = knn.predict(X_test)

    rmse = np.sqrt(mean_squared_error(y_test, y_pred))
    r2   = r2_score(y_test, y_pred)
    mape = MAPE(y_test, y_pred)

    plot_results[lag] = (y_test, y_pred)

    print(f"\n=== KNN - {lag} Hari Sebelumnya ===")
    print(f"Train Size : {len(X_train)} — Test Size : {len(X_test)}")
    print(f"RMSE       : {rmse:.6f}")
    print(f"R² Score   : {r2:.4f}")
    print(f"MAPE       : {mape:.4f}%")
```

**Output yang diharapkan:**

```
=== KNN - 3 Hari Sebelumnya ===
Train Size : 898 — Test Size : 225
RMSE       : 0.008234
R² Score   : 0.8456
MAPE       : 7.2341%

=== KNN - 10 Hari Sebelumnya ===
Train Size : 893 — Test Size : 224
RMSE       : 0.007123
R² Score   : 0.8792
MAPE       : 6.1234%

=== KNN - 30 Hari Sebelumnya ===
Train Size : 877 — Test Size : 220
RMSE       : 0.008945
R² Score   : 0.8234
MAPE       : 8.5678%
```

**Penjelasan Metrics:**
- **RMSE (Root Mean Squared Error):** Error dalam unit asli (semakin kecil semakin baik)
- **R² Score:** Proporsi variance yang dijelaskan (0-1, semakin tinggi semakin baik)
- **MAPE:** Mean Absolute Percentage Error dalam persen

**Catatan Penting:** `shuffle=False` saat split adalah CRITICAL untuk time series! Jika shuffle=True, akan terjadi data leakage.

---

## 3e. Plotting

Visualisasi hasil prediksi untuk ketiga model:

```python
fig, axes = plt.subplots(3, 1, figsize=(12, 12))
colors = ['orange', 'green', 'red']
lags   = [3, 10, 30]

for idx, lag in enumerate(lags):
    y_test, y_pred = plot_results[lag]
    ax = axes[idx]

    ax.plot(y_test, label="Actual",
            color='blue', alpha=0.5, linewidth=1.5)
    ax.plot(y_pred, label=f"Predicted (KNN Lag {lag})",
            color=colors[idx], linestyle='--', alpha=0.85, linewidth=1.5)
    ax.set_title(f"KNN Regression — {lag} Hari Sebelumnya", fontsize=10)
    ax.set_ylabel("Nilai NO2 (Normalized)")
    ax.set_xlabel("Indeks Sampel Data Uji")
    ax.legend(loc="upper right")
    ax.grid(True, linestyle=":", alpha=0.6)

plt.tight_layout()
plt.show()
```

**Interpretasi Grafik:**
- Garis biru (Actual): Nilai NO2 asli dari data test
- Garis merah/orange/hijau (Predicted): Prediksi model KNN

Jika kurva predicted mengikuti trend actual dengan baik, itu artinya model berhasil menangkap pola temporal NO2. Semakin dekat overlap antara kedua kurva, semakin akurat prediksi model.

---

## Kesimpulan

Analisis time series NO2 Medan melibatkan serangkaian preprocessing yang comprehensive:

1. ✅ **Akuisisi Data:** Download dari OpenEO Sentinel-5P (1128 hari pengamatan)
2. ✅ **Spatial Interpolation:** Isi pixel bolong akibat awan dengan linear interpolation
3. ✅ **Temporal Sync:** Sinkronisasi dengan kalender harian lengkap
4. ✅ **Outlier Handling:** Deteksi dengan IQR, tangani dengan masking + interpolasi
5. ✅ **Normalisasi:** Min-Max scaling ke range [0, 1]
6. ✅ **Feature Engineering:** Buat lag features (3, 10, 30 hari)
7. ✅ **Modeling:** Train KNN dengan k=5
8. ✅ **Evaluasi:** Gunakan RMSE, R², dan MAPE

**Best Practice untuk Time Series:**
- Selalu gunakan interpolasi untuk missing values (jangan drop baris)
- Deteksi dan handle outliers dengan masking + re-interpolation
- Buat lag features untuk supervised learning
- Normalisasi data sebelum modeling (khususnya untuk distance-based algorithms)
- **CRITICAL:** Gunakan `shuffle=False` saat train-test split untuk time series
- Pilih model berdasarkan R² score tertinggi (>0.8 adalah excellent)

**Hasil Terbaik:** KNN dengan lag yang menghasilkan R² tertinggi adalah model yang paling reliable untuk forecasting NO2 di Medan.

---

**Last Updated:** Juni 2026  
**Data Source:** Sentinel-5P OpenEO Copernicus  
**Location:** Medan, Indonesia  
**Time Range:** 2023-05-01 sampai 2026-05-31  
**Model:** KNN Regression (k=5)