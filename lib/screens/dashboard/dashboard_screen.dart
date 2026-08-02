import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../core/utils/category_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/skeleton_loader.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            AppDimensions.wSM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currencyFormat.format(amount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                    "$type: ${_currencyFormat.format(spot.y)}",
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
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.success,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.22),
                    AppColors.success.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: AppColors.danger,
              barWidth: 3.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.danger,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.danger.withValues(alpha: 0.22),
                    AppColors.danger.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
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
        toolbarHeight: 70,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                user?.name.substring(0, 1).toUpperCase() ?? "U",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
            AppDimensions.wSM,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${user?.name ?? 'User'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                  ),
                ),
                Text(
                  "Welcome back",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sync_rounded,
              color: isDark ? AppColors.textLight : AppColors.textDark,
            ),
            onPressed: () => dashboardProvider.loadDashboardData(),
          ),
          AppDimensions.wSM,
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
                    const ShimmerLoading(width: 140, height: 16),
                    AppDimensions.hSM,
                    SkeletonLoader.chart(),
                    AppDimensions.hLG,
                    const ShimmerLoading(width: 160, height: 16),
                    AppDimensions.hSM,
                    SkeletonLoader.listTile(),
                    SkeletonLoader.listTile(),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDimensions.hMD,
                    // Balance Gradient Banner (Fintech style)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Abstract light effect ring
                          Positioned(
                            right: -40,
                            top: -40,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppDimensions.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TOTAL BALANCE",
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currencyFormat.format(dashboardProvider.summary?.balance ?? 0.0),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppDimensions.hMD,
                    // Income & Expenses Summary Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: "Income",
                            amount: dashboardProvider.summary?.totalIncome ?? 0.0,
                            color: AppColors.success,
                            icon: Icons.south_west_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSummaryCard(
                            title: "Expense",
                            amount: dashboardProvider.summary?.totalExpense ?? 0.0,
                            color: AppColors.danger,
                            icon: Icons.north_east_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    AppDimensions.hLG,
                    // Monthly Trend Chart Section
                    const Text(
                      "Monthly summary",
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
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildLegendItem("Income", AppColors.success),
                                const SizedBox(width: 16),
                                _buildLegendItem("Expense", AppColors.danger),
                              ],
                            ),
                            _buildMonthlyTrendChart(dashboardProvider, isDark),
                          ],
                        ),
                      ),
                    ),
                    AppDimensions.hLG,
                    // Recent Transactions Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Transactions",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                        ),
                        TextButton(
                          onPressed: () {
                            context.go("/transactions");
                          },
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
                            width: 1.0,
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
                            width: 1.0,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dashboardProvider.recentTransactions.length,
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
                                    "${isExpense ? '-' : '+'}${_currencyFormat.format(tx.amount)}",
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
}