import 'package:flutter/material.dart';
import 'app_theme.dart';

InputDecoration appInputDecoration(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppTheme.softInk),
    filled: true,
    fillColor: AppTheme.surface,
    border: _border(),
    enabledBorder: _border(),
    focusedBorder: _border(color: AppTheme.red),
    suffixIcon: suffixIcon,
  );
}

OutlineInputBorder _border({Color color = AppTheme.line}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
}