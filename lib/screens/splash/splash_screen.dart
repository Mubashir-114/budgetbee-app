import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../core/services/token_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  String _statusMessage = "Initializing secure connection...";
  bool _showRetry = false;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() {
      _opacity = 1.0;
    });

    final token = await TokenService.getToken();
    if (token == null) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      context.go("/login");
      return;
    }

    _verifySession();
  }

  Future<void> _verifySession() async {
    if (!mounted) return;
    setState(() {
      _showRetry = false;
      _statusMessage = "Securing session handshake...";
    });

    _statusTimer?.cancel();
    _statusTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _statusMessage = "Waking up server instance (Render cold starts may take up to a minute)...";
        });
      }
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.loadCurrentUser();
      _statusTimer?.cancel();

      if (!mounted) return;

      if (success) {
        context.go("/dashboard");
      } else {
        final tokenAfter = await TokenService.getToken();
        if (tokenAfter == null) {
          context.go("/login");
        } else {
          setState(() {
            _showRetry = true;
            _statusMessage = "Unable to connect to server. Check your connection or try again.";
          });
        }
      }
    } catch (_) {
      _statusTimer?.cancel();
      if (mounted) {
        setState(() {
          _showRetry = true;
          _statusMessage = "Server verification failed. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppColors.darkScaffold, const Color(0xFF0D0E15)]
                : [const Color(0xFFF1F5F9), AppColors.scaffold],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo container
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 32,
                              spreadRadius: 6,
                            ),
                          ],
                          border: Border.all(
                            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      AppDimensions.hLG,
                      Text(
                        "Personal Finance",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textLight : AppColors.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      AppDimensions.hXS,
                      Text(
                        "Manage your money smarter",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 24,
                  right: 24,
                  child: Column(
                    children: [
                      if (!_showRetry) ...[
                        const SizedBox(
                          width: 200,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        ),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: _verifySession,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text("RETRY CONNECTING"),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark.withValues(alpha: 0.8)
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}