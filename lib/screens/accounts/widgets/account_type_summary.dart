import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/account_model.dart';

/// Compact summary row showing counts for each account type.
class AccountTypeSummary extends StatelessWidget {
  final List<AccountModel> accounts;

  const AccountTypeSummary({super.key, required this.accounts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bankCount = accounts.where((a) => a.type == 'bank').length;
    final cashCount = accounts.where((a) => a.type == 'cash').length;
    final walletCount = accounts.where((a) => a.type == 'wallet').length;
    final creditCount = accounts.where((a) => a.type == 'credit_card').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
            AppColors.secondary.withValues(alpha: isDark ? 0.12 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TypeChip(
            icon: Icons.savings_rounded,
            label: 'Bank',
            count: bankCount,
            color: AppColors.primary,
          ),
          _TypeChip(
            icon: Icons.money_rounded,
            label: 'Cash',
            count: cashCount,
            color: AppColors.success,
          ),
          _TypeChip(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Wallet',
            count: walletCount,
            color: AppColors.info,
          ),
          _TypeChip(
            icon: Icons.credit_card_rounded,
            label: 'Credit',
            count: creditCount,
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _TypeChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}
