import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../models/budget_model.dart';
import '../../../providers/budget_provider.dart';

/// Historical budget comparison sheet for FinTrack Budgets.
/// Shows past 6 months' configured budget versus actual spending, variance, and utilization.
class BudgetHistorySheet extends StatelessWidget {
  const BudgetHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    context.read<BudgetProvider>().loadBudgetHistory(months: 6);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const BudgetHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final colors = AppColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Historical Budget Comparison",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: colors.textSecondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Text(
                "Past monthly budget vs actual spending performance comparison.",
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Content Body
              Expanded(
                child: provider.isHistoryLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
                            const SizedBox(height: 12),
                            Text(
                              "Loading budget records...",
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : provider.history.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_toggle_off_rounded, size: 40, color: colors.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  "No budget history recorded yet.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Prior months will appear here as you maintain your monthly spending caps.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: provider.history.length,
                            itemBuilder: (context, index) {
                              final h = provider.history[index];
                              return _HistoryItemCard(history: h);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryItemCard extends StatelessWidget {
  const _HistoryItemCard({required this.history});

  final BudgetHistoryItemModel history;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final monthName = DateFormat('MMMM').format(DateTime(history.year, history.month));
    final isOver = history.status == "exceeded";

    final spentNum = double.tryParse(history.totalSpent) ?? 0.0;
    final budgetNum = double.tryParse(history.totalBudget) ?? 0.0;
    final progress = budgetNum > 0 ? (spentNum / budgetNum).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isOver ? colors.danger.withValues(alpha: 0.35) : colors.cardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$monthName ${history.year}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${history.categoryCount} categories budgeted",
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Spent: ₹${history.totalSpent} / ₹${history.totalBudget}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOver ? colors.danger : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${history.utilizationPercentage}% used",
                      style: TextStyle(
                        fontSize: 11,
                        color: isOver ? colors.danger : colors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedProgressBar(
              value: progress,
              backgroundColor: colors.divider,
              color: isOver ? colors.danger : colors.primary,
              height: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// Backward compatibility alias for existing code/tests
class BudgetHistoryBottomSheet extends StatelessWidget {
  const BudgetHistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetHistorySheet();
  }
}
