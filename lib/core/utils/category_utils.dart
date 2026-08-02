import 'package:flutter/material.dart';

IconData getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'salary':
      return Icons.payments_rounded;
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
    case 'shopping':
      return Icons.shopping_bag_rounded;
    case 'medical':
      return Icons.local_hospital_rounded;
    case 'education':
      return Icons.school_rounded;
    case 'entertainment':
      return Icons.movie_rounded;
    case 'bills':
      return Icons.receipt_rounded;
    case 'rent':
      return Icons.home_rounded;
    case 'travel':
      return Icons.flight_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'salary':
      return Colors.green;
    case 'freelancing':
      return Colors.teal;
    case 'business':
      return Colors.indigo;
    case 'investment':
      return Colors.cyan;
    case 'bonus':
      return Colors.amber;
    case 'gift':
      return Colors.pink;
    case 'food':
      return Colors.orange;
    case 'transport':
      return Colors.blue;
    case 'shopping':
      return Colors.purple;
    case 'medical':
      return Colors.red;
    case 'education':
      return Colors.brown;
    case 'entertainment':
      return Colors.deepOrange;
    case 'bills':
      return Colors.blueGrey;
    case 'rent':
      return Colors.indigoAccent;
    case 'travel':
      return Colors.purpleAccent;
    default:
      return Colors.grey;
  }
}
