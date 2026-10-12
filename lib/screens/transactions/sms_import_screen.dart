import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/category_utils.dart';
import '../../models/category_model.dart';
import '../../models/detected_transaction_model.dart';
import '../../providers/account_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sms_provider.dart';
import '../../providers/transaction_provider.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final Set<String> _expandedHashes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmsProvider>().scanAndDetectSmartTransactions();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  void _toggleMessageExpand(String hash) {
    setState(() {
      if (_expandedHashes.contains(hash)) {
        _expandedHashes.remove(hash);
      } else {
        _expandedHashes.add(hash);
      }
    });
  }

  void _showResultDialog(BuildContext context, int imported, int duplicates, int failed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLG)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text("Import Summary"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Import job processed successfully with the following results:"),
            const SizedBox(height: 16),
            _buildResultRow(Icons.add_task_rounded, "Imported", imported, AppColors.success),
            const SizedBox(height: 8),
            _buildResultRow(Icons.copy_rounded, "Duplicates (Skipped)", duplicates, AppColors.warning),
            const SizedBox(height: 8),
            _buildResultRow(Icons.error_outline_rounded, "Failed", failed, AppColors.danger),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<TransactionProvider>().loadTransactions();
              context.read<DashboardProvider>().loadDashboardData();
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String label, int count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          ),
          child: Text(
            "$count",
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsProvider = context.watch<SmsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          title: const Text("Smart SMS Transactions"),
          elevation: 0,
          actions: [
            if (!smsProvider.isScanning && !smsProvider.isImporting && !smsProvider.isOperating)
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => smsProvider.scanAndDetectSmartTransactions(),
                tooltip: "Rescan SMS",
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Smart Review"),
              Tab(text: "New SMS"),
              Tab(text: "Archived"),
            ],
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Phase 3B Smart Transactions Review
            _buildSmartReviewTab(context, smsProvider, isDark),

            // Tab 2: New Messages Checklist (Legacy inbox import preserved)
            Stack(
              children: [
                _buildLegacyContent(context, smsProvider, isDark, showArchived: false),
                if (smsProvider.isImporting) _buildImportOverlay("Importing to ledger..."),
              ],
            ),

            // Tab 3: Archived Messages List
            _buildLegacyContent(context, smsProvider, isDark, showArchived: true),
          ],
        ),
      ),
    );
  }

  // ── Privacy & Safety Banner ─────────────────────────────────────────────────

  Widget _buildPrivacyBanner(bool isDark) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.all(AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_rounded, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Privacy & Financial Safety",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "SMS notifications are parsed on your device. Unreviewed records never alter your ledger or account balances until explicitly approved. Full account numbers are never logged.",
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Smart Review Content ─────────────────────────────────────────────

  Widget _buildSmartReviewTab(BuildContext context, SmsProvider smsProvider, bool isDark) {
    final colors = AppColors.of(context);
    if (smsProvider.isScanning || smsProvider.isLoadingDetected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Analyzing banking notifications...",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    if (smsProvider.detectedErrorMessage != null && smsProvider.detectedTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                "Unable to load suggestions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                smsProvider.detectedErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => smsProvider.loadDetectedTransactions(status: "suggested"),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (smsProvider.detectedTransactions.isEmpty) {
      return ListView(
        children: [
          _buildPrivacyBanner(isDark),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: AppDimensions.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 64,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  "All Caught Up",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "No detected transactions are currently awaiting review. Tap Rescan to scan new SMS messages.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => smsProvider.scanAndDetectSmartTransactions(),
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text("Rescan Inbox"),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildPrivacyBanner(isDark),

        // Multi-select & Batch Actions Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
          color: colors.surface,
          child: Row(
            children: [
              Checkbox(
                value: smsProvider.isAllDetectedSelected,
                tristate: smsProvider.selectedDetectedCount > 0 && !smsProvider.isAllDetectedSelected,
                onChanged: (val) => smsProvider.toggleSelectAllDetected(val ?? true),
              ),
              Text(
                "${smsProvider.detectedCount} Detected (${smsProvider.selectedDetectedCount} selected)",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              if (smsProvider.selectedDetectedCount > 0) ...[
                TextButton.icon(
                  onPressed: smsProvider.isOperating
                      ? null
                      : () async {
                          final ok = await smsProvider.batchRejectSelected();
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Selected transactions rejected")),
                            );
                          }
                        },
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                  label: const Text("Reject", style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: smsProvider.isOperating
                      ? null
                      : () async {
                          final ok = await smsProvider.batchConfirmSelected();
                          if (ok && context.mounted) {
                            context.read<TransactionProvider>().loadTransactions();
                            context.read<DashboardProvider>().loadDashboardData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Selected transactions confirmed into ledger")),
                            );
                          }
                        },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text("Confirm", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                ),
              ],
            ],
          ),
        ),

        // List of detected transactions
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.sm),
            itemCount: smsProvider.detectedTransactions.length,
            itemBuilder: (ctx, index) {
              final tx = smsProvider.detectedTransactions[index];
              return _buildDetectedCard(context, tx, smsProvider, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedCard(
    BuildContext context,
    DetectedTransactionModel tx,
    SmsProvider smsProvider,
    bool isDark,
  ) {
    final colors = AppColors.of(context);
    final currencySymbol = context.watch<CurrencyProvider>().currencySymbol;
    final isSelected = smsProvider.selectedDetectedIds.contains(tx.id);
    final isIncomeType = ["income", "refund", "credit_card_repayment"].contains(tx.classification);
    final isNeedsReview = tx.confidence < 0.8 || tx.isAccountAmbiguous || tx.accountId == null;

    final cardBg = colors.surface;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
      elevation: 1,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: BorderSide(
          color: isNeedsReview
              ? colors.warning.withValues(alpha: 0.5)
              : colors.divider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Selection Checkbox + Clean Merchant + Amount
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => smsProvider.toggleDetectedSelection(tx.id),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.merchantClean.isNotEmpty ? tx.merchantClean : "Unknown Merchant",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tx.merchantRaw.isNotEmpty && tx.merchantRaw != tx.merchantClean)
                        Text(
                          "Raw: ${tx.merchantRaw}",
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  "${isIncomeType ? '+' : '-'} $currencySymbol${tx.amount}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isIncomeType
                        ? colors.success
                        : colors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Row 2: Badges (Classification, Account suggestion, Category, Confidence)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Classification badge
                _buildBadge(
                  label: _formatClassification(tx.classification),
                  color: isIncomeType ? colors.success : colors.primary,
                  icon: isIncomeType ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                ),

                // Account suggestion badge
                if (tx.isAccountAmbiguous)
                  _buildBadge(
                    label: "Ambiguous (**${tx.maskedAccountHint ?? '----'})",
                    color: colors.warning,
                    icon: Icons.warning_amber_rounded,
                  )
                else if (tx.suggestedAccountName != null || tx.accountName != null)
                  _buildBadge(
                    label: tx.accountName ?? tx.suggestedAccountName!,
                    color: colors.primary,
                    icon: Icons.account_balance_rounded,
                  )
                else
                  _buildBadge(
                    label: "Select Account",
                    color: colors.warning,
                    icon: Icons.help_outline_rounded,
                  ),

                // Category suggestion badge
                _buildBadge(
                  label: tx.categoryName ?? tx.suggestedCategoryName ?? "General",
                  color: colors.secondary,
                  icon: getCategoryIcon(tx.categoryName ?? tx.suggestedCategoryName ?? "General"),
                ),

                // Confidence badge
                _buildBadge(
                  label: isNeedsReview
                      ? "Needs Review (${(tx.confidence * 100).toInt()}%)"
                      : "${(tx.confidence * 100).toInt()}% Match",
                  color: isNeedsReview ? colors.warning : colors.success,
                  icon: isNeedsReview ? Icons.rate_review_outlined : Icons.verified_rounded,
                ),
              ],
            ),

            if (tx.confidenceReason != null && tx.confidenceReason!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tx.confidenceReason!,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colors.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // Row 3: Action Buttons (Confirm, Edit, Reject)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  tx.transactionDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: smsProvider.isOperating
                      ? null
                      : () => _showRejectDialog(context, tx.id, smsProvider),
                  icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.danger),
                  label: const Text("Reject", style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: smsProvider.isOperating
                      ? null
                      : () => _showEditDialog(context, tx, smsProvider),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text("Edit", style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  onPressed: smsProvider.isOperating
                      ? null
                      : () async {
                          final ok = await smsProvider.confirmDetected(tx.id);
                          if (ok && context.mounted) {
                            context.read<TransactionProvider>().loadTransactions();
                            context.read<DashboardProvider>().loadDashboardData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Confirmed ${tx.merchantClean} to ledger")),
                            );
                          }
                        },
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text("Confirm", style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  String _formatClassification(String raw) {
    switch (raw) {
      case "credit_card_purchase":
        return "Card Purchase";
      case "credit_card_repayment":
        return "Card Repayment";
      case "refund":
        return "Refund";
      case "transfer":
        return "Transfer";
      case "income":
        return "Income";
      default:
        return "Expense";
    }
  }

  // ── Manual Correction / Edit Dialog ─────────────────────────────────────────

  void _showEditDialog(
    BuildContext context,
    DetectedTransactionModel tx,
    SmsProvider smsProvider,
  ) {
    final merchantCtrl = TextEditingController(text: tx.merchantClean);
    String selectedClassification = tx.classification;
    int? selectedAccountId = tx.accountId ?? tx.suggestedAccountId;
    int? selectedCategoryId = tx.categoryId ?? tx.suggestedCategoryId;

    final accounts = context.read<AccountProvider>().accounts;
    final categories = CategoryModel.categories;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLG)),
          title: const Text("Edit Transaction"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: merchantCtrl,
                  decoration: const InputDecoration(
                    labelText: "Merchant Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedClassification,
                  decoration: const InputDecoration(
                    labelText: "Classification",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: "expense", child: Text("Expense")),
                    DropdownMenuItem(value: "income", child: Text("Income")),
                    DropdownMenuItem(value: "credit_card_purchase", child: Text("Card Purchase")),
                    DropdownMenuItem(value: "credit_card_repayment", child: Text("Card Repayment")),
                    DropdownMenuItem(value: "refund", child: Text("Refund")),
                    DropdownMenuItem(value: "transfer", child: Text("Transfer")),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedClassification = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: selectedAccountId,
                  decoration: const InputDecoration(
                    labelText: "Account",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("None / Default")),
                    ...accounts.map(
                      (acc) => DropdownMenuItem(
                        value: acc.id,
                        child: Text("${acc.displayName} (${acc.maskedLast4 ?? 'no digits'})"),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedAccountId = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Auto Category")),
                    ...categories.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text("${c.name} (${c.type})"),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedCategoryId = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final changes = <String, dynamic>{
                  "merchantClean": merchantCtrl.text.trim(),
                  "classification": selectedClassification,
                  "accountId": selectedAccountId,
                  "categoryId": selectedCategoryId,
                };
                Navigator.of(dialogCtx).pop();
                await smsProvider.updateDetected(tx.id, changes);
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, int txId, SmsProvider smsProvider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Reject Transaction?"),
        content: const Text(
          "This transaction will be discarded and will not be added to your account ledger.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await smsProvider.rejectDetected(txId);
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  // ── Legacy Content (Preserved for compatibility) ────────────────────────────

  Widget _buildImportOverlay(String message) {
    return Container(
      color: Colors.black45,
      child: Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegacyContent(
    BuildContext context,
    SmsProvider smsProvider,
    bool isDark, {
    required bool showArchived,
  }) {
    final list = showArchived ? smsProvider.archivedTransactions : smsProvider.transactions;

    if (smsProvider.isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Scanning messages...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ],
        ),
      );
    }

    if (smsProvider.errorMessage != null && list.isEmpty) {
      final isPermanent = smsProvider.permissionStatus?.isPermanentlyDenied ?? false;
      return Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sms_failed_outlined, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                "Access Blocked",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                smsProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              if (isPermanent)
                ElevatedButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text("Open App Settings"),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => smsProvider.scanSms(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry Scanning"),
                ),
            ],
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                showArchived ? Icons.archive_outlined : Icons.mark_email_read_rounded,
                size: 64,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                showArchived ? "No archived messages" : "No transactions found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                showArchived
                    ? "Successfully imported SMS transactions will be archived here."
                    : "We scanned your messages but couldn't find any new financial transactions.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              if (!showArchived)
                ElevatedButton.icon(
                  onPressed: () => smsProvider.scanSms(),
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text("Rescan Inbox"),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (!showArchived)
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: Row(
              children: [
                Checkbox(
                  value: smsProvider.isAllSelected,
                  tristate: smsProvider.selectedCount > 0 && !smsProvider.isAllSelected,
                  onChanged: (val) => smsProvider.toggleSelectAll(val ?? true),
                ),
                Text(
                  "${smsProvider.foundCount} Found (${smsProvider.selectedCount} selected)",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: smsProvider.selectedCount == 0 || smsProvider.isImporting
                      ? null
                      : () async {
                          final ok = await smsProvider.importSelectedTransactions();
                          if (ok && smsProvider.importResponse != null && context.mounted) {
                            final res = smsProvider.importResponse!;
                            _showResultDialog(context, res.imported, res.duplicates, res.failed);
                          }
                        },
                  child: const Text("Import Selected"),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (ctx, idx) {
              final tx = list[idx];
              final isSelected = smsProvider.selectedHashes.contains(tx.smsHash);
              final isExpanded = _expandedHashes.contains(tx.smsHash);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.xs),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.sm),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (!showArchived)
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => smsProvider.toggleSelection(tx.smsHash),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  "${DateFormat('d MMM y').format(tx.date)} • ${tx.bank}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${tx.type == 'income' ? '+' : '-'} ₹${tx.amount.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx.type == 'income' ? AppColors.success : AppColors.danger,
                            ),
                          ),
                          IconButton(
                            icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                            onPressed: () => _toggleMessageExpand(tx.smsHash),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            tx.messageBody,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
