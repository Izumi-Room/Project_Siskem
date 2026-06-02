import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ════════════════════════════════════════════════════════════════════════════
// DESIGN SYSTEM — Smart Attendance 2026
// Inspired by: Linear, Notion, Material 3, Headspace
// ════════════════════════════════════════════════════════════════════════════

class AppColors {
  AppColors._();

  // ── Brand Palette ─────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF6366F1); // Indigo 500
  static const Color primaryDark   = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight  = Color(0xFF818CF8); // Indigo 400
  static const Color secondary     = Color(0xFF8B5CF6); // Violet 500
  static const Color accent        = Color(0xFF06B6D4); // Cyan 500

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success       = Color(0xFF10B981); // Emerald 500
  static const Color successLight  = Color(0xFFD1FAE5); // Emerald 100
  static const Color warning       = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight  = Color(0xFFFEF3C7); // Amber 100
  static const Color error         = Color(0xFFEF4444); // Red 500
  static const Color errorLight    = Color(0xFFFEE2E2); // Red 100
  static const Color info          = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight     = Color(0xFFDBEAFE); // Blue 100

  // ── Light Mode ────────────────────────────────────────────────────────────
  static const Color bgLight       = Color(0xFFF8F9FF); // Near white with blue tint
  static const Color surfaceLight  = Color(0xFFFFFFFF);
  static const Color cardLight     = Color(0xFFFFFFFF);
  static const Color borderLight   = Color(0xFFE8EAFF);
  static const Color textPrimary   = Color(0xFF0F0F23); // Near black
  static const Color textSecondary = Color(0xFF6B7280); // Gray 500
  static const Color textTertiary  = Color(0xFF9CA3AF); // Gray 400

  // ── Dark Mode ─────────────────────────────────────────────────────────────
  static const Color bgDark        = Color(0xFF0A0A14); // Deep dark
  static const Color surfaceDark   = Color(0xFF13131F); // Card dark
  static const Color cardDark      = Color(0xFF1A1A2E); // Elevated dark
  static const Color borderDark    = Color(0xFF2D2D4A);
  static const Color textPrimaryDark   = Color(0xFFF1F1FF);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradientLight = LinearGradient(
    colors: [Color(0xFFF8F9FF), Color(0xFFEEF0FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w800,
    letterSpacing: -1.0, height: 1.1,
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700,
    letterSpacing: -0.5, height: 1.2,
  );
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    letterSpacing: -0.3, height: 1.3,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600,
    letterSpacing: -0.2, height: 1.3,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    letterSpacing: 0, height: 1.4,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.1, height: 1.4,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    letterSpacing: 0, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    letterSpacing: 0, height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    letterSpacing: 0.1, height: 1.5,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}

class AppRadius {
  AppRadius._();
  static const double xs  = 8;
  static const double sm  = 12;
  static const double md  = 16;
  static const double lg  = 20;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double full = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      cardColor: AppColors.cardLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      cardColor: AppColors.cardDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimaryDark,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryDark,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
