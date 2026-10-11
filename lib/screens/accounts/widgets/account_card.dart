import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/account_model.dart';
import 'account_icon.dart';
import 'money_text.dart';

/// Card displayed in the accounts list. Visually distinguishes credit-card
/// liabilities (red accent) from asset accounts (primary accent).
class AccountCard extends StatelessWidget {
  final AccountModel account;
  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCredit = account.type == 'credit_card';
    final accentColor = isCredit ? AppColors.danger : AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                AccountIcon(
                  type: account.type,
                  subtype: account.subtype,
                  size: 44,
                  accentColor: accentColor,
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              account.displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (account.isDefault)
                            _DefaultBadge(),
                        ],
                      ),
                      const SizedBox(height: 3),
                      _SubtitleRow(account: account, isDark: isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount + chevron
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    MoneyText(
                      decimalString: (isCredit && account.creditLimit != null)
                          ? account.creditLimit!
                          : account.openingAmount,
                      currencyCode: account.currencyCode,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCredit ? AppColors.danger : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCredit ? 'Credit limit' : 'Opening amount',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      ),
      child: const Text(
        'Default',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  final AccountModel account;
  final bool isDark;

  const _SubtitleRow({required this.account, required this.isDark});

  String get _subtitle {
    final parts = <String>[];
    if (account.institutionName != null) {
      parts.add(account.institutionName!);
    }
    if (account.maskedLast4 != null) {
      parts.add('••••${account.maskedLast4}');
    }
    if (parts.isEmpty) {
      return _typeLabel(account.subtype);
    }
    return parts.join(' · ');
  }

  String _typeLabel(String subtype) {
    switch (subtype) {
      case 'savings':
        return 'Savings Account';
      case 'current':
        return 'Current Account';
      case 'salary':
        return 'Salary Account';
      case 'stored_value':
        return 'Digital Wallet';
      case 'credit_card':
        return 'Credit Card';
      case 'cash':
        return 'Cash';
      default:
        return subtype;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Text(
      _subtitle,
      style: TextStyle(fontSize: 12, color: color),
      overflow: TextOverflow.ellipsis,
    );
  }
}
