<div align="center">

# 🔐 AbsensiKu Secure

### Aplikasi Absensi Modern dengan Enkripsi Triple DES

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Security](https://img.shields.io/badge/Encryption-3DES-red?style=for-the-badge&logo=shield&logoColor=white)]()
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge&logo=android)](https://flutter.dev)

> *Kehadiran tercatat, data terlindungi — sistem absensi dengan lapisan keamanan enkripsi Triple DES.*

<br/>

![AbsensiKu Banner](https://placehold.co/900x300/1B1F3B/00F5FF?text=🔐+ABSENSI+SECURE&font=montserrat)

</div>

---

## 📖 Tentang Aplikasi

**AbsensiKu Secure** adalah aplikasi absensi berbasis Flutter yang mengutamakan keamanan data karyawan. Setiap transaksi absensi — mulai dari data lokasi, waktu, hingga identitas pengguna — dienkripsi menggunakan algoritma **Triple DES (3DES / TDEA)** sebelum dikirim ke server maupun disimpan secara lokal. Dirancang untuk instansi, sekolah, dan perusahaan yang peduli terhadap privasi dan integritas data kehadiran.

---

## 🛡️ Keamanan: Triple DES (3DES)

```
Data Absensi  →  [Enkripsi 3DES Key1]  →  [Dekripsi 3DES Key2]  →  [Enkripsi 3DES Key3]  →  Ciphertext Aman
```

**Mengapa Triple DES?**

| Aspek | Keterangan |
|-------|------------|
| 🔑 **Panjang Kunci** | 112-bit hingga 168-bit efektif |
| 🔄 **Proses** | Enkripsi → Dekripsi → Enkripsi (EDE) |
| 🧱 **Block Size** | 64-bit per blok |
| 🛡️ **Mode** | CBC (Cipher Block Chaining) dengan IV acak |
| 📦 **Data Dienkripsi** | Token, payload absensi, data biometrik hash |

> ⚠️ Semua komunikasi API menggunakan HTTPS + payload terenkripsi 3DES untuk perlindungan berlapis.

---

## ✨ Fitur Unggulan

| Fitur | Deskripsi |
|-------|-----------|
| 🔐 **Enkripsi 3DES** | Seluruh data absensi dienkripsi end-to-end |
| 🧬 **Verifikasi Biometrik** | Sidik jari / Face ID sebagai autentikasi masuk |
| 📍 **Absensi Berbasis GPS** | Validasi lokasi dengan geofencing radius kantor |
| 🕐 **Real-time Clock** | Timestamp NTP terverifikasi, anti-manipulasi waktu |
| 📊 **Laporan Kehadiran** | Dashboard lengkap dengan ekspor PDF & Excel |
| 👤 **Manajemen Karyawan** | CRUD karyawan, divisi, dan jadwal kerja |
| 📵 **Anti-Pemalsuan** | Deteksi GPS spoofing & emulator |

---

## 📱 Screenshot

<div align="center">

| Login | Dashboard | Absen | Laporan |
|:-----:|:---------:|:-----:|:-------:|
| ![Login](https://placehold.co/200x400/1B1F3B/00F5FF?text=🔐+Login) | ![Dashboard](https://placehold.co/200x400/12263A/00F5FF?text=📊+Dashboard) | ![Absen](https://placehold.co/200x400/1B2838/00F5FF?text=✅+Absen) | ![Laporan](https://placehold.co/200x400/0D1B2A/00F5FF?text=📋+Laporan) |

</div>

---

## 🔄 Alur Kerja Enkripsi

```
┌─────────────────────────────────────────────────────────────┐
│                     ALUR ABSENSI AMAN                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Pengguna]                                                 │
│      │                                                      │
│      ▼                                                      │
│  Biometrik / PIN  ──►  Verifikasi Lokal                     │
│      │                                                      │
│      ▼                                                      │
│  Data Absensi (waktu, lokasi, user_id)                      │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────────────────┐                           │
│  │   Enkripsi Triple DES       │                           │
│  │   Key: dari Secure Storage  │                           │
│  │   Mode: CBC + IV acak       │                           │
│  └────────────┬────────────────┘                           │
│               │                                             │
│               ▼                                             │
│  Payload Terenkripsi  ──►  HTTPS  ──►  Server               │
│                                            │                │
│                                            ▼                │
│                                    Dekripsi di Server       │
│                                            │                │
│                                            ▼                │
│                                    Simpan ke Database       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Arsitektur Proyek


## 💻 Implementasi Triple DES

## 🚀 Cara Memulai

### Prasyarat

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `>=3.0.0`
- Dart `>=3.0.0`
- Android Studio / VS Code
- Android `>=6.0` / iOS `>=12.0`

### Instalasi

**1. Clone repositori**
```bash
git clone https://github.com/username/absensi-secure.git
cd absensi-secure
```

**2. Install dependensi**
```bash
flutter pub get
```

**3. Konfigurasi environment**
```bash
cp .env.example .env
```

Edit `.env`:
```env
BASE_URL=https://api.absensimu.id
DES_SECRET_KEY=your_24_char_secret_key_here
DES_IV_SEED=your_iv_seed
MAPS_API_KEY=your_google_maps_key
GEOFENCE_RADIUS_METER=100
```

**4. Jalankan aplikasi**
```bash
flutter run
```

**5. Build produksi**
```bash
# Android APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Android App Bundle
flutter build appbundle --release --obfuscate

# iOS
flutter build ios --release
```

> 💡 Flag `--obfuscate` direkomendasikan agar logika enkripsi tidak mudah di-reverse engineer.

---

## 📦 Dependensi Utama

```yaml
dependencies:
  flutter_bloc: ^8.1.3           # State management
  dio: ^5.3.2                    # HTTP client
  encrypt: ^5.0.3                # Enkripsi AES/3DES
  flutter_secure_storage: ^9.0.0 # Simpan kunci enkripsi aman
  local_auth: ^2.1.8             # Biometrik (sidik jari/wajah)
  geolocator: ^10.1.0            # GPS & geofencing
  camera: ^0.10.5                # Selfie saat absen
  hive: ^2.2.3                   # Database lokal terenkripsi
  ntp: ^2.0.0                    # Sinkronisasi waktu NTP
  flutter_local_notifications: ^16.1.0
  pointycastle: ^3.7.3           # Kriptografi tambahan

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2
```

---

## 🧪 Testing

```bash
# Jalankan semua test
flutter test

# Test khusus modul keamanan
flutter test test/security/triple_des_test.dart

# Test dengan coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Contoh unit test enkripsi:

```dart
void main() {
  group('TripleDES Encryption', () {
    final service = TripleDESService();
    const key = 'my_secret_key_24chars!!';

    test('enkripsi dan dekripsi menghasilkan teks asli', () {
      const plainText = 'user_id:001|2024-01-15T08:00:00Z';
      final encrypted = service.encrypt(plainText, key);
      final decrypted = service.decrypt(encrypted, key);
      expect(decrypted, equals(plainText));
    });

    test('hasil enkripsi selalu berbeda (karena IV acak)', () {
      const plainText = 'data absensi sama';
      final enc1 = service.encrypt(plainText, key);
      final enc2 = service.encrypt(plainText, key);
      expect(enc1, isNot(equals(enc2)));
    });
  });
}
```

---

## 🔒 Praktik Keamanan

- ✅ Kunci enkripsi disimpan di **Secure Storage** (Keychain iOS / Keystore Android)
- ✅ IV (Initialization Vector) dibuat **acak setiap sesi**
- ✅ Komunikasi API wajib menggunakan **HTTPS/TLS 1.3**
- ✅ Token sesi memiliki **waktu kedaluwarsa** (expiry)
- ✅ Deteksi **root/jailbreak** device
- ✅ Deteksi **GPS spoofing** dan emulator
- ✅ **Obfuscation** kode saat build produksi
- ✅ Log tidak menyimpan data sensitif (no PII in logs)

---

## 🤝 Kontribusi

1. **Fork** repositori ini
2. Buat **branch** baru (`git checkout -b fitur/nama-fitur`)
3. **Commit** perubahan (`git commit -m 'feat: tambah fitur X'`)
4. **Push** ke branch (`git push origin fitur/nama-fitur`)
5. Buka **Pull Request**

> 🔐 Untuk perubahan pada modul keamanan, harap sertakan analisis dampak keamanan di PR.

---

## 📄 Lisensi

Didistribusikan di bawah lisensi **MIT**. Lihat [`LICENSE`](LICENSE) untuk informasi lebih lanjut.

---

## 👨‍💻 Tim Pengembang

<div align="center">

| Avatar | Nama | Peran |
|:------:|:----:|:-----:|
| 👤 | **Ary Subakti** | Lead Developer & Security |
| 👤 | **Erlinda Amira Putri Sudarmono	2401020021** | UI/UX Designer |
| 👤 | **Rismayanti** | Backend & API |

</div>

---

<div align="center">

**Dibuat dengan 🔐 & ❤️ — Keamanan bukan fitur tambahan, tapi fondasi utama.**

</div>
