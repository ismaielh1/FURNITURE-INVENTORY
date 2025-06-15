import 'package:flutter/material.dart';

class Product {
  String id;
  String categoryId;
  String name;
  int quantity;
  String? imageUrl;
  final Color color;

  Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.quantity,
    this.imageUrl,
    required this.color,
  });

  Map<String, dynamic> toJson({bool withId = true}) {
    final map = {
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'color_value': color.value,
      'category_id': categoryId,
    };
    if (withId) map['id'] = id;
    return map;
  }

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] ?? '',
        categoryId: json['category_id'] ?? '',
        name: json['name'] ?? 'منتج غير مسمى',
        quantity: json['quantity'] ?? 0,
        imageUrl: json['image_url'],
        color: Color(json['color_value'] ?? 0xFF000000),
      );
}
