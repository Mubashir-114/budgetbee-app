import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/goal_model.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/goal_provider.dart';

class ForecastView extends StatefulWidget {
  const ForecastView({super.key});

  @override
  State<ForecastView> createState() => _ForecastViewState();
}

class _ForecastViewState extends State<ForecastView> {
  static const List<Map<String, String>> _horizons = [
    {'key': 'next_30_days', 'label': '30 Days'},
    {'key': 'next_3_months', 'label': '3 Months'},
    {'key': 'next_6_months', 'label': '6 Months'},
    {'key': 'next_12_months', 'label': '12 Months'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GoalProvider>();
      if (provider.forecast == null && !provider.isForecastLoading) {
        provider.loadCashFlowForecast();
      }
    });
  }

  Widget _buildHorizonSelector(GoalProvider provider, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.elevated : colors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        children: _horizons.map((h) {
          final isSelected = provider.selectedHorizon == h['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  provider.setHorizon(h['key']!);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    h['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    String? subtitle,
    dynamic colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: colors.isDark
                ? colors.surface.withValues(alpha: 0.8)
                : colors.divider.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSufficiencyBanner(CashFlowForecastModel forecast, dynamic colors) {
    if (forecast.isSufficient) return const SizedBox.shrink();

    final message = forecast.warnings.isNotEmpty
        ? forecast.warnings.first
        : 'Based on limited historical records (${forecast.historicalMonthsSampled} months sampled). Projections become more precise as more monthly activity is saved.';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preliminary Cash-Flow Projection',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>();
    final provider = context.watch<GoalProvider>();

    if (provider.isForecastLoading && provider.forecast == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colors.primary),
            const SizedBox(height: 14),
            Text(
              'Computing deterministic forecast...',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (provider.errorMessage != null && provider.forecast == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                'Unable to load cash-flow forecast',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.errorMessage!,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => provider.loadCashFlowForecast(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final forecast = provider.forecast;
    if (forecast == null) {
      return const SizedBox.shrink();
    }

    final netColor = forecast.netMonthlyCashFlow >= 0 ? AppColors.success : AppColors.danger;
    final capacityColor = forecast.potentialMonthlySavingsCapacity >= 0
        ? colors.primary
        : AppColors.danger;

    return RefreshIndicator(
      onRefresh: () => provider.loadCashFlowForecast(),
      color: colors.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.md),
        children: [
          // Horizon Selector
          _buildHorizonSelector(provider, colors),
          const SizedBox(height: 16),

          // Data Sufficiency Notice
          _buildSufficiencyBanner(forecast, colors),

          // Monthly Baseline Averages Row
          Row(
            children: [
              _buildMetricCard(
                context: context,
                title: 'Avg Income',
                amount: currency.format(forecast.historicalAvgMonthlyIncome),
                subtitle: 'per month',
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
                colors: colors,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                context: context,
                title: 'Avg Expense',
                amount: currency.format(forecast.historicalAvgMonthlyExpense),
                subtitle: 'per month',
                icon: Icons.trending_down_rounded,
                color: AppColors.danger,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Net Cash Flow and Monthly Savings Capacity
          Row(
            children: [
              _buildMetricCard(
                context: context,
                title: 'Net Cash Flow',
                amount: currency.format(forecast.netMonthlyCashFlow),
                subtitle: 'Income - Expense',
                icon: Icons.account_balance_rounded,
                color: netColor,
                colors: colors,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                context: context,
                title: 'Savings Capacity',
                amount: currency.format(forecast.potentialMonthlySavingsCapacity),
                subtitle: 'Free cash flow',
                icon: Icons.savings_rounded,
                color: capacityColor,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizon Projection Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors.isDark
                    ? [colors.elevated, colors.surface]
                    : [colors.surface, colors.background],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Projected Horizon Totals',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${forecast.horizonMonths} months',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _buildProjectionRow(
                  'Projected Inflow',
                  currency.format(forecast.projectedIncome),
                  AppColors.success,
                  colors,
                ),
                const SizedBox(height: 8),
                _buildProjectionRow(
                  'Projected Outflow',
                  currency.format(forecast.projectedExpenses),
                  AppColors.danger,
                  colors,
                ),
                const SizedBox(height: 8),
                _buildProjectionRow(
                  'Projected Net Savings',
                  currency.format(forecast.projectedNetCashFlow),
                  forecast.projectedNetCashFlow >= 0 ? AppColors.success : AppColors.danger,
                  colors,
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _buildProjectionRow(
                  'Projected Free Savings Capacity',
                  currency.format(forecast.projectedSavingsCapacity),
                  colors.primary,
                  colors,
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Methodology & Governance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(
                color: colors.isDark
                    ? colors.surface.withValues(alpha: 0.8)
                    : colors.divider.withValues(alpha: 0.6),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rule_folder_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Deterministic Methodology',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '• Excluded transactions: Internal wallet transfers, goal allocations, refunds and reversals are strictly excluded to prevent double-counting.',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Baseline sample: Analyzed ${forecast.historicalMonthsSampled} historical months of confirmed stored transactions via read-only private analytics connection.',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Safety notice: Scenario estimates based strictly on past records, never guaranteed future account balances or income.',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProjectionRow(
    String label,
    String value,
    Color valueColor,
    dynamic colors, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? colors.textPrimary : colors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
