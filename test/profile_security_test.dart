import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/screens/profile/edit_profile_screen.dart';
import 'package:frontend/screens/profile/profile_screen.dart';
import 'package:frontend/screens/profile/security_screen.dart';

class _FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _user;
  String? _errorMessage;
  bool updateProfileCalled = false;
  bool changePasswordCalled = false;
  String? lastUpdatedName;
  String? lastUpdatedEmail;

  _FakeAuthProvider({UserModel? initialUser}) : _user = initialUser;

  @override
  UserModel? get currentUser => _user;

  @override
  bool get isLoggedIn => _user != null;

  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => _errorMessage;

  @override
  VoidCallback? get onSessionReset => null;

  @override
  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    updateProfileCalled = true;
    lastUpdatedName = name;
    lastUpdatedEmail = email;
    _user = UserModel(id: _user?.id ?? 1, name: name, email: email);
    notifyListeners();
    return true;
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalled = true;
    return true;
  }

  @override
  Future<bool> login({required String email, required String password}) async => true;

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async => true;

  @override
  Future<void> logout() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<bool> loadCurrentUser() async => true;
}

Widget _wrapWithProviders({
  required Widget child,
  required _FakeAuthProvider authProvider,
  CurrencyProvider? currencyProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<CurrencyProvider>.value(
        value: currencyProvider ?? CurrencyProvider(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    ),
  );
}

void main() {
  group('Graphite & Champagne Default Theme Token Specifications', () {
    test('Dark theme tokens match graphite and champagne specifications', () {
      expect(AppColors.darkScaffold, const Color(0xFF171B24));
      expect(AppColors.surfaceDark, const Color(0xFF252934));
      expect(AppColors.elevatedDark, const Color(0xFF30343F));
      expect(AppColors.primary, const Color(0xFFD6A668));
      expect(AppColors.primaryDeep, const Color(0xFFBE8F50));
      expect(AppColors.secondary, const Color(0xFFE6BE85));
      expect(AppColors.textLight, const Color(0xFFF4EFE7));
      expect(AppColors.textSecondaryDark, const Color(0xFFB5AFAB));
      expect(AppColors.dividerDark, const Color(0xFF393D48));
    });

    test('ThemeData reflects graphite surface and champagne primary', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF171B24));
      expect(darkTheme.colorScheme.primary, const Color(0xFFD6A668));
      expect(darkTheme.colorScheme.surface, const Color(0xFF252934));
    });
  });

  group('ProfileScreen Layout & Read-Only Hierarchy', () {
    testWidgets('renders compact identity header and grouped settings without permanent form fields', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthProvider(
        initialUser: const UserModel(id: 42, name: 'Elena Rostova', email: 'elena@fintrack.io'),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          child: const ProfileScreen(),
          authProvider: fakeAuth,
        ),
      );

      // Verify compact identity header
      expect(find.text('Elena Rostova'), findsOneWidget);
      expect(find.text('elena@fintrack.io'), findsOneWidget);
      expect(find.text('E'), findsOneWidget); // Monogram initial
      expect(find.text('Edit'), findsOneWidget); // Subtle edit action

      // Verify no permanent form fields are exposed on main screen
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('UPDATE DETAILS'), findsNothing);
      expect(find.text('CHANGE PASSWORD'), findsNothing);

      // Verify grouped settings sections
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Accounts & Wallets'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Display Currency'), findsOneWidget);

      expect(find.text('SECURITY & LEGAL'), findsOneWidget);
      expect(find.text('Security & Password'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('About Application'), findsOneWidget);

      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });
  });

  group('EditProfileScreen', () {
    testWidgets('initializes with current user and tracks change state', (
      tester,
    ) async {
      final fakeAuth = _FakeAuthProvider(
        initialUser: const UserModel(id: 10, name: 'Marcus Vance', email: 'marcus@vance.io'),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          child: const EditProfileScreen(),
          authProvider: fakeAuth,
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Marcus Vance'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'marcus@vance.io'), findsOneWidget);

      // Modify the name
      final nameField = find.widgetWithText(TextFormField, 'Marcus Vance');
      await tester.enterText(nameField, 'Marcus Vance Jr');
      await tester.pumpAndSettle();

      // Tap SAVE CHANGES
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(fakeAuth.updateProfileCalled, isTrue);
      expect(fakeAuth.lastUpdatedName, 'Marcus Vance Jr');
      expect(fakeAuth.lastUpdatedEmail, 'marcus@vance.io');
    });
  });

  group('SecurityScreen', () {
    testWidgets('validates required fields and minimum length', (tester) async {
      final fakeAuth = _FakeAuthProvider(
        initialUser: const UserModel(id: 10, name: 'User', email: 'user@test.com'),
      );

      await tester.pumpWidget(
        _wrapWithProviders(
          child: const SecurityScreen(),
          authProvider: fakeAuth,
        ),
      );

      expect(find.text('Security & Password'), findsOneWidget);
      expect(find.text('UPDATE PASSWORD'), findsOneWidget);

      // Tap update without entering passwords
      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pumpAndSettle();

      expect(find.text('Current password is required'), findsOneWidget);
      expect(fakeAuth.changePasswordCalled, isFalse);

      // Enter valid current, invalid new
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'oldpass123');
      await tester.enterText(textFields.at(1), '123');
      await tester.enterText(textFields.at(2), '123');
      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Enter matching valid new passwords
      await tester.enterText(textFields.at(1), 'newsecret456');
      await tester.enterText(textFields.at(2), 'newsecret456');
      await tester.tap(find.text('UPDATE PASSWORD'));
      await tester.pumpAndSettle();

      expect(fakeAuth.changePasswordCalled, isTrue);
    });
  });
}
