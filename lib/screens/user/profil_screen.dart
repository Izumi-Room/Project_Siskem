import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfilScreen extends StatefulWidget {
  final UserModel user;

  const ProfilScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _authService = AuthService();

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar Akun"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Batal",
              style: TextStyle(color: AppConstants.textLight),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _authService.logout();
              Navigator.pop(context); // close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              "Keluar",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Avatar Card
          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConstants.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 80,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.user.nama,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "NIM. ${widget.user.nim ?? '-'}",
            style: const TextStyle(
              fontSize: 15,
              color: AppConstants.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 30),

          // Detail Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.mail_outline, "Email", widget.user.email),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.security,
                  "Role",
                  widget.user.role.toUpperCase(),
                ),
                const Divider(height: 24),
                _buildInfoRow(Icons.cloud_done, "Database", "Firebase Cloud"),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.lock,
                  "Enkripsi",
                  "Triple DES (3DES) EDE CBC",
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Logout Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              "KELUAR AKUN",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppConstants.secondaryColor),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppConstants.textLight,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppConstants.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
