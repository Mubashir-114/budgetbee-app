import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/account_provider.dart';

/// Add Account form with dynamic fields by account type.
///
/// Generates a client creation key for idempotent submission.
/// Financial amounts are collected and transmitted as exact decimal strings.
class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  // Type/subtype selection
  String _type = 'bank';
  String _subtype = 'savings';

  // Controllers
  final _displayNameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _maskedLast4Controller = TextEditingController();
  final _openingAmountController = TextEditingController(text: '0.00');
  final _creditLimitController = TextEditingController();

  bool _isDefault = false;
  bool _isSubmitting = false;
  String? _submitError;

  static const _types = [
    ('bank', 'Bank Account', Icons.savings_rounded),
    ('cash', 'Cash', Icons.money_rounded),
    ('wallet', 'Digital Wallet', Icons.account_balance_wallet_rounded),
    ('credit_card', 'Credit Card', Icons.credit_card_rounded),
  ];

  static const _bankSubtypes = [
    ('savings', 'Savings'),
    ('current', 'Current'),
    ('salary', 'Salary'),
  ];

  @override
  void dispose() {
    _displayNameController.dispose();
    _institutionController.dispose();
    _maskedLast4Controller.dispose();
    _openingAmountController.dispose();
    _creditLimitController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String type) {
    setState(() {
      _type = type;
      // Reset to valid subtype
      switch (type) {
        case 'bank':
          _subtype = 'savings';
        case 'cash':
          _subtype = 'cash';
        case 'wallet':
          _subtype = 'stored_value';
        case 'credit_card':
          _subtype = 'credit_card';
      }
      _submitError = null;
    });
  }

  bool get _needsInstitution => _type == 'bank' || _type == 'credit_card';
  bool get _isCash => _type == 'cash';
  bool get _isCredit => _type == 'credit_card';

  /// Validates an exact decimal string: digits, optional single dot, ≤2 decimals.
  String? _validateDecimal(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Amount is required' : null;
    }
    final trimmed = value.trim();
    final pattern = RegExp(r'^-?\d+(\.\d{1,2})?$');
    if (!pattern.hasMatch(trimmed)) {
      return 'Enter a valid decimal (e.g. 1000.00)';
    }
    return null;
  }

  String _generateCreationKey() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final provider = context.read<AccountProvider>();
    final account = await provider.createAccount(
      type: _type,
      subtype: _subtype,
      displayName: _displayNameController.text.trim(),
      institutionName:
          _needsInstitution ? _institutionController.text.trim() : null,
      maskedLast4: (!_isCash && _maskedLast4Controller.text.isNotEmpty)
          ? _maskedLast4Controller.text.trim()
          : null,
      openingAmount: _openingAmountController.text.trim(),
      creditLimit: _isCredit ? _creditLimitController.text.trim() : null,
      isDefault: _isDefault,
      clientCreationKey: _generateCreationKey(),
    );

    if (!mounted) return;

    if (account != null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _submitError = provider.actionError ?? 'Failed to create account';
      });
      provider.resetActionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Account')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Type selector ─────────────────────────────────────────────
            Text('Account Type',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            _TypeSelector(
              types: _types,
              selected: _type,
              onChanged: _onTypeChanged,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // ── Bank subtype ──────────────────────────────────────────────
            if (_type == 'bank') ...[
              Text('Account Subtype',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _SubtypeSelector(
                subtypes: _bankSubtypes,
                selected: _subtype,
                onChanged: (v) => setState(() => _subtype = v),
                isDark: isDark,
              ),
              const SizedBox(height: 20),
            ],

            // ── Display name ──────────────────────────────────────────────
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Account Name *',
                hintText: 'e.g. HDFC Savings',
                prefixIcon: Icon(Icons.label_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Account name is required';
                }
                if (v.trim().length > 100) {
                  return 'Max 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Institution (bank / credit card) ──────────────────────────
            if (_needsInstitution) ...[
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Institution Name *',
                  hintText: 'e.g. HDFC Bank',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                validator: (v) {
                  if (!_needsInstitution) return null;
                  if (v == null || v.trim().isEmpty) {
                    return 'Institution name is required';
                  }
                  if (v.trim().length > 100) return 'Max 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Masked last 4 (optional for non-cash) ─────────────────────
            if (!_isCash) ...[
              TextFormField(
                controller: _maskedLast4Controller,
                decoration: const InputDecoration(
                  labelText: 'Last 4 Digits (optional)',
                  hintText: '1234',
                  prefixIcon: Icon(Icons.pin_rounded),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (v.length != 4) return 'Must be exactly 4 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Opening amount ────────────────────────────────────────────
            TextFormField(
              controller: _openingAmountController,
              decoration: InputDecoration(
                labelText: _isCredit
                    ? 'Opening Statement Balance'
                    : 'Opening Amount',
                hintText: '0.00',
                prefixText: '₹ ',
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                helperText: _type == 'bank' && _subtype == 'current'
                    ? 'Negative values allowed for current accounts'
                    : null,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (v) => _validateDecimal(v),
            ),
            const SizedBox(height: 16),

            // ── Credit limit (credit card only) ───────────────────────────
            if (_isCredit) ...[
              TextFormField(
                controller: _creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'Credit Limit *',
                  hintText: '100000.00',
                  prefixText: '₹ ',
                  prefixIcon: Icon(Icons.credit_score_rounded),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final err = _validateDecimal(v, required: true);
                  if (err != null) return err;
                  // Must be positive
                  final trimmed = v!.trim();
                  if (trimmed.startsWith('-') || trimmed == '0' || trimmed == '0.00') {
                    return 'Credit limit must be positive';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // ── Default toggle (assets only) ──────────────────────────────
            if (!_isCredit) ...[
              _DefaultToggle(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                isDark: isDark,
              ),
              const SizedBox(height: 20),
            ],

            // ── Error ─────────────────────────────────────────────────────
            if (_submitError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.danger.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_rounded, color: tokens.danger, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _submitError!,
                        style: TextStyle(color: tokens.danger, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Submit ────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Create Account',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
  }
}

// ── Internal widgets ───────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final List<(String, String, IconData)> types;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _TypeSelector({
    required this.types,
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: types.map((t) {
        final (value, label, icon) = t;
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? tokens.primary.withValues(alpha: 0.12) : tokens.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: isSelected ? tokens.primary : tokens.divider,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon,
                      size: 18,
                      color: isSelected ? tokens.primary : tokens.textSecondary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: isSelected ? tokens.primary : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubtypeSelector extends StatelessWidget {
  final List<(String, String)> subtypes;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _SubtypeSelector({
    required this.subtypes,
    required this.selected,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Row(
      children: subtypes.map((s) {
        final (value, label) = s;
        final isSelected = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => onChanged(value),
              selectedColor: tokens.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? tokens.primary : null,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DefaultToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _DefaultToggle({
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    final theme = Theme.of(context);
    return Material(
      color: tokens.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: tokens.divider,
          ),
        ),
        child: SwitchListTile.adaptive(
          title: const Text('Set as Default Account',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            'The default account is used for transactions by default.',
            style: theme.textTheme.bodySmall,
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: tokens.primary,
        ),
      ),
    );
  }
}
