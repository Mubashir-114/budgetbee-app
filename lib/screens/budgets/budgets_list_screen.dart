import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/budget_provider.dart';
import '../../providers/report_provider.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/custom_toast.dart';

class BudgetsListScreen extends StatefulWidget {
  const BudgetsListScreen({super.key});

  @override
  State<BudgetsListScreen> createState() => _BudgetsListScreenState();
}

class _BudgetsListScreenState extends State<BudgetsListScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgetStatus();
    });
  }

  void _showAddEditDialog([BudgetStatusModel? status]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditBudgetDialog(status: status),
    );
  }

  void _selectMonthYear() async {
    final provider = context.read<BudgetProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        int tempMonth = provider.selectedMonth;
        int tempYear = provider.selectedYear;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          title: const Text("Select Month & Year", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: tempMonth,
                    decoration: const InputDecoration(labelText: "Month"),
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(DateFormat('MMMM').format(DateTime(2026, m))),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempMonth = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: tempYear,
                    decoration: const InputDecoration(labelText: "Year"),
                    dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                    items: List.generate(10, (i) => DateTime.now().year - 2 + i)
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(y.toString()),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => tempYear = val);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                provider.changeDate(tempMonth, tempYear);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 40)),
              child: const Text("SELECT"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedMonthName = DateFormat('MMMM').format(DateTime(2026, provider.selectedMonth));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.scaffold,
      appBar: AppBar(
        title: const Text("Budgets", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: _selectMonthYear,
          ),
          AppDimensions.wSM,
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            child: Card(
              elevation: 0,
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                side: BorderSide(
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        AppDimensions.wSM,
                        Text(
                          "$selectedMonthName ${provider.selectedYear}",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _selectMonthYear,
                      icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                      label: const Text("Change", style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadBudgetStatus(),
              child: provider.isLoading && provider.budgetStatuses.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                      children: List.generate(4, (index) => SkeletonLoader.card(height: 110)),
                    )
                  : provider.budgetStatuses.isEmpty
                      ? EmptyState(
                          icon: Icons.account_balance_rounded,
                          title: "No budgets defined",
                          description: "Create budget limits for $selectedMonthName ${provider.selectedYear} to monitor spending caps.",
                          actionLabel: "Add Budget Limit",
                          onAction: () => _showAddEditDialog(),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                          itemCount: provider.budgetStatuses.length,
                          itemBuilder: (context, index) {
                            final status = provider.budgetStatuses[index];
                            final isOver = status.status == "over_budget";
                            final progress = (status.spent / status.budget).clamp(0.0, 1.0);

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                                side: BorderSide(
                                  color: isDark
                                      ? (isOver ? AppColors.danger.withValues(alpha: 0.4) : AppColors.dividerDark)
                                      : (isOver ? AppColors.danger.withValues(alpha: 0.3) : AppColors.dividerLight),
                                  width: isOver ? 1.5 : 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppDimensions.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          status.category,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        Row(
                                          children: [
                                            if (isOver)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.danger.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                                                ),
                                                child: const Text(
                                                  "OVER BUDGET",
                                                  style: TextStyle(
                                                    color: AppColors.danger,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            PopupMenuButton<String>(
                                              iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                              color: isDark ? AppColors.surfaceDark : Colors.white,
                                              onSelected: (action) {
                                                if (action == 'edit') {
                                                  _showAddEditDialog(status);
                                                } else if (action == 'delete') {
                                                  showDialog(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text("Delete Budget"),
                                                      content: const Text("Are you sure you want to delete this budget limit? This action cannot be undone."),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(ctx),
                                                          child: const Text("CANCEL"),
                                                        ),
                                                        TextButton(
                                                          onPressed: () async {
                                                            Navigator.pop(ctx);
                                                            final success = await provider.deleteBudget(status.budgetId);
                                                            if (success && mounted) {
                                                              context.read<ReportProvider>().loadAllReports();
                                                              CustomToast.showSuccess(context, "Budget limit deleted successfully");
                                                            } else if (mounted) {
                                                              CustomToast.showError(context, provider.errorMessage ?? "Failed to delete budget");
                                                            }
                                                          },
                                                          child: const Text("DELETE", style: TextStyle(color: AppColors.danger)),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: ListTile(
                                                    leading: Icon(Icons.edit_outlined, size: 20),
                                                    title: Text('Edit Amount', style: TextStyle(fontSize: 14)),
                                                    contentPadding: EdgeInsets.zero,
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: ListTile(
                                                    leading: Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                                    title: Text('Delete', style: TextStyle(color: AppColors.danger, fontSize: 14)),
                                                    contentPadding: EdgeInsets.zero,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: isDark ? AppColors.dividerDark : Colors.grey.shade100,
                                        color: isOver ? AppColors.danger : AppColors.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Spent: ${_currencyFormat.format(status.spent)}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOver ? AppColors.danger : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                            fontWeight: isOver ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          "Limit: ${_currencyFormat.format(status.budget)}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? AppColors.textLight : AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      status.remaining >= 0
                                          ? "Remaining: ${_currencyFormat.format(status.remaining)}"
                                          : "Over by: ${_currencyFormat.format(status.remaining.abs())}",
                                      style: TextStyle(
                                        color: status.remaining >= 0 ? AppColors.success : AppColors.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLG)),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text("Limit", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class AddEditBudgetDialog extends StatefulWidget {
  final BudgetStatusModel? status;

  const AddEditBudgetDialog({super.key, this.status});

  @override
  State<AddEditBudgetDialog> createState() => _AddEditBudgetDialogState();
}

class _AddEditBudgetDialogState extends State<AddEditBudgetDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  int? _selectedCategoryId;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final s = widget.status;
    final provider = context.read<BudgetProvider>();

    _amountController = TextEditingController(text: s != null ? s.budget.toString() : '');
    _selectedCategoryId = s?.categoryId;
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final provider = context.read<BudgetProvider>();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    bool success;
    if (widget.status != null) {
      success = await provider.editBudget(
        id: widget.status!.budgetId,
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
      context.read<ReportProvider>().loadAllReports();
      Navigator.pop(context);
      CustomToast.showSuccess(context, widget.status != null ? "Budget limit updated" : "Budget limit created");
    } else if (mounted) {
      CustomToast.showError(context, provider.errorMessage ?? "An error occurred");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.status != null;
    final provider = context.watch<BudgetProvider>();
    final expenseCategories = CategoryModel.getExpenseCategories();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        isEditing ? "Edit Budget Limit" : "Add Budget Limit",
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                decoration: const InputDecoration(labelText: "Expense Category"),
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                items: expenseCategories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: isEditing
                    ? null
                    : (val) {
                        setState(() {
                          _selectedCategoryId = val;
                        });
                      },
                validator: (val) => val == null ? "Select a category" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Limit Amount (\$)", prefixText: "\$ "),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return "Amount is required";
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) return "Enter a valid budget limit";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(labelText: "Target Period", enabled: false),
                child: Text(
                  "${DateFormat('MMMM').format(DateTime(2026, _selectedMonth))} $_selectedYear",
                  style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: provider.isActionLoading ? null : () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: provider.isActionLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(90, 40),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: provider.isActionLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("SAVE"),
        ),
      ],
    );
  }
}
