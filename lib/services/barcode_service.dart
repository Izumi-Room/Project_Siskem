import '../models/barcode_model.dart';
import 'api_service.dart';
import 'triple_des_service.dart';

class BarcodeService {
  /// Generate a new QR attendance session (Admin side)
  /// Returns the generated ciphertext to be drawn as QR, or null if failed
  Future<String?> generateNewSession({
    required int adminId,
    required String status,
    required int durationMinutes,
  }) async {
    // 1. Prepare plain details
    final now = DateTime.now();
    final tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final jam =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final randomKey = TripleDesService.generateRandomKey(8);

    // Format: admin_id|tanggal|jam|status|random_key
    final plainPayload = TripleDesService.createBarcodePayload(
      adminId: adminId,
      tanggal: tanggal,
      jam: jam,
      status: status,
      randomKey: randomKey,
    );

    // 2. Encrypt using Triple DES
    final cipherText = TripleDesService.encryptData(plainPayload);

    // 3. Register session in database via API
    final response = await ApiService.post('generate_barcode.php', {
      'kode': cipherText,
      'minutes': durationMinutes,
    });

    if (response['status'] == 'success') {
      return cipherText;
    } else {
      return null;
    }
  }

  /// Parse the scanned QR content (Student side)
  /// Scanned text is the Triple DES ciphertext.
  /// Decrypts and returns parsed map or null if invalid.
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
