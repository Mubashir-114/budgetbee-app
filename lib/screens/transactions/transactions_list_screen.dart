import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../core/utils/category_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/custom_toast.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionProvider>().loadTransactions(loadMore: true);
    }
  }

  void _onSearchChanged(String query, TransactionProvider provider) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      provider.setSearchQuery(query.trim().isEmpty ? null : query.trim());
    });
  }

  void _showAddEditDialog([TransactionModel? transaction]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditTransactionDialog(transaction: transaction),
    );
  }

  Future<void> _selectDateRange() async {
    final provider = context.read<TransactionProvider>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: provider.selectedDateRange,
    );
    if (range != null) {
      provider.setDateRange(range);
    }
  }

  void _showSortSheet(TransactionProvider provider, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sort Transactions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                ),
                const SizedBox(height: 16),
                _buildSortOption(
                  label: "Newest Transactions",
                  isSelected: provider.sortBy == "transaction_date" && provider.sortOrder == "desc",
                  onTap: () {
                    provider.setSort("transaction_date", "desc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Oldest Transactions",
                  isSelected: provider.sortBy == "transaction_date" && provider.sortOrder == "asc",
                  onTap: () {
                    provider.setSort("transaction_date", "asc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Highest Spending",
                  isSelected: provider.sortBy == "amount" && provider.sortOrder == "desc",
                  onTap: () {
                    provider.setSort("amount", "desc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Lowest Spending",
                  isSelected: provider.sortBy == "amount" && provider.sortOrder == "asc",
                  onTap: () {
                    provider.setSort("amount", "asc");
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20) : null,
      onTap: onTap,
    );
  }

  Widget _buildFilterChips(TransactionProvider provider, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text("All"),
            selected: provider.selectedType == null,
            onSelected: (_) => provider.setType(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text("Income"),
            selected: provider.selectedType == "income",
            onSelected: (_) => provider.setType("income"),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text("Expense"),
            selected: provider.selectedType == "expense",
            onSelected: (_) => provider.setType("expense"),
          ),
          const SizedBox(width: 16),
          DropdownButton<int?>(
            value: provider.selectedCategoryId,
            hint: Text(
              "Category",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            underline: const SizedBox(),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text("All Categories", style: TextStyle(fontSize: 13)),
              ),
              ...CategoryModel.categories.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name, style: const TextStyle(fontSize: 13)),
                  )),
            ],
            onChanged: (val) => provider.setCategoryId(val),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.scaffold,
      appBar: AppBar(
        title: const Text("Transactions", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(
              Icons.sort_rounded,
              color: provider.sortBy != "transaction_date" || provider.sortOrder != "desc"
                  ? AppColors.primary
                  : null,
            ),
            onPressed: () => _showSortSheet(provider, isDark),
          ),
          IconButton(
            icon: Icon(
              Icons.date_range_rounded,
              color: provider.selectedDateRange != null ? AppColors.primary : null,
            ),
            onPressed: _selectDateRange,
          ),
          if (provider.selectedDateRange != null ||
              provider.selectedType != null ||
              provider.selectedCategoryId != null ||
              provider.searchQuery != null)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded, color: AppColors.danger),
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
            ),
          AppDimensions.wSM,
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            child: SearchBar(
              controller: _searchController,
              hintText: "Search transactions...",
              hintStyle: WidgetStatePropertyAll(
                TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
              ),
              leading: Icon(
                Icons.search,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                size: 20,
              ),
              backgroundColor: WidgetStatePropertyAll(isDark ? AppColors.surfaceDark : Colors.white),
              elevation: const WidgetStatePropertyAll(0),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  side: BorderSide(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    width: 1.0,
                  ),
                ),
              ),
              onChanged: (val) => _onSearchChanged(val, provider),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      provider.setSearchQuery(null);
                    },
                  )
              ],
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 4.0),
            child: _buildFilterChips(provider, isDark),
          ),
          const Divider(),
          // Transactions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadTransactions(),
              child: provider.isLoading && provider.transactions.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: List.generate(6, (index) => SkeletonLoader.listTile()),
                    )
                  : provider.transactions.isEmpty
                      ? EmptyState(
                          icon: Icons.search_off_rounded,
                          title: "No transactions found",
                          description: provider.searchQuery != null
                              ? "We couldn't find any results matching \"${provider.searchQuery}\"."
                              : "Start tracking budgets by logs or details.",
                          actionLabel: provider.searchQuery != null || provider.selectedCategoryId != null || provider.selectedType != null
                              ? "Clear Filters"
                              : "Refresh List",
                          onAction: () {
                            if (provider.searchQuery != null || provider.selectedCategoryId != null || provider.selectedType != null) {
                              _searchController.clear();
                              provider.clearFilters();
                            } else {
                              provider.loadTransactions();
                            }
                          },
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                          itemCount: provider.transactions.length + (provider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.transactions.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final tx = provider.transactions[index];
                            final isExpense = tx.type == "expense";

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                side: BorderSide(
                                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                                  width: 1.0,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Hero(
                                  tag: 'avatar_${tx.id}',
                                  child: CircleAvatar(
                                    backgroundColor: getCategoryColor(tx.category).withValues(alpha: 0.12),
                                    radius: 20,
                                    child: Icon(
                                      getCategoryIcon(tx.category),
                                      color: getCategoryColor(tx.category),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  tx.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  "${tx.category} • ${tx.transactionDate}\n${tx.note ?? ''}",
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${isExpense ? '-' : '+'}${context.watch<CurrencyProvider>().format(tx.amount)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isExpense ? AppColors.danger : AppColors.success,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    PopupMenuButton<String>(
                                      iconColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      color: isDark ? AppColors.surfaceDark : Colors.white,
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _showAddEditDialog(tx);
                                        } else if (action == 'delete') {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text("Delete Transaction"),
                                              content: const Text("Are you sure you want to delete this transaction? This action is permanent."),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text("CANCEL"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    Navigator.pop(ctx);
                                                    final success = await provider.deleteTransaction(tx.id);
                                                    if (success && mounted) {
                                                      context.read<DashboardProvider>().loadDashboardData();
                                                      context.read<ReportProvider>().loadAllReports();
                                                      context.read<BudgetProvider>().loadBudgetStatus();
                                                      
                                                      CustomToast.showSuccess(context, "Transaction deleted successfully");
                                                    } else if (mounted) {
                                                      CustomToast.showError(context, provider.errorMessage ?? "Failed to delete transaction");
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
                                            title: Text('Edit', style: TextStyle(fontSize: 14)),
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
        label: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class AddEditTransactionDialog extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionDialog({super.key, this.transaction});

  @override
  State<AddEditTransactionDialog> createState() => _AddEditTransactionDialogState();
}

class _AddEditTransactionDialogState extends State<AddEditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedType;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(text: tx != null ? tx.amount.toString() : '');
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedDate = tx != null ? DateTime.parse(tx.transactionDate) : DateTime.now();
    _selectedType = tx?.type ?? 'expense';
    _selectedCategoryId = tx?.categoryId;

    if (_selectedCategoryId == null) {
      final available = _selectedType == 'income'
          ? CategoryModel.getIncomeCategories()
          : CategoryModel.getExpenseCategories();
      if (available.isNotEmpty) {
        _selectedCategoryId = available.first.id;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    final provider = context.read<TransactionProvider>();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    bool success;
    if (widget.transaction != null) {
      success = await provider.editTransaction(
        id: widget.transaction!.id,
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        title: _titleController.text.trim(),
        amount: amount,
        transactionDate: dateStr,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
    } else {
      success = await provider.addTransaction(
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        title: _titleController.text.trim(),
        amount: amount,
        transactionDate: dateStr,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
    }

    if (success && mounted) {
      context.read<DashboardProvider>().loadDashboardData();
      context.read<ReportProvider>().loadAllReports();
      context.read<BudgetProvider>().loadBudgetStatus();

      Navigator.pop(context);
      CustomToast.showSuccess(context, widget.transaction != null ? "Transaction updated" : "Transaction added");
    } else if (mounted) {
      CustomToast.showError(context, provider.errorMessage ?? "An error occurred");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    final provider = context.watch<TransactionProvider>();
    final categories = _selectedType == 'income'
        ? CategoryModel.getIncomeCategories()
        : CategoryModel.getExpenseCategories();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        isEditing ? "Edit Transaction" : "Add Transaction",
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'expense';
                              _selectedCategoryId = CategoryModel.getExpenseCategories().first.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedType == 'expense'
                                  ? (isDark ? AppColors.primary : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                              boxShadow: _selectedType == 'expense' && !isDark
                                  ? [const BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))]
                                  : null,
                            ),
                            child: Text(
                              "Expense",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedType == 'expense'
                                    ? (isDark ? Colors.white : AppColors.textDark)
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'income';
                              _selectedCategoryId = CategoryModel.getIncomeCategories().first.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedType == 'income'
                                  ? (isDark ? AppColors.primary : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                              boxShadow: _selectedType == 'income' && !isDark
                                  ? [const BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2))]
                                  : null,
                            ),
                            child: Text(
                              "Income",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selectedType == 'income'
                                    ? (isDark ? Colors.white : AppColors.textDark)
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: "Category"),
                  dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                  items: categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategoryId = val;
                    });
                  },
                  validator: (val) => val == null ? "Select a category" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Title is required";
                    if (val.trim().length < 3) return "Title must be at least 3 characters";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "Amount (\$)", prefixText: "\$ "),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "Amount is required";
                    final parsed = double.tryParse(val);
                    if (parsed == null || parsed <= 0) return "Enter a valid positive number";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: "Transaction Date"),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(_selectedDate),
                          style: TextStyle(
                            color: isDark ? AppColors.textLight : AppColors.textDark,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: "Note (Optional)"),
                  maxLines: 2,
                ),
              ],
            ),
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
