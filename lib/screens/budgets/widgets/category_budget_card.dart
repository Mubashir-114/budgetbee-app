import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';

/// Animated, tactile category budget card for FinTrack Budgets.
/// Features a category-specific tinted icon, progress bar, financial metrics,
/// status pill indicator, and staggered entrance animation.
class CategoryBudgetCard extends StatefulWidget {
  const CategoryBudgetCard({
    super.key,
    required this.budget,
    required this.currency,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetCategoryProgressModel budget;
  final CurrencyProvider currency;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<CategoryBudgetCard> createState() => _CategoryBudgetCardState();
}

class _CategoryBudgetCardState extends State<CategoryBudgetCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: AppMotion.enter,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: AppMotion.enter,
    ));

    // Staggered entry delay: ~50ms per item
    final delayMs = (widget.index * 50).clamp(0, 350);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (reduceMotion) {
          _entryController.value = 1.0;
        } else {
          _entryController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final b = widget.budget;
    final limitNum = double.tryParse(b.budgetLimit) ?? 0.0;
    final spentNum = double.tryParse(b.actualSpending) ?? 0.0;
    final remainingNum = double.tryParse(b.remainingAmount) ?? 0.0;
    final isOver = b.status == "exceeded";
    final isApproaching = b.status == "approaching_limit";

    final progressVal = limitNum <= 0 ? 0.0 : (spentNum / limitNum).clamp(0.0, 1.0);

    Color progressColor = colors.primary;
    if (isOver) {
      progressColor = colors.danger;
    } else if (isApproaching) {
      progressColor = colors.warning;
    }

    final catIcon = getCategoryIcon(b.category);
    final catColor = getCategoryColor(b.category);

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed && !reduceMotion ? 0.985 : 1.0,
            duration: AppMotion.press,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                border: Border.all(
                  color: isOver
                      ? colors.danger.withValues(alpha: 0.4)
                      : (isApproaching
                          ? colors.warning.withValues(alpha: 0.4)
                          : colors.cardBorder),
                  width: isOver || isApproaching ? 1.4 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isOver
                            ? colors.danger
                            : (isApproaching ? colors.warning : catColor))
                        .withValues(alpha: isDark ? 0.06 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Category Icon, Name, Status Pill, Action Menu
                    Row(
                      children: [
                        // Distinct Category Icon
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: catColor.withValues(alpha: 0.28),
                              width: 1,
                            ),
                          ),
                          child: Icon(catIcon, size: 20, color: catColor),
                        ),
                        const SizedBox(width: 12),

                        // Category Name & Type
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.category,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Limit: ${widget.currency.format(limitNum)}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        if (isOver)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                            ),
                            child: Text(
                              "OVER BUDGET",
                              style: TextStyle(
                                color: colors.danger,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else if (isApproaching)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                            ),
                            child: Text(
                              "80%+ USED",
                              style: TextStyle(
                                color: colors.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.success.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                            ),
                            child: Text(
                              "ON TRACK",
                              style: TextStyle(
                                color: colors.success,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                        const SizedBox(width: 4),

                        // Action Menu (Edit / Delete)
                        PopupMenuButton<String>(
                          iconColor: colors.textSecondary,
                          color: colors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: colors.divider),
                          ),
                          onSelected: (action) {
                            if (action == 'edit') {
                              widget.onEdit();
                            } else if (action == 'delete') {
                              widget.onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined, size: 18),
                                title: Text('Edit Amount', style: TextStyle(fontSize: 13)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline_rounded,
                                    color: colors.danger, size: 18),
                                title: Text('Delete',
                                    style: TextStyle(color: colors.danger, fontSize: 13)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Animated Progress Bar
                    AnimatedProgressBar(
                      value: progressVal,
                      backgroundColor: colors.divider,
                      color: progressColor,
                      height: 7,
                      semanticLabel: '${b.category} budget used',
                    ),

                    const SizedBox(height: 10),

                    // Spending & Remaining Metrics
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Spent: ${widget.currency.format(spentNum)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: isOver ? colors.danger : colors.textSecondary,
                            fontWeight: isOver ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        Text(
                          remainingNum >= 0
                              ? "Remaining: ${widget.currency.format(remainingNum)}"
                              : "Over by: ${widget.currency.format(remainingNum.abs())}",
                          style: TextStyle(
                            color: remainingNum >= 0 ? colors.success : colors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Utilization percentage & projection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${b.utilizationPercentage}% (${b.projectedSpending} proj)",
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                        if (b.daysRemaining > 0)
                          Text(
                            "${b.daysRemaining} days left",
                            style: TextStyle(
                              fontSize: 11,
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
    );
  }
}
