import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/analytics_provider.dart';
import 'fin_character.dart';
import 'fin_visual_controller.dart';

/// FinTrack 2.0 — Global Persistent FIN Peeking Character Overlay
///
/// Implemented at the authenticated shell layer (`MainNavigationScreen`).
/// - Peeks out from the screen edge (right or left) with bezel-gripping gesture
/// - Eyes observant of current screen content, gentle breathing and leaf motion
/// - Smoothly emerges when tapped, offering warm greeting and functional actions
/// - Keyboard-aware: gracefully hides when typing
/// - Suppressed when full conversation screen (/analytics) is open to avoid duplicates
/// - Reduced-motion compliant, 60 FPS targeted
class GlobalFinOverlay extends StatefulWidget {
  const GlobalFinOverlay({super.key});

  @override
  State<GlobalFinOverlay> createState() => _GlobalFinOverlayState();
}

class _GlobalFinOverlayState extends State<GlobalFinOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _emergenceController;
  late final Animation<double> _emergenceAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _emergenceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _emergenceAnimation = CurvedAnimation(
      parent: _emergenceController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _emergenceController.dispose();
    super.dispose();
  }

  void _toggleEmergence(FinVisualController controller) {
    final media = MediaQuery.maybeOf(context);
    final disableAnimations = media?.disableAnimations ?? false;

    if (_isExpanded) {
      if (disableAnimations) {
        _emergenceController.value = 0.0;
      } else {
        _emergenceController.reverse();
      }
      controller.onIdle();
      setState(() => _isExpanded = false);
    } else {
      controller.onGreeting();
      if (disableAnimations) {
        _emergenceController.value = 1.0;
      } else {
        _emergenceController.forward();
      }
      setState(() => _isExpanded = true);
    }
  }

  void _collapse(FinVisualController controller) {
    if (!_isExpanded) return;
    final media = MediaQuery.maybeOf(context);
    final disableAnimations = media?.disableAnimations ?? false;
    if (disableAnimations) {
      _emergenceController.value = 0.0;
    } else {
      _emergenceController.reverse();
    }
    controller.onIdle();
    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final prefs = provider.companionPreferences;
    final visualController = provider.visualController;
    final colors = AppColors.of(context);
    final media = MediaQuery.of(context);

    // 1. Hide if disabled by user settings
    if (!prefs.showAcrossApp) {
      return const SizedBox.shrink();
    }

    // 2. Hide when on full companion conversation screen (/analytics) to avoid duplicate FIN
    final location = GoRouterState.of(context).matchedLocation;
    if (visualController.isFullCompanionOpen ||
        location.contains('analytics') ||
        location.startsWith('/analytics')) {
      return const SizedBox.shrink();
    }

    // 3. Keyboard awareness: if keyboard is open, collapse and hide out of sight
    final isKeyboardVisible = media.viewInsets.bottom > 50;
    if (isKeyboardVisible && _isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _collapse(visualController);
      });
    }

    final isLeftEdge = prefs.edgePosition.toLowerCase().trim() == 'left';
    final screenHeight = media.size.height;
    final topPosition = screenHeight * 0.40;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Dismiss backdrop when expanded
        if (_isExpanded)
          GestureDetector(
            key: const ValueKey('global_fin_backdrop'),
            onTap: () => _collapse(visualController),
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),

        // Animated Peeking Character & Emergence Panel
        AnimatedBuilder(
          animation: _emergenceAnimation,
          builder: (context, _) {
            final progress = _emergenceAnimation.value;
            // When keyboard is visible, slide character off-screen behind the edge
            final keyboardSlide = isKeyboardVisible ? 100.0 : 0.0;

            final characterWidth = 98.0;
            final characterHeight = 106.0;

            // Character positioning
            // Idle peeking: sits partially behind bezel, visible footprint ~54px
            // Fully emerged: steps out into the screen
            final peekingTuck = (1.0 - progress) * (characterWidth * 0.44);

            final rightPos = isLeftEdge
                ? null
                : (keyboardSlide - peekingTuck);
            final leftPos = isLeftEdge
                ? (keyboardSlide - peekingTuck)
                : null;

            return Positioned(
              top: topPosition,
              right: rightPos,
              left: leftPos,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isKeyboardVisible ? 0.0 : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isLeftEdge && progress > 0.05)
                      _buildEmergencePanel(
                        context,
                        colors,
                        provider,
                        visualController,
                        progress,
                        isLeftEdge,
                      ),

                    // Peeking FIN Character Widget
                    Semantics(
                      button: true,
                      label: _isExpanded ? 'Dismiss FIN companion' : 'Meet FIN companion',
                      child: GestureDetector(
                        key: const ValueKey('global_fin_peeking_character'),
                        onTap: () => _toggleEmergence(visualController),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: characterWidth,
                          height: characterHeight,
                          alignment: isLeftEdge ? Alignment.centerLeft : Alignment.centerRight,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Character Aura Glow when emerging
                              if (progress > 0.1)
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF41E5F2)
                                            .withValues(alpha: 0.28 * progress),
                                        blurRadius: 22,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),

                              FinCharacter(
                                size: 96,
                                state: visualController.state,
                                controller: visualController,
                                isPeeking: true,
                                peekingOnLeft: isLeftEdge,
                                peekProgress: progress,
                                animationsEnabled: prefs.animationsEnabled,
                              ),

                              // Quick status pill when peeking with speech bubble
                              if (visualController.speechBubbleText != null &&
                                  visualController.speechBubbleText!.isNotEmpty &&
                                  progress < 0.2)
                                Positioned(
                                  top: 0,
                                  right: isLeftEdge ? null : 40,
                                  left: isLeftEdge ? 40 : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF07142D),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF41E5F2).withValues(alpha: 0.6),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      visualController.speechBubbleText!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (isLeftEdge && progress > 0.05)
                      _buildEmergencePanel(
                        context,
                        colors,
                        provider,
                        visualController,
                        progress,
                        isLeftEdge,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmergencePanel(
    BuildContext context,
    dynamic colors,
    AnalyticsProvider provider,
    FinVisualController visualController,
    double progress,
    bool isLeftEdge,
  ) {
    final prefs = provider.companionPreferences;
    final preferredName = prefs.preferredName?.trim();
    final greetingText = (preferredName != null && preferredName.isNotEmpty)
        ? "Hi, $preferredName! I'm FIN."
        : "Hi! I'm FIN, your companion.";

    // Active alert hint if present
    String? alertHint;
    if (provider.activeAlerts.isNotEmpty) {
      alertHint = provider.activeAlerts.first.title;
    }

    return FadeTransition(
      opacity: _emergenceAnimation,
      child: Transform.scale(
        scale: 0.85 + (progress * 0.15),
        alignment: isLeftEdge ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          key: const ValueKey('global_fin_action_panel'),
          width: 245,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1329),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF41E5F2).withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF41E5F2).withValues(alpha: 0.12),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Identity & Status Pill & Close
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF41E5F2).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF41E5F2).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF06D6A0),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "FIN is here",
                          style: TextStyle(
                            color: Color(0xFF41E5F2),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Switch edge toggle button
                  InkWell(
                    key: const ValueKey('global_fin_edge_switch'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      final newEdge = isLeftEdge ? 'right' : 'left';
                      provider.updateCompanionPreferences(
                        prefs.copyWith(edgePosition: newEdge),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isLeftEdge
                            ? Icons.arrow_forward_ios_rounded
                            : Icons.arrow_back_ios_new_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Close button
                  InkWell(
                    key: const ValueKey('global_fin_action_close'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _collapse(visualController),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Warm Greeting & Contextual Prompt
              Text(
                greetingText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                alertHint != null
                    ? "Alert: $alertHint"
                    : "Ready to explore your money story or check budgets?",
                style: TextStyle(
                  color: alertHint != null
                      ? const Color(0xFFF4B942)
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFF1E2D4D)),
              const SizedBox(height: 10),

              // Action Buttons
              _buildActionButton(
                key: const ValueKey('global_fin_action_talk'),
                icon: Icons.chat_bubble_outline_rounded,
                label: "Talk to FIN",
                accentColor: const Color(0xFF41E5F2),
                onTap: () {
                  _collapse(visualController);
                  context.push('/analytics');
                },
              ),
              const SizedBox(height: 6),
              _buildActionButton(
                key: const ValueKey('global_fin_action_spending'),
                icon: Icons.pie_chart_outline_rounded,
                label: "My spending",
                accentColor: const Color(0xFFF4B942),
                onTap: () {
                  _collapse(visualController);
                  context.push('/analytics?q=How much did I spend this month?');
                },
              ),
              const SizedBox(height: 6),
              _buildActionButton(
                key: const ValueKey('global_fin_action_budget'),
                icon: Icons.account_balance_wallet_outlined,
                label: "Budget check",
                accentColor: const Color(0xFF06D6A0),
                onTap: () {
                  _collapse(visualController);
                  context.go('/budgets');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required Key key,
    required IconData icon,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFF13203C),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
