import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/goal_model.dart';
import '../../../providers/currency_provider.dart';

class GoalCard extends StatelessWidget {
  final GoalModel goal;

  const GoalCard({super.key, required this.goal});

  Color _getStatusColor(String status, dynamic colors) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'on_track':
        return AppColors.success;
      case 'behind_schedule':
        return AppColors.danger;
      case 'archived':
        return colors.textSecondary;
      case 'in_progress':
      default:
        return AppColors.info;
    }
  }

  String _getStatusLabel(String status, bool isOverdue) {
    if (isOverdue) return 'Overdue';
    switch (status) {
      case 'completed':
        return 'Achieved';
      case 'on_track':
        return 'On Track';
      case 'behind_schedule':
        return 'Behind Pace';
      case 'archived':
        return 'Archived';
      case 'in_progress':
      default:
        return 'In Progress';
    }
  }

  IconData _getStatusIcon(String status, bool isOverdue) {
    if (isOverdue) return Icons.warning_amber_rounded;
    switch (status) {
      case 'completed':
        return Icons.check_circle_rounded;
      case 'on_track':
        return Icons.trending_up_rounded;
      case 'behind_schedule':
        return Icons.priority_high_rounded;
      case 'archived':
        return Icons.archive_outlined;
      case 'in_progress':
      default:
        return Icons.savings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>();
    final statusColor = _getStatusColor(goal.intelligenceStatus, colors);
    final statusLabel = _getStatusLabel(goal.intelligenceStatus, goal.isOverdue);
    final statusIcon = _getStatusIcon(goal.intelligenceStatus, goal.isOverdue);

    final progressRatio = (goal.progressPercentage / 100).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: colors.isDark
              ? colors.surface.withValues(alpha: 0.8)
              : colors.divider.withValues(alpha: 0.6),
        ),
      ),
      color: colors.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        onTap: () {
          context.push('/planning/goals/${goal.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    ),
                    child: Icon(Icons.flag_rounded, color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (goal.description != null && goal.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              goal.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Saved vs Target Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracked Saved',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(goal.savedAmount),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Target',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(goal.targetAmount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress Bar
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progressRatio,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.primary,
                            goal.isAchieved ? AppColors.success : colors.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer: Progress % & Target Date or Required Monthly Saving
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.progressPercentage.toStringAsFixed(1)}% completed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  if (goal.targetDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          goal.isOverdue
                              ? 'Due date passed'
                              : goal.daysRemaining != null
                                  ? '${goal.daysRemaining} days left'
                                  : goal.targetDate!,
                          style: TextStyle(
                            fontSize: 12,
                            color: goal.isOverdue ? AppColors.danger : colors.textSecondary,
                            fontWeight: goal.isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'No deadline set',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),

              if (goal.requiredMonthlySaving != null && !goal.isAchieved && !goal.isOverdue) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Pace: ${currency.format(goal.requiredMonthlySaving!)}/mo needed to finish on time',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
