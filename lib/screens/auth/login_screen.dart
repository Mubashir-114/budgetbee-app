import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_motion.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/custom_toast.dart';
import '../../core/widgets/living_wallet.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      CustomToast.showSuccess(context, 'Welcome back! Login successful.');
      context.go('/dashboard');
    } else {
      setState(() => _isLoading = false);
      CustomToast.showError(
        context,
        authProvider.errorMessage ?? 'Invalid credentials. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final short = MediaQuery.sizeOf(context).height < 700;

    final tokens = AppColors.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tokens.surface, tokens.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -80,
              child: _AmbientOrb(color: tokens.primary),
            ),
            Positioned(
              top: 220,
              left: -105,
              child: _AmbientOrb(color: tokens.secondary, size: 210),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(20, short ? 12 : 24, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: TweenAnimationBuilder<double>(
                      duration: reduceMotion ? Duration.zero : AppMotion.reveal,
                      curve: AppMotion.enter,
                      tween: Tween(begin: 0, end: 1),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 18),
                          child: child,
                        ),
                      ),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _Wordmark(),
                              SizedBox(height: short ? 4 : 10),
                              LivingWallet(height: short ? 132 : 172),
                              Text(
                                'Your money, beautifully in control.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontSize: short ? 25 : 29,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                'Welcome Back · Sign in to see the full picture.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: tokens.textSecondary,
                                ),
                              ),
                              SizedBox(height: short ? 18 : 25),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withValues(
                                    alpha: .88,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXL,
                                  ),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(
                                      alpha: .8,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha:
                                            theme.brightness == Brightness.dark
                                            ? .18
                                            : .05,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    AppTextField(
                                      controller: emailController,
                                      label: 'Email address',
                                      prefixIcon: Icons.alternate_email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.username,
                                        AutofillHints.email,
                                      ],
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!RegExp(
                                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(value)) {
                                          return 'Enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    AppTextField(
                                      controller: passwordController,
                                      label: 'Password',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _login(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (value.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              AppButton(
                                text: 'SIGN IN',
                                isLoading: _isLoading,
                                onPressed: _login,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'New to FinTrack?',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => context.push('/register'),
                                    child: const Text('Create account'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final tokens = AppColors.of(context);
    return Semantics(
      header: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: AppColors.auroraGradient,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'FinTrack',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '2.0',
              style: TextStyle(
                color: tokens.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.color, this.size = 240});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .14), Colors.transparent],
        ),
      ),
    ),
  );
}
