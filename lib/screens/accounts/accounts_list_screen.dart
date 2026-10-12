import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../providers/account_provider.dart';
import 'widgets/account_card.dart';
import 'widgets/account_type_summary.dart';

class AccountsListScreen extends StatefulWidget {
  const AccountsListScreen({super.key});

  @override
  State<AccountsListScreen> createState() => _AccountsListScreenState();
}

class _AccountsListScreenState extends State<AccountsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AccountProvider>();
      if (provider.accounts.isEmpty && !provider.isLoading) {
        provider.loadAccounts();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AccountProvider>().loadAccounts(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transfer',
            onPressed: () => context.push('/accounts/transfer'),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Account',
            onPressed: () => context.push('/accounts/add'),
          ),
        ],
      ),
      body: Consumer<AccountProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.accounts.isEmpty) {
            return const _LoadingView();
          }
          if (provider.errorMessage != null && provider.accounts.isEmpty) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: provider.loadAccounts,
            );
          }
          if (provider.accounts.isEmpty) {
            return _EmptyView(onAdd: () => context.push('/accounts/add'));
          }

          final activeAccounts =
              provider.accounts.where((a) => a.isActive).toList();
          final assets = activeAccounts.where((a) => a.isAsset).toList();
          final liabilities =
              activeAccounts.where((a) => !a.isAsset).toList();

          return RefreshIndicator(
            color: tokens.primary,
            onRefresh: provider.refresh,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Summary bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: AccountTypeSummary(
                      accounts: activeAccounts,
                    ),
                  ),
                ),

                // Assets section
                if (assets.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Asset Accounts',
                    count: assets.length,
                    color: tokens.success,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: AccountCard(
                          account: assets[i],
                          onTap: () =>
                              context.push('/accounts/${assets[i].id}'),
                        ),
                      ),
                      childCount: assets.length,
                    ),
                  ),
                ],

                // Liabilities section
                if (liabilities.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Credit Cards',
                    count: liabilities.length,
                    color: tokens.danger,
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: AccountCard(
                          account: liabilities[i],
                          onTap: () =>
                              context.push('/accounts/${liabilities[i].id}'),
                        ),
                      ),
                      childCount: liabilities.length,
                    ),
                  ),
                ],

                // Pagination loader
                if (provider.isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: tokens.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 24),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_account_fab',
        onPressed: () => context.push('/accounts/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Account'),
      ),
    );
  }
}

// ── Internal widgets ───────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: tokens.primary),
          const SizedBox(height: 16),
          const Text('Loading accounts…'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tokens.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  size: 40, color: tokens.danger),
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load accounts',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyView({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    tokens.primary.withValues(alpha: 0.12),
                    tokens.secondary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_rounded,
                  size: 48, color: tokens.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No accounts yet',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your bank accounts, cash, wallets\nor credit cards to get started.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: tokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Account'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(
                    AppDimensions.radiusSM),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
