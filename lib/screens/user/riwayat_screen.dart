import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/absensi_model.dart';
import '../../services/realtime_database_service.dart';
import '../../services/triple_des_service.dart';
import '../../utils/constants.dart';

class RiwayatScreen extends StatefulWidget {
  final UserModel user;

  const RiwayatScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<AbsensiModel> _riwayatList = [];
  bool _isLoading = true;
  String _errorMsg = "";
  final _databaseService = RealtimeDatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      final data = await _databaseService.getRiwayatAbsensi(widget.user.uid);
      setState(() {
        _riwayatList = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Gagal mengambil riwayat dari Firebase Cloud.";
        _isLoading = false;
      });
    }
  }

  void _showCryptographyDetail(AbsensiModel absensi) {
    String decryptedPlain = "";
    bool decryptSuccess = true;
    try {
      decryptedPlain = TripleDesService.decryptData(absensi.cipherText);
    } catch (e) {
      decryptedPlain = "Dekripsi gagal: ${e.toString()}";
      decryptSuccess = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet handle
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Icon(
                    Icons.enhanced_encryption,
                    color: AppConstants.primaryColor,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Detail Kriptografi Triple DES",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Data berikut disimpan di pangkalan data secara aman dalam bentuk Ciphertext terenkripsi 3DES.",
                style: TextStyle(color: AppConstants.textLight, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Ciphertext Card
              const Text(
                "CIPHERTEXT (DI DATABASE):",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  absensi.cipherText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Decrypted Plaintext Card
              const Text(
                "HASIL DEKRIPSI (PLAINTEXT):",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      decryptedPlain,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (decryptSuccess) ...[
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 6),
                      const Text(
                        "Format: user_id | session_id | tanggal | jam | status | random_key",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConstants.textLight,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppConstants.textDark,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                onPressed: _fetchRiwayat,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "Coba Lagi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_riwayatList.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchRiwayat,
        color: AppConstants.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: AppConstants.textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Belum ada riwayat absensi.",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRiwayat,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _riwayatList.length,
        itemBuilder: (context, index) {
          final absensi = _riwayatList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppConstants.primaryColor,
                  ),
                ),
                title: Text(
                  absensi.status,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
                subtitle: Text(
                  "${absensi.tanggal}  •  ${absensi.jam}",
                  style: const TextStyle(
                    color: AppConstants.textLight,
                    fontSize: 13,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        "3DES",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () => _showCryptographyDetail(absensi),
              ),
            ),
          );
        },
      ),
    );
  }
}
