import 'realtime_database_service.dart';
import 'triple_des_service.dart';

class BarcodeService {
  BarcodeService({RealtimeDatabaseService? databaseService})
      : _databaseService = databaseService ?? RealtimeDatabaseService();

  final RealtimeDatabaseService _databaseService;

  Future<String?> generateNewSession({
    required int adminId,
    required String adminUid,
    required String status,
    required int durationMinutes,
  }) async {
    final now = DateTime.now();
    final tanggal =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final jam =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final randomKey = TripleDesService.generateRandomKey(8);

    final plainPayload = TripleDesService.createBarcodePayload(
      adminId: adminId,
      tanggal: tanggal,
      jam: jam,
      status: status,
      randomKey: randomKey,
    );

    final cipherText = TripleDesService.encryptData(plainPayload);

    await _databaseService.createBarcodeSession(
      adminUid: adminUid,
      adminId: adminId,
      kode: cipherText,
      durationMinutes: durationMinutes,
    );

    return cipherText;
  }

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
