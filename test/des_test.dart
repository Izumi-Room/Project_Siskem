import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:absensi_triple_des_offline/utils/custom_des.dart' as custom;

void main() {
  test('Pure Dart Triple DES Encryption and Decryption Verification', () {
    final key = utf8.encode('AbsensiTripleDesSecure24'); // 24 bytes
    final iv = utf8.encode('12345678'); // 8 bytes
    final plainText = '1|1|2026-05-23|20:45|Hadir|XYZ12345';
    
    // This is the mathematically correct standard Triple DES EDE CBC ciphertext
    // for the above plaintext, key, and IV.
    const expectedBase64 = 'YZBN10Ymuf2q72oB7cClzPBYGijNH8OA29mUlsTyibupd/ptAK93kA==';

    // 1. Initialize Custom DES3
    final customDes = custom.DES3(
      key: key,
      mode: custom.DESMode.CBC,
      iv: iv,
      paddingType: custom.DESPaddingType.PKCS7,
    );

    // 2. Test Encryption
    final customEncrypted = customDes.encrypt(utf8.encode(plainText));
    final customBase64 = base64Encode(customEncrypted);
    
    expect(customBase64, expectedBase64, reason: 'Encryption output should match standard 3DES output.');

    // 3. Test Decryption
    final customDecrypted = customDes.decrypt(customEncrypted);
    final customPlain = utf8.decode(customDecrypted);

    expect(customPlain, plainText, reason: 'Decrypted plaintext should match original plaintext.');
  });
}
