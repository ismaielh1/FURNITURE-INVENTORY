import 'package:flutter/material.dart';
import 'package:furniture_inventory/utils/icon_helper.dart';

class Category {
  String id;
  String name;
  IconData icon;
  String? parentId;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    this.parentId,
  });

  Map<String, dynamic> toJson({bool withId = true}) {
    final map = {
      'name': name,
      'icon_key': IconHelper.getStringFromIcon(icon),
      'parent_id': parentId,
    };
    if (withId) map['id'] = id;
    return map;
  }

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(
        id: json['id'],
        name: json['name'],
        icon: IconHelper.getIconFromString(json['icon_key']),
        parentId: json['parent_id'],
      );
}
