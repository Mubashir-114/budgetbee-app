import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';

/// Refined date range selector bar for FinTrack Reports.
/// Displays the active period label and allows quick date picking or resetting.
class ReportsDateRangeBar extends StatelessWidget {
  const ReportsDateRangeBar({
    super.key,
    required this.selectedRange,
    required this.onSelectRange,
    required this.onClearRange,
  });

  final DateTimeRange? selectedRange;
  final VoidCallback onSelectRange;
  final VoidCallback onClearRange;

  String _formatRange(DateTimeRange range) {
    final startYear = range.start.year;
    final endYear = range.end.year;
    final nowYear = DateTime.now().year;

    if (startYear == endYear && startYear == nowYear) {
      final start = DateFormat('d MMM').format(range.start);
      final end = DateFormat('d MMM').format(range.end);
      return '$start – $end';
    } else if (startYear == endYear) {
      final start = DateFormat('d MMM').format(range.start);
      final end = DateFormat('d MMM yyyy').format(range.end);
      return '$start – $end';
    } else {
      final start = DateFormat('d MMM yy').format(range.start);
      final end = DateFormat('d MMM yy').format(range.end);
      return '$start – $end';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFilter = selectedRange != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onSelectRange,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                child: AnimatedContainer(
                  duration: AppMotion.quick,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hasFilter
                        ? colors.primary.withValues(alpha: isDark ? 0.14 : 0.08)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(
                      color: hasFilter
                          ? colors.primary.withValues(alpha: 0.45)
                          : colors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: hasFilter ? colors.primary : colors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasFilter
                              ? _formatRange(selectedRange!)
                              : "All Time (Complete History)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                            color: hasFilter ? colors.textPrimary : colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClearRange,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(
                      color: colors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Reset",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
