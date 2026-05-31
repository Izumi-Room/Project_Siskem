import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'generate_barcode.dart';
import 'data_user.dart';
import 'data_absensi.dart';
import 'laporan_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedDrawerIndex = 0;
  UserModel? _currentAdmin;
  bool _isLoading = true;
  final _databaseService = RealtimeDatabaseService();

  // Statistics
  int _totalMahasiswa = 0;
  int _totalAbsensi = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminSession();
  }

  void _loadAdminSession() async {
    final session = await AuthService().getUserSession();
    setState(() {
      _currentAdmin = session;
      _isLoading = false;
    });

    _fetchAdminStats();
  }

  Future<void> _fetchAdminStats() async {
    try {
      final stats = await _databaseService.getAdminStats();
      setState(() {
        _totalMahasiswa = stats['mahasiswa'] ?? 0;
        _totalAbsensi = stats['absensi'] ?? 0;
      });
    } catch (_) {
      // Offline fallback
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar Admin"),
        content: const Text("Apakah Anda yakin ingin keluar dari panel admin?"),
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
              await AuthService().logout();
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
    if (_isLoading || _currentAdmin == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        ),
      );
    }

    // Dynamic Admin sub pages
    final List<Widget> pages = [
      _buildDashboardTab(),
      GenerateBarcodeScreen(admin: _currentAdmin!),
      const DataUserScreen(),
      const DataAbsensiScreen(),
      const LaporanScreen(),
    ];

    final List<String> titles = [
      "Dashboard Admin",
      "Generate Barcode Sesi",
      "Kelola Data Mahasiswa",
      "Monitoring Absensi Realtime",
      "Laporan Rekapitulasi",
    ];

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          titles[_selectedDrawerIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_selectedDrawerIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchAdminStats,
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppConstants.primaryColor),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: const Icon(
                  Icons.security,
                  size: 40,
                  color: AppConstants.primaryColor,
                ),
              ),
              accountName: Text(
                _currentAdmin!.nama,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                _currentAdmin!.email,
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            // Navigation items
            _buildDrawerItem(0, Icons.dashboard_outlined, "Dashboard"),
            _buildDrawerItem(1, Icons.qr_code_2, "Generate Barcode"),
            _buildDrawerItem(2, Icons.people_outline, "Kelola Data User"),
            _buildDrawerItem(3, Icons.history_edu, "Lihat Data Absensi"),
            _buildDrawerItem(4, Icons.print_outlined, "Rekap Laporan"),

            const Spacer(),
            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                "Keluar",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _handleLogout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: pages[_selectedDrawerIndex],
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    final isSelected = _selectedDrawerIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppConstants.primaryColor.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isSelected ? AppConstants.primaryColor : AppConstants.textLight,
        ),
        title: Text(
          title,
          style: TextStyle(
            color:
                isSelected ? AppConstants.primaryColor : AppConstants.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedDrawerIndex = index;
          });
          Navigator.pop(context); // close drawer
        },
      ),
    );
  }

  // Dashboard content tab
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: const BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Selamat Bekerja,",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentAdmin!.nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Firebase Cloud aktif untuk autentikasi dan database absensi.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick statistical summary row
                Row(
                  children: [
                    _buildStatsBox(
                      "Mahasiswa",
                      _totalMahasiswa,
                      Icons.people,
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildStatsBox(
                      "Total Absen",
                      _totalAbsensi,
                      Icons.assignment_turned_in,
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Quick actions section
                const Text(
                  "Menu Cepat",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 14),

                _buildActionCard(
                  title: "Buat Sesi QR Absensi Baru",
                  subtitle:
                      "Generate kode QR terenkripsi Triple DES untuk absensi mahasiswa kelas.",
                  icon: Icons.qr_code_scanner,
                  color: AppConstants.secondaryColor,
                  onTap: () {
                    setState(() {
                      _selectedDrawerIndex = 1;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _buildActionCard(
                  title: "Monitoring Realtime Absensi",
                  subtitle:
                      "Lihat data kehadiran mahasiswa terbaru beserta ciphertext dan plaintext 3DES.",
                  icon: Icons.history_edu,
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _selectedDrawerIndex = 3;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBox(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 16),
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: AppConstants.textLight,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textDark,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppConstants.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppConstants.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
