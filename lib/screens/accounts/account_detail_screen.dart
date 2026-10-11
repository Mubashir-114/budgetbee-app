import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/account_model.dart';
import '../../models/account_balance_model.dart';
import '../../models/account_activity_model.dart';
import '../../providers/account_provider.dart';
import 'widgets/account_icon.dart';
import 'widgets/money_text.dart';

class AccountDetailScreen extends StatefulWidget {
  final int accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  AccountModel? _account;
  AccountBalanceModel? _balance;
  List<AccountActivityModel> _activities = [];
  bool _isLoading = true;
  bool _loadingLedger = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final provider = context.read<AccountProvider>();
    final cached = provider.accounts.where((a) => a.id == widget.accountId).firstOrNull;
    if (cached != null) {
      setState(() {
        _account = cached;
        _isLoading = false;
      });
      _loadLedgerData();
      return;
    }
    try {
      await provider.loadAccounts();
      if (!mounted) return;
      final response = provider.accounts
          .where((a) => a.id == widget.accountId)
          .firstOrNull;
      if (response == null) {
        setState(() {
          _error = 'Account not found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _account = response;
          _isLoading = false;
        });
        _loadLedgerData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLedgerData() async {
    setState(() => _loadingLedger = true);
    final provider = context.read<AccountProvider>();
    final balFuture = provider.getAccountBalance(widget.accountId);
    final actFuture = provider.getAccountActivity(widget.accountId);
    final results = await Future.wait([balFuture, actFuture]);
    if (!mounted) return;
    setState(() {
      _balance = results[0] as AccountBalanceModel?;
      _activities = (results[1] as AccountActivityListResponse?)?.activities ?? [];
      _loadingLedger = false;
    });
  }

  Future<void> _showAdjustBalanceDialog() async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    bool isCredit = true;
    final adjustDate = DateTime.now();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Adjust Balance'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record an auditable correction or reconciliation entry.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('+ Inflow'),
                              selected: isCredit,
                              onSelected: (val) => setDialogState(() => isCredit = true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('- Outflow'),
                              selected: !isCredit,
                              onSelected: (val) => setDialogState(() => isCredit = false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount (${_account?.currencyCode ?? 'INR'})',
                          hintText: '0.00',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Enter amount';
                          final n = double.tryParse(val.trim());
                          if (n == null || n <= 0) return 'Enter valid positive number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason / Memo',
                          hintText: 'e.g. Reconciliation discrepancy',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Reason is required';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      final sign = isCredit ? '' : '-';
      final formattedAmount = '$sign${amountController.text.trim()}';
      final clientKey = 'adj_${DateTime.now().millisecondsSinceEpoch}_${widget.accountId}';
      final dateStr = adjustDate.toIso8601String().substring(0, 10);

      final provider = context.read<AccountProvider>();
      final ok = await provider.createAdjustment(
        widget.accountId,
        amount: formattedAmount,
        reason: reasonController.text.trim(),
        adjustmentDate: dateStr,
        clientAdjustmentKey: clientKey,
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Balance adjusted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadAccount();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.actionError ?? 'Adjustment failed'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
    amountController.dispose();
    reasonController.dispose();
  }

  Future<void> _setDefault() async {
    final provider = context.read<AccountProvider>();
    final ok = await provider.setDefault(widget.accountId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Default account updated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      _loadAccount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.actionError ?? 'Failed to set default'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
    provider.resetActionStatus();
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Account'),
        content: const Text(
          'Archived accounts are kept for history but hidden from active lists. '
          'This cannot be undone from the app.\n\nContinue?',
        ),
        actions: [
          TextButton(
              onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => ctx.pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<AccountProvider>();
    final ok = await provider.archiveAccount(widget.accountId);
    if (!mounted) return;
    if (ok) {
      context.pop(); // Return to list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.actionError ?? 'Failed to archive'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
    provider.resetActionStatus();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_error != null || _account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account Details')),
        body: Center(
          child: Text(_error ?? 'Account not found',
              style: const TextStyle(color: AppColors.danger)),
        ),
      );
    }

    final account = _account!;
    final isCredit = account.type == 'credit_card';
    final accentColor = isCredit ? AppColors.danger : AppColors.primary;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
          if (account.isActive)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/accounts/${account.id}/edit').then((_) => _loadAccount());
                } else if (value == 'default') {
                  _setDefault();
                } else if (value == 'archive') {
                  _archive();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 12),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (!isCredit && !account.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 18,
                            color: AppColors.warning),
                        SizedBox(width: 12),
                        Text('Set as Default'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_rounded, size: 18,
                          color: AppColors.danger),
                      SizedBox(width: 12),
                      Text('Archive',
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            _HeaderCard(
              account: account,
              currentBalance: _balance?.currentBalance,
              availableCredit: _balance?.availableCredit,
              accentColor: accentColor,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Quick Actions
            if (account.isActive) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text('Transfer'),
                      onPressed: () {
                        context
                            .push('/accounts/transfer?sourceId=${account.id}')
                            .then((_) => _loadAccount());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Adjust Balance'),
                      onPressed: _showAdjustBalanceDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Metadata card
            _InfoCard(
              title: 'Account Details',
              isDark: isDark,
              children: [
                _InfoRow(label: 'Type', value: _typeLabel(account.type)),
                _InfoRow(label: 'Subtype', value: _subtypeLabel(account.subtype)),
                _InfoRow(label: 'Currency', value: account.currencyCode),
                if (account.institutionName != null)
                  _InfoRow(
                      label: 'Institution', value: account.institutionName!),
                if (account.maskedLast4 != null)
                  _InfoRow(
                      label: 'Account No.',
                      value: '••••${account.maskedLast4}'),
                _InfoRow(
                  label: 'Status',
                  value: account.status[0].toUpperCase() +
                      account.status.substring(1),
                  valueColor:
                      account.isActive ? AppColors.success : AppColors.danger,
                ),
                _InfoRow(
                  label: 'Default Account',
                  value: account.isDefault ? 'Yes' : 'No',
                  valueColor: account.isDefault ? AppColors.primary : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial card
            _InfoCard(
              title: 'Financial Info',
              isDark: isDark,
              children: [
                _MoneyRow(
                  label: 'Current Ledger Balance',
                  decimalString: _balance?.currentBalance ?? account.openingAmount,
                  currencyCode: account.currencyCode,
                  isDark: isDark,
                ),
                _MoneyRow(
                  label: 'Opening Amount',
                  decimalString: account.openingAmount,
                  currencyCode: account.currencyCode,
                  note: isCredit ? 'Immutable' : null,
                  isDark: isDark,
                ),
                if (_balance != null) ...[
                  _MoneyRow(
                    label: 'Total Inflow (Income)',
                    decimalString: _balance!.totalIncome,
                    currencyCode: account.currencyCode,
                    isDark: isDark,
                  ),
                  _MoneyRow(
                    label: 'Total Outflow (Expenses)',
                    decimalString: _balance!.totalExpense,
                    currencyCode: account.currencyCode,
                    isDark: isDark,
                  ),
                  _MoneyRow(
                    label: 'Transfers In',
                    decimalString: _balance!.transfersIn,
                    currencyCode: account.currencyCode,
                    isDark: isDark,
                  ),
                  _MoneyRow(
                    label: 'Transfers Out',
                    decimalString: _balance!.transfersOut,
                    currencyCode: account.currencyCode,
                    isDark: isDark,
                  ),
                  _MoneyRow(
                    label: 'Net Adjustments',
                    decimalString: _balance!.totalAdjustments,
                    currencyCode: account.currencyCode,
                    isDark: isDark,
                  ),
                ],
                if (account.creditLimit != null)
                  _MoneyRow(
                    label: 'Credit Limit',
                    decimalString: account.creditLimit!,
                    currencyCode: account.currencyCode,
                    note: 'Immutable',
                    isDark: isDark,
                  ),
                if (_balance?.availableCredit != null)
                  _MoneyRow(
                    label: 'Available Credit',
                    decimalString: _balance!.availableCredit!,
                    currencyCode: account.currencyCode,
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Activity Feed
            _ActivityFeedCard(
              activities: _activities,
              currencyCode: account.currencyCode,
              isLoading: _loadingLedger,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Archive button
            if (account.isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _archive,
                  icon: const Icon(Icons.archive_rounded),
                  label: const Text('Archive Account'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
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

  String _subtypeLabel(String subtype) {
    switch (subtype) {
      case 'savings':
        return 'Savings';
      case 'current':
        return 'Current';
      case 'salary':
        return 'Salary';
      case 'stored_value':
        return 'Stored Value';
      case 'credit_card':
        return 'Credit Card';
      case 'cash':
        return 'Cash';
      default:
        return subtype;
    }
  }
}

// ── Internal sub-widgets ───────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final AccountModel account;
  final String? currentBalance;
  final String? availableCredit;
  final Color accentColor;
  final bool isDark;

  const _HeaderCard({
    required this.account,
    this.currentBalance,
    this.availableCredit,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: isDark ? 0.25 : 0.1),
            accentColor.withValues(alpha: isDark ? 0.12 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccountIcon(
                type: account.type,
                subtype: account.subtype,
                size: 52,
                accentColor: accentColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (account.institutionName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        account.institutionName!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (account.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Default',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(
            'Current Balance',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          MoneyText(
            decimalString: currentBalance ?? account.openingAmount,
            currencyCode: account.currencyCode,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
          ),
          if (availableCredit != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Available Credit: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  '${account.currencyCode} $availableCredit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  final String label;
  final String decimalString;
  final String currencyCode;
  final String? note;
  final bool isDark;

  const _MoneyRow({
    required this.label,
    required this.decimalString,
    required this.currencyCode,
    this.note,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          MoneyText(
            decimalString: decimalString,
            currencyCode: currencyCode,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActivityFeedCard extends StatelessWidget {
  final List<AccountActivityModel> activities;
  final String currencyCode;
  final bool isLoading;
  final bool isDark;

  const _ActivityFeedCard({
    required this.activities,
    required this.currencyCode,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Activity',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const Divider(height: 24, indent: 16, endIndent: 16),
          if (activities.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: Text(
                  'No activity recorded for this account',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (context, index) {
                final item = activities[index];
                final isPositive = item.isIncomeOrInflow;
                final color =
                    isPositive ? AppColors.success : AppColors.danger;
                final sign = isPositive ? '+' : '-';

                IconData icon;
                if (item.activityType == 'transfer') {
                  icon = Icons.swap_horiz_rounded;
                } else if (item.activityType == 'adjustment') {
                  icon = Icons.tune_rounded;
                } else if (item.type == 'income') {
                  icon = Icons.arrow_downward_rounded;
                } else {
                  icon = Icons.arrow_upward_rounded;
                }

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    '${item.date}${item.note != null && item.note!.isNotEmpty ? ' • ${item.note}' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Text(
                    '$sign$currencyCode ${item.amount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

