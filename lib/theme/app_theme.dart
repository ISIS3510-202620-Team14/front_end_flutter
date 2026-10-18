import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: cream,
    textTheme: TextTheme(
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 36, fontWeight: FontWeight.w700, color: ink,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: softInk,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: red,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? darkRed : red,
        ),
      ),
    ),
  );
}
