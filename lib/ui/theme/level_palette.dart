import 'package:flutter/material.dart';

class LevelPalette {
  static const Color first = Color(0xFFB72619);
  static const Color second = Color(0xFFCC6B68);
  static const Color third = Color(0xFFF0BC40);
  static const Color fourth = Color(0xFFF9D876);
  static const Color fifth = Color(0xFF9BC184);
  static const Color sixth = Color(0xFF56A359);
  static const Color neutral = Color(0xFFE9E9E6);

  static Color forName(String name) {
    switch (name) {
      case 'Principiante':
        return first;
      case 'Letra':
      case '1 dígito':
        return second;
      case 'Palabra':
      case '2 dígitos':
        return third;
      case 'Párrafo':
      case 'Resta':
        return fourth;
      case 'Cuento':
      case 'División':
        return fifth;
      case 'Comprensión':
      case 'Problema escrito':
        return sixth;
      default:
        return neutral;
    }
  }

  static Color foreground(Color background) {
    if (background == first) {
      return Colors.white;
    }
    return const Color(0xFF1D1D1B);
  }

  static TextStyle label(TextTheme theme, Color background) {
    return theme.labelMedium!.copyWith(color: foreground(background));
  }
}
