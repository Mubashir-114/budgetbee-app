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
import '../../core/widgets/animated_progress_bar.dart';
import '../accounts/widgets/money_text.dart';
import '../accounts/widgets/account_icon.dart';
import 'widgets/premium_dashboard_cards.dart';

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

  Future<void> _selectCustomMonth(
    BuildContext context,
    DashboardProvider provider,
  ) async {
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

  Widget _buildFilterBar(
    BuildContext context,
    DashboardProvider provider,
    bool isDark,
  ) {
    final currentPeriod = provider.selectedPeriod;
    final customMonth = provider.selectedMonth;
    final colors = AppColors.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text("Current Month"),
            selected: currentPeriod == "current_month" && customMonth == null,
            onSelected: (_) => provider.setPeriod("current_month"),
            selectedColor: colors.primary.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentPeriod == "current_month" && customMonth == null
                  ? colors.primary
                  : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("Previous Month"),
            selected: currentPeriod == "previous_month",
            onSelected: (_) => provider.setPeriod("previous_month"),
            selectedColor: colors.primary.withValues(alpha: 0.18),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: currentPeriod == "previous_month"
                  ? colors.primary
                  : colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            avatar: const Icon(Icons.calendar_month_rounded, size: 16),
            label: Text(customMonth ?? "Select Month"),
            onPressed: () => _selectCustomMonth(context, provider),
            backgroundColor: customMonth != null
                ? colors.primary.withValues(alpha: 0.18)
                : colors.surface,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: customMonth != null
                  ? colors.primary
                  : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetWorthCard(
    FinancialOverview? overview,
    List<MonthlySummary> monthlySummaries,
    bool isDark,
  ) {
    final netWorth = overview?.netWorth ?? "0.00";
    final totalAssets = overview?.totalAssets ?? "0.00";
    final totalLiabilities = overview?.totalLiabilities ?? "0.00";
    final colors = AppColors.of(context);

    return PremiumSummaryCard(
      animatedHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "NET WORTH",
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.55,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                ),
              ),
              DashboardGlowChip(label: "LEDGER ACCURATE"),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedAmountText(
            decimalString: netWorth,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.35,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Your position across every connected account",
            style: TextStyle(
              fontSize: 11,
              color: colors.textSecondary,
            ),
          ),
          if (monthlySummaries.length > 1) ...[
            const SizedBox(height: 14),
            _buildHeroSparkline(monthlySummaries),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : colors.primary).withValues(
                alpha: .055,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: (isDark ? Colors.white : colors.primary).withValues(
                  alpha: .08,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHeroBalance(
                    "ASSETS",
                    totalAssets,
                    AppColors.success,
                    isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color:
                      colors.divider.withValues(alpha: .7),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildHeroBalance(
                    "LIABILITIES",
                    totalLiabilities,
                    AppColors.danger,
                    isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBalance(
    String label,
    String amount,
    Color color,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: .8,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedAmountText(
          decimalString: amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSparkline(List<MonthlySummary> summaries) {
    final colors = AppColors.of(context);
    final values = summaries.take(8).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (var index = 0; index < values.length; index++) {
      spots.add(
        FlSpot(index.toDouble(), values[index].income - values[index].expense),
      );
    }
    return Semantics(
      label: 'Net savings trend for the last ${values.length} months',
      child: SizedBox(
        height: 38,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: .35,
                color: colors.secondary,
                barWidth: 2.4,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.secondary.withValues(alpha: .2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 550),
        ),
      ),
    );
  }

  Widget _buildCashFlowSection(
    FinancialOverview? overview,
    bool isDark, {
    bool premium = true,
  }) {
    if (premium) return _buildPremiumCashFlowSection(overview, isDark);
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
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
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
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
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            "${incomeMoM.startsWith('-') ? '' : '+'}$incomeMoM%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: incomeMoM.startsWith('-')
                                  ? AppColors.danger
                                  : AppColors.success,
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
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
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
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          Text(
                            "${expenseMoM.startsWith('-') ? '' : '+'}$expenseMoM%",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: expenseMoM.startsWith('+')
                                  ? AppColors.danger
                                  : AppColors.success,
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
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    MoneyText(
                      decimalString: savings,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: savings.startsWith('-')
                            ? AppColors.danger
                            : AppColors.primary,
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
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
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

  Widget _buildPremiumCashFlowSection(
    FinancialOverview? overview,
    bool isDark,
  ) {
    final income = overview?.monthlyIncome ?? "0.00";
    final expenses = overview?.monthlyExpenses ?? "0.00";
    final savings = overview?.monthlyNetSavings ?? "0.00";
    final incomeMoM = overview?.incomeChangePercent ?? "0.0";
    final expenseMoM = overview?.expenseChangePercent ?? "0.0";
    final savingsMoM = overview?.savingsChangePercent ?? "0.0";
    final savingsRate = overview?.savingsRate ?? "0.0";
    final parsedRate = (double.tryParse(savingsRate) ?? 0) / 100;
    final colors = AppColors.of(context);

    String trendLabel(String value) =>
        "${value.startsWith('-') || value.startsWith('+') ? '' : '+'}$value%";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PremiumSectionHeader(
          title: "Monthly Cash Flow",
          subtitle: "Income, outflow and what you kept",
        ),
        const SizedBox(height: 11),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PremiumMetricCard(
                label: "Income",
                amount: income,
                icon: Icons.south_west_rounded,
                accent: colors.success,
                trend: trendLabel(incomeMoM),
                trendIsPositive: !incomeMoM.startsWith('-'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PremiumMetricCard(
                label: "Expenses",
                amount: expenses,
                icon: Icons.north_east_rounded,
                accent: colors.danger,
                trend: trendLabel(expenseMoM),
                trendIsPositive: expenseMoM.startsWith('-'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PremiumMetricCard(
          label: "Net Savings (Cash Flow)",
          amount: savings,
          icon: Icons.auto_graph_rounded,
          accent: savings.startsWith('-') ? colors.danger : colors.primary,
          trend: trendLabel(savingsMoM),
          trendIsPositive: !savingsMoM.startsWith('-'),
          trailing: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Savings rate",
                    style: TextStyle(
                      fontSize: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    "$savingsRate%",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedProgressBar(
                value: parsedRate,
                color: savings.startsWith('-')
                    ? colors.danger
                    : colors.primary,
                backgroundColor: colors.divider,
                height: 6,
                semanticLabel: "Savings rate",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingByCategory(
    List<CategorySummary> categories,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    if (categories.isEmpty) {
      return PremiumEmptyStateCard(
        icon: Icons.donut_large_rounded,
        title: "No expenses recorded for this period.",
        message:
            "Category insights will appear as soon as spending is recorded.",
        accent: colors.secondary,
      );
    }

    return PremiumSummaryCard(
      accent: colors.secondary,
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Padding(
        padding: EdgeInsets.zero,
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
                  backgroundColor: getCategoryColor(
                    cat.name,
                  ).withValues(alpha: 0.12),
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
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$pct% of expenses",
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                MoneyText(
                  decimalString:
                      cat.totalString ?? cat.total.toStringAsFixed(2),
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

  Widget _buildAccountOverview(
    List<DashboardAccountItem> accounts,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    if (accounts.isEmpty) {
      return PremiumEmptyStateCard(
        icon: Icons.account_balance_wallet_outlined,
        title: "No accounts linked yet.",
        message:
            "Connect an account to bring your complete financial picture to life.",
        actionLabel: "Add Account",
        onAction: () => context.push('/accounts'),
        accent: colors.secondary,
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final acc = accounts[index];
          final isCredit = acc.type == "credit_card";
          final accentColor = isCredit ? colors.danger : colors.primary;

          final utilization =
              (double.tryParse(acc.utilizationPercentage ?? '0') ?? 0) / 100;

          return Container(
            width: 218,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        accentColor.withValues(alpha: .12),
                        colors.surface,
                      ]
                    : [accentColor.withValues(alpha: .07), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(color: accentColor.withValues(alpha: .24)),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? .07 : .05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (acc.isDefault)
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: AppColors.warning,
                      )
                    else if (acc.isArchived)
                      Icon(
                        Icons.archive_outlined,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCredit ? "Outstanding Debt" : "Ledger Balance",
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      decimalString: isCredit
                          ? (acc.outstandingDebt ?? "0.00")
                          : acc.currentBalance,
                      currencyCode: acc.currencyCode,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isCredit
                            ? colors.danger
                            : colors.textPrimary,
                      ),
                    ),
                    if (isCredit && acc.utilizationPercentage != null) ...[
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Utilization",
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            "${acc.utilizationPercentage}%",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AnimatedProgressBar(
                        value: utilization,
                        color: accentColor,
                        backgroundColor: colors.divider,
                        height: 4,
                        semanticLabel: "${acc.displayName} utilization",
                      ),
                    ],
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
    final colors = AppColors.of(context);
    final summaries = provider.monthlySummaries
        .take(6)
        .toList()
        .reversed
        .toList();
    if (summaries.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No monthly summary data available.",
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
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
              getTooltipColor: (_) =>
                  colors.elevated,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final String type = spot.barIndex == 0 ? "Income" : "Expense";
                  return LineTooltipItem(
                    "$type: ₹${spot.y.toStringAsFixed(2)}",
                    TextStyle(
                      color: colors.textPrimary,
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
                color: colors.divider.withValues(alpha: 0.4),
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
                    final monthName = DateFormat(
                      'MMM',
                    ).format(DateTime(2026, monthNum));
                    return SideTitleWidget(
                      meta: meta,
                      space: 6,
                      child: Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Financial Insights",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/analytics'),
              icon: Icon(Icons.auto_awesome_rounded, size: 16, color: colors.primary),
              label: Text(
                "Ask AI",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
        AppDimensions.hSM,
        Card(
          elevation: 0,
          color: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(
              color: colors.divider,
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
                    iconColor = colors.primary;
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
                          color: colors.textPrimary,
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
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        toolbarHeight: 65,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primary.withValues(alpha: 0.12),
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : "U",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colors.primary,
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
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  "FinTrack Dashboard",
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
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
              color: colors.textPrimary,
            ),
            onPressed: () => context.push('/accounts'),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(
              Icons.sync_rounded,
              color: colors.textPrimary,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDimensions.hMD,
                    const DashboardSkeletonCard(height: 210),
                    AppDimensions.hMD,
                    Row(
                      children: [
                        const Expanded(
                          child: DashboardSkeletonCard(
                            height: 118,
                            accent: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: DashboardSkeletonCard(
                            height: 118,
                            accent: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    AppDimensions.hLG,
                    const DashboardSkeletonCard(height: 220),
                  ],
                ),
              )
            : dashboardProvider.errorMessage != null &&
                  dashboardProvider.summary == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.danger,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    // 7. Date & Month Filter
                    _buildFilterBar(context, dashboardProvider, isDark),
                    AppDimensions.hMD,

                    // 1. Net worth & Total Assets / Liabilities
                    DashboardEntrance(
                      index: 0,
                      child: _buildNetWorthCard(
                        dashboardProvider.overview,
                        dashboardProvider.monthlySummaries,
                        isDark,
                      ),
                    ),
                    AppDimensions.hMD,

                    // 2. Cash Flow (Income, Expenses, Net Savings)
                    DashboardEntrance(
                      index: 1,
                      child: _buildCashFlowSection(
                        dashboardProvider.overview,
                        isDark,
                      ),
                    ),
                    AppDimensions.hLG,

                    // 5. Account Balance Overview
                    PremiumSectionHeader(
                      title: "Account Balances",
                      subtitle: "Live balances from your ledger",
                      actionLabel: "Manage",
                      onAction: () => context.push('/accounts'),
                    ),
                    AppDimensions.hXS,
                    DashboardEntrance(
                      index: 2,
                      child: _buildAccountOverview(
                        dashboardProvider.accounts,
                        isDark,
                      ),
                    ),
                    AppDimensions.hLG,

                    // 3. Spending by Category
                    PremiumSectionHeader(
                      title: "Spending by Category",
                      subtitle: "Where this period's money went",
                      trailing: dashboardProvider.topMerchants.isNotEmpty
                          ? DashboardGlowChip(
                              label:
                                  "TOP · ${dashboardProvider.topMerchants[0].merchant.toUpperCase()}",
                              icon: Icons.local_fire_department_rounded,
                              color: colors.secondary,
                            )
                          : null,
                    ),
                    AppDimensions.hSM,
                    DashboardEntrance(
                      index: 3,
                      child: _buildSpendingByCategory(
                        dashboardProvider.categorySummaries,
                        isDark,
                      ),
                    ),
                    AppDimensions.hLG,

                    // 4. Monthly Trend Chart Section
                    PremiumSectionHeader(
                      title: "Income vs Expense Trend",
                      subtitle: "Your six-month cash-flow rhythm",
                      trailing: Row(
                        children: [
                          _buildLegendItem("Income", AppColors.success),
                          const SizedBox(width: 12),
                          _buildLegendItem("Expense", AppColors.danger),
                        ],
                      ),
                    ),
                    AppDimensions.hSM,
                    DashboardEntrance(
                      index: 4,
                      child: PremiumSummaryCard(
                        accent: AppColors.info,
                        padding: const EdgeInsets.all(AppDimensions.md),
                        child: _buildMonthlyTrendChart(
                          dashboardProvider,
                          isDark,
                        ),
                      ),
                    ),
                    AppDimensions.hLG,

                    // Deterministic Financial Insights
                    _buildInsightsSection(dashboardProvider.insights, isDark),
                    AppDimensions.hLG,

                    // 6. Recent Transactions Section
                    PremiumSectionHeader(
                      title: "Recent Transactions",
                      subtitle: "Latest activity across your accounts",
                      actionLabel: "See All",
                      onAction: () => context.go("/transactions"),
                    ),
                    AppDimensions.hXS,
                    if (dashboardProvider.recentTransactions.isEmpty)
                      const PremiumEmptyStateCard(
                        icon: Icons.receipt_long_rounded,
                        title: "No transactions recorded yet.",
                        message:
                            "New income and expenses will collect here for a quick review.",
                        accent: AppColors.info,
                      )
                    else
                      PremiumSummaryCard(
                        accent: AppColors.info,
                        padding: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dashboardProvider.recentTransactions
                              .take(8)
                              .length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            indent: 72,
                            endIndent: 16,
                              color: colors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final tx =
                                dashboardProvider.recentTransactions[index];
                            final isExpense = tx.type == "expense";

                            String formattedDate = tx.transactionDate;
                            try {
                              final parsedDate = DateTime.parse(
                                tx.transactionDate,
                              );
                              formattedDate = DateFormat(
                                'MMM dd, yyyy',
                              ).format(parsedDate);
                            } catch (_) {}

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: getCategoryColor(
                                      tx.category,
                                    ).withValues(alpha: 0.12),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tx.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          color: colors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          "${tx.category} • $formattedDate",
                                          style: TextStyle(
                                            fontSize: 11,
                                          color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isExpense
                                        ? "-₹${tx.amount.toStringAsFixed(2)}"
                                        : "+₹${tx.amount.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isExpense
                                          ? AppColors.danger
                                          : AppColors.success,
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
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
