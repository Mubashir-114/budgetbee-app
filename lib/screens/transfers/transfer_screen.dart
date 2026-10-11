import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/account_provider.dart';

class TransferScreen extends StatefulWidget {
  final int? initialSourceAccountId;

  const TransferScreen({super.key, this.initialSourceAccountId});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _sourceAccountId;
  int? _destinationAccountId;
  DateTime _transferDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _sourceAccountId = widget.initialSourceAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceAccountId == null || _destinationAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both source and destination accounts'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_sourceAccountId == _destinationAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Source and destination accounts must be different'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<AccountProvider>();
    final key = 'tr-${DateTime.now().millisecondsSinceEpoch}-$_sourceAccountId-$_destinationAccountId';
    final dateStr =
        '${_transferDate.year}-${_transferDate.month.toString().padLeft(2, '0')}-${_transferDate.day.toString().padLeft(2, '0')}';

    final success = await provider.createTransfer(
      sourceAccountId: _sourceAccountId!,
      destinationAccountId: _destinationAccountId!,
      amount: _amountController.text.trim(),
      transferDate: dateStr,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      clientTransferKey: key,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer completed successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.actionError ?? 'Transfer failed'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts.where((a) => a.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Funds'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Source account dropdown
              DropdownButtonFormField<int>(
                initialValue: _sourceAccountId,
                decoration: const InputDecoration(
                  labelText: 'From Account',
                  prefixIcon: Icon(Icons.outbox_rounded),
                ),
                items: accounts.map((acc) {
                  return DropdownMenuItem<int>(
                    value: acc.id,
                    child: Text('${acc.displayName} (${acc.type})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _sourceAccountId = val;
                    if (_destinationAccountId == val) {
                      _destinationAccountId = null;
                    }
                  });
                },
                validator: (val) => val == null ? 'Please select source account' : null,
              ),
              const SizedBox(height: 16),

              // Destination account dropdown
              DropdownButtonFormField<int>(
                initialValue: _destinationAccountId,
                decoration: const InputDecoration(
                  labelText: 'To Account',
                  prefixIcon: Icon(Icons.move_to_inbox_rounded),
                ),
                items: accounts.where((acc) => acc.id != _sourceAccountId).map((acc) {
                  return DropdownMenuItem<int>(
                    value: acc.id,
                    child: Text('${acc.displayName} (${acc.type})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _destinationAccountId = val);
                },
                validator: (val) => val == null ? 'Please select destination account' : null,
              ),
              const SizedBox(height: 16),

              // Amount input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (INR)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  hintText: 'e.g. 500.00',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final trimmed = val.trim();
                  if (!RegExp(r'^(0|[1-9]\d*)(\.\d{1,2})?$').hasMatch(trimmed)) {
                    return 'Enter a valid decimal (e.g. 500.00)';
                  }
                  if (trimmed == '0' || trimmed == '0.00' || trimmed == '0.0') {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Transfer date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Transfer Date'),
                subtitle: Text(
                  '${_transferDate.year}-${_transferDate.month.toString().padLeft(2, '0')}-${_transferDate.day.toString().padLeft(2, '0')}',
                ),
                trailing: TextButton(
                  child: const Text('Change'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _transferDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _transferDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Note input
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  prefixIcon: Icon(Icons.note_rounded),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.swap_horiz_rounded),
                label: Text(_isSubmitting ? 'Transferring...' : 'Transfer Funds'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
