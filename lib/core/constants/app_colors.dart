import 'package:flutter/material.dart';

/// Obsidian & Jade semantic palette shared by every financial surface.
class AppColors {
  AppColors._();

  // Primary Obsidian & Jade palette
  static const Color primary = Color(0xFF38D5B0); // Jade primary accent
  static const Color primaryDeep = Color(0xFF159B82); // Accent pressed/dark
  static const Color secondary = Color(0xFF2DD4BF); // Clean teal companion
  static const Color gold = Color(0xFFFFCB78);

  static const Color success = Color(0xFF38D5B0);
  static const Color income = success;
  static const Color danger = Color(0xFFFF6B81);
  static const Color expense = danger;
  static const Color warning = Color(0xFFFFB84D);
  static const Color info = Color(0xFF5AB0FF);
  static const Color transfer = Color(0xFF88A0BF);
  static const Color savings = secondary;

  // Light theme tokens
  static const Color scaffold = Color(0xFFF4F7F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark theme tokens (Obsidian & Jade)
  static const Color darkScaffold = Color(0xFF0B111A);
  static const Color surfaceDark = Color(0xFF151F2B);
  static const Color cardDark = Color(0xFF151F2B);
  static const Color elevatedDark = Color(0xFF1C2935);
  static const Color dividerDark = Color(0xFF293846);
  static const Color textLight = Color(0xFFF3F7F8);
  static const Color textSecondaryDark = Color(0xFF9CABB8);

  static const LinearGradient auroraGradient = LinearGradient(
    colors: [primary, Color(0xFF2DD4BF), primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient midnightGradient = LinearGradient(
    colors: [Color(0xFF1C2935), Color(0xFF151F2B), Color(0xFF0B111A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient pageGradient(Brightness brightness) => LinearGradient(
    colors: brightness == Brightness.dark
        ? const [Color(0xFF151F2B), darkScaffold]
        : const [Color(0xFFF8FAFB), scaffold],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
