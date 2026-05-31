# Absensi Triple DES Offline

Aplikasi absensi berbasis Flutter yang menggunakan QR Code, Firebase, dan enkripsi Triple DES untuk mendukung demo sistem keamanan data absensi.

## Ringkasan

Absensi Triple DES Offline memisahkan alur kerja admin dan mahasiswa:

- Admin membuat sesi absensi dalam bentuk QR Code terenkripsi.
- Mahasiswa memindai QR Code untuk mengirim data kehadiran.
- Data pengguna, sesi, dan absensi disimpan di Firebase Realtime Database.
- Autentikasi menggunakan Firebase Authentication.
- Payload QR Code dan payload absensi diproses dengan Triple DES.

Project ini ditujukan untuk pembelajaran, penelitian, dan demo tugas akhir. Untuk penggunaan production, konfigurasi keamanan, manajemen key, validasi server-side, dan aturan Firebase perlu diperketat.

## Fitur

- Login dan register dengan Firebase Authentication.
- Session checker untuk mengarahkan pengguna ke dashboard sesuai role.
- Role admin dan mahasiswa.
- Generate QR Code untuk sesi absensi.
- Scan QR Code menggunakan kamera perangkat.
- Input ciphertext manual untuk kebutuhan demo atau emulator.
- Riwayat absensi mahasiswa.
- Data mahasiswa dan data absensi untuk admin.
- Penyimpanan data di Firebase Realtime Database.
- Penyimpanan lokasi absensi jika izin lokasi diberikan.
- Enkripsi dan dekripsi payload menggunakan Triple DES.

## Teknologi

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Firebase Realtime Database
- Firebase Storage
- mobile_scanner
- qr_flutter
- geolocator
- intl

## Alur Sistem

```text
Admin
  -> Login
  -> Pilih status dan durasi sesi
  -> Buat payload sesi
  -> Enkripsi Triple DES
  -> Tampilkan ciphertext sebagai QR Code
  -> Simpan sesi ke Firebase Realtime Database

Mahasiswa
  -> Login
  -> Scan QR Code
  -> Dekripsi payload sesi
  -> Buat payload absensi
  -> Enkripsi Triple DES
  -> Simpan absensi ke Firebase Realtime Database
  -> Lihat riwayat absensi
```

## Format Payload

Payload QR Code dari admin:

```text
admin_id|tanggal|jam|status|random_key
```

Payload absensi dari mahasiswa:

```text
user_id|session_id|tanggal|jam|status|random_key
```

Contoh penggunaan service:

```dart
final cipherText = TripleDesService.encryptData(plainPayload);
final plainText = TripleDesService.decryptData(cipherText);
```

File utama terkait enkripsi:

- `lib/services/triple_des_service.dart`
- `lib/utils/encryption.dart`
- `lib/utils/custom_des.dart`

## Struktur Project

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

Data utama disimpan pada node berikut:

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
2. Aktifkan Authentication dengan provider Email/Password.
3. Aktifkan Realtime Database.
4. Tambahkan aplikasi Android/iOS/Web sesuai target build.
5. Unduh file konfigurasi Firebase:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Web atau multiplatform: generate ulang `lib/firebase_options.dart` dengan FlutterFire CLI jika diperlukan.
6. Pastikan URL database sesuai dengan project Firebase.

Default URL database didefinisikan di:

```dart
lib/services/realtime_database_service.dart
```

Untuk override saat menjalankan aplikasi:

```bash
flutter run --dart-define=FIREBASE_DATABASE_URL=https://your-project-id-default-rtdb.firebaseio.com
```

## Instalasi

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

## Testing dan Analisis

Jalankan unit/widget test:

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

Output APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Build release dengan obfuscation:

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

## Catatan Keamanan

- Jangan menyimpan key dan IV production langsung di source code.
- Gunakan aturan Firebase Realtime Database yang membatasi akses berdasarkan `auth.uid` dan role.
- Validasi masa berlaku QR Code di sisi database/server logic.
- Tambahkan proteksi replay attack berbasis session ID atau `random_key`.
- Hindari mencetak ciphertext, plaintext, token, atau data sensitif ke log production.
- Gunakan HTTPS dan konfigurasi Firebase resmi untuk setiap platform.
- Review kembali permission lokasi sebelum rilis.

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
