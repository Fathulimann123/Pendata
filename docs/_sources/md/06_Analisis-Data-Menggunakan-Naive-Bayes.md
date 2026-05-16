# Analisis Data Menggunakan  Naive Bayes

Dataset ini merupakan kumpulan data komprehensif yang mencakup informasi demografis, akademik, hingga riwayat kesehatan personal untuk memprediksi risiko depresi pada mahasiswa.

### Atribut yang Digunakan

| No | Atribut | Tipe Data | Penjelasan Singkat |
| :--- | :--- | :--- | :--- |
| 1 | **Age** | Numerik | Usia responden/mahasiswa saat ini. |
| 2 | **Gender** | Kategorikal | Jenis kelamin responden. |
| 3 | **City** | Kategorikal | Kota asal atau domisili mahasiswa. |
| 4 | **Degree** | Kategorikal | Jenjang pendidikan atau program studi yang ditempuh. |
| 5 | **Academic Pressure** | Numerik | Skala tekanan dari beban perkuliahan. |
| 6 | **Work Pressure** | Numerik | Skala tekanan dari pekerjaan atau tanggung jawab luar. |
| 7 | **CGPA** | Numerik | Nilai Indeks Prestasi Kumulatif (IPK). |
| 8 | **Study Satisfaction** | Numerik | Tingkat kepuasan terhadap proses pembelajaran. |
| 9 | **Job Satisfaction** | Numerik | Tingkat kepuasan terhadap pekerjaan/tugas. |
| 10 | **Work/Study Hours** | Numerik | Durasi waktu aktivitas harian (belajar/bekerja). |
| 11 | **Family History** | Kategorikal | Riwayat gangguan kesehatan mental dalam keluarga. |
| 12 | **Dietary Habits** | Kategorikal | Pola atau kebiasaan makan sehari-hari. |
| 13 | **Suicidal Thoughts** | Kategorikal | Riwayat adanya pikiran untuk menyakiti diri sendiri. |
| 14 | **Depression** | Kategorikal | **Target Label**: Status depresi (Depresi / Tidak). |

### implementasi Knime
![Statistik Orange](../img/data-understanding/gaussian.png)

## Analisis Workflow KNIME: Optimasi Gaussian Naive Bayes

Workflow ini dirancang untuk meningkatkan performa algoritma Gaussian Naive Bayes dengan fokus pada pembersihan data dan pemenuhan asumsi independensi fitur.

### Daftar Node dan Fungsinya

#### Tabel Node KNIME: Optimasi Gaussian Naive Bayes

| Nama Node        | Penjelasan Singkat |
|------------------|--------------------|
| CSV Reader       | Membaca dataset mahasiswa. |
| Table Partitioner| Membagi data jadi Training & Testing. |
| Normalizer       | Menyamakan skala variabel (mean = 0, std = 1). |
| Numeric Outliers | Mengatasi nilai ekstrem agar tidak merusak model. |
| Missing Value    | Mengisi data kosong supaya tidak error. |
| PCA Compute      | Mengubah fitur berkorelasi jadi komponen independen. |
| PCA Apply        | Menerapkan hasil PCA ke data uji. |
| Python Script    | Menjalankan Gaussian Naive Bayes dengan scikit-learn. |
| Scorer           | Menghitung akurasi, presisi, dan recall. |

Implementasi Kode Python
Berikut adalah script yang digunakan di dalam node **Python Script**. Kode ini menggunakan standar library `scikit-learn` dengan penanganan tipe data otomatis.

```python
import knime.scripting.io as knio
import pandas as pd
from sklearn.naive_bayes import GaussianNB
from sklearn.preprocessing import LabelEncoder

# 1. Mengambil data dari input port KNIME
df = knio.input_tables[0].to_pandas()

# 2. Inisialisasi LabelEncoder untuk data kategorikal
le = LabelEncoder()

# 3. Preprocessing: Konversi kolom non-numerik dan proteksi tipe data
# Fitur (X) adalah semua kolom kecuali target 'Depression' dan 'id'
cols_to_drop = ['id', 'Depression']
if 'Prediction_Gaussian' in df.columns:
    cols_to_drop.append('Prediction_Gaussian')

for col in df.columns:
    if col not in cols_to_drop:
        # Ubah teks menjadi angka (Encoding)
        if df[col].dtype == 'object':
            df[col] = le.fit_transform(df[col].astype(str))
        
        # Pastikan data bertipe numerik (float) untuk rumus Gaussian
        df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)

# 4. Pemisahan Fitur dan Target
X = df.drop(columns=cols_to_drop)
y = df['Depression'].astype(int)

# 5. Training Model Gaussian Naive Bayes
model = GaussianNB()
model.fit(X, y)

# 6. Melakukan Prediksi
df['Prediction_Gaussian'] = model.predict(X)

# 7. Mengirimkan kembali tabel hasil ke KNIME
knio.output_tables[0] = knio.Table.from_pandas(df)
```

### Penjelasan Teknis Python Script

Algoritma yang digunakan dalam penelitian ini adalah **Gaussian Naive Bayes** yang diimplementasikan melalui pustaka **Scikit-Learn**. Berikut adalah breakdown logikanya:

1. **Integrasi Library**: Menggunakan `knio` untuk menjembatani aliran data antara KNIME dan Python, serta `pandas` untuk manipulasi tabel data.
2. **Encoding Kategori**: Karena algoritma Naive Bayes berbasis perhitungan probabilitas matematis, semua fitur kategorikal (teks) dikonversi menjadi numerik menggunakan `LabelEncoder`.
3. **Data Type Enforcement**: Dilakukan pembersihan tipe data menggunakan `pd.to_numeric` untuk memastikan tidak ada konflik tipe data (string vs integer) yang dapat memicu error saat perhitungan probabilitas.
4. **Model Training & Prediction**: 
   - Fitur (X) dipisahkan dari Target (y/Depression).
   - Model dilatih menggunakan fungsi `.fit()`.
   - Prediksi dihasilkan melalui fungsi `.predict()` dan dimasukkan ke dalam kolom baru bernama `Prediction_Gaussian`.


### 3 Keunggulan Alur Optimasi

1. PCA membuat fitur independen, sesuai asumsi Naive Bayes.
2. Outlier ditangani sehingga prediksi lebih stabil.
3. Normalisasi Z-Score memastikan semua variabel setara.

### Ringkasan

Alur ini membersihkan data (missing value & outlier), menstandarisasi skala, lalu mengurangi korelasi antar fitur dengan PCA. Hasilnya, Gaussian Naive Bayes dapat bekerja lebih sesuai teorinya.


