import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool isDestructive;
  final bool showDivider;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.iconBackgroundColor,
    this.isDestructive = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);

    final effectiveIconColor = isDestructive
        ? colors.danger
        : (iconColor ?? colors.primary);

    final effectiveIconBg = iconBackgroundColor ??
        (isDestructive
            ? colors.danger.withValues(alpha: 0.12)
            : colors.primary.withValues(alpha: isDark ? 0.14 : 0.10));

    final titleColor = isDestructive
        ? colors.danger
        : colors.textPrimary;

    final subtitleColor = colors.textSecondary;

    final dividerColor = colors.divider.withValues(alpha: isDark ? 0.6 : 0.8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: effectiveIconColor.withValues(alpha: 0.08),
            highlightColor: effectiveIconColor.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: effectiveIconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: effectiveIconColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: titleColor,
                          ),
                        ),
                        if (subtitleWidget != null) ...[
                          const SizedBox(height: 3),
                          subtitleWidget!,
                        ] else if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (onTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colors.textSecondary.withValues(
                        alpha: isDark ? 0.7 : 0.8,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
            ),
          ),
      ],
    );
  }
}
