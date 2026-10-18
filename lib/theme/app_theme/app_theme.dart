import 'package:flutter/material.dart';

class AppTheme {
  static const double panelRadius = 20;
  static const double controlRadius = 16;
  static const double pageInset = 20;
  static const background = Color(0xFFFAF6F3);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1D1D1B);
  static const softInk = Color(0xFF50504D);
  static const line = Color(0xFFE2E2E2);
  static const red = Color(0xFFE52228);
  static const darkRed = red;
  static const green = Color(0xFF3E7C59);
  static const greenBackground = Color(0xFFEAF3EC);
  static const amber = Color(0xFFB4700F);
  static const amberBackground = Color(0xFFFBF0DE);
  static const amberText = Color(0xFF955D0C);
  static const pendingBackground = Color(0xFFF4E3C8);
  static const pendingText = Color(0xFF8A5A22);
  static const assessedBackground = Color(0xFFD7ECDD);
  static const assessedText = Color(0xFF2E6B45);

  static TextStyle recordStatusText(Color color) {
    return _label(14, FontWeight.w600).copyWith(color: color);
  }

  static ThemeData get headerTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Work Sans',
      textTheme: TextTheme(
        bodySmall: _body(12, surface),
        labelMedium: _label(12, FontWeight.w600).copyWith(color: surface),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF747470)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: surface,
          minimumSize: const Size(48, 48),
          textStyle: _label(12, FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          side: const BorderSide(color: Color(0xFFAAA6A3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  static ThemeData get theme {
    final ColorScheme colors =
        ColorScheme.fromSeed(
          seedColor: red,
          brightness: Brightness.light,
        ).copyWith(
          primary: ink,
          onPrimary: surface,
          primaryContainer: const Color(0xFFE9E9E6),
          onPrimaryContainer: ink,
          secondary: ink,
          onSecondary: surface,
          secondaryContainer: const Color(0xFFE9E9E6),
          onSecondaryContainer: ink,
          tertiary: amber,
          onTertiary: surface,
          tertiaryContainer: amberBackground,
          onTertiaryContainer: amberText,
          surface: surface,
          surfaceContainerLowest: surface,
          surfaceContainerLow: background,
          surfaceContainer: const Color(0xFFE9E9E6),
          surfaceContainerHigh: const Color(0xFFDEDEDA),
          onSurface: ink,
          onSurfaceVariant: softInk,
          outline: softInk,
          outlineVariant: line,
          error: ink,
          onError: surface,
          surfaceTint: Colors.transparent,
        );
    final TextTheme text = ThemeData.light().textTheme.apply(
      fontFamily: 'Work Sans',
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
        fontFamily: 'Work Sans',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(controlRadius),
      ),
    );
    final OutlineInputBorder fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: const BorderSide(color: softInk),
    );
    return ThemeData(
      useMaterial3: true,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ink,
        selectionColor: Color(0xFFDEDEDA),
        selectionHandleColor: ink,
      ),
      colorScheme: colors,
      fontFamily: 'Work Sans',
      scaffoldBackgroundColor: background,
      textTheme: text.copyWith(
        displayLarge: _heading(28.8),
        displayMedium: _heading(28.8),
        displaySmall: _heading(28.8),
        headlineLarge: _heading(25.6),
        headlineMedium: _heading(25.6),
        headlineSmall: _heading(22),
        titleLarge: _heading(19.2, weight: FontWeight.w500),
        titleMedium: _heading(16, weight: FontWeight.w500),
        titleSmall: _heading(14, weight: FontWeight.w500),
        bodyLarge: _body(16, ink),
        bodyMedium: _body(14, softInk),
        bodySmall: _body(14, softInk),
        labelLarge: _label(16, FontWeight.w700),
        labelMedium: _label(14, FontWeight.w600),
        labelSmall: _label(12, FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: const Color(0xFFE9E9E6),
        labelStyle: _body(14, ink),
        checkmarkColor: ink,
        side: const BorderSide(color: line),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          textStyle: WidgetStatePropertyAll(_label(14, FontWeight.w600)),
          foregroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return surface;
            }
            return ink;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return ink;
            }
            return surface;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: softInk)),
        ),
      ),
      scrollbarTheme: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(true),
        thickness: WidgetStatePropertyAll(4),
        thumbColor: WidgetStatePropertyAll(softInk),
        radius: Radius.circular(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: red),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          iconColor: red,
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          iconColor: red,
          backgroundColor: surface,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
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
          borderSide: const BorderSide(color: ink, width: 2),
        ),
        labelStyle: const TextStyle(color: softInk),
        floatingLabelStyle: const TextStyle(color: softInk),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ink,
        linearTrackColor: line,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        titleTextStyle: _heading(25.6),
        toolbarHeight: 72,
        backgroundColor: background,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(
          fontFamily: 'Work Sans',
          color: surface,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: line),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(panelRadius),
        ),
      ),
    );
  }

  static TextStyle _body(double size, Color color) {
    return TextStyle(
      fontFamily: 'Work Sans',
      fontSize: size,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: color,
    );
  }

  static TextStyle _label(double size, FontWeight weight) {
    return TextStyle(
      fontFamily: 'Work Sans',
      fontSize: size,
      fontWeight: weight,
      height: 1.5,
      color: ink,
    );
  }

  static TextStyle _heading(
    double size, {
    FontWeight weight = FontWeight.w700,
  }) {
    return TextStyle(
      fontFamily: 'Lexend',
      fontSize: size,
      fontWeight: weight,
      height: 1.2,
      color: ink,
    );
  }
}
