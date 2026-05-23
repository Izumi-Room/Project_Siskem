import 'dart:convert';
import 'package:dart_des/dart_des.dart';

class TripleDESHelper {
  // Triple DES (3DES) EDE CBC Security Configurations
  // The key must be exactly 24 bytes.
  // The IV must be exactly 8 bytes for DES block size.
  static final List<int> _keyBytes = 'AbsensiTripleDesSecure24'.codeUnits; // 24 bytes
  static final List<int> _ivBytes = '12345678'.codeUnits; // 8 bytes

  /// Encrypts plaintext using Triple DES CBC mode.
  /// Returns a Base64-encoded ciphertext.
  static String encrypt(String plainText) {
    try {
      final des3 = DES3(
        key: _keyBytes,
        mode: DESMode.CBC,
        iv: _ivBytes,
        paddingType: DESPaddingType.PKCS5,
      );
      final encrypted = des3.encrypt(utf8.encode(plainText));
      return base64Encode(encrypted);
    } catch (e) {
      throw Exception("Encryption failed: ${e.toString()}");
    }
  }

  /// Decrypts a Base64 ciphertext using Triple DES CBC mode.
  /// Returns the original plaintext.
  static String decrypt(String base64CipherText) {
    try {
      final des3 = DES3(
        key: _keyBytes,
        mode: DESMode.CBC,
        iv: _ivBytes,
        paddingType: DESPaddingType.PKCS5,
      );
      final decrypted = des3.decrypt(base64Decode(base64CipherText));
      return utf8.decode(decrypted);
    } catch (e) {
      throw Exception("Decryption failed: ${e.toString()}");
    }
  }
}
