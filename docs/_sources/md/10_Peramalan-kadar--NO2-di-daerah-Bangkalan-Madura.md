# Analisis Time Series NO2 Menggunakan OpenEO di Google Colab menggunakan daerah MEDAN 

## Pengenalan & Setup

### Apa itu OpenEO?

**OpenEO** adalah platform cloud-based yang memungkinkan akses data satelit Sentinel dengan mudah. Data yang kita gunakan adalah:

- **Sentinel-5P:** Satelit yang mengukur kualitas udara global
- **NO2 (Nitrogen Dioxide):** Indikator polusi udara
- **Temporal Range:** 2023-05-01 sampai 2026-05-31
- **Location:** Medan, Indonesia (batas koordinat barat, selatan, timur, utara)

### Google Colab sebagai Environment

Google Colab adalah Jupyter Notebook berbasis cloud yang gratis. Keuntungannya:
- ✅ Tidak perlu install Python lokal
- ✅ Akses GPU/TPU gratis (untuk machine learning)
- ✅ Bisa run kode Python langsung di browser
- ✅ Sudah tersedia numpy, pandas, matplotlib

---

## Install Dependencies

Sebelum mulai, kita perlu install beberapa library yang belum tersedia di Colab:

```python
!pip install openeo
!pip install netCDF4
```

**Penjelasan:**
- `!` di depan = menjalankan command terminal (bukan Python)
- `openeo`: Library untuk akses data satelit
- `netCDF4`: Library untuk baca file format NetCDF (format data satelit)

**Output yang diharapkan:**
Akan muncul pesan `Successfully installed` setelah semua library terinstall.

---

## Autentikasi OpenEO

Sebelum bisa download data, kita perlu authenticate dengan server OpenEO:

```python
import openeo

# Koneksi ke OpenEO server di Eropa
connection = openeo.connect("openeo.dataspace.copernicus.eu").authenticate_oidc()
```

**Penjelasan:**

1. **Import openeo:** Load library OpenEO
2. **Connect:** Hubung ke server OpenEO di `openeo.dataspace.copernicus.eu`
3. **Authenticate_oidc():** Login dengan metode OIDC (OpenID Connect)
   - Browser akan membuka tab baru untuk login
   - Klik "Authorize successfully"
   - Kembali ke Colab dan notebook akan lanjut running

**Mengapa perlu authenticate?**
- Server perlu tahu identitas kita (user registration)
- Mencegah abuse/unlimited downloads
- Track penggunaan resource

---

## Load Data Sentinel NO2

Sekarang kita siap download data NO2 dari satelit Sentinel:

```python
aoi = {
    "type": "Polygon",
    "coordinates": [
        [
            [98.60976241891433, 3.631446683286171],
            [98.77068168809933, 3.631446683286171],
            [98.77068168809933, 3.514639930484565],
            [98.60976241891433, 3.514639930484565],
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
```

**Penjelasan Detail:**

### Area of Interest (AOI) - Koordinat Medan
```
aoi = {
    "type": "Polygon",          # Bentuk region = polygon (area)
    "coordinates": [            # Koordinat sudut-sudut area
        [
            [longitude, latitude],  # Sudut barat-laut
            [longitude, latitude],  # Sudut timur-laut
            [longitude, latitude],  # Sudut timur-tenggara
            [longitude, latitude],  # Sudut barat-tenggara
            [longitude, latitude]   # Kembali ke awal (menutup polygon)
        ]
    ]
}
```

Koordinat Medan Indonesia: (98.67°E, 3.57°N)

### Load Collection Parameters:

| Parameter | Nilai | Penjelasan |
|---|---|---|
| `collection` | SENTINEL_5P_L2 | Nama dataset (Sentinel-5P Level 2) |
| `temporal_extent` | ["2023-05-01", "2026-06-01"] | Rentang waktu data yang diunduh |
| `spatial_extent` | Koordinat batas | Area geografis Medan |
| `bands` | ["NO2"] | Hanya ambil band NO2 (tidak semua band) |

---

## Handle Missing Values

Data satelit sering punya celah (missing values) karena awan atau sensor error. Kita perlu mengisi celah ini:

```python
# 1. Baca data yang sudah diunduh
file_path = "NO2Medan.nc"
ds = netCDF4.Dataset(file_path)

# 2. Lihat variabel apa saja dalam file
print("Variabel dalam file:")
print(ds.variables.keys())
# dict_keys(['t', 'x', 'y', 'crs', 'NO2'])

# 3. Ambil data NO2
no2 = ds.variables["NO2"][:, :]

# 4. Ambil waktu (time)
time = ds.variables["t"][:]

# 5. Konversi waktu ke format tanggal jika punya atribut 'units'
try:
    time_units = ds.variables["t"].units
    dates = netCDF4.num2date(time, units=time_units)
except Exception:
    dates = time  # Fallback jika tidak ada units
```

**Penjelasan:**

- **NetCDF format:** Format standar untuk data satelit (mirip HDF5)
  - Punya struktur: variables, dimensions, attributes
  - Bisa simpan multidimensional data (time, lat, lon)

- **Struktur data NO2:**
  - Dimensi: (time=1128, lat=4, lon=3) = 1128 hari × 4 lokasi lat × 3 lokasi lon
  - Jadi ada 1128 pengamatan per lokasi

### Interpolasi Missing Values

```python
import pandas as pd
import numpy as np

# Buat DataFrame untuk mudah dimanipulasi
df = pd.DataFrame({
    "date": dates,
    "NO2": no2  # Array nilai NO2
})

# 1. Ubah format datetime
new_dates = []
for i in range(len(dates)):
    new_date = dates[i].strftime('%Y-%m-%d')
    new_dates.append(new_date)
df["date"] = new_dates

# 2. Ubah format datetime dan sorting
df['date'] = pd.to_datetime(df['date'])
df = df.sort_values('date')

# 3. Cek tanggal yang hilang
start_date = "2023-05-01"
end_date = "2026-05-31"
full_range = pd.date_range(start=start_date, end=end_date, freq='D')

# Lihat tanggal yang hilang
missing_dates = full_range.difference(df['date'])
print(f"Jumlah hari missing: {len(missing_dates)}")
print("Daftar tanggal missing:")
print(missing_dates)
```

**Penjelasan:**

- **Full Range:** Buat daftar semua tanggal dari 2023-05-01 sampai 2026-05-31
- **Difference:** Cari tanggal yang ada di full_range tapi tidak ada di data
- Hasil: Ada 7 hari yang hilang

### Interpolasi Linear

```python
# 4. Reindex agar 7 hari yang hilang tadi muncul di baris (tapi isinya NaN)
df = df.set_index('date').reindex(full_range)
df.index.name = 'date'

# 5. Jalankan interpolasi linear bersarkan indexes waktu untuk mengisi 7 hari yang NaN
df['NO2'] = df['NO2'].interpolate(method='time')

# 6. Gunakan backward fill dan forward fill jika ada NaN di ujung awal atau akhir data
df['NO2'] = df['NO2'].bfill().ffill()

# 7. Simpan hasil akhir yang sudah 100% mulus ke file CSV baru
df.to_csv("no2_timeseries_interpolated.csv")

print("=== PENGECEKAN ULANG SETELAH INTERPOLASI AKHIR ===")
print(f"Jumlah hari missing sekarang: {df['NO2'].isnull().sum()}")
print("Daftar tanggal missing:")
print(df[df['NO2'].isnull()].index.tolist())
print("\nSTATUS DATA: ✅ AMAN 100% Data harian sudah lengkap tanpa ada yang bolong.")
```

**Penjelasan Interpolasi:**

| Metode | Cara Kerja | Kapan Digunakan |
|---|---|---|
| **Linear Interpolate** | Tarik garis lurus antar 2 nilai yang ada, ambil titik di tengahnya | Data ada sebelum & sesudah missing value |
| **Backward Fill (bfill)** | Salin nilai sebelumnya ke belakang | Missing value di awal data |
| **Forward Fill (ffill)** | Salin nilai sebelumnya ke depan | Missing value di akhir data |

**Hasil:**
- Sebelum: 7 hari missing
- Sesudah: 0 hari missing ✅
- Status: Data siap untuk analisis lebih lanjut

---

## Deteksi Outlier dengan IQR

Outlier adalah nilai yang sangat berbeda dari nilai lainnya (kemungkinan error sensor):

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# 1. Baca data final yang sudah mulus tanpa bolongan harian
df = pd.read_csv("no2_timeseries_interpolated.csv")
df['date'] = pd.to_datetime(df['date'])

# 2. Hitung Quartil 1 (Q1), Kuartil 3 (Q3), dan Interquartile Range (IQR)
Q1 = df['NO2'].quantile(0.25)
Q3 = df['NO2'].quantile(0.75)
IQR = Q3 - Q1

# 3. Tentukan Batas Bawah dan Batas Atas Outlier
lower_bound = Q1 - 1.5 * IQR
upper_bound = Q3 + 1.5 * IQR

# 4. Filter data untuk melihat mana saja yang termasuk outlier
outliers = df[(df['NO2'] < lower_bound) | (df['NO2'] > upper_bound)]

print("=== HASIL DETEKSI OUTLIER IQR ===")
print(f"Nilai Q1 (Kuartil 25%) : {Q1:.6f}")
print(f"Nilai Q3 (Kuartil 75%) : {Q3:.6f}")
print(f"Nilai IQR : {IQR:.6f}")
print(f"Batas Bawah : {lower_bound:.6f}")
print(f"Batas Atas : {upper_bound:.6f}")
print(f"Jumlah Outlier : {len(outliers)} hari dari total {len(df)} hari data")
print("-------------------------------------------")

if len(outliers) > 0:
    print("Contoh 5 data outlier terdeteksi:")
    print(outliers[['date', 'NO2']].head())
else:
    print("✅ Mantap! Tidak ditemukan adanya pencilan/outlier pada data Medan kamu.")
```

**Penjelasan IQR Method:**

```
Distribution Data NO2:
|-- -- --]=========|=========]-- -- --|
           Q1       Median    Q3
           |<----IQR---->|
|<- 1.5*IQR ->|           |<- 1.5*IQR ->|
Lower Bound                          Upper Bound

Outlier = nilai < Lower Bound ATAU > Upper Bound
```

### Visualisasi Outlier

```python
# 5. VISUALISASI BOXPLOT untuk membandingkan sebelum vs sesudah
plt.figure(figsize=(10, 4))

plt.subplot(1, 2, 1)
plt.boxplot(df['NO2'])
plt.title('Sebelum Capping (Ada Outlier)')

# 6. PENANGANAN OUTLIER: Metode Capping (Winsorizing)
# Nilainya dipotong tidak boleh kurang dari lower_bound atau lebih dari upper_bound
df['NO2_clean'] = np.clip(df['NO2'], lower_bound, upper_bound)

plt.subplot(1, 2, 2)
plt.boxplot(df['NO2_clean'])
plt.title('Sesudah Capping (Bersih)')

plt.show()
```

**Hasil:**
- Sebelum: Ada outlier (titik di luar box plot)
- Sesudah: Data sudah bersih (tidak ada outlier)

---

## Pembuatan Time Series

Sekarang kita siap membuat time series data yang proper:

```python
import pandas as pd
import numpy as np

# 1. Baca data final yang sudah bersih
df = pd.read_csv("no2_timeseries_interpolated.csv")
df['date'] = pd.to_datetime(df['date'])
df = df.sort_values('date')

# 2. Buat rentang tanggal lengkap (Mei 2023 s/d Mei 2026)
start_date = "2023-05-01"
end_date = "2026-05-31"
full_range = pd.date_range(start=start_date, end=end_date, freq='D')

# 3. Reindex agar 7 tanggal yang hilang tadi muncul di baris (tapi isinya NaN)
df = df.set_index('date').reindex(full_range)
df.index.name = 'date'

# 4. Jalankan Interpolasi linear bersarkan indexes waktu untuk mengisi 7 hari yang NaN
df['NO2'] = df['NO2'].interpolate(method='time')

# 5. Gunakan backward fill dan forward fill jika ada NaN di ujung awal atau akhir data
df['NO2'] = df['NO2'].bfill().ffill()

# 6. Simpan hasil akhir yang sudah 100% mulus ke file CSV baru
df.to_csv("no2_final_clean.csv")

print("✅ Hasil: Data bersih disimpan dengan nama 'no2_final_clean.csv' untuk tahap modeling.")
```

---

## Feature Engineering (Lag Features)

Untuk model supervised learning, kita buat lag features (nilai data hari sebelumnya):

```python
import pandas as pd

# 1. Baca data yang sudah mulus tanpa bolongan harian
df = pd.read_csv("no2_final_clean.csv")
df['date'] = pd.to_datetime(df['date'])

# 2. Buat fitur lag (hari-hari sebelumnya) dari 1 hingga 30 hari ke belakang
df_lag = df.copy()
for i in range(1, 31):
    # Tambahkan kolom target untuk hari ini NO2(t)
    df_lag[f'NO2(t-{i})'] = df_lag['NO2'].shift(i)

# Tambahkan kolom target untuk hari ini
df_lag['NO2(t)'] = df_lag['NO2']

# Hapus baris pertama yang ada NaN akibat dari shift
return df_lag.dropna()

# Membuat 3 variasi data lag untuk bahan eksperimen model KNN
# Sesuai korelasi terbaik Medan 

# Fungsi helper untuk membuat format matrix supervised learning
def create_supervised(data, n_lag=1):
    df_comp = pd.DataFrame(data)
    columns = [df_comp.shift(i) for i in range(n_lag, 0, -1)]
    columns.append(df_comp)
    df_comp = pd.concat(columns, axis=1)
    
    # Membuat nama kolom otomatis seperti NO2(t-3), NO2(t-2), dst.
    cols = [f'NO2(t-{i})' for i in range(n_lag, 0, -1)]
    cols.append('NO2(t)')
    df_comp.columns = cols
    
    # Hapus baris pertama yang ada NaN akibat dari shift
    return df_comp.dropna()

# Membuat 3 variasi data lag untuk bahan eksperimen model KNN
supervised_df3 = create_supervised(df['NO2'].values, n_lag=3)   # 3 hari sebelumnya
supervised_df10 = create_supervised(df['NO2'].values, n_lag=10) # 10 hari sebelumnya
supervised_df30 = create_supervised(df['NO2'].values, n_lag=30) # 30 hari sebelumnya

print("=== HASIL STRUKTUR DATA SUPERVISED (3c) ===")
print(f"Data 3 Hari Sebelumnya (Bentuk Matrik): {supervised_df3.shape}")
print(supervised_df3.head())
print(f"\nData 10 Hari Sebelumnya (Bentuk Matrik): {supervised_df10.shape}")
print(f"Data 30 Hari Sebelumnya (Bentuk Matrik): {supervised_df30.shape}")
print("-------------------------------------------")
print("✅ Langkah 3b dan 3c Selesai! Data siap dimasukkan ke model KNN Regression.")
```

**Penjelasan Lag Features:**

Jika data NO2 adalah:
```
Tanggal:     2023-05-01  2023-05-02  2023-05-03  2023-05-04
NO2:         3.5         3.2         3.8         4.1
```

Dengan `n_lag=3`, struktur supervised menjadi:
```
NO2(t-3)  NO2(t-2)  NO2(t-1)  NO2(t)
   3.5       3.2       3.8       4.1    ← Target adalah NO2 hari ini
```

**Interpretasi:**
- `NO2(t-1)`: Nilai NO2 kemarin (1 hari sebelumnya)
- `NO2(t-2)`: Nilai NO2 2 hari sebelumnya
- `NO2(t-3)`: Nilai NO2 3 hari sebelumnya
- `NO2(t)`: Target yang ingin diprediksi (nilai NO2 hari ini)

---

## Normalisasi Data

Sebelum masuk model ML, semua feature harus di-scale ke range yang sama:

```python
from sklearn.preprocessing import MinMaxScaler
import pandas as pd
import numpy as np

# 1. Baca data bersih terakhir
df = pd.read_csv("no2_timeseries_interpolated.csv")

# =========================================
# 3b. Normalisasi Data (Min-Max Scaler)
# =========================================
scaler = MinMaxScaler()
df['NO2_scaled'] = scaler.fit_transform(df[['NO2']])

print("=== HASIL NORMALISASI DATA (3b) ===")
print(df[['date', 'NO2', 'NO2_scaled']].head())
print("-------------------------------------------\n")

# =========================================
# 3c. Mengubah Data ke Supervised (Lag Features)
# =========================================
# Fungsi helper untuk membuat format matrix supervised learning
def create_supervised(data, n_lag=1):
    df_comp = pd.DataFrame(data)
    columns = [df_comp.shift(i) for i in range(n_lag, 0, -1)]
    columns.append(df_comp)
    df_comp = pd.concat(columns, axis=1)
    
    # Membuat nama kolom otomatis seperti NO2(t-3), NO2(t-2), dst.
    cols = [f'NO2(t-{i})' for i in range(n_lag, 0, -1)]
    cols.append('NO2(t)')
    df_comp.columns = cols
    
    # Hapus baris pertama yang ada NaN akibat dari shift
    return df_comp.dropna()

# Membuat 3 variasi data lag untuk bahan eksperimen model KNN
supervised_df3 = create_supervised(df['NO2_scaled'].values, n_lag=3)
supervised_df10 = create_supervised(df['NO2_scaled'].values, n_lag=10)
supervised_df30 = create_supervised(df['NO2_scaled'].values, n_lag=30)

print("=== HASIL STRUKTUR DATA SUPERVISED (3c) ===")
print(f"Data 3 Hari Sebelumnya (Bentuk Matrik): {supervised_df3.shape}")
print(supervised_df3.head())
```

**Penjelasan Min-Max Scaling:**

```
Formula: X_scaled = (X - min(X)) / (max(X) - min(X))

Contoh:
NO2 original: [2.5, 3.8, 4.2, 5.1, 6.3]
min = 2.5, max = 6.3

NO2_scaled:
- 2.5 → (2.5 - 2.5)/(6.3 - 2.5) = 0 / 3.8 = 0.000
- 3.8 → (3.8 - 2.5)/(6.3 - 2.5) = 1.3 / 3.8 = 0.342
- 5.1 → (5.1 - 2.5)/(6.3 - 2.5) = 2.6 / 3.8 = 0.684
- 6.3 → (6.3 - 2.5)/(6.3 - 2.5) = 3.8 / 3.8 = 1.000

Result: Semua nilai sekarang dalam range [0, 1]
```

---

## Model KNN Regression

Sekarang kita training model KNN untuk prediksi:

```python
from sklearn.model_selection import train_test_split
from sklearn.neighbors import KNeighborsRegressor
from sklearn.metrics import mean_squared_error, r2_score
import pandas as pd
import numpy as np

# 1. Baca data yang sudah bersih terakhir
df = pd.read_csv("no2_timeseries_interpolated.csv")

# 2. Buat fitur lag
def create_supervised(data, n_lag=1):
    df_comp = pd.DataFrame(data)
    columns = [df_comp.shift(i) for i in range(n_lag, 0, -1)]
    columns.append(df_comp)
    df_comp = pd.concat(columns, axis=1)
    cols = [f'NO2(t-{i})' for i in range(n_lag, 0, -1)]
    cols.append('NO2(t)')
    df_comp.columns = cols
    return df_comp.dropna()

# 3. Buat model untuk 3 variasi lag
supervised_df3 = create_supervised(df['NO2'].values, n_lag=3)
supervised_df10 = create_supervised(df['NO2'].values, n_lag=10)
supervised_df30 = create_supervised(df['NO2'].values, n_lag=30)

# 4. Train model untuk masing-masing
models = {}
results = {}

for lag, data in [(3, supervised_df3), (10, supervised_df10), (30, supervised_df30)]:
    # Pisahkan X (features) dan y (target)
    X = data.iloc[:, :-1]  # Semua kolom kecuali yang terakhir
    y = data.iloc[:, -1]   # Kolom terakhir adalah target
    
    # Split 80-20
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )
    
    # Train KNN
    knn = KNeighborsRegressor(n_neighbors=5)
    knn.fit(X_train, y_train)
    
    # Prediksi
    y_pred = knn.predict(X_test)
    
    # Evaluasi
    mse = mean_squared_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    models[lag] = knn
    results[lag] = {'mse': mse, 'r2': r2, 'predictions': y_pred}
    
    print(f"\n=== KNN dengan {lag} Lag ===")
    print(f"MSE: {mse:.6f}")
    print(f"R² Score: {r2:.4f}")
    print(f"Training samples: {len(X_train)}")
    print(f"Testing samples: {len(X_test)}")

print("\n✅ Model KNN sudah siap dan di-train untuk 3 variasi lag!")
print("Pilih lag yang punya R² score tertinggi untuk performa terbaik.")
```

**Penjelasan KNN Regression:**

KNN (K-Nearest Neighbors) adalah algoritma yang bekerja dengan konsep "tetangga":

```
Untuk prediksi NO2(t):
1. Cari 5 nilai NO2(t-3), NO2(t-2), NO2(t-1) terdekat di data training
2. Ambil rata-rata dari target values (NO2(t)) mereka
3. Hasil rata-rata = prediksi NO2(t)

Contoh:
Jika k=5, dan 5 tetangga terdekat punya NO2(t) = [3.2, 3.5, 3.8, 4.1, 3.9]
Maka prediksi = (3.2 + 3.5 + 3.8 + 4.1 + 3.9) / 5 = 3.7
```

---

## Interpretasi Hasil

### R² Score
- **Range:** 0 sampai 1
- **Penjelasan:**
  - R² = 0.9 → Model menjelaskan 90% varian data (EXCELLENT)
  - R² = 0.7 → Model menjelaskan 70% varian data (GOOD)
  - R² = 0.5 → Model menjelaskan 50% varian data (FAIR)
  - R² = 0.0 → Model sama dengan rata-rata (POOR)

### MSE (Mean Squared Error)
- **Semakin kecil, semakin baik**
- Mengukur rata-rata kuadrat error: $MSE = \frac{1}{n}\sum(y_{true} - y_{pred})^2$

---

## Kesimpulan

Analisis time series NO2 Medan melibatkan:

1. ✅ **Data Acquisition:** Download dari OpenEO Sentinel-5P
2. ✅ **Data Cleaning:** Handle missing values dengan interpolasi
3. ✅ **Outlier Detection:** Gunakan IQR method
4. ✅ **Feature Engineering:** Buat lag features
5. ✅ **Normalization:** Min-Max scaling
6. ✅ **Modeling:** Train KNN dengan 3 variasi lag
7. ✅ **Evaluation:** Gunakan R² dan MSE

**Best Practice untuk data time series:**
- Selalu gunakan interpolasi untuk missing values
- Deteksi dan handle outliers
- Buat lag features untuk supervised learning
- Normalisasi sebelum modeling
- Pilih model berdasarkan R² score tertinggi

---

**Last Updated:** Juni 2026  
**Data Source:** Sentinel-5P OpenEO  
**Location:** Medan, Indonesia  
**Time Range:** 2023-05-01 sampai 2026-05-31