import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/budget_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/animated_progress_bar.dart';
import '../../core/widgets/custom_toast.dart';

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

  void _showAddEditDialog([BudgetCategoryProgressModel? categoryBudget]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditBudgetDialog(categoryBudget: categoryBudget),
    );
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
        final tokens = AppColors.of(ctx);
        return AlertDialog(
          title: const Text(
            "Monthly Savings Target",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set a net savings target (Income - Expenses) for this month.",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Target Amount",
                  prefixText: "₹ ",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL"),
            ),
            if (currentTarget.isNotEmpty)
              TextButton(
                onPressed: () {
                  provider.setUserSavingsTarget(null);
                  Navigator.pop(ctx);
                  CustomToast.showSuccess(context, "Savings target cleared");
                },
                child: Text("CLEAR", style: TextStyle(color: tokens.danger)),
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
              child: const Text("SET TARGET"),
            ),
          ],
        );
      },
    );
  }

  void _showSuggestionsSheet() {
    final provider = context.read<BudgetProvider>();
    provider.loadBudgetSuggestions();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const SmartSuggestionsBottomSheet(),
    );
  }

  void _showHistorySheet() {
    final provider = context.read<BudgetProvider>();
    provider.loadBudgetHistory(months: 6);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const BudgetHistoryBottomSheet(),
    );
  }

  void _selectMonthYear() async {
    final provider = context.read<BudgetProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        int tempMonth = provider.selectedMonth;
        int tempYear = provider.selectedYear;
        return AlertDialog(
          title: const Text(
            "Select Month & Year",
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: tempMonth,
                    decoration: const InputDecoration(labelText: "Month"),
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
                    decoration: const InputDecoration(labelText: "Year"),
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
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.changeDate(tempMonth, tempYear);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
              child: const Text("SELECT"),
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
    final isDark = theme.brightness == Brightness.dark;
    final tokens = AppColors.of(context);
    final selectedMonthName =
        DateFormat('MMMM').format(DateTime(2026, provider.selectedMonth));

    final progress = provider.progress;
    final overall = progress?.overall;
    final alerts = provider.alerts;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Budgets", style: TextStyle(fontWeight: FontWeight.bold)),
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
        child: provider.isLoading && progress == null
            ? ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                children: List.generate(4, (index) => SkeletonLoader.card(height: 120)),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                children: [
                  // Month Selector Banner
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.date_range_rounded,
                                color: tokens.primary.withValues(alpha: 0.8),
                                size: 20,
                              ),
                              AppDimensions.wSM,
                              Text(
                                "$selectedMonthName ${provider.selectedYear}",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _selectMonthYear,
                            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                            label: const Text("Change", style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Overall Monthly Budget Overview Card
                  if (overall != null && overall.hasBudgetsDefined) ...[
                    _buildOverallBudgetCard(context, overall, progress!.period, isDark, currency),
                    const SizedBox(height: 12),
                  ],

                  // In-App Alerts Banner
                  if (alerts != null && alerts.totalAlertsCount > 0) ...[
                    _buildAlertsBanner(context, alerts, isDark),
                    const SizedBox(height: 12),
                  ],

                  // Savings Target Progress Card
                  if (progress != null) ...[
                    _buildSavingsProgressCard(context, progress.savings, isDark, currency),
                    const SizedBox(height: 16),
                  ],

                  // Section Header: Categories
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Category Budgets (${progress?.categoryBudgets.length ?? 0})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showSuggestionsSheet,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                        label: const Text("Suggestions", style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category Budgets List or Empty State
                  if (progress == null || progress.categoryBudgets.isEmpty)
                    EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "No budgets defined",
                      description:
                          "Create category limits for $selectedMonthName ${provider.selectedYear} or view smart suggestions.",
                      actionLabel: "Add Budget Limit",
                      onAction: () => _showAddEditDialog(),
                    )
                  else
                    ...progress.categoryBudgets.map(
                      (b) => _buildCategoryBudgetCard(context, b, isDark, currency),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: tokens.primary,
        foregroundColor: tokens.isDark ? const Color(0xFF0B111A) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG)),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text("Add Budget", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildOverallBudgetCard(
    BuildContext context,
    BudgetOverallProgressModel overall,
    BudgetPeriodModel period,
    bool isDark,
    CurrencyProvider currency,
  ) {
    final tokens = AppColors.of(context);
    final limitNum = double.tryParse(overall.budgetLimit) ?? 0.0;
    final spentNum = double.tryParse(overall.actualSpending) ?? 0.0;
    final remainingNum = double.tryParse(overall.remainingAmount) ?? 0.0;
    final isExceeded = overall.status == "exceeded";
    final isApproaching = overall.status == "approaching_limit";

    final progressVal = limitNum > 0 ? (spentNum / limitNum).clamp(0.0, 1.0) : 0.0;

    Color statusColor = tokens.success;
    String statusLabel = "ON TRACK";
    if (isExceeded) {
      statusColor = tokens.danger;
      statusLabel = "EXCEEDED";
    } else if (isApproaching) {
      statusColor = tokens.warning;
      statusLabel = "APPROACHING LIMIT";
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: isExceeded
              ? tokens.danger.withValues(alpha: 0.5)
              : (isApproaching
                  ? tokens.warning.withValues(alpha: 0.5)
                  : (Theme.of(context).dividerColor)),
          width: isExceeded || isApproaching ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Monthly Total Budget",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedProgressBar(
              value: progressVal,
              backgroundColor: Theme.of(context).dividerColor,
              color: statusColor,
              height: 10,
              semanticLabel: 'Overall budget used',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Spent: ${currency.format(spentNum)}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isExceeded ? tokens.danger : (tokens.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remainingNum >= 0
                          ? "Remaining: ${currency.format(remainingNum)}"
                          : "Over: ${currency.format(remainingNum.abs())}",
                      style: TextStyle(
                        fontSize: 12,
                        color: remainingNum >= 0 ? tokens.success : tokens.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Cap: ${currency.format(limitNum)}",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${overall.utilizationPercentage}% used",
                      style: TextStyle(
                        fontSize: 12,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn("Days Left", "${period.daysRemaining} days", isDark),
                _buildStatColumn("Daily Burn", "₹${overall.dailyBurnRate}/d", isDark),
                _buildStatColumn("Projected", "₹${overall.projectedSpending}", isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, bool isDark) {
    final tokens = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAlertsBanner(BuildContext context, BudgetAlertsResponseModel alerts, bool isDark) {
    final tokens = AppColors.of(context);
    final alertItems = [...alerts.exceeded, ...alerts.approachingLimit];
    if (alertItems.isEmpty && alerts.overallAlert == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: alerts.exceeded.isNotEmpty
          ? tokens.danger.withValues(alpha: 0.08)
          : tokens.warning.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: BorderSide(
          color: alerts.exceeded.isNotEmpty
              ? tokens.danger.withValues(alpha: 0.3)
              : tokens.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alerts.exceeded.isNotEmpty
                      ? Icons.warning_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: alerts.exceeded.isNotEmpty ? tokens.danger : tokens.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  alerts.exceeded.isNotEmpty ? "Budget Alert" : "Budget Notice",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: alerts.exceeded.isNotEmpty ? tokens.danger : tokens.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (alerts.overallAlert != null) ...[
              Text(
                alerts.overallAlert!.message,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
            ],
            ...alertItems.take(2).map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "• ${a.message}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsProgressCard(
    BuildContext context,
    BudgetSavingsProgressModel savings,
    bool isDark,
    CurrencyProvider currency,
  ) {
    final tokens = AppColors.of(context);
    final incomeNum = double.tryParse(savings.totalIncome) ?? 0.0;
    final netSavingsNum = double.tryParse(savings.netSavings) ?? 0.0;
    final targetNum = double.tryParse(savings.savingsTarget ?? '') ?? 0.0;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.savings_outlined, size: 20, color: tokens.primary),
                    const SizedBox(width: 8),
                    const Text(
                      "Net Savings Progress",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _showSavingsTargetDialog,
                  child: Text(targetNum > 0 ? "Edit Target" : "Set Target",
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Net Saved: ${currency.format(netSavingsNum)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: netSavingsNum >= 0 ? tokens.success : tokens.danger,
                  ),
                ),
                if (targetNum > 0)
                  Text(
                    "Target: ${currency.format(targetNum)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textSecondary,
                    ),
                  )
                else
                  Text(
                    "Income: ${currency.format(incomeNum)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: tokens.textSecondary,
                    ),
                  ),
              ],
            ),
            if (targetNum > 0) ...[
              const SizedBox(height: 8),
              AnimatedProgressBar(
                value: (netSavingsNum / targetNum).clamp(0.0, 1.0),
                backgroundColor: Theme.of(context).dividerColor,
                color: savings.isTargetAchieved ? tokens.success : tokens.primary,
                height: 7,
                semanticLabel: 'Savings target achieved',
              ),
              const SizedBox(height: 4),
              Text(
                "${savings.progressPercentage ?? '0.0'}% achieved",
                style: TextStyle(
                  fontSize: 11,
                  color: savings.isTargetAchieved ? tokens.success : tokens.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetCard(
    BuildContext context,
    BudgetCategoryProgressModel b,
    bool isDark,
    CurrencyProvider currency,
  ) {
    final tokens = AppColors.of(context);
    final limitNum = double.tryParse(b.budgetLimit) ?? 0.0;
    final spentNum = double.tryParse(b.actualSpending) ?? 0.0;
    final remainingNum = double.tryParse(b.remainingAmount) ?? 0.0;
    final isOver = b.status == "exceeded";
    final isApproaching = b.status == "approaching_limit";

    final progress = limitNum <= 0 ? 0.0 : (spentNum / limitNum).clamp(0.0, 1.0);

    Color color = tokens.primary;
    if (isOver) {
      color = tokens.danger;
    } else if (isApproaching) {
      color = tokens.warning;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: isOver
              ? tokens.danger.withValues(alpha: 0.4)
              : (isApproaching
                  ? tokens.warning.withValues(alpha: 0.4)
                  : (Theme.of(context).dividerColor)),
          width: isOver || isApproaching ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  b.category,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (isOver)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tokens.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        ),
                        child: Text(
                          "OVER BUDGET",
                          style: TextStyle(
                            color: tokens.danger,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else if (isApproaching)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tokens.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                        ),
                        child: Text(
                          "80%+ USED",
                          style: TextStyle(
                            color: tokens.warning,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      iconColor: tokens.textSecondary,
                      color: Theme.of(context).colorScheme.surface,
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showAddEditDialog(b);
                        } else if (action == 'delete') {
                          _confirmDelete(b);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined, size: 20),
                            title: Text('Edit Amount', style: TextStyle(fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline_rounded,
                                color: tokens.danger, size: 20),
                            title: Text('Delete',
                                style: TextStyle(color: tokens.danger, fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedProgressBar(
              value: progress,
              backgroundColor: Theme.of(context).dividerColor,
              color: color,
              height: 7,
              semanticLabel: '${b.category} budget used',
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Spent: ${currency.format(spentNum)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isOver ? tokens.danger : tokens.textSecondary,
                    fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  "Limit: ${currency.format(limitNum)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  remainingNum >= 0
                      ? "Remaining: ${currency.format(remainingNum)}"
                      : "Over by: ${currency.format(remainingNum.abs())}",
                  style: TextStyle(
                    color: remainingNum >= 0 ? tokens.success : tokens.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${b.utilizationPercentage}% (${b.projectedSpending} proj)",
                  style: TextStyle(
                    fontSize: 11,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BudgetCategoryProgressModel b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Budget"),
        content: Text("Are you sure you want to delete the budget limit for ${b.category}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
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
                    context, provider.errorMessage ?? "Failed to delete budget");
              }
            },
            child: Builder(builder: (ctx2) => Text("DELETE", style: TextStyle(color: AppColors.of(ctx2).danger))),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Smart Suggestions Bottom Sheet
// ============================================================================

class SmartSuggestionsBottomSheet extends StatelessWidget {
  const SmartSuggestionsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final tokens = AppColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Smart Budget Suggestions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                "Deterministic recommendations based on your previous 3-month spending trends. Requires explicit user confirmation.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.isSuggestionsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.suggestions.isEmpty
                        ? const Center(
                            child: Text("No suggestions available yet. Keep tracking expenses!"))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: provider.suggestions.length,
                            itemBuilder: (context, index) {
                              final s = provider.suggestions[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: tokens.divider,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            s.categoryName,
                                            style: const TextStyle(
                                                fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Suggested: ₹${s.estimates.suggestedBudget}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: tokens.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        s.estimates.rationale,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Trend: ${s.estimates.trend.toUpperCase()}",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: s.estimates.trend == "increasing"
                                                  ? tokens.danger
                                                  : (s.estimates.trend == "decreasing"
                                                      ? tokens.success
                                                      : Theme.of(context).disabledColor),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final confirmed = await showDialog<bool>(
                                                context: context,
                                                builder: (dialogCtx) => AlertDialog(
                                                  title: const Text("Confirm Budget"),
                                                  content: Text(
                                                      "Apply suggested budget of ₹${s.estimates.suggestedBudget} for ${s.categoryName}?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(dialogCtx, false),
                                                      child: const Text("CANCEL"),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(dialogCtx, true),
                                                      child: const Text("CONFIRM"),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmed == true && context.mounted) {
                                                final ok = await provider.applySuggestion(s);
                                                if (context.mounted) {
                                                  if (ok) {
                                                    CustomToast.showSuccess(context,
                                                        "Budget for ${s.categoryName} applied");
                                                    Navigator.pop(context);
                                                  } else {
                                                    CustomToast.showError(context,
                                                        provider.errorMessage ?? "Failed to apply");
                                                  }
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 14, vertical: 8),
                                              minimumSize: const Size(60, 32),
                                            ),
                                            child: const Text("APPLY",
                                                style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
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

// ============================================================================
// Budget History Bottom Sheet
// ============================================================================

class BudgetHistoryBottomSheet extends StatelessWidget {
  const BudgetHistoryBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final tokens = AppColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Historical Budget Comparison",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                "Past monthly budget vs actual spending comparison.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.isHistoryLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.history.isEmpty
                        ? const Center(child: Text("No budget history recorded yet."))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: provider.history.length,
                            itemBuilder: (context, index) {
                              final h = provider.history[index];
                              final monthName = DateFormat('MMMM')
                                  .format(DateTime(2026, h.month));
                              final isOver = h.status == "exceeded";

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: tokens.divider,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "$monthName ${h.year}",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${h.categoryCount} categories budgeted",
                                            style: const TextStyle(
                                                fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Spent: ₹${h.totalSpent} / ₹${h.totalBudget}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isOver ? tokens.danger : tokens.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${h.utilizationPercentage}% used",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isOver
                                                  ? tokens.danger
                                                  : tokens.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
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

// ============================================================================
// Add/Edit Budget Limit Dialog
// ============================================================================

class AddEditBudgetDialog extends StatefulWidget {
  final BudgetCategoryProgressModel? categoryBudget;

  const AddEditBudgetDialog({super.key, this.categoryBudget});

  @override
  State<AddEditBudgetDialog> createState() => _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends State<AddEditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  int? _selectedCategoryId;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final cb = widget.categoryBudget;
    final provider = context.read<BudgetProvider>();

    _amountController =
        TextEditingController(text: cb != null ? cb.budgetLimit : '');
    _selectedCategoryId = cb?.categoryId;
    _selectedMonth = provider.selectedMonth;
    _selectedYear = provider.selectedYear;

    if (_selectedCategoryId == null) {
      final expenses = CategoryModel.getExpenseCategories();
      if (expenses.isNotEmpty) {
        _selectedCategoryId = expenses.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final provider = context.read<BudgetProvider>();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    bool success;
    if (widget.categoryBudget != null) {
      success = await provider.editBudget(
        id: widget.categoryBudget!.budgetId,
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    } else {
      success = await provider.addBudget(
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    }

    if (success && mounted) {
      context.read<ReportProvider>().loadAllReports();
      Navigator.pop(context);
      CustomToast.showSuccess(
        context,
        widget.categoryBudget != null
            ? "Budget limit updated"
            : "Budget limit created",
      );
    } else if (mounted) {
      CustomToast.showError(
          context, provider.errorMessage ?? "An error occurred");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryBudget != null;
    final provider = context.watch<BudgetProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final expenseCategories = CategoryModel.getExpenseCategories();
    final tokens = AppColors.of(context);

    return AlertDialog(
      title: Text(
        isEditing ? "Edit Budget Limit" : "Add Budget Limit",
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Theme.of(context).colorScheme.surface,
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: "Expense Category"),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: expenseCategories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: isEditing
                    ? null
                    : (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                validator: (val) => val == null ? "Select a category" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Limit Amount (${currencyProvider.currencyCode})',
                  prefixText: '${currencyProvider.currencySymbol} ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Amount is required";
                  }
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return "Enter a valid budget limit";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                    labelText: "Target Period", enabled: false),
                child: Text(
                  "${DateFormat('MMMM').format(DateTime(2026, _selectedMonth))} $_selectedYear",
                  style: TextStyle(
                      color: tokens.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              provider.isActionLoading ? null : () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: provider.isActionLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(90, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: provider.isActionLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("SAVE"),
        ),
      ],
    );
  }
}
