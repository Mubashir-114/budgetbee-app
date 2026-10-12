import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class BankSubtypeOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const BankSubtypeOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Refined segmented bank subtype selector for Savings, Current, and Salary accounts.
class BankSubtypeSelector extends StatelessWidget {
  final String selectedSubtype;
  final ValueChanged<String> onSubtypeChanged;

  const BankSubtypeSelector({
    super.key,
    required this.selectedSubtype,
    required this.onSubtypeChanged,
  });

  static const List<BankSubtypeOption> subtypes = [
    BankSubtypeOption(
      key: 'savings',
      title: 'Savings',
      subtitle: 'Daily & Interest',
      icon: Icons.savings_rounded,
    ),
    BankSubtypeOption(
      key: 'current',
      title: 'Current',
      subtitle: 'Overdraft Ready',
      icon: Icons.business_rounded,
    ),
    BankSubtypeOption(
      key: 'salary',
      title: 'Salary',
      subtitle: 'Payroll Account',
      icon: Icons.payments_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: subtypes.map((option) {
        final isSelected = selectedSubtype == option.key;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option.key != subtypes.last.key ? 8.0 : 0.0,
            ),
            child: _SubtypeCard(
              option: option,
              isSelected: isSelected,
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onSubtypeChanged(option.key);
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubtypeCard extends StatelessWidget {
  final BankSubtypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubtypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = disableAnimations ? Duration.zero : const Duration(milliseconds: 200);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.title} bank account',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          splashColor: tokens.primary.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.primary.withValues(alpha: isDark ? 0.16 : 0.10)
                  : tokens.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: isSelected ? tokens.primary : tokens.divider,
                width: isSelected ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option.icon,
                  size: 20,
                  color: isSelected ? tokens.primary : tokens.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? tokens.primary : tokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: tokens.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
