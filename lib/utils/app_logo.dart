import 'package:flutter/material.dart';

/// Widget logo aplikasi Absensi Triple DES.
/// Menggunakan gambar assets/images/logo.png.
/// Fallback ke icon clipboard jika gambar tidak tersedia.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Image.asset(
      'assets/images/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _fallback(),
    );

    if (!showGlow) return widget;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      child: widget,
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Icon(
        Icons.assignment_turned_in_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
