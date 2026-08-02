import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class SkeletonLoader extends StatelessWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }

  // Preset for card loaders (like Dashboard balances)
  static Widget card({double height = 120.0}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const ShimmerLoading(width: 80, height: 12),
                const SizedBox(height: 8),
                ShimmerLoading(width: double.infinity, height: height - 60),
              ],
            ),
          ),
        );
      }
    );
  }

  // Preset for list item loaders (Transactions list)
  static Widget listTile() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              const ShimmerLoading(width: 40, height: 40, borderRadius: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoading(width: 120, height: 14),
                    const SizedBox(height: 6),
                    ShimmerLoading(width: 80, height: 10),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const ShimmerLoading(width: 60, height: 14),
            ],
          ),
        );
      }
    );
  }

  // Preset for stats chart loading
  static Widget chart() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Card(
          elevation: 0,
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
          ),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerLoading(width: 100, height: 16),
                    ShimmerLoading(width: 60, height: 16),
                  ],
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerLoading(width: 12, height: 80, borderRadius: 6),
                    ShimmerLoading(width: 12, height: 120, borderRadius: 6),
                    ShimmerLoading(width: 12, height: 60, borderRadius: 6),
                    ShimmerLoading(width: 12, height: 140, borderRadius: 6),
                    ShimmerLoading(width: 12, height: 90, borderRadius: 6),
                  ],
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        );
      }
    );
  }
}
