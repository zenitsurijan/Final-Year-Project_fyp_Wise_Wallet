import 'package:flutter/material.dart';

class IconMapping {
  static IconData getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'directions_car':
      case 'transport':
        return Icons.directions_car;
      case 'shopping_bag':
      case 'shopping':
        return Icons.shopping_bag;
      case 'receipt_long':
      case 'bills':
        return Icons.receipt_long;
      case 'movie':
      case 'entertainment':
        return Icons.movie;
      case 'medical_services':
      case 'health':
        return Icons.medical_services;
      case 'school':
      case 'education':
        return Icons.school;
      case 'work':
      case 'salary':
        return Icons.work;
      case 'computer':
      case 'freelance':
        return Icons.computer;
      case 'trending_up':
      case 'investment':
        return Icons.trending_up;
      case 'card_giftcard':
      case 'gift':
        return Icons.card_giftcard;
      case 'payments':
      case 'other_income':
        return Icons.payments;
      case 'category':
      default:
        return Icons.category;
    }
  }
}
