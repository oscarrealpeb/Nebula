import 'package:flutter/material.dart';

Color tint(Color color, double amount) {
  return Color.lerp(color, Colors.white, amount.clamp(0.0, 1.0)) ?? color;
}

Color shiftHue(Color color, double delta) {
  final hsv = HSVColor.fromColor(color);
  var hue = hsv.hue + delta;
  while (hue < 0) {
    hue += 360;
  }
  while (hue >= 360) {
    hue -= 360;
  }
  return hsv.withHue(hue).toColor();
}
