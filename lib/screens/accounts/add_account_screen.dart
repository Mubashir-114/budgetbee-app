import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/theme/fin_track_theme_tokens.dart';
import '../../providers/account_provider.dart';
import 'widgets/account_default_settings_card.dart';
import 'widgets/animated_account_type_selector.dart';
import 'widgets/bank_subtype_selector.dart';
import 'widgets/live_account_preview_card.dart';

/// FinTrack 2.0 — Premium Animated Account Creation Screen.
///
/// Features:
/// - Real-time animated account-type selector (Bank, Cash, Digital Wallet, Credit Card).
/// - Dynamic subtype selector for bank accounts (Savings, Current, Salary).
/// - The Living Account preview card updating in real-time as the user inputs details.
/// - Contextual form fields with smooth animated transitions.
/// - Exact decimal money validation with overdraft-aware rules.
/// - Default account controls with asset/liability discrimination.
/// - Sticky primary action bar respecting SafeArea and system insets without overlapping.
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Type & subtype selection
  String _type = 'bank';
  String _subtype = 'savings';

  // Form controllers
  final _displayNameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _maskedLast4Controller = TextEditingController();
  final _openingAmountController = TextEditingController(text: '0.00');
  final _creditLimitController = TextEditingController();
  final _statementClosingDayController = TextEditingController();
  final _paymentDueDayController = TextEditingController();

  // Focus nodes for keyboard navigation
  final _displayNameFocus = FocusNode();
  final _institutionFocus = FocusNode();
  final _maskedLast4Focus = FocusNode();
  final _openingAmountFocus = FocusNode();
  final _creditLimitFocus = FocusNode();

  bool _isDefault = false;
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void dispose() {
    _displayNameController.dispose();
    _institutionController.dispose();
    _maskedLast4Controller.dispose();
    _openingAmountController.dispose();
    _creditLimitController.dispose();
    _statementClosingDayController.dispose();
    _paymentDueDayController.dispose();

    _displayNameFocus.dispose();
    _institutionFocus.dispose();
    _maskedLast4Focus.dispose();
    _openingAmountFocus.dispose();
    _creditLimitFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      switch (newType) {
        case 'bank':
          _subtype = 'savings';
          break;
        case 'cash':
          _subtype = 'cash';
          break;
        case 'wallet':
          _subtype = 'stored_value';
          break;
        case 'credit_card':
          _subtype = 'credit_card';
          _isDefault = false; // Credit cards cannot be default asset accounts
          break;
      }
      _submitError = null;
    });
  }

  void _onSubtypeChanged(String newSubtype) {
    if (_subtype == newSubtype) return;
    setState(() {
      _subtype = newSubtype;
      _submitError = null;
    });
  }

  bool get _needsInstitution => _type == 'bank' || _type == 'credit_card';
  bool get _isCash => _type == 'cash';
  bool get _isCredit => _type == 'credit_card';
  bool get _isWallet => _type == 'wallet';

  String? _validateDecimal(String? value, {bool required = true, bool allowNegative = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Amount is required' : null;
    }
    final trimmed = value.trim();
    final pattern = RegExp(r'^-?\d+(\.\d{1,2})?$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Enter a valid decimal amount (e.g. 1000.00)';
    }
    if (!allowNegative && trimmed.startsWith('-')) {
      return 'Negative amounts are not allowed for this account type';
    }
    return null;
  }

  String _generateCreationKey() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _submit() async {
    // Clear keyboard focus before validation
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      HapticFeedback.vibrate();
      return;
    }
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final provider = context.read<AccountProvider>();

    // Prepare fields adhering strictly to backend contracts
    final String? institution = _isCash
        ? null
        : (_institutionController.text.trim().isNotEmpty
            ? _institutionController.text.trim()
            : null);

    final String? maskedDigits = _isCash
        ? null
        : (_maskedLast4Controller.text.trim().isNotEmpty
            ? _maskedLast4Controller.text.trim()
            : null);

    final String? creditLimit = _isCredit && _creditLimitController.text.trim().isNotEmpty
        ? _creditLimitController.text.trim()
        : null;

    final account = await provider.createAccount(
      type: _type,
      subtype: _subtype,
      displayName: _displayNameController.text.trim(),
      institutionName: institution,
      maskedLast4: maskedDigits,
      openingAmount: _openingAmountController.text.trim(),
      creditLimit: creditLimit,
      isDefault: _isCredit ? false : _isDefault,
      clientCreationKey: _generateCreationKey(),
    );

    if (!mounted) return;

    if (account != null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('${account.displayName} created successfully')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _isSubmitting = false;
        _submitError = provider.actionError ?? 'Failed to create account. Please check your inputs.';
      });
      provider.resetActionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accountProvider = context.watch<AccountProvider>();
    final hasDefault = accountProvider.defaultAccount != null;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'FINTRACK 2.0 · LIVING ACCOUNT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: tokens.primary,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Scrollable form body
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. Account Classification ───────────────────────
                        _SectionHeader(
                          title: 'Account Classification',
                          step: '1 of 3',
                          tokens: tokens,
                        ),
                        const SizedBox(height: 10),
                        AnimatedAccountTypeSelector(
                          selectedType: _type,
                          onTypeChanged: _onTypeChanged,
                        ),
                        const SizedBox(height: 14),

                        // Bank Subtype Selector (contextual)
                        AnimatedSize(
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          curve: Curves.easeInOutCubic,
                          child: _type == 'bank'
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bank Account Subtype',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: tokens.textSecondary,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    BankSubtypeSelector(
                                      selectedSubtype: _subtype,
                                      onSubtypeChanged: _onSubtypeChanged,
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),

                        // ── 2. Live Account Preview ─────────────────────────
                        _SectionHeader(
                          title: 'Live Account Preview',
                          badge: 'INTERACTIVE',
                          tokens: tokens,
                        ),
                        const SizedBox(height: 10),
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            _displayNameController,
                            _institutionController,
                            _maskedLast4Controller,
                            _openingAmountController,
                            _creditLimitController,
                          ]),
                          builder: (context, _) {
                            return LiveAccountPreviewCard(
                              type: _type,
                              subtype: _subtype,
                              displayName: _displayNameController.text,
                              institutionName: _institutionController.text,
                              maskedLast4: _maskedLast4Controller.text,
                              openingAmount: _openingAmountController.text,
                              creditLimit: _creditLimitController.text,
                              currencyCode: 'INR',
                            );
                          },
                        ),
                        const SizedBox(height: 22),

                        // ── 3. Account Configuration Details ────────────────
                        _SectionHeader(
                          title: 'Account Details',
                          step: '2 of 3',
                          tokens: tokens,
                        ),
                        const SizedBox(height: 12),

                        // Display Name
                        TextFormField(
                          controller: _displayNameController,
                          focusNode: _displayNameFocus,
                          decoration: InputDecoration(
                            labelText: 'Account Name *',
                            hintText: _type == 'bank'
                                ? 'e.g. HDFC Salary Account'
                                : (_type == 'credit_card'
                                    ? 'e.g. Amazon Pay ICICI Card'
                                    : 'e.g. Daily Cash Reserve'),
                            prefixIcon: const Icon(Icons.label_rounded),
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: _needsInstitution
                              ? TextInputAction.next
                              : TextInputAction.next,
                          onFieldSubmitted: (_) {
                            if (_needsInstitution) {
                              _institutionFocus.requestFocus();
                            } else if (!_isCash) {
                              _maskedLast4Focus.requestFocus();
                            } else {
                              _openingAmountFocus.requestFocus();
                            }
                          },
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Account name is required';
                            }
                            if (v.trim().length > 100) {
                              return 'Maximum 100 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Institution Name (Contextual: Required for bank & credit_card, optional for wallet)
                        AnimatedSize(
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          curve: Curves.easeInOutCubic,
                          child: !_isCash
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    controller: _institutionController,
                                    focusNode: _institutionFocus,
                                    decoration: InputDecoration(
                                      labelText: _needsInstitution
                                          ? 'Institution Name *'
                                          : 'Provider / Service (Optional)',
                                      hintText: _isCredit
                                          ? 'e.g. ICICI Bank / HDFC'
                                          : (_isWallet
                                              ? 'e.g. Paytm / Amazon Pay'
                                              : 'e.g. State Bank of India'),
                                      prefixIcon: const Icon(Icons.business_rounded),
                                    ),
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        _maskedLast4Focus.requestFocus(),
                                    validator: (v) {
                                      if (_needsInstitution) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Institution name is required';
                                        }
                                        if (v.trim().length > 100) {
                                          return 'Maximum 100 characters';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Masked Last 4 Digits (Contextual: non-cash)
                        AnimatedSize(
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          curve: Curves.easeInOutCubic,
                          child: !_isCash
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    controller: _maskedLast4Controller,
                                    focusNode: _maskedLast4Focus,
                                    decoration: const InputDecoration(
                                      labelText: 'Last 4 Digits (Optional)',
                                      hintText: '1234',
                                      prefixIcon: Icon(Icons.pin_rounded),
                                      helperText: 'For recognizable card or account masking',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    onFieldSubmitted: (_) =>
                                        _openingAmountFocus.requestFocus(),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return null;
                                      if (v.length != 4) {
                                        return 'Must be exactly 4 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // Opening Amount (Financial hierarchy)
                        TextFormField(
                          controller: _openingAmountController,
                          focusNode: _openingAmountFocus,
                          decoration: InputDecoration(
                            labelText: _isCredit
                                ? 'Opening Statement Debt *'
                                : 'Opening Balance *',
                            hintText: '0.00',
                            prefixText: '₹ ',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded),
                            helperText: _type == 'bank' && _subtype == 'current'
                                ? 'Negative amounts allowed for current accounts (overdraft)'
                                : (_isCredit
                                    ? 'Enter statement balance / debt. Enter 0.00 if fresh card.'
                                    : 'Initial cleared funds on this account'),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                            signed: _type == 'bank' && _subtype == 'current',
                          ),
                          textInputAction: _isCredit
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (_isCredit) _creditLimitFocus.requestFocus();
                          },
                          validator: (v) => _validateDecimal(
                            v,
                            required: true,
                            allowNegative: _type == 'bank' && _subtype == 'current',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Credit Limit (Contextual: Credit Card only)
                        AnimatedSize(
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          curve: Curves.easeInOutCubic,
                          child: _isCredit
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: TextFormField(
                                    controller: _creditLimitController,
                                    focusNode: _creditLimitFocus,
                                    decoration: const InputDecoration(
                                      labelText: 'Credit Limit *',
                                      hintText: '100000.00',
                                      prefixText: '₹ ',
                                      prefixIcon: Icon(Icons.credit_score_rounded),
                                      helperText: 'Total revolving credit approved by card issuer',
                                    ),
                                    keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    validator: (v) {
                                      final err = _validateDecimal(
                                        v,
                                        required: true,
                                        allowNegative: false,
                                      );
                                      if (err != null) return err;
                                      final trimmed = v!.trim();
                                      if (trimmed == '0' ||
                                          trimmed == '0.00' ||
                                          trimmed.startsWith('-')) {
                                        return 'Credit limit must be greater than zero';
                                      }
                                      return null;
                                    },
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // ── 4. Account Preferences ──────────────────────────
                        _SectionHeader(
                          title: 'Preferences',
                          step: '3 of 3',
                          tokens: tokens,
                        ),
                        const SizedBox(height: 10),
                        AccountDefaultSettingsCard(
                          isDefault: _isDefault,
                          onChanged: (val) => setState(() => _isDefault = val),
                          isCreditCard: _isCredit,
                          hasExistingDefault: hasDefault,
                        ),
                        const SizedBox(height: 16),

                        // ── Submission Error Banner ─────────────────────────
                        if (_submitError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: tokens.danger.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusMD),
                              border: Border.all(
                                color: tokens.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: tokens.danger, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _submitError!,
                                    style: TextStyle(
                                      color: tokens.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // ── 5. Sticky Bottom Action Bar ───────────────────────────────
              // Resolved bottom navigation & keyboard overlap properly with SafeArea
              Container(
                decoration: BoxDecoration(
                  color: tokens.surface,
                  border: Border(
                    top: BorderSide(
                      color: tokens.divider.withValues(alpha: isDark ? 0.6 : 0.8),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.paddingOf(context).bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: const ValueKey('create_account_button'),
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.primary,
                      foregroundColor: isDark ? const Color(0xFF171B24) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? step;
  final String? badge;
  final FinTrackThemeTokens tokens;

  const _SectionHeader({
    required this.title,
    this.step,
    this.badge,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: tokens.textPrimary,
          ),
        ),
        if (step != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tokens.elevated,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              border: Border.all(color: tokens.divider),
            ),
            child: Text(
              step!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        if (badge != null)
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tokens.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: tokens.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
