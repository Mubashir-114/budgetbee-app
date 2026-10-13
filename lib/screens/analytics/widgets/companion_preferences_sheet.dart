import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/companion_model.dart';
import '../../../providers/analytics_provider.dart';
import 'fin_character.dart';

/// 5E.2 — Persistent Relationship Preferences Sheet
///
/// Gives users explicit control over FIN's memory:
/// - Preferred name
/// - Response style (friendly, concise, detailed)
/// - Animations toggle
/// - Personalized greetings toggle
/// - Reset/clear preferences
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prefs = context.read<AnalyticsProvider>().companionPreferences;
    _nameController = TextEditingController(text: prefs.preferredName ?? '');
    _responseStyle = prefs.responseStyle;
    _animationsEnabled = prefs.animationsEnabled;
    _personalizedGreetings = prefs.personalizedGreetings;
  }

  @override
  void dispose() {
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
        title: const Text("Reset FIN Memory?"),
        content: const Text(
          "This will clear your saved preferred name and reset FIN's style settings to default. Your financial records are not affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
                  size: 44,
                  state: FinCharacterState.idle,
                ),
                const SizedBox(width: 12),
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

            const SizedBox(height: 20),

            // Preferred Name Field
            Text(
              "Preferred Name",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: "What should FIN call you? (optional)",
                hintStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
                filled: true,
                fillColor: colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.cardBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // Response Style
            Text(
              "Response Style",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStyleOption(
                  label: "Friendly",
                  value: "friendly",
                  description: "Warm & conversational",
                ),
                const SizedBox(width: 8),
                _buildStyleOption(
                  label: "Concise",
                  value: "concise",
                  description: "Direct & brief",
                ),
                const SizedBox(width: 8),
                _buildStyleOption(
                  label: "Detailed",
                  value: "detailed",
                  description: "In-depth context",
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Toggles
            SwitchListTile.adaptive(
              title: Text(
                "Smooth 2.5D Animations",
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
              ),
              subtitle: Text(
                "Enable FIN's floating, breathing, and eye expressions",
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
                "Allow FIN to greet you by your preferred name",
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              value: _personalizedGreetings,
              activeTrackColor: colors.primary.withValues(alpha: 0.5),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _personalizedGreetings = val),
            ),

            const SizedBox(height: 16),

            // Privacy Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "FIN stores only these style preferences and preferred name. Full chat transcripts and sensitive financial secrets are never stored.",
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isSaving ? null : _handleReset,
                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.redAccent),
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
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("Save Preferences", style: TextStyle(fontWeight: FontWeight.bold)),
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
  }) {
    final colors = AppColors.of(context);
    final isSelected = _responseStyle == value;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _responseStyle = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.15)
                : colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colors.primary : colors.cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
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
