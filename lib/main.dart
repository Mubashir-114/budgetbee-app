import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/report_provider.dart';
import 'providers/sms_provider.dart';
import 'providers/currency_provider.dart';
import 'providers/account_provider.dart';
import 'providers/theme_provider.dart';
import 'core/services/cache_service.dart';
import 'core/services/connectivity_service.dart';
import 'api/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CacheService.initialize();
  ConnectivityService.initialize();

  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final dashboardProvider = DashboardProvider();
  final transactionProvider = TransactionProvider();
  final budgetProvider = BudgetProvider();
  final reportProvider = ReportProvider();
  final smsProvider = SmsProvider();
  final accountProvider = AccountProvider();
  final authProvider = AuthProvider(
    onSessionReset: () {
      dashboardProvider.clearSession();
      transactionProvider.clearSession();
      budgetProvider.clearSession();
      reportProvider.clearSession();
      smsProvider.clearSession();
      accountProvider.clearSession();
    },
  );

  ApiClient.onUnauthorized = () {
    authProvider.logout().whenComplete(() => appRouter.go('/login'));
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (context) => CurrencyProvider()),
        ChangeNotifierProvider.value(value: dashboardProvider),
        ChangeNotifierProvider.value(value: transactionProvider),
        ChangeNotifierProvider.value(value: budgetProvider),
        ChangeNotifierProvider.value(value: reportProvider),
        ChangeNotifierProvider.value(value: smsProvider),
        ChangeNotifierProvider.value(value: accountProvider),
      ],
      child: const PersonalFinanceApp(),
    ),
  );
}

class PersonalFinanceApp extends StatelessWidget {
  const PersonalFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Personal Finance Manager',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}