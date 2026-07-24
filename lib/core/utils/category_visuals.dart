import 'package:flutter/material.dart';

class CategoryVisuals {
  CategoryVisuals._();

  static const Map<String, IconData> icons = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'home': Icons.home,
    'receipt': Icons.receipt_long,
    'health': Icons.health_and_safety,
    'school': Icons.school,
    'sports_esports': Icons.sports_esports,
    'shopping_bag': Icons.shopping_bag,
    'subscriptions': Icons.subscriptions,
    'payments': Icons.payments,
    'work': Icons.work,
    'trending_up': Icons.trending_up,
    'card_giftcard': Icons.card_giftcard,
    'replay': Icons.replay,
    'flight': Icons.flight,
    'pets': Icons.pets,
    'phone_android': Icons.phone_android,
    'fitness_center': Icons.fitness_center,
    'savings': Icons.savings,
    'category': Icons.category,
  };

  static const List<String> colors = [
    '#F44336',
    '#E91E63',
    '#9C27B0',
    '#673AB7',
    '#3F51B5',
    '#2196F3',
    '#03A9F4',
    '#009688',
    '#4CAF50',
    '#8BC34A',
    '#FFC107',
    '#FF9800',
    '#795548',
    '#607D8B',
  ];

  static IconData iconFromName(String? name) {
    return icons[name] ?? Icons.category;
  }

  static Color colorFromHex(String? hex, {Color fallback = Colors.blue}) {
    if (hex == null || hex.trim().isEmpty) {
      return fallback;
    }

    var normalized = hex.trim().replaceFirst('#', '');

    if (normalized.length == 6) {
      normalized = 'FF$normalized';
    }

    final value = int.tryParse(normalized, radix: 16);

    if (value == null) {
      return fallback;
    }

    return Color(value);
  }
}
