import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/utils/category_utils.dart';
import '../../providers/sms_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/dashboard_provider.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$');
  final Set<String> _expandedHashes = {};

  @override
  void initState() {
    super.initState();
    // Auto-scan on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmsProvider>().scanSms();
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
            Text("Import job processed successfully with the following results:"),
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
              
              // Refresh state of transaction ledger and dashboard
              context.read<TransactionProvider>().loadTransactions();
              context.read<DashboardProvider>().loadDashboardData();
              
              // Go back
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkScaffold : AppColors.scaffold,
        appBar: AppBar(
          title: const Text("Import SMS Transactions"),
          elevation: 0,
          actions: [
            if (!smsProvider.isScanning && !smsProvider.isImporting)
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => smsProvider.scanSms(),
                tooltip: "Rescan SMS",
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "New Messages"),
              Tab(text: "Archived"),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: New Messages Checklist
            Stack(
              children: [
                _buildContent(context, smsProvider, isDark, showArchived: false),
                if (smsProvider.isImporting) _buildImportOverlay(),
              ],
            ),
            // Tab 2: Archived Messages List
            _buildContent(context, smsProvider, isDark, showArchived: true),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOverlay() {
    return Container(
      color: Colors.black45,
      child: const Center(
        child: Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Importing to ledger...",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SmsProvider smsProvider, bool isDark, {required bool showArchived}) {
    final list = showArchived ? smsProvider.archivedTransactions : smsProvider.transactions;

    // 1. Scanning State
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
            const SizedBox(height: 8),
            Text(
              "Looking for banking notifications",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Error State (like permission denied)
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () => smsProvider.scanSms(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry Scanning"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // 3. Empty Transactions State
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

    // 4. Checklist Display State
    return Stack(
      children: [
        Column(
          children: [
            // Selection Header Stats
            if (!showArchived)
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: smsProvider.isAllSelected,
                      tristate: smsProvider.selectedCount > 0 && !smsProvider.isAllSelected,
                      onChanged: (val) {
                        smsProvider.toggleSelectAll(val ?? true);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${smsProvider.foundCount} Transactions Found",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "✓ ${smsProvider.selectedCount} Selected",
                            style: TextStyle(
                              fontSize: 12,
                              color: smsProvider.selectedCount > 0 ? AppColors.primary : AppColors.textSecondaryLight,
                              fontWeight: smsProvider.selectedCount > 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable Transactions List
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.only(bottom: showArchived ? 24 : 90), // spacer for bottom action bar
                itemCount: list.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                ),
                itemBuilder: (context, index) {
                  final tx = list[index];
                  final isExpense = tx.type == "expense";
                  final isExpanded = _expandedHashes.contains(tx.smsHash);

                  return InkWell(
                    onTap: showArchived ? null : () => smsProvider.toggleSelection(tx.smsHash),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm, vertical: AppDimensions.md),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showArchived)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                                  child: Icon(
                                    Icons.cloud_done_rounded,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                )
                              else
                                Checkbox(
                                  value: smsProvider.selectedHashes.contains(tx.smsHash),
                                  onChanged: (_) => smsProvider.toggleSelection(tx.smsHash),
                                ),
                              CircleAvatar(
                                backgroundColor: getCategoryColor(tx.category).withValues(alpha: 0.12),
                                radius: 20,
                                child: Icon(
                                  getCategoryIcon(tx.category),
                                  color: getCategoryColor(tx.category),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tx.merchant,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${isExpense ? '-' : '+'}${_currencyFormat.format(tx.amount)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isExpense ? AppColors.danger : AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                                            borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                                          ),
                                          child: Text(
                                            tx.bank,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          DateFormat('MMM dd, hh:mm a').format(tx.date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isExpense ? AppColors.danger : AppColors.success).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            isExpense ? "Expense" : "Income",
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isExpense ? AppColors.danger : AppColors.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (tx.referenceNumber != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "Ref: ${tx.referenceNumber}",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    // Clickable Message Preview toggle
                                    InkWell(
                                      onTap: () => _toggleMessageExpand(tx.smsHash),
                                      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isExpanded ? "Hide Message" : "View Message Text",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            size: 16,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isExpanded) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(AppDimensions.sm),
                                        decoration: BoxDecoration(
                                          color: isDark ? AppColors.cardDark : AppColors.dividerLight.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                                          border: Border.all(
                                            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          tx.messageBody,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
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
          ],
        ),

        // Floating Bottom Action Bar
        if (!showArchived)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: smsProvider.selectedCount == 0
                          ? null
                          : () async {
                              final success = await smsProvider.importSelectedTransactions();
                              if (success && context.mounted) {
                                final response = smsProvider.importResponse;
                                if (response != null) {
                                  _showResultDialog(
                                    context,
                                    response.imported,
                                    response.duplicates,
                                    response.failed,
                                  );
                                }
                              } else if (context.mounted && smsProvider.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(smsProvider.errorMessage!),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                        ),
                        disabledBackgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                      ),
                      child: Text(
                        "Import Selected (${smsProvider.selectedCount})",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
