import 'package:flutter/material.dart';

/// Renders an exact decimal money string without any floating-point conversion.
///
/// The [decimalString] is the raw string from the API (e.g. "12500.00").
/// This widget formats it for display using string operations only — no
/// [double] arithmetic.
class MoneyText extends StatelessWidget {
  final String decimalString;
  final String currencyCode;
  final TextStyle? style;
  final bool showSign;

  const MoneyText({
    super.key,
    required this.decimalString,
    this.currencyCode = 'INR',
    this.style,
    this.showSign = false,
  });

  static String getSymbol(String currencyCode) {
    switch (currencyCode) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$currencyCode ';
    }
  }

  /// Formats the decimal string for display using string operations only — no double conversions.
  static String format(String raw, [String currencyCode = 'INR', bool showSign = false]) {
    final isNegative = raw.startsWith('-');
    final abs = isNegative ? raw.substring(1) : raw;
    final parts = abs.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final symbol = getSymbol(currencyCode);

    final String formatted;
    if (currencyCode == 'INR') {
      // Indian numbering: first group of 3 from right, then groups of 2
      final chars = intPart.split('').reversed.toList();
      final groups = <String>[];
      for (int i = 0; i < chars.length; i++) {
        if (i == 3 && chars.length > 3) {
          groups.add(',');
        } else if (i > 3 && (i - 3) % 2 == 0) {
          groups.add(',');
        }
        groups.add(chars[i]);
      }
      formatted = groups.reversed.join();
    } else {
      // Standard grouping in 3s
      final chars = intPart.split('').reversed.toList();
      final groups = <String>[];
      for (int i = 0; i < chars.length; i++) {
        if (i > 0 && i % 3 == 0) {
          groups.add(',');
        }
        groups.add(chars[i]);
      }
      formatted = groups.reversed.join();
    }

    final sign = isNegative ? '-' : (showSign ? '+' : '');
    return '$sign$symbol$formatted.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      format(decimalString, currencyCode, showSign),
      style: style,
    );
  }
}
