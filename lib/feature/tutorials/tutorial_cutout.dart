import 'package:flutter/material.dart';

class TutorialCutout extends CustomClipper<Path> {
  const TutorialCutout(this.target);
  final Rect? target;
  @override
  Path getClip(Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    if (target != null) {
      path.addRRect(
        RRect.fromRectAndRadius(target!, const Radius.circular(18)),
      );
    }
    return path;
  }

  @override
  bool shouldReclip(TutorialCutout oldClipper) {
    return target != oldClipper.target;
  }
}
