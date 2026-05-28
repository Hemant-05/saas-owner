import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// QR Cafe Design System
/// All colors, typography, spacing, border radii, and shadows are defined here.
/// Never hardcode any of these values inline — always reference this file.
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary palette — dark navy theme
  static const Color primary = Color(0xFF1A1A2E);
  static const Color secondary = Color(0xFF16213E);
  static const Color accent = Color(0xFFE94560); // coral-red CTA
  static const Color accentAlt = Color(0xFFFF6B35); // orange alt accent

  // Semantic colors
  static const Color success = Color(0xFF0A9D58);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Background / Surface
  static const Color background = Color(0xFF0D0D1A); // dark bg
  static const Color surface = Color(0xFF12121F); // card surface
  static const Color surfaceElevated = Color(0xFF1A1A2E); // dialogs, elevated

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C3);
  static const Color textMuted = Color(0xFF6B6B80);

  // Border
  static const Color border = Color(0xFF2A2A3E);
  static const Color borderLight = Color(0xFF3A3A50);

  // Order status colors
  static const Color statusPlaced = Color(0xFF3B82F6);
  static const Color statusPreparing = Color(0xFFF59E0B);
  static const Color statusReady = Color(0xFF0A9D58);
  static const Color statusDelivered = Color(0xFF6B7280);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Payment status colors
  static const Color paymentPending = Color(0xFFF59E0B);
  static const Color paymentPaid = Color(0xFF0A9D58);
  static const Color paymentFailed = Color(0xFFEF4444);

  // Inventory status colors
  static const Color stockHealthy = Color(0xFF0A9D58);
  static const Color stockLow = Color(0xFFF59E0B);
  static const Color stockOut = Color(0xFFEF4444);
}

class AppTextStyles {
  AppTextStyles._();

  // Heading styles
  static const TextStyle headingXL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingL = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle headingM = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingS = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Body styles
  static const TextStyle bodyL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Label styles
  static const TextStyle labelL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingPage =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets paddingCard =
      EdgeInsets.all(md);
  static const EdgeInsets paddingCardSm =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double xl = 24.0;
  static const double full = 100.0;

  static BorderRadius get borderSmall => BorderRadius.circular(small);
  static BorderRadius get borderMedium => BorderRadius.circular(medium);
  static BorderRadius get borderLarge => BorderRadius.circular(large);
  static BorderRadius get borderXL => BorderRadius.circular(xl);
  static BorderRadius get borderFull => BorderRadius.circular(full);
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get glow => [
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ];
}

/// The main ThemeData for the app
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accent,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentAlt,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),

      // App bar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMedium,
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 4,
          ),
          textStyle: AppTextStyles.labelM,
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 4,
          ),
          textStyle: AppTextStyles.labelM,
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.labelM,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMedium,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMedium,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMedium,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMedium,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        hintStyle: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
        errorStyle: AppTextStyles.bodyS.copyWith(color: AppColors.error),
      ),

      // Snack bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyles.bodyM,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMedium),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXL),
        elevation: 24,
        titleTextStyle: AppTextStyles.headingS,
        contentTextStyle: AppTextStyles.bodyM,
      ),

      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accent,
        labelStyle: AppTextStyles.labelS,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.borderFull),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return AppColors.border;
        }),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.border,
      ),

      fontFamily: 'Roboto', // Will update to Poppins when google_fonts is added
    );
  }
}
