import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_motion.dart';

/// A lightweight, entirely vector-rendered ambient illustration for auth.
/// It deliberately avoids realistic notes and pauses when animations are
/// disabled by the platform accessibility setting.
class LivingWallet extends StatefulWidget {
  const LivingWallet({super.key, this.height = 178});

  final double height;

  @override
  State<LivingWallet> createState() => _LivingWalletState();
}

class _LivingWalletState extends State<LivingWallet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.ambient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion == reduce) return;
    _reduceMotion = reduce;
    if (reduce) {
      _controller.stop();
      _controller.value = .38;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'An illustrated wallet with gently floating money tokens',
      child: RepaintBoundary(
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _WalletPainter(
                progress: _controller.value,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletPainter extends CustomPainter {
  const _WalletPainter({required this.progress, required this.dark});

  final double progress;
  final bool dark;

  double wave(double offset) => math.sin((progress + offset) * math.pi * 2);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .61);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: dark ? .24 : .16),
          AppColors.secondary.withValues(alpha: .06),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * .42));
    canvas.drawCircle(center, size.width * .42, glow);

    for (var i = 0; i < 7; i++) {
      final x = size.width * (.16 + i * .115);
      final y = size.height * (.2 + .07 * wave(i * .19));
      canvas.drawCircle(
        Offset(x, y),
        i.isEven ? 2.2 : 1.4,
        Paint()
          ..color = (i % 3 == 0 ? AppColors.secondary : AppColors.primary)
              .withValues(alpha: .3 + .15 * wave(i * .11).abs()),
      );
    }

    _drawToken(
      canvas,
      Offset(size.width * .29, size.height * (.31 + .035 * wave(0))),
      17,
      AppColors.gold,
      '₹',
    );
    _drawToken(
      canvas,
      Offset(size.width * .69, size.height * (.27 + .045 * wave(.32))),
      15,
      AppColors.secondary,
      '₹',
    );
    _drawNote(
      canvas,
      Offset(size.width * .48, size.height * (.18 + .035 * wave(.58))),
      wave(.13) * .08,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(wave(.1) * .018);
    canvas.translate(-center.dx, -center.dy);

    final walletRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width * .58, height: 82),
      const Radius.circular(23),
    );
    canvas.drawRRect(
      walletRect.shift(const Offset(0, 9)),
      Paint()
        ..color = Colors.black.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      walletRect,
      Paint()
        ..shader = LinearGradient(
          colors: dark
              ? const [Color(0xFF2C303B), Color(0xFF1F222B)]
              : const [Color(0xFF383C47), Color(0xFF282B33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(walletRect.outerRect),
    );

    final seam = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(walletRect.deflate(7), seam);

    final clasp = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx + size.width * .13, center.dy - 18, 51, 36),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      clasp,
      Paint()..color = dark ? const Color(0xFF373C48) : const Color(0xFF2E323D),
    );
    canvas.drawCircle(
      Offset(clasp.left + 15, clasp.center.dy),
      4,
      Paint()..color = AppColors.gold,
    );
    canvas.restore();
  }

  void _drawToken(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    String label,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = color.withValues(alpha: .18),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: radius,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawNote(Canvas canvas, Offset center, double angle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-25, -13, 50, 26),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = AppColors.secondary.withValues(alpha: .9),
    );
    canvas.drawCircle(
      Offset.zero,
      6,
      Paint()
        ..color = dark
            ? const Color(0xFF353946)
            : const Color(0xFF454A57),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WalletPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dark != dark;
}
