import 'package:flutter/material.dart';

ThemeData appTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xff126b61),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    brightness: brightness,
    fontFamily: 'Roboto',
    fontFamilyFallback: const ['NotoSansBengali'],
    scaffoldBackgroundColor: dark
        ? const Color(0xff101d1b)
        : const Color(0xfff5f8f6),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 44,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        height: 1.28,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.33,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.4,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, height: 1.45),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
  );
}
