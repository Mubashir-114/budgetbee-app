import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/goal_model.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/goal_provider.dart';

class AddEditGoalSheet extends StatefulWidget {
  final GoalModel? goal;

  const AddEditGoalSheet({super.key, this.goal});

  static Future<bool?> show(BuildContext context, {GoalModel? goal}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditGoalSheet(goal: goal),
    );
  }

  @override
  State<AddEditGoalSheet> createState() => _AddEditGoalSheetState();
}

class _AddEditGoalSheetState extends State<AddEditGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;
  late final TextEditingController _startingAmountController;
  late final TextEditingController _descriptionController;

  DateTime? _selectedTargetDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _targetAmountController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(0) : '',
    );
    _startingAmountController = TextEditingController(
      text: g != null ? g.startingAmount.toStringAsFixed(0) : '0',
    );
    _descriptionController = TextEditingController(text: g?.description ?? '');
    if (g?.targetDate != null) {
      try {
        _selectedTargetDate = DateTime.parse(g!.targetDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _startingAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final initial = _selectedTargetDate ?? now.add(const Duration(days: 90));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: 'Select Target Deadline',
    );
    if (picked != null) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final currency = context.read<CurrencyProvider>().currencyCode;
    final name = _nameController.text.trim();
    final targetAmount = double.tryParse(_targetAmountController.text.trim()) ?? 0;
    final startingAmount = double.tryParse(_startingAmountController.text.trim()) ?? 0;
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final provider = context.read<GoalProvider>();
    final targetDateStr = _selectedTargetDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedTargetDate!)
        : null;

    try {
      bool success;
      if (_isEditing) {
        final Map<String, dynamic> updateData = {
          'name': name,
          'targetAmount': targetAmount,
        };
        if (description != null) updateData['description'] = description;
        if (targetDateStr != null) updateData['targetDate'] = targetDateStr;

        success = await provider.updateGoal(widget.goal!.id, updateData);
      } else {
        final Map<String, dynamic> createData = {
          'name': name,
          'targetAmount': targetAmount,
          'currency': currency,
        };
        if (description != null) createData['description'] = description;
        if (targetDateStr != null) createData['targetDate'] = targetDateStr;
        if (startingAmount > 0) createData['startingAmount'] = startingAmount;

        success = await provider.createGoal(createData);
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _errorMessage = provider.errorMessage ?? 'Failed to save goal';
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
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                  Text(
                    _isEditing ? 'Edit Savings Goal' : 'New Savings Goal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Accounting Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Goals are planning trackers. Setting a goal does not withdraw funds or alter your bank or wallet balances.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
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

              // Goal Name Field
              TextFormField(
                controller: _nameController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Goal Name *',
                  hintText: 'e.g. Emergency Fund, New Laptop, Vacation',
                  prefixIcon: const Icon(Icons.flag_rounded),
                  counterText: '',
                  filled: true,
                  fillColor: colors.isDark ? colors.elevated : colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a goal name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Target Amount Field
              TextFormField(
                controller: _targetAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Target Amount *',
                  prefixText: '${currency.currencySymbol} ',
                  prefixIcon: const Icon(Icons.savings_rounded),
                  filled: true,
                  fillColor: colors.isDark ? colors.elevated : colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a target amount';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Target Date Selector
              InkWell(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                onTap: _pickTargetDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.isDark ? colors.elevated : colors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: colors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Date (Optional)',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTargetDate != null
                                  ? DateFormat('MMMM dd, yyyy').format(_selectedTargetDate!)
                                  : 'No deadline set',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: _selectedTargetDate != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _selectedTargetDate != null
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedTargetDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedTargetDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Starting Amount (creation only)
              if (!_isEditing) ...[
                TextFormField(
                  controller: _startingAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Initial Saved Progress (Optional)',
                    prefixText: '${currency.currencySymbol} ',
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                    helperText: 'Existing savings you already have towards this goal',
                    filled: true,
                    fillColor: colors.isDark ? colors.elevated : colors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return null;
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Enter a non-negative number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: 'Notes / Motivation (Optional)',
                  hintText: 'e.g. For peace of mind or 3 months living expenses',
                  prefixIcon: const Icon(Icons.notes_rounded),
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
                        _isEditing ? 'Save Changes' : 'Create Goal',
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
