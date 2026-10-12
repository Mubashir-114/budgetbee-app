import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';

/// Compact, elegant month & year selector for FinTrack Budgets.
/// Replaces the oversized card with a sleek `‹   OCTOBER 2026   ›` control,
/// with animated month transitions and quick date picker dialog access.
class BudgetMonthSelector extends StatelessWidget {
  const BudgetMonthSelector({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onTapMonth,
    this.isLoading = false,
  });

  final int selectedMonth;
  final int selectedYear;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onTapMonth;
  final bool isLoading;

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return now.month == selectedMonth && now.year == selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final monthName = DateFormat('MMMM').format(DateTime(selectedYear, selectedMonth)).toUpperCase();
    final dateKey = ValueKey('$selectedMonth-$selectedYear');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: colors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.04 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  // Previous Month Button
                  Semantics(
                    label: 'Previous month',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      color: colors.textSecondary,
                      tooltip: "Previous Month",
                      splashRadius: 20,
                      onPressed: onPreviousMonth,
                    ),
                  ),

                  // Month & Year Display (Tap to open picker)
                  Expanded(
                    child: InkWell(
                      onTap: onTapMonth,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            AnimatedSwitcher(
                              duration: reduceMotion ? Duration.zero : AppMotion.quick,
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                "$monthName $selectedYear",
                                key: dateKey,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            if (_isCurrentMonth) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "NOW",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next Month Button
                  Semantics(
                    label: 'Next month',
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      color: colors.textSecondary,
                      tooltip: "Next Month",
                      splashRadius: 20,
                      onPressed: onNextMonth,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colors.divider,
                color: colors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
