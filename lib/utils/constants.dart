import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  // Theme Colors (Premium Blue & White Palette)
  static const Color primaryColor = Color(0xFF1565C0); // Dark Blue
  static const Color secondaryColor = Color(0xFF1E88E5); // Bright Blue
  static const Color accentColor = Color(0xFF00B0FF); // Light Blue
  static const Color backgroundColor = Color(0xFFF8FAFC); // Off-white/slate 50
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF1E293B); // Slate 800
  static const Color textLight = Color(0xFF64748B); // Slate 500

  // Fallback default IP
  static const String defaultIp = '192.168.137.1';
  static const String ipPrefsKey = 'absensi_server_ip';

  // Getter for Dynamic Base URL based on stored IP
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString(ipPrefsKey) ?? defaultIp;
    return 'http://$ip/absensi_api';
  }

  // Getter for stored IP
  static Future<String> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ipPrefsKey) ?? defaultIp;
  }

  // Setter for server IP
  static Future<bool> setServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(ipPrefsKey, ip.trim());
  }
}
