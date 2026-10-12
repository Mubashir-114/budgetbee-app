import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/transactions/transactions_list_screen.dart';
import '../screens/budgets/budgets_list_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/security_screen.dart';
import '../screens/transactions/sms_import_screen.dart';
import '../screens/accounts/accounts_list_screen.dart';
import '../screens/accounts/add_account_screen.dart';
import '../screens/accounts/account_detail_screen.dart';
import '../screens/accounts/edit_account_screen.dart';
import '../screens/transfers/transfer_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  
  redirect: (context, state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isLoggedIn;
    
    final isGoingToSplash = state.matchedLocation == '/splash';
    final isGoingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/register';

    if (isGoingToSplash) {
      return null;
    }

    if (!isLoggedIn && !isGoingToAuth) {
      return '/login';
    }

    if (isLoggedIn && (isGoingToAuth || isGoingToSplash)) {
      return '/dashboard';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainNavigationScreen(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/transactions',
          builder: (context, state) => const TransactionsListScreen(),
        ),
        GoRoute(
          path: '/sms-import',
          builder: (context, state) => const SmsImportScreen(),
        ),
        GoRoute(
          path: '/budgets',
          builder: (context, state) => const BudgetsListScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/profile/security',
          builder: (context, state) => const SecurityScreen(),
        ),
        GoRoute(
          path: '/accounts',
          builder: (context, state) => const AccountsListScreen(),
        ),
        GoRoute(
          path: '/accounts/add',
          builder: (context, state) => const AddAccountScreen(),
        ),
        GoRoute(
          path: '/accounts/transfer',
          builder: (context, state) {
            final sourceId = int.tryParse(state.uri.queryParameters['sourceId'] ?? '');
            return TransferScreen(initialSourceAccountId: sourceId);
          },
        ),
        GoRoute(
          path: '/accounts/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return AccountDetailScreen(accountId: id);
          },
        ),
        GoRoute(
          path: '/accounts/:id/edit',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return EditAccountScreen(accountId: id);
          },
        ),
      ],
    ),
  ],
);