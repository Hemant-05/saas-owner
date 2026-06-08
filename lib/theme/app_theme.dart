import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// QR Cafe Design System
/// All colors, typography, spacing, border radii, and shadows are defined here.
/// ─────────────────────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Primary palette (Brand Orange)
  static const Color primary = Color(0xFFF25C38);
  static const Color secondary = Color(0xFFFF8A65);
  static const Color accent = Color(0xFFF25C38); // Main brand color
  static const Color accentAlt = Color(0xFFE64A19);

  // Semantic colors
  static const Color success = Color(0xFF7CB342); // Soft green for completed/paid
  static const Color warning = Color(0xFFFFCA28); // Soft yellow for pending
  static const Color error = Color(0xFFEF5350); // Soft red
  static const Color info = Color(0xFF29B6F6);

  // Background / Surface
  static const Color backgroundLight = Color(0xFFF5F7FA); // Light grayish blue
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  // We are forcing light mode everywhere, but keep these aliases for compatibility
  static const Color backgroundDark = Color(0xFFF5F7FA);
  static const Color surfaceDark = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimaryLight = Color(0xFF1E293B); // Dark gray
  static const Color textSecondaryLight = Color(0xFF64748B); // Medium gray
  static const Color textMutedLight = Color(0xFF94A3B8); // Light gray

  static const Color textPrimaryDark = Color(0xFF1E293B);
  static const Color textSecondaryDark = Color(0xFF64748B);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Border
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFE2E8F0);
  
  // Legacy aliases
  static const Color background = backgroundLight;
  static const Color surface = surfaceLight;
  static const Color surfaceElevated = surfaceElevatedLight;
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textMutedLight;
  static const Color border = borderLight;

  // Order status colors
  static const Color statusPlaced = Color(0xFF29B6F6);
  static const Color statusPreparing = Color(0xFFFFCA28);
  static const Color statusReady = Color(0xFF7CB342);
  static const Color statusDelivered = Color(0xFF94A3B8);
  static const Color statusCancelled = Color(0xFFEF5350);

  // Payment status colors
  static const Color paymentPending = Color(0xFFFFCA28);
  static const Color paymentPaid = Color(0xFF7CB342);
  static const Color paymentFailed = Color(0xFFEF5350);

  // Inventory status colors
  static const Color stockHealthy = Color(0xFF7CB342);
  static const Color stockLow = Color(0xFFFFCA28);
  static const Color stockOut = Color(0xFFEF5350);
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
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: AppColors.accent,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.accent,
        secondary: AppColors.accentAlt,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLarge,
          side: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.backgroundLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMedium,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMedium,
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMedium,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMutedLight,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return lightTheme; // Enforce Light Theme completely
  }
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headingL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimaryLight,
    letterSpacing: -0.5,
  );

  static const TextStyle headingM = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
    letterSpacing: -0.3,
  );

  static const TextStyle headingS = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle bodyL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
    height: 1.5,
  );

  static const TextStyle bodyM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
    height: 1.5,
  );

  static const TextStyle bodyS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondaryLight,
    height: 1.4,
  );

  static const TextStyle labelL = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle labelM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle labelS = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondaryLight,
  );
}
