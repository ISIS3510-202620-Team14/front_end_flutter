import 'package:flutter/material.dart';

enum QuickActionShape { circle, roundedSquare }

class QuickAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final QuickActionShape shape;

  const QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.shape = QuickActionShape.circle,
  });
}
