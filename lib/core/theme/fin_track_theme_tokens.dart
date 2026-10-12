import 'package:flutter/material.dart';
import 'theme_collection.dart';

/// Centralized semantic design tokens for FinTrack 2.0.
/// Implemented as a [ThemeExtension] so any widget can easily inspect
/// the active theme tokens via `Theme.of(context).extension<FinTrackThemeTokens>()`.
@immutable
class FinTrackThemeTokens extends ThemeExtension<FinTrackThemeTokens> {
  const FinTrackThemeTokens({
    required this.collection,
    required this.isDark,
    required this.primary,
    required this.primaryDeep,
    required this.secondary,
    required this.highlight,
    required this.background,
    required this.surface,
    required this.elevated,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.info,
    required this.transfer,
    required this.cardBorder,
    required this.midnightGradient,
    required this.cardGradient,
  });

  final ThemeCollection collection;
  final bool isDark;
  final Color primary;
  final Color primaryDeep;
  final Color secondary;
  final Color highlight;
  final Color background;
  final Color surface;
  final Color elevated;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color info;
  final Color transfer;
  final Color cardBorder;
  final LinearGradient midnightGradient;
  final LinearGradient cardGradient;

  // ===========================================================================
  // 1. Graphite & Champagne (New Default Identity)
  // ===========================================================================

  static const FinTrackThemeTokens graphiteChampagneDark = FinTrackThemeTokens(
    collection: ThemeCollection.graphiteChampagne,
    isDark: true,
    primary: Color(0xFFD6A668), // Champagne accent
    primaryDeep: Color(0xFFBE8F50), // Pressed / darker champagne
    secondary: Color(0xFFE6BE85), // Soft gold highlight
    highlight: Color(0xFFE6BE85),
    background: Color(0xFF171B24), // Background: #171B24
    surface: Color(0xFF252934), // Surface: #252934
    elevated: Color(0xFF30343F), // Elevated surface: #30343F
    divider: Color(0xFF393D48), // Dividers: #393D48
    textPrimary: Color(0xFFF4EFE7), // Primary text: #F4EFE7
    textSecondary: Color(0xFFB5AFAB), // Secondary text: #B5AFAB
    success: Color(0xFF38D5B0),
    danger: Color(0xFFFF6B81),
    warning: Color(0xFFFFB84D),
    info: Color(0xFF5AB0FF),
    transfer: Color(0xFF88A0BF),
    cardBorder: Color(0xFF393D48),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF30343F), Color(0xFF252934), Color(0xFF171B24)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF252934), Color(0xFF1F232D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const FinTrackThemeTokens graphiteChampagneLight = FinTrackThemeTokens(
    collection: ThemeCollection.graphiteChampagne,
    isDark: false,
    primary: Color(0xFFB88542), // Accessible champagne gold (>4.5:1 on light)
    primaryDeep: Color(0xFF9E6E30),
    secondary: Color(0xFFD6A668),
    highlight: Color(0xFFD6A668),
    background: Color(0xFFF8F6F1), // Warm ivory
    surface: Color(0xFFFFFFFF), // Crisp surface
    elevated: Color(0xFFF0EBE1), // Soft warm ivory elevated
    divider: Color(0xFFE3DDD2), // Accessible warm divider
    textPrimary: Color(0xFF1C1E24), // Soft graphite text
    textSecondary: Color(0xFF6B6760), // Muted graphite secondary
    success: Color(0xFF10B981),
    danger: Color(0xFFE11D48),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
    transfer: Color(0xFF64748B),
    cardBorder: Color(0xFFE3DDD2),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFF8F6F1), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFFBF9F5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ===========================================================================
  // 2. Obsidian & Jade
  // ===========================================================================

  static const FinTrackThemeTokens obsidianJadeDark = FinTrackThemeTokens(
    collection: ThemeCollection.obsidianJade,
    isDark: true,
    primary: Color(0xFF38D5B0), // Jade primary accent
    primaryDeep: Color(0xFF159B82),
    secondary: Color(0xFF2DD4BF),
    highlight: Color(0xFFFFCB78),
    background: Color(0xFF0B111A),
    surface: Color(0xFF151F2B),
    elevated: Color(0xFF1C2935),
    divider: Color(0xFF293846),
    textPrimary: Color(0xFFF3F7F8),
    textSecondary: Color(0xFF9CABB8),
    success: Color(0xFF38D5B0),
    danger: Color(0xFFFF6B81),
    warning: Color(0xFFFFB84D),
    info: Color(0xFF5AB0FF),
    transfer: Color(0xFF88A0BF),
    cardBorder: Color(0xFF293846),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF1C2935), Color(0xFF151F2B), Color(0xFF0B111A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF151F2B), Color(0xFF0F1722)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const FinTrackThemeTokens obsidianJadeLight = FinTrackThemeTokens(
    collection: ThemeCollection.obsidianJade,
    isDark: false,
    primary: Color(0xFF159B82),
    primaryDeep: Color(0xFF0E705E),
    secondary: Color(0xFF2DD4BF),
    highlight: Color(0xFFD97706),
    background: Color(0xFFF4F7F8),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFE8EEF0),
    divider: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    success: Color(0xFF10B981),
    danger: Color(0xFFE11D48),
    warning: Color(0xFFD97706),
    info: Color(0xFF2563EB),
    transfer: Color(0xFF64748B),
    cardBorder: Color(0xFFE2E8F0),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFF4F7F8), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  // ===========================================================================
  // 3. Arctic Blue
  // ===========================================================================

  static const FinTrackThemeTokens arcticBlueDark = FinTrackThemeTokens(
    collection: ThemeCollection.arcticBlue,
    isDark: true,
    primary: Color(0xFF4FA3F7), // Arctic blue accent
    primaryDeep: Color(0xFF2B80DE),
    secondary: Color(0xFF7DD3FC), // Cyan highlight
    highlight: Color(0xFF7DD3FC),
    background: Color(0xFF0E1726),
    surface: Color(0xFF162338),
    elevated: Color(0xFF1E304B),
    divider: Color(0xFF273E5D),
    textPrimary: Color(0xFFF0F6FC),
    textSecondary: Color(0xFF94A3B8),
    success: Color(0xFF38D5B0),
    danger: Color(0xFFFF6B81),
    warning: Color(0xFFFFB84D),
    info: Color(0xFF4FA3F7),
    transfer: Color(0xFF88A0BF),
    cardBorder: Color(0xFF273E5D),
    midnightGradient: LinearGradient(
      colors: [Color(0xFF1E304B), Color(0xFF162338), Color(0xFF0E1726)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFF162338), Color(0xFF111C2E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const FinTrackThemeTokens arcticBlueLight = FinTrackThemeTokens(
    collection: ThemeCollection.arcticBlue,
    isDark: false,
    primary: Color(0xFF0284C7),
    primaryDeep: Color(0xFF0369A1),
    secondary: Color(0xFF38BDF8),
    highlight: Color(0xFF38BDF8),
    background: Color(0xFFF1F6FB),
    surface: Color(0xFFFFFFFF),
    elevated: Color(0xFFE1EDF7),
    divider: Color(0xFFD3E2F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    success: Color(0xFF10B981),
    danger: Color(0xFFE11D48),
    warning: Color(0xFFD97706),
    info: Color(0xFF0284C7),
    transfer: Color(0xFF64748B),
    cardBorder: Color(0xFFD3E2F0),
    midnightGradient: LinearGradient(
      colors: [Color(0xFFF1F6FB), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    cardGradient: LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF6F9FD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static FinTrackThemeTokens resolve(ThemeCollection collection, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (collection) {
      case ThemeCollection.graphiteChampagne:
        return dark ? graphiteChampagneDark : graphiteChampagneLight;
      case ThemeCollection.obsidianJade:
        return dark ? obsidianJadeDark : obsidianJadeLight;
      case ThemeCollection.arcticBlue:
        return dark ? arcticBlueDark : arcticBlueLight;
    }
  }

  @override
  ThemeExtension<FinTrackThemeTokens> copyWith({
    ThemeCollection? collection,
    bool? isDark,
    Color? primary,
    Color? primaryDeep,
    Color? secondary,
    Color? highlight,
    Color? background,
    Color? surface,
    Color? elevated,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? danger,
    Color? warning,
    Color? info,
    Color? transfer,
    Color? cardBorder,
    LinearGradient? midnightGradient,
    LinearGradient? cardGradient,
  }) {
    return FinTrackThemeTokens(
      collection: collection ?? this.collection,
      isDark: isDark ?? this.isDark,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      secondary: secondary ?? this.secondary,
      highlight: highlight ?? this.highlight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      transfer: transfer ?? this.transfer,
      cardBorder: cardBorder ?? this.cardBorder,
      midnightGradient: midnightGradient ?? this.midnightGradient,
      cardGradient: cardGradient ?? this.cardGradient,
    );
  }

  @override
  ThemeExtension<FinTrackThemeTokens> lerp(
    covariant ThemeExtension<FinTrackThemeTokens>? other,
    double t,
  ) {
    if (other is! FinTrackThemeTokens) return this;
    return FinTrackThemeTokens(
      collection: t < 0.5 ? collection : other.collection,
      isDark: t < 0.5 ? isDark : other.isDark,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t) ?? primaryDeep,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      highlight: Color.lerp(highlight, other.highlight, t) ?? highlight,
      background: Color.lerp(background, other.background, t) ?? background,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      elevated: Color.lerp(elevated, other.elevated, t) ?? elevated,
      divider: Color.lerp(divider, other.divider, t) ?? divider,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      success: Color.lerp(success, other.success, t) ?? success,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      transfer: Color.lerp(transfer, other.transfer, t) ?? transfer,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t) ?? cardBorder,
      midnightGradient: LinearGradient.lerp(midnightGradient, other.midnightGradient, t) ?? midnightGradient,
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t) ?? cardGradient,
    );
  }
}
