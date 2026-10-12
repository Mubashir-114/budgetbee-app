import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/budget_model.dart';

/// Refined in-app status notification banner for budget alerts and insights.
/// Displays exceeding limits, approaching warning thresholds, and allowance insights.
class BudgetAlertsBanner extends StatefulWidget {
  const BudgetAlertsBanner({
    super.key,
    required this.alerts,
  });

  final BudgetAlertsResponseModel alerts;

  @override
  State<BudgetAlertsBanner> createState() => _BudgetAlertsBannerState();
}

class _BudgetAlertsBannerState extends State<BudgetAlertsBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final alerts = widget.alerts;
    final isCritical = alerts.exceeded.isNotEmpty;
    final alertItems = [...alerts.exceeded, ...alerts.approachingLimit];

    if (alertItems.isEmpty && alerts.overallAlert == null && alerts.insights.isEmpty) {
      return const SizedBox.shrink();
    }

    final accentColor = isCritical ? colors.danger : colors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.32),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Title Bar
            Row(
              children: [
                Icon(
                  isCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isCritical ? "Budget Alert" : "Budget Notice",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: accentColor,
                    letterSpacing: -0.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${alerts.totalAlertsCount} ${alerts.totalAlertsCount == 1 ? 'item' : 'items'}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Overall Alert Message (if present)
            if (alerts.overallAlert != null) ...[
              Text(
                alerts.overallAlert!.message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
            ],

            // Category Alerts (first 2 items always visible)
            ...alertItems.take(_expanded ? alertItems.length : 2).map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "• ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            a.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            // Daily Allowance / Insights (if available)
            if (_expanded && alerts.insights.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...alerts.insights.map(
                (ins) => Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 13, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "${ins.title}: ${ins.message}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Expand / Collapse Action
            if (alertItems.length > 2 || alerts.insights.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _expanded ? "Show less" : "View ${alertItems.length - 2 + alerts.insights.length} more notices...",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
