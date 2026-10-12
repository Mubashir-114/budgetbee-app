import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/account_model.dart';
import '../../providers/account_provider.dart';

/// Edit Account screen — only permits metadata edits (name, institution,
/// masked last-4).  Financial fields, type, subtype and currency are immutable
/// and displayed read-only per the backend contract.
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
    super.dispose();
  }

  bool get _needsInstitution =>
      _account?.type == 'bank' || _account?.type == 'credit_card';

  Future<void> _submit() async {
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
      Navigator.of(context).pop(true);
    } else {
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
        body: Center(child: CircularProgressIndicator(color: tokens.primary)),
      );
    }
    if (_account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Account')),
        body: const Center(child: Text('Account not found')),
      );
    }

    final account = _account!;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Account')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Immutable fields (read-only) ──────────────────────────────
            _ImmutableSection(account: account, isDark: isDark),
            const SizedBox(height: 20),

            // ── Editable: Display name ────────────────────────────────────
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Account Name *',
                prefixIcon: Icon(Icons.label_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Account name is required';
                }
                if (v.trim().length > 100) return 'Max 100 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Editable: Institution (bank / credit card) ────────────────
            if (_needsInstitution) ...[
              TextFormField(
                controller: _institutionController,
                decoration: const InputDecoration(
                  labelText: 'Institution Name *',
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

            // ── Editable: Masked last 4 (non-cash) ────────────────────────
            if (account.type != 'cash') ...[
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

            // ── Error ─────────────────────────────────────────────────────
            if (_submitError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
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
                    : const Text('Save Changes',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
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
                'Immutable Fields',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Row(
              label: 'Type',
              value: _typeName(account.type),
              isDark: isDark),
          _Row(
              label: 'Opening Amount',
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
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: tokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
