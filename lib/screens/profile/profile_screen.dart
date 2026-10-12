import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/custom_toast.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Settings mock state
  bool _notificationsEnabled = true;

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return AlertDialog(
          title: const Text(
            "Privacy Policy",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: colors.surface,
          content: const SingleChildScrollView(
            child: Text(
              "Your privacy is our priority. Personal Finance Manager encrypts your authentication token locally using secure hardware-backed storage. None of your transaction details, savings data, or budgets are shared with third parties or advertisers. Information is fetched securely over HTTPS from our cloud server. If you request account deletion, all data is immediately and permanently removed from our hosting database.\n\nFor questions, please contact support@personalfinance.io.",
              style: TextStyle(fontSize: 13, height: 1.45),
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
        final colors = AppColors.of(ctx);
        final themeProvider = ctx.watch<ThemeProvider>();
        return AlertDialog(
          title: const Text(
            "About FinTrack",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          backgroundColor: colors.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FinTrackLogo(
                size: 64,
                collection: themeProvider.collection,
                borderRadius: 18,
                showBorder: true,
                showShadow: true,
              ),
              const SizedBox(height: 14),
              const Text(
                "FinTrack 2.0",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 2),
              Text(
                "Version 2.0.0 (${themeProvider.collection.displayName} Edition)",
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Engineered with Flutter, Provider, and refined fintech design tokens. Optimized for rapid transaction tracking and offline caching.",
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

  void _confirmLogout() {
    final provider = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(ctx).surface,
        title: const Text(
          "Confirm Logout",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          "Are you sure you want to log out of your account on this device?",
          style: TextStyle(fontSize: 14, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.logout();
              if (!mounted) return;
              context.go("/login");
            },
            child: const Text(
              "LOGOUT",
              style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);

    final name = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : "FinTrack User";
    final email = (user?.email != null && user!.email.isNotEmpty)
        ? user.email
        : "user@fintrack.io";
    final initial = name.substring(0, 1).toUpperCase();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A. Compact identity header card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.divider.withValues(alpha: isDark ? 0.7 : 1),
                ),
              ),
              child: Row(
                children: [
                  // Clean monogram avatar (64px)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? colors.elevated
                            : colors.primary.withValues(alpha: 0.12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.35),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Subtle Edit Profile Action
                  InkWell(
                    onTap: () => context.push('/profile/edit'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(
                          alpha: isDark ? 0.12 : 0.09,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // D. Application Preferences
            SettingsGroup(
              title: "Preferences",
              children: [
                SettingsTile(
                  icon: Icons.palette_outlined,
                  title: "Appearance",
                  subtitle: "Graphite & Champagne, Obsidian & Jade, Arctic Blue",
                  onTap: () => context.push('/profile/appearance'),
                ),
                SettingsTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Accounts & Wallets",
                  subtitle: "Manage bank accounts, credit cards and cash wallets",
                  onTap: () => context.push('/accounts'),
                ),
                SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: "Push Notifications",
                  subtitle: "Receive limit threshold alerts",
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
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
                ),
                SettingsTile(
                  icon: Icons.attach_money_rounded,
                  title: "Display Currency",
                  showDivider: false,
                  subtitleWidget: Consumer<CurrencyProvider>(
                    builder: (context, currency, child) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current currency: ${currency.selectedCurrencyString}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Changes the symbol only; amounts are not converted.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Consumer<CurrencyProvider>(
                    builder: (context, currency, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.elevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colors.divider,
                            ),
                          ),
                          child: Text(
                            currency.currencyCode,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: colors.textSecondary.withValues(
                            alpha: isDark ? 0.7 : 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    final currencyProv = context.read<CurrencyProvider>();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text(
                          "Select Display Currency",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: colors.surface,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            {'label': 'USD (\$)', 'code': 'USD'},
                            {'label': 'EUR (€)', 'code': 'EUR'},
                            {'label': 'GBP (£)', 'code': 'GBP'},
                            {'label': 'INR (₹)', 'code': 'INR'},
                          ]
                              .map((c) => ListTile(
                                    title: Text(
                                      c['label']!,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    trailing: currencyProv.currencyCode == c['code']
                                        ? Icon(
                                            Icons.check_circle_rounded,
                                            color: colors.primary,
                                            size: 20,
                                          )
                                        : null,
                                    onTap: () {
                                      currencyProv.setCurrency(c['code']!);
                                      Navigator.pop(ctx);
                                      CustomToast.showSuccess(
                                        context,
                                        "Currency updated to ${c['label']}",
                                      );
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // C & D. Security & Legal
            SettingsGroup(
              title: "Security & Legal",
              children: [
                SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: "Security & Password",
                  subtitle: "Change password and credentials",
                  onTap: () => context.push('/profile/security'),
                ),
                SettingsTile(
                  icon: Icons.shield_outlined,
                  title: "Privacy Policy",
                  subtitle: "Data encryption and local storage protection",
                  onTap: _showPrivacyPolicy,
                ),
                SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: "About Application",
                  subtitle: "Version 2.0.0 · Graphite & Champagne edition",
                  showDivider: false,
                  onTap: _showAbout,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // E. Account actions
            SettingsGroup(
              title: "Account",
              children: [
                SettingsTile(
                  icon: Icons.logout_rounded,
                  title: "Log Out",
                  subtitle: "Sign out of your active session on this device",
                  isDestructive: true,
                  showDivider: false,
                  onTap: _confirmLogout,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
