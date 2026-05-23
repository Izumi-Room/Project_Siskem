import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ApiService {
  /// General helper to perform POST requests dynamically using configured local IP
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final baseUrl = await AppConstants.getBaseUrl();
      final uri = Uri.parse('$baseUrl/$endpoint');

      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 7));

      return _processResponse(response);
    } catch (e) {
      return {
        "status": "error",
        "message":
            "Tidak dapat terhubung ke server lokal. Pastikan koneksi WiFi benar dan server aktif. Detail: $e",
      };
    }
  }

  /// General helper to perform GET requests dynamically using configured local IP
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    try {
      final baseUrl = await AppConstants.getBaseUrl();
      var urlString = '$baseUrl/$endpoint';

      if (params != null && params.isNotEmpty) {
        final query = Uri(queryParameters: params).query;
        urlString += '?$query';
      }

      final uri = Uri.parse(urlString);

      final response = await http
          .get(uri, headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 7));

      return _processResponse(response);
    } catch (e) {
      return {
        "status": "error",
        "message":
            "Tidak dapat terhubung ke server lokal. Pastikan koneksi WiFi benar. Detail: $e",
      };
    }
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    final body = response.body;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      } else {
        return {
          "status": "error",
          "message":
              json['message'] ??
              "Terjadi kesalahan server (${response.statusCode})",
        };
      }
    } catch (_) {
      return {
        "status": "error",
        "message": "Format respon server tidak valid.",
      };
    }
  }
}
