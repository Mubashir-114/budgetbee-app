import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onFieldSubmitted,
        obscureText: _obscureText,
        validator: widget.validator,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(
            widget.prefixIcon,
            color: _isFocused
                ? colors.primary
                : colors.textSecondary,
            size: 22,
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  tooltip: _obscureText ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
