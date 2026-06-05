# InfoLansia (Posyandu Sakura)

Aplikasi mobile berbasis Flutter yang dirancang untuk memfasilitasi skrining, pencatatan, dan pemantauan kesehatan lanjut usia (lansia) di **Posyandu Sakura** secara modern, efisien, dan terstruktur.

---

## 🌟 Deskripsi Proyek

**InfoLansia** adalah solusi digital yang dikembangkan untuk mendukung petugas kesehatan (bidan dan kader Posyandu) dalam memantau kondisi kesehatan lansia secara berkala. Aplikasi ini memindahkan proses skrining manual (kertas) ke dalam sistem digital terintegrasi yang memudahkan penginputan data, pencarian riwayat pasien, hingga visualisasi tren kesehatan secara berkala.

Aplikasi ini dibangun dengan fokus pada **kemudahan aksesibilitas**, **keterbacaan yang tinggi**, dan **estetika premium** yang menenangkan untuk digunakan dalam operasional pelayanan kesehatan sehari-hari.

---

## 🎨 Filosofi Desain (Vitality Core)

Desain antarmuka InfoLansia menerapkan pedoman desain **Vitality Core** dengan pengaruh kuat dari konsep modern minimalis dan estetika **iOS-inspired**:

*   **Palet Warna "Emerald Health"**: Didominasi oleh warna hijau zamrud premium (`#006c47`) yang melambangkan vitalitas dan pelayanan medis profesional, dipadukan dengan latar belakang off-white (`#F8F9FA`) untuk meminimalkan kelelahan mata.
*   **Tipografi**: Menggunakan font **Plus Jakarta Sans** yang bersih, modern, dan memiliki tingkat keterbacaan yang sangat baik di layar perangkat mobile.
*   **Layout Spacing**: Menghadirkan *white space* yang cukup luas (*fluid grid* dengan margin halaman `20px`) untuk mengurangi beban kognitif petugas medis saat melakukan skrining yang padat.
*   **Bentuk & Kedalaman**: Sudut kartu melengkung lembut (*continuous curves* 12px–16px) dan efek bayangan halus (*ambient shadow* `0px 4px 24px rgba(0,0,0,0.04)`) untuk memberikan kesan premium, modern, dan ramah pengguna.

---

## 🚀 Fitur Utama

Aplikasi ini mencakup modul-modul utama berikut:

1.  **Autentikasi Petugas**: Akses login khusus untuk Bidan dan Kader Posyandu untuk menjamin keamanan data lansia.
2.  **Dashboard Utama**: Ringkasan aktivitas posyandu, jumlah pasien terdaftar, dan menu pintasan ke fungsi krusial.
3.  **Manajemen Data Lansia**: 
    *   Registrasi/Pendaftaran lansia baru.
    *   Pencarian dan penyaringan data lansia secara cepat.
    *   Pembaruan dan pengeditan profil lansia.
4.  **Layanan Pemeriksaan & Skrining**:
    *   **Skrining Tensi (Tekanan Darah)**: Pencatatan tekanan darah sistolik & diastolik beserta indikator kategorinya.
    *   **Skrining Gula Darah**: Pemantauan kadar gula darah acak/puasa.
5.  **Visualisasi & Tren Kesehatan**:
    *   **Grafik Perkembangan**: Grafik riwayat pemeriksaan tensi dan gula darah untuk memantau peningkatan/penurunan kesehatan individu.
    *   **Visualisasi Tahunan**: Grafik komparatif tahunan aktivitas pemeriksaan posyandu secara keseluruhan.
6.  **Riwayat Pemeriksaan**: Penyimpanan catatan medis historis setiap lansia secara rapi untuk referensi pemeriksaan berikutnya.

---

## 🛠️ Spesifikasi Teknologi & Dependensi

*   **SDK Flutter**: `>=3.0.0 <4.0.0`
*   **Bahasa Pemrograman**: Dart
*   **Dependensi Utama**:
    *   `google_fonts`: Menyediakan font *Plus Jakarta Sans*.
    *   `cupertino_icons`: Ikonografi bergaya iOS yang konsisten.
    *   `flutter_lints`: Menjamin standar kualitas penulisan kode Flutter yang baik.

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── main.dart           # Entry point aplikasi
├── theme.dart          # Konfigurasi sistem desain (Vitality Core)
├── screens/            # Layar aplikasi utama (Dashboard, Layanan, Profil, dsb.)
│   ├── dashboard_screen.dart
│   ├── detail_pasien_screen.dart
│   ├── edit_lansia_screen.dart
│   ├── layanan_gula_darah_screen.dart
│   ├── layanan_screen.dart
│   ├── layanan_tensi_screen.dart
│   ├── login_screen.dart
│   ├── pasien_screen.dart
│   ├── profil_screen.dart
│   ├── riwayat_pemeriksaan_screen.dart
│   ├── skrining_baru_screen.dart
│   ├── skrining_screen.dart
│   ├── tambah_lansia_screen.dart
│   ├── tren_kesehatan_screen.dart
│   └── visualisasi_tahunan_screen.dart
└── widgets/            # Reusable UI components (tombol, kartu, input, dll.)
```

---

## 🏁 Memulai (Getting Started)

Untuk menjalankan proyek ini secara lokal, ikuti langkah-langkah di bawah:

### Prasyarat (Prerequisites)
Pastikan Anda sudah menginstal:
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi `>=3.0.0`)
*   [Dart SDK](https://dart.dev/get-started/sdk)
*   Emulator Android/iOS atau perangkat fisik yang terhubung

### Instalasi & Menjalankan Aplikasi

1.  Clone repositori ini ke komputer lokal Anda:
    ```bash
    git clone https://github.com/Umam07/InfoLansia.git
    ```
2.  Masuk ke direktori proyek:
    ```bash
    cd InfoLansia
    ```
3.  Ambil dependensi yang diperlukan:
    ```bash
    flutter pub get
    ```
4.  Jalankan aplikasi pada perangkat/emulator yang aktif:
    ```bash
    flutter run
    ```

---

## 👨‍💻 Kontributor

*   **Umam07** - [GitHub Profile](https://github.com/Umam07)
