import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/services/connectivity_service.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/report_provider.dart';
import '../providers/account_provider.dart';
import '../providers/goal_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  StreamSubscription<bool>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = ConnectivityService.connectionStream.listen((isOnline) {
      if (isOnline && _wasOffline) {
        _syncData();
      }
      _wasOffline = !isOnline;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _syncData() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.sync_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text("Connection restored. Syncing latest data..."),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );

    context.read<DashboardProvider>().loadDashboardData();
    context.read<TransactionProvider>().loadTransactions();
    context.read<BudgetProvider>().loadBudgetStatus();
    context.read<ReportProvider>().loadAllReports();
    context.read<AccountProvider>().loadAccounts();
    context.read<GoalProvider>().loadGoals();
  }

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/reports')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/budgets');
        break;
      case 3:
        context.go('/reports');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    Widget mainLayout;

    if (isTablet) {
      // Tablet/Desktop responsive layout: Use Navigation Rail
      mainLayout = Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
            labelType: NavigationRailLabelType.all,
            backgroundColor: theme.colorScheme.surface,
            indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.14),
            selectedLabelTextStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelTextStyle: TextStyle(
              color: colors.textSecondary,
              fontSize: 11,
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded, color: theme.colorScheme.primary),
                label: const Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.receipt_long_rounded),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: theme.colorScheme.primary),
                label: const Text('Transactions'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.account_balance_wallet_rounded),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: theme.colorScheme.primary),
                label: const Text('Budgets'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.bar_chart_rounded, color: theme.colorScheme.primary),
                label: const Text('Reports'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.person_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                label: const Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: widget.child),
        ],
      );
    } else {
      // Mobile standard layout: Bottom Navigation Bar
      mainLayout = widget.child;
    }

    return Scaffold(
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: ConnectivityService.connectionStream,
            initialData: ConnectivityService.isOnline,
            builder: (context, snapshot) {
              final isOnline = snapshot.data ?? true;
              if (isOnline) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                color: AppColors.danger.withValues(alpha: .94),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Offline · Showing saved data. Changes need a connection.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: mainLayout),
        ],
      ),
      bottomNavigationBar: !isTablet
          ? Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: NavigationBar(
                height: 68,
                elevation: 0,
                backgroundColor: theme.colorScheme.surface,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onItemTapped(index, context),
                indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: colors.textSecondary,
                    ),
                    selectedIcon: Icon(
                      Icons.grid_view_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.receipt_long_rounded,
                      color: colors.textSecondary,
                    ),
                    selectedIcon: Icon(
                      Icons.receipt_long_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    label: 'Activity',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colors.textSecondary,
                    ),
                    selectedIcon: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    label: 'Budgets',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: colors.textSecondary,
                    ),
                    selectedIcon: Icon(
                      Icons.bar_chart_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_rounded,
                      color: colors.textSecondary,
                    ),
                    selectedIcon: Icon(
                      Icons.person_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
