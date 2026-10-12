import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';
import 'widgets/live_account_preview_card.dart';

/// Edit Account screen — only permits metadata edits (name, institution,
/// masked last-4). Financial fields, type, subtype and currency are immutable
/// and displayed read-only per the backend contract.
///
/// Features:
/// - Real-time LiveAccountPreviewCard reflection of edited metadata.
/// - Read-only display of immutable financial values.
/// - Theme consistency and safe-area anchored action bar.
class EditAccountScreen extends StatefulWidget {
  final int accountId;

  const EditAccountScreen({super.key, required this.accountId});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  AccountModel? _account;
  bool _isLoadingAccount = true;
  bool _isSubmitting = false;
  String? _submitError;

  final _displayNameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _maskedLast4Controller = TextEditingController();

  final _displayNameFocus = FocusNode();
  final _institutionFocus = FocusNode();
  final _maskedLast4Focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  void _loadAccount() {
    final provider = context.read<AccountProvider>();
    final account = provider.accounts
        .where((a) => a.id == widget.accountId)
        .firstOrNull;
    if (account != null) {
      _initControllers(account);
    } else {
      // Not cached — schedule a reload
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await provider.loadAccounts();
        if (!mounted) return;
        final loaded = provider.accounts
            .where((a) => a.id == widget.accountId)
            .firstOrNull;
        if (loaded != null) _initControllers(loaded);
        setState(() => _isLoadingAccount = false);
      });
    }
  }

  void _initControllers(AccountModel account) {
    setState(() {
      _account = account;
      _isLoadingAccount = false;
      _displayNameController.text = account.displayName;
      _institutionController.text = account.institutionName ?? '';
      _maskedLast4Controller.text = account.maskedLast4 ?? '';
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _institutionController.dispose();
    _maskedLast4Controller.dispose();

    _displayNameFocus.dispose();
    _institutionFocus.dispose();
    _maskedLast4Focus.dispose();
    super.dispose();
  }

  bool get _needsInstitution =>
      _account?.type == 'bank' || _account?.type == 'credit_card';

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) return;
    if (_isSubmitting || _account == null) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final provider = context.read<AccountProvider>();
    final updated = await provider.updateAccount(
      widget.accountId,
      displayName: _displayNameController.text.trim(),
      institutionName: _needsInstitution
          ? _institutionController.text.trim()
          : null,
      maskedLast4: _maskedLast4Controller.text.isNotEmpty
          ? _maskedLast4Controller.text.trim()
          : null,
    );

    if (!mounted) return;
    if (updated != null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('${updated.displayName} updated successfully')),
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
        _submitError = provider.actionError ?? 'Failed to update account';
      });
      provider.resetActionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = AppColors.of(context);

    if (_isLoadingAccount) {
      return Scaffold(
        backgroundColor: tokens.background,
        body: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }
    if (_account == null) {
      return Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(title: const Text('Edit Account')),
        body: const Center(child: Text('Account not found')),
      );
    }

    final account = _account!;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'METADATA CONFIGURATION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: tokens.primary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // ── Live Account Preview ──────────────────────────────────
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        _displayNameController,
                        _institutionController,
                        _maskedLast4Controller,
                      ]),
                      builder: (context, _) {
                        return LiveAccountPreviewCard(
                          type: account.type,
                          subtype: account.subtype,
                          displayName: _displayNameController.text,
                          institutionName: _institutionController.text,
                          maskedLast4: _maskedLast4Controller.text,
                          openingAmount: account.openingAmount,
                          creditLimit: account.creditLimit,
                          currencyCode: account.currencyCode,
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Immutable fields notice ───────────────────────────────
                    _ImmutableSection(account: account, isDark: isDark),
                    const SizedBox(height: 20),

                    // ── Editable: Display name ────────────────────────────────
                    Text(
                      'Account Metadata',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: tokens.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _displayNameController,
                      focusNode: _displayNameFocus,
                      decoration: const InputDecoration(
                        labelText: 'Account Name *',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: _needsInstitution
                          ? TextInputAction.next
                          : (account.type != 'cash'
                              ? TextInputAction.next
                              : TextInputAction.done),
                      onFieldSubmitted: (_) {
                        if (_needsInstitution) {
                          _institutionFocus.requestFocus();
                        } else if (account.type != 'cash') {
                          _maskedLast4Focus.requestFocus();
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Account name is required';
                        }
                        if (v.trim().length > 100) return 'Max 100 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Editable: Institution (bank / credit card) ────────────
                    if (_needsInstitution) ...[
                      TextFormField(
                        controller: _institutionController,
                        focusNode: _institutionFocus,
                        decoration: const InputDecoration(
                          labelText: 'Institution Name *',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _maskedLast4Focus.requestFocus(),
                        validator: (v) {
                          if (!_needsInstitution) return null;
                          if (v == null || v.trim().isEmpty) {
                            return 'Institution name is required';
                          }
                          if (v.trim().length > 100) return 'Max 100 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Editable: Masked last 4 (non-cash) ────────────────────
                    if (account.type != 'cash') ...[
                      TextFormField(
                        controller: _maskedLast4Controller,
                        focusNode: _maskedLast4Focus,
                        decoration: const InputDecoration(
                          labelText: 'Last 4 Digits (Optional)',
                          hintText: '1234',
                          prefixIcon: Icon(Icons.pin_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          if (v.length != 4) return 'Must be exactly 4 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Error Banner ──────────────────────────────────────────
                    if (_submitError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: tokens.danger.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMD),
                          border: Border.all(
                            color: tokens.danger.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: tokens.danger, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _submitError!,
                                style:
                                    TextStyle(color: tokens.danger, fontSize: 13),
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

            // ── Sticky Bottom Action Bar ────────────────────────────────────
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
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: tokens.primary,
                    foregroundColor:
                        isDark ? const Color(0xFF171B24) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMD),
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
                          'Save Changes',
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
    );
  }
}

// ── Immutable info card ────────────────────────────────────────────────────

class _ImmutableSection extends StatelessWidget {
  final AccountModel account;
  final bool isDark;

  const _ImmutableSection({required this.account, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.warning.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: tokens.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 14, color: tokens.warning),
              const SizedBox(width: 6),
              Text(
                'Financial Accounting Rules · Read Only',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Row(
              label: 'Account Type',
              value: _typeName(account.type),
              isDark: isDark),
          _Row(
              label: account.type == 'credit_card'
                  ? 'Opening Debt'
                  : 'Opening Balance',
              value: '₹${account.openingAmount}',
              isDark: isDark),
          _Row(
              label: 'Currency',
              value: account.currencyCode,
              isDark: isDark),
          if (account.creditLimit != null)
            _Row(
                label: 'Credit Limit',
                value: '₹${account.creditLimit}',
                isDark: isDark),
        ],
      ),
    );
  }

  String _typeName(String type) {
    switch (type) {
      case 'bank':
        return 'Bank Account';
      case 'cash':
        return 'Cash';
      case 'wallet':
        return 'Digital Wallet';
      case 'credit_card':
        return 'Credit Card';
      default:
        return type;
    }
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _Row({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
