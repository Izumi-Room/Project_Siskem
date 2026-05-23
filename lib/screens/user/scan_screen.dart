import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/user_model.dart';
import '../../services/barcode_service.dart';
import '../../services/scanner_service.dart';
import '../../utils/constants.dart';

class ScanScreen extends StatefulWidget {
  final UserModel user;
  final VoidCallback onAttendanceSuccess;

  const ScanScreen({
    Key? key,
    required this.user,
    required this.onAttendanceSuccess,
  }) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _barcodeService = BarcodeService();
  final _scannerService = ScannerService();
  final _manualInputController = TextEditingController();
  bool _isProcessing = false;
  MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  // Handle scanned cipher text
  void _processScannedData(String cipherText) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    _scannerController.stop(); // Stop scanning to prevent multiple scans

    // 1. Decrypt & parse the QR session
    final parsedQR = _barcodeService.parseScannedQR(cipherText);

    if (parsedQR == null) {
      _showResultDialog(
        success: false,
        title: "QR Code Tidak Valid",
        message: "Format QR tidak didukung atau kunci enkripsi salah.",
      );
      return;
    }

    final adminId = parsedQR['admin_id'].toString();
    final tanggal = parsedQR['tanggal'];
    final jam = parsedQR['jam'];
    final status = parsedQR['status'];
    final randomKey = parsedQR['random_key'];

    // 2. Validate date (Optional, for demo we can print info)
    // 3. Submit attendance (student encrypts their data and posts to PHP)
    try {
      final response = await _scannerService.submitAttendance(
        studentId: widget.user.id,
        adminId: adminId,
        tanggal: tanggal,
        jam: jam,
        status: status,
        randomKey: randomKey,
      );

      if (response['status'] == 'success') {
        widget.onAttendanceSuccess(); // callback to update list/stats
        _showResultDialog(
          success: true,
          title: "Absensi Berhasil!",
          message:
              "Kehadiran Anda [Status: $status] pada tanggal $tanggal jam $jam telah sukses dicatat di database server lokal menggunakan pengamanan Triple DES.",
        );
      } else {
        _showResultDialog(
          success: false,
          title: "Gagal Absensi",
          message: response['message'] ?? "Sistem menolak pencatatan absensi.",
        );
      }
    } catch (e) {
      _showResultDialog(
        success: false,
        title: "Koneksi Bermasalah",
        message:
            "Gagal mengirim data ke server. Pastikan IP server lokal sudah disesuaikan dan server XAMPP aktif. Detail: $e",
      );
    }
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: success
                      ? Colors.green.withOpacity(0.1)
                      : Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: success ? Colors.green : Colors.redAccent,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: success
                        ? Colors.green
                        : AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isProcessing = false;
                    });
                    _scannerController.start(); // Resume scanner
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  // Opens a dialog for manual ciphertext input (perfect for emulator testing!)
  void _showManualInputDialog() {
    _manualInputController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.keyboard, color: AppConstants.primaryColor),
              SizedBox(width: 10),
              Text(
                "Input Ciphertext Manual",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Mode Demo: Salin Ciphertext yang di-generate Admin dan tempel di bawah ini.",
                style: TextStyle(color: AppConstants.textLight, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualInputController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Masukkan Ciphertext Base64...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Batal",
                style: TextStyle(color: AppConstants.textLight),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final text = _manualInputController.text.trim();
                Navigator.pop(context);
                if (text.isNotEmpty) {
                  _processScannedData(text);
                }
              },
              child: const Text(
                "Proses",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera Viewfinder
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                _processScannedData(barcode.rawValue!);
                break;
              }
            }
          },
        ),

        // Beautiful Scanner Mask
        Positioned.fill(
          child: Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppConstants.secondaryColor,
                borderRadius: 24,
                borderLength: 30,
                borderWidth: 8,
                cutOutSize: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),
        ),

        // Top Guide
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "Arahkan Kamera ke QR Code Absensi",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom Actions (Flash & Manual Input)
        Positioned(
          bottom: 40,
          left: 24,
          right: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flash Button
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.black.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () => _scannerController.toggleTorch(),
                ),
              ),

              // Manual Input (Demo mode shortcut)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: const BorderSide(
                    color: AppConstants.secondaryColor,
                    width: 1.5,
                  ),
                ),
                icon: const Icon(Icons.keyboard, color: Colors.white, size: 20),
                label: const Text(
                  "Mode Demo: Input Text",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: _showManualInputDialog,
              ),

              // Camera Flip
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.black.withOpacity(0.6),
                child: IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ),
            ],
          ),
        ),

        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppConstants.secondaryColor),
                  SizedBox(height: 16),
                  Text(
                    "Mengamankan Transaksi Absensi...",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Proses Enkripsi Triple DES",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Custom Painter for QR Scanning Frame Overlay
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderLength = 40.0,
    this.borderRadius = 0.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final boxWidth = cutOutSize;
    final boxHeight = cutOutSize;

    final left = (width - boxWidth) / 2;
    final top = (height - boxHeight) / 2;
    final right = left + boxWidth;
    final bottom = top + boxHeight;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Outer background overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(left, top, right, bottom),
            Radius.circular(borderRadius),
          ),
        ),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Custom borders around the cutout region
    final path = Path();
    // Top Left Corner
    path.moveTo(left + borderRadius, top);
    path.lineTo(left + borderLength, top);
    path.moveTo(left, top + borderRadius);
    path.lineTo(left, top + borderLength);

    // Top Right Corner
    path.moveTo(right - borderRadius, top);
    path.lineTo(right - borderLength, top);
    path.moveTo(right, top + borderRadius);
    path.lineTo(right, top + borderLength);

    // Bottom Left Corner
    path.moveTo(left + borderRadius, bottom);
    path.lineTo(left + borderLength, bottom);
    path.moveTo(left, bottom - borderRadius);
    path.lineTo(left, bottom - borderLength);

    // Bottom Right Corner
    path.moveTo(right - borderRadius, bottom);
    path.lineTo(right - borderLength, bottom);
    path.moveTo(right, bottom - borderRadius);
    path.lineTo(right, bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderLength: borderLength,
      borderRadius: borderRadius,
      cutOutSize: cutOutSize,
    );
  }
}
