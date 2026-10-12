import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/report_models.dart';
import '../../../providers/currency_provider.dart';

/// Complete redesign of the Cashflow Tab for FinTrack 2.0.
/// Renders an interactive financial activity timeline grouped by date,
/// with localized friendly dates, daily net flow summaries, timeline markers,
/// and transaction inspection sheets.
class CashflowTabView extends StatelessWidget {
  const CashflowTabView({
    super.key,
    required this.cashflowReports,
    required this.onRefresh,
  });

  final List<CashflowReport> cashflowReports;
  final Future<void> Function() onRefresh;

  String _formatFriendlyTimestamp(String dateStr) {
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final txDay = DateTime(parsed.year, parsed.month, parsed.day);
      final diff = today.difference(txDay).inDays;

      final bool hasTime = dateStr.contains('T') || dateStr.contains(':');
      final timeStr = hasTime ? DateFormat('h:mm a').format(parsed) : null;

      if (diff == 0) {
        return timeStr != null ? "Today, $timeStr" : "Today";
      } else if (diff == 1) {
        return timeStr != null ? "Yesterday, $timeStr" : "Yesterday";
      } else if (diff > 1 && diff < 7) {
        final dayName = DateFormat('EEEE').format(parsed);
        return timeStr != null ? "$dayName, $timeStr" : dayName;
      } else if (parsed.year == now.year) {
        final d = DateFormat('d MMM').format(parsed);
        return timeStr != null ? "$d, $timeStr" : d;
      } else {
        final d = DateFormat('d MMM yyyy').format(parsed);
        return timeStr != null ? "$d, $timeStr" : d;
      }
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateHeader(String dateStr) {
    try {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed == null) return dateStr;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final txDay = DateTime(parsed.year, parsed.month, parsed.day);
      final diff = today.difference(txDay).inDays;

      if (diff == 0) return "Today";
      if (diff == 1) return "Yesterday";
      if (parsed.year == now.year) {
        return DateFormat('EEEE, d MMMM').format(parsed);
      }
      return DateFormat('EEEE, d MMMM yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  void _showTransactionDetails(
    BuildContext context,
    CashflowReport item,
    dynamic colors,
    CurrencyProvider currency,
  ) {
    final isExpense = item.type.toLowerCase().trim() == "expense";
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = getCategoryColor(item.category);
    final catIcon = getCategoryIcon(item.category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 16),

                // Icon & Title Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: catColor.withValues(alpha: 0.3)),
                      ),
                      child: Icon(catIcon, color: catColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isExpense ? colors.danger : colors.success)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isExpense ? "Expense" : "Income",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isExpense ? colors.danger : colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Details Grid
                _buildDetailRow("Amount", "${isExpense ? '-' : '+'}${currency.format(item.amount)}", colors,
                    valueColor: isExpense ? colors.danger : colors.success),
                const SizedBox(height: 12),
                _buildDetailRow("Recorded Date", _formatFriendlyTimestamp(item.date), colors),
                const SizedBox(height: 12),
                _buildDetailRow("Cumulative Cash Flow", currency.format(item.runningBalance), colors),
                const SizedBox(height: 8),
                Text(
                  "* Cumulative Cash Flow represents the period's net ledger sum, not a live bank balance.",
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: colors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.elevated,
                      foregroundColor: colors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.cardBorder),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    dynamic colors, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? colors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>();

    if (cashflowReports.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: colors.primary,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.md),
          children: const [
            EmptyState(
              icon: Icons.receipt_long_rounded,
              title: "No cash-flow entries",
              description: "No ledger transactions were recorded in the selected date range.",
            ),
          ],
        ),
      );
    }

    // Group transactions by date key (YYYY-MM-DD)
    final grouped = <String, List<CashflowReport>>{};
    for (final report in cashflowReports) {
      final parsed = DateTime.tryParse(report.date);
      final key = parsed != null ? DateFormat('yyyy-MM-dd').format(parsed) : report.date;
      grouped.putIfAbsent(key, () => []).add(report);
    }

    // Sort date keys in reverse-chronological order (newest dates first)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm,
        ),
        itemCount: sortedKeys.length,
        itemBuilder: (context, dateIndex) {
          final dateKey = sortedKeys[dateIndex];
          final items = grouped[dateKey]!;

          // Calculate daily net inflow/outflow
          double dayIncome = 0.0;
          double dayExpense = 0.0;
          for (final item in items) {
            if (item.type.toLowerCase().trim() == "expense") {
              dayExpense += item.amount;
            } else {
              dayIncome += item.amount;
            }
          }
          final dayNet = dayIncome - dayExpense;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Group Header
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4.0, right: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDateHeader(dateKey),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      dayNet >= 0
                          ? "+${currency.format(dayNet)}"
                          : "-${currency.format(dayNet.abs())}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: dayNet >= 0 ? colors.success : colors.danger,
                      ),
                    ),
                  ],
                ),
              ),

              // Transaction Items in Timeline
              ...List.generate(items.length, (itemIndex) {
                final item = items[itemIndex];
                final isLast = itemIndex == items.length - 1;
                final isExpense = item.type.toLowerCase().trim() == "expense";
                final catColor = getCategoryColor(item.category);
                final catIcon = getCategoryIcon(item.category);
                final formattedTime = _formatFriendlyTimestamp(item.date);
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeline Indicator Column
                      SizedBox(
                        width: 24,
                        child: Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isExpense ? colors.danger : colors.success,
                                border: Border.all(
                                  color: colors.surface,
                                  width: 2,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 1.5,
                                  color: colors.divider.withValues(alpha: 0.4),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Transaction Card
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                            border: Border.all(color: colors.cardBorder),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showTransactionDetails(
                                context,
                                item,
                                colors,
                                currency,
                              ),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    // Category Mini Badge
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(
                                          alpha: isDark ? 0.2 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(catIcon, color: catColor, size: 17),
                                    ),
                                    const SizedBox(width: 10),

                                    // Title & Category Metadata
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
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
                                            "${item.category} • $formattedTime",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: colors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // Amount & Cumulative Indicator
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${isExpense ? '-' : '+'}${currency.format(item.amount)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isExpense ? colors.danger : colors.success,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Flow: ${currency.format(item.runningBalance)}",
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
