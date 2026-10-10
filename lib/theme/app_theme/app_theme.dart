import 'package:flutter/material.dart';

class AppTheme {
  static const cream = Color(0xFFFAF6F0);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF221F1F);
  static const softInk = Color(0xFF6B6259);
  static const line = Color(0xFFE7DFD3);
  static const red = Color(0xFFC62222);
  static const darkRed = Color(0xFF8F1717);
  static const green = Color(0xFF3E7C59);
  static const greenBackground = Color(0xFFEAF3EC);
  static const amber = Color(0xFFB4700F);
  static const amberBackground = Color(0xFFFBF0DE);
  static const amberText = Color(0xFF955D0C);
  static const pendingBackground = Color(0xFFF4E3C8);
  static const pendingText = Color(0xFF8A5A22);
  static const assessedBackground = Color(0xFFD7ECDD);
  static const assessedText = Color(0xFF2E6B45);

  static ThemeData get theme {
    final ColorScheme colors =
        ColorScheme.fromSeed(
          seedColor: red,
          brightness: Brightness.light,
        ).copyWith(
          primary: red,
          onPrimary: surface,
          primaryContainer: const Color(0xFFF7E5DF),
          onPrimaryContainer: darkRed,
          secondary: green,
          onSecondary: surface,
          secondaryContainer: greenBackground,
          onSecondaryContainer: assessedText,
          tertiary: amber,
          onTertiary: surface,
          tertiaryContainer: amberBackground,
          onTertiaryContainer: amberText,
          surface: surface,
          onSurface: ink,
          onSurfaceVariant: softInk,
          outline: softInk,
          outlineVariant: line,
          error: red,
          onError: surface,
          surfaceTint: Colors.transparent,
        );
    final TextTheme text = ThemeData.light().textTheme.apply(
      fontFamily: 'Inter',
      bodyColor: ink,
      displayColor: ink,
    );
    final ButtonStyle primaryButton = ElevatedButton.styleFrom(
      backgroundColor: red,
      foregroundColor: surface,
      disabledBackgroundColor: line,
      disabledForegroundColor: softInk,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    );
    final OutlineInputBorder fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: line),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: cream,
      textTheme: text.copyWith(
        displayLarge: _heading(40),
        displayMedium: _heading(36),
        displaySmall: _heading(32),
        headlineLarge: _heading(28.8),
        headlineMedium: _heading(25.6),
        headlineSmall: _heading(22),
        titleLarge: _heading(19.2),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, color: softInk),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: red),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: red, width: 2),
        ),
        labelStyle: const TextStyle(color: softInk),
        floatingLabelStyle: const TextStyle(color: softInk),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: red,
        linearTrackColor: line,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: line),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: line),
        ),
      ),
    );
  }

  static TextStyle _heading(double size) {
    return TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: ink,
    );
  }
}
