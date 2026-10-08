import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/widgets/custom_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Settings mock states
  bool _notificationsEnabled = true;
  
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isUpdatingProfile = true;
    });

    final provider = context.read<AuthProvider>();
    final success = await provider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isUpdatingProfile = false;
    });

    if (success) {
      CustomToast.showSuccess(context, "Profile details updated successfully");
    } else {
      CustomToast.showError(context, provider.errorMessage ?? "Failed to update profile");
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() {
      _isChangingPassword = true;
    });

    final provider = context.read<AuthProvider>();
    final success = await provider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isChangingPassword = false;
    });

    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      CustomToast.showSuccess(context, "Password updated successfully");
    } else {
      CustomToast.showError(context, provider.errorMessage ?? "Failed to update password");
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          content: const SingleChildScrollView(
            child: Text(
              "Your privacy is our priority. Personal Finance Manager encrypts your authentication token locally using secure hardware-backed storage. None of your transaction details, savings data, or budgets are shared with third parties or advertisers. Information is fetched securely over HTTPS from our cloud server. If you request account deletion, all data is immediately and permanently removed from our hosting database.\n\nFor questions, please contact support@personalfinance.io.",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CLOSE"),
            ),
          ],
        );
      },
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          title: const Text("About App", style: TextStyle(fontWeight: FontWeight.bold)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_rounded, size: 48, color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                "Personal Finance Manager",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "Version 1.0.0 (M3 Upgrade Edition)",
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              SizedBox(height: 16),
              Text(
                "Created with Flutter, Provider, and Material 3 design systems. Optimized for fast transactions tracking and offline caching.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CLOSE"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final provider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.scaffold,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.md),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        user?.name.substring(0, 1).toUpperCase() ?? "U",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? "User Name",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? "email@example.com",
                    style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account settings card
            Card(
              elevation: 0,
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Account Settings",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Full Name"),
                        validator: (val) => val == null || val.trim().isEmpty ? "Name is required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: "Email Address"),
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return "Email is required";
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Enter a valid email";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isUpdatingProfile ? null : _updateProfile,
                          child: _isUpdatingProfile
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("UPDATE DETAILS"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Change password card
            Card(
              elevation: 0,
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Change Password",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _currentPasswordController,
                        decoration: const InputDecoration(labelText: "Current Password"),
                        obscureText: true,
                        validator: (val) => val == null || val.isEmpty ? "Current password is required" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: const InputDecoration(labelText: "New Password"),
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "New password is required";
                          if (val.length < 6) return "Minimum 6 characters";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(labelText: "Confirm New Password"),
                        obscureText: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Confirm your password";
                          if (val != _newPasswordController.text) return "Passwords do not match";
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isChangingPassword ? null : _changePassword,
                          child: _isChangingPassword
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text("CHANGE PASSWORD"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preference settings card (mock preferences)
            Card(
              elevation: 0,
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "Application Preferences",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: -0.2),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Push Notifications", style: TextStyle(fontSize: 14)),
                      subtitle: const Text("Receive limits threshold alerts", style: TextStyle(fontSize: 11)),
                      value: _notificationsEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _notificationsEnabled = val;
                        });
                        CustomToast.showInfo(
                          context,
                          val ? "Notifications Enabled" : "Notifications Disabled",
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Display Currency", style: TextStyle(fontSize: 14)),
                      subtitle: Consumer<CurrencyProvider>(
                        builder: (context, currency, child) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current currency: ${currency.selectedCurrencyString}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            const Text(
                              'Changes the symbol only; amounts are not converted.',
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: () {
                        final currencyProv = context.read<CurrencyProvider>();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Select Display Currency"),
                            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                {'label': 'USD (\$)', 'code': 'USD'},
                                {'label': 'EUR (€)', 'code': 'EUR'},
                                {'label': 'GBP (£)', 'code': 'GBP'},
                                {'label': 'INR (₹)', 'code': 'INR'},
                              ]
                                  .map((c) => ListTile(
                                        title: Text(c['label']!),
                                        trailing: currencyProv.currencyCode == c['code']
                                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)
                                            : null,
                                        onTap: () {
                                          currencyProv.setCurrency(c['code']!);
                                          Navigator.pop(ctx);
                                          CustomToast.showSuccess(context, "Currency updated to ${c['label']}");
                                        },
                                      ))
                                  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Privacy Policy", style: TextStyle(fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: _showPrivacyPolicy,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("About Application", style: TextStyle(fontSize: 14)),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      onTap: _showAbout,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logout Action
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMD)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Confirm Logout"),
                      content: const Text("Are you sure you want to log out of your account?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("CANCEL"),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await provider.logout();
                            if (!context.mounted) return;
                            context.go("/login");
                          },
                          child: const Text("LOGOUT", style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("LOG OUT", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
