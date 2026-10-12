import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_motion.dart';

/// Distinctive, animated empty state for FinTrack Budgets.
/// Shows an interactive vector budget-ring illustration, clear onboarding headline,
/// a single primary Create Budget CTA, and an Explore Suggestions action.
/// Eliminates duplicate actions and removes the floating action button when empty.
class BudgetEmptyState extends StatefulWidget {
  const BudgetEmptyState({
    super.key,
    required this.selectedMonthName,
    required this.selectedYear,
    required this.onCreateBudget,
    required this.onExploreSuggestions,
  });

  final String selectedMonthName;
  final int selectedYear;
  final VoidCallback onCreateBudget;
  final VoidCallback onExploreSuggestions;

  @override
  State<BudgetEmptyState> createState() => _BudgetEmptyStateState();
}

class _BudgetEmptyStateState extends State<BudgetEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.reveal,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Vector Budget Ring Illustration
            RepaintBoundary(
              child: SizedBox(
                width: 140,
                height: 140,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _BudgetRingIllustrationPainter(
                        animationValue: _controller.value,
                        primaryColor: colors.primary,
                        secondaryColor: colors.secondary,
                        trackColor: colors.divider,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Headline
            Text(
              "Shape Your Living Budget",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Supporting Explanation
            Text(
              "Set intentional spending limits for ${widget.selectedMonthName} ${widget.selectedYear} to track category pace, or apply deterministic recommendations.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Single Prominent Primary Action
            ElevatedButton.icon(
              onPressed: widget.onCreateBudget,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                "Create Budget",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: isDark ? const Color(0xFF0B111A) : Colors.white,
                minimumSize: const Size(180, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Action
            TextButton.icon(
              onPressed: widget.onExploreSuggestions,
              icon: Icon(Icons.auto_awesome_rounded, size: 16, color: colors.secondary),
              label: Text(
                "Explore Suggestions",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(160, 36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetRingIllustrationPainter extends CustomPainter {
  const _BudgetRingIllustrationPainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trackColor,
    required this.isDark,
  });

  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final Color trackColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Ambient radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.16 : 0.10),
          secondaryColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Background dashed/segmented track
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: isDark ? 0.35 : 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Rotating segment arc
    final rotation = animationValue * math.pi * 2;
    final arcPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: 0.1),
          primaryColor,
          secondaryColor,
        ],
        transform: GradientRotation(rotation),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      rotation,
      math.pi * 1.25,
      false,
      arcPaint,
    );

    // Center circular badge with coin/wallet emblem
    final innerCenterPaint = Paint()
      ..color = primaryColor.withValues(alpha: isDark ? 0.14 : 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.52, innerCenterPaint);

    final innerBorderPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 0.52, innerBorderPaint);

    // Minimalist wallet / coin icon representation
    final coinPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, coinPaint);

    final coinHole = Paint()
      ..color = isDark ? const Color(0xFF171B24) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, coinHole);
  }

  @override
  bool shouldRepaint(_BudgetRingIllustrationPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.isDark != isDark;
  }
}
