import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_motion.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController = AnimationController(
    vsync: this,
    duration: AppMotion.press,
    lowerBound: 0,
    upperBound: .035,
  );

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final foreground = Theme.of(context).colorScheme.onPrimary;
    return Semantics(
      button: true,
      enabled: !widget.isLoading,
      label: widget.isLoading ? '${widget.text}, loading' : widget.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.isLoading ? null : (_) => _pressController.forward(),
        onTapUp: widget.isLoading ? null : (_) => _pressController.reverse(),
        onTapCancel: widget.isLoading ? null : _pressController.reverse,
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedBuilder(
          animation: _pressController,
          builder: (context, child) => Transform.scale(
            scale: MediaQuery.disableAnimationsOf(context)
                ? 1
                : 1 - _pressController.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: AppMotion.quick,
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              gradient: LinearGradient(
                colors: widget.isLoading
                    ? [
                        colors.primary.withValues(alpha: .55),
                        colors.primaryDeep.withValues(alpha: .55),
                      ]
                    : [colors.primary, colors.primaryDeep],
              ),
              boxShadow: widget.isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: .28),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: AppMotion.quick,
                child: widget.isLoading
                    ? SizedBox(
                        key: ValueKey('loading'),
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      )
                    : Text(
                        widget.text,
                        key: const ValueKey('label'),
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
