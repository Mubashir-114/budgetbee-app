import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/analytics_model.dart';
import '../../../providers/analytics_provider.dart';

class AlertPreferencesSheet extends StatefulWidget {
  const AlertPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    final colors = AppColors.of(context);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AlertPreferencesSheet(),
    );
  }

  @override
  State<AlertPreferencesSheet> createState() => _AlertPreferencesSheetState();
}

class _AlertPreferencesSheetState extends State<AlertPreferencesSheet> {
  late bool _enableProactiveInsights;
  late bool _enableBudgetAlerts;
  late bool _enableAnomalyAlerts;
  late bool _enableSavingsAlerts;
  late double _budgetThreshold;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AnalyticsProvider>().preferences;
    _enableProactiveInsights = prefs.enableProactiveInsights;
    _enableBudgetAlerts = prefs.enableBudgetAlerts;
    _enableAnomalyAlerts = prefs.enableAnomalyAlerts;
    _enableSavingsAlerts = prefs.enableSavingsAlerts;
    _budgetThreshold = prefs.budgetThreshold;
  }

  void _savePreferences() {
    final provider = context.read<AnalyticsProvider>();
    final newPrefs = AlertPreferences.create(
      enableProactiveInsights: _enableProactiveInsights,
      enableBudgetAlerts: _enableBudgetAlerts,
      enableAnomalyAlerts: _enableAnomalyAlerts,
      enableSavingsAlerts: _enableSavingsAlerts,
      budgetThreshold: _budgetThreshold,
    );
    provider.updatePreferences(newPrefs);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.watch<AnalyticsProvider>();
    final dismissedCount = provider.dismissedAlertIds.length;

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.lg,
        right: AppDimensions.lg,
        top: AppDimensions.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tune_rounded, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Alert Preferences",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      "Configure deterministic proactive insights",
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Master Switch
          Material(
            color: colors.elevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: _enableProactiveInsights
                    ? colors.primary.withValues(alpha: 0.4)
                    : colors.cardBorder,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Proactive Financial Insights",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  "Display proactive events and pattern alerts",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                activeThumbColor: colors.primary,
                value: _enableProactiveInsights,
                onChanged: (val) {
                  setState(() => _enableProactiveInsights = val);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Sub Category Switches (enabled only if master is on)
          Opacity(
            opacity: _enableProactiveInsights ? 1.0 : 0.45,
            child: IgnorePointer(
              ignoring: !_enableProactiveInsights,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Budget Limit Warnings",
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      "Alerts when approaching or exceeding budgets",
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                    activeThumbColor: colors.primary,
                    value: _enableBudgetAlerts,
                    onChanged: (val) {
                      setState(() => _enableBudgetAlerts = val);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Unusual Spending Alerts",
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      "Detects historical anomalies with statistical confidence",
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                    activeThumbColor: colors.primary,
                    value: _enableAnomalyAlerts,
                    onChanged: (val) {
                      setState(() => _enableAnomalyAlerts = val);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Savings Opportunities",
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    ),
                    subtitle: Text(
                      "Actionable recommendations based on saved records",
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                    activeThumbColor: colors.primary,
                    value: _enableSavingsAlerts,
                    onChanged: (val) {
                      setState(() => _enableSavingsAlerts = val);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Budget Threshold Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Budget Warning Threshold",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${(_budgetThreshold * 100).toInt()}%",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Slider(
                        value: _budgetThreshold,
                        min: 0.50,
                        max: 0.95,
                        divisions: 9,
                        activeColor: colors.primary,
                        inactiveColor: colors.elevated,
                        label: "${(_budgetThreshold * 100).toInt()}%",
                        onChanged: (val) {
                          setState(() => _budgetThreshold = (val * 100).round() / 100.0);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Reset Dismissed Alerts Action
          if (dismissedCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: Text("Reset Dismissed Alerts ($dismissedCount)"),
                onPressed: () {
                  provider.resetDismissedAlerts();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("All dismissed alerts have been restored."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),

          // Save / Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _savePreferences,
              child: const Text(
                "Save Preferences",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
