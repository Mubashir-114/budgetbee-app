import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Data representation of an account type option.
class AccountTypeOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const AccountTypeOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Refined, animated account-type selector for FinTrack 2.0.
///
/// Features:
/// - 4 distinct types with contextual icons and micro-copy.
/// - 200–240ms smooth animated selection borders and surface highlights.
/// - Clear active indicator badge with check icon (indicator beyond color alone).
/// - Haptic feedback on tap.
/// - Respects reduced motion preferences.
class AnimatedAccountTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const AnimatedAccountTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  static const List<AccountTypeOption> options = [
    AccountTypeOption(
      key: 'bank',
      title: 'Bank Account',
      subtitle: 'Savings, current & salary',
      icon: Icons.account_balance_rounded,
    ),
    AccountTypeOption(
      key: 'cash',
      title: 'Cash',
      subtitle: 'Physical notes & reserve',
      icon: Icons.payments_rounded,
    ),
    AccountTypeOption(
      key: 'wallet',
      title: 'Digital Wallet',
      subtitle: 'Prepaid & stored value',
      icon: Icons.account_balance_wallet_rounded,
    ),
    AccountTypeOption(
      key: 'credit_card',
      title: 'Credit Card',
      subtitle: 'Revolving line of credit',
      icon: Icons.credit_card_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute optimal column/grid layout for 320–430dp widths
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.62,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            final isSelected = selectedType == option.key;
            return _TypeCard(
              option: option,
              isSelected: isSelected,
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  onTypeChanged(option.key);
                }
              },
            );
          },
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  final AccountTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
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
    final duration = disableAnimations ? Duration.zero : const Duration(milliseconds: 220);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.title}: ${option.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          splashColor: tokens.primary.withValues(alpha: 0.12),
          highlightColor: tokens.primary.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? tokens.primary.withValues(alpha: isDark ? 0.14 : 0.09)
                  : tokens.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: isSelected
                    ? tokens.primary
                    : tokens.divider,
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: tokens.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Icon container + Active check badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: duration,
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tokens.primary.withValues(alpha: 0.22)
                            : tokens.elevated,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: Icon(
                        option.icon,
                        size: 19,
                        color: isSelected ? tokens.primary : tokens.textSecondary,
                      ),
                    ),
                    AnimatedOpacity(
                      duration: duration,
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: tokens.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom: Title & Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? tokens.primary : tokens.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? tokens.textSecondary
                            : tokens.textSecondary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
