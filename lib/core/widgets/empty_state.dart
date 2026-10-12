import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
                border: Border.all(
                  color: colors.divider,
                  width: 1.0,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: colors.primary,
              ),
            ),
            AppDimensions.hLG,
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            AppDimensions.hXS,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
