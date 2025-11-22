import 'package:flutter/material.dart';

class AppTheme {
  final String id;
  final String name;
  final int price;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  const AppTheme({
    required this.id,
    required this.name,
    required this.price,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    this.isDark = false,
  });
}
