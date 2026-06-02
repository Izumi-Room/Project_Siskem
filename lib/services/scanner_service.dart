import 'package:intl/intl.dart';

import '../models/user_model.dart';
import 'barcode_service.dart';
import 'realtime_database_service.dart';
import 'triple_des_service.dart';

class ScannerService {
  ScannerService({
    RealtimeDatabaseService? databaseService,
    BarcodeService? barcodeService,
  })  : _databaseService = databaseService ?? RealtimeDatabaseService(),
        _barcodeService = barcodeService ?? BarcodeService();

  final RealtimeDatabaseService _databaseService;
  final BarcodeService _barcodeService;

  // ── Metode Utama: Proses QR yang di-scan ────────────────────────────────

  /// Memproses string yang di-scan dari QR Code.
  ///
  /// Mendukung dua format:
  /// 1. **qrId** (Firebase push key) — validasi 5 langkah via server
  /// 2. **ciphertext 3DES** (format lama) — backward compatibility
  ///
  /// Mengembalikan map:
  /// - `status`: 'success' | 'error'
  /// - `message`: String
  /// - `location`: String? (jika sukses)
  /// - `statusAbsensi`: String? (jika sukses)
  Future<Map<String, dynamic>> processScannedQR({
    required UserModel student,
    required String scannedValue,
  }) async {
    final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // ── Format Baru: qrId (Firebase push key) ───────────────────────────
    if (_barcodeService.isQrId(scannedValue)) {
      return _processQrId(
        student: student,
        qrId: scannedValue,
        tanggal: tanggal,
      );
    }

    // ── Format Lama: ciphertext 3DES (backward compatibility) ───────────
    return _processLegacyCipherText(
      student: student,
      cipherText: scannedValue,
      tanggal: tanggal,
    );
  }

  // ── Proses qrId (Format Baru, Aman) ─────────────────────────────────────

  Future<Map<String, dynamic>> _processQrId({
    required UserModel student,
    required String qrId,
    required String tanggal,
  }) async {
    // Buat ciphertext 3DES untuk record absensi (enkripsi data user)
    final jam = DateFormat('HH:mm').format(DateTime.now());
    final randomKey = TripleDesService.generateRandomKey(8);
    final plainPayload = TripleDesService.createAttendancePayload(
      userId: student.id,
      sessionId: qrId,
      tanggal: tanggal,
      jam: jam,
      status: 'pending', // akan diisi dari qrData.status
      randomKey: randomKey,
    );
    final cipherText = TripleDesService.encryptData(plainPayload);

    // Validasi 5 langkah + simpan (atomic via server)
    final result = await _databaseService.validateAndSubmitAttendance(
      user: student,
      qrId: qrId,
      cipherText: cipherText,
      tanggal: tanggal,
    );

    if (result['valid'] == true) {
      final qrData = result['qrData'];
      return {
        'status': 'success',
        'message': 'Absensi berhasil dicatat.',
        'location': qrData?.location ?? '-',
        'statusAbsensi': qrData?.status ?? 'Hadir',
      };
    }

    return {
      'status': 'error',
      'message': result['message'] ?? 'Validasi gagal.',
    };
  }

  // ── Proses Ciphertext Lama (Backward Compatibility) ─────────────────────

  Future<Map<String, dynamic>> _processLegacyCipherText({
    required UserModel student,
    required String cipherText,
    required String tanggal,
  }) async {
    // Dekripsi QR lama
    final parsedQR = _barcodeService.parseScannedQR(cipherText);
    if (parsedQR == null) {
      return {
        'status': 'error',
        'message': 'Format QR tidak didukung atau kunci enkripsi salah.',
      };
    }

    final adminId = parsedQR['admin_id'].toString();
    final jam = parsedQR['jam'] as String;
    final status = parsedQR['status'] as String;
    final randomKey = parsedQR['random_key'] as String;

    // Cek absensi hari ini (anti-cheat untuk format lama)
    final alreadyAbsen =
        await _databaseService.hasAttendanceToday(student.uid, tanggal);
    if (alreadyAbsen) {
      return {
        'status': 'error',
        'message':
            'Anda sudah melakukan absensi hari ini. Tidak dapat absen dua kali.',
      };
    }

    // Buat ciphertext absensi
    final attendancePlain = TripleDesService.createAttendancePayload(
      userId: student.id,
      sessionId: adminId,
      tanggal: tanggal,
      jam: jam,
      status: status,
      randomKey: randomKey,
    );
    final attendanceCipher = TripleDesService.encryptData(attendancePlain);

    // Simpan ke attendance node (aman, 1x per hari)
    try {
      await _databaseService.saveAttendanceSecure(
        user: student,
        qrId: adminId,
        location: 'Lokasi QR Lama',
        status: status,
        tanggal: tanggal,
        cipherText: attendanceCipher,
      );

      return {
        'status': 'success',
        'message': 'Absensi berhasil dicatat.',
        'location': 'Lokasi QR Lama',
        'statusAbsensi': status,
      };
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('permission-denied') ||
          msg.contains('Permission denied')) {
        return {
          'status': 'error',
          'message':
              'Anda sudah melakukan absensi hari ini (ditolak oleh server).',
        };
      }
      rethrow;
    }
  }

  // ── Legacy method (dipertahankan untuk kompatibilitas) ───────────────────

  @Deprecated('Gunakan processScannedQR() yang mendukung validasi server-side')
  Future<Map<String, dynamic>> submitAttendance({
    required UserModel student,
    required String adminId,
    required String tanggal,
    required String jam,
    required String status,
    required String randomKey,
  }) async {
    final plainPayload = TripleDesService.createAttendancePayload(
      userId: student.id,
      sessionId: adminId,
      tanggal: tanggal,
      jam: jam,
      status: status,
      randomKey: randomKey,
    );
    final cipherText = TripleDesService.encryptData(plainPayload);

    await _databaseService.saveAbsensi(
      user: student,
      sessionId: adminId,
      tanggal: tanggal,
      jam: jam,
      status: status,
      cipherText: cipherText,
    );

    return {'status': 'success'};
  }
}
