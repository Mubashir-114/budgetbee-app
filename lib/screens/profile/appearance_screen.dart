import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/fin_track_theme_tokens.dart';
import '../../core/theme/theme_collection.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currency = context.watch<CurrencyProvider>();

    final tokens = theme.extension<FinTrackThemeTokens>() ??
        FinTrackThemeTokens.resolve(themeProvider.collection, theme.brightness);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: const Text(
          "Appearance",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Interactive Theme Preview
            _LivePreviewCard(
              tokens: tokens,
              collection: themeProvider.collection,
              displayMode: themeProvider.displayMode,
              isDark: isDark,
              currencySymbol: currency.currencySymbol,
            ),
            const SizedBox(height: 24),

            // 2. Theme Collection Section
            Row(
              children: [
                Text(
                  "THEME COLLECTION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "3 PALETTES",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: tokens.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Select FinTrack's financial aesthetic identity and accents.",
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
            const SizedBox(height: 12),

            // 3 Theme Collection Cards
            _ThemeOptionCard(
              collection: ThemeCollection.graphiteChampagne,
              isSelected: themeProvider.collection ==
                  ThemeCollection.graphiteChampagne,
              isDefaultBadge: true,
              swatches: const [
                Color(0xFF171B24), // Background
                Color(0xFF252934), // Surface
                Color(0xFFD6A668), // Champagne
                Color(0xFFE6BE85), // Soft Gold
              ],
              activeTokens: tokens,
              isDark: isDark,
              onTap: () {
                themeProvider.setCollection(
                  ThemeCollection.graphiteChampagne,
                );
                CustomToast.showSuccess(
                  context,
                  "Applied Graphite & Champagne theme",
                );
              },
            ),
            const SizedBox(height: 12),

            _ThemeOptionCard(
              collection: ThemeCollection.obsidianJade,
              isSelected:
                  themeProvider.collection == ThemeCollection.obsidianJade,
              swatches: const [
                Color(0xFF0B111A), // Background
                Color(0xFF151F2B), // Surface
                Color(0xFF38D5B0), // Jade
                Color(0xFF2DD4BF), // Teal
              ],
              activeTokens: tokens,
              isDark: isDark,
              onTap: () {
                themeProvider.setCollection(ThemeCollection.obsidianJade);
                CustomToast.showSuccess(
                  context,
                  "Applied Obsidian & Jade theme",
                );
              },
            ),
            const SizedBox(height: 12),

            _ThemeOptionCard(
              collection: ThemeCollection.arcticBlue,
              isSelected:
                  themeProvider.collection == ThemeCollection.arcticBlue,
              swatches: const [
                Color(0xFF0E1726), // Background
                Color(0xFF162338), // Surface
                Color(0xFF4FA3F7), // Arctic
                Color(0xFF7DD3FC), // Cyan
              ],
              activeTokens: tokens,
              isDark: isDark,
              onTap: () {
                themeProvider.setCollection(ThemeCollection.arcticBlue);
                CustomToast.showSuccess(
                  context,
                  "Applied Arctic Blue theme",
                );
              },
            ),
            const SizedBox(height: 28),

            // 3. Display Mode Section
            Text(
              "DISPLAY MODE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Control light, dark, or system-synchronized theme rendering.",
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
            const SizedBox(height: 12),

            // Display Mode Options
            Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: tokens.divider.withValues(alpha: isDark ? 0.75 : 0.9),
                ),
              ),
              child: Column(
                children: [
                  _DisplayModeTile(
                    mode: AppDisplayMode.system,
                    icon: Icons.brightness_auto_rounded,
                    isSelected:
                        themeProvider.displayMode == AppDisplayMode.system,
                    tokens: tokens,
                    showDivider: true,
                    onTap: () {
                      themeProvider.setDisplayMode(AppDisplayMode.system);
                      CustomToast.showInfo(
                        context,
                        "Display mode set to System Default",
                      );
                    },
                  ),
                  _DisplayModeTile(
                    mode: AppDisplayMode.dark,
                    icon: Icons.dark_mode_rounded,
                    isSelected:
                        themeProvider.displayMode == AppDisplayMode.dark,
                    tokens: tokens,
                    showDivider: true,
                    onTap: () {
                      themeProvider.setDisplayMode(AppDisplayMode.dark);
                      CustomToast.showInfo(
                        context,
                        "Display mode set to Dark Mode",
                      );
                    },
                  ),
                  _DisplayModeTile(
                    mode: AppDisplayMode.light,
                    icon: Icons.light_mode_rounded,
                    isSelected:
                        themeProvider.displayMode == AppDisplayMode.light,
                    tokens: tokens,
                    showDivider: false,
                    onTap: () {
                      themeProvider.setDisplayMode(AppDisplayMode.light);
                      CustomToast.showInfo(
                        context,
                        "Display mode set to Light Mode",
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({
    required this.tokens,
    required this.collection,
    required this.displayMode,
    required this.isDark,
    required this.currencySymbol,
  });

  final FinTrackThemeTokens tokens;
  final ThemeCollection collection;
  final AppDisplayMode displayMode;
  final bool isDark;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tokens.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.primary.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with active badges
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: tokens.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: tokens.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FinTrack Theme Preview",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${collection.displayName} · ${displayMode.displayName}",
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: tokens.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: tokens.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Mini account balance demo
          Text(
            "Total Net Worth",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "$currencySymbol 124,500.00",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: tokens.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "+14.2%",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: tokens.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive sample pills and primary button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: tokens.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      "Primary Action",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: collection == ThemeCollection.graphiteChampagne && isDark
                            ? const Color(0xFF171B24)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: tokens.secondary),
                    const SizedBox(width: 5),
                    Text(
                      "Encrypted",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.collection,
    required this.isSelected,
    required this.swatches,
    required this.activeTokens,
    required this.isDark,
    required this.onTap,
    this.isDefaultBadge = false,
  });

  final ThemeCollection collection;
  final bool isSelected;
  final List<Color> swatches;
  final FinTrackThemeTokens activeTokens;
  final bool isDark;
  final VoidCallback onTap;
  final bool isDefaultBadge;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? activeTokens.primary
        : activeTokens.divider.withValues(alpha: isDark ? 0.7 : 0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: activeTokens.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeTokens.primary.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Radio / Checkmark Icon
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? activeTokens.primary
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? activeTokens.primary
                        : activeTokens.textSecondary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: collection == ThemeCollection.graphiteChampagne && isDark
                            ? const Color(0xFF171B24)
                            : Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Title, Badges & Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            collection.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: activeTokens.textPrimary,
                            ),
                          ),
                        ),
                        if (isDefaultBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: activeTokens.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "DEFAULT",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: activeTokens.primary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      collection.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: activeTokens.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Color swatches row
                    Row(
                      children: swatches.map((color) {
                        return Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisplayModeTile extends StatelessWidget {
  const _DisplayModeTile({
    required this.mode,
    required this.icon,
    required this.isSelected,
    required this.tokens,
    required this.showDivider,
    required this.onTap,
  });

  final AppDisplayMode mode;
  final IconData icon;
  final bool isSelected;
  final FinTrackThemeTokens tokens;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tokens.primary.withValues(alpha: 0.15)
                          : tokens.elevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? tokens.primary : tokens.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mode.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: tokens.primary,
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 64,
            endIndent: 16,
            color: tokens.divider.withValues(alpha: 0.6),
          ),
      ],
    );
  }
}
