import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const lightBackground = Color(0xFFF6F8FC);
  static const lightSurface = Colors.white;
  static const lightInk = Color(0xFF0B1220);
  static const lightMuted = Color(0xFF475467);
  static const primary = Color(0xFF2546D2);
  static const darkBackground = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111B2E);
  static const darkInk = Color(0xFFF8FAFC);
  static const darkMuted = Color(0xFFCDD5E0);
  static const darkPrimary = Color(0xFFA8BAFF);
  static const success = Color(0xFF027A48);
  static const warning = Color(0xFFB54708);
  static const error = Color(0xFFB42318);
}

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final surface = dark ? AppPalette.darkSurface : AppPalette.lightSurface;
    final ink = dark ? AppPalette.darkInk : AppPalette.lightInk;
    final primary = dark ? AppPalette.darkPrimary : AppPalette.primary;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppPalette.primary,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          onPrimary: dark ? AppPalette.darkBackground : Colors.white,
          surface: surface,
          onSurface: ink,
          error: dark ? const Color(0xFFFF9B8F) : AppPalette.error,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark
          ? AppPalette.darkBackground
          : AppPalette.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? AppPalette.darkBackground
            : AppPalette.lightBackground,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: dark ? const Color(0xFF263349) : const Color(0xFFE7ECF3),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
      ),
    );
  }
}
