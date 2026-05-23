import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const String userSessionKey = 'absensi_user_session';

  /// Authenticate user via PHP login endpoint
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('login.php', {
      'email': email,
      'password': password,
    });

    if (response['status'] == 'success' && response['user'] != null) {
      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      await saveUserSession(user);
    }
    return response;
  }

  /// Register student via PHP register endpoint
  Future<Map<String, dynamic>> register({
    required String nama,
    required String nim,
    required String email,
    required String password,
  }) async {
    return await ApiService.post('register.php', {
      'nama': nama,
      'nim': nim,
      'email': email,
      'password': password,
    });
  }

  /// Save logged-in user details locally
  Future<bool> saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(userSessionKey, jsonEncode(user.toJson()));
  }

  /// Retrieve current active user session
  Future<UserModel?> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(userSessionKey);
    if (jsonString == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Terminate session and clear user data
  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(userSessionKey);
  }
}
