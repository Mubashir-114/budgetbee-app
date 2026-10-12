import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_collection.dart';
import '../theme/fin_track_theme_tokens.dart';
import '../../providers/theme_provider.dart';

/// The official FinTrack 2.0 wallet-and-growth logo component.
/// Dynamically adapts artwork according to the active [ThemeCollection].
class FinTrackLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final ThemeCollection? collection;
  final bool showBorder;
  final bool showShadow;

  const FinTrackLogo({
    super.key,
    this.size = 48,
    this.borderRadius,
    this.collection,
    this.showBorder = false,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeCollection =
        collection ?? context.watch<ThemeProvider>().collection;
    final theme = Theme.of(context);
    final tokens = theme.extension<FinTrackThemeTokens>() ??
        FinTrackThemeTokens.resolve(activeCollection, theme.brightness);

    final radius = borderRadius ?? (size * 0.28);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(
                color: tokens.primary.withValues(alpha: 0.35),
                width: 1.5,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: tokens.primary.withValues(alpha: 0.25),
                  blurRadius: size * 0.3,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          activeCollection.logoAssetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: tokens.primary.withValues(alpha: 0.14),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: size * 0.55,
                color: tokens.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Branded header displaying the FinTrack 2.0 logo alongside typography.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final ThemeCollection? collection;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showSubtitle = true,
    this.collection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCollection =
        collection ?? context.watch<ThemeProvider>().collection;
    final tokens = theme.extension<FinTrackThemeTokens>() ??
        FinTrackThemeTokens.resolve(activeCollection, theme.brightness);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FinTrackLogo(
          size: size,
          collection: activeCollection,
          showShadow: true,
          showBorder: true,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "FinTrack",
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: tokens.textPrimary,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: tokens.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                "2.0",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 6),
          Text(
            "Manage your money smarter",
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}