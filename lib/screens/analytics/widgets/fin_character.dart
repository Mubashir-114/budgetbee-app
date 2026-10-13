import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/companion_model.dart';

/// FIN's native Flutter 2.5D full-body character.
///
/// [size] is the character's total logical height. Head, torso, articulated
/// arms, hands, and lower floating shell are deliberately separate forms.
class FinCharacter extends StatefulWidget {
  final FinCharacterState state;
  final double size;
  final bool? animationsEnabled;
  final bool animationActive;
  final bool allowAnimationInTests;
  final VoidCallback? onTap;

  const FinCharacter({
    super.key,
    this.state = FinCharacterState.idle,
    this.size = 100,
    this.animationsEnabled,
    this.animationActive = true,
    this.allowAnimationInTests = false,
    this.onTap,
  });

  @override
  State<FinCharacter> createState() => _FinCharacterState();
}

class _FinCharacterState extends State<FinCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant FinCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimationState();
  }

  bool get _motionAllowed {
    final media = MediaQuery.maybeOf(context);
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
    return (widget.animationsEnabled ?? true) &&
        widget.animationActive &&
        !(media?.disableAnimations ?? false) &&
        TickerMode.valuesOf(context).enabled &&
        (!isTest || widget.allowAnimationInTests);
  }

  void _syncAnimationState() {
    if (_motionAllowed) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paintSize = Size(widget.size * .78, widget.size);
    Widget character = RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: paintSize,
          painter: _FinPainter(
            state: widget.state,
            animationValue: _motionAllowed ? _controller.value : 0,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      character = GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: character,
      );
    }

    return Semantics(
      button: widget.onTap != null,
      label: 'FIN financial companion, currently ${widget.state.label}',
      child: SizedBox(
        width: paintSize.width,
        height: paintSize.height,
        child: character,
      ),
    );
  }
}

class _FinPainter extends CustomPainter {
  final FinCharacterState state;
  final double animationValue;

  const _FinPainter({required this.state, required this.animationValue});

  static const _navy = Color(0xFF07142D);
  static const _cyan = Color(0xFF41E5F2);
  static const _gold = Color(0xFFF4B942);
  static const _goldDark = Color(0xFFB96C12);
  static const _cream = Color(0xFFFFFCF4);
  static const _creamShadow = Color(0xFFD8C8AA);

  double get _wave => math.sin(animationValue * math.pi * 2);
  double get _quickWave => math.sin(animationValue * math.pi * 4);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final floatY = _wave * h * .012;
    final breath = 1 + _wave * .008;
    final pose = _poseForState();

    _drawShadow(canvas, Offset(cx, h * .94 - floatY), w * .25, h * .022);
    canvas.save();
    canvas.translate(cx, h * .5 + floatY);
    canvas.rotate(pose.bodyTilt);
    canvas.scale(breath, breath);
    canvas.translate(-cx, -h * .5);
    _drawAura(canvas, size, pose);
    _drawLowerBody(canvas, size);
    _drawArms(canvas, size, pose);
    _drawTorso(canvas, size, pose);
    _drawNeck(canvas, size);
    _drawHead(canvas, size, pose);
    _drawSprout(canvas, size, pose);
    if (state == FinCharacterState.celebrating) _drawCelebration(canvas, size);
    canvas.restore();
  }

  _FinPose _poseForState() {
    switch (state) {
      case FinCharacterState.greeting:
        return _FinPose(-.025, -.72 + _quickWave * .05, .28, 1.05, -.2, 1);
      case FinCharacterState.listening:
        return const _FinPose(.025, -.12, .12, .16, -.16, .7);
      case FinCharacterState.thinking:
        return const _FinPose(.045, .08, -.92, .12, -.25, .8);
      case FinCharacterState.explaining:
        return _FinPose(-.01, -.36 + _quickWave * .06, .38, .62, -.5, .85);
      case FinCharacterState.happy:
        return const _FinPose(-.015, -.35, .35, .52, -.52, 1);
      case FinCharacterState.celebrating:
        return _FinPose(
          0,
          -1.02 + _quickWave * .08,
          1.02 - _quickWave * .08,
          -.42,
          .42,
          1.25,
        );
      case FinCharacterState.concerned:
        return const _FinPose(.015, .42, -.42, .28, -.28, .45);
      case FinCharacterState.confused:
        return const _FinPose(-.06, .25, -.72, .42, -.22, .7);
      case FinCharacterState.error:
        return const _FinPose(.025, .48, -.48, .32, -.32, .3);
      case FinCharacterState.idle:
        return _FinPose(
          0,
          -.1 + _wave * .025,
          .1 - _wave * .025,
          .12,
          -.12,
          .55,
        );
    }
  }

  void _drawAura(Canvas canvas, Size size, _FinPose pose) {
    final alpha = (.035 + pose.glow * .025).clamp(0.0, .09);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .48),
      width: size.width * .82,
      height: size.height * .7,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _cyan.withValues(alpha: alpha),
            _gold.withValues(alpha: alpha * .35),
            Colors.transparent,
          ],
        ).createShader(rect),
    );
  }

  void _drawShadow(Canvas canvas, Offset center, double rx, double ry) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()
        ..color = _navy.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  Paint _shellPaint(Rect rect) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, _cream, Color(0xFFF1E7D3), _creamShadow],
      stops: [0, .28, .7, 1],
    ).createShader(rect);

  void _drawLowerBody(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bob = state == FinCharacterState.celebrating
        ? _quickWave * h * .008
        : 0;
    final rect = Rect.fromCenter(
      center: Offset(w * .5, h * .82 + bob),
      width: w * .38,
      height: h * .135,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(Offset(0, h * .012)),
        Radius.circular(w * .16),
      ),
      Paint()
        ..color = _navy.withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(w * .16)),
      _shellPaint(rect),
    );
    final belt = Rect.fromCenter(
      center: Offset(w * .5, h * .79 + bob),
      width: w * .29,
      height: h * .025,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(belt, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(
          colors: [_gold, _goldDark],
        ).createShader(belt),
    );
    _drawHighlight(canvas, rect, .7);
  }

  void _drawArms(Canvas canvas, Size size, _FinPose pose) {
    _drawArm(
      canvas,
      size,
      isLeft: true,
      shoulderAngle: pose.leftShoulder,
      elbowAngle: pose.leftElbow,
    );
    _drawArm(
      canvas,
      size,
      isLeft: false,
      shoulderAngle: pose.rightShoulder,
      elbowAngle: pose.rightElbow,
    );
  }

  void _drawArm(
    Canvas canvas,
    Size size, {
    required bool isLeft,
    required double shoulderAngle,
    required double elbowAngle,
  }) {
    final w = size.width;
    final h = size.height;
    final side = isLeft ? -1.0 : 1.0;
    final shoulder = Offset(w * (.5 + side * .25), h * .5);
    final base = isLeft ? math.pi : 0.0;
    final a1 = base + side * shoulderAngle;
    final elbow = shoulder + Offset(math.cos(a1), math.sin(a1)) * h * .145;
    final a2 = a1 + side * elbowAngle;
    final hand = elbow + Offset(math.cos(a2), math.sin(a2)) * h * .125;

    final shadow = Paint()
      ..color = _navy.withValues(alpha: .16)
      ..strokeWidth = w * .115
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final shell = Paint()
      ..color = _cream
      ..strokeWidth = w * .1
      ..strokeCap = StrokeCap.round;
    final rim = Paint()
      ..color = Colors.white.withValues(alpha: .72)
      ..strokeWidth = w * .025
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      shoulder + const Offset(0, 3),
      elbow + const Offset(0, 3),
      shadow,
    );
    canvas.drawLine(
      elbow + const Offset(0, 3),
      hand + const Offset(0, 3),
      shadow,
    );
    canvas.drawLine(shoulder, elbow, shell);
    canvas.drawLine(elbow, hand, shell);
    canvas.drawLine(
      shoulder - const Offset(0, 1),
      elbow - const Offset(0, 1),
      rim,
    );
    _drawGoldNode(canvas, shoulder, w * .048);
    _drawGoldNode(canvas, elbow, w * .037);
    _drawHand(canvas, hand, size, a2, side);
  }

  void _drawHand(
    Canvas canvas,
    Offset center,
    Size size,
    double angle,
    double side,
  ) {
    final radius = size.width * .065;
    canvas.drawCircle(
      center + const Offset(0, 2),
      radius,
      Paint()..color = _navy.withValues(alpha: .14),
    );
    canvas.drawCircle(
      center,
      radius,
      _shellPaint(Rect.fromCircle(center: center, radius: radius)),
    );
    final fingerPaint = Paint()
      ..color = _creamShadow
      ..strokeWidth = math.max(1, size.width * .012)
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final fingerAngle = angle + side * (i * .22);
      final start =
          center +
          Offset(math.cos(fingerAngle), math.sin(fingerAngle)) * radius * .55;
      final end =
          center +
          Offset(math.cos(fingerAngle), math.sin(fingerAngle)) * radius * 1.18;
      canvas.drawLine(start, end, fingerPaint);
    }
  }

  void _drawTorso(Canvas canvas, Size size, _FinPose pose) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromCenter(
      center: Offset(w * .5, h * .61),
      width: w * .49,
      height: h * .315,
    );
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(w * .18));
    canvas.drawRRect(
      shape.shift(Offset(0, h * .014)),
      Paint()
        ..color = _navy.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(shape, _shellPaint(rect));
    canvas.drawRRect(
      shape,
      Paint()
        ..color = Colors.white.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _drawHighlight(canvas, rect, .58);
    _drawChestEmblem(canvas, Offset(w * .5, h * .59), w * .105, pose.glow);
    _drawGoldNode(canvas, Offset(w * .37, h * .71), w * .024);
    _drawGoldNode(canvas, Offset(w * .63, h * .71), w * .024);
  }

  void _drawNeck(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .425),
      width: size.width * .19,
      height: size.height * .08,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(10)),
      _shellPaint(rect),
    );
    final collar = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .45),
      width: size.width * .24,
      height: size.height * .025,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(collar, const Radius.circular(6)),
      Paint()..color = _goldDark,
    );
  }

  void _drawHead(Canvas canvas, Size size, _FinPose pose) {
    final w = size.width;
    final h = size.height;
    final headBob =
        (state == FinCharacterState.listening ? _wave : 0) * h * .004;
    final rect = Rect.fromCenter(
      center: Offset(w * .5, h * .285 + headBob),
      width: w * .69,
      height: h * .29,
    );
    final head = RRect.fromRectAndRadius(rect, Radius.circular(w * .25));
    canvas.drawRRect(
      head.shift(Offset(0, h * .014)),
      Paint()
        ..color = _navy.withValues(alpha: .2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawRRect(head, _shellPaint(rect));
    canvas.drawRRect(
      head,
      Paint()
        ..color = Colors.white.withValues(alpha: .75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    _drawGoldNode(canvas, Offset(rect.left + w * .01, rect.center.dy), w * .06);
    _drawGoldNode(
      canvas,
      Offset(rect.right - w * .01, rect.center.dy),
      w * .06,
    );
    _drawVisor(canvas, size, rect, pose);
    _drawHighlight(canvas, rect, .72);
  }

  void _drawVisor(Canvas canvas, Size size, Rect headRect, _FinPose pose) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromCenter(
      center: Offset(w * .5, headRect.center.dy + h * .006),
      width: w * .53,
      height: h * .185,
    );
    final visor = RRect.fromRectAndRadius(rect, Radius.circular(w * .18));
    canvas.drawRRect(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13284D), _navy, Color(0xFF09101F)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      visor,
      Paint()
        ..color = _cyan.withValues(alpha: .13 * pose.glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final sheen = Path()
      ..moveTo(rect.left + w * .04, rect.top + h * .025)
      ..quadraticBezierTo(
        rect.center.dx,
        rect.top,
        rect.right - w * .05,
        rect.top + h * .045,
      )
      ..lineTo(rect.right - w * .08, rect.top + h * .07)
      ..quadraticBezierTo(
        rect.center.dx,
        rect.top + h * .035,
        rect.left + w * .05,
        rect.top + h * .06,
      )
      ..close();
    canvas.drawPath(
      sheen,
      Paint()..color = Colors.white.withValues(alpha: .14),
    );
    _drawEyes(canvas, size, rect, pose);
  }

  void _drawEyes(Canvas canvas, Size size, Rect visor, _FinPose pose) {
    final w = size.width;
    final h = size.height;
    final eyeY = visor.center.dy + h * .01;
    final spacing = w * .125;
    final blink = animationValue > .925 && animationValue < .965;
    final glow = Paint()
      ..color = _cyan.withValues(alpha: .38 * pose.glow)
      ..strokeWidth = w * .045
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final line = Paint()
      ..color = state == FinCharacterState.error
          ? const Color(0xFF72C7E8)
          : _cyan
      ..strokeWidth = math.max(1.6, w * .025)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final side in [-1.0, 1.0]) {
      final center = Offset(w * .5 + spacing * side, eyeY);
      final eye = Path();
      if (blink || state == FinCharacterState.error) {
        eye.moveTo(center.dx - w * .04, center.dy);
        eye.lineTo(center.dx + w * .04, center.dy);
      } else if (state == FinCharacterState.happy ||
          state == FinCharacterState.greeting ||
          state == FinCharacterState.celebrating) {
        eye.moveTo(center.dx - w * .045, center.dy + h * .008);
        eye.quadraticBezierTo(
          center.dx,
          center.dy - h * .028,
          center.dx + w * .045,
          center.dy + h * .008,
        );
      } else if (state == FinCharacterState.concerned) {
        eye.moveTo(center.dx - w * .045, center.dy - side * h * .008);
        eye.quadraticBezierTo(
          center.dx,
          center.dy + h * .018,
          center.dx + w * .045,
          center.dy + side * h * .008,
        );
      } else if (state == FinCharacterState.confused && side > 0) {
        eye.moveTo(center.dx - w * .042, center.dy + h * .005);
        eye.quadraticBezierTo(
          center.dx,
          center.dy - h * .024,
          center.dx + w * .042,
          center.dy + h * .005,
        );
      } else {
        final look = state == FinCharacterState.thinking
            ? Offset(w * .012, -h * .008)
            : Offset.zero;
        final r = Rect.fromCenter(
          center: center + look,
          width: w * (state == FinCharacterState.listening ? .09 : .075),
          height: h * (state == FinCharacterState.listening ? .055 : .045),
        );
        canvas.drawOval(
          r.inflate(w * .01),
          Paint()
            ..color = _cyan.withValues(alpha: .25 * pose.glow)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawOval(r, Paint()..color = _cyan);
        canvas.drawCircle(
          r.center - Offset(w * .012, h * .009),
          w * .008,
          Paint()..color = Colors.white.withValues(alpha: .9),
        );
        continue;
      }
      canvas.drawPath(eye, glow);
      canvas.drawPath(eye, line);
    }
  }

  void _drawSprout(Canvas canvas, Size size, _FinPose pose) {
    final w = size.width;
    final h = size.height;
    final base = Offset(w * .5, h * .13);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(_wave * .045 + pose.bodyTilt * .35);
    final stem = Paint()
      ..color = _goldDark
      ..strokeWidth = w * .027
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(0, h * .015)
        ..quadraticBezierTo(-w * .015, -h * .03, w * .006, -h * .07),
      stem,
    );
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE07A), _gold, _goldDark],
      ).createShader(Rect.fromLTWH(-w * .15, -h * .12, w * .3, h * .1));
    final left = Path()
      ..moveTo(0, -h * .05)
      ..quadraticBezierTo(-w * .12, -h * .115, -w * .14, -h * .065)
      ..quadraticBezierTo(-w * .08, -h * .03, 0, -h * .05)
      ..close();
    final right = Path()
      ..moveTo(0, -h * .05)
      ..quadraticBezierTo(w * .13, -h * .12, w * .15, -h * .07)
      ..quadraticBezierTo(w * .08, -h * .03, 0, -h * .05)
      ..close();
    canvas.drawPath(left, leafPaint);
    canvas.drawPath(right, leafPaint);
    canvas.drawCircle(Offset.zero, w * .026, Paint()..color = _gold);
    canvas.restore();
  }

  void _drawChestEmblem(
    Canvas canvas,
    Offset center,
    double radius,
    double glowLevel,
  ) {
    canvas.drawCircle(
      center,
      radius * 1.18,
      Paint()
        ..color = _gold.withValues(alpha: .22 * glowLevel)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE083), _gold, _goldDark],
        ).createShader(rect),
    );
    final growth = Path()
      ..moveTo(center.dx - radius * .52, center.dy + radius * .35)
      ..lineTo(center.dx - radius * .12, center.dy)
      ..lineTo(center.dx + radius * .12, center.dy + radius * .16)
      ..lineTo(center.dx + radius * .55, center.dy - radius * .46);
    canvas.drawPath(
      growth,
      Paint()
        ..color = Colors.white.withValues(alpha: .88)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * .2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawGoldNode(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center + const Offset(0, 1),
      radius * 1.08,
      Paint()..color = _goldDark.withValues(alpha: .38),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.4),
          colors: [Color(0xFFFFF0AA), _gold, _goldDark],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center - Offset(radius * .25, radius * .3),
      radius * .18,
      Paint()..color = Colors.white.withValues(alpha: .75),
    );
  }

  void _drawHighlight(Canvas canvas, Rect rect, double widthFactor) {
    final path = Path()
      ..moveTo(rect.left + rect.width * .18, rect.top + rect.height * .14)
      ..quadraticBezierTo(
        rect.center.dx,
        rect.top + rect.height * .02,
        rect.left + rect.width * widthFactor,
        rect.top + rect.height * .12,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCelebration(Canvas canvas, Size size) {
    final paint = Paint()..color = _gold.withValues(alpha: .85);
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * .43 + animationValue * .7;
      final center = Offset(
        size.width * .5 + math.cos(angle) * size.width * (.34 + i * .015),
        size.height * .33 + math.sin(angle) * size.height * .17,
      );
      final r = size.width * (i.isEven ? .018 : .012);
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy - r)
          ..lineTo(center.dx + r * .35, center.dy - r * .25)
          ..lineTo(center.dx + r, center.dy)
          ..lineTo(center.dx + r * .35, center.dy + r * .25)
          ..lineTo(center.dx, center.dy + r)
          ..lineTo(center.dx - r * .35, center.dy + r * .25)
          ..lineTo(center.dx - r, center.dy)
          ..lineTo(center.dx - r * .35, center.dy - r * .25)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FinPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.animationValue != animationValue;
}

class _FinPose {
  final double bodyTilt;
  final double leftShoulder;
  final double rightShoulder;
  final double leftElbow;
  final double rightElbow;
  final double glow;

  const _FinPose(
    this.bodyTilt,
    this.leftShoulder,
    this.rightShoulder,
    this.leftElbow,
    this.rightElbow,
    this.glow,
  );
}
