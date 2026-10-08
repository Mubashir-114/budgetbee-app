import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/custom_toast.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAllReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final provider = context.read<ReportProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: provider.selectedDateRange,
    );
    if (range != null) {
      provider.setDateRange(range);
    }
  }

  Future<void> _exportCSV() async {
    final provider = context.read<ReportProvider>();
    final csv = await provider.exportCSV();

    if (csv != null && mounted) {
      try {
        final outputDir = await getApplicationDocumentsDirectory();
        if (!mounted) return;
        final file = File(
          "${outputDir.path}/finance_report_${DateTime.now().millisecondsSinceEpoch}.csv",
        );
        await file.writeAsString(csv);
        if (!mounted) return;
        await Clipboard.setData(ClipboardData(text: file.path));
        if (!mounted) return;
        CustomToast.showSuccess(
          context,
          "CSV Report saved to:\n${file.path}\n(Path copied to clipboard!)",
        );
      } catch (_) {
        if (!mounted) return;
        await Clipboard.setData(ClipboardData(text: csv));
        if (!mounted) return;
        CustomToast.showSuccess(context, "CSV report copied to clipboard!");
      }
    } else if (mounted) {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "Failed to export CSV",
      );
    }
  }

  Future<void> _exportPDF() async {
    final provider = context.read<ReportProvider>();
    final dateRangeStr = provider.selectedDateRange != null
        ? "${DateFormat('yyyy-MM-dd').format(provider.selectedDateRange!.start)} to ${DateFormat('yyyy-MM-dd').format(provider.selectedDateRange!.end)}"
        : "All Time";

    final path = await provider.exportPDF(
      dateRangeStr,
      context.read<CurrencyProvider>().currencySymbol,
    );

    if (path != null && mounted) {
      await Clipboard.setData(ClipboardData(text: path));
      if (!mounted) return;
      CustomToast.showSuccess(
        context,
        "PDF Report generated successfully at:\n$path\n(Path copied to clipboard!)",
      );
    } else if (mounted) {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "Failed to export PDF",
      );
    }
  }

  Widget _buildOverviewTab(ReportProvider provider, bool isDark) {
    final summary = provider.summary;
    if (summary == null) {
      return const EmptyState(
        icon: Icons.analytics_outlined,
        title: "No data available",
        description: "There is no overview data available for this range.",
      );
    }

    final isTablet = MediaQuery.of(context).size.width >= 600;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: isTablet ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isTablet ? 1.5 : 1.35,
            children: [
              _buildStatCard(
                "Total Income",
                summary.totalIncome,
                AppColors.success,
                isDark,
              ),
              _buildStatCard(
                "Total Expense",
                summary.totalExpense,
                AppColors.danger,
                isDark,
              ),
              _buildStatCard(
                "Net Savings",
                summary.netBalance,
                AppColors.info,
                isDark,
              ),
              _buildStatCard(
                "Savings Rate",
                summary.savingsRate,
                AppColors.warning,
                isDark,
                isPercent: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Monthly Trends",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
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
              padding: const EdgeInsets.all(16.0),
              child: _buildTrendsChart(provider, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    double value,
    Color color,
    bool isDark, {
    bool isPercent = false,
  }) {
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
        padding: const EdgeInsets.all(14.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPercent
                  ? "${value.toStringAsFixed(1)}%"
                  : context.watch<CurrencyProvider>().format(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsChart(ReportProvider provider, bool isDark) {
    final trends = provider.trendsReports;
    if (trends.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No trend metrics to plot",
            style: TextStyle(color: AppColors.textSecondaryLight),
          ),
        ),
      );
    }

    final double maxVal = trends.fold(0.0, (max, item) {
      final val = item.income > item.expense ? item.income : item.expense;
      return val > max ? val : max;
    });
    final double adjustedMax = maxVal == 0 ? 100 : maxVal * 1.2;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: adjustedMax,
          alignment: BarChartAlignment.spaceEvenly,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? AppColors.cardDark : AppColors.surfaceLight,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final String type = rodIndex == 0 ? "Income" : "Expense";
                return BarTooltipItem(
                  "$type: ${context.read<CurrencyProvider>().format(rod.toY)}",
                  TextStyle(
                    color: isDark ? AppColors.textLight : AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx >= 0 && idx < trends.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        trends[idx].monthName.substring(0, 3),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
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
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(trends.length, (index) {
            final trend = trends[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: trend.income,
                  color: AppColors.success,
                  width: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: trend.expense,
                  color: AppColors.danger,
                  width: 7,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryTab(ReportProvider provider, bool isDark) {
    final reports = provider.categoryReports;
    if (reports.isEmpty) {
      return const EmptyState(
        icon: Icons.pie_chart_outline_rounded,
        title: "No budget limits configured",
        description: "There are no categories details tracked for this range.",
      );
    }

    final double totalExpense = reports.fold(
      0.0,
      (sum, item) => sum + item.spent,
    );
    final List<PieChartSectionData> sections = [];
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      Colors.pink.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade400,
      Colors.deepPurple.shade400,
    ];

    for (int i = 0; i < reports.length; i++) {
      final r = reports[i];
      if (r.spent <= 0) continue;
      final percentage = totalExpense > 0
          ? (r.spent / totalExpense) * 100
          : 0.0;
      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: r.spent,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 35,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Expense Allocations",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          AppDimensions.hSM,
          if (sections.isNotEmpty)
            Card(
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
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 140,
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 30,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                    ),
                    AppDimensions.wMD,
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(reports.length, (index) {
                          final r = reports[index];
                          if (r.spent <= 0) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    r.category,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.textLight
                                          : AppColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
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
                  color: isDark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    "No expenses recorded to build allocations.",
                    style: TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            "Budget Tracking Status",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          AppDimensions.hSM,
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final r = reports[index];
              final progress = r.budget <= 0
                  ? 0.0
                  : (r.spent / r.budget).clamp(0.0, 1.0);
              final isOver = r.spent > r.budget && r.budget > 0;

              return Card(
                elevation: 0,
                color: isDark ? AppColors.surfaceDark : Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            r.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "${context.watch<CurrencyProvider>().format(r.spent)} / ${context.watch<CurrencyProvider>().format(r.budget)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isOver
                                  ? AppColors.danger
                                  : (isDark
                                        ? AppColors.textLight
                                        : AppColors.textDark),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: isOver ? AppColors.danger : AppColors.success,
                          backgroundColor: isDark
                              ? AppColors.dividerDark
                              : Colors.grey.shade100,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        r.budget == 0
                            ? "No budget allocated"
                            : isOver
                            ? "Over budget limit by ${context.read<CurrencyProvider>().format(r.spent - r.budget)}"
                            : "Remaining budget limit: ${context.read<CurrencyProvider>().format(r.remaining)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isOver ? AppColors.danger : AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCashflowTab(ReportProvider provider, bool isDark) {
    final reports = provider.cashflowReports;
    if (reports.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_rounded,
        title: "No cashflow details",
        description: "No ledger accounts found for this period range.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final item = reports[index];
        final isExpense = item.type == "expense";

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            side: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: isExpense
                  ? AppColors.danger.withValues(alpha: 0.1)
                  : AppColors.success.withValues(alpha: 0.1),
              radius: 18,
              child: Icon(
                isExpense
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isExpense ? AppColors.danger : AppColors.success,
                size: 16,
              ),
            ),
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              "${item.category} • ${item.date}",
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isExpense ? '-' : '+'}${context.watch<CurrencyProvider>().format(item.amount)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpense ? AppColors.danger : AppColors.success,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Balance: ${context.watch<CurrencyProvider>().format(item.runningBalance)}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.scaffold,
      appBar: AppBar(
        title: const Text(
          "Reports",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.date_range_rounded,
              color: provider.selectedDateRange != null
                  ? AppColors.primary
                  : null,
            ),
            onPressed: _selectDateRange,
          ),
          PopupMenuButton<String>(
            icon: provider.isExporting || provider.isPdfExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            onSelected: (action) {
              if (action == 'pdf') {
                _exportPDF();
              } else if (action == 'csv') {
                _exportCSV();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.danger,
                    size: 20,
                  ),
                  title: Text('Export PDF', style: TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(
                    Icons.grid_on_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  title: Text('Export CSV', style: TextStyle(fontSize: 14)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          AppDimensions.wSM,
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3.0,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: "Trends"),
            Tab(text: "Categories"),
            Tab(text: "Cashflow"),
          ],
        ),
      ),
      body: provider.isLoading && provider.summary == null
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: SkeletonLoader.card(height: 60)),
                      const SizedBox(width: 8),
                      Expanded(child: SkeletonLoader.card(height: 60)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: SkeletonLoader.card(height: 60)),
                      const SizedBox(width: 8),
                      Expanded(child: SkeletonLoader.card(height: 60)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SkeletonLoader.chart(),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(provider, isDark),
                _buildCategoryTab(provider, isDark),
                _buildCashflowTab(provider, isDark),
              ],
            ),
    );
  }
}
