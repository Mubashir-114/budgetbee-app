import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/report_models.dart';
import '../../../providers/currency_provider.dart';

/// Complete redesign of the Categories Tab for FinTrack 2.0.
/// Features an interactive expense distribution donut chart with a reactive
/// center summary, compact spending cards, and refined budget tracking
/// distinguishing configured budgets from unconfigured limits.
class CategoriesTabView extends StatefulWidget {
  const CategoriesTabView({
    super.key,
    required this.categoryReports,
    required this.onRefresh,
  });

  final List<CategoryReport> categoryReports;
  final Future<void> Function() onRefresh;

  @override
  State<CategoriesTabView> createState() => _CategoriesTabViewState();
}

class _CategoriesTabViewState extends State<CategoriesTabView> {
  int? _selectedCategoryIndex;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reports = widget.categoryReports;

    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        color: colors.primary,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.md),
          children: const [
            EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: "No category data",
              description: "No categorized expenses were found for the selected reporting period.",
            ),
          ],
        ),
      );
    }

    // Filter categories that have expenses
    final expenseCategories = reports.where((r) => r.spent > 0).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. Interactive Expense Distribution Section
            _buildExpenseDistributionSection(context, expenseCategories, colors),
            const SizedBox(height: 20),

            // B. Category Spending List
            if (expenseCategories.isNotEmpty) ...[
              _buildCategorySpendingSection(context, expenseCategories, colors),
              const SizedBox(height: 20),
            ],

            // C. Budget Tracking Section
            _buildBudgetTrackingSection(context, reports, colors),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // A. INTERACTIVE EXPENSE DISTRIBUTION
  // ===========================================================================

  Widget _buildExpenseDistributionSection(
    BuildContext context,
    List<CategoryReport> expenseCategories,
    dynamic colors,
  ) {
    final currency = context.watch<CurrencyProvider>();
    final double totalSpent = expenseCategories.fold(0.0, (sum, item) => sum + item.spent);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: colors.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Expense Distribution",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                "${expenseCategories.length} categories",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (expenseCategories.isEmpty || totalSpent <= 0)
            _buildEmptyExpensesState(colors)
          else if (expenseCategories.length == 1)
            _buildSingleCategoryFocusView(expenseCategories.first, totalSpent, colors)
          else
            _buildInteractiveDonutChart(expenseCategories, totalSpent, currency, colors),
        ],
      ),
    );
  }

  Widget _buildEmptyExpensesState(dynamic colors) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.donut_large_rounded,
            size: 38,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            "No expenses recorded in this period",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Informative companion summary when a single category represents 100% of spending.
  Widget _buildSingleCategoryFocusView(
    CategoryReport cat,
    double totalSpent,
    dynamic colors,
  ) {
    final currency = context.watch<CurrencyProvider>();
    final catColor = getCategoryColor(cat.category);
    final catIcon = getCategoryIcon(cat.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          // Circular Focus Icon
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
              border: Border.all(color: catColor.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Icon(catIcon, color: catColor, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat.category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "100% Share",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: catColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(totalSpent),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "All expenditures in this period were concentrated solely in ${cat.category}.",
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveDonutChart(
    List<CategoryReport> categories,
    double totalSpent,
    CurrencyProvider currency,
    dynamic colors,
  ) {
    final selectedIdx = _selectedCategoryIndex;
    final hasSelection = selectedIdx != null && selectedIdx >= 0 && selectedIdx < categories.length;
    final activeCategory = hasSelection ? categories[selectedIdx] : null;

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final isSelected = selectedIdx == i;
      final catColor = getCategoryColor(cat.category);

      sections.add(
        PieChartSectionData(
          color: catColor,
          value: cat.spent,
          title: '', // Titles rendered in center and coordinated legend for clarity
          radius: isSelected ? 30 : 22,
          badgePositionPercentageOffset: .98,
        ),
      );
    }

    return Column(
      children: [
        // Donut Chart with Reactive Center Info
        SizedBox(
          height: 190,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 56,
                  sectionsSpace: 2.5,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent && response?.touchedSection != null) {
                        final touchedIdx = response!.touchedSection!.touchedSectionIndex;
                        setState(() {
                          if (_selectedCategoryIndex == touchedIdx) {
                            _selectedCategoryIndex = null;
                          } else if (touchedIdx >= 0 && touchedIdx < categories.length) {
                            _selectedCategoryIndex = touchedIdx;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              // Reactive Center Widget
              GestureDetector(
                onTap: () {
                  setState(() => _selectedCategoryIndex = null);
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (activeCategory != null) ...[
                        Icon(
                          getCategoryIcon(activeCategory.category),
                          size: 18,
                          color: getCategoryColor(activeCategory.category),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeCategory.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          "${totalSpent > 0 ? ((activeCategory.spent / totalSpent) * 100).toStringAsFixed(1) : 0}%",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          currency.format(activeCategory.spent),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          "Total Spent",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            currency.format(totalSpent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        Text(
                          "Tap to inspect",
                          style: TextStyle(
                            fontSize: 8,
                            color: colors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Interactive Coordinated Legend Chips
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(categories.length, (idx) {
            final cat = categories[idx];
            final isSelected = selectedIdx == idx;
            final catColor = getCategoryColor(cat.category);
            final pct = totalSpent > 0 ? (cat.spent / totalSpent * 100) : 0.0;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = isSelected ? null : idx;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: AppMotion.quick,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? catColor.withValues(alpha: 0.16)
                      : colors.elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? catColor : colors.cardBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: catColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${pct.toStringAsFixed(0)}%",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: catColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ===========================================================================
  // B. CATEGORY SPENDING CARDS
  // ===========================================================================

  Widget _buildCategorySpendingSection(
    BuildContext context,
    List<CategoryReport> categories,
    dynamic colors,
  ) {
    final currency = context.watch<CurrencyProvider>();
    final double totalSpent = categories.fold(0.0, (sum, item) => sum + item.spent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category Spending Breakdown",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategoryIndex == index;
            final catColor = getCategoryColor(cat.category);
            final catIcon = getCategoryIcon(cat.category);
            final shareRatio = totalSpent > 0 ? (cat.spent / totalSpent) : 0.0;
            final sharePct = shareRatio * 100;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(
                  color: isSelected ? catColor : colors.cardBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = isSelected ? null : index;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: catColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Icon(catIcon, color: catColor, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.category,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${sharePct.toStringAsFixed(1)}% of total expenses",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currency.format(cat.spent),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: shareRatio.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: colors.divider.withValues(alpha: 0.4),
                            valueColor: AlwaysStoppedAnimation<Color>(catColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // C. BUDGET TRACKING
  // ===========================================================================

  Widget _buildBudgetTrackingSection(
    BuildContext context,
    List<CategoryReport> reports,
    dynamic colors,
  ) {
    final currency = context.watch<CurrencyProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Budget Tracking Status",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              "${reports.where((r) => r.budget > 0).length} configured",
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final r = reports[index];
            final hasBudget = r.budget > 0;
            final isOver = hasBudget && r.spent > r.budget;
            final progress = hasBudget ? (r.spent / r.budget).clamp(0.0, 1.0) : 0.0;
            final ratio = hasBudget ? (r.spent / r.budget) : 0.0;
            final isWarning = hasBudget && !isOver && ratio >= 0.85;

            final Color statusColor;
            final String badgeText;
            if (!hasBudget) {
              statusColor = colors.textSecondary;
              badgeText = "No Budget Set";
            } else if (isOver) {
              statusColor = colors.danger;
              badgeText = "Exceeded Limit";
            } else if (isWarning) {
              statusColor = colors.warning;
              badgeText = "Near Limit";
            } else {
              statusColor = colors.success;
              badgeText = "On Track";
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Category & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            getCategoryIcon(r.category),
                            size: 16,
                            color: getCategoryColor(r.category),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            r.category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Spending vs Budget Figures
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        hasBudget
                            ? "${currency.format(r.spent)} spent of ${currency.format(r.budget)}"
                            : "Spent: ${currency.format(r.spent)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (hasBudget)
                        Text(
                          "${(ratio * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar if budget is configured
                  if (hasBudget) ...[
                    AnimatedProgressBar(
                      value: progress,
                      color: statusColor,
                      backgroundColor: colors.divider.withValues(alpha: 0.4),
                      height: 6,
                      semanticLabel: '${r.category} budget utilization',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOver
                          ? "Over limit by ${currency.format(r.spent - r.budget)}"
                          : "Remaining balance: ${currency.format(r.remaining)}",
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Text(
                      "No budget configured for this category in this period.",
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
