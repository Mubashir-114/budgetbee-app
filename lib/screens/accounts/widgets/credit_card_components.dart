import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/decimal_money.dart';
import '../../../core/widgets/animated_progress_bar.dart';
import '../../../models/credit_card_models.dart';
import '../../../models/transfer_model.dart';
import '../../../providers/account_provider.dart';
import 'money_text.dart';

/// Card displaying credit card balances: debt, limit, available credit and utilization.
class CreditCardSummaryCard extends StatelessWidget {
  final String outstandingDebt;
  final String creditLimit;
  final String availableCredit;
  final String creditBalance;
  final String utilizationPercentage;
  final String currencyCode;
  final bool isDark;

  const CreditCardSummaryCard({
    super.key,
    required this.outstandingDebt,
    required this.creditLimit,
    required this.availableCredit,
    required this.creditBalance,
    required this.utilizationPercentage,
    required this.currencyCode,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDebt = DecimalMoney.isValidDecimal(outstandingDebt) &&
        DecimalMoney.isPositive(outstandingDebt);
    final hasCreditBalance = DecimalMoney.isValidDecimal(creditBalance) &&
        DecimalMoney.isPositive(creditBalance);

    // Compute progress bar fill between 0.0 and 1.0 solely for UI bar rendering
    double progress = 0.0;
    try {
      final cleanUtil = utilizationPercentage.replaceAll('%', '').trim();
      final parsed = double.tryParse(cleanUtil) ?? 0.0;
      progress = (parsed / 100.0).clamp(0.0, 1.0);
    } catch (_) {}

    final utilColor = progress > 0.7
        ? AppColors.of(context).danger
        : (progress > 0.3 ? AppColors.of(context).warning : AppColors.of(context).success);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Credit Card Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: utilColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Text(
                  '$utilizationPercentage Utilized',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: utilColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Outstanding debt
          Text(
            'Current Outstanding Debt',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.of(context).textSecondary
                  : AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          MoneyText(
            decimalString: outstandingDebt,
            currencyCode: currencyCode,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: hasDebt ? AppColors.of(context).danger : AppColors.of(context).success,
            ),
          ),

          if (hasCreditBalance) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 14, color: AppColors.of(context).success),
                const SizedBox(width: 4),
                Text(
                  'Credit balance (overpayment): ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.of(context).success,
                  ),
                ),
                Text(
                  '$currencyCode $creditBalance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).success,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          AnimatedProgressBar(
            value: progress,
            height: 7,
            backgroundColor:
                isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
            color: utilColor,
            semanticLabel: 'Credit utilization',
          ),
          const SizedBox(height: 16),

          // Two column stats: limit & available
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Credit Limit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.of(context).textSecondary
                            : AppColors.of(context).textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currencyCode $creditLimit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Credit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.of(context).textSecondary
                            : AppColors.of(context).textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currencyCode $availableCredit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card displaying upcoming statement closing and payment due dates.
class CreditCardBillingCard extends StatelessWidget {
  final CreditCardBillingModel billing;
  final VoidCallback onEditBilling;
  final bool isDark;

  const CreditCardBillingCard({
    super.key,
    required this.billing,
    required this.onEditBilling,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfigured = billing.status != 'unconfigured' &&
        billing.statementClosingDay != null &&
        billing.paymentDueDay != null;

    Color statusColor;
    String statusLabel;
    switch (billing.status) {
      case 'overdue':
        statusColor = AppColors.of(context).danger;
        statusLabel = 'Overdue';
        break;
      case 'due':
        statusColor = AppColors.of(context).warning;
        statusLabel = 'Payment Due';
        break;
      case 'paid_in_full':
        statusColor = AppColors.of(context).success;
        statusLabel = 'Paid in Full';
        break;
      case 'current':
        statusColor = AppColors.of(context).primary;
        statusLabel = 'Current';
        break;
      default:
        statusColor = AppColors.of(context).textSecondary;
        statusLabel = 'Unconfigured';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Billing & Due Dates',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSM),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    tooltip: 'Edit Billing Cycle',
                    onPressed: onEditBilling,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!isConfigured) ...[
            Text(
              'Statement closing day and payment due day are not configured for this card.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.of(context).textSecondary
                    : AppColors.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('Configure Billing Cycle'),
              onPressed: onEditBilling,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _DateColumn(
                    label: 'Statement Closes',
                    dateString: billing.closingDate ?? 'N/A',
                    cycleDay: 'Day ${billing.statementClosingDay}',
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _DateColumn(
                    label: 'Payment Due',
                    dateString: billing.dueDate ?? 'N/A',
                    cycleDay: 'Day ${billing.paymentDueDay}',
                    highlight: billing.isOverdue || billing.isDue,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (billing.daysUntilDue != null && billing.status != 'paid_in_full')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  billing.isOverdue
                      ? 'Payment is overdue by ${billing.daysUntilDue!.abs()} days.'
                      : (billing.daysUntilDue == 0
                          ? 'Payment is due today!'
                          : 'Payment due in ${billing.daysUntilDue} days.'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: billing.isOverdue
                        ? AppColors.of(context).danger
                        : (billing.isDue ? AppColors.of(context).warning : statusColor),
                  ),
                ),
              ),

            // Estimation disclaimer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: isDark
                        ? AppColors.of(context).textSecondary
                        : AppColors.of(context).textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dates are estimated from your configured cycle days. Check your official bank statement for confirmed payment amounts and dates.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.of(context).textSecondary
                            : AppColors.of(context).textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  final String label;
  final String dateString;
  final String cycleDay;
  final bool highlight;
  final bool isDark;

  const _DateColumn({
    required this.label,
    required this.dateString,
    required this.cycleDay,
    this.highlight = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.of(context).textSecondary
                : AppColors.of(context).textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateString,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: highlight ? AppColors.of(context).danger : null,
          ),
        ),
        Text(
          cycleDay,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.of(context).textSecondary
                : AppColors.of(context).textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Card displaying credit card payment history.
class CreditCardRepaymentHistoryCard extends StatelessWidget {
  final List<TransferModel> payments;
  final String currencyCode;
  final bool isLoading;
  final bool isDark;

  const CreditCardRepaymentHistoryCard({
    super.key,
    required this.payments,
    required this.currencyCode,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Repayment History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (payments.isNotEmpty)
                Text(
                  '${payments.length} payments',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.of(context).textSecondary
                        : AppColors.of(context).textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 32,
                      color: isDark
                          ? AppColors.of(context).textSecondary
                          : AppColors.of(context).textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No repayments recorded yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.of(context).textSecondary
                            : AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: payments.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (ctx, index) {
                final p = payments[index];
                return Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.of(context).success.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSM),
                      ),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        size: 18,
                        color: AppColors.of(context).success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.sourceAccountName != null
                                ? 'Paid from ${p.sourceAccountName}'
                                : 'Repayment',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.transferDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.of(context).textSecondary
                                  : AppColors.of(context).textSecondary,
                            ),
                          ),
                          if (p.note != null && p.note!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              p.note!,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? AppColors.of(context).textSecondary
                                    : AppColors.of(context).textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    MoneyText(
                      decimalString: p.amount,
                      currencyCode: p.currencyCode,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).success,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Dialog for recording an atomic repayment to a credit card.
class CreditCardRepaymentDialog extends StatefulWidget {
  final int cardId;
  final String cardName;
  final String outstandingDebt;
  final String currencyCode;

  const CreditCardRepaymentDialog({
    super.key,
    required this.cardId,
    required this.cardName,
    required this.outstandingDebt,
    required this.currencyCode,
  });

  @override
  State<CreditCardRepaymentDialog> createState() =>
      _CreditCardRepaymentDialogState();
}

class _CreditCardRepaymentDialogState extends State<CreditCardRepaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  int? _selectedSourceId;
  DateTime _paymentDate = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AccountProvider>();
    // Default to the first active asset account
    final eligible = provider.accounts
        .where((a) => a.isAsset && a.isActive && a.id != widget.cardId)
        .toList();
    if (eligible.isNotEmpty) {
      _selectedSourceId = eligible.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSourceId == null) {
      setState(() => _errorMessage = 'Please select a source asset account');
      return;
    }

    final provider = context.read<AccountProvider>();
    final source = provider.accounts
        .where((a) => a.id == _selectedSourceId)
        .firstOrNull;
    final sourceName = source?.displayName ?? 'Selected account';
    final amount = _amountController.text.trim();

    // Confirmation dialog before payment
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Card Repayment'),
        content: Text(
          'Pay ${widget.currencyCode} $amount from $sourceName to ${widget.cardName}?\n\n'
          'This will reduce your source balance and card debt. Repayments are internal money movements and do not count as expenses.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final dateFormatted =
        '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}';
    final clientKey =
        'repay-${widget.cardId}-${DateTime.now().millisecondsSinceEpoch}';

    final result = await provider.repayCreditCard(
      cardId: widget.cardId,
      sourceAccountId: _selectedSourceId!,
      amount: amount,
      paymentDate: dateFormatted,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      clientPaymentKey: clientKey,
    );

    if (!mounted) return;

    if (result != null) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Repayment successful! Remaining card debt: ${widget.currencyCode} ${result.cardDebt}',
          ),
          backgroundColor: AppColors.of(context).success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = provider.actionError ?? 'Failed to process repayment';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AccountProvider>();
    final eligibleAccounts = provider.accounts
        .where((a) => a.isAsset && a.isActive && a.id != widget.cardId)
        .toList();

    return AlertDialog(
      title: const Text('Pay Credit Card'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Source Account
              const Text(
                'Pay From (Asset Account)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              if (eligibleAccounts.isEmpty)
                Text(
                  'No active bank or wallet accounts available for repayment.',
                  style: TextStyle(color: AppColors.of(context).danger, fontSize: 12),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _selectedSourceId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: eligibleAccounts.map((a) {
                    final sub = a.institutionName != null
                        ? ' (${a.institutionName})'
                        : '';
                    return DropdownMenuItem<int>(
                      value: a.id,
                      child: Text('${a.displayName}$sub'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedSourceId = val),
                ),
              const SizedBox(height: 16),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Repayment Amount',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (DecimalMoney.isValidDecimal(widget.outstandingDebt) &&
                      DecimalMoney.isPositive(widget.outstandingDebt))
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        _amountController.text = widget.outstandingDebt;
                      },
                      child: const Text('Pay Full Debt',
                          style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '${widget.currencyCode} ',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (!DecimalMoney.isValidDecimal(val.trim())) {
                    return 'Enter a valid decimal (e.g. 1500.00)';
                  }
                  if (!DecimalMoney.isPositive(val.trim())) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Payment Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Date',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: Text(
                      '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _paymentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _paymentDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteController,
                maxLength: 255,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. October statement bill payment',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting || eligibleAccounts.isEmpty ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Payment'),
        ),
      ],
    );
  }
}

/// Dialog for editing credit card statement closing day and payment due day.
class CreditCardBillingDialog extends StatefulWidget {
  final int cardId;
  final int? currentClosingDay;
  final int? currentDueDay;

  const CreditCardBillingDialog({
    super.key,
    required this.cardId,
    this.currentClosingDay,
    this.currentDueDay,
  });

  @override
  State<CreditCardBillingDialog> createState() =>
      _CreditCardBillingDialogState();
}

class _CreditCardBillingDialogState extends State<CreditCardBillingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _closingDayController;
  late final TextEditingController _dueDayController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _closingDayController = TextEditingController(
      text: widget.currentClosingDay?.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: widget.currentDueDay?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final closingStr = _closingDayController.text.trim();
    final dueStr = _dueDayController.text.trim();

    final closingDay = closingStr.isEmpty ? null : int.parse(closingStr);
    final dueDay = dueStr.isEmpty ? null : int.parse(dueStr);

    final provider = context.read<AccountProvider>();
    final ok = await provider.updateBillingSettings(
      widget.cardId,
      statementClosingDay: closingDay,
      paymentDueDay: dueDay,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Billing cycle settings updated'),
          backgroundColor: AppColors.of(context).success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            provider.actionError ?? 'Failed to update billing cycle';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Billing Settings'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configure your card\'s monthly billing schedule to estimate statement dates and payment deadlines.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.of(context).danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Closing Day
              TextFormField(
                controller: _closingDayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Statement Closing Day (1 - 31)',
                  hintText: 'e.g. 15',
                  border: OutlineInputBorder(),
                  helperText: 'Day of month your billing cycle closes',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return null; // optional
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed < 1 || parsed > 31) {
                    return 'Must be between 1 and 31';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Due Day
              TextFormField(
                controller: _dueDayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Payment Due Day (1 - 31)',
                  hintText: 'e.g. 5',
                  border: OutlineInputBorder(),
                  helperText: 'Day of month payment is due',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return null; // optional
                  }
                  final parsed = int.tryParse(val.trim());
                  if (parsed == null || parsed < 1 || parsed > 31) {
                    return 'Must be between 1 and 31';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Settings'),
        ),
      ],
    );
  }
}
