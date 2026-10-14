import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/fin_constants.dart';
import '../../../models/companion_model.dart';
import '../../../providers/analytics_provider.dart';
import 'fin_character.dart';

/// FinTrack 2.0 - Phase 5F FIN Companion Preferences Sheet
///
/// Gives users explicit control over FIN's memory:
/// - Preferred name with real-time greeting preview
/// - Response style (friendly, concise, detailed) with icon cards
/// - Smooth 2.5D animations toggle with reduced-motion awareness
/// - Personalized greetings toggle
/// - Safe memory reset with clear isolation guarantee
class CompanionPreferencesSheet extends StatefulWidget {
  const CompanionPreferencesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CompanionPreferencesSheet(),
    );
  }

  @override
  State<CompanionPreferencesSheet> createState() =>
      _CompanionPreferencesSheetState();
}

class _CompanionPreferencesSheetState extends State<CompanionPreferencesSheet> {
  late TextEditingController _nameController;
  late String _responseStyle;
  late bool _animationsEnabled;
  late bool _personalizedGreetings;
  late bool _showAcrossApp;
  late String _edgePosition;
  late bool _proactiveHints;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AnalyticsProvider>().companionPreferences;
    _nameController = TextEditingController(text: prefs.preferredName ?? '');
    _nameController.addListener(_onNameChanged);
    _responseStyle = prefs.responseStyle;
    _animationsEnabled = prefs.animationsEnabled;
    _personalizedGreetings = prefs.personalizedGreetings;
    _showAcrossApp = prefs.showAcrossApp;
    _edgePosition = prefs.edgePosition;
    _proactiveHints = prefs.proactiveHints;
  }

  void _onNameChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final provider = context.read<AnalyticsProvider>();
    final newPrefs = CompanionPreferences(
      preferredName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      responseStyle: _responseStyle,
      animationsEnabled: _animationsEnabled,
      personalizedGreetings: _personalizedGreetings,
      showAcrossApp: _showAcrossApp,
      edgePosition: _edgePosition,
      proactiveHints: _proactiveHints,
    );

    await provider.updateCompanionPreferences(newPrefs);

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("FIN companion preferences saved."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text("Reset FIN Memory?"),
          ],
        ),
        content: const Text(
          "This will clear your saved preferred name and reset FIN's style settings to default. Your financial records, accounts, and transactions are not affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Reset"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isSaving = true);
    final provider = context.read<AnalyticsProvider>();
    await provider.resetCompanionPreferences();

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("FIN memory and preferences have been cleared."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with mini FIN
              Row(
                children: [
                  const FinCharacter(
                    size: 46,
                    state: FinCharacterState.idle,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FIN Companion Settings",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Manage relationship memory and conversation style",
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // About FIN — Official Expanded Identity Information Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FinIdentity.fullExpansion,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            FinIdentity.tagline,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Preferred Name Field
              Text(
                "Preferred Name",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "How FIN should address you in greetings and financial insights.",
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "What should FIN call you? (optional)",
                  hintStyle:
                      TextStyle(fontSize: 13, color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              if (_nameController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Greeting Preview: "Hey ${_nameController.text.trim()}! Ready to inspect your finances?"',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Response Style
              Text(
                "Response Style",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Choose how concise or detailed FIN's explanations should be.",
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildStyleOption(
                    label: "Friendly",
                    value: "friendly",
                    description: "Warm & conversational",
                    icon: Icons.sentiment_satisfied_alt_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildStyleOption(
                    label: "Concise",
                    value: "concise",
                    description: "Direct & brief",
                    icon: Icons.bolt_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildStyleOption(
                    label: "Detailed",
                    value: "detailed",
                    description: "In-depth context",
                    icon: Icons.insights_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Toggles
              SwitchListTile.adaptive(
                title: Text(
                  "Smooth 2.5D Animations",
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                ),
                subtitle: Text(
                  "Enable FIN's floating, breathing, and eye expressions. Respects device reduced-motion settings.",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                value: _animationsEnabled,
                activeTrackColor: colors.primary.withValues(alpha: 0.5),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _animationsEnabled = val),
              ),

              SwitchListTile.adaptive(
                title: Text(
                  "Personalized Greetings",
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                ),
                subtitle: Text(
                  "Allow FIN to greet you by your preferred name when starting a conversation.",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                value: _personalizedGreetings,
                activeTrackColor: colors.primary.withValues(alpha: 0.5),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) =>
                    setState(() => _personalizedGreetings = val),
              ),

              const SizedBox(height: 10),

              // Companion App Presence Settings
              SwitchListTile.adaptive(
                title: Text(
                  "Show FIN Across the App",
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                ),
                subtitle: Text(
                  "Keep FIN peeking at the edge of your screen across your Dashboard, Activity, Budgets, and Reports.",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                value: _showAcrossApp,
                activeTrackColor: colors.primary.withValues(alpha: 0.5),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _showAcrossApp = val),
              ),

              if (_showAcrossApp) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Companion Edge Position",
                              style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Which side of the screen FIN should peek from.",
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ChoiceChip(
                        label: const Text("Right"),
                        selected: _edgePosition == 'right',
                        onSelected: (selected) {
                          if (selected) setState(() => _edgePosition = 'right');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Left"),
                        selected: _edgePosition == 'left',
                        onSelected: (selected) {
                          if (selected) setState(() => _edgePosition = 'left');
                        },
                      ),
                    ],
                  ),
                ),
              ],

              SwitchListTile.adaptive(
                title: Text(
                  "Proactive Hints & Guidance",
                  style: TextStyle(fontSize: 14, color: colors.textPrimary),
                ),
                subtitle: Text(
                  "Allow FIN to gently highlight verified budget alerts and milestones without intrusive popups.",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                value: _proactiveHints,
                activeTrackColor: colors.primary.withValues(alpha: 0.5),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _proactiveHints = val),
              ),

              const SizedBox(height: 16),

              // Privacy Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        FinIdentity.privacyNotice,
                        style: TextStyle(
                            fontSize: 11, color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _isSaving ? null : _handleReset,
                    icon: const Icon(Icons.delete_sweep_outlined,
                        size: 16, color: Colors.redAccent),
                    label: const Text(
                      "Clear Memory",
                      style: TextStyle(fontSize: 12, color: Colors.redAccent),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor:
                          colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text("Save Preferences",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleOption({
    required String label,
    required String value,
    required String description,
    required IconData icon,
  }) {
    final colors = AppColors.of(context);
    final isSelected = _responseStyle == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _responseStyle = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.15)
                : colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.cardBorder,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
