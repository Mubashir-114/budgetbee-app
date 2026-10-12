import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/fin_track_theme_tokens.dart';
import 'money_text.dart';

/// Interactive, animated live account preview card.
///
/// Updates in real-time as the user types form inputs.
/// Adheres strictly to FinTrack financial design rules:
/// - Opening amount is explicitly labeled as **OPENING BALANCE** (for assets)
///   or **OPENING DEBT** (for credit cards), never "Current Balance".
/// - Formats exact decimal strings via [MoneyText] without floating-point math.
/// - Adapts dynamically to Graphite & Champagne, Obsidian & Jade, and Arctic Blue themes.
class LiveAccountPreviewCard extends StatelessWidget {
  final String type; // 'bank' | 'cash' | 'wallet' | 'credit_card'
  final String subtype; // 'savings' | 'current' | 'salary' | 'cash' | 'stored_value' | 'credit_card'
  final String displayName;
  final String? institutionName;
  final String? maskedLast4;
  final String openingAmount;
  final String? creditLimit;
  final String currencyCode;

  const LiveAccountPreviewCard({
    super.key,
    required this.type,
    required this.subtype,
    required this.displayName,
    this.institutionName,
    this.maskedLast4,
    required this.openingAmount,
    this.creditLimit,
    this.currencyCode = 'INR',
  });

  String get _cleanOpeningAmount {
    final trimmed = openingAmount.trim();
    if (trimmed.isEmpty) return '0.00';
    // Validate if it is a formatted decimal or partial
    final pattern = RegExp(r'^-?\d+(\.\d{1,2})?$');
    return pattern.hasMatch(trimmed) ? trimmed : '0.00';
  }

  String get _cleanCreditLimit {
    if (creditLimit == null) return '0.00';
    final trimmed = creditLimit!.trim();
    final pattern = RegExp(r'^\d+(\.\d{1,2})?$');
    return pattern.hasMatch(trimmed) ? trimmed : '0.00';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      label: 'Live preview of $displayName account',
      container: true,
      child: AnimatedSwitcher(
        duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey('$type-$subtype'),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 196),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            gradient: _resolveGradient(tokens, isDark),
            border: Border.all(
              color: _resolveBorderColor(tokens, isDark),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : tokens.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            child: Stack(
              children: [
                // Abstract background accent watermark
                Positioned(
                  right: -24,
                  bottom: -28,
                  child: Opacity(
                    opacity: isDark ? 0.08 : 0.06,
                    child: _WatermarkEmblem(type: type, tokens: tokens),
                  ),
                ),

                // Subtle directional light sheen
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tokens.primary.withValues(alpha: isDark ? 0.06 : 0.04),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // Card content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: _buildCardContent(context, tokens, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _resolveGradient(FinTrackThemeTokens tokens, bool isDark) {
    switch (type) {
      case 'credit_card':
        return LinearGradient(
          colors: isDark
              ? [
                  tokens.elevated,
                  tokens.surface,
                  const Color(0xFF141720),
                ]
              : [
                  const Color(0xFF2B303C),
                  const Color(0xFF1F232D),
                  const Color(0xFF171B24),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'cash':
        return LinearGradient(
          colors: isDark
              ? [
                  tokens.elevated,
                  tokens.surface,
                ]
              : [
                  tokens.surface,
                  tokens.elevated,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'wallet':
        return LinearGradient(
          colors: isDark
              ? [
                  tokens.surface,
                  tokens.background,
                ]
              : [
                  tokens.surface,
                  tokens.elevated,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'bank':
      default:
        return LinearGradient(
          colors: isDark
              ? [
                  tokens.surface,
                  tokens.elevated,
                ]
              : [
                  tokens.surface,
                  tokens.elevated,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _resolveBorderColor(FinTrackThemeTokens tokens, bool isDark) {
    if (type == 'credit_card') {
      return tokens.primary.withValues(alpha: 0.35);
    }
    return tokens.primary.withValues(alpha: isDark ? 0.25 : 0.3);
  }

  Widget _buildCardContent(
    BuildContext context,
    FinTrackThemeTokens tokens,
    bool isDark,
  ) {
    final isCreditCardTheme = type == 'credit_card' && !isDark;
    final textColor = isCreditCardTheme ? Colors.white : tokens.textPrimary;
    final secondaryTextColor =
        isCreditCardTheme ? const Color(0xFFB5AFAB) : tokens.textSecondary;

    switch (type) {
      case 'bank':
        return _buildBankContent(context, tokens, textColor, secondaryTextColor);
      case 'cash':
        return _buildCashContent(context, tokens, textColor, secondaryTextColor);
      case 'wallet':
        return _buildWalletContent(context, tokens, textColor, secondaryTextColor);
      case 'credit_card':
        return _buildCreditCardContent(context, tokens, isCreditCardTheme);
      default:
        return _buildBankContent(context, tokens, textColor, secondaryTextColor);
    }
  }

  // ── 1. Bank Account Preview ────────────────────────────────────────────────
  Widget _buildBankContent(
    BuildContext context,
    FinTrackThemeTokens tokens,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final inst = institutionName?.trim();
    final name = displayName.trim().isEmpty ? 'Primary Bank Account' : displayName.trim();
    final digits = maskedLast4?.trim();
    final subtypeLabel = _bankSubtypeLabel(subtype);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PreviewBadge(
              label: subtypeLabel.toUpperCase(),
              icon: Icons.account_balance_rounded,
              tokens: tokens,
            ),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 4),
                Text(
                  inst != null && inst.isNotEmpty ? inst : 'Institution',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Middle: Display name & Masked account
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              digits != null && digits.isNotEmpty
                  ? '•••• •••• •••• $digits'
                  : '•••• •••• •••• ••••',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                letterSpacing: 1.5,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Bottom row: Opening Balance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPENING BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  decimalString: _cleanOpeningAmount,
                  currencyCode: currencyCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Text(
                currencyCode,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: tokens.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 2. Cash Account Preview ────────────────────────────────────────────────
  Widget _buildCashContent(
    BuildContext context,
    FinTrackThemeTokens tokens,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final name = displayName.trim().isEmpty ? 'Cash Wallet' : displayName.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PreviewBadge(
              label: 'PHYSICAL CASH',
              icon: Icons.payments_rounded,
              tokens: tokens,
            ),
            Text(
              'LIQUID ASSET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: tokens.success,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Direct Cash Reserves · Hand-to-Hand',
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPENING BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  decimalString: _cleanOpeningAmount,
                  currencyCode: currencyCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.account_balance_wallet_rounded,
              color: tokens.primary,
              size: 24,
            ),
          ],
        ),
      ],
    );
  }

  // ── 3. Digital Wallet Preview ──────────────────────────────────────────────
  Widget _buildWalletContent(
    BuildContext context,
    FinTrackThemeTokens tokens,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final inst = institutionName?.trim();
    final name = displayName.trim().isEmpty ? 'Digital Wallet' : displayName.trim();
    final digits = maskedLast4?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PreviewBadge(
              label: 'STORED VALUE',
              icon: Icons.account_balance_wallet_rounded,
              tokens: tokens,
            ),
            Row(
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 16,
                  color: tokens.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  inst != null && inst.isNotEmpty ? inst : 'Prepaid Service',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tokens.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              digits != null && digits.isNotEmpty
                  ? 'WALLET ID: •••• $digits'
                  : 'DIGITAL PREPAID BALANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: secondaryTextColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OPENING BALANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  decimalString: _cleanOpeningAmount,
                  currencyCode: currencyCode,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tokens.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Text(
                'PREPAID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: tokens.info,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 4. Credit Card Preview ────────────────────────────────────────────────
  Widget _buildCreditCardContent(
    BuildContext context,
    FinTrackThemeTokens tokens,
    bool isCreditCardTheme,
  ) {
    final inst = institutionName?.trim();
    final name = displayName.trim().isEmpty ? 'CARDHOLDER' : displayName.trim().toUpperCase();
    final digits = maskedLast4?.trim();
    final primaryColor = tokens.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Top: Issuer + Contactless Wave
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              inst != null && inst.isNotEmpty ? inst.toUpperCase() : 'FINTRACK PLATINUM',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tokens.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Text(
                    'LIABILITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: tokens.danger,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.sensors_rounded,
                  size: 18,
                  color: primaryColor,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // EMV Chip Simulation
        Row(
          children: [
            Container(
              width: 38,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE5C07B), Color(0xFFC99B49), Color(0xFFD4AF37)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF99752A), width: 0.6),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF805F1E), width: 0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 16-Digit Masked Display
        Text(
          digits != null && digits.isNotEmpty
              ? '••••  ••••  ••••  $digits'
              : '••••  ••••  ••••  ••••',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 2.2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),

        // Cardholder Name
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: Color(0xFFE2E8F0),
          ),
        ),
        const SizedBox(height: 12),

        // Bottom row: Opening Debt & Credit Limit
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OPENING DEBT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                MoneyText(
                  decimalString: _cleanOpeningAmount,
                  currencyCode: currencyCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (creditLimit != null && creditLimit!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'CREDIT LIMIT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    decimalString: _cleanCreditLimit,
                    currencyCode: currencyCode,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  String _bankSubtypeLabel(String subtype) {
    switch (subtype) {
      case 'savings':
        return 'Savings Account';
      case 'current':
        return 'Current Account';
      case 'salary':
        return 'Salary Account';
      default:
        return 'Bank Account';
    }
  }
}

class _PreviewBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final FinTrackThemeTokens tokens;

  const _PreviewBadge({
    required this.label,
    required this.icon,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(
          color: tokens.primary.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tokens.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: tokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatermarkEmblem extends StatelessWidget {
  final String type;
  final FinTrackThemeTokens tokens;

  const _WatermarkEmblem({required this.type, required this.tokens});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case 'credit_card':
        icon = Icons.credit_card_rounded;
        break;
      case 'cash':
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'wallet':
        icon = Icons.tap_and_play_rounded;
        break;
      case 'bank':
      default:
        icon = Icons.account_balance_rounded;
        break;
    }
    return Icon(
      icon,
      size: 150,
      color: tokens.primary,
    );
  }
}
