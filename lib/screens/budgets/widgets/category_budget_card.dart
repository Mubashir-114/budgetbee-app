import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';
import '../../../core/utils/category_utils.dart';
import '../../../models/budget_model.dart';
import '../../../providers/currency_provider.dart';

/// Supported distinctive visual identities for living category cards.
enum CategoryVisualType {
  food,
  shopping,
  transport,
  healthcare,
  utilities,
  entertainment,
  general,
}

CategoryVisualType resolveCategoryVisualType(String category) {
  final norm = category.toLowerCase().trim();
  if (norm.contains('health') ||
      norm.contains('medic') ||
      norm.contains('pharm') ||
      norm.contains('doctor') ||
      norm.contains('hospital')) {
    return CategoryVisualType.healthcare;
  }
  if (norm.contains('food') ||
      norm.contains('dining') ||
      norm.contains('grocer') ||
      norm.contains('restaurant')) {
    return CategoryVisualType.food;
  }
  if (norm.contains('shop') ||
      norm.contains('cloth') ||
      norm.contains('retail') ||
      norm.contains('store')) {
    return CategoryVisualType.shopping;
  }
  if (norm.contains('transport') ||
      norm.contains('transit') ||
      norm.contains('fuel') ||
      norm.contains('travel') ||
      norm.contains('commute') ||
      norm.contains('vehicle') ||
      norm == 'car' ||
      norm.startsWith('car ') ||
      norm.endsWith(' car')) {
    return CategoryVisualType.transport;
  }
  if (norm.contains('bill') ||
      norm.contains('utilit') ||
      norm.contains('electric') ||
      norm.contains('water') ||
      norm.contains('gas')) {
    return CategoryVisualType.utilities;
  }
  if (norm.contains('entertain') ||
      norm.contains('movie') ||
      norm.contains('stream') ||
      norm.contains('game')) {
    return CategoryVisualType.entertainment;
  }
  return CategoryVisualType.general;
}

/// FinTrack 2.0 Living Category Budget Card.
/// Provides category-specific visual identity, dedicated motion, interactive
/// expand/collapse details, tactile press feedback, and theme consistency.
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
  bool _expanded = false;

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
      begin: const Offset(0.0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: AppMotion.enter,
    ));

    final delayMs = (widget.index * 45).clamp(0, 320);
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

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
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

    final progressRatio = limitNum <= 0 ? 0.0 : (spentNum / limitNum).clamp(0.0, 1.0);

    Color statusColor = colors.primary;
    if (isOver) {
      statusColor = colors.danger;
    } else if (isApproaching) {
      statusColor = colors.warning;
    }

    final catVisual = resolveCategoryVisualType(b.category);
    final catIcon = getCategoryIcon(b.category);
    final catAccentColor = getCategoryColor(b.category);

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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              child: InkWell(
                onTap: _toggleExpand,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    border: Border.all(
                      color: isOver
                          ? colors.danger.withValues(alpha: 0.5)
                          : (isApproaching
                              ? colors.warning.withValues(alpha: 0.5)
                              : colors.cardBorder),
                      width: isOver || isApproaching ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isOver
                                ? colors.danger
                                : (isApproaching
                                    ? colors.warning
                                    : catAccentColor))
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
                        // Card Header Row: Icon, Category Name/Limit, Status Badge, Expand Indicator
                        Row(
                          children: [
                            // Tinted Category Identity Badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: catAccentColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: catAccentColor.withValues(alpha: 0.28),
                                  width: 1,
                                ),
                              ),
                              child: Icon(catIcon, size: 21, color: catAccentColor),
                            ),
                            const SizedBox(width: 12),

                            // Name & Configured Monthly Limit
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
                                    limitNum > 0
                                        ? "Limit: ${widget.currency.format(limitNum)}"
                                        : "Limit: ${widget.currency.format(limitNum)} (Zero Limit)",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Explicit Financial Status Pill (Exact match for test contracts)
                            if (isOver)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.danger.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusXS),
                                  border: Border.all(
                                    color: colors.danger.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.warning.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusXS),
                                  border: Border.all(
                                    color: colors.warning.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.success.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusXS),
                                  border: Border.all(
                                    color: colors.success.withValues(alpha: 0.25),
                                    width: 1,
                                  ),
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
                                    title: Text('Edit Amount',
                                        style: TextStyle(fontSize: 13)),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline_rounded,
                                        color: colors.danger, size: 18),
                                    title: Text('Delete',
                                        style: TextStyle(
                                            color: colors.danger, fontSize: 13)),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Distinct Living Category Visualization
                        _buildCategoryLivingVisual(
                          catVisual: catVisual,
                          progressRatio: progressRatio,
                          statusColor: statusColor,
                          catColor: catAccentColor,
                          b: b,
                          limitNum: limitNum,
                          spentNum: spentNum,
                          remainingNum: remainingNum,
                          reduceMotion: reduceMotion,
                        ),

                        const SizedBox(height: 10),

                        // Spending & Remaining Metrics Row
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

                        // Utilization % and Projection Summary
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
                            Row(
                              children: [
                                if (b.daysRemaining > 0)
                                  Text(
                                    "${b.daysRemaining} days left",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  _expanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 16,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Animated Expand / Collapse Details
                        AnimatedSize(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeInOut,
                          child: _expanded
                              ? _buildExpandedDetails(
                                  colors: colors,
                                  spentNum: spentNum,
                                  limitNum: limitNum,
                                  remainingNum: remainingNum,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds category-specific living progress visuals.
  Widget _buildCategoryLivingVisual({
    required CategoryVisualType catVisual,
    required double progressRatio,
    required Color statusColor,
    required Color catColor,
    required BudgetCategoryProgressModel b,
    required double limitNum,
    required double spentNum,
    required double remainingNum,
    required bool reduceMotion,
  }) {
    switch (catVisual) {
      case CategoryVisualType.food:
        return _FoodCircularGauge(
          progress: progressRatio,
          color: statusColor,
          accentColor: catColor,
          remainingAmount: widget.currency.format(remainingNum),
          reduceMotion: reduceMotion,
        );
      case CategoryVisualType.shopping:
        return _ShoppingGauge(
          progress: progressRatio,
          color: statusColor,
          accentColor: catColor,
          spentAmount: widget.currency.format(spentNum),
          reduceMotion: reduceMotion,
        );
      case CategoryVisualType.transport:
        return _TransportRoute(
          progress: progressRatio,
          color: statusColor,
          accentColor: catColor,
          remainingAmount: widget.currency.format(remainingNum),
          reduceMotion: reduceMotion,
        );
      case CategoryVisualType.healthcare:
        return _HealthcarePulse(
          progress: progressRatio,
          color: statusColor,
          accentColor: catColor,
          status: b.status,
          reduceMotion: reduceMotion,
        );
      case CategoryVisualType.utilities:
        return _UtilitiesSegmented(
          progress: progressRatio,
          color: statusColor,
          accentColor: catColor,
          spentAmount: widget.currency.format(spentNum),
          limitAmount: widget.currency.format(limitNum),
          reduceMotion: reduceMotion,
        );
      case CategoryVisualType.entertainment:
        return _EntertainmentRadial(
          progress: progressRatio,
          color: statusColor,
          accentColor: catColor,
          utilization: b.utilizationPercentage,
          reduceMotion: reduceMotion,
        );
      case CategoryVisualType.general:
        return _GeneralProgressTrack(
          progress: progressRatio,
          color: statusColor,
          reduceMotion: reduceMotion,
        );
    }
  }

  /// Builds additional financial insights in the expanded state.
  Widget _buildExpandedDetails({
    required dynamic colors,
    required double spentNum,
    required double limitNum,
    required double remainingNum,
  }) {
    final b = widget.budget;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 14, color: colors.secondary),
              const SizedBox(width: 6),
              Text(
                "Category Spending Insights",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Projected EOM Spend:",
                  style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              Text("₹${b.projectedSpending}",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Budget Utilization:",
                  style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              Text("${b.utilizationPercentage}%",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Days Remaining in Period:",
                  style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              Text("${b.daysRemaining} days",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text("Edit Limit", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 14, color: colors.danger),
                  label: Text("Delete",
                      style: TextStyle(fontSize: 12, color: colors.danger)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.danger,
                    side: BorderSide(color: colors.danger.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Distinct Category Visual Components & Micro-Motions
// ============================================================================

/// 1. Food & Dining: Circular Spending Gauge with gentle filling motion
class _FoodCircularGauge extends StatelessWidget {
  const _FoodCircularGauge({
    required this.progress,
    required this.color,
    required this.accentColor,
    required this.remainingAmount,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final Color accentColor;
  final String remainingAmount;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.enter,
      builder: (context, animatedProgress, _) {
        return Row(
          children: [
            // Circular Ring Gauge
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: animatedProgress,
                    strokeWidth: 4.5,
                    backgroundColor: colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.08),
                    ),
                    child: Center(
                      child: Text(
                        "${(animatedProgress * 100).toInt()}%",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Dining context & allowance highlight
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_menu_rounded,
                          size: 13, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        "Dining Allowance",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "$remainingAmount left for meals",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 2. Shopping: Horizontal Spending Gauge with sliding bag marker
class _ShoppingGauge extends StatelessWidget {
  const _ShoppingGauge({
    required this.progress,
    required this.color,
    required this.accentColor,
    required this.spentAmount,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final Color accentColor;
  final String spentAmount;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.enter,
      builder: (context, animatedProgress, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 13, color: colors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      "Retail Spending Gauge",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Used: ${(animatedProgress * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Track with subtle notch marks
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Filled progress
                FractionallySizedBox(
                  widthFactor: animatedProgress.clamp(0.01, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 3. Transport: Route-inspired progress track with transit motion
class _TransportRoute extends StatelessWidget {
  const _TransportRoute({
    required this.progress,
    required this.color,
    required this.accentColor,
    required this.remainingAmount,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final Color accentColor;
  final String remainingAmount;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.enter,
      builder: (context, animatedProgress, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.route_rounded, size: 13, color: colors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      "Commute Route Track",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  "$remainingAmount left",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: animatedProgress,
                      minHeight: 6,
                      color: color,
                      backgroundColor: colors.divider,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: animatedProgress >= 1.0 ? color : colors.textSecondary,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// 4. Healthcare: Heartbeat/pulse identity with calm status presentation
class _HealthcarePulse extends StatelessWidget {
  const _HealthcarePulse({
    required this.progress,
    required this.color,
    required this.accentColor,
    required this.status,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final Color accentColor;
  final String status;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    String vitalStatus = "Vitals: Healthy Range";
    if (status == "exceeded") {
      vitalStatus = "Vitals: Limit Exceeded";
    } else if (status == "approaching_limit") {
      vitalStatus = "Vitals: Care Advisory";
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.enter,
      builder: (context, animatedProgress, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_heart_outlined,
                        size: 14, color: color),
                    const SizedBox(width: 5),
                    Text(
                      vitalStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${(animatedProgress * 100).toInt()}% utilized",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: animatedProgress,
                minHeight: 7,
                color: color,
                backgroundColor: colors.divider,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 5. Bills & Utilities: Segmented progress indicator
class _UtilitiesSegmented extends StatelessWidget {
  const _UtilitiesSegmented({
    required this.progress,
    required this.color,
    required this.accentColor,
    required this.spentAmount,
    required this.limitAmount,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final Color accentColor;
  final String spentAmount;
  final String limitAmount;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const totalSegments = 5;
    final filledSegments = (progress * totalSegments).clamp(0.0, totalSegments.toDouble());

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: filledSegments),
      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.enter,
      builder: (context, animatedFilled, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 13, color: colors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      "Recurring Billing Segments",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Commitment: $spentAmount",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 5 segmented pill indicators
            Row(
              children: List.generate(totalSegments, (index) {
                final isFilled = animatedFilled >= (index + 1);
                final isPartial =
                    !isFilled && animatedFilled > index && animatedFilled < (index + 1);
                return Expanded(
                  child: Container(
                    height: 8,
                    margin: EdgeInsets.only(right: index < totalSegments - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? color
                          : (isPartial
                              ? color.withValues(alpha: 0.5)
                              : colors.divider),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

/// 6. Entertainment: Radial / Semi-Circular Treatment
class _EntertainmentRadial extends StatelessWidget {
  const _EntertainmentRadial({
    required this.progress,
    required this.color,
    required this.accentColor,
    required this.utilization,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final Color accentColor;
  final String utilization;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.enter,
      builder: (context, animatedProgress, _) {
        return Row(
          children: [
            // Gauge Arc
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: animatedProgress,
                    strokeWidth: 4,
                    backgroundColor: colors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Icon(Icons.movie_filter_rounded, size: 16, color: color),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.theater_comedy_rounded,
                          size: 13, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        "Media & Leisure Arc",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$utilization% of recreational cap consumed",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 7. Other categories: Polished fallback presentation
class _GeneralProgressTrack extends StatelessWidget {
  const _GeneralProgressTrack({
    required this.progress,
    required this.color,
    required this.reduceMotion,
  });

  final double progress;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
      curve: AppMotion.enter,
      builder: (context, animatedProgress, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: animatedProgress,
            minHeight: 7,
            color: color,
            backgroundColor: colors.divider,
          ),
        );
      },
    );
  }
}
