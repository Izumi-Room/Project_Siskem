<div align="center">

# 🔐 Absensi Triple DES Offline

### Aplikasi Absensi QR Code dengan Enkripsi Triple DES

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![PHP](https://img.shields.io/badge/PHP-Local%20API-777BB4?style=for-the-badge&logo=php&logoColor=white)](https://www.php.net)
[![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)
[![Security](https://img.shields.io/badge/Encryption-Triple%20DES-red?style=for-the-badge&logo=shield&logoColor=white)]()

> Kehadiran tercatat, data terlindungi — sistem absensi berbasis QR Code dengan lapisan keamanan Triple DES.

<br/>

![Absensi Triple DES Banner](https://placehold.co/900x300/1565C0/FFFFFF?text=ABSENSI+TRIPLE+DES+OFFLINE&font=montserrat)

</div>

---

## 📖 Tentang Aplikasi

**Absensi Triple DES Offline** adalah aplikasi absensi berbasis Flutter yang dirancang untuk kebutuhan demo skripsi/tugas akhir. Aplikasi ini menggunakan **QR Code** sebagai media sesi absensi dan **Triple DES (3DES)** untuk mengenkripsi payload absensi sebelum data dikirim ke API PHP lokal.

Sistem berjalan dengan server lokal menggunakan **WAMP/XAMPP**. Admin dapat membuat sesi absensi dalam bentuk QR Code terenkripsi, lalu mahasiswa melakukan scan QR Code untuk mencatat kehadiran. Data yang tersimpan dapat ditinjau kembali melalui halaman riwayat dan halaman admin, lengkap dengan tampilan ciphertext serta hasil dekripsi untuk kebutuhan pembuktian kriptografi.

---

## 🛡️ Keamanan: Triple DES

```text
Plaintext Absensi -> Enkripsi Triple DES CBC -> Ciphertext Base64 -> API PHP -> Database
```

Implementasi enkripsi pada aplikasi:

| Aspek | Keterangan |
| --- | --- |
| Algoritma | Triple DES / 3DES |
| Mode | CBC |
| Padding | PKCS5 |
| Output | Base64 Ciphertext |
| Key | 24 byte |
| IV | 8 byte |
| Data QR | `admin_id`, tanggal, jam, status, `random_key` |
| Data Absensi | `user_id`, session, tanggal, jam, status, `random_key` |

> Catatan: project ini ditujukan untuk pembelajaran dan demo. Untuk production, key dan IV sebaiknya tidak disimpan langsung di source code.

---

## ✨ Fitur Unggulan

| Fitur | Deskripsi |
| --- | --- |
| 🔐 Enkripsi 3DES | Payload QR Code dan data absensi dienkripsi menggunakan Triple DES |
| 📱 Scan QR Code | Mahasiswa melakukan absensi dengan kamera melalui QR Code |
| 🧾 Generate QR | Admin membuat sesi absensi dalam bentuk QR Code terenkripsi |
| ⏱️ Durasi Sesi | Admin dapat menentukan masa berlaku QR Code |
| 👥 Multi Role | Tampilan dan fitur dipisah antara admin dan mahasiswa |
| 📚 Riwayat Absensi | Mahasiswa dapat melihat riwayat kehadiran |
| 🧑‍🎓 Data Mahasiswa | Admin dapat melihat daftar mahasiswa terdaftar |
| 🔎 Detail Kriptografi | Ciphertext dan hasil dekripsi dapat dilihat untuk pembuktian |
| 🌐 Server Lokal | Terhubung ke API PHP lokal melalui IP server yang dapat dikonfigurasi |
| ⌨️ Mode Demo | Ciphertext dapat diinput manual untuk pengujian emulator |

---

## 📱 Screenshot

<div align="center">

| Login | Admin | Generate QR | Scan QR |
|:---:|:---:|:---:|:---:|
| ![Login](https://placehold.co/200x400/1565C0/FFFFFF?text=Login) | ![Admin](https://placehold.co/200x400/1E88E5/FFFFFF?text=Admin) | ![Generate QR](https://placehold.co/200x400/00B0FF/FFFFFF?text=Generate+QR) | ![Scan QR](https://placehold.co/200x400/0F172A/FFFFFF?text=Scan+QR) |

| Riwayat | Data User | Data Absensi | Detail 3DES |
|:---:|:---:|:---:|:---:|
| ![Riwayat](https://placehold.co/200x400/1565C0/FFFFFF?text=Riwayat) | ![Data User](https://placehold.co/200x400/1E88E5/FFFFFF?text=Data+User) | ![Data Absensi](https://placehold.co/200x400/00B0FF/FFFFFF?text=Absensi) | ![Detail 3DES](https://placehold.co/200x400/0F172A/FFFFFF?text=3DES) |

</div>

> Ganti placeholder di atas dengan screenshot asli agar repository terlihat lebih profesional.

---

## 🔄 Alur Kerja Sistem

```text
┌─────────────────────────────────────────────────────────────┐
│                    ALUR ABSENSI TERENKRIPSI                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Admin]                                                    │
│     │                                                       │
│     ▼                                                       │
│  Pilih status dan durasi absensi                            │
│     │                                                       │
│     ▼                                                       │
│  Payload sesi: admin_id|tanggal|jam|status|random_key       │
│     │                                                       │
│     ▼                                                       │
│  Enkripsi Triple DES                                        │
│     │                                                       │
│     ▼                                                       │
│  Ciphertext ditampilkan sebagai QR Code                     │
│                                                             │
│  [Mahasiswa]                                                │
│     │                                                       │
│     ▼                                                       │
│  Scan QR Code                                               │
│     │                                                       │
│     ▼                                                       │
│  Dekripsi data sesi absensi                                 │
│     │                                                       │
│     ▼                                                       │
│  Payload absensi: user_id|session|tanggal|jam|status|key    │
│     │                                                       │
│     ▼                                                       │
│  Enkripsi Triple DES                                        │
│     │                                                       │
│     ▼                                                       │
│  Kirim ciphertext ke API PHP lokal                          │
│     │                                                       │
│     ▼                                                       │
│  Simpan data absensi ke database                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Arsitektur Project

```text
Flutter App
├── Auth
│   ├── Login
│   ├── Register
│   └── Session Local Storage
├── Admin
│   ├── Generate QR Code
│   ├── Data Mahasiswa
│   └── Data Absensi
├── Mahasiswa
│   ├── Scan QR Code
│   ├── Input Ciphertext Manual
│   ├── Riwayat Absensi
│   └── Profil
├── Services
│   ├── API Service
│   ├── Auth Service
│   ├── Barcode Service
│   ├── Scanner Service
│   └── Triple DES Service
└── PHP Local API
    ├── Login/Register
    ├── Generate Barcode
    ├── Submit Absensi
    └── Get Data Absensi
```

---

## 📁 Struktur Folder

```text
lib/
  main.dart
  models/
    absensi_model.dart
    admin_model.dart
    barcode_model.dart
    user_model.dart
  screens/
    admin/
      admin_home.dart
      data_absensi.dart
      data_user.dart
      generate_barcode.dart
      laporan_screen.dart
    auth/
      login_screen.dart
      register_screen.dart
    user/
      home_screen.dart
      profil_screen.dart
      riwayat_screen.dart
      scan_screen.dart
  services/
    api_service.dart
    auth_service.dart
    barcode_service.dart
    scanner_service.dart
    triple_des_service.dart
  utils/
    constants.dart
    custom_des.dart
    encryption.dart
  widgets/
    custom_button.dart
    custom_textfield.dart
```

---

## 💻 Implementasi Triple DES

Payload sesi absensi admin:

```text
admin_id|tanggal|jam|status|random_key
```

Payload absensi mahasiswa:

```text
user_id|session_id|tanggal|jam|status|random_key
```

Contoh helper pada Flutter:

```dart
final cipherText = TripleDesService.encryptData(plainPayload);
final plainText = TripleDesService.decryptData(cipherText);
```

File utama terkait enkripsi:

```text
lib/services/triple_des_service.dart
lib/utils/encryption.dart
lib/utils/custom_des.dart
```

---

## 🚀 Cara Memulai

### Prasyarat

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Android Studio atau Visual Studio Code
- WAMP/XAMPP
- MySQL/MariaDB
- Android emulator atau perangkat Android fisik

### Instalasi

**1. Clone repository**

```bash
git clone https://github.com/Izumi-Room/Project_Siskem.git
cd Project_Siskem
```

**2. Install dependency Flutter**

```bash
flutter pub get
```

**3. Siapkan API PHP lokal**

Letakkan folder API pada direktori web server:

```text
C:\wamp64\www\absensi_api
```

atau:

```text
C:\xampp\htdocs\absensi_api
```

**4. Jalankan server lokal**

- Aktifkan Apache.
- Aktifkan MySQL.
- Import database yang digunakan project.
- Sesuaikan koneksi database pada `config.php`.

**5. Konfigurasi IP server**

File konfigurasi:

```text
lib/utils/constants.dart
```

Default IP:

```dart
static const String defaultIp = '192.168.137.1';
```

Jika menggunakan HP fisik, pastikan HP dan laptop berada pada jaringan yang sama.

**6. Jalankan aplikasi**

```bash
flutter run
```

---

## 🌐 Endpoint API

Base URL:

```text
http://<ip-server>/absensi_api
```

Daftar endpoint:

| Endpoint | Fungsi |
| --- | --- |
| `login.php` | Login admin/mahasiswa |
| `register.php` | Registrasi mahasiswa |
| `generate_barcode.php` | Membuat sesi QR Code absensi |
| `absensi.php` | Mengirim data absensi mahasiswa |
| `get_absensi_all.php` | Mengambil seluruh data absensi |
| `get_riwayat.php` | Mengambil riwayat absensi mahasiswa |
| `get_users.php` | Mengambil data mahasiswa |
| `get_profile.php` | Mengambil data profil pengguna |

---

## 📦 Dependensi Utama

```yaml
dependencies:
  flutter:
    sdk: flutter
  mobile_scanner: ^5.1.1
  qr_flutter: ^4.1.0
  http: ^1.2.1
  shared_preferences: ^2.2.3
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 🧪 Testing

Jalankan test Flutter:

```bash
flutter test
```

Jalankan analisis kode:

```bash
flutter analyze
```

---

## 📱 Build APK

Build APK release:

```bash
flutter build apk --release
```

Hasil build:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔒 Praktik Keamanan yang Disarankan

- Simpan key enkripsi di tempat yang lebih aman, bukan hardcoded di source code.
- Gunakan HTTPS jika API dipublikasikan di server online.
- Tambahkan validasi masa berlaku QR Code di sisi server.
- Tambahkan proteksi replay attack berbasis `random_key` atau token sesi.
- Hindari menyimpan data sensitif pada log aplikasi.
- Gunakan obfuscation saat build release.

Build release dengan obfuscation:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

---

## 🤝 Kontribusi

1. Fork repository ini.
2. Buat branch baru.
3. Commit perubahan.
4. Push ke branch.
5. Buat Pull Request.

Contoh:

```bash
git checkout -b fitur/nama-fitur
git commit -m "feat: tambah fitur baru"
git push origin fitur/nama-fitur
```

---

## 👨‍💻 Tim Pengembang

<div align="center">

| Nama | Peran |
|:---:|:---:|
| Ary Subakti | Lead Developer & Security |
| Erlinda Amira Putri Sudarmono | UI/UX Designer |
| Rismayanti | Backend & API |

</div>

---

## 📄 Lisensi

Project ini dibuat untuk kebutuhan pembelajaran, penelitian, dan pengembangan tugas akhir. Silakan sesuaikan lisensi repository sesuai kebutuhan.

---

<div align="center">

**Dibuat dengan fokus pada keamanan data absensi dan pembelajaran kriptografi.**

</div>
