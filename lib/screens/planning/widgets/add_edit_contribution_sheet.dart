import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/goal_model.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/goal_provider.dart';

class AddEditContributionSheet extends StatefulWidget {
  final int goalId;
  final String goalName;
  final GoalContributionModel? contribution;

  const AddEditContributionSheet({
    super.key,
    required this.goalId,
    required this.goalName,
    this.contribution,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int goalId,
    required String goalName,
    GoalContributionModel? contribution,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditContributionSheet(
        goalId: goalId,
        goalName: goalName,
        contribution: contribution,
      ),
    );
  }

  @override
  State<AddEditContributionSheet> createState() => _AddEditContributionSheetState();
}

class _AddEditContributionSheetState extends State<AddEditContributionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.contribution != null;

  @override
  void initState() {
    super.initState();
    final c = widget.contribution;
    _amountController = TextEditingController(
      text: c != null ? c.amount.toStringAsFixed(0) : '',
    );
    _noteController = TextEditingController(text: c?.note ?? '');
    if (c?.contributionDate != null) {
      try {
        _selectedDate = DateTime.parse(c!.contributionDate);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'Select Contribution Date',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final provider = context.read<GoalProvider>();

    final Map<String, dynamic> data = {
      'amount': amount,
      'contributionDate': dateStr,
    };
    if (note != null) data['note'] = note;

    try {
      bool success;
      if (_isEditing) {
        success = await provider.updateContribution(
          widget.goalId,
          widget.contribution!.id,
          data,
        );
      } else {
        success = await provider.addContribution(
          widget.goalId,
          data,
        );
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = provider.errorMessage ?? 'Failed to record contribution';
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.lg,
        right: AppDimensions.lg,
        top: AppDimensions.md,
        bottom: bottomInset + AppDimensions.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Contribution' : 'Add Progress Record',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.goalName,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Prominent Accounting Safety Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Savings Allocation Only',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This records progress toward your target. It does NOT withdraw money from your accounts or create an expense ledger entry.',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Contribution Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Saved Amount *',
                  prefixText: '${currency.currencySymbol} ',
                  prefixIcon: const Icon(Icons.add_circle_outline_rounded),
                  filled: true,
                  fillColor: colors.isDark ? colors.elevated : colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a contribution amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Contribution Date
              InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.isDark ? colors.elevated : colors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: colors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date of Saving',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMMM dd, yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_calendar_rounded, color: colors.primary, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Note / Description
              TextFormField(
                controller: _noteController,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. Monthly salary transfer or bonus allocation',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  counterText: '',
                  filled: true,
                  fillColor: colors.isDark ? colors.elevated : colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Record' : 'Record Progress',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
