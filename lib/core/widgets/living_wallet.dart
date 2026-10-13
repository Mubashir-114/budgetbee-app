import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_motion.dart';
import '../theme/fin_track_theme_tokens.dart';
import '../theme/theme_collection.dart';

/// A lightweight, entirely vector-rendered ambient illustration for auth.
/// It deliberately avoids realistic notes and pauses when animations are
/// disabled by the platform accessibility setting.
class LivingWallet extends StatefulWidget {
  const LivingWallet({super.key, this.height = 178});

  final double height;

  @visibleForTesting
  static Color brandAccentFor(ThemeCollection collection) =>
      switch (collection) {
        ThemeCollection.graphiteChampagne => const Color(0xFFD6A668),
        ThemeCollection.obsidianJade => const Color(0xFF38D5B0),
        ThemeCollection.arcticBlue => const Color(0xFF4FA3F7),
      };

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
    final theme = Theme.of(context);
    final tokens =
        theme.extension<FinTrackThemeTokens>() ??
        FinTrackThemeTokens.resolve(
          ThemeCollection.graphiteChampagne,
          theme.brightness,
        );

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
                colors: _LivingWalletColors.fromTheme(theme, tokens),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletPainter extends CustomPainter {
  const _WalletPainter({required this.progress, required this.colors});

  final double progress;
  final _LivingWalletColors colors;

  double wave(double offset) => math.sin((progress + offset) * math.pi * 2);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .61);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.accent.withValues(alpha: colors.dark ? .24 : .16),
          colors.highlight.withValues(alpha: .06),
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
          ..color = (i % 3 == 0 ? colors.highlight : colors.accent).withValues(
            alpha: .3 + .15 * wave(i * .11).abs(),
          ),
      );
    }

    _drawToken(
      canvas,
      Offset(size.width * .29, size.height * (.31 + .035 * wave(0))),
      17,
      colors.highlight,
      '₹',
    );
    _drawToken(
      canvas,
      Offset(size.width * .69, size.height * (.27 + .045 * wave(.32))),
      15,
      colors.accent,
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
        ..color = colors.shadow.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      walletRect,
      Paint()
        ..shader = LinearGradient(
          colors: [colors.walletStart, colors.walletEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(walletRect.outerRect),
    );

    final seam = Paint()
      ..color = colors.outline.withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(walletRect.deflate(7), seam);

    final clasp = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx + size.width * .13, center.dy - 18, 51, 36),
      const Radius.circular(12),
    );
    canvas.drawRRect(clasp, Paint()..color = colors.clasp);
    canvas.drawCircle(
      Offset(clasp.left + 15, clasp.center.dy),
      4,
      Paint()..color = colors.accent,
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
      Paint()..color = colors.highlight.withValues(alpha: .9),
    );
    canvas.drawCircle(Offset.zero, 6, Paint()..color = colors.noteCenter);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WalletPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.colors != colors;
}

@immutable
class _LivingWalletColors {
  const _LivingWalletColors({
    required this.dark,
    required this.accent,
    required this.highlight,
    required this.walletStart,
    required this.walletEnd,
    required this.clasp,
    required this.noteCenter,
    required this.outline,
    required this.shadow,
  });

  factory _LivingWalletColors.fromTheme(
    ThemeData theme,
    FinTrackThemeTokens tokens,
  ) {
    final accent = LivingWallet.brandAccentFor(tokens.collection);
    final dark = theme.brightness == Brightness.dark;
    final walletStart = dark
        ? tokens.elevated
        : Color.lerp(tokens.textPrimary, tokens.elevated, .12)!;
    final walletEnd = dark
        ? tokens.surface
        : Color.lerp(tokens.textPrimary, tokens.background, .05)!;

    return _LivingWalletColors(
      dark: dark,
      accent: accent,
      highlight: Color.lerp(accent, tokens.textPrimary, dark ? .28 : .18)!,
      walletStart: walletStart,
      walletEnd: walletEnd,
      clasp: Color.lerp(walletStart, tokens.textPrimary, dark ? .1 : .08)!,
      noteCenter: Color.lerp(walletStart, walletEnd, .5)!,
      outline: tokens.textPrimary,
      shadow: theme.colorScheme.shadow,
    );
  }

  final bool dark;
  final Color accent;
  final Color highlight;
  final Color walletStart;
  final Color walletEnd;
  final Color clasp;
  final Color noteCenter;
  final Color outline;
  final Color shadow;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _LivingWalletColors &&
          dark == other.dark &&
          accent == other.accent &&
          highlight == other.highlight &&
          walletStart == other.walletStart &&
          walletEnd == other.walletEnd &&
          clasp == other.clasp &&
          noteCenter == other.noteCenter &&
          outline == other.outline &&
          shadow == other.shadow;

  @override
  int get hashCode => Object.hash(
    dark,
    accent,
    highlight,
    walletStart,
    walletEnd,
    clasp,
    noteCenter,
    outline,
    shadow,
  );
}
