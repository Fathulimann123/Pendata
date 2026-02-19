# Data Understanding

## 2.1 Describe Data
Tahap ini bertujuan untuk mendokumentasikan properti permukaan dari dataset yang digunakan, termasuk format data, jumlah rekaman, serta identitas setiap kolom (field).

### Sampel Data
Berikut adalah gambaran 5 baris pertama (head) dari dataset Iris untuk menunjukkan format data awal:

| sepal_length | sepal_width | petal_length | petal_width | species |
| :--- | :--- | :--- | :--- | :--- |
| 5.1 | 3.5 | 1.4 | 0.2 | Iris-setosa |
| 4.9 | 3.0 | 1.4 | 0.2 | Iris-setosa |
| 4.7 | 3.2 | 1.3 | 0.2 | Iris-setosa |
| 4.6 | 3.1 | 1.5 | 0.2 | Iris-setosa |
| 5.0 | 3.6 | 1.4 | 0.2 | Iris-setosa |

### Struktur Dataset
Berdasarkan pemeriksaan awal terhadap Iris Flower Dataset, diperoleh informasi struktur sebagai berikut:
* **Jumlah Baris**: Dataset ini memiliki total **150 baris** (records).
* **Jumlah Kolom**: Terdapat **5 kolom** utama yang digunakan untuk proses analisis.
* **Sumber Data**: Dataset diperoleh dari repositori publik Kaggle.

### Deskripsi Atribut (Tipe Data)
Dataset ini terdiri dari 4 fitur numerik sebagai prediktor dan 1 kolom kategorikal sebagai target klasifikasi. Semua pengukuran dimensi fisik menggunakan satuan **centimeter (cm)**.

| Nama Atribut | Tipe Data | Deskripsi |
| :--- | :--- | :--- |
| **sepal_length** | Numerik (Float) | Panjang kelopak bunga dalam cm. |
| **sepal_width** | Numerik (Float) | Lebar kelopak bunga dalam cm. |
| **petal_length** | Numerik (Float) | Panjang mahkota bunga dalam cm. |
| **petal_width** | Numerik (Float) | Lebar mahkota bunga dalam cm. |
| **species** | Kategorikal (String)| Label spesies bunga (*Setosa, Versicolor, Virginica*). |

> **Catatan**: Atribut numerik akan digunakan sebagai variabel independen, sedangkan atribut `species` akan menjadi variabel dependen dalam pemodelan nanti.