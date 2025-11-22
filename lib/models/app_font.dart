import 'package:flutter/material.dart';

class AppFont {
  final String id;
  final String name;
  final int price;
  final TextStyle? style; // We will use this to store the GoogleFont style

  const AppFont({
    required this.id,
    required this.name,
    required this.price,
    this.style,
  });
}
