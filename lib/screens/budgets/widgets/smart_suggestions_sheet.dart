import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../models/budget_model.dart';
import '../../../providers/budget_provider.dart';

/// Interactive smart suggestions bottom sheet for FinTrack Budgets.
/// Shows deterministic recommendations based on past 3 months' expenses,
/// rationale breakdown, historical facts, and explicit apply action with confirmation.
class SmartSuggestionsSheet extends StatelessWidget {
  const SmartSuggestionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    context.read<BudgetProvider>().loadBudgetSuggestions();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SmartSuggestionsSheet(),
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
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Smart Budget Suggestions",
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
                "Deterministic recommendations based on your previous 3-month spending trends. Requires explicit user confirmation.",
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Content Body
              Expanded(
                child: provider.isSuggestionsLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
                            const SizedBox(height: 12),
                            Text(
                              "Analyzing spending trends...",
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : provider.suggestions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.insights_rounded, size: 40, color: colors.textSecondary),
                                const SizedBox(height: 12),
                                Text(
                                  "No suggestions available yet.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Keep tracking regular expenses to generate historical spending insights.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: provider.suggestions.length,
                            itemBuilder: (context, index) {
                              final s = provider.suggestions[index];
                              return _SuggestionCard(suggestion: s);
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});

  final BudgetSuggestionModel suggestion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.read<BudgetProvider>();
    final catIcon = getCategoryIcon(suggestion.categoryName);
    final catColor = getCategoryColor(suggestion.categoryName);

    final trend = suggestion.estimates.trend.toLowerCase();
    Color trendColor = colors.textSecondary;
    IconData trendIcon = Icons.trending_flat_rounded;
    if (trend == "increasing") {
      trendColor = colors.danger;
      trendIcon = Icons.trending_up_rounded;
    } else if (trend == "decreasing") {
      trendColor = colors.success;
      trendIcon = Icons.trending_down_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Category, Icon & Trend
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(catIcon, size: 17, color: catColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        "Suggested: ₹${suggestion.estimates.suggestedBudget}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, size: 13, color: trendColor),
                      const SizedBox(width: 4),
                      Text(
                        "Trend: ${suggestion.estimates.trend.toUpperCase()}",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Rationale explanation
            Text(
              suggestion.estimates.rationale,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Historical facts row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.divider),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FactItem(label: "Last Month", amount: "₹${suggestion.historicalFacts.lastMonthSpent}"),
                  _FactItem(label: "2 Mo Ago", amount: "₹${suggestion.historicalFacts.twoMonthsAgoSpent}"),
                  _FactItem(label: "3 Mo Avg", amount: "₹${suggestion.historicalFacts.threeMonthAverage}"),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Apply Button with Explicit User Confirmation
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text("APPLY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.isDark ? const Color(0xFF0B111A) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(80, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text("Confirm Budget"),
                      content: Text(
                        "Apply suggested budget of ₹${suggestion.estimates.suggestedBudget} for ${suggestion.categoryName}?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx, false),
                          child: const Text("CANCEL"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogCtx, true),
                          child: const Text("CONFIRM"),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    final ok = await provider.applySuggestion(suggestion);
                    if (context.mounted) {
                      if (ok) {
                        CustomToast.showSuccess(
                          context,
                          "Budget for ${suggestion.categoryName} applied",
                        );
                        Navigator.pop(context);
                      } else {
                        CustomToast.showError(
                          context,
                          provider.errorMessage ?? "Failed to apply suggestion",
                        );
                      }
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FactItem extends StatelessWidget {
  const _FactItem({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
        const SizedBox(height: 1),
        Text(
          amount,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textPrimary),
        ),
      ],
    );
  }
}

/// Backward compatibility alias for existing code/tests
class SmartSuggestionsBottomSheet extends StatelessWidget {
  const SmartSuggestionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmartSuggestionsSheet();
  }
}
