<div align="center">
  <img src="assets/icons/app_icon.png" alt="SignBridge Logo" width="120" />
  <h1>SignBridge</h1>
  <p><strong>Aplikasi Penerjemah Bahasa Isyarat Indonesia (BISINDO) ke Teks & Suara secara Real-Time</strong></p>
  <p><em>Proyek Kompetisi Software Development UNITY #14</em></p>
</div>

---

## 🌟 Tentang SignBridge

**SignBridge** adalah aplikasi mobile berbasis AI yang dirancang untuk mendobrak batasan komunikasi antara teman tuli dan masyarakat luas. Dengan memanfaatkan kamera *smartphone*, aplikasi ini mampu menerjemahkan gerakan Bahasa Isyarat Indonesia (BISINDO) menjadi teks dan suara secara *real-time* dengan performa tinggi dan latensi sangat rendah.

## ✨ Fitur Utama

- **Deteksi Real-Time**: Menerjemahkan gerakan isyarat (BISINDO) langsung dari *feed* kamera tanpa jeda.
- **Text-to-Speech (TTS)**: Menyuarakan hasil terjemahan untuk memfasilitasi komunikasi dua arah yang lancar.
- **100% Offline**: Privasi pengguna terjaga karena seluruh pemrosesan gambar dan AI dilakukan *on-device*.
- **Desain Aksesibel**: Antarmuka pengguna dirancang dengan kontras tinggi demi kenyamanan visual pengguna.

## 🏗️ Arsitektur & Teknologi

Aplikasi ini dibangun menggunakan **Flutter (Dart)** untuk sisi *front-end* dan **TensorFlow Lite (Google Teachable Machine)** untuk model klasifikasi gambar (Image Classification).

Berikut adalah *engineering highlights* yang kami terapkan untuk mencapai performa optimal:

1. **⚡ On-Device Processing**
   Inferensi AI berjalan 100% secara lokal (*offline*). Hal ini tidak hanya menjaga privasi data pengguna, tetapi juga menghasilkan latensi sekecil mungkin yang krusial untuk pengalaman penerjemahan *real-time*.

2. **🧵 Dart Isolates (Multithreading)**
   Pemrosesan model AI yang berat dipisahkan dari *Main Thread* ke *Background Isolate*. Arsitektur ini memastikan UI kamera tetap mulus di **60 FPS** tanpa *stuttering* atau *memory leak*, meskipun inferensi terus berjalan di latar belakang.

3. **📐 Center Crop Algorithm & Precise UV Mapping**
   Menerapkan algoritma pra-pemrosesan di mana *frame* `YUV420` dari kamera secara matematis di-*crop* persis di tengah menjadi rasio **1:1** sebelum di-*resize* menjadi tensor `224x224`. Algoritma ini mencegah distorsi gambar (*stretching*) dan memetakan matriks piksel secara *pixel-perfect* di tengah rotasi matriks, sehingga memaksimalkan akurasi deteksi model.

4. **🎨 High-Contrast UI**
   Mengadopsi prinsip desain inklusif dengan menggunakan kombinasi warna *Navy Blue* (`#0A192F`) dan *Primary Yellow* (`#FFD700`). Skema warna ini memberikan tingkat kontras tinggi, membuat teks dan elemen UI mudah dibaca oleh berbagai kalangan.

## 🚀 Persyaratan & Cara Instalasi

Pastikan Anda telah menginstal [Flutter SDK](https://flutter.dev/docs/get-started/install) di mesin Anda.

1. **Clone repositori ini:**
   ```bash
   git clone https://github.com/username/signbridge.git
   cd signbridge
   ```

2. **Unduh seluruh dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di perangkat fisik Android / iOS:**
   *(Catatan: Sangat disarankan menggunakan perangkat fisik, bukan emulator, karena aplikasi membutuhkan fitur kamera)*
   ```bash
   flutter run
   ```

## 📂 Struktur Direktori Utama

```text
signbridge/
├── assets/
│   ├── icons/               # Ikon aplikasi
│   ├── labels.txt           # Label kelas AI (Kosong, Halo, Terimakasih, dll.)
│   └── model_unquant.tflite # Model TensorFlow Lite
├── lib/
│   ├── main.dart            # Entry point aplikasi
│   └── screens/
│       └── main_screen.dart # Logika utama UI, Image Processing & Isolate
└── pubspec.yaml             # Konfigurasi proyek & dependensi
```

## 👨‍💻 Tim Pengembang

Proyek ini dikembangkan oleh mahasiswa **Politeknik Negeri Indramayu** untuk ajang kompetisi UNITY #14:

- **Lesmana Adhi Kusuma**
- **Firly Alam Sudrajat**
- **Virna Nanju Fernanda**

---
<div align="center">
  <p>Dibuat dengan ❤️ untuk aksesibilitas yang lebih baik.</p>
</div>
