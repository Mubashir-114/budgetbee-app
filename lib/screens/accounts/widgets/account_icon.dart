import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Circular icon that represents an account type visually.
class AccountIcon extends StatelessWidget {
  final String type;
  final String subtype;
  final double size;
  final Color accentColor;

  const AccountIcon({
    super.key,
    required this.type,
    required this.subtype,
    this.size = 44,
    this.accentColor = AppColors.primary,
  });

  IconData get _icon {
    switch (type) {
      case 'bank':
        switch (subtype) {
          case 'salary':
            return Icons.payments_rounded;
          case 'current':
            return Icons.account_balance_rounded;
          default:
            return Icons.savings_rounded;
        }
      case 'cash':
        return Icons.money_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      default:
        return Icons.account_balance_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Icon(
        _icon,
        color: accentColor,
        size: size * 0.48,
      ),
    );
  }
}
