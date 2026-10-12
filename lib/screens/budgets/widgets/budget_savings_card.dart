import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';

/// Elegant savings target goal card for FinTrack Budgets.
/// Shows net savings progress, income/target comparison, and milestone celebration feedback.
class BudgetSavingsCard extends StatelessWidget {
  const BudgetSavingsCard({
    super.key,
    required this.savings,
    required this.currency,
    required this.onEditTarget,
  });

  final BudgetSavingsProgressModel savings;
  final CurrencyProvider currency;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final incomeNum = double.tryParse(savings.totalIncome) ?? 0.0;
    final netSavingsNum = double.tryParse(savings.netSavings) ?? 0.0;
    final targetNum = double.tryParse(savings.savingsTarget ?? '') ?? 0.0;
    final isAchieved = savings.isTargetAchieved;

    final progressVal = targetNum > 0
        ? (netSavingsNum / targetNum).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isAchieved && targetNum > 0
              ? colors.success.withValues(alpha: 0.45)
              : colors.cardBorder,
          width: isAchieved && targetNum > 0 ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAchieved ? colors.success : colors.secondary)
                .withValues(alpha: isDark ? 0.05 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Icon, Title, and Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.savings_rounded,
                        size: 18,
                        color: colors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Net Savings Progress",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onEditTarget,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(60, 30),
                  ),
                  child: Text(
                    targetNum > 0 ? "Edit Target" : "Set Target",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Financial Metrics: Net Saved vs Target / Income
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Net Saved: ${currency.format(netSavingsNum)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: netSavingsNum >= 0 ? colors.success : colors.danger,
                  ),
                ),
                if (targetNum > 0)
                  Text(
                    "Target: ${currency.format(targetNum)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  )
                else
                  Text(
                    "Income: ${currency.format(incomeNum)}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
              ],
            ),

            if (targetNum > 0) ...[
              const SizedBox(height: 10),
              AnimatedProgressBar(
                value: progressVal,
                backgroundColor: colors.divider,
                color: isAchieved ? colors.success : colors.primary,
                height: 7,
                semanticLabel: 'Savings target achieved',
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${savings.progressPercentage ?? '0.0'}% achieved",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isAchieved ? colors.success : colors.primary,
                    ),
                  ),
                  if (isAchieved)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "GOAL REACHED ✨",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: colors.success,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
