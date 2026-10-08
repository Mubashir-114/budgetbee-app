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
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            selectedLabelTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelTextStyle: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, fontSize: 11),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_rounded),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                label: Text('Transactions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_rounded),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                label: Text('Budgets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart_rounded),
                selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                label: Text('Profile'),
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
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                color: AppColors.danger,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 8),
                    Text(
                      "Offline: some previously loaded data may be shown. Changes need a connection.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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
                height: 64,
                elevation: 0,
                backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onItemTapped(index, context),
                indicatorColor: AppColors.primary.withValues(alpha: 0.12),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  NavigationDestination(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    selectedIcon: const Icon(
                      Icons.grid_view_rounded,
                      color: AppColors.primary,
                    ),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.receipt_long_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    selectedIcon: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                    ),
                    label: 'Transactions',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    selectedIcon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                    ),
                    label: 'Budgets',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    selectedIcon: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.primary,
                    ),
                    label: 'Reports',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.person_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    selectedIcon: const Icon(
                      Icons.person_rounded,
                      color: AppColors.primary,
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
