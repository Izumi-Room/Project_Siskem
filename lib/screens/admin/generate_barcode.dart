import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/user_model.dart';
import '../../services/barcode_service.dart';
import '../../utils/constants.dart';

class GenerateBarcodeScreen extends StatefulWidget {
  final UserModel admin;

  const GenerateBarcodeScreen({Key? key, required this.admin})
    : super(key: key);

  @override
  State<GenerateBarcodeScreen> createState() => _GenerateBarcodeScreenState();
}

class _GenerateBarcodeScreenState extends State<GenerateBarcodeScreen> {
  final _barcodeService = BarcodeService();
  String _selectedStatus = "Hadir";
  int _durationMinutes = 15;
  String? _generatedCipherText;
  bool _isLoading = false;

  void _handleGenerateQR() async {
    setState(() {
      _isLoading = true;
      _generatedCipherText = null;
    });

    try {
      final cipherText = await _barcodeService.generateNewSession(
        adminId: widget.admin.id,
        status: _selectedStatus,
        durationMinutes: _durationMinutes,
      );

      setState(() {
        _isLoading = false;
        _generatedCipherText = cipherText;
      });

      if (cipherText != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "QR Code Sesi Absensi berhasil dibuat & didaftarkan ke server!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mendaftarkan sesi QR ke database server."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Buat Sesi Absensi Baru",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Atur status dan durasi absensi untuk di-generate menjadi QR Code terenkripsi Triple DES.",
            style: TextStyle(fontSize: 13, color: AppConstants.textLight),
          ),
          const SizedBox(height: 24),

          // Settings Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown Status
                const Text(
                  "STATUS ABSENSI",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.check_circle_outline,
                      color: AppConstants.secondaryColor,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: ["Hadir", "Sakit", "Izin"]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Expiry Duration Minutes
                const Text(
                  "DURASI EXPIRED (MENIT)",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _durationMinutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        activeColor: AppConstants.primaryColor,
                        inactiveColor: AppConstants.primaryColor.withOpacity(
                          0.15,
                        ),
                        label: "$_durationMinutes Menit",
                        onChanged: (val) {
                          setState(() {
                            _durationMinutes = val.toInt();
                          });
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "$_durationMinutes mnt",
                        style: const TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.qr_code, color: Colors.white),
                    label: const Text(
                      "GENERATE QR CODE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleGenerateQR,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Result QR Section
          if (_generatedCipherText != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                  border: Border.all(
                    color: AppConstants.secondaryColor.withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "SCAN ME",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppConstants.primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Berhasil Dienkripsi dengan Triple DES",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Live QR Render using qr_flutter
                    QrImageView(
                      data: _generatedCipherText!,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppConstants.primaryColor,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppConstants.secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Demonstration Ciphertext breakdown
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      "CIPHERTEXT YANG TERSIMPAN DI QR CODE:",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: SelectableText(
                        _generatedCipherText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}
