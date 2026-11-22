import 'package:flutter/material.dart';

abstract final class AppColors {
  static const midnight = Color(0xFF17212D);
  static const deepNavy = Color(0xFF111A24);
  static const slate = Color(0xFF202C39);
  static const raisedSlate = Color(0xFF293746);
  static const sage = Color(0xFF96A487);
  static const gold = Color(0xFFD8B873);
  static const warmWhite = Color(0xFFF4EFE3);
  static const mutedText = Color(0xFFAEB7BE);
  static const expense = Color(0xFFE29B7A);
}

/// Semantic colors for the Trace interface.  Use this instead of a fixed
/// dark swatch in widgets so the same component remains legible in both
/// appearance modes.
extension TraceThemeColors on BuildContext {
  ColorScheme get traceScheme => Theme.of(this).colorScheme;
  bool get isTraceDark => Theme.of(this).brightness == Brightness.dark;

  Color get traceCard =>
      Theme.of(this).cardTheme.color ?? traceScheme.surfaceContainer;
  Color get traceRaisedCard =>
      isTraceDark ? AppColors.raisedSlate : const Color(0xFFFFFFFF);
  Color get traceField =>
      isTraceDark ? AppColors.deepNavy : const Color(0xFFF0EEE8);
  Color get traceBorder =>
      isTraceDark ? const Color(0xFF344352) : const Color(0xFFE0DDD5);
  Color get traceMuted => traceScheme.onSurfaceVariant;
  Color get traceOnSurface => traceScheme.onSurface;
  Color get traceNavSurface =>
      isTraceDark ? AppColors.deepNavy : const Color(0xFFFFFFFF);
  Color get traceNavBorder =>
      isTraceDark ? const Color(0xFF3B4958) : const Color(0xFFDEDAD0);
  Color get traceIncomeTint =>
      isTraceDark ? const Color(0xFF39463B) : const Color(0xFFE5EBDD);
  Color get traceExpenseTint =>
      isTraceDark ? const Color(0xFF4A3733) : const Color(0xFFF8E6DE);
}

abstract final class AppTheme {
  static ThemeData get light {
    const colors = ColorScheme.light(
      primary: Color(0xFF8A651A),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFE4A9),
      onPrimaryContainer: Color(0xFF2C2109),
      secondary: Color(0xFF5E7057),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0EBD8),
      onSecondaryContainer: Color(0xFF1C2B18),
      error: Color(0xFFB74036),
      onError: Colors.white,
      surface: Color(0xFFF6F4EF),
      onSurface: Color(0xFF211F1A),
      onSurfaceVariant: Color(0xFF625F59),
      outline: Color(0xFF77736B),
      outlineVariant: Color(0xFFE0DDD5),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: const Color(0xFFF6F4EF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFF211F1A),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFE0DDD5)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFFFE4A9),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        modalBackgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0EEE8),
        labelStyle: const TextStyle(color: Color(0xFF625F59)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0DDD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8A651A), width: 1.5),
        ),
      ),
      dividerColor: const Color(0xFFE0DDD5),
    );
  }

  static ThemeData get dark {
    const colors = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.deepNavy,
      primaryContainer: Color(0xFF4B4231),
      onPrimaryContainer: Color(0xFFFFE3AA),
      secondary: AppColors.sage,
      onSecondary: AppColors.deepNavy,
      secondaryContainer: Color(0xFF384338),
      onSecondaryContainer: Color(0xFFDCE7D2),
      error: AppColors.expense,
      onError: AppColors.deepNavy,
      surface: AppColors.midnight,
      onSurface: AppColors.warmWhite,
      onSurfaceVariant: AppColors.mutedText,
      outline: Color(0xFF566473),
      outlineVariant: Color(0xFF334252),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colors,
      scaffoldBackgroundColor: AppColors.midnight,
      canvasColor: AppColors.slate,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.warmWhite,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.slate,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF2E3D4C)),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.deepNavy,
        indicatorColor: Color(0xFF4B4231),
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.deepNavy,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.slate,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.slate,
        showDragHandle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.deepNavy,
        labelStyle: const TextStyle(color: AppColors.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3A4958)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
      dividerColor: const Color(0xFF334252),
    );
  }
}
