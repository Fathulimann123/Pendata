## Data Understanding

### Apa itu Metodologi CRISP-DM?
Dalam mengerjakan proyek penambangan data ini, kita mengikuti alur **CRISP-DM** (*Cross-Industry Standard Process for Data Mining*). Metodologi ini punya 6 tahapan utama, mulai dari memahami bisnis sampai modelnya siap dipakai. Tahap **Data Understanding** adalah fase kedua setelah *Business Understanding*. Kalau di fase pertama kita fokus ke "apa masalahnya?", di fase kedua ini kita fokus ke "mana datanya?" dan "gimana kondisi datanya?".

### Tujuan Utama Fase Ini:
1. **Kenalan sama data**: Biar kita gak asing sama isi tabelnya.
2. **Cek Kualitas**: Mastiin datanya bersih, gak ada yang kosong (*missing values*), atau gak ada yang aneh (*outliers*).
3. **Cari Insight Awal**: Nemu pola-pola menarik lewat statistik simpel.

---
## Persiapan Akses Data
Sebelum kita bisa memahami pola dan karakteristik data, kita perlu memastikan data bisa diakses dengan baik. Tahap ini termasuk bagian dari **Data Understanding**, karena kita sedang mengenali sumber data dan cara membacanya.

**Install Library & Connect Python ke Database**  
Jalankan perintah berikut di terminal/command prompt untuk menginstal library yang dibutuhkan:

```python
pip install pandas seaborn matplotlib numpy sqlalchemy pymysql

```
Kenapa perintahnya panjang? Karena kita mengunduh beberapa alat sekaligus:
- **SQLAlchemy**: Mesin pengolah database.
- **PyMySQL**: "Kabel" penghubung ke MySQL Laragon.
- **Pandas**: Pembuat tabel agar data rapi.
- **Seaborn & Matplotlib**: Alat visualisasi untuk grafik.
- **NumPy**: Mesin hitung numerik yang dipakai Pandas dan Seaborn.

```
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
from sqlalchemy import create_engine

# Koneksi ke MySQL Laragon
engine = create_engine("mysql+pymysql://root:@localhost/pendata")
df = pd.read_sql("SELECT * FROM iris", engine)

print("✅ Data Berhasil Diambil dari MySQL!")
```
**Sampel Data** <br>
Berikut adalah gambaran 5 baris pertama (head) dari dataset Iris untuk menunjukkan format data awal:


|index|sepal\_length|sepal\_width|petal\_length|petal\_width|species|
|---|---|---|---|---|---|
|0|5\.1|3\.5|1\.4|0\.2|Iris-setosa|
|1|4\.9|3\.0|1\.4|0\.2|Iris-setosa|
|2|4\.7|3\.2|1\.3|0\.2|Iris-setosa|
|3|4\.6|3\.1|1\.5|0\.2|Iris-setosa|
|4|5\.0|3\.6|1\.4|0\.2|Iris-setosa|

**Struktur Dataset** <br>
Berdasarkan pemeriksaan awal terhadap Iris Flower Dataset, diperoleh informasi struktur sebagai berikut:
* **Jumlah Baris**: Dataset ini memiliki total **150 baris** (records).
* **Jumlah Kolom**: Terdapat **5 kolom** utama yang digunakan untuk proses analisis.
* **Sumber Data**: Dataset diperoleh dari repositori publik Kaggle.

**Deskripsi Atribut (Tipe Data)** <br>
Dataset ini terdiri dari 4 atribut numerik yang merepresentasikan ukuran bagian bunga dalam satuan **centimeter (cm)** dan 1 atribut kategorikal yang berfungsi sebagai **label atau target klasifikasi bunga** tersebut.

>Kita pakai fungsi df.info() buat lihat tipe data tiap kolom dan mastiin nggak ada data yang bolong.
```
df.info()
```

| Nama Atribut | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| **sepal_length** | Numerik (Float) | Panjang kelopak bunga dalam cm. |
| **sepal_width** | Numerik (Float) | Lebar kelopak bunga dalam cm. |
| **petal_length** | Numerik (Float) | Panjang mahkota bunga dalam cm. |
| **petal_width** | Numerik (Float) | Lebar mahkota bunga dalam cm. |
| **species** | Kategorikal (String)| Label spesies bunga (*Setosa, Versicolor, Virginica*). |


> **Catatan**: Atribut numerik akan digunakan sebagai variabel independen, sedangkan atribut `species` akan menjadi variabel dependen.

Analisis Singkat:<br>

* Total Sampel: 150 data.
* Kondisi: Data sangat sehat karena tidak ditemukan nilai kosong (Non-Null).
* Atribut: Terdiri dari 4 fitur angka (panjang & lebar kelopak/mahkota) dan 1 kolom target (spesies).

**Statistik Deskriptif**
>Kita hitung nilai rata-rata ($\bar{x}$) dan sebaran datanya ($\sigma$) untuk melihat ringkasan angka dari 150 sampel yang kita punya.

**Kode Python:**
```python
# Menampilkan ringkasan statistik untuk semua fitur numerik
df.describe()
```
|index|sepal\_length|sepal\_width|petal\_length|petal\_width|
|---|---|---|---|---|
|count|150\.0|150\.0|150\.0|150\.0|
|mean|5\.843333333333334|3\.0540000000000003|3\.758666666666666|1\.1986666666666668|
|std|0\.8280661279778629|0\.4335943113621737|1\.7644204199522617|0\.7631607417008414|
|min|4\.3|2\.0|1\.0|0\.1|
|25%|5\.1|2\.8|1\.6|0\.3|
|50%|5\.8|3\.0|4\.35|1\.3|
|75%|6\.4|3\.3|5\.1|1\.8|
|max|7\.9|4\.4|6\.9|2\.5|

**Penjelasan Parameter:**

>Setelah menjalankan fungsi `df.describe()`, kita akan mendapatkan beberapa parameter kunci yang menjelaskan karakteristik data Iris kita:

1. **Count**: Menunjukkan jumlah total baris data yang ada. Untuk dataset ini, jumlahnya adalah 150 sampel.
2. **Mean**: Nilai rata-rata dari seluruh data pada atribut tertentu.
3. **Std**: Standar deviasi, yang menunjukkan seberapa jauh data tersebar dari nilai rata-ratanya. Semakin besar nilainya, berarti data semakin bervariasi.
4. **Min**: Nilai terkecil yang ditemukan dalam kolom tersebut.
5. **Max**: Nilai terbesar yang ditemukan dalam kolom tersebut.
---

## Verifikasi Kualitas Data (Null & Duplicate)

Setelah kita cek angka-angkanya, sekarang kita pastikan data ini benar-benar bersih. Di dunia penambangan data, ada istilah **"Garbage In, Garbage Out"**; kalau datanya sampah, hasilnya pun bakal sampah.

**Pemeriksaan Nilai Null (Missing Values)**

Data kosong bisa bikin algoritma kita *error* atau salah hitung. Kita pakai fungsi `isnull()` untuk melihat apakah ada baris yang bolong.

**Kode Python:**
```python
# Cek jumlah data kosong di setiap kolom
print("Jumlah Data Null:")
print(df.isnull().sum())
```

Pemeriksaan dilakukan untuk mengidentifikasi keberadaan nilai kosong (missing values) pada setiap variabel dalam dataset. Berdasarkan hasil pengecekan, seluruh kolom tidak memiliki nilai null.

**Jumlah Data Null per Kolom**

| Nama Kolom      | Jumlah Null |
|-----------------|------------|
| sepal_length    | 0 |
| sepal_width     | 0 |
| petal_length    | 0 |
| petal_width     | 0 |
| species         | 0 |
| dtype: int6|

**Analisis:** <br>
Jika hasilnya semua 0, berarti data Iris kamu sudah aman dan lengkap. Tidak perlu ada proses "tambal sulam" data (imputasi).

---

**Pemeriksaan Data Duplikat**

Data duplikat adalah baris yang memiliki seluruh nilai kolom identik satu sama lain. Keberadaan data duplikat dalam jumlah signifikan dapat memengaruhi hasil analisis, terutama pada pemodelan machine learning, karena dapat menyebabkan bias distribusi dan meningkatkan risiko overfitting.

```
# Cek jumlah data yang kembar
jml_duplikat = df.duplicated().sum()
print(f"Jumlah data duplikat: {jml_duplikat}")

# Kalau mau lihat data mana aja yang kembar:
if jml_duplikat > 0:
    print(df[df.duplicated()])
```

Berdasarkan hasil pengecekan, ditemukan adanya data duplikat dalam dataset.

**Jumlah Data Duplikat**
- Total data duplikat: **3 baris**


| Index | sepal_length | sepal_width | petal_length | petal_width | species |
|-------|-------------|------------|-------------|------------|---------------|
| 34    | 4.9 | 3.1 | 1.5 | 0.1 | Iris-setosa |
| 37    | 4.9 | 3.1 | 1.5 | 0.1 | Iris-setosa |
| 142   | 5.8 | 2.7 | 5.1 | 1.9 | Iris-virginica |

>Ditemukan tiga baris dengan nilai identik.

##  Visualisasi Data

### Histogram
#### Apa itu Histogram?
Histogram adalah grafik batang yang menggambarkan distribusi atau penyebaran frekuensi data. Alih alih melihat tumpukan angka dalam tabel, histogram mengubahnya menjadi bentuk visual agar kita bisa melihat pola data secara instan.

**Kenapa Kita Melakukan Visualisasi Ini?** <br>
Tujuannya adalah untuk memahami karakteristik fisik (seperti panjang dan lebar kelopak bunga) secara cepat. Kita bisa langsung mengetahui:

* Pola Utama: Nilai mana yang paling sering muncul (rata-rata).
* Variasi: Seberapa luas rentang datanya.
* Anomali: Apakah ada data yang letaknya sangat jauh dari kelompok utama.

**Panduan Membaca Sumbu (X & Y)** <br>
Agar mudah dipahami, bayangkan sumbu ini sebagai koordinat dasar:

* **Sumbu X (Horizontal/Mendatar)**: Mewakili Nilai atau Ukuran. Misalnya, panjang kelopak dalam satuan cm (5cm, 6cm, dst).
* **Sumbu Y (Vertical/Tegak)**: Mewakili Frekuensi atau Jumlah. Menunjukkan berapa kali ukuran di sumbu X tersebut muncul dalam data kita.

Logika Singkat: Sumbu X adalah "Apa ukurannya?", Sumbu Y adalah "Berapa banyak jumlahnya?".

![Statistik Orange](../img/data-understanding/Histogram-sepal_length.png)
**Fig. 1 Histogram Distribusi Frekuensi Fitur sepal_length**

![Statistik Orange](../img/data-understanding/sepal_width.png)
**Fig. 2 Histogram Distribusi Frekuensi Fitur sepal_width**

![Statistik Orange](../img/data-understanding/petal_length.png)
**Fig. 3 Histogram Distribusi Frekuensi Fitur petal_length**

![Statistik Orange](../img/data-understanding/petal_width.png)
**Fig. 4 Histogram Distribusi Frekuensi Fitur petal_width**

![Statistik Orange](../img/data-understanding/species.png)
**Fig. 5 Histogram Distribusi Frekuensi Fitur species**

### Scatter plot
#### Apa itu Scatter Plot?
Scatter plot (diagram titik) adalah grafik yang digunakan untuk melihat hubungan antara dua variabel angka. Jika histogram hanya melihat satu fitur, scatter plot mempertemukan dua fitur sekaligus untuk melihat apakah mereka saling memengaruhi.

#### Kenapa Kita Melakukan Visualisasi Ini?
Tujuannya adalah untuk mencari Korelasi (pola hubungan). Dengan scatter plot, kita bisa menjawab pertanyaan seperti:


* "Kalau kelopak bunganya makin panjang, apakah lebarnya otomatis makin besar juga?"
* "Apakah ada kelompok data yang terpisah secara jelas?" (Ini sangat penting untuk teknik Clustering di mata kuliah Penambangan Data).

#### Memahami Sumbu X dan Y (Titik Pertemuan)
Cara membacanya sangat sederhana, bayangkan seperti koordinat di peta:
* ***Sumbu X (Horizontal)***: Variabel pertama (misal: Panjang Sepal).
* ***Sumbu Y (Vertical)***: Variabel kedua (misal: Lebar Sepal).

Titik (Dot): Setiap satu titik di grafik mewakili satu sampel data yang merupakan pertemuan antara nilai X dan nilai Y.

**Scatter Plot sepal_length dan sepal_width** <br>
![Statistik Orange](../img/data-understanding/sepal_length-sepal_width.png)
**Fig. 6 Scatter Plot Fitur sepal_length dan sepal width**
* Korelasi: Nilai $r = -0.11$ menunjukkan korelasi negatif yang sangat lemah, hampir mendekati nol.
* Insight: Artinya, panjang sepal tidak terlalu memengaruhi lebarnya. Titik-titik data terlihat menyebar (scattered) tanpa membentuk pola garis yang jelas. Untuk klasifikasi, fitur sepal ini biasanya lebih sulit membedakan antar spesies dibanding fitur petal.

**Scatter Plot petal dan petal_width** <br>
![Statistik Orange](../img/data-understanding/petal_length-petal_width.png)
**Fig. 7 Scatter Plot Fitur petal_length dan petal_width**
berikut jika di implementasikan di python

```
print("Korelasi petal_length dan petal_width: ",round(df['petal_width'].corr(df['petal_length']), 2))
plt.scatter(df['petal_length'], df['petal_width'])
plt.xlabel('petal_length')
plt.ylabel('petal_width')
plt.title('Scatter Plot petal_length vs petal_width')
plt.show()
```
![Statistik Orange](../img/data-understanding/python-petal_length-petal_width.png)

* Korelasi: Nilai $r = 0.96$ menunjukkan korelasi positif yang sangat kuat (mendekati sempurna). **Insight**: Ada hubungan linear yang sangat konsisten semakin panjang kelopak (petal), maka lebarnya hampir pasti bertambah secara proporsional.
* Cluster: Kamu bisa melihat ada kelompok kecil di pojok kiri bawah yang terpisah jauh dari kelompok besar lainnya. Itu adalah spesies Setosa, yang secara fisik memang jauh lebih kecil dibanding Versicolor dan Virginica.

### Outlier
#### Apa itu Outlier?
Outlier (Pencilan) adalah titik data yang nilainya sangat jauh berbeda dari mayoritas data lainnya dalam satu kelompok. Bayangkan jika kamu mendata tinggi badan mahasiswa di kelasmu yang rata-rata 160–170 cm, tiba-tiba ada satu orang yang tingginya 210 cm. Nah, orang tersebut adalah outlier.

**Kenapa Kita Harus Mendeteksi Outlier?** <br> 
Dalam pengolahan data, outlier bisa terjadi karena dua hal:

1. Kesalahan Input: Misalnya salah ketik angka (seharusnya 1.5 jadi 15).
2. Variasi Alami: Memang ada sampel yang unik/langka.

Penting untuk mendeteksi mereka karena outlier bisa "merusak" hasil statistik (seperti rata-rata) dan membuat model prediksi menjadi tidak akurat.

**Metode: Local Outlier Factor (LOF)** <br>
Berdasarkan gambar laporan, saya menggunakan metode LOF.

* **Cara Kerjanya**: LOF tidak hanya melihat nilai angka, tapi melihat kepadatan di sekitar sebuah titik. Jika sebuah titik berada di area yang sangat sepi (jauh dari tetangganya/neighbors), maka sistem akan menandainya sebagai outlier.

* **Sumbu X & Y pada Outlier** : Dalam visualisasi yang kamu buat, sumbu X dan Y tetap mewakili fitur data, namun sistem menambahkan tanda khusus (biasanya warna atau bentuk berbeda) pada titik-titik yang dianggap "aneh" oleh algoritma LOF tersebut.

![Statistik Orange](../img/data-understanding/data-table.png)
**Fig. 8 Outlier**

berikut jika di implementasikan di python 
```
X = df.select_dtypes(include=[np.number]).values
lof = LocalOutlierFactor(
    n_neighbors=20,
    contamination=0.10,
    metric='euclidean'
)

y_pred = lof.fit_predict(X)
df['LOF_Score'] = -lof.negative_outlier_factor_
df['Outlier'] = y_pred

outlier_lines = list(df[df['Outlier'] == -1].index + 1)

print("Total Outlier:", len(outlier_lines))
print("Nomor Baris Outlier:")
print(outlier_lines)
```
>Total Outlier: 15 <br>
Nomor Baris Outlier: <br>
[14, 15, 16, 34, 42, 58, 61, 94, 99, 106, 107, 118, 119, 123, 132]

## Mengukur jarak data  (distance)

### Menghitung jarak data iris <br>
Diatas tadi kita sudah explorasi data kita sudah tau bahwa data pada ```IRIS``` yang semua datanya Numerik, sehingga kita hanya akan menggunakan tipe jarak Euclidean, dan jarak kategorikal pada kolom spesies
| Fitur / Kolom | Baris 0 | Baris 1 | Tipe Data |
| :--- | :--- | :--- | :--- |
| **sepal_length** | 5.1 | 4.9 | Numerik |
| **sepal_width** | 3.5 | 3.0 | Numerik |
| **petal_length** | 1.4 | 1.4 | Numerik |
| **petal_width** | 0.2 | 0.2 | Numerik |
| **species** | setosa | setosa | Kategorikal |

#### Menghitung Jarak Numerik Pada IRIS

Tujuan perhitungan ini adalah untuk mengukur kemiripan (*similarity*) dua sampel data dengan melihat selisih nilai pada tiap fitur ```numeriknya```.

| Fitur | Row 0 | Row 1 | Selisih ($A-B$) | Kuadrat $(A-B)^2$ |
| :--- | :---: | :---: | :---: | :---: |
| **sepal_length** | 5.1 | 4.9 | $0.2$ | $0.04$ |
| **sepal_width** | 3.5 | 3.0 | $0.5$ | $0.25$ |
| **petal_length** | 1.4 | 1.4 | $0$ | $0$ |
| **petal_width** | 0.2 | 0.2 | $0$ | $0$ |



**Langkah Penyelesaian:**

1.  **Total Kuadrat ($\sum$):** Menjumlahkan seluruh kolom hasil kuadrat.
    * $0.04 + 0.25 + 0 + 0 = \mathbf{0.29}$
2.  **Jarak Akhir ($\sqrt{}$):** Melakukan akar kuadrat dari total penjumlahan untuk mendapatkan jarak Euclidean.
    * $d = \sqrt{0.29} \approx \mathbf{0.5385}$



**Interpretasi Singkat:** <br>
Nilai jarak **0.5385** yang mendekati angka **0** membuktikan secara matematis bahwa **Row 0** dan **Row 1** memiliki karakteristik fisik yang sangat identik. Dalam Penambangan Data, ini mengindikasikan bahwa kedua data tersebut kemungkinan besar berada dalam satu kelompok (*cluster*) yang sama.

---
#### Menghitung Jarak Kategorikal Pada IRIS

Untuk atribut non-numerik seperti 'Species', kita menggunakan metode **```Simple Matching```**. Logikanya sederhana: jika data sama maka jaraknya 0 (identik), jika berbeda maka jaraknya 1 (maksimal). 

Rumus yang digunakan adalah $D_{cat} = \frac{P - M}{P}$, di mana $P$ adalah total fitur kategorikal dan $M$ adalah jumlah kecocokan (*match*).

| Variabel Kategorikal | Baris 0 (Sampel A) | Baris 1 (Sampel B) | Hasil Observasi |
| :--- | :---: | :---: | :---: |
| **species** | setosa | setosa | *Match* (Cocok) |



**Kalkulasi Jarak:**

* **Total Dimensi Kategorikal ($P$):** 1
* **Jumlah Atribut yang Sama ($M$):** 1
* **Skor Jarak Kategorikal ($D_{cat}$):** $\frac{1 - 1}{1} = \frac{0}{1} = \mathbf{0}$


> **Kesimpulan:** Karena skor $D_{cat}$ adalah **0**, ini mengonfirmasi bahwa secara kategoris tidak ada perbedaan antara Baris 0 dan Baris 1. Keduanya memiliki label yang sama persis, sehingga nilai "penalti" jaraknya adalah nol.

---

#### Akumulasi Jarak Akhir Pada IRIS 

Setelah mendapatkan nilai dari dua aspek berbeda (Numerik dan Kategorikal), kita menggabungkannya untuk mendapatkan skor jarak total. Dalam kasus ini, kita menggunakan penjumlahan sederhana:

$$D_{total} = D_{num} + D_{cat}$$

**Kalkulasi:**
$$D_{total} = 0.5385 + 0 = \mathbf{0.5385}$$

---

#### Analisis Tambahan: Cosine Similarity (Arah Kedekatan)

Selain melihat jarak "garis lurus" (Euclidean), kita juga menggunakan **Cosine Similarity** untuk melihat kemiripan proporsi atau arah sudut antar fitur numerik. Jika Euclidean melihat seberapa "jauh" perbedaannya, Cosine melihat seberapa "searah" polanya.

**Rumus Komputasi:**
$$\cos(\theta) = \frac{\mathbf{A} \cdot \mathbf{B}}{\|\mathbf{A}\| \|\mathbf{B}\|}$$

**Proses Kalkulasi:**
1. **Dot Product (Atas):** $(5.1 \times 4.9) + (3.5 \times 3.0) + (1.4 \times 1.4) + (0.2 \times 0.2) = \mathbf{37.49}$
2. **Magnitude (Bawah):** $\sqrt{5.1^2 + 3.5^2 + 1.4^2 + 0.2^2} \times \sqrt{4.9^2 + 3.0^2 + 1.4^2 + 0.2^2}$
   * $\mathbf{6.345 \times 5.918 \approx 37.550}$
3. **Hasil Akhir:** $\frac{37.49}{37.550} \approx \mathbf{0.9984}$


#### Insight Akhir

* **Jarak Total (0.5385):** Mengonfirmasi bahwa secara fisik, kedua bunga ini berada pada posisi yang berdekatan di ruang data.
* **Cosine Similarity (0.9984):** Angka yang sangat mendekati **1.0** ini menunjukkan bahwa pola pertumbuhan (proporsi) antara Baris 0 dan Baris 1 hampir identik secara arah sudut.

> **Kesimpulan Final:** Kedua sampel data ini tidak hanya memiliki nilai yang mirip secara angka, tetapi juga memiliki "pola" fitur yang sangat searah.

#### Implementasi pada Orange Data Mining
Dalam praktikum menggunakan Orange Data Mining, kita memanfaatkan widget Distances. Poin krusial dalam langkah ini adalah penggunaan metode Normalized Euclidean.

Mengapa Harus Normalisasi? Karena setiap fitur mungkin memiliki skala yang berbeda. Normalisasi memastikan bahwa fitur dengan angka besar (misal Sepal Length) tidak mendominasi fitur dengan angka kecil (misal Petal Width).

Output: Hasilnya diproyeksikan ke dalam Distance Matrix, yang memvisualisasikan skor jarak antar setiap sampel data secara head-to-head.
![Statistik Orange](../img/data-understanding/iris-euclidean.png)

Berdasarkan hasil pemrosesan pada widget Distance Matrix:
- Nilai mendekati 0 (Warna Gelap): Menunjukkan bahwa kedua bunga memiliki karakteristik fisik yang hampir identik.
- Nilai tinggi (Warna Terang): Menunjukkan perbedaan morfologi yang signifikan antar bunga.
---

### Menghitung jarak data student
Berikut adalah data sampel untuk pengujian (Row 0 dan Row 1):

| Fitur / Kolom | Baris 0 | Baris 1 | Tipe Data (DM) |
| :--- | :--- | :--- | :--- |
| **Gender** | Male | Female | Nominal |
| **Age** | 33.0 | 24.0 | Numerik |
| **City** | Visakhapatnam | Bangalore | Nominal |
| **Academic Pressure** | 5.0 | 2.0 | Ordinal |
| **CGPA** | 8.97 | 5.9 | Numerik |
| **Study Satisfaction** | 2.0 | 5.0 | Ordinal |
| **Sleep Duration** | '5-6 hours' | '5-6 hours' | Ordinal |
| **Dietary Habits** | Healthy | Moderate | Ordinal |
| **Financial Stress** | 1.0 | 2.0 | Ordinal |
| **Depression** | 1 | 0 | Nominal (Target) |

**Kenapa Harus Dipilah? Ini Alasannya:** <br>
Dalam Data Mining, kita tidak bisa asal menjumlahkan semua kolom karena "cara ngukurnya" beda-beda. Berikut alasan kenapa saya pilah:

**1. Masalah Data Ordinal (Skala)**

Seperti yang kamu bilang, data Ordinal (seperti Academic Pressure 1-5 atau Sleep Duration) itu spesial.
- Dia punya tingkatan (1 lebih rendah dari 5), tapi dia bukan angka murni seperti CGPA.
- Alasan: Sebelum dihitung pakai Euclidean, kita harus melakukan Mapping (misal: 'Healthy' jadi 3, 'Moderate' jadi 2, 'Unhealthy' jadi 1). Kalau belum di-mapping, komputer akan bingung membacanya sebagai angka atau teks.

**2. Perbedaan Metrik Jarak**
- Numerik (Age, CGPA): Pakai Euclidean (dikurangi lalu dikuadratkan).
- Nominal (Gender, City): Pakai Simple Matching (Sama atau Beda).
- Jika kita paksa semua kolom masuk ke satu rumus tanpa dipilah, hasil jaraknya jadi tidak akurat (istilahnya Bias).

**3. Kolom Target (Depression/Suicidal Thoughts)**
- Alasan: Kolom seperti Depression biasanya tidak dimasukkan dalam hitungan jarak kemiripan.
- Kenapa? Karena ini adalah "jawaban" yang ingin kita prediksi. Kita menghitung jarak berdasarkan "ciri-cirinya" (tekanan, nilai, pola tidur), bukan berdasarkan "hasil akhirnya".

**Perbedaan Nominal dengan Ordinal**

Nominal: Gak ada urutan.
- Contoh: Warna motor (Merah, Hitam, Biru). Gak ada yang lebih "tinggi" derajatnya.

Ordinal: Ada urutan/tingkatan.
- Contoh: Kepuasan belajar (Puas, Cukup, Tidak Puas). Di sini jelas kalau "Puas" itu levelnya di atas "Cukup".

---
Karena dataset Student memiliki variasi tipe data yang berbeda, kita melakukan dekomposisi perhitungan berdasarkan sifat masing-masing fitur (Numerik, Nominal, dan Ordinal) untuk menjaga akurasi kemiripan.

---

#### Menghitung Jarak Numerik pada Student
Fitur numerik kontinu diukur menggunakan selisih kuadrat untuk melihat jarak fisik antar observasi.

| Fitur Numerik | Sampel A (Row 0) | Sampel B (Row 1) | Selisih ($A-B$) | Kuadrat $(A-B)^2$ |
| :--- | :---: | :---: | :---: | :---: |
| **Age** | 33.0 | 24.0 | $9.0$ | $81.0$ |
| **CGPA** | 8.97 | 5.9 | $3.07$ | $9.4249$ |



* **Total Varians Numerik ($\sum$):** $81.0 + 9.4249 = \mathbf{90.4249}$
* **Jarak Numerik ($D_{num}$):** $\sqrt{90.4249} \approx \mathbf{9.51}$

---

#### Menghitung Nominal Pada Student (Simple Matching)
Untuk fitur label (Nominal), kita menggunakan rasio ketidakcocokan. Jarak akan bernilai **0** jika identik dan **1** jika berbeda.

| Fitur Nominal | Sampel A | Sampel B | Status |
| :--- | :---: | :---: | :---: |
| **Gender** | Male | Female | *Mismatch* |
| **City** | Visakhapatnam | Bangalore | *Mismatch* |
| **Profession** | Student | Student | **Match** |

* **Total Atribut ($P$):** 3
* **Jumlah Cocok ($M$):** 1
* **Jarak Nominal ($D_{nom}$):** $\frac{P - M}{P} = \frac{3 - 1}{3} = \frac{2}{3} \approx \mathbf{0.67}$

---

#### Normalisasi & Menghitung Jarak Ordinal
Fitur ordinal memiliki tingkatan nilai. Kita melakukan *mapping* ke skala numerik (misal: Healthy=3, Moderate=2, Unhealthy=1) sebelum dilakukan perhitungan.

| Fitur Ordinal | Sampel A (Val) | Sampel B (Val) | Selisih | Kuadrat |
| :--- | :---: | :---: | :---: | :---: |
| **Academic Pressure** | 5 | 2 | $3$ | $9$ |
| **Study Satisfaction** | 2 | 5 | $-3$ | $9$ |
| **Dietary Habits** | 3 (Healthy) | 2 (Mod) | $1$ | $1$ |



* **Total Varians Ordinal:** $9 + 9 + 1 = \mathbf{19}$
* **Jarak Ordinal ($D_{ord}$):** $\sqrt{19} \approx \mathbf{4.36}$

---

#### Akumulasi Jarak Akhir Pada Student

Hasil akhir diperoleh dengan menggabungkan ketiga dimensi jarak tersebut:

$$D_{total} = D_{num} + D_{nom} + D_{ord}$$
$$D_{total} = 9.51 + 0.67 + 4.36 = \mathbf{14.54}$$

---

#### Analisis & Interpretasi Akhir

Berdasarkan hasil komputasi sebesar **14.54**, dapat disimpulkan bahwa Mahasiswa pada Baris 0 dan Baris 1 memiliki tingkat perbedaan yang signifikan. 

1. **Dominasi Usia:** Perbedaan usia (9 tahun) memberikan kontribusi terbesar ($81.0$ pada varians) terhadap jarak total.
2. **Kesenjangan Performa:** Terdapat perbedaan drastis pada beban akademik (*Academic Pressure*) dan kepuasan belajar (*Study Satisfaction*) yang saling bertolak belakang.
3. **Kesesuaian Profesi:** Meskipun memiliki latar belakang sosial dan fisik yang berbeda, keduanya tetap memiliki kemiripan nominal pada fitur **Profession** (keduanya adalah mahasiswa).

## Preprocessing Data: Normalisasi dan Penanganan Data Hilang
Tahap preprocessing merupakan langkah krusial dalam Data Mining untuk memastikan data mentah siap diolah oleh algoritma. Pada proyek ini, fokus utama preprocessing adalah melakukan Normalisasi untuk menyamakan skala fitur numerik dan Imputasi untuk menangani data yang kosong (missing values) agar informasi dalam dataset tetap utuh dan akurat.

### Analisis Tipe Data Atribut
Sebelum menerapkan rumus, kita harus mengelompokkan atribut berdasarkan tipe datanya untuk menentukan metode transformasi yang tepat:  
Kelompok Atribut   | Nama Atribut                                | Tipe Data             | Metode Penanganan
-------------------|---------------------------------------------|-----------------------|-------------------------
Numerik & Ordinal  | Age, CGPA, Academic Pressure, Financial Stress | Angka (Rasio/Ordinal) | Min-Max Normalization
Kategorikal        | Gender, City, Depression, Anxiety, Panic Attack | Teks (Kategori)       | Mapping & Label Encoding

### Normalisasi Min-Max

#### 1. Tujuan dan Atribut Sasaran
Normalisasi Min-Max digunakan untuk menyamakan skala atribut numerik dan ordinal seperti
- Age
- CGPA
- Academic Pressure
- Financial Stress

Tujuannya adalah agar semua nilai berada dalam rentang 0 hingga 1, sehingga perbandingan antar atribut menjadi lebih adil.

#### 2. Cara Kerja
Metode ini melakukan transformasi linear pada data asli.
- Nilai terkecil dalam suatu kolom akan menjadi 0.
- Nilai terbesar akan menjadi 1.
- Nilai lainnya akan dipetakan ke angka desimal di antara 0 dan 1.<br>

Rumus matematisnya adalah:

$$x' = \frac{x - x_{min}}{x_{max} - x_{min}}$$

#### 3. Alasan Pemilihan Min-Max
- Keadilan Jarak: Tanpa normalisasi, selisih Age (misalnya 10 tahun) bisa terlihat jauh lebih besar dibanding selisih CGPA (misalnya 0.5). Padahal, pengaruh IPK terhadap stres bisa lebih signifikan. Normalisasi membuat perbandingan lebih seimbang.
- Kompatibilitas: Rentang 0–1 cocok dipadukan dengan data kategorikal yang sudah di-encode menjadi biner (0 dan 1). Hal ini membuat perhitungan jarak Euclidean lebih stabil dan akurat.

#### 4. Penjelasan Sederhana
Bayangkan kamu punya dua penggaris: satu panjang 100 cm (untuk Age), satu lagi hanya 4 cm (untuk CGPA). Kalau dibandingkan langsung, perubahan kecil di CGPA akan kalah terlihat dibanding perubahan besar di Age. Normalisasi Min-Max ibarat menyamakan panjang penggaris menjadi skala yang sama (0–1), sehingga setiap perubahan bisa dibandingkan secara adil.

### Mapping & Encoding (Data Kategorikal)
#### 1. Tujuan dan Atribut Sasaran
Data kategori berbentuk teks (misalnya Gender, City, dan Mental Health Status) tidak bisa langsung diproses dengan rumus matematika.
Oleh karena itu, dilakukan Encoding agar label teks diubah menjadi angka representatif sehingga bisa digunakan dalam perhitungan jarak.

#### 2. Mekanisme Transformasi
1. Biner (Label Encoding)  
Digunakan untuk atribut dengan dua pilihan.
Contoh:
- Gender → Female = 0, Male = 1
- Depression → No = 0, Yes = 1
2. Multi-Kategori (Mapping)  
Digunakan untuk atribut dengan banyak pilihan.
Contoh:
- City → Visakhapatnam = 0, Bangalore = 1, Srinagar = 2, dan seterusnya. <br>
Dengan cara ini, setiap kategori teks memiliki representasi angka yang konsisten.

#### 3. Alasan Pemilihan Mapping
1. Sederhana & Efisien: Mudah diterapkan tanpa algoritma kompleks.
2. Kompatibel dengan Simple Matching (WKNN):
- Jika dua baris memiliki angka encoding yang sama → jarak = 0 (identik).
- Jika berbeda → jarak = 1 (berbeda).

Hal ini membuat perhitungan jarak antar data kategorikal lebih stabil dan mudah dipahami.

#### 4. Penjelasan Sederhana
Bayangkan kamu sedang membandingkan dua orang berdasarkan Gender. Kalau ditulis sebagai teks ("Male" vs "Female"), komputer tidak bisa langsung menghitung jaraknya. Tapi kalau diubah jadi angka (Male = 1, Female = 0), komputer bisa dengan mudah melihat apakah sama (jarak 0) atau berbeda (jarak 1).

### Dataset Final (Hasil Preprocessing)
Setelah tahap Normalisasi Min-Max dan Mapping selesai, inilah tabel final yang siap digunakan untuk perhitungan Weighted K-Nearest Neighbors (WKNN):

| Gender | Age | City | Academic | CGPA | Financial Stress | Depression |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 1 | 1 | 0 | 1 | 1 | 0 | 1 |
| 0 | 0 | 1 | 0 | 0 | 0.25 | 0 |
| 1 | 0.777778 | 2 | 0.333333 | 0.368078 | 0 | 0 |
| 0 | 0.444444 | 3 | 0.333333 | | 1 | 1 |
| 0 | 0.111111 | 4 | 0.666667 | 0.726384 | 0 | 0 |

Meskipun fitur CGPA pada Baris 4 masih memiliki data yang kosong (missing value), dataset ini sekarang telah siap untuk diproses lebih lanjut. Tahap selanjutnya adalah menggunakan algoritma Weighted K-Nearest Neighbors untuk memprediksi nilai CGPA yang hilang tersebut berdasarkan kemiripan karakteristik dengan baris data lainnya.

**Penjelasan Singkat:**
- Gender: (1 = Male, 0 = Female)
- City: (0-4 sesuai urutan kota)
- Depression: (1 = Yes, 0 = No)
- Age & Academic & CGPA: Sudah dalam skala 0-1 hasil Min-Max Normalization.

## Penanganan Missing Value dengan Weighted K-Nearest Neighbors.
Dalam dataset Student Mental Health yang kita olah, terdapat satu baris data yang memiliki nilai tidak lengkap (Missing Value) pada atribut CGPA. Baris inilah yang akan menjadi target utama dalam proses imputasi menggunakan algoritma Weighted K-Nearest Neighbors (WKNN).

### Perhitungan Jarak Euclidean
Untuk mencari kemiripan, kita menggunakan rumus Euclidean Distance. Atribut yang dihitung adalah semua atribut kecuali CGPA (karena CGPA Baris 4 kosong).

#### A. Rumus Dasar
$$d(i, j) = \sqrt{\sum_{k=1}^{n} (x_{ik} - x_{jk})^2}$$

Catatan: Untuk atribut City, jika kodenya berbeda maka selisihnya dianggap 1, jika sama dianggap 0.

#### B.Tabel Perhitungan Jarak (Manual)
Berikut adalah hasil perhitungan jarak antara Baris 4 (Target) dengan baris referensi lainnya:

| Gender | Age      | City | Academic | CGPA     | Financial | Depression | Jarak    | Status |
|--------|----------|------|----------|----------|-----------|------------|----------|--------|
| 1      | 1        | 0    | 1        | 1        | 0         | 1          | 1.937288 | 3      |
| 0      | 0        | 1    | 0        | 0     | 0.25         | 0          | 1.694444 | 1      |
| 1      | 0.777778 | 2    | 0.333333 | 0.368078 | 0         | 0          | 2.027588 | elim   |
| 0      | 0.444444 | 3    | 0.333333 |         | 1         | 1          |          |        |
| 0      | 0.111111 | 4    | 0.666667 | 0.726384 | 0         | 0          | 1.795055 | 2      |

![Statistik Orange](../img/data-understanding/jarak-euclidean.png)

#### C. Perhitungan Jarak (code)
![Statistik Orange](../img/data-understanding/kode-normalisasi.png)

=== PERHITUNGAN JARAK EUCLIDEAN ===

Jarak Target (Baris 4) ke Baris 1: 1.9373 <br>
Jarak Target (Baris 4) ke Baris 2: 1.6944 <br>
Jarak Target (Baris 4) ke Baris 3: 2.0276 <br>
Jarak Target (Baris 4) ke Baris 5: 1.7951 <br>

#### D. Penentuan Tetangga Terdekat (K=3)
Setelah seluruh jarak Euclidean antara Baris 4 (Target) dengan baris lainnya dihitung, langkah selanjutnya adalah mengurutkan jarak tersebut dari yang terkecil hingga terbesar.

Dalam analisis ini, kita menetapkan nilai K=3, yang berarti kita hanya akan mengambil tiga tetangga terdekat (dengan tingkat kemiripan tertinggi) untuk digunakan dalam proses prediksi nilai CGPA.


| Peringkat | Tetangga | Jarak Euclidean (d) | Status           |
|-----------|----------|----------------------|------------------|
| 1         | Baris 2  | 1.6944               | Terpilih (K-1)   |
| 2         | Baris 5  | 1.7951               | Terpilih (K-2)   |
| 3         | Baris 1  | 1.9373               | Terpilih (K-3)   |
| 4         | Baris 3  | 2.0276               | Dieliminasi      |

Penggunaan K=3 dipilih agar hasil prediksi tidak terlalu sensitif terhadap satu data saja (noise) namun tetap menjaga relevansi kemiripan yang kuat.

### Perhitungan Bobot 
#### 1. Menghitung Nilai Bobot (W)
Kita menggunakan rumus Inverse Squared Distance. Intinya: semakin besar jaraknya, semakin kecil bobotnya.

Rumusnya:

$$W = \frac{1}{d^2}$$

![Statistik Orange](../img/data-understanding/weight.png)

#### 2. Menghitung Perkalian Bobot dengan Nilai (W * y)
Sekarang kita kalikan bobot masing-masing tetangga dengan nilai CGPA mereka yang sudah dinormalisasi

![Statistik Orange](../img/data-understanding/w-cgpa.png)


| Baris | Bobot (W) | CGPA   | Rumus Excel | Hasil   |
|-------|-----------|--------|-------------|---------|
| 1 (Row 5) | 0.2664    | 1.0000 | =X5*R5      | 0.2664  |
| 2 (Row 6) | 0.3483    | 0.0000 | =X6*R6      | 0.0000  |
| 5 (Row 9) | 0.3103    | 0.7264 | =X9*R9      | 0.2254  |

#### 3. Final Imputation (Menambal Data)

Di langkah ini, kita akan melakukan dua kali penjumlahan, lalu membaginya.

Rumus Sederhananya:

$$\text{Hasil Akhir} = \frac{\text{Total dari Kolom Z (W * CGPA)}}{\text{Total dari Kolom Y (Weight)}}$$

---
#### **4. Hasil Akhir** 

Setelah mendapatkan nilai bobot ($W$) dan kontribusi nilai ($W \times CGPA$) dari 3 tetangga terdekat, tahap terakhir adalah menghitung rata-rata terbobot untuk menentukan nilai CGPA Baris 4.

**A. Rekapitulasi Perhitungan**

| Komponen | Rumus | Hasil Perhitungan |
| :--- | :--- | :--- |
| **Total Bobot ($\sum W$)** | $W_1 + W_2 + W_5$ | 0.925068 |
| **Total Kontribusi ($\sum W \times y$)** | $(W_1 \times y_1) + (W_2 \times y_2) + (W_5 \times y_5)$ | 0.491873 |

**B. Nilai Prediksi Final**

Nilai CGPA untuk Baris 4 dihitung dengan membagi total kontribusi dengan total bobot:

$$CGPA_{baru} = \frac{0.491873}{0.925068} = \mathbf{0.531715}$$

**Kesimpulan:**
Nilai CGPA Baris 4 yang sebelumnya kosong (Missing Value) kini telah diisi dengan nilai **0.531715** (dalam skala normalisasi). Data ini sekarang siap digunakan untuk proses analisis data mining lebih lanjut.





