import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../models/companion_model.dart';

/// 5E.3 — FIN Premium 2.5D Animated Character
///
/// Locally rendered, lightweight, expressive financial companion.
/// Features:
/// - Rounded champagne/cream shell with soft 2.5D shading and specular highlights
/// - Glossy dark-navy face display with glass sheen
/// - Luminous cyan/blue digital eyes dynamically adapting to 10 character states
/// - Gold growth-leaf sprout on top of head with subtle sway
/// - Gold financial chest emblem and ear node accents
/// - Smooth native floating, breathing, and blinking animations
/// - Respects reduced-motion accessibility settings and widget disposal
class FinCharacter extends StatefulWidget {
  final FinCharacterState state;
  final double size;
  final bool? animationsEnabled;
  final bool allowAnimationInTests;
  final VoidCallback? onTap;

  const FinCharacter({
    super.key,
    this.state = FinCharacterState.idle,
    this.size = 100.0,
    this.animationsEnabled,
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
      duration: const Duration(milliseconds: 3200),
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

  void _syncAnimationState() {
    final systemDisableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool isTestEnv =
        WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
    final bool enableMotion = (widget.animationsEnabled ?? true) &&
        !systemDisableAnimations &&
        (!isTestEnv || widget.allowAnimationInTests);

    if (enableMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect system reduced-motion or user preference
    final systemDisableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final bool enableMotion =
        (widget.animationsEnabled ?? true) && !systemDisableAnimations;

    Widget characterWidget = CustomPaint(
      size: Size(widget.size, widget.size * 1.15),
      painter: _FinPainter(
        state: widget.state,
        animationValue: enableMotion ? _controller.value : 0.0,
      ),
    );

    if (enableMotion) {
      characterWidget = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size * 1.15),
            painter: _FinPainter(
              state: widget.state,
              animationValue: _controller.value,
            ),
          );
        },
      );
    }

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: characterWidget,
      );
    }

    return Semantics(
      label: 'FIN Financial Companion, currently ${widget.state.label}',
      child: characterWidget,
    );
  }
}

class _FinPainter extends CustomPainter {
  final FinCharacterState state;
  final double animationValue;

  _FinPainter({
    required this.state,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Center coordinates
    final double cx = w * 0.5;
    final double cy = h * 0.52;

    // Motion parameters
    final double floatOffset = math.sin(animationValue * 2 * math.pi) * (h * 0.035);
    final double breathScale = 1.0 + math.sin(animationValue * 2 * math.pi) * 0.015;
    final double sproutSway = math.sin(animationValue * 2 * math.pi) * 0.08;

    // State-based adjustments
    double stateTilt = 0.0;
    double verticalShift = floatOffset;

    switch (state) {
      case FinCharacterState.greeting:
        stateTilt = -0.06;
        verticalShift -= h * 0.02;
        break;
      case FinCharacterState.listening:
        stateTilt = 0.04;
        break;
      case FinCharacterState.thinking:
        stateTilt = 0.07;
        break;
      case FinCharacterState.celebrating:
        verticalShift += math.sin(animationValue * 6 * math.pi).abs() * -(h * 0.05);
        break;
      case FinCharacterState.concerned:
        verticalShift += h * 0.015;
        break;
      case FinCharacterState.confused:
        stateTilt = -0.09;
        break;
      default:
        break;
    }

    canvas.save();

    // 1. Shadow underneath character
    _paintShadow(canvas, cx, h * 0.95, w * 0.32 * breathScale, h * 0.08 * breathScale, floatOffset);

    // Apply floating and tilt transform
    canvas.translate(cx, cy + verticalShift);
    canvas.rotate(stateTilt);
    canvas.scale(breathScale, breathScale);
    canvas.translate(-cx, -cy);

    // 2. Ear Nodes (gold side accents)
    _paintEarNodes(canvas, cx, cy, w, h);

    // 3. Main Champagne Body Shell
    _paintBodyShell(canvas, cx, cy, w, h);

    // 4. Gold Head Sprout (growth-leaf)
    _paintSprout(canvas, cx, cy - (h * 0.36), w, h, sproutSway);

    // 5. Glossy Navy Face Display
    _paintFaceVisor(canvas, cx, cy - (h * 0.06), w, h);

    // 6. Luminous Cyan Digital Eyes
    _paintEyes(canvas, cx, cy - (h * 0.06), w, h);

    // 7. Gold Chest Emblem (growth leaf badge)
    _paintChestEmblem(canvas, cx, cy + (h * 0.22), w, h);

    // 8. Celebration Sparkles (if celebrating)
    if (state == FinCharacterState.celebrating) {
      _paintCelebrationSparkles(canvas, cx, cy, w, h);
    }

    canvas.restore();
  }

  void _paintShadow(Canvas canvas, double cx, double cy, double rx, double ry, double floatOffset) {
    final shadowOpacity = (0.24 - (floatOffset / 120.0)).clamp(0.08, 0.35);
    final paint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: shadowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      paint,
    );
  }

  void _paintEarNodes(Canvas canvas, double cx, double cy, double w, double h) {
    final earY = cy - (h * 0.06);
    final earW = w * 0.1;
    final earH = h * 0.18;

    final goldEarGradient = const LinearGradient(
      colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFD97706)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final earPaint = Paint();

    // Left ear
    final leftRect = Rect.fromCenter(center: Offset(cx - (w * 0.41), earY), width: earW, height: earH);
    earPaint.shader = goldEarGradient.createShader(leftRect);
    canvas.drawRRect(RRect.fromRectAndRadius(leftRect, Radius.circular(earW * 0.5)), earPaint);

    // Right ear
    final rightRect = Rect.fromCenter(center: Offset(cx + (w * 0.41), earY), width: earW, height: earH);
    earPaint.shader = goldEarGradient.createShader(rightRect);
    canvas.drawRRect(RRect.fromRectAndRadius(rightRect, Radius.circular(earW * 0.5)), earPaint);
  }

  void _paintBodyShell(Canvas canvas, double cx, double cy, double w, double h) {
    final bodyRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: w * 0.78,
      height: h * 0.72,
    );
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.36));

    // Outer subtle ambient shadow
    final shellShadowPaint = Paint()
      ..color = const Color(0xFFD7CCC8).withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(bodyRRect.shift(const Offset(0, 4)), shellShadowPaint);

    // 2.5D Champagne / Cream gradient fill
    final shellGradient = const LinearGradient(
      colors: [
        Color(0xFFFFFFFF), // Top highlight
        Color(0xFFFDFBF7), // Warm champagne upper
        Color(0xFFF7F2E7), // Soft cream mid
        Color(0xFFEBE2D0), // Warm beige lower
        Color(0xFFDECDB4), // Subtle bottom ambient shadow
      ],
      stops: [0.0, 0.25, 0.6, 0.88, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final bodyPaint = Paint()
      ..shader = shellGradient.createShader(bodyRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRRect, bodyPaint);

    // Smooth soft rim highlight
    final rimPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(bodyRRect, rimPaint);

    // Top head gloss curve
    final headGlossRect = Rect.fromCenter(
      center: Offset(cx - (w * 0.08), cy - (h * 0.26)),
      width: w * 0.48,
      height: h * 0.12,
    );
    final headGlossPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(headGlossRect);
    canvas.drawOval(headGlossRect, headGlossPaint);
  }

  void _paintSprout(Canvas canvas, double cx, double cy, double w, double h, double sway) {
    canvas.save();
    canvas.translate(cx, cy + 4);
    canvas.rotate(sway);

    // Gold Sprout Stem
    final stemPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.035;

    final stemPath = Path();
    stemPath.moveTo(0, 0);
    stemPath.quadraticBezierTo(-w * 0.02, -h * 0.05, 0, -h * 0.09);
    canvas.drawPath(stemPath, stemPaint);

    // Left gold financial growth leaf
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(-w * 0.12, -h * 0.16, w * 0.14, h * 0.09))
      ..style = PaintingStyle.fill;

    final leftLeafPath = Path();
    leftLeafPath.moveTo(0, -h * 0.08);
    leftLeafPath.quadraticBezierTo(-w * 0.09, -h * 0.14, -w * 0.12, -h * 0.09);
    leftLeafPath.quadraticBezierTo(-w * 0.07, -h * 0.06, 0, -h * 0.08);
    canvas.drawPath(leftLeafPath, leafPaint);

    // Right gold financial growth leaf (slightly larger)
    final rightLeafPath = Path();
    rightLeafPath.moveTo(0, -h * 0.08);
    rightLeafPath.quadraticBezierTo(w * 0.11, -h * 0.15, w * 0.13, -h * 0.10);
    rightLeafPath.quadraticBezierTo(w * 0.08, -h * 0.06, 0, -h * 0.08);
    canvas.drawPath(rightLeafPath, leafPaint);

    // Gold seed node at base
    final nodePaint = Paint()..color = const Color(0xFFFFD54F);
    canvas.drawCircle(Offset.zero, w * 0.028, nodePaint);

    canvas.restore();
  }

  void _paintFaceVisor(Canvas canvas, double cx, double cy, double w, double h) {
    final visorRect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: w * 0.58,
      height: h * 0.36,
    );
    final visorRRect = RRect.fromRectAndRadius(visorRect, Radius.circular(w * 0.18));

    // Deep glossy dark-navy visor
    final visorGradient = const LinearGradient(
      colors: [
        Color(0xFF070D1E),
        Color(0xFF0B132B),
        Color(0xFF131D38),
        Color(0xFF0A1024),
      ],
      stops: [0.0, 0.35, 0.75, 1.0],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final visorPaint = Paint()
      ..shader = visorGradient.createShader(visorRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(visorRRect, visorPaint);

    // Subtle dark inner stroke
    final visorBorderPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(visorRRect, visorBorderPaint);

    // Visor glass sheen highlight (curved diagonal glint)
    final sheenPath = Path();
    sheenPath.moveTo(cx - (w * 0.25), cy - (h * 0.14));
    sheenPath.quadraticBezierTo(cx - (w * 0.05), cy - (h * 0.14), cx + (w * 0.16), cy - (h * 0.06));
    sheenPath.lineTo(cx + (w * 0.10), cy - (h * 0.03));
    sheenPath.quadraticBezierTo(cx - (w * 0.10), cy - (h * 0.10), cx - (w * 0.25), cy - (h * 0.09));
    sheenPath.close();

    final sheenPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(visorRect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(sheenPath, sheenPaint);
  }

  void _paintEyes(Canvas canvas, double cx, double cy, double w, double h) {
    final eyeSpacing = w * 0.15;
    final eyeY = cy;
    final eyeW = w * 0.10;
    final eyeH = h * 0.12;

    // Blink calculation for idle / listening / explaining
    bool isBlinking = false;
    if (state == FinCharacterState.idle ||
        state == FinCharacterState.listening ||
        state == FinCharacterState.explaining) {
      final double cycleTime = animationValue % 1.0;
      // Blink between 0.92 and 0.98 of animation cycle
      if (cycleTime > 0.92 && cycleTime < 0.98) {
        isBlinking = true;
      }
    }

    final eyeGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final eyePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF0284C7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: eyeSpacing * 2, height: eyeH))
      ..style = PaintingStyle.fill;

    // Render left and right eyes based on character state
    switch (state) {
      case FinCharacterState.greeting:
      case FinCharacterState.happy:
      case FinCharacterState.celebrating:
        // Cheerful curved crescent eyes (^ ^)
        _drawCurvedEye(canvas, cx - eyeSpacing, eyeY, eyeW, eyeH, true);
        _drawCurvedEye(canvas, cx + eyeSpacing, eyeY, eyeW, eyeH, true);
        break;

      case FinCharacterState.concerned:
        // Gentle sympathetic slightly downward slanted soft eyes
        _drawConcernedEye(canvas, cx - eyeSpacing, eyeY, eyeW, eyeH, false);
        _drawConcernedEye(canvas, cx + eyeSpacing, eyeY, eyeW, eyeH, true);
        break;

      case FinCharacterState.confused:
        // Curious asymmetric eyes (one inquisitive round, one slightly raised)
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY - 2), width: eyeW * 1.15, height: eyeH * 1.15),
          eyeGlowPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY - 2), width: eyeW * 1.15, height: eyeH * 1.15),
          eyePaint,
        );
        _drawCurvedEye(canvas, cx + eyeSpacing, eyeY + 1, eyeW * 0.9, eyeH * 0.8, true);
        break;

      case FinCharacterState.thinking:
        // Thoughtful upward-tilted glowing gaze with soft pulse
        final pulse = 0.85 + (math.sin(animationValue * 4 * math.pi) * 0.15);
        final thinkPaint = Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFF38BDF8), Color(0xFF0284C7)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: eyeSpacing * 2, height: eyeH))
          ..style = PaintingStyle.fill;

        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - eyeSpacing + 2, eyeY - 3), width: eyeW * pulse, height: eyeH * 0.9),
          thinkPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + eyeSpacing + 2, eyeY - 3), width: eyeW * pulse, height: eyeH * 0.9),
          thinkPaint,
        );
        break;

      case FinCharacterState.error:
        // Reassuring soft horizontal pill eyes
        final errorPaint = Paint()
          ..color = const Color(0xFF38BDF8)
          ..style = PaintingStyle.fill;
        final leftRect = Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY), width: eyeW * 1.05, height: eyeH * 0.35);
        final rightRect = Rect.fromCenter(center: Offset(cx + eyeSpacing, eyeY), width: eyeW * 1.05, height: eyeH * 0.35);
        canvas.drawRRect(RRect.fromRectAndRadius(leftRect, const Radius.circular(3)), errorPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(rightRect, const Radius.circular(3)), errorPaint);
        break;

      case FinCharacterState.listening:
        // Wider attentive open circular eyes
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY), width: eyeW * 1.2, height: eyeH * 1.2),
          eyeGlowPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + eyeSpacing, eyeY), width: eyeW * 1.2, height: eyeH * 1.2),
          eyeGlowPaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY), width: eyeW * 1.2, height: eyeH * 1.2),
          eyePaint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx + eyeSpacing, eyeY), width: eyeW * 1.2, height: eyeH * 1.2),
          eyePaint,
        );
        break;

      case FinCharacterState.idle:
      case FinCharacterState.explaining:
        if (isBlinking) {
          // Closed eyelid line
          final blinkPaint = Paint()
            ..color = const Color(0xFF00E5FF)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(
            Offset(cx - eyeSpacing - (eyeW * 0.5), eyeY),
            Offset(cx - eyeSpacing + (eyeW * 0.5), eyeY),
            blinkPaint,
          );
          canvas.drawLine(
            Offset(cx + eyeSpacing - (eyeW * 0.5), eyeY),
            Offset(cx + eyeSpacing + (eyeW * 0.5), eyeY),
            blinkPaint,
          );
        } else {
          // Luminous rounded oval eyes
          final leftRect = Rect.fromCenter(center: Offset(cx - eyeSpacing, eyeY), width: eyeW, height: eyeH);
          final rightRect = Rect.fromCenter(center: Offset(cx + eyeSpacing, eyeY), width: eyeW, height: eyeH);

          canvas.drawOval(leftRect, eyeGlowPaint);
          canvas.drawOval(rightRect, eyeGlowPaint);
          canvas.drawOval(leftRect, eyePaint);
          canvas.drawOval(rightRect, eyePaint);

          // Tiny specular eye glints
          final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
          canvas.drawCircle(Offset(cx - eyeSpacing - 2, eyeY - 3), 1.8, glintPaint);
          canvas.drawCircle(Offset(cx + eyeSpacing - 2, eyeY - 3), 1.8, glintPaint);
        }
        break;
    }
  }

  void _drawCurvedEye(Canvas canvas, double ex, double ey, double ew, double eh, bool isSmile) {
    final arcPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.35)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    path.moveTo(ex - (ew * 0.55), ey + (eh * 0.1));
    path.quadraticBezierTo(ex, ey - (eh * 0.5), ex + (ew * 0.55), ey + (eh * 0.1));

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, arcPaint);
  }

  void _drawConcernedEye(Canvas canvas, double ex, double ey, double ew, double eh, bool isRight) {
    final eyePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isRight) {
      path.moveTo(ex - (ew * 0.5), ey - (eh * 0.2));
      path.quadraticBezierTo(ex, ey + (eh * 0.2), ex + (ew * 0.5), ey + (eh * 0.1));
    } else {
      path.moveTo(ex - (ew * 0.5), ey + (eh * 0.1));
      path.quadraticBezierTo(ex, ey + (eh * 0.2), ex + (ew * 0.5), ey - (eh * 0.2));
    }
    canvas.drawPath(path, eyePaint);
  }

  void _paintChestEmblem(Canvas canvas, double cx, double cy, double w, double h) {
    // Subtle circular gold recess on torso
    final badgeRadius = w * 0.085;
    final badgeRect = Rect.fromCircle(center: Offset(cx, cy), radius: badgeRadius);

    final badgePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(badgeRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx, cy), badgeRadius, badgePaint);

    // Embossed financial leaf inside badge
    final leafPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final leafPath = Path();
    leafPath.moveTo(cx, cy - (badgeRadius * 0.6));
    leafPath.quadraticBezierTo(cx + (badgeRadius * 0.6), cy, cx, cy + (badgeRadius * 0.6));
    leafPath.quadraticBezierTo(cx - (badgeRadius * 0.6), cy, cx, cy - (badgeRadius * 0.6));
    canvas.drawPath(leafPath, leafPaint);
  }

  void _paintCelebrationSparkles(Canvas canvas, double cx, double cy, double w, double h) {
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Small star sparkles near head
    _drawStar(canvas, cx - (w * 0.38), cy - (h * 0.32), w * 0.035, sparklePaint);
    _drawStar(canvas, cx + (w * 0.38), cy - (h * 0.28), w * 0.045, sparklePaint);
  }

  void _drawStar(Canvas canvas, double sx, double sy, double r, Paint paint) {
    final path = Path();
    path.moveTo(sx, sy - r);
    path.quadraticBezierTo(sx, sy, sx + r, sy);
    path.quadraticBezierTo(sx, sy, sx, sy + r);
    path.quadraticBezierTo(sx, sy, sx - r, sy);
    path.quadraticBezierTo(sx, sy, sx, sy - r);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FinPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.animationValue != animationValue;
  }
}
