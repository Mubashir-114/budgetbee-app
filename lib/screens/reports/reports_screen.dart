import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/currency_provider.dart';
import '../../providers/report_provider.dart';
import 'widgets/cashflow_tab_view.dart';
import 'widgets/categories_tab_view.dart';
import 'widgets/reports_date_range_bar.dart';
import 'widgets/trends_tab_view.dart';

/// FinTrack 2.0 Reports & Financial Analytics Screen.
/// Provides an interactive, animated, and theme-independent analytics
/// suite comprising Trends, Categories, and Cashflow timelines.
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
      builder: (context, child) {
        final colors = AppColors.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.primary,
                  onPrimary: colors.background,
                ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      provider.setDateRange(range);
    }
  }

  void _clearDateRange() {
    context.read<ReportProvider>().clearDateRange();
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
        "PDF Report generated at:\n$path\n(Path copied to clipboard!)",
      );
    } else if (mounted) {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "Failed to export PDF",
      );
    }
  }

  String _getPeriodLabel(DateTimeRange? range) {
    if (range == null) return "All-Time Overview";
    final start = DateFormat('d MMM').format(range.start);
    final end = DateFormat('d MMM yyyy').format(range.end);
    return "$start – $end";
  }

  Widget _buildLoadingSkeleton(dynamic colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        children: [
          SkeletonLoader.card(height: 140),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: SkeletonLoader.card(height: 68)),
              const SizedBox(width: 8),
              Expanded(child: SkeletonLoader.card(height: 68)),
              const SizedBox(width: 8),
              Expanded(child: SkeletonLoader.card(height: 68)),
            ],
          ),
          const SizedBox(height: 16),
          SkeletonLoader.chart(),
          const SizedBox(height: 16),
          SkeletonLoader.card(height: 120),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, dynamic colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colors.danger,
            ),
            const SizedBox(height: 14),
            Text(
              "Unable to load reports",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                context.read<ReportProvider>().loadAllReports();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
    final provider = context.watch<ReportProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "Financial Reports",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        actions: [
          // Export Popup Menu (PDF & CSV)
          PopupMenuButton<String>(
            icon: provider.isExporting || provider.isPdfExporting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : Icon(
                    Icons.download_rounded,
                    color: colors.textPrimary,
                  ),
            tooltip: "Export report",
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.cardBorder),
            ),
            onSelected: (action) {
              if (action == 'pdf') {
                _exportPDF();
              } else if (action == 'csv') {
                _exportCSV();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: colors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Export PDF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(
                      Icons.table_chart_rounded,
                      color: colors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Export CSV',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // Date Range Filter Bar
              ReportsDateRangeBar(
                selectedRange: provider.selectedDateRange,
                onSelectRange: _selectDateRange,
                onClearRange: _clearDateRange,
              ),
              const SizedBox(height: 4),

              // Refined Modern Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.divider.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: colors.primary,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: colors.primary,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: -0.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: "Trends"),
                    Tab(text: "Categories"),
                    Tab(text: "Cashflow"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: provider.isLoading && provider.summary == null
          ? _buildLoadingSkeleton(colors)
          : provider.errorMessage != null && provider.summary == null
              ? _buildErrorState(provider.errorMessage!, colors)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    TrendsTabView(
                      summary: provider.summary,
                      trends: provider.trendsReports,
                      periodLabel: _getPeriodLabel(provider.selectedDateRange),
                      onRefresh: provider.loadAllReports,
                    ),
                    CategoriesTabView(
                      categoryReports: provider.categoryReports,
                      onRefresh: provider.loadAllReports,
                    ),
                    CashflowTabView(
                      cashflowReports: provider.cashflowReports,
                      onRefresh: provider.loadAllReports,
                    ),
                  ],
                ),
    );
  }
}
