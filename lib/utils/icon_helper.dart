import 'package:flutter/material.dart';

class IconHelper {
  static final Map<String, IconData> iconMap = {
    'living_outlined': Icons.living_outlined,
    'table_bar_outlined': Icons.table_bar_outlined,
    'chair_outlined': Icons.chair_outlined,
    'bed_outlined': Icons.bed_outlined,
    'light_outlined': Icons.light_outlined,
    'shelves': Icons.shelves,
    'desk_outlined': Icons.desk_outlined,
    'auto_awesome_outlined': Icons.auto_awesome_outlined,
  };

  static IconData getIconFromString(String? iconKey) {
    if (iconKey == null || !iconMap.containsKey(iconKey)) {
      return Icons.category;
    }
    return iconMap[iconKey]!;
  }

  static String getStringFromIcon(IconData icon) {
    var entry = iconMap.entries.firstWhere(
        (entry) => entry.value.codePoint == icon.codePoint,
        orElse: () => iconMap.entries.first);
    return entry.key;
  }
}
