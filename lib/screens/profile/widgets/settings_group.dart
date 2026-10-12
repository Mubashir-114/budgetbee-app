import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);

    final surfaceColor = colors.surface;
    final borderColor = colors.divider.withValues(alpha: isDark ? 0.7 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
            child: Text(
              title!.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ],
    );
  }
}
