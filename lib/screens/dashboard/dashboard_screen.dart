import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../models/dashboard_models.dart';
import '../../core/utils/category_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../accounts/widgets/money_text.dart';
import '../accounts/widgets/account_icon.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  Future<void> _selectCustomMonth(BuildContext context, DashboardProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: "Select month to view",
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      final mStr = "${picked.year}-${picked.month.toString().padLeft(2, '0')}";
      provider.setMonth(mStr);
    }
  }

  Widget _buildFilterBar(BuildContext context, DashboardProvider provider, bool isDark) {
    final currentPeriod = provider.selectedPeriod;
    final customMonth = provider.selectedMonth;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text("Current Month"),
            selected: currentPeriod == "current_month" && customMonth == null,
            onSelected: (_) => provider.setPeriod("current_month"),
            selectedColor: AppColors.primary.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentPeriod == "current_month" && customMonth == null
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Previous Month"),
            selected: currentPeriod == "previous_month",
            onSelected: (_) => provider.setPeriod("previous_month"),
            selectedColor: AppColors.primary.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentPeriod == "previous_month"
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.calendar_month_rounded, size: 16),
            label: Text(customMonth ?? "Select Month"),
            onPressed: () => _selectCustomMonth(context, provider),
            backgroundColor: customMonth != null
                ? AppColors.primary.withValues(alpha: 0.18)
                : (isDark ? AppColors.surfaceDark : Colors.white),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: customMonth != null
                  ? AppColors.primary
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(FinancialOverview? overview, bool isDark) {
    final netWorth = overview?.netWorth ?? "0.00";
    final totalAssets = overview?.totalAssets ?? "0.00";
    final totalLiabilities = overview?.totalLiabilities ?? "0.00";

    return Card(
      elevation: 0,
      color: isDark ? AppColors.elevatedDark : const Color(0xFFF0ECFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: .32),
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
                  "NET WORTH",
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Text(
                    "Ledger Accurate",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            MoneyText(
              decimalString: netWorth,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Total Assets",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      MoneyText(
                        decimalString: totalAssets,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Total Liabilities",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      MoneyText(
                        decimalString: totalLiabilities,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashFlowSection(FinancialOverview? overview, bool isDark) {
    final income = overview?.monthlyIncome ?? "0.00";
    final expenses = overview?.monthlyExpenses ?? "0.00";
    final savings = overview?.monthlyNetSavings ?? "0.00";
    final incomeMoM = overview?.incomeChangePercent ?? "0.0";
    final expenseMoM = overview?.expenseChangePercent ?? "0.0";
    final savingsRate = overview?.savingsRate ?? "0.0";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Monthly Cash Flow",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
        AppDimensions.hSM,
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 0,
                color: isDark ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  side: BorderSide(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
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
                            "Income",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            "${incomeMoM.startsWith('-') ? '' : '+'}$incomeMoM%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: incomeMoM.startsWith('-') ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MoneyText(
                        decimalString: income,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                elevation: 0,
                color: isDark ? AppColors.surfaceDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  side: BorderSide(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
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
                            "Expenses",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            "${expenseMoM.startsWith('-') ? '' : '+'}$expenseMoM%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: expenseMoM.startsWith('+') ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MoneyText(
                        decimalString: expenses,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Net Savings (Cash Flow)",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MoneyText(
                      decimalString: savings,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: savings.startsWith('-') ? AppColors.danger : AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Savings Rate",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$savingsRate%",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingByCategory(List<CategorySummary> categories, bool isDark) {
    if (categories.isEmpty) {
      return Card(
        elevation: 0,
        color: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: Text(
              "No expenses recorded for this period.",
              style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.take(5).length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final pct = cat.percentage ?? "0.0";
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: getCategoryColor(cat.name).withValues(alpha: 0.12),
                  radius: 18,
                  child: Icon(
                    getCategoryIcon(cat.name),
                    color: getCategoryColor(cat.name),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$pct% of expenses",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyText(
                  decimalString: cat.totalString ?? cat.total.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAccountOverview(List<DashboardAccountItem> accounts, bool isDark) {
    if (accounts.isEmpty) {
      return Card(
        elevation: 0,
        color: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Center(
            child: Column(
              children: [
                const Text(
                  "No accounts linked yet.",
                  style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push('/accounts'),
                  child: const Text("Add Account"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final acc = accounts[index];
          final isCredit = acc.type == "credit_card";
          final accentColor = isCredit ? AppColors.danger : AppColors.primary;

          return Container(
            width: 200,
            padding: const EdgeInsets.all(AppDimensions.sm + 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        AccountIcon(
                          type: acc.type,
                          subtype: acc.subtype ?? 'savings',
                          size: 28,
                          accentColor: accentColor,
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: Text(
                            acc.displayName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (acc.isDefault)
                      const Icon(Icons.star_rounded, size: 16, color: AppColors.warning)
                    else if (acc.isArchived)
                      const Icon(Icons.archive_outlined, size: 14, color: AppColors.textSecondaryLight),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCredit ? "Outstanding Debt" : "Ledger Balance",
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      decimalString: isCredit ? (acc.outstandingDebt ?? "0.00") : acc.currentBalance,
                      currencyCode: acc.currencyCode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? AppColors.danger : (isDark ? AppColors.textLight : AppColors.textDark),
                      ),
                    ),
                    if (isCredit && acc.utilizationPercentage != null)
                      Text(
                        "Utilization: ${acc.utilizationPercentage}%",
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyTrendChart(DashboardProvider provider, bool isDark) {
    final summaries = provider.monthlySummaries.take(6).toList().reversed.toList();
    if (summaries.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No monthly summary data available.",
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
          ),
        ),
      );
    }

    final double maxVal = summaries.fold(0.0, (max, item) {
      final val = item.income > item.expense ? item.income : item.expense;
      return val > max ? val : max;
    });

    final double adjustedMax = maxVal == 0 ? 100 : maxVal * 1.25;

    final List<FlSpot> incomeSpots = [];
    final List<FlSpot> expenseSpots = [];
    for (int i = 0; i < summaries.length; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), summaries[i].income));
      expenseSpots.add(FlSpot(i.toDouble(), summaries[i].expense));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          maxY: adjustedMax,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => isDark ? AppColors.cardDark : AppColors.surfaceLight,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final String type = spot.barIndex == 0 ? "Income" : "Expense";
                  return LineTooltipItem(
                    "$type: ₹${spot.y.toStringAsFixed(2)}",
                    TextStyle(
                      color: isDark ? AppColors.textLight : AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? AppColors.dividerDark.withValues(alpha: 0.4) : AppColors.dividerLight.withValues(alpha: 0.4),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < summaries.length) {
                    final parts = summaries[index].month.split('-');
                    final monthNum = int.tryParse(parts.last) ?? 1;
                    final monthName = DateFormat('MMM').format(DateTime(2026, monthNum));
                    return SideTitleWidget(
                      meta: meta,
                      space: 6,
                      child: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: AppColors.success,
              barWidth: 3.0,
              dotData: const FlDotData(show: true),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: AppColors.danger,
              barWidth: 3.0,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(List<FinancialInsight> insights, bool isDark) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Financial Insights",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
        ),
        AppDimensions.hSM,
        Card(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: insights.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final insight = insights[index];
                IconData icon;
                Color iconColor;

                switch (insight.type) {
                  case 'highest_category':
                    icon = Icons.pie_chart_rounded;
                    iconColor = AppColors.warning;
                    break;
                  case 'largest_expense':
                    icon = Icons.shopping_bag_outlined;
                    iconColor = AppColors.danger;
                    break;
                  case 'savings_rate':
                    icon = Icons.savings_outlined;
                    iconColor = AppColors.success;
                    break;
                  case 'credit_utilization':
                    icon = Icons.credit_card_rounded;
                    iconColor = AppColors.primary;
                    break;
                  default:
                    icon = Icons.insights_rounded;
                    iconColor = AppColors.info;
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final dashboardProvider = context.watch<DashboardProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.scaffold,
      appBar: AppBar(
        toolbarHeight: 65,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : "U",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${user?.name ?? 'User'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
                Text(
                  "FinTrack Dashboard",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Accounts & Wallets',
            icon: Icon(
              Icons.account_balance_rounded,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
            onPressed: () => context.push('/accounts'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.sync_rounded,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
            onPressed: () => dashboardProvider.loadDashboardData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboardProvider.loadDashboardData(),
        child: dashboardProvider.isLoading && dashboardProvider.summary == null
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDimensions.hMD,
                    SkeletonLoader.card(height: 120),
                    AppDimensions.hMD,
                    Row(
                      children: [
                        Expanded(child: SkeletonLoader.card(height: 70)),
                        const SizedBox(width: 8),
                        Expanded(child: SkeletonLoader.card(height: 70)),
                      ],
                    ),
                    AppDimensions.hLG,
                    SkeletonLoader.chart(),
                  ],
                ),
              )
            : dashboardProvider.errorMessage != null && dashboardProvider.summary == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.danger),
                          const SizedBox(height: 12),
                          Text(
                            dashboardProvider.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => dashboardProvider.loadDashboardData(),
                            child: const Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // 7. Date & Month Filter
                        _buildFilterBar(context, dashboardProvider, isDark),
                        AppDimensions.hMD,

                        // 1. Net worth & Total Assets / Liabilities
                        _buildNetWorthCard(dashboardProvider.overview, isDark),
                        AppDimensions.hMD,

                        // 2. Cash Flow (Income, Expenses, Net Savings)
                        _buildCashFlowSection(dashboardProvider.overview, isDark),
                        AppDimensions.hLG,

                        // 5. Account Balance Overview
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Account Balances",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                            ),
                            TextButton(
                              onPressed: () => context.push('/accounts'),
                              child: const Text("Manage"),
                            ),
                          ],
                        ),
                        AppDimensions.hXS,
                        _buildAccountOverview(dashboardProvider.accounts, isDark),
                        AppDimensions.hLG,

                        // 3. Spending by Category
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Spending by Category",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                            ),
                            if (dashboardProvider.topMerchants.isNotEmpty)
                              Text(
                                "Top: ${dashboardProvider.topMerchants[0].merchant}",
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                              ),
                          ],
                        ),
                        AppDimensions.hSM,
                        _buildSpendingByCategory(dashboardProvider.categorySummaries, isDark),
                        AppDimensions.hLG,

                        // 4. Monthly Trend Chart Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Income vs Expense Trend",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                            ),
                            Row(
                              children: [
                                _buildLegendItem("Income", AppColors.success),
                                const SizedBox(width: 12),
                                _buildLegendItem("Expense", AppColors.danger),
                              ],
                            ),
                          ],
                        ),
                        AppDimensions.hSM,
                        Card(
                          elevation: 0,
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                            side: BorderSide(
                              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.md),
                            child: _buildMonthlyTrendChart(dashboardProvider, isDark),
                          ),
                        ),
                        AppDimensions.hLG,

                        // Deterministic Financial Insights
                        _buildInsightsSection(dashboardProvider.insights, isDark),
                        AppDimensions.hLG,

                        // 6. Recent Transactions Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Recent Transactions",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                            ),
                            TextButton(
                              onPressed: () => context.go("/transactions"),
                              child: const Text("See All"),
                            ),
                          ],
                        ),
                        AppDimensions.hXS,
                        if (dashboardProvider.recentTransactions.isEmpty)
                          Card(
                            elevation: 0,
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                              side: BorderSide(
                                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 36.0),
                              child: Center(
                                child: Text(
                                  "No transactions recorded yet.",
                                  style: TextStyle(color: AppColors.textSecondaryLight),
                                ),
                              ),
                            ),
                          )
                        else
                          Card(
                            elevation: 0,
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                              side: BorderSide(
                                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: dashboardProvider.recentTransactions.take(8).length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                indent: 72,
                                endIndent: 16,
                                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                              ),
                              itemBuilder: (context, index) {
                                final tx = dashboardProvider.recentTransactions[index];
                                final isExpense = tx.type == "expense";

                                String formattedDate = tx.transactionDate;
                                try {
                                  final parsedDate = DateTime.parse(tx.transactionDate);
                                  formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);
                                } catch (_) {}

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: getCategoryColor(tx.category).withValues(alpha: 0.12),
                                        radius: 20,
                                        child: Icon(
                                          getCategoryIcon(tx.category),
                                          color: getCategoryColor(tx.category),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark ? AppColors.textLight : AppColors.textDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              "${tx.category} • $formattedDate",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isExpense ? "-₹${tx.amount.toStringAsFixed(2)}" : "+₹${tx.amount.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isExpense ? AppColors.danger : AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
