import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/analytics_model.dart';
import '../../../providers/analytics_provider.dart';
import 'alert_preferences_sheet.dart';
import 'fin_character.dart';

class InsightsFeedView extends StatelessWidget {
  const InsightsFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.watch<AnalyticsProvider>();

    if (provider.isLoadingAlerts) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Evaluating financial patterns...",
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.alertsError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded, color: colors.danger, size: 36),
            const SizedBox(height: 10),
            Text(
              "Unable to Load Live Alerts",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              provider.alertsError!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => provider.loadAlerts(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("Retry Evaluation"),
            ),
          ],
        ),
      );
    }

    if (!provider.preferences.enableProactiveInsights) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.notifications_off_outlined, color: colors.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              "Proactive Insights Disabled",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Enable automated pattern detection to receive budget and spending warnings.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => AlertPreferencesSheet.show(context),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text("Customize Preferences"),
            ),
          ],
        ),
      );
    }

    final activeAlerts = provider.activeAlerts;

    if (activeAlerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Column(
          children: [
            const FinCharacter(size: 48, state: FinCharacterState.happy),
            const SizedBox(height: 12),
            Text(
              "All Clear! No Active Alerts",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              provider.dismissedAlertIds.isNotEmpty
                  ? "You have dismissed ${provider.dismissedAlertIds.length} alert(s) for this session."
                  : "All monitored budgets and categories are operating within healthy historical parameters.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (provider.dismissedAlertIds.isNotEmpty) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => provider.resetDismissedAlerts(),
                    icon: const Icon(Icons.restore_rounded, size: 16),
                    label: const Text("Reset Dismissed"),
                  ),
                  const SizedBox(width: 10),
                ],
                IconButton(
                  tooltip: "Refresh alerts",
                  icon: Icon(Icons.refresh_rounded, color: colors.primary),
                  onPressed: () => provider.loadAlerts(),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Smart Alerts Feed",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${activeAlerts.length}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: "Preferences",
                  icon: Icon(Icons.tune_rounded, size: 20, color: colors.textSecondary),
                  onPressed: () => AlertPreferencesSheet.show(context),
                ),
                IconButton(
                  tooltip: "Refresh alerts",
                  icon: Icon(Icons.refresh_rounded, size: 20, color: colors.textSecondary),
                  onPressed: () => provider.loadAlerts(),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 10),

        // List of Active Prioritized Alert Cards
        ...activeAlerts.map((alert) => _buildAlertCard(context, colors, provider, alert)),
      ],
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    dynamic colors,
    AnalyticsProvider provider,
    SmartAlertItem alert,
  ) {
    Color severityColor;
    IconData severityIcon;

    switch (alert.severity) {
      case 'critical':
        severityColor = colors.danger;
        severityIcon = Icons.warning_rounded;
        break;
      case 'high':
        severityColor = Colors.orangeAccent;
        severityIcon = Icons.error_outline_rounded;
        break;
      case 'medium':
        severityColor = colors.warning;
        severityIcon = Icons.info_outline_rounded;
        break;
      case 'low':
        severityColor = colors.info;
        severityIcon = Icons.trending_up_rounded;
        break;
      default:
        severityColor = colors.primary;
        severityIcon = Icons.lightbulb_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.severity == 'critical'
              ? severityColor.withValues(alpha: 0.6)
              : colors.cardBorder,
          width: alert.severity == 'critical' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: severityColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row: Severity, Type, and Dismiss Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(severityIcon, size: 14, color: severityColor),
                      const SizedBox(width: 4),
                      Text(
                        alert.severity.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.type.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Dismiss alert",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close_rounded, size: 18, color: colors.textSecondary),
                  onPressed: () => provider.dismissAlert(alert.id),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              alert.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            // Explanation
            Text(
              alert.explanation,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),

            // Calculated Values Metrics (if available)
            if (alert.calculatedValues.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMetricsRow(colors, alert.calculatedValues),
            ],

            const SizedBox(height: 12),

            // Provenance Tag (Privacy and Determinism Guarantee)
            if (alert.provenance != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.elevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 12, color: colors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "${alert.provenance!.source} • ${alert.provenance!.period ?? alert.period?.label ?? 'Current Period'}",
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Contextual FIN Quick Actions
            Text(
              "Ask FIN about this:",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            _buildContextualQuestionChips(colors, provider, alert),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(dynamic colors, Map<String, dynamic> values) {
    final entries = values.entries.take(4).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((entry) {
        String valStr = entry.value.toString();
        if (entry.value is double) {
          valStr = (entry.value as double).toStringAsFixed(1);
        } else if (entry.value is num) {
          valStr = entry.value.toString();
        }

        final label = entry.key
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : "")
            .join(' ');

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.elevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: colors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                valStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContextualQuestionChips(
    dynamic colors,
    AnalyticsProvider provider,
    SmartAlertItem alert,
  ) {
    List<String> questions = [];

    switch (alert.type) {
      case 'budget_exceeded':
      case 'budget_reached':
      case 'budget_approaching':
      case 'budget_burn_rate':
        questions = [
          "Why am I over budget?",
          "How was this calculated?",
          "What can I do to improve?",
        ];
        break;
      case 'unusual_category_spending':
      case 'large_individual_expense':
      case 'spending_spike':
        questions = [
          "Explain this spending increase",
          "How was this calculated?",
          "Compare this with last month",
        ];
        break;
      case 'spending_trend_increase':
      case 'category_trend_increase':
        questions = [
          "Compare this with last month",
          "Explain this spending increase",
          "What can I do to improve?",
        ];
        break;
      case 'savings_opportunity':
        questions = [
          "What can I do to improve?",
          "How was this calculated?",
          "Why am I over budget?",
        ];
        break;
      default:
        questions = [
          "How was this calculated?",
          "Compare this with last month",
        ];
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: questions.map((q) {
        return ActionChip(
          backgroundColor: colors.primary.withValues(alpha: 0.1),
          side: BorderSide(color: colors.primary.withValues(alpha: 0.25)),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 12, color: colors.primary),
              const SizedBox(width: 5),
              Text(
                q,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          onPressed: () {
            provider.askAlertQuestion(alert, q);
          },
        );
      }).toList(),
    );
  }
}
