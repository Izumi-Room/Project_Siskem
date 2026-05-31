<div align="center">

# Absensi Triple DES 

### Sistem absensi QR Code dengan Firebase dan enkripsi Triple DES

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Realtime%20DB-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Security](https://img.shields.io/badge/Encryption-Triple%20DES-B91C1C?style=for-the-badge)](#catatan-keamanan)

Data kehadiran tidak hanya dicatat, tetapi juga diproses melalui lapisan enkripsi untuk kebutuhan pembuktian keamanan data.

</div>

---

## Gambaran Project

**Absensi Triple DES** adalah aplikasi absensi berbasis Flutter untuk kebutuhan demo skripsi, tugas akhir, atau pembelajaran kriptografi terapan. Aplikasi ini menggabungkan QR Code sebagai media sesi absensi, Firebase sebagai backend cloud, dan Triple DES sebagai mekanisme enkripsi payload.

Alur utamanya sederhana: admin membuat sesi absensi, aplikasi menghasilkan QR Code terenkripsi, mahasiswa memindai kode tersebut, lalu data kehadiran disimpan ke Firebase Realtime Database.

> Project ini bersifat edukatif. Untuk production, aturan database, manajemen key, validasi sesi, dan proteksi replay attack perlu diperkuat.

## Highlight

| Area | Kemampuan |
| --- | --- |
| Autentikasi | Login dan register menggunakan Firebase Authentication |
| Role pengguna | Dashboard dipisahkan untuk admin dan mahasiswa |
| QR Code | Admin membuat QR Code untuk sesi absensi |
| Scanner | Mahasiswa memindai QR Code dengan kamera perangkat |
| Enkripsi | Payload sesi dan absensi diproses menggunakan Triple DES |
| Database | Data pengguna, sesi, dan absensi tersimpan di Firebase Realtime Database |
| Lokasi | Koordinat absensi ikut disimpan jika izin lokasi diberikan |
| Demo mode | Ciphertext dapat diuji manual saat memakai emulator |
| Riwayat | Mahasiswa dapat melihat riwayat kehadiran |
| Monitoring | Admin dapat melihat data mahasiswa dan rekap absensi |

## Stack Teknologi

| Layer | Teknologi |
| --- | --- |
| Mobile app | Flutter, Dart |
| Authentication | Firebase Authentication |
| Database | Firebase Realtime Database |
| Storage | Firebase Storage |
| QR scanner | `mobile_scanner` |
| QR generator | `qr_flutter` |
| Lokasi | `geolocator` |
| Format tanggal | `intl` |
| Enkripsi | Triple DES custom service |

## Cara Kerja

```text
ADMIN
  Login
    |
    v
  Buat sesi absensi
    |
    v
  Payload: admin_id|tanggal|jam|status|random_key
    |
    v
  Enkripsi Triple DES
    |
    v
  QR Code ditampilkan dan sesi disimpan ke Firebase

MAHASISWA
  Login
    |
    v
  Scan QR Code
    |
    v
  Dekripsi payload sesi
    |
    v
  Payload: user_id|session_id|tanggal|jam|status|random_key
    |
    v
  Enkripsi Triple DES
    |
    v
  Data absensi disimpan ke Firebase
```

## Format Payload Enkripsi

Payload sesi yang dibuat admin:

```text
admin_id|tanggal|jam|status|random_key
```

Payload absensi yang dikirim mahasiswa:

```text
user_id|session_id|tanggal|jam|status|random_key
```

Contoh pemanggilan service:

```dart
final cipherText = TripleDesService.encryptData(plainPayload);
final plainText = TripleDesService.decryptData(cipherText);
```

File terkait:

| File | Fungsi |
| --- | --- |
| `lib/services/triple_des_service.dart` | Interface utama enkripsi, dekripsi, dan pembentukan payload |
| `lib/utils/encryption.dart` | Helper enkripsi Triple DES |
| `lib/utils/custom_des.dart` | Implementasi pendukung algoritma DES |

## Fitur Berdasarkan Role

### Admin

- Login sebagai admin.
- Membuat sesi absensi berdasarkan status dan durasi.
- Menampilkan QR Code terenkripsi.
- Melihat daftar mahasiswa.
- Melihat data absensi.
- Melihat laporan atau rekap data kehadiran.

### Mahasiswa

- Register dan login akun.
- Scan QR Code absensi.
- Input ciphertext manual untuk kebutuhan demo.
- Mengirim absensi berdasarkan sesi aktif.
- Melihat riwayat absensi.
- Melihat profil pengguna.

## Struktur Folder

```text
lib/
  firebase_options.dart
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
    auth_service.dart
    barcode_service.dart
    realtime_database_service.dart
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

## Skema Firebase Realtime Database

```text
users/
  {uid}/
    uid
    nama
    nim
    email
    role
    timestamp

barcode/
  {session_id}/
    id
    admin_uid
    admin_id
    kode
    expired_at
    expired_at_ms
    created_at
    duration_minutes

absensi/
  {absensi_id}/
    id
    user_id
    user_uid
    session_id
    nama
    nim
    email
    tanggal
    jam
    status
    cipher_text
    created_at
    created_at_text
    latitude
    longitude
```

## Persiapan Firebase

1. Buat project Firebase.
2. Aktifkan **Authentication** dengan provider **Email/Password**.
3. Aktifkan **Realtime Database**.
4. Tambahkan aplikasi Android, iOS, atau Web sesuai target build.
5. Unduh konfigurasi Firebase sesuai platform:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Multiplatform: generate `lib/firebase_options.dart` menggunakan FlutterFire CLI.
6. Pastikan URL database sesuai project Firebase yang dipakai.

Default URL database berada di:

```dart
lib/services/realtime_database_service.dart
```

Override URL database saat menjalankan aplikasi:

```bash
flutter run --dart-define=FIREBASE_DATABASE_URL=https://your-project-id-default-rtdb.firebaseio.com
```

## Quick Start

Clone repository:

```bash
git clone https://github.com/Izumi-Room/Project_Siskem.git
cd Project_Siskem
```

Install dependency:

```bash
flutter pub get
```

Jalankan aplikasi:

```bash
flutter run
```

## Testing

Jalankan test:

```bash
flutter test
```

Jalankan analisis kode:

```bash
flutter analyze
```

## Build APK

Build APK release:

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build release dengan obfuscation:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## Catatan Keamanan

- Jangan menyimpan key dan IV production langsung di source code.
- Batasi akses Firebase Realtime Database berdasarkan `auth.uid` dan `role`.
- Validasi masa berlaku QR Code pada layer database atau backend logic.
- Tambahkan proteksi replay attack berbasis session ID, nonce, atau `random_key`.
- Hindari mencetak plaintext, ciphertext, token, atau data sensitif ke log production.
- Gunakan konfigurasi Firebase resmi untuk setiap platform.
- Review permission lokasi sebelum aplikasi dirilis.

## Roadmap Pengembangan

| Status | Rencana |
| --- | --- |
| Selesai | Login, register, role admin dan mahasiswa |
| Selesai | Generate dan scan QR Code |
| Selesai | Penyimpanan absensi ke Firebase Realtime Database |
| Selesai | Riwayat absensi mahasiswa |
| Berikutnya | Validasi masa berlaku QR di sisi database atau backend |
| Berikutnya | Export laporan absensi |
| Berikutnya | Hardening rules Firebase |
| Berikutnya | Screenshot asli aplikasi di README |

## Kontribusi

1. Fork repository ini.
2. Buat branch fitur atau perbaikan.
3. Commit perubahan.
4. Push branch.
5. Buat pull request.

Contoh:

```bash
git checkout -b fitur/nama-fitur
git commit -m "feat: tambah fitur baru"
git push origin fitur/nama-fitur
```

## Tim Pengembang

| Nama | Peran |
| --- | --- |
| Ary Subakti | Lead Developer & Security |
| Erlinda Amira Putri Sudarmono | UI/UX Designer |
| Rismayanti | Backend & Database |

## Lisensi

Project ini dibuat untuk kebutuhan pembelajaran, penelitian, dan pengembangan tugas akhir. Sesuaikan lisensi repository dengan kebutuhan penggunaan.

---

<div align="center">

**Absensi sederhana, alur jelas, dan payload yang dapat dibuktikan melalui enkripsi.**

</div>
