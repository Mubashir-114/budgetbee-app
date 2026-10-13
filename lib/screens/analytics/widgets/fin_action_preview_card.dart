import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/companion_model.dart';
import '../../../providers/analytics_provider.dart';

/// 5E.4 — FIN Action Preview & Explicit Confirmation Card
///
/// Presents safe previews of user-authorized actions (e.g. goal creation, budget updates)
/// with parameter summaries, financial impact, and explicit confirmation requirements.
class FinActionPreviewCard extends StatefulWidget {
  final FinActionPreview actionPreview;
  final VoidCallback? onDismiss;

  const FinActionPreviewCard({
    super.key,
    required this.actionPreview,
    this.onDismiss,
  });

  @override
  State<FinActionPreviewCard> createState() => _FinActionPreviewCardState();
}

class _FinActionPreviewCardState extends State<FinActionPreviewCard> {
  bool _isConfirming = false;
  String? _executionResult;
  bool _isSuccess = false;
  bool _isDismissed = false;

  Future<void> _handleConfirm() async {
    setState(() {
      _isConfirming = true;
    });

    final provider = context.read<AnalyticsProvider>();
    final success = await provider.confirmPendingAction(widget.actionPreview);

    if (!mounted) return;

    setState(() {
      _isConfirming = false;
      _isSuccess = success;
      _executionResult = success
          ? (provider.actionSuccessMessage ??
                "Action confirmed and executed successfully.")
          : (provider.errorMessage ?? "Action failed. Please try again.");
    });
  }

  void _handleDismiss() {
    setState(() {
      _isDismissed = true;
    });
    if (widget.onDismiss != null) {
      widget.onDismiss!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final preview = widget.actionPreview;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSuccess
              ? colors.success.withValues(alpha: 0.6)
              : colors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Action Type Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_calendar_rounded,
                  size: 16,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      "FIN Prepared Action • Requires Your Authorization",
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSuccess)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: colors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Confirmed",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            preview.summary,
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              height: 1.35,
            ),
          ),

          // Parameter Key-Values
          if (preview.parameters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                children: preview.parameters.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatParamKey(entry.key),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            entry.value?.toString() ?? "-",
                            textAlign: TextAlign.end,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Financial Impact Note
          if (preview.impactNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    preview.impactNote,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Execution result status message
          if (_executionResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? colors.success.withValues(alpha: 0.12)
                    : colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    size: 16,
                    color: _isSuccess ? colors.success : colors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _executionResult!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _isSuccess ? colors.success : colors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Confirmation Buttons (shown only if not yet successfully executed)
          if (!_isSuccess) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isConfirming ? null : _handleDismiss,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: colors.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.isDark
                          ? Colors.black
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 16),
                              SizedBox(width: 6),
                              Text(
                                "Confirm & Save",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatParamKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }
}
