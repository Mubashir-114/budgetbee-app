import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Compact, theme-aware default account settings component.
///
/// Features:
/// - Explains default account purpose (primary account for new transactions/transfers).
/// - Refined theme-aware switch with smooth feedback.
/// - Informative callout explaining automatic default behavior when first asset account.
/// - Strictly disables/hides setting default for credit card liability accounts.
class AccountDefaultSettingsCard extends StatelessWidget {
  final bool isDefault;
  final ValueChanged<bool> onChanged;
  final bool isCreditCard;
  final bool hasExistingDefault;

  const AccountDefaultSettingsCard({
    super.key,
    required this.isDefault,
    required this.onChanged,
    required this.isCreditCard,
    this.hasExistingDefault = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCreditCard) {
      // Ineligible credit card notice
      return Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: tokens.divider),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: tokens.elevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Account Not Applicable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Credit cards represent liability lines and cannot serve as the default asset account for everyday spending.',
                      style: TextStyle(
                        fontSize: 11,
                        color: tokens.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: isDefault ? tokens.primary.withValues(alpha: 0.6) : tokens.divider,
            width: isDefault ? 1.4 : 1.0,
          ),
          boxShadow: isDefault
              ? [
                  BoxShadow(
                    color: tokens.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              secondary: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDefault
                      ? tokens.primary.withValues(alpha: 0.2)
                      : tokens.elevated,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(
                  isDefault ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 20,
                  color: isDefault ? tokens.primary : tokens.textSecondary,
                ),
              ),
              title: Text(
                'Set as Default Account',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              subtitle: Text(
                'Primary source for new transactions, expense logging, and quick transfers.',
                style: TextStyle(
                  fontSize: 11,
                  color: tokens.textSecondary,
                  height: 1.3,
                ),
              ),
              value: isDefault,
              onChanged: onChanged,
              activeTrackColor: tokens.primary.withValues(alpha: 0.35),
              activeThumbColor: tokens.primary,
            ),
            if (!hasExistingDefault)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: tokens.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  border: Border.all(
                    color: tokens.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: tokens.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your first active asset account will automatically be designated as default by FinTrack.',
                        style: TextStyle(
                          fontSize: 11,
                          color: tokens.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
