## UTS - DATASET KLASIFIKASI KESUBURAN TANAH 
### Dataset Kesuburan Tanah 
Dataset berisi 2.000 sampel data tanah dengan 10 fitur agronomis dan 1 kolom label yang membagi kondisi tanah menjadi dua kelas: Subur dan Tidak Subur.

### Atribut yang dipakai 
| Atribut | Tipe Data | Penjelasan Singkat |
|:---|:---|:---|
| pH Tanah | Numerik | Skala keasaman atau kebasaan tanah (0–14). |
| N Total (%) | Numerik | Kandungan nitrogen total dalam bentuk persentase. |
| P Tersedia (ppm) | Numerik | Kadar fosfor yang dapat diserap tanaman (dalam ppm). |
| K Tersedia (meq/100g) | Numerik | Kandungan kalium tersedia dalam satuan miliekuivalen. |
| C Organik (%) | Numerik | Persentase kandungan karbon organik dalam tanah. |
| KTK (meq/100g) | Numerik | Kapasitas tanah dalam mengikat dan menyediakan unsur hara. |
| Kejenuhan Basa (%) | Numerik | Persentase kation basa dari total kapasitas tukar kation. |
| Tekstur Tanah | Kategorikal | Klasifikasi jenis partikel tanah (Lempung, Pasir, Liat, dll). |
| Kadar Air (%) | Numerik | Persentase kandungan air yang tersimpan di dalam tanah. |
| Bulk Density (g/cm³) | Numerik | Tingkat kerapatan atau kepadatan massa tanah. |

### Implementasi Knime
Bagian ini menjelaskan rangkaian proses data mining yang dilakukan menggunakan KNIME. Setiap node memiliki peran spesifik dalam mentransformasi data mentah menjadi hasil klasifikasi yang akurat. <br>

![Flow-Knime](../img/uts/knimeflow.png)

### Penjelasan Alur Kerja KNIME (Klasifikasi K-NN dengan PCA)

| Nama Node | Kegunaan / Fungsi Utama | Penjelasan Singkat |
|:---|:---|:---|
| CSV Reader | Data Input | Memasukkan dataset mentah (format .csv) ke dalam sistem. |
| Table View | Inspeksi Data | Menampilkan data dalam bentuk tabel untuk pengecekan awal. |
| Table Partitioner | Data Splitting | Membagi dataset menjadi dua jalur: Data Training (latih) dan Data Testing (uji). |
| Normalizer | Preprocessing | Menyamakan skala semua angka (misal 0 ke 1) agar atribut dengan nilai besar tidak mendominasi. |
| Numeric Outliers | Data Cleaning | Mendeteksi dan menangani nilai ekstrem yang dapat mengganggu akurasi model. |
| Missing Value | Data Cleaning | Mengisi atau menghapus data yang kosong/hilang agar alur tidak error. |
| PCA Compute | Reduksi Dimensi | Menghitung komponen utama untuk menyederhanakan jumlah atribut tanpa kehilangan informasi penting. |
| PCA Apply | Transformasi Data | Menerapkan hasil hitungan PCA ke data training dan testing agar memiliki format dimensi yang sama. |
| K Nearest Neighbor | Model Machine Learning | Algoritma klasifikasi yang menentukan kelompok data berdasarkan jarak tetangga terdekat. |
| Scorer | Evaluasi Model | Membandingkan hasil prediksi dengan data asli untuk menghitung nilai akurasi (%). |

### detail output node utama
A. NODE SCORER

![Flow-Knime](../img/uts/scorer1.png)

| Metrik | Keterangan |
|:---|:---|
| **Accuracy** | Persentase prediksi yang benar dibandingkan dengan total keseluruhan data. |
| **Precision** | Menilai seberapa tepat prediksi kelas positif (Contoh: Dari semua yang diprediksi "Subur", berapa yang benar-benar "Subur"). |
| **Recall** | Menilai seberapa baik model menemukan kembali kelas positif (Contoh: Dari semua tanah yang aslinya "Subur", berapa banyak yang berhasil dideteksi oleh model). |
| **F1-Score** | Nilai rata-rata harmonis antara Precision dan Recall; memberikan gambaran keseimbangan antara keduanya. |

![Flow-Knime](../img/uts/scorer2.png)



