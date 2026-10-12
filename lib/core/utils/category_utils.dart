import 'package:flutter/material.dart';

IconData getCategoryIcon(String category) {
  switch (category.toLowerCase().trim()) {
    case 'salary':
      return Icons.payments_rounded;
    case 'other income':
      return Icons.account_balance_wallet_rounded;
    case 'freelancing':
      return Icons.work_rounded;
    case 'business':
      return Icons.storefront_rounded;
    case 'investment':
      return Icons.trending_up_rounded;
    case 'bonus':
      return Icons.card_giftcard_rounded;
    case 'gift':
      return Icons.redeem_rounded;
    case 'food':
      return Icons.restaurant_rounded;
    case 'transport':
      return Icons.directions_car_rounded;
    case 'housing':
    case 'rent':
      return Icons.home_rounded;
    case 'utilities':
    case 'bills':
      return Icons.bolt_rounded;
    case 'healthcare':
    case 'medical':
      return Icons.local_hospital_rounded;
    case 'entertainment':
      return Icons.movie_rounded;
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'travel':
      return Icons.flight_rounded;
    case 'other expense':
    case 'other':
      return Icons.category_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color getCategoryColor(String category) {
  switch (category.toLowerCase().trim()) {
    case 'salary':
      return const Color(0xFF10B981); // Emerald
    case 'other income':
      return const Color(0xFF06B6D4); // Cyan
    case 'freelancing':
      return const Color(0xFF14B8A6); // Teal
    case 'business':
      return const Color(0xFF6366F1); // Indigo
    case 'investment':
      return const Color(0xFF38BDF8); // Sky
    case 'bonus':
      return const Color(0xFFF59E0B); // Amber
    case 'gift':
      return const Color(0xFFEC4899); // Pink
    case 'food':
      return const Color(0xFFF97316); // Warm Amber / Orange
    case 'transport':
      return const Color(0xFF3B82F6); // Blue
    case 'housing':
    case 'rent':
      return const Color(0xFF8B5CF6); // Purple
    case 'utilities':
    case 'bills':
      return const Color(0xFFF43F5E); // Rose
    case 'healthcare':
    case 'medical':
      return const Color(0xFFEF4444); // Red/Coral
    case 'entertainment':
      return const Color(0xFFA855F7); // Violet
    case 'shopping':
      return const Color(0xFFD97706); // Ocre
    case 'education':
      return const Color(0xFF0D9488); // Teal Dark
    case 'travel':
      return const Color(0xFF0284C7); // Sky Dark
    case 'other expense':
    case 'other':
      return const Color(0xFF64748B); // Slate
    default:
      return const Color(0xFF94A3B8); // Slate Light
  }
}
