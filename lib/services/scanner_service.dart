import '../models/user_model.dart';
import 'realtime_database_service.dart';
import 'triple_des_service.dart';

class ScannerService {
  ScannerService({RealtimeDatabaseService? databaseService})
      : _databaseService = databaseService ?? RealtimeDatabaseService();

  final RealtimeDatabaseService _databaseService;

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
