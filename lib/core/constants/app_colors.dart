import 'package:flutter/material.dart';
import '../theme/fin_track_theme_tokens.dart';

/// Centralized FinTrack design tokens.
/// The default identity is Graphite & Champagne, with support for
/// runtime theme collection switches via [FinTrackThemeTokens].
class AppColors {
  AppColors._();

  // Primary Graphite & Champagne palette (Default FinTrack identity)
  static const Color primary = Color(0xFFD6A668); // Champagne primary accent
  static const Color primaryDeep = Color(0xFFBE8F50); // Accent pressed/darker
  static const Color secondary = Color(0xFFE6BE85); // Soft gold highlight
  static const Color gold = Color(0xFFE6BE85);

  static const Color success = Color(0xFF38D5B0);
  static const Color income = success;
  static const Color danger = Color(0xFFFF6B81);
  static const Color expense = danger;
  static const Color warning = Color(0xFFFFB84D);
  static const Color info = Color(0xFF5AB0FF);
  static const Color transfer = Color(0xFF88A0BF);
  static const Color savings = secondary;

  // Light theme tokens (Warm ivory, soft graphite, accessible contrast)
  static const Color scaffold = Color(0xFFF8F6F1);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFE3DDD2);
  static const Color textDark = Color(0xFF1C1E24);
  static const Color textSecondaryLight = Color(0xFF6B6760);

  // Dark theme tokens (Graphite & Champagne)
  static const Color darkScaffold = Color(0xFF171B24);
  static const Color surfaceDark = Color(0xFF252934);
  static const Color cardDark = Color(0xFF252934);
  static const Color elevatedDark = Color(0xFF30343F);
  static const Color dividerDark = Color(0xFF393D48);
  static const Color textLight = Color(0xFFF4EFE7);
  static const Color textSecondaryDark = Color(0xFFB5AFAB);

  // Approved FinTrack brand mark gradient (preserved without recoloring original artwork)
  static const LinearGradient auroraGradient = LinearGradient(
    colors: [Color(0xFF38D5B0), Color(0xFF2DD4BF), Color(0xFF159B82)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient champagneGradient = LinearGradient(
    colors: [Color(0xFFE6BE85), primary, primaryDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient midnightGradient = LinearGradient(
    colors: [Color(0xFF30343F), Color(0xFF252934), Color(0xFF171B24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient pageGradient(Brightness brightness) => LinearGradient(
    colors: brightness == Brightness.dark
        ? const [Color(0xFF252934), darkScaffold]
        : const [Color(0xFFFCFAF6), scaffold],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Helper to get the active theme extension tokens from the current context.
  static FinTrackThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<FinTrackThemeTokens>() ??
        FinTrackThemeTokens.graphiteChampagneDark;
  }
}
