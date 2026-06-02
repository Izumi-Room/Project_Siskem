import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Legacy constants — kept for backward compatibility.
/// New code should use AppColors and AppTheme directly.
class AppConstants {
  // Mapped to new design system
  static const Color primaryColor   = AppColors.primary;
  static const Color secondaryColor = AppColors.primaryLight;
  static const Color accentColor    = AppColors.accent;
  static const Color backgroundColor = AppColors.bgLight;
  static const Color cardColor      = AppColors.cardLight;
  static const Color textDark       = AppColors.textPrimary;
  static const Color textLight      = AppColors.textSecondary;
}
