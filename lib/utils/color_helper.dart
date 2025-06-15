import 'package:flutter/material.dart';

class ColorHelper {
  static final Map<int, String> colorNameMap = {
    Colors.black.value: 'أسود',
    Colors.white.value: 'أبيض',
    Colors.grey.value: 'رمادي',
    Colors.red.value: 'أحمر',
    Colors.blue.value: 'أزرق',
    Colors.green.value: 'أخضر',
    const Color(0xFF8D6E63).value: 'بني',
    Colors.yellow.value: 'أصفر',
    Colors.purple.value: 'بنفسجي',
  };

  static String getColorName(Color color) {
    return colorNameMap[color.value] ??
        '#${color.value.toRadixString(16)}';
  }
}
