import 'api_service.dart';
import 'triple_des_service.dart';

class ScannerService {
  /// Submit encrypted student attendance
  Future<Map<String, dynamic>> submitAttendance({
    required int studentId,
    required String adminId, // can act as session_id
    required String tanggal,
    required String jam,
    required String status,
    required String randomKey,
  }) async {
    // 1. Construct student-side plaintext attendance packet
    // Format: student_id|session_id|tanggal|jam|status|random_key
    final plainPayload = TripleDesService.createAttendancePayload(
      userId: studentId,
      sessionId: adminId,
      tanggal: tanggal,
      jam: jam,
      status: status,
      randomKey: randomKey,
    );

    // 2. Encrypt with Triple DES
    final cipherText = TripleDesService.encryptData(plainPayload);

    // 3. Post to PHP local API
    return await ApiService.post('absensi.php', {
      'user_id': studentId,
      'cipher_text': cipherText,
    });
  }
}
