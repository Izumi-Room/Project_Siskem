import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/user_model.dart';
import '../../services/scanner_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/lottie_assets.dart';

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

  // ── Proses QR yang di-scan ───────────────────────────────────────────────

  void _processScannedData(String scannedValue) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _scannerController.stop();

    try {
      final response = await _scannerService.processScannedQR(
        student: widget.user,
        scannedValue: scannedValue,
      );

      if (response['status'] == 'success') {
        widget.onAttendanceSuccess();
        _showResultDialog(
          success: true,
          title: 'Absensi Berhasil!',
          message:
              'Status: ${response['statusAbsensi']}\n'
              'Lokasi: ${response['location']}\n\n'
              'Kehadiran Anda telah dicatat di Firebase Cloud '
              'dengan pengamanan Triple DES.',
        );
      } else {
        _showResultDialog(
          success: false,
          title: 'Absensi Ditolak',
          message: response['message'] ?? 'Sistem menolak pencatatan absensi.',
        );
      }
    } catch (e) {
      _showResultDialog(
        success: false,
        title: 'Koneksi Bermasalah',
        message: 'Gagal menyimpan data ke Firebase Cloud.\nDetail: $e',
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
      barrierColor: Colors.black87,
      builder: (context) => _LottieResultDialog(
        success: success,
        title: title,
        message: message,
        onDismiss: () {
          Navigator.pop(context);
          setState(() => _isProcessing = false);
          if (!success) _scannerController.start();
        },
      ),
    );
  }

  // Opens a dialog for manual QR ID input (perfect for emulator testing!)
  void _showManualInputDialog() {
    _manualInputController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.keyboard, color: AppColors.primary),
              SizedBox(width: 10),
              Text(
                'Input QR ID Manual',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mode Demo: Salin QR ID dari panel Admin dan tempel di bawah ini.',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _manualInputController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Masukkan QR ID (Firebase push key)...',
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
                'Batal',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
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
                'Proses',
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
                borderColor: AppColors.primary,
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
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.full),
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
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () => _scannerController.toggleTorch(),
                ),
              ),

              // Manual Input — DEBUG ONLY, hidden in release builds
              if (kDebugMode)
                ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                icon: const Icon(Icons.keyboard, color: Colors.white, size: 20),
                label: const Text(
                  'Mode Demo: Input QR ID',
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
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ),
            ],
          ),
        ),

        // ── Lottie QR Scan Animation Overlay ────────────────────────
        if (!_isProcessing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.width * 0.15,
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    child: Lottie.asset(
                      LottieAssets.scanQr,
                      fit: BoxFit.contain,
                      repeat: true,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    LottieAssets.scanQr,
                    width: 120,
                    height: 120,
                    repeat: true,
                    errorBuilder: (_, __, ___) => CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Memvalidasi Absensi...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cek QR · Cek Expired · Cek Duplikat',
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
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Outer background overlay
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()
          ..addRRect(
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

// ── Lottie Result Dialog (fullscreen modal) ───────────────────────────────────
class _LottieResultDialog extends StatefulWidget {
  final bool success;
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const _LottieResultDialog({
    required this.success,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_LottieResultDialog> createState() => _LottieResultDialogState();
}

class _LottieResultDialogState extends State<_LottieResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();

    // Auto-dismiss after 2.5s on success
    if (widget.success) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.success ? const Color(0xFF059669) : Colors.redAccent;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Lottie ──────────────────────────────────────────────
                Lottie.asset(
                  widget.success
                      ? LottieAssets.resultSuccess
                      : LottieAssets.resultError,
                  width: 160,
                  height: 160,
                  repeat: !widget.success,
                  errorBuilder: (_, __, ___) => Icon(
                    widget.success
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: color,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Title ────────────────────────────────────────────────
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Message ──────────────────────────────────────────────
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Button (only shown on error; success auto-dismisses) ─
                if (!widget.success)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: widget.onDismiss,
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                if (widget.success) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kembali ke dashboard otomatis...',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
