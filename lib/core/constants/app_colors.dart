import 'package:flutter/material.dart';

/// Midnight Aurora semantic palette shared by every financial surface.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF806BFF);
  static const Color primaryDeep = Color(0xFF5D48DC);
  static const Color secondary = Color(0xFF69E3CE);
  static const Color gold = Color(0xFFFFCB78);

  static const Color success = Color(0xFF45D6A6);
  static const Color income = success;
  static const Color danger = Color(0xFFFF708A);
  static const Color expense = danger;
  static const Color warning = Color(0xFFFFCB78);
  static const Color info = Color(0xFF6EB7FF);
  static const Color transfer = Color(0xFF8FA3C8);
  static const Color savings = secondary;

  static const Color scaffold = Color(0xFFF7F5F2);
  static const Color surfaceLight = Color(0xFFFFFDFC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE5E2EA);
  static const Color textDark = Color(0xFF171B32);
  static const Color textSecondaryLight = Color(0xFF686D82);

  static const Color darkScaffold = Color(0xFF101427);
  static const Color surfaceDark = Color(0xFF171C32);
  static const Color cardDark = Color(0xFF1B2139);
  static const Color elevatedDark = Color(0xFF242B48);
  static const Color dividerDark = Color(0xFF303854);
  static const Color textLight = Color(0xFFF8F9FF);
  static const Color textSecondaryDark = Color(0xFFB7BDD5);

  static const LinearGradient auroraGradient = LinearGradient(
    colors: [primary, Color(0xFF9A72F8), secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient midnightGradient = LinearGradient(
    colors: [Color(0xFF20294B), Color(0xFF171C32), Color(0xFF11162A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient pageGradient(Brightness brightness) => LinearGradient(
    colors: brightness == Brightness.dark
        ? const [Color(0xFF151A32), darkScaffold]
        : const [Color(0xFFF0ECFF), scaffold],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
