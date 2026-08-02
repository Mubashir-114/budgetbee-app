import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CurrencyProvider extends ChangeNotifier {
  static const String _prefKey = 'user_currency_code';

  String _currencyCode = 'USD';
  String _currencySymbol = '\$';

  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;
  String get selectedCurrencyString => '$_currencyCode ($_currencySymbol)';

  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'INR': '₹',
  };

  CurrencyProvider() {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && currencySymbols.containsKey(savedCode)) {
        _currencyCode = savedCode;
        _currencySymbol = currencySymbols[savedCode]!;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setCurrency(String code) async {
    if (!currencySymbols.containsKey(code)) return;
    _currencyCode = code;
    _currencySymbol = currencySymbols[code]!;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, code);
    } catch (_) {}
  }

  String format(double amount) {
    return NumberFormat.currency(symbol: _currencySymbol, decimalDigits: 2).format(amount);
  }
}
