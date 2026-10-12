import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/budget_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/budget_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/custom_toast.dart';
import 'widgets/budget_month_selector.dart';
import 'widgets/budget_hero_overview.dart';
import 'widgets/category_budget_card.dart';
import 'widgets/budget_savings_card.dart';
import 'widgets/budget_alerts_banner.dart';
import 'widgets/budget_empty_state.dart';
import 'widgets/add_edit_budget_sheet.dart';
import 'widgets/smart_suggestions_sheet.dart';
import 'widgets/budget_history_sheet.dart';

// Re-export sheet widgets so existing imports or test references remain functional
export 'widgets/add_edit_budget_sheet.dart' show AddEditBudgetDialog, AddEditBudgetSheet;
export 'widgets/smart_suggestions_sheet.dart' show SmartSuggestionsBottomSheet, SmartSuggestionsSheet;
export 'widgets/budget_history_sheet.dart' show BudgetHistoryBottomSheet, BudgetHistorySheet;

/// FinTrack 2.0 Budgets Screen — THE LIVING BUDGET.
/// A premium, interactive and animated financial planning experience.
class BudgetsListScreen extends StatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  State<BudgetsListScreen> createState() => _BudgetsListScreenState();
}

class _BudgetsListScreenState extends State<BudgetsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadAllBudgetData();
    });
  }

  void _showAddEditSheet([BudgetCategoryProgressModel? categoryBudget]) {
    AddEditBudgetSheet.show(context, categoryBudget: categoryBudget);
  }

  void _showSavingsTargetDialog() {
    final provider = context.read<BudgetProvider>();
    final currentTarget = provider.userSavingsTarget?.toString() ??
        provider.progress?.savings.savingsTarget ??
        '';
    final controller = TextEditingController(text: currentTarget);

    showDialog(
      context: context,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            "Monthly Savings Target",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: colors.textPrimary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(color: colors.cardBorder),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Set a net savings target (Income - Expenses) for this month.",
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Target Amount",
                  prefixText: "₹ ",
                  filled: true,
                  fillColor: colors.elevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: TextStyle(color: colors.textSecondary)),
            ),
            if (currentTarget.isNotEmpty)
              TextButton(
                onPressed: () {
                  provider.setUserSavingsTarget(null);
                  Navigator.pop(ctx);
                  CustomToast.showSuccess(context, "Savings target cleared");
                },
                child: Text("CLEAR", style: TextStyle(color: colors.danger)),
              ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(controller.text.trim());
                if (amount != null && amount > 0) {
                  provider.setUserSavingsTarget(amount);
                  Navigator.pop(ctx);
                  CustomToast.showSuccess(context, "Savings target updated");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.isDark ? const Color(0xFF0B111A) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              child: const Text("SET TARGET"),
            ),
          ],
        );
      },
    );
  }

  void _showSuggestionsSheet() {
    SmartSuggestionsSheet.show(context);
  }

  void _showHistorySheet() {
    BudgetHistorySheet.show(context);
  }

  void _handlePreviousMonth() {
    final provider = context.read<BudgetProvider>();
    int newMonth = provider.selectedMonth - 1;
    int newYear = provider.selectedYear;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    provider.changeDate(newMonth, newYear);
  }

  void _handleNextMonth() {
    final provider = context.read<BudgetProvider>();
    int newMonth = provider.selectedMonth + 1;
    int newYear = provider.selectedYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    provider.changeDate(newMonth, newYear);
  }

  void _selectMonthYear() {
    final provider = context.read<BudgetProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        int tempMonth = provider.selectedMonth;
        int tempYear = provider.selectedYear;
        final colors = AppColors.of(ctx);

        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            "Select Month & Year",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
              color: colors.textPrimary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(color: colors.cardBorder),
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: tempMonth,
                    dropdownColor: colors.surface,
                    decoration: InputDecoration(
                      labelText: "Month",
                      filled: true,
                      fillColor: colors.elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM').format(DateTime(2026, m))),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempMonth = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: tempYear,
                    dropdownColor: colors.surface,
                    decoration: InputDecoration(
                      labelText: "Year",
                      filled: true,
                      fillColor: colors.elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                    ),
                    items: List.generate(10, (i) => DateTime.now().year - 2 + i)
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(y.toString()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempYear = val);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.changeDate(tempMonth, tempYear);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.isDark ? const Color(0xFF0B111A) : Colors.white,
                minimumSize: const Size(90, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
              ),
              child: const Text("SELECT"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BudgetCategoryProgressModel b) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text("Delete Budget", style: TextStyle(color: colors.textPrimary)),
          content: Text(
            "Are you sure you want to delete the budget limit for ${b.category}?",
            style: TextStyle(color: colors.textSecondary),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(color: colors.cardBorder),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("CANCEL", style: TextStyle(color: colors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final provider = context.read<BudgetProvider>();
                final success = await provider.deleteBudget(b.budgetId);
                if (!mounted) return;
                if (success) {
                  context.read<ReportProvider>().loadAllReports();
                  CustomToast.showSuccess(context, "Budget limit deleted successfully");
                } else {
                  CustomToast.showError(
                    context,
                    provider.errorMessage ?? "Failed to delete budget",
                  );
                }
              },
              child: Text("DELETE", style: TextStyle(color: colors.danger, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final currency = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    final selectedMonthName =
        DateFormat('MMMM').format(DateTime(2026, provider.selectedMonth));

    final progress = provider.progress;
    final overall = progress?.overall;
    final alerts = provider.alerts;

    final hasBudgets = progress != null &&
        (overall?.hasBudgetsDefined == true || progress.categoryBudgets.isNotEmpty);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Budgets",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            tooltip: "Smart Suggestions",
            icon: const Icon(Icons.lightbulb_outline_rounded),
            onPressed: _showSuggestionsSheet,
          ),
          IconButton(
            tooltip: "Budget History",
            icon: const Icon(Icons.history_rounded),
            onPressed: _showHistorySheet,
          ),
          IconButton(
            tooltip: "Select Month",
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _selectMonthYear,
          ),
          AppDimensions.wSM,
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllBudgetData(forceRefresh: true),
        color: colors.primary,
        backgroundColor: colors.surface,
        child: provider.isLoading && progress == null
            ? ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                children: List.generate(4, (index) => SkeletonLoader.card(height: 120)),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                children: [
                  // Compact Month & Year Selector Control
                  BudgetMonthSelector(
                    selectedMonth: provider.selectedMonth,
                    selectedYear: provider.selectedYear,
                    isLoading: provider.isLoading,
                    onPreviousMonth: _handlePreviousMonth,
                    onNextMonth: _handleNextMonth,
                    onTapMonth: _selectMonthYear,
                  ),

                  // Populated Budgets View
                  if (hasBudgets) ...[
                    // Overall Monthly Budget Hero Overview
                    if (overall != null && overall.hasBudgetsDefined)
                      BudgetHeroOverview(
                        overall: overall,
                        period: progress.period,
                        currency: currency,
                      ),

                    // In-App Alerts Banner
                    if (alerts != null && alerts.totalAlertsCount > 0)
                      BudgetAlertsBanner(alerts: alerts),

                    // Net Savings Progress Card
                    BudgetSavingsCard(
                      savings: progress.savings,
                      currency: currency,
                      onEditTarget: _showSavingsTargetDialog,
                    ),

                    // Section Header: Categories
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Category Budgets (${progress.categoryBudgets.length})",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showSuggestionsSheet,
                            icon: Icon(Icons.auto_awesome_rounded, size: 15, color: colors.secondary),
                            label: Text(
                              "Suggestions",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Category Budgets List
                    if (progress.categoryBudgets.isNotEmpty)
                      ...progress.categoryBudgets.asMap().entries.map(
                            (entry) => CategoryBudgetCard(
                              index: entry.key,
                              budget: entry.value,
                              currency: currency,
                              onEdit: () => _showAddEditSheet(entry.value),
                              onDelete: () => _confirmDelete(entry.value),
                            ),
                          ),

                    const SizedBox(height: 80),
                  ] else ...[
                    // Engaging Empty State (No duplicate FAB is shown!)
                    BudgetEmptyState(
                      selectedMonthName: selectedMonthName,
                      selectedYear: provider.selectedYear,
                      onCreateBudget: () => _showAddEditSheet(),
                      onExploreSuggestions: _showSuggestionsSheet,
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
      ),
      // Contextual Floating Action Button: Shown ONLY when budgets exist
      floatingActionButton: hasBudgets
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditSheet(),
              backgroundColor: colors.primary,
              foregroundColor: colors.isDark ? const Color(0xFF0B111A) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              ),
              icon: const Icon(Icons.add_rounded, size: 22),
              label: const Text(
                "Add Budget",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            )
          : null,
    );
  }
}
