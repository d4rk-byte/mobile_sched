import 'package:flutter/material.dart';

class AppColors {
  // Core accent palette
  static const Color primaryColor = Color(0xFF465FFF);
  static const Color primaryDark = Color(0xFF3448D9);
  static const Color primaryLight = Color(0xFF9CB0FF);

  // Shared card palette
  static const Color cardPrimaryStart = Color(0xFF1D4ED8);
  static const Color cardPrimaryEnd = Color(0xFF465FFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardSurfaceElevated = Color(0xFFF8FAFF);
  static const Color cardBorder = Color(0xFFE8ECF4);
  static const Color cardChipSurface = Color(0xFFEDF0FF);
  static const Color cardChipText = Color(0xFF1E3A8A);

  // Surfaces and backgrounds
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEAECF0);

  // Subtle borders and overlays
  static const Color borderSubtle = Color(0xFFF0F2F5);
  static const Color surfaceOverlay = Color(0x0A465FFF);
  static const Color cardShadow = Color(0x0A111827);

  // Shimmer / skeleton loading
  static const Color shimmerBase = Color(0xFFEEF1F6);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  // Text colors
  static const Color blackTextColor = Color(0xFF111827);
  static const Color greyTextColor = Color(0xFF667085);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF667085);

  // Status colors
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 28;
  static const double xxxl = 32;
  static const double page = 20;
}

class AppRadius {
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 22;
  static const double pill = 999;
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration stagger = Duration(milliseconds: 40);
}

/// Unified shadow system — use instead of inline BoxShadow definitions.
class AppShadow {
  /// Cards resting on the surface (default state).
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x08111827),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Cards on hover/pressed or elevated panels.
  static const List<BoxShadow> cardElevated = [
    BoxShadow(
      color: Color(0x0C111827),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Hero/gradient cards — colored glow shadow.
  static List<BoxShadow> hero(Color baseColor) => [
        BoxShadow(
          color: baseColor.withValues(alpha: 0.18),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  /// Bottom sheets & modals.
  static const List<BoxShadow> sheet = [
    BoxShadow(
      color: Color(0x14111827),
      blurRadius: 32,
      offset: Offset(0, -8),
    ),
  ];
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    textTheme: _textTheme(Brightness.light),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.cardPrimaryEnd,
      primary: AppColors.cardPrimaryEnd,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.backgroundColor,
    dividerColor: AppColors.divider,
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: AppSpacing.xl,
    ),
    splashFactory: InkSparkle.splashFactory,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.cardPrimaryEnd,
      linearTrackColor: AppColors.cardChipSurface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundColor,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      margin: const EdgeInsets.all(AppSpacing.xs),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.whiteColor,
      hintStyle: TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textSecondary.withValues(alpha: 0.72),
        fontSize: 14,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        fontFamily: 'Outfit',
        color: AppColors.cardPrimaryEnd,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide:
            const BorderSide(color: AppColors.cardPrimaryEnd, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(AppColors.whiteColor),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(2),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      horizontalTitleGap: AppSpacing.md,
      dense: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primaryLight,
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xl,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.cardPrimaryEnd,
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.cardPrimaryEnd,
        foregroundColor: Colors.white,
        disabledBackgroundColor:
            AppColors.cardPrimaryEnd.withValues(alpha: 0.5),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xl,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cardPrimaryEnd,
        side: const BorderSide(color: AppColors.cardPrimaryEnd, width: 1.5),
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xl,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      side: const BorderSide(color: AppColors.cardBorder),
      selectedColor: AppColors.cardChipSurface,
      backgroundColor: AppColors.cardSurface,
      labelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.cardChipText,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.whiteColor,
      selectedItemColor: AppColors.cardPrimaryEnd,
      unselectedItemColor: AppColors.greyTextColor,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        color: Colors.white,
      ),
      elevation: 2,
    ),
    dialogTheme: DialogThemeData(
      titleTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    textTheme: _textTheme(Brightness.dark),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D1424),
    dividerColor: const Color(0xFF273245),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF273245),
      thickness: 1,
      space: AppSpacing.xl,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1424),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF121A2A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: Color(0xFF273245)),
      ),
      margin: const EdgeInsets.all(AppSpacing.xs),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF121A2A),
      selectedItemColor: AppColors.cardPrimaryEnd,
      unselectedItemColor: Color(0xFF98A2B3),
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor =
        isDark ? Colors.white.withValues(alpha: 0.74) : AppColors.textSecondary;

    return TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 30,
        height: 1.15,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 24,
        height: 1.2,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 19,
        height: 1.25,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 15,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: bodyColor,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: bodyColor,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 12.5,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: mutedColor,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14,
        height: 1.2,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 11.5,
        height: 1.2,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
    );
  }
}
