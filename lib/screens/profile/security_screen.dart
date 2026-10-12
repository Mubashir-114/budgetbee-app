import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/auth_provider.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate() || _isChangingPassword) return;

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
      Navigator.of(context).pop();
    } else {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "Failed to update password",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "Security & Password",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.divider.withValues(alpha: isDark ? 0.7 : 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          color: colors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password Security",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Choose a strong password with at least 6 characters.",
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Password Fields
                AppTextField(
                  controller: _currentPasswordController,
                  label: "Current Password",
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Current password is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _newPasswordController,
                  label: "New Password",
                  prefixIcon: Icons.lock_reset_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "New password is required";
                    }
                    if (val.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _confirmPasswordController,
                  label: "Confirm New Password",
                  prefixIcon: Icons.check_circle_outline_rounded,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleChangePassword(),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Please confirm your password";
                    }
                    if (val != _newPasswordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit button
                AppButton(
                  text: "UPDATE PASSWORD",
                  isLoading: _isChangingPassword,
                  onPressed: _handleChangePassword,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
