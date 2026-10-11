import 'package:flutter/material.dart';

import '../constants/app_motion.dart';

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.height = 7,
    this.semanticLabel,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: semanticLabel,
      value: '${(target * 100).round()} percent',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: target),
        duration: reduceMotion ? Duration.zero : AppMotion.reveal,
        curve: AppMotion.enter,
        builder: (context, animatedValue, _) => ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: LinearProgressIndicator(
            value: animatedValue,
            minHeight: height,
            color: color,
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );
  }
}
