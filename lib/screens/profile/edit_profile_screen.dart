import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/custom_toast.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  late String _initialName;
  late String _initialEmail;

  bool _isUpdating = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _initialName = user?.name ?? '';
    _initialEmail = user?.email ?? '';

    _nameController = TextEditingController(text: _initialName);
    _emailController = TextEditingController(text: _initialEmail);

    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final changed = _nameController.text.trim() != _initialName ||
        _emailController.text.trim() != _initialEmail;
    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_hasChanges || _isUpdating) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    final provider = context.read<AuthProvider>();
    final success = await provider.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isUpdating = false;
    });

    if (success) {
      CustomToast.showSuccess(context, "Profile details updated successfully");
      Navigator.of(context).pop();
    } else {
      CustomToast.showError(
        context,
        provider.errorMessage ?? "Failed to update profile",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final user = context.watch<AuthProvider>().currentUser;
    final initials = (user?.name.isNotEmpty ?? false)
        ? user!.name.substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
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
                // Compact avatar monogram
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.surface,
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Form Fields
                AppTextField(
                  controller: _nameController,
                  label: "Full Name",
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _emailController,
                  label: "Email Address",
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSave(),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Email is required";
                    }
                    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(val.trim())) {
                      return "Enter a valid email address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Subtle helper text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    "Your name and email are used for account identification and report exports.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save action - only active when changes exist
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _hasChanges ? 1.0 : 0.45,
                  child: AppButton(
                    text: "SAVE CHANGES",
                    isLoading: _isUpdating,
                    onPressed: _hasChanges ? _handleSave : () {},
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isUpdating
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text("CANCEL"),
                  ),
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
