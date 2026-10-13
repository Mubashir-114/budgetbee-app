import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/goal_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import 'widgets/add_edit_contribution_sheet.dart';
import 'widgets/add_edit_goal_sheet.dart';

class GoalDetailScreen extends StatefulWidget {
  final int goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final provider = context.read<GoalProvider>();
    await provider.loadGoalById(widget.goalId);
  }

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

  Future<void> _confirmDeleteGoal(GoalModel goal) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Delete "${goal.name}"?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Are you sure you want to delete this savings goal and all its tracked progress history? This action cannot be undone.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await context.read<GoalProvider>().deleteGoal(goal.id);
        if (mounted && success) {
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete goal: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleArchiveGoal(GoalModel goal) async {
    final provider = context.read<GoalProvider>();
    try {
      final newStatus = goal.status == 'archived' ? 'active' : 'archived';
      await provider.updateGoal(goal.id, {'status': newStatus});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update goal: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteContribution(int contributionId) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Remove Contribution?', style: TextStyle(color: colors.textPrimary)),
        content: Text(
          'Remove this progress contribution record? Your goal saved total will be automatically recalculated.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<GoalProvider>().deleteContribution(widget.goalId, contributionId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete contribution: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>();
    final provider = context.watch<GoalProvider>();

    final goal = provider.selectedGoal?.id == widget.goalId
        ? provider.selectedGoal
        : provider.goals.where((g) => g.id == widget.goalId).firstOrNull;

    if (provider.isLoading && goal == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    if (goal == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(
                'Goal not found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to Planning'),
              ),
            ],
          ),
        ),
      );
    }

    final contributions = goal.recentContributions;
    final statusColor = _getStatusColor(goal.intelligenceStatus, colors);
    final statusLabel = _getStatusLabel(goal.intelligenceStatus, goal.isOverdue);
    final statusIcon = _getStatusIcon(goal.intelligenceStatus, goal.isOverdue);
    final progressRatio = (goal.progressPercentage / 100).clamp(0.0, 1.0);

    DateTime? targetDateParsed;
    if (goal.targetDate != null) {
      try {
        targetDateParsed = DateTime.parse(goal.targetDate!);
      } catch (_) {}
    }

    DateTime? completionDateParsed;
    if (goal.estimatedCompletionDate != null) {
      try {
        completionDateParsed = DateTime.parse(goal.estimatedCompletionDate!);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          goal.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: colors.textSecondary),
            tooltip: 'Edit Goal',
            onPressed: () => AddEditGoalSheet.show(context, goal: goal),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary),
            color: colors.surface,
            onSelected: (val) {
              if (val == 'archive') {
                _toggleArchiveGoal(goal);
              } else if (val == 'delete') {
                _confirmDeleteGoal(goal);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      goal.status == 'archived'
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      goal.status == 'archived' ? 'Unarchive Goal' : 'Archive Goal',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Delete Goal', style: TextStyle(color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditContributionSheet.show(
          context,
          goalId: goal.id,
          goalName: goal.name,
        ),
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record Progress', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: colors.primary,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.md),
          children: [
            // Progress Hero Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
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
                  // Status Badge & Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${goal.progressPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (goal.description != null && goal.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      goal.description!,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      minHeight: 12,
                      backgroundColor: colors.isDark ? colors.elevated : colors.background,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal.isAchieved ? AppColors.success : colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saved vs Remaining vs Target stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeroStat(
                        'Saved So Far',
                        currency.format(goal.savedAmount),
                        colors.primary,
                        colors,
                      ),
                      _buildHeroStat(
                        'Remaining',
                        currency.format(goal.remainingAmount),
                        goal.remainingAmount > 0 ? AppColors.danger : AppColors.success,
                        colors,
                      ),
                      _buildHeroStat(
                        'Target Goal',
                        currency.format(goal.targetAmount),
                        colors.textPrimary,
                        colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Deterministic Intelligence Card
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
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
                      Icon(Icons.insights_rounded, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Progress Intelligence',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Target Date / Days Left
                  _buildIntelligenceRow(
                    label: 'Target Deadline',
                    value: targetDateParsed != null
                        ? DateFormat('MMMM dd, yyyy').format(targetDateParsed)
                        : 'No deadline set',
                    subtitle: targetDateParsed != null
                        ? (goal.daysRemaining != null && goal.daysRemaining! > 0
                            ? '${goal.daysRemaining} days left (${goal.monthsRemaining?.toStringAsFixed(1)} months)'
                            : 'Target date has passed')
                        : null,
                    icon: Icons.calendar_today_rounded,
                    colors: colors,
                  ),
                  const Divider(height: 18),

                  // Required Monthly Saving
                  if (goal.requiredMonthlySaving != null && goal.requiredMonthlySaving! > 0) ...[
                    _buildIntelligenceRow(
                      label: 'Required Monthly Pace',
                      value: '${currency.format(goal.requiredMonthlySaving!)} / month',
                      subtitle: 'To achieve target by your deadline',
                      icon: Icons.speed_rounded,
                      colors: colors,
                      valueColor: colors.primary,
                    ),
                    const Divider(height: 18),
                  ],

                  // Completion Projection
                  _buildIntelligenceRow(
                    label: 'Estimated Completion Date',
                    value: goal.isAchieved
                        ? 'Goal Target Achieved!'
                        : (goal.isEstimated && completionDateParsed != null
                            ? DateFormat('MMMM yyyy').format(completionDateParsed)
                            : 'More data needed'),
                    subtitle: goal.isAchieved
                        ? 'Congratulations on reaching your target!'
                        : (goal.estimationReason ?? 'Based on contribution velocity'),
                    icon: Icons.track_changes_rounded,
                    colors: colors,
                    valueColor: goal.isAchieved
                        ? AppColors.success
                        : (goal.isEstimated ? colors.primary : colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Ask FIN Assistant Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors.isDark
                      ? [colors.elevated, colors.surface]
                      : [colors.primary.withValues(alpha: 0.1), colors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask FIN About This Goal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ask "When can I reach my ${goal.name} goal?"',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      final prompt = 'When can I reach my ${goal.name} goal?';
                      context.push('/analytics?q=${Uri.encodeComponent(prompt)}');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    child: const Text('Ask FIN'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contributions List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contribution History (${contributions.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => AddEditContributionSheet.show(
                    context,
                    goalId: goal.id,
                    goalName: goal.name,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Record', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contribution List or Empty State
            if (contributions.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
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
                  children: [
                    Icon(Icons.savings_outlined, size: 36, color: colors.textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'No contributions recorded yet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record saved amounts to track your progress and calculate velocity completion dates.',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => AddEditContributionSheet.show(
                        context,
                        goalId: goal.id,
                        goalName: goal.name,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Record First Progress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contributions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final c = contributions[index];
                  DateTime cDate = DateTime.now();
                  try {
                    cDate = DateTime.parse(c.contributionDate);
                  } catch (_) {}

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(
                        color: colors.isDark
                            ? colors.surface.withValues(alpha: 0.8)
                            : colors.divider.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                          ),
                          child: Icon(Icons.arrow_upward_rounded, color: colors.primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currency.format(c.amount),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy').format(cDate),
                                style: TextStyle(fontSize: 11, color: colors.textSecondary),
                              ),
                              if (c.note != null && c.note!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  c.note!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: colors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, size: 18, color: colors.textSecondary),
                          color: colors.surface,
                          onSelected: (val) {
                            if (val == 'edit') {
                              AddEditContributionSheet.show(
                                context,
                                goalId: goal.id,
                                goalName: goal.name,
                                contribution: c,
                              );
                            } else if (val == 'delete') {
                              _confirmDeleteContribution(c.id);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 16, color: colors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text('Edit', style: TextStyle(color: colors.textPrimary)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                  SizedBox(width: 8),
                                  Text('Remove', style: TextStyle(color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 80), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(
    String label,
    String amount,
    Color color,
    dynamic colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildIntelligenceRow({
    required String label,
    required String value,
    String? subtitle,
    required IconData icon,
    required dynamic colors,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? colors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
