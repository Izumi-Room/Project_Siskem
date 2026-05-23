import 'dart:math';
import '../utils/encryption.dart';

class TripleDesService {
  /// Encrypt plaintext using Triple DES
  static String encryptData(String plainText) {
    return TripleDESHelper.encrypt(plainText);
  }

  /// Decrypt ciphertext using Triple DES
  static String decryptData(String cipherText) {
    return TripleDESHelper.decrypt(cipherText);
  }

  /// Generate a random alphanumeric key for salt / anti-replay attack protection
  static String generateRandomKey([int length = 8]) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// Helper to construct attendance plain text
  /// Format: user_id|session_id|tanggal|jam|status|random_key
  static String createAttendancePayload({
    required int userId,
    required String sessionId,
    required String tanggal,
    required String jam,
    required String status,
    required String randomKey,
  }) {
    return '$userId|$sessionId|$tanggal|$jam|$status|$randomKey';
  }

  /// Helper to construct barcode plain text (Admin side)
  /// Format: admin_id|tanggal|jam|status|random_key
  static String createBarcodePayload({
    required int adminId,
    required String tanggal,
    required String jam,
    required String status,
    required String randomKey,
  }) {
    return '$adminId|$tanggal|$jam|$status|$randomKey';
  }
}
