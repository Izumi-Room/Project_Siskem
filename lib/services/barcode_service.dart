import 'realtime_database_service.dart';
import 'triple_des_service.dart';

class BarcodeService {
  BarcodeService({RealtimeDatabaseService? databaseService})
      : _databaseService = databaseService ?? RealtimeDatabaseService();

  final RealtimeDatabaseService _databaseService;

  // ── Generate QR Session (Admin) ──────────────────────────────────────────

  /// Membuat sesi QR baru di node `qr_codes`.
  ///
  /// Mengembalikan map berisi:
  /// - `qrId`: String — ID unik yang disimpan di Firebase (ini yang di-encode ke QR)
  /// - `cipherText`: String — ciphertext 3DES untuk ditampilkan (opsional/demo)
  Future<Map<String, String>?> generateNewSession({
    required int adminId,
    required String adminUid,
    required String status,
    required String location,
    required int durationMinutes,
  }) async {
    final now = DateTime.now();
    final tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final jam =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final randomKey = TripleDesService.generateRandomKey(8);

    // Buat ciphertext 3DES (untuk keperluan demo/tampilan)
    final plainPayload = TripleDesService.createBarcodePayload(
      adminId: adminId,
      tanggal: tanggal,
      jam: jam,
      status: status,
      randomKey: randomKey,
    );
    final cipherText = TripleDesService.encryptData(plainPayload);

    // Simpan ke node qr_codes dan dapatkan qrId
    final qrId = await _databaseService.createQrCode(
      adminUid: adminUid,
      location: location,
      status: status,
      durationMinutes: durationMinutes,
    );

    // Juga simpan ke node barcode lama (backward compatibility)
    await _databaseService.createBarcodeSession(
      adminUid: adminUid,
      adminId: adminId,
      kode: cipherText,
      durationMinutes: durationMinutes,
    );

    return {
      'qrId': qrId,
      'cipherText': cipherText,
    };
  }

  // ── Parse QR yang di-scan (User) ─────────────────────────────────────────

  /// Menentukan apakah string yang di-scan adalah qrId (node baru)
  /// atau ciphertext 3DES lama.
  ///
  /// Format qrId dari Firebase push key: dimulai dengan '-' dan panjang ~20 karakter.
  /// Ciphertext 3DES: Base64 string yang lebih panjang.
  bool isQrId(String scanned) {
    // Firebase push key: dimulai '-', panjang 20 karakter, hanya alphanumeric + '-' + '_'
    final pushKeyRegex = RegExp(r'^-[A-Za-z0-9_-]{19}$');
    return pushKeyRegex.hasMatch(scanned);
  }

  /// Parse ciphertext 3DES lama (backward compatibility).
  Map<String, dynamic>? parseScannedQR(String scannedCipherText) {
    try {
      final decrypted = TripleDesService.decryptData(scannedCipherText);
      final parts = decrypted.split('|');

      if (parts.length < 5) return null;

      return {
        'admin_id': int.parse(parts[0]),
        'tanggal': parts[1],
        'jam': parts[2],
        'status': parts[3],
        'random_key': parts[4],
      };
    } catch (_) {
      return null;
    }
  }
}
