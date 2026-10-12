import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/account_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../core/utils/category_utils.dart';
import '../../core/utils/decimal_money.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_motion.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/custom_toast.dart';

/// Formats transaction date into a friendly, localized human-readable label.
String formatFriendlyDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDate).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    if (diff > 1 && diff < 7) return DateFormat('EEEE').format(date);
    if (date.year == now.year) return DateFormat('d MMM').format(date);
    return DateFormat('d MMM yyyy').format(date);
  } catch (_) {
    return dateStr;
  }
}

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
      if (context.read<AccountProvider>().accounts.isEmpty) {
        context.read<AccountProvider>().loadAccounts();
      }
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TransactionProvider>().loadTransactions(loadMore: true);
    }
  }

  void _onSearchChanged(String query, TransactionProvider provider) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      provider.setSearchQuery(query.trim().isEmpty ? null : query.trim());
    });
  }

  void _showAddEditSheet([TransactionModel? transaction]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEditTransactionSheet(transaction: transaction),
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

  void _showSortSheet(TransactionProvider provider) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: colors.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Sort Transactions",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSortOption(
                  label: "Newest First",
                  isSelected:
                      provider.sortBy == "transaction_date" &&
                      provider.sortOrder == "desc",
                  onTap: () {
                    provider.setSort("transaction_date", "desc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Oldest First",
                  isSelected:
                      provider.sortBy == "transaction_date" &&
                      provider.sortOrder == "asc",
                  onTap: () {
                    provider.setSort("transaction_date", "asc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Highest Amount",
                  isSelected:
                      provider.sortBy == "amount" &&
                      provider.sortOrder == "desc",
                  onTap: () {
                    provider.setSort("amount", "desc");
                    Navigator.pop(ctx);
                  },
                ),
                _buildSortOption(
                  label: "Lowest Amount",
                  isSelected:
                      provider.sortBy == "amount" &&
                      provider.sortOrder == "asc",
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
    final colors = AppColors.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? colors.primary : colors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              color: colors.primary,
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildFilterChips(TransactionProvider provider, bool isDark) {
    final colors = AppColors.of(context);
    final hasActiveCategory = provider.selectedCategoryId != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All Filter
          _buildTypePill(
            label: "All",
            isSelected: provider.selectedType == null,
            onTap: () => provider.setType(null),
            colors: colors,
          ),
          const SizedBox(width: 8),

          // Expense Filter
          _buildTypePill(
            label: "Expense",
            isSelected: provider.selectedType == "expense",
            onTap: () => provider.setType("expense"),
            colors: colors,
            indicatorColor: colors.danger,
          ),
          const SizedBox(width: 8),

          // Income Filter
          _buildTypePill(
            label: "Income",
            isSelected: provider.selectedType == "income",
            onTap: () => provider.setType("income"),
            colors: colors,
            indicatorColor: colors.success,
          ),
          const SizedBox(width: 12),

          // Category Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasActiveCategory
                  ? colors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                  : colors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              border: Border.all(
                color: hasActiveCategory
                    ? colors.primary
                    : colors.cardBorder,
                width: 1.0,
              ),
            ),
            child: DropdownButton<int?>(
              value: provider.selectedCategoryId,
              hint: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Category",
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down_rounded,
                size: 20,
                color: hasActiveCategory ? colors.primary : colors.textSecondary,
              ),
              dropdownColor: colors.surface,
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    "All Categories",
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                ...CategoryModel.categories.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getCategoryIcon(c.name),
                          size: 16,
                          color: getCategoryColor(c.name),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (val) => provider.setCategoryId(val),
            ),
          ),

          if (hasActiveCategory) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => provider.setCategoryId(null),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypePill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required dynamic colors,
    Color? indicatorColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: AnimatedContainer(
        duration: AppMotion.quick,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: isSelected ? colors.primary : colors.cardBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (indicatorColor != null && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx,
    dynamic colors,
    ThemeData theme,
    bool isDark,
    TransactionProvider provider,
  ) {
    final isExpense = tx.type == "expense";
    final categoryColor = getCategoryColor(tx.category);
    final categoryIcon = getCategoryIcon(tx.category);
    final friendlyDate = formatFriendlyDate(tx.transactionDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: colors.cardBorder, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddEditSheet(tx),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Category Icon Badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      categoryIcon,
                      color: categoryColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colors.textPrimary,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tx.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tx.accountName != null &&
                              tx.accountName!.isNotEmpty) ...[
                            Text(
                              " • ${tx.accountName}",
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          Text(
                            " • $friendlyDate",
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (tx.note != null && tx.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tx.note!.trim(),
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: colors.textSecondary.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Amount & Overflow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isExpense
                              ? Icons.arrow_outward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 13,
                          color: isExpense ? colors.danger : colors.success,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "${isExpense ? '-' : '+'}${context.watch<CurrencyProvider>().format(tx.amount)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpense ? colors.danger : colors.success,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Menu Button
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  color: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.cardBorder),
                  ),
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showAddEditSheet(tx);
                    } else if (action == 'delete') {
                      _confirmDelete(context, tx, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: colors.textPrimary),
                          const SizedBox(width: 10),
                          Text('Edit', style: TextStyle(fontSize: 13, color: colors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 18, color: colors.danger),
                          const SizedBox(width: 10),
                          Text('Delete', style: TextStyle(fontSize: 13, color: colors.danger)),
                        ],
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

  void _confirmDelete(BuildContext context, TransactionModel tx, TransactionProvider provider) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Transaction",
          style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        content: Text(
          "Are you sure you want to permanently delete \"${tx.title}\"?",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCEL", style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await provider.deleteTransaction(tx.id);
              if (!mounted) return;
              if (success) {
                this.context.read<DashboardProvider>().loadDashboardData();
                this.context.read<ReportProvider>().loadAllReports();
                this.context.read<BudgetProvider>().loadBudgetStatus();
                CustomToast.showSuccess(
                  this.context,
                  "Transaction deleted successfully",
                );
              } else {
                CustomToast.showError(
                  this.context,
                  provider.errorMessage ?? "Failed to delete transaction",
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text("DELETE"),
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
    final colors = AppColors.of(context);

    final hasFilters = provider.selectedType != null ||
        provider.selectedCategoryId != null ||
        provider.searchQuery != null ||
        provider.selectedDateRange != null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "Transactions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Sort",
            icon: Icon(
              Icons.sort_rounded,
              color: provider.sortBy != "transaction_date" ||
                      provider.sortOrder != "desc"
                  ? colors.primary
                  : colors.textSecondary,
            ),
            onPressed: () => _showSortSheet(provider),
          ),
          IconButton(
            tooltip: "Date Range",
            icon: Icon(
              Icons.date_range_rounded,
              color: provider.selectedDateRange != null
                  ? colors.primary
                  : colors.textSecondary,
            ),
            onPressed: _selectDateRange,
          ),
          if (hasFilters)
            IconButton(
              tooltip: "Clear Filters",
              icon: Icon(
                Icons.filter_alt_off_rounded,
                color: colors.danger,
              ),
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.md,
              AppDimensions.sm,
              AppDimensions.md,
              AppDimensions.xs,
            ),
            child: SearchBar(
              controller: _searchController,
              hintText: "Search merchant, note...",
              hintStyle: WidgetStatePropertyAll(
                TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              leading: Icon(
                Icons.search,
                color: colors.textSecondary,
                size: 20,
              ),
              backgroundColor: WidgetStatePropertyAll(colors.surface),
              elevation: const WidgetStatePropertyAll(0),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  side: BorderSide(
                    color: colors.cardBorder,
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
                  ),
              ],
            ),
          ),

          // Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: 6.0,
            ),
            child: _buildFilterChips(provider, isDark),
          ),

          const Divider(height: 1),

          // Transactions List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadTransactions(),
              child: provider.isLoading && provider.transactions.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: AppDimensions.md),
                      children: List.generate(
                        6,
                        (index) => SkeletonLoader.listTile(),
                      ),
                    )
                  : provider.transactions.isEmpty
                      ? _buildEmptyState(provider, colors)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.md,
                            vertical: AppDimensions.sm,
                          ),
                          itemCount: provider.transactions.length +
                              (provider.hasMore ? 1 : 0),
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
                            return _buildTransactionCard(
                              context,
                              tx,
                              colors,
                              theme,
                              isDark,
                              provider,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditSheet(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          "Add",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TransactionProvider provider, dynamic colors) {
    final hasFilters = provider.searchQuery != null ||
        provider.selectedCategoryId != null ||
        provider.selectedType != null ||
        provider.selectedDateRange != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.elevated,
                shape: BoxShape.circle,
                border: Border.all(color: colors.cardBorder),
              ),
              child: Icon(
                hasFilters ? Icons.filter_alt_off_rounded : Icons.receipt_long_rounded,
                size: 32,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters ? "No matching transactions" : "No transactions yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? "Try loosening your filters or searching for something else."
                  : "Tap the Add button below to record your first transaction.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  provider.clearFilters();
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text("Reset Filters"),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showAddEditSheet(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("New Transaction"),
              ),
          ],
        ),
      ),
    );
  }
}

/// Backwards-compatible wrapper so any external dialog callers stay functional.
class AddEditTransactionDialog extends StatelessWidget {
  final TransactionModel? transaction;
  const AddEditTransactionDialog({super.key, this.transaction});

  @override
  Widget build(BuildContext context) {
    return AddEditTransactionSheet(transaction: transaction);
  }
}

/// Premium, mobile-first full-height bottom sheet for adding or editing a transaction.
class AddEditTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionSheet({super.key, this.transaction});

  @override
  State<AddEditTransactionSheet> createState() => _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState extends State<AddEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _selectedType;
  int? _selectedCategoryId;
  int? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(
      text: tx != null ? DecimalMoney.formatMinor(DecimalMoney.parseToMinor(tx.amount.toString())) : '',
    );
    _noteController = TextEditingController(text: tx?.note ?? '');
    _selectedDate = tx != null
        ? DateTime.tryParse(tx.transactionDate) ?? DateTime.now()
        : DateTime.now();
    _selectedType = tx?.type ?? 'expense';
    _selectedCategoryId = tx?.categoryId;
    _selectedAccountId = tx?.accountId;

    // Verify existing category matches type or resolve intelligently
    _ensureValidCategorySelection();
  }

  void _ensureValidCategorySelection() {
    final available = _selectedType == 'income'
        ? CategoryModel.getIncomeCategories()
        : CategoryModel.getExpenseCategories();

    if (_selectedCategoryId != null) {
      final matching = CategoryModel.findById(_selectedCategoryId);
      if (matching == null || matching.type != _selectedType) {
        // Try resolving by name for the target type
        final byName = widget.transaction != null
            ? CategoryModel.findByName(widget.transaction!.category, type: _selectedType)
            : null;
        if (byName != null) {
          _selectedCategoryId = byName.id;
        } else if (available.isNotEmpty) {
          _selectedCategoryId = available.first.id;
        }
      }
    } else if (available.isNotEmpty) {
      _selectedCategoryId = available.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(String newType) {
    if (_selectedType == newType) return;
    setState(() {
      _selectedType = newType;
      final available = newType == 'income'
          ? CategoryModel.getIncomeCategories()
          : CategoryModel.getExpenseCategories();
      final current = CategoryModel.findById(_selectedCategoryId);
      if (current == null || current.type != newType) {
        _selectedCategoryId = available.isNotEmpty ? available.first.id : null;
      }
    });
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
    if (_selectedCategoryId == null) {
      CustomToast.showError(context, "Please choose a category");
      return;
    }

    final provider = context.read<TransactionProvider>();
    final trimmedAmount = _amountController.text.trim();
    final minor = DecimalMoney.parseToMinor(trimmedAmount);
    final amountDouble = double.parse(DecimalMoney.formatMinor(minor));
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    bool success;
    if (widget.transaction != null) {
      success = await provider.editTransaction(
        id: widget.transaction!.id,
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        title: _titleController.text.trim(),
        amount: amountDouble,
        transactionDate: dateStr,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        accountId: _selectedAccountId,
      );
    } else {
      success = await provider.addTransaction(
        categoryId: _selectedCategoryId!,
        type: _selectedType,
        title: _titleController.text.trim(),
        amount: amountDouble,
        transactionDate: dateStr,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        accountId: _selectedAccountId,
      );
    }

    if (success && mounted) {
      context.read<DashboardProvider>().loadDashboardData();
      context.read<ReportProvider>().loadAllReports();
      context.read<BudgetProvider>().loadBudgetStatus();

      Navigator.pop(context);
      CustomToast.showSuccess(
        context,
        widget.transaction != null
            ? "Transaction updated"
            : "Transaction added",
      );
    } else if (mounted) {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "An error occurred",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    final provider = context.watch<TransactionProvider>();
    final accountProvider = context.watch<AccountProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animDuration = reduceMotion ? Duration.zero : AppMotion.quick;

    final isExpense = _selectedType == 'expense';
    final categories = isExpense
        ? CategoryModel.getExpenseCategories()
        : CategoryModel.getIncomeCategories();

    final flowColor = isExpense ? colors.danger : colors.success;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: colors.cardBorder, width: 1.0),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? "Edit Transaction" : "New Transaction",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Segmented Expense / Income Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.elevated,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      border: Border.all(color: colors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        // Expense Tab
                        Expanded(
                          child: InkWell(
                            onTap: () => _onTypeChanged('expense'),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                            child: AnimatedContainer(
                              duration: animDuration,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isExpense
                                    ? colors.danger.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                border: Border.all(
                                  color: isExpense
                                      ? colors.danger.withValues(alpha: 0.6)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_outward_rounded,
                                    size: 16,
                                    color: isExpense
                                        ? colors.danger
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Expense",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isExpense
                                          ? colors.danger
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Income Tab
                        Expanded(
                          child: InkWell(
                            onTap: () => _onTypeChanged('income'),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                            child: AnimatedContainer(
                              duration: animDuration,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isExpense
                                    ? colors.success.withValues(alpha: isDark ? 0.25 : 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                border: Border.all(
                                  color: !isExpense
                                      ? colors.success.withValues(alpha: 0.6)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: !isExpense
                                        ? colors.success
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Income",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: !isExpense
                                          ? colors.success
                                          : colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prominent Animated Amount Card
                  AnimatedContainer(
                    duration: animDuration,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.elevated,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                      border: Border.all(
                        color: flowColor.withValues(alpha: isDark ? 0.45 : 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: flowColor.withValues(alpha: isDark ? 0.08 : 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Amount",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                            ),
                            // Direction Indicator Badge
                            AnimatedSwitcher(
                              duration: animDuration,
                              child: Container(
                                key: ValueKey('motif_$_selectedType'),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: flowColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isExpense
                                          ? Icons.arrow_outward_rounded
                                          : Icons.arrow_downward_rounded,
                                      size: 12,
                                      color: flowColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isExpense ? "Outflow" : "Inflow",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: flowColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "${currencyProvider.currencySymbol} ",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: flowColor,
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _amountController,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: "0.00",
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "Amount is required";
                                  }
                                  final clean = val.trim();
                                  if (!DecimalMoney.isValidDecimal(clean)) {
                                    return "Enter a valid positive number";
                                  }
                                  final minor = DecimalMoney.parseToMinor(clean);
                                  if (minor <= BigInt.zero) {
                                    return "Amount must be greater than zero";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Expressive Category Picker
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Category",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (_selectedCategoryId != null)
                            Text(
                              CategoryModel.getNameById(_selectedCategoryId!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: animDuration,
                        child: Wrap(
                          key: ValueKey('categories_wrap_$_selectedType'),
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((cat) {
                            final isSelected = _selectedCategoryId == cat.id;
                            final catColor = getCategoryColor(cat.name);
                            return InkWell(
                              key: ValueKey('cat_chip_${cat.id}'),
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = cat.id;
                                });
                              },
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                              child: AnimatedContainer(
                                duration: animDuration,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? catColor.withValues(alpha: isDark ? 0.22 : 0.12)
                                      : colors.elevated,
                                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                                  border: Border.all(
                                    color: isSelected
                                        ? catColor
                                        : colors.cardBorder,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      getCategoryIcon(cat.name),
                                      size: 15,
                                      color: isSelected ? catColor : colors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected
                                            ? colors.textPrimary
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Title / Merchant Field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Title / Merchant",
                      hintText: isExpense ? "e.g. Swiggy, Uber, Groceries" : "e.g. Salary, Consulting",
                      prefixIcon: Icon(Icons.edit_note_rounded, color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        borderSide: BorderSide(color: colors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        borderSide: BorderSide(color: colors.cardBorder),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Title is required";
                      }
                      if (val.trim().length < 2) {
                        return "Title must be at least 2 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Account Selector (if accounts exist)
                  if (accountProvider.accounts.isNotEmpty) ...[
                    DropdownButtonFormField<int?>(
                      initialValue: _selectedAccountId,
                      dropdownColor: colors.surface,
                      decoration: InputDecoration(
                        labelText: "Account (Optional)",
                        prefixIcon: Icon(Icons.account_balance_rounded, color: colors.textSecondary),
                        filled: true,
                        fillColor: colors.elevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          borderSide: BorderSide(color: colors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          borderSide: BorderSide(color: colors.cardBorder),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text("None / Default Account"),
                        ),
                        ...accountProvider.accounts.map(
                          (acc) => DropdownMenuItem(
                            value: acc.id,
                            child: Text("${acc.displayName} (${acc.subtype})"),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedAccountId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Transaction Date Field
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Transaction Date",
                        prefixIcon: Icon(Icons.calendar_today_rounded, color: colors.textSecondary),
                        filled: true,
                        fillColor: colors.elevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          borderSide: BorderSide(color: colors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                          borderSide: BorderSide(color: colors.cardBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('d MMMM yyyy').format(_selectedDate),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Note (Optional)
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: "Note (Optional)",
                      prefixIcon: Icon(Icons.notes_rounded, color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.elevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        borderSide: BorderSide(color: colors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        borderSide: BorderSide(color: colors.cardBorder),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // Sticky Save Action
                  ElevatedButton(
                    onPressed: provider.isActionLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isActionLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditing ? "SAVE CHANGES" : "ADD TRANSACTION",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
