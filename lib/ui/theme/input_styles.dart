import 'package:flutter/material.dart';

InputDecoration appInputDecoration(
  String label, {
  Widget? suffixIcon,
  bool floatingLabel = true,
}) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: _floatingLabelBehavior(floatingLabel),
    suffixIcon: suffixIcon,
  );
}

FloatingLabelBehavior _floatingLabelBehavior(bool enabled) {
  if (enabled) {
    return FloatingLabelBehavior.auto;
  } else {
    return FloatingLabelBehavior.never;
  }
}
