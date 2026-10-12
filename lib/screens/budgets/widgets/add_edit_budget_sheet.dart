import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/category_utils.dart';
import '../../../core/widgets/custom_toast.dart';
import '../../../models/budget_model.dart';
import '../../../models/category_model.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/report_provider.dart';

/// Premium adaptive bottom sheet for creating or editing category budgets.
/// Features category selection with contextual icons, prominent amount entry,
/// quick presets, keyboard handling, and sticky accessible actions.
class AddEditBudgetSheet extends StatefulWidget {
  const AddEditBudgetSheet({
    super.key,
    this.categoryBudget,
  });

  final BudgetCategoryProgressModel? categoryBudget;

  static Future<void> show(
    BuildContext context, {
    BudgetCategoryProgressModel? categoryBudget,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditBudgetSheet(categoryBudget: categoryBudget),
    );
  }

  @override
  State<AddEditBudgetSheet> createState() => _AddEditBudgetSheetState();
}

class _AddEditBudgetSheetState extends State<AddEditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late FocusNode _amountFocusNode;

  int? _selectedCategoryId;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final cb = widget.categoryBudget;
    final provider = context.read<BudgetProvider>();

    _amountController = TextEditingController(text: cb != null ? cb.budgetLimit : '');
    _amountFocusNode = FocusNode();
    _selectedCategoryId = cb?.categoryId;
    _selectedMonth = provider.selectedMonth;
    _selectedYear = provider.selectedYear;

    if (_selectedCategoryId == null) {
      final expenses = CategoryModel.getExpenseCategories();
      if (expenses.isNotEmpty) {
        _selectedCategoryId = expenses.first.id;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _addQuickPreset(double increment) {
    final current = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final next = current + increment;
    _amountController.text = next.toStringAsFixed(0);
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final provider = context.read<BudgetProvider>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    bool success;
    if (widget.categoryBudget != null) {
      success = await provider.editBudget(
        id: widget.categoryBudget!.budgetId,
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    } else {
      success = await provider.addBudget(
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    }

    if (success && mounted) {
      if (provider.selectedMonth != _selectedMonth ||
          provider.selectedYear != _selectedYear) {
        provider.changeDate(_selectedMonth, _selectedYear);
      }
      context.read<ReportProvider>().loadAllReports();
      Navigator.pop(context);
      CustomToast.showSuccess(
        context,
        widget.categoryBudget != null
            ? "Budget limit updated"
            : "Budget limit created",
      );
    } else if (mounted) {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "An error occurred",
      );
    }
  }

  Future<void> _delete() async {
    final cb = widget.categoryBudget;
    if (cb == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final colors = AppColors.of(dialogCtx);
        return AlertDialog(
          title: const Text("Delete Budget"),
          content: Text("Are you sure you want to delete the budget limit for ${cb.category}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text("DELETE", style: TextStyle(color: colors.danger)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final provider = context.read<BudgetProvider>();
      final ok = await provider.deleteBudget(cb.budgetId);
      if (mounted) {
        if (ok) {
          context.read<ReportProvider>().loadAllReports();
          Navigator.pop(context);
          CustomToast.showSuccess(context, "Budget limit deleted");
        } else {
          CustomToast.showError(context, provider.errorMessage ?? "Failed to delete");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.categoryBudget != null;
    final provider = context.watch<BudgetProvider>();
    final currency = context.watch<CurrencyProvider>();
    final colors = AppColors.of(context);
    final expenseCategories = CategoryModel.getExpenseCategories();
    final monthName = DateFormat('MMMM').format(DateTime(2026, _selectedMonth));

    final selectedCategory = expenseCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => expenseCategories.first,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sheet Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? "Edit Budget Limit" : "Add Budget Limit",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Target Period: $monthName $_selectedYear",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: colors.textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Category Selector
                Text(
                  "Expense Category",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                if (isEditing)
                  // Fixed category badge when editing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.elevated,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: getCategoryColor(selectedCategory.name).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            getCategoryIcon(selectedCategory.name),
                            size: 18,
                            color: getCategoryColor(selectedCategory.name),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedCategory.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.lock_outline_rounded, size: 16, color: colors.textSecondary),
                      ],
                    ),
                  )
                else
                  // Interactive dropdown with icons when creating
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    dropdownColor: colors.surface,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: colors.elevated,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        borderSide: BorderSide(color: colors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        borderSide: BorderSide(color: colors.cardBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        borderSide: BorderSide(color: colors.primary, width: 1.5),
                      ),
                    ),
                    items: expenseCategories.map((c) {
                      final cColor = getCategoryColor(c.name);
                      return DropdownMenuItem<int>(
                        value: c.id,
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: cColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(getCategoryIcon(c.name), size: 15, color: cColor),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategoryId = val);
                    },
                    validator: (val) => val == null ? "Select a category" : null,
                  ),

                const SizedBox(height: 18),

                // Amount Entry Field
                Text(
                  "Limit Amount (${currency.currencyCode})",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _amountController,
                  focusNode: _amountFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    prefixText: '${currency.currencySymbol} ',
                    prefixStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                    filled: true,
                    fillColor: colors.elevated,
                    hintText: "0.00",
                    hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      borderSide: BorderSide(color: colors.primary, width: 1.5),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Amount is required";
                    }
                    final parsed = double.tryParse(val.trim());
                    if (parsed == null || parsed <= 0) {
                      return "Enter a valid budget limit";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Quick Presets Row (+₹1k, +₹2k, +₹5k, +₹10k)
                Wrap(
                  spacing: 8,
                  children: [
                    _PresetChip(label: "+₹1,000", onTap: () => _addQuickPreset(1000)),
                    _PresetChip(label: "+₹2,000", onTap: () => _addQuickPreset(2000)),
                    _PresetChip(label: "+₹5,000", onTap: () => _addQuickPreset(5000)),
                    _PresetChip(label: "+₹10,000", onTap: () => _addQuickPreset(10000)),
                  ],
                ),

                const SizedBox(height: 24),

                // Sticky Action Buttons
                Row(
                  children: [
                    if (isEditing) ...[
                      OutlinedButton(
                        onPressed: provider.isActionLoading ? null : _delete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.danger,
                          side: BorderSide(color: colors.danger.withValues(alpha: 0.5)),
                          minimumSize: const Size(48, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                          ),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 20),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: provider.isActionLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.isDark ? const Color(0xFF0B111A) : Colors.white,
                          minimumSize: const Size.fromHeight(46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                          ),
                          elevation: 0,
                        ),
                        child: provider.isActionLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.isDark ? const Color(0xFF0B111A) : Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? "UPDATE BUDGET" : "SAVE BUDGET",
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility wrapper for existing tests or dialog invocations.
class AddEditBudgetDialog extends StatelessWidget {
  const AddEditBudgetDialog({super.key, this.categoryBudget});

  final BudgetCategoryProgressModel? categoryBudget;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AddEditBudgetSheet(categoryBudget: categoryBudget),
    );
  }
}
