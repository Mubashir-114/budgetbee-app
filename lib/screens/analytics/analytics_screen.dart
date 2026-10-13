import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/analytics_model.dart';
import '../../providers/analytics_provider.dart';
import 'widgets/alert_preferences_sheet.dart';
import 'widgets/companion_preferences_sheet.dart';
import 'widgets/fin_action_preview_card.dart';
import 'widgets/fin_character.dart';
import 'widgets/insights_feed_view.dart';

class AnalyticsScreen extends StatefulWidget {
  final String? initialQuestion;

  const AnalyticsScreen({super.key, this.initialQuestion});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isFinHeroVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateFinVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.prepareForScreenEntry();
      provider.loadCapabilities();
      provider.loadInsights();
      provider.loadCompanionPreferences();
      provider.initializeAlertPreferences().then((_) {
        provider.loadAlerts();
      });
      if (widget.initialQuestion != null &&
          widget.initialQuestion!.trim().isNotEmpty) {
        _submitQuestion(widget.initialQuestion!.trim());
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    _scrollController
      ..removeListener(_updateFinVisibility)
      ..dispose();
    super.dispose();
  }

  void _updateFinVisibility() {
    final visible =
        !_scrollController.hasClients || _scrollController.offset < 280;
    if (visible != _isFinHeroVisible && mounted) {
      setState(() => _isFinHeroVisible = visible);
    }
  }

  void _submitQuestion(String text) {
    if (text.trim().isEmpty) return;
    _focusNode.unfocus();
    _questionController.clear();
    context.read<AnalyticsProvider>().askQuestion(text);
  }

  void _selectSuggestedQuestion(SuggestedQuestion suggestion) {
    _submitQuestion(suggestion.question);
  }

  void _showPrivacyDialog() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final media = MediaQuery.of(context);
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * .9),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + media.viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Privacy & Isolation Guarantee",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            "FinTrack 2.0 — Phase 5E FIN Companion",
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
                _buildPrivacyPoint(
                  colors,
                  Icons.check_circle_outline,
                  "Saved records only",
                  "Analyzes exclusively transactions explicitly saved and owned by your account.",
                ),
                const SizedBox(height: 12),
                _buildPrivacyPoint(
                  colors,
                  Icons.block_outlined,
                  "No bank connections",
                  "Zero capability to connect to bank accounts, open-banking APIs, or institutional credentials.",
                ),
                const SizedBox(height: 12),
                _buildPrivacyPoint(
                  colors,
                  Icons.speaker_notes_off_outlined,
                  "No SMS inbox reading",
                  "Cannot read device messages, SMS permissions, or unsaved staging candidates.",
                ),
                const SizedBox(height: 12),
                _buildPrivacyPoint(
                  colors,
                  Icons.lock_outline,
                  "Deterministic local AI",
                  "Calculations use exact mathematical formulas and safe templates. No external LLM providers.",
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.isDark
                          ? Colors.black
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Understood",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyPoint(
    dynamic colors,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: colors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "AI Financial Insights",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: "FIN Settings & Memory",
            icon: Icon(Icons.tune_rounded, color: colors.textSecondary),
            onSelected: (value) {
              if (value == 'companion') {
                CompanionPreferencesSheet.show(context);
              } else if (value == 'alerts') {
                AlertPreferencesSheet.show(context);
              } else if (value == 'reset') {
                provider.clearConversation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'companion',
                child: ListTile(
                  leading: Icon(Icons.face_retouching_natural_rounded),
                  title: Text('FIN settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'alerts',
                child: ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Alert preferences'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (provider.messages.isNotEmpty)
                const PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('Reset conversation'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: "Privacy Guarantee",
            icon: Icon(Icons.shield_outlined, color: colors.primary),
            onPressed: _showPrivacyDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FIN 2.5D Animated Companion Hero Card
              _buildFinHero(colors, provider),

              const SizedBox(height: 14),

              // 2. Privacy Banner
              _buildPrivacyBanner(colors),

              const SizedBox(height: 16),

              // 3. Question Input Field
              _buildQuestionInput(colors, provider),

              const SizedBox(height: 16),

              // 4. Suggested Questions Chips
              _buildSuggestedChips(colors, provider),

              const SizedBox(height: 20),

              // 5. Conversation History (if multi-turn messages exist)
              if (provider.messages.length > 1) ...[
                _buildConversationHistory(colors, provider),
                const SizedBox(height: 20),
              ],

              // 6. Active Result / State Views
              if (provider.isLoading)
                _buildLoadingState(colors)
              else if (provider.isOffline)
                _buildOfflineState(colors)
              else if (provider.isRateLimited)
                _buildRateLimitedState(colors)
              else if (provider.errorMessage != null)
                _buildErrorState(colors, provider.errorMessage!)
              else if (provider.latestResult != null)
                _buildResultView(colors, provider.latestResult!)
              else
                _buildDefaultInsightsView(colors, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinHero(dynamic colors, AnalyticsProvider provider) {
    final prefs = provider.companionPreferences;
    final name = prefs.preferredName;
    final state = provider.characterState;

    String statusText;
    switch (state) {
      case FinCharacterState.greeting:
        statusText = "FIN is welcoming you";
        break;
      case FinCharacterState.listening:
        statusText = "FIN is listening attentively";
        break;
      case FinCharacterState.thinking:
        statusText = "FIN is analyzing verified records";
        break;
      case FinCharacterState.explaining:
        statusText = "FIN is explaining the figures";
        break;
      case FinCharacterState.happy:
        statusText = "FIN is pleased with your progress";
        break;
      case FinCharacterState.celebrating:
        statusText = "FIN is celebrating your goal!";
        break;
      case FinCharacterState.concerned:
        statusText = "FIN noticed spending pressure";
        break;
      case FinCharacterState.confused:
        statusText = "FIN needs clarification";
        break;
      case FinCharacterState.error:
        statusText = "FIN encountered an issue";
        break;
      case FinCharacterState.idle:
        statusText = "FIN is ready to help";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 390;
          final availableHeight = MediaQuery.sizeOf(context).height;
          final characterHeight =
              (compact ? constraints.maxWidth * .52 : availableHeight * .245)
                  .clamp(150.0, 220.0);

          final character = FinCharacter(
            size: characterHeight,
            state: state,
            animationsEnabled: prefs.animationsEnabled,
            animationActive: _isFinHeroVisible,
            onTap: () => CompanionPreferencesSheet.show(context),
          );
          final copy = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: compact ? WrapAlignment.center : WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    "FIN",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      letterSpacing: .7,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      maxLines: 2,
                      textAlign: compact ? TextAlign.center : TextAlign.start,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                name != null && name.isNotEmpty
                    ? "Hey $name! Ready to inspect your spending or plan goals together?"
                    : "Your private financial companion. Ask about spending, budgets, or plans.",
                textAlign: compact ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [character, const SizedBox(height: 8), copy],
            );
          }
          return Row(
            children: [
              character,
              const SizedBox(width: 18),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrivacyBanner(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: colors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Private & Read-Only: Analyzes only saved records. No bank or SMS inbox access.",
              style: TextStyle(
                fontSize: 12,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _showPrivacyDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "View Guarantee",
              style: TextStyle(
                fontSize: 12,
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput(dynamic colors, AnalyticsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.cardBorder),
            ),
            child: TextField(
              controller: _questionController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: _submitQuestion,
              decoration: InputDecoration(
                hintText:
                    "Ask FIN about your spending, trends, budgets, or goals...",
                hintStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
                prefixIcon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: colors.textSecondary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: "Ask Question",
          style: IconButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.isDark ? Colors.black : Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.arrow_upward_rounded, size: 20),
          onPressed: () => _submitQuestion(_questionController.text),
        ),
      ],
    );
  }

  Widget _buildSuggestedChips(dynamic colors, AnalyticsProvider provider) {
    final suggestions = provider.suggestedQuestions.isNotEmpty
        ? provider.suggestedQuestions
        : const [
            SuggestedQuestion(
              intent: "total_spending",
              question: "How much did I spend this month?",
              label: "Total Spending",
            ),
            SuggestedQuestion(
              intent: "spending_by_category",
              question: "Show spending by category",
              label: "By Category",
            ),
            SuggestedQuestion(
              intent: "spending_trend",
              question: "How does my spending compare to last month?",
              label: "Spending Trend",
            ),
            SuggestedQuestion(
              intent: "category_comparison",
              question: "Which category increased the most?",
              label: "Category Comparison",
            ),
            SuggestedQuestion(
              intent: "budget_status",
              question: "Am I exceeding my food budget?",
              label: "Food Budget",
            ),
            SuggestedQuestion(
              intent: "remaining_allowance",
              question: "How much can I still spend?",
              label: "Remaining Allowance",
            ),
            SuggestedQuestion(
              intent: "fin_greeting",
              question: "Hey FIN!",
              label: "Hey FIN!",
            ),
            SuggestedQuestion(
              intent: "fin_action_goal",
              question: "Help me save ₹50,000 for a laptop",
              label: "Plan Laptop Goal",
            ),
            SuggestedQuestion(
              intent: "fin_concern_spending",
              question: "I'm spending too much lately.",
              label: "Spending Concern",
            ),
            SuggestedQuestion(
              intent: "savings_opportunities",
              question: "Where can I save money?",
              label: "Savings Opportunities",
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Suggested Questions",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) {
            return ActionChip(
              backgroundColor: colors.surface,
              side: BorderSide(color: colors.cardBorder),
              label: Text(
                s.label.isNotEmpty ? s.label : s.question,
                style: TextStyle(fontSize: 12, color: colors.textPrimary),
              ),
              onPressed: () => _selectSuggestedQuestion(s),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConversationHistory(dynamic colors, AnalyticsProvider provider) {
    final previousMessages = provider.messages.length > 2
        ? provider.messages.sublist(0, provider.messages.length - 1)
        : provider.messages.take(1).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                "Conversation Context",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...previousMessages.map((m) {
            final isUser = m.sender == MessageSender.user;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      "You: ",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FinCharacter(
                          size: 16,
                          state: FinCharacterState.idle,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "FIN: ",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  Expanded(
                    child: Text(
                      m.text,
                      style: TextStyle(fontSize: 12, color: colors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLoadingState(dynamic colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          const FinCharacter(size: 68, state: FinCharacterState.thinking),
          const SizedBox(height: 14),
          CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
          const SizedBox(height: 12),
          Text(
            "Analyzing saved FinTrack records locally...",
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineState(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.warning),
      ),
      child: Row(
        children: [
          const FinCharacter(size: 48, state: FinCharacterState.error),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Offline Mode",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  "Unable to connect to local server. Please check your network.",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateLimitedState(dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.warning),
      ),
      child: Row(
        children: [
          const FinCharacter(size: 48, state: FinCharacterState.concerned),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rate Limit Reached",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  "Too many requests. Please wait a moment before asking FIN another question.",
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic colors, String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.danger),
      ),
      child: Row(
        children: [
          const FinCharacter(size: 48, state: FinCharacterState.error),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(dynamic colors, AnalyticsQueryResult result) {
    if (result.isRefusal || result.intent == "unsupported") {
      return _buildRefusalCard(colors, result);
    }

    final provider = context.watch<AnalyticsProvider>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive badges wrap rather than competing for horizontal space.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.intent.replaceAll("_", " ").toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
              if (result.period != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        result.period!.label,
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

          const SizedBox(height: 14),

          // FIN Response Row with character
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinCharacter(
                size: 38,
                state: provider.characterState,
                animationsEnabled:
                    provider.companionPreferences.animationsEnabled,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.answer,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          // 5E.4 Action Preview Card (if an action was prepared)
          if (result.actionPreview != null) ...[
            const SizedBox(height: 16),
            FinActionPreviewCard(actionPreview: result.actionPreview!),
          ],

          // 5E.4 Navigation Action Card (if a feature navigation was suggested)
          if (result.navigationAction != null) ...[
            const SizedBox(height: 12),
            _buildNavigationCard(colors, result.navigationAction!),
          ],

          // Structured Metrics Details (Categories, Budgets, Comparisons, Indicators)
          if (result.categories.isNotEmpty &&
              result.intent == "spending_by_category") ...[
            const SizedBox(height: 16),
            Text(
              "Category Breakdown",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...result.categories.map((c) => _buildCategoryTile(colors, c)),
          ],

          if (result.comparisonCategories.isNotEmpty &&
              result.intent == "category_comparison") ...[
            const SizedBox(height: 16),
            _buildCategoryComparisonCard(colors, result),
          ],

          if (result.categoryBudget != null) ...[
            const SizedBox(height: 16),
            _buildCategoryBudgetCard(colors, result.categoryBudget!),
          ],

          if (result.budgetItems.isNotEmpty &&
              result.intent == "budget_status" &&
              result.categoryBudget == null) ...[
            const SizedBox(height: 16),
            Text(
              "BUDGET STATUS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...result.budgetItems.map((b) => _buildBudgetTile(colors, b)),
          ],

          if (result.unusualIndicators.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildUnusualSpendingCard(colors, result.unusualIndicators),
          ],

          if (result.savingsOpportunities.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSavingsOpportunitiesCard(colors, result.savingsOpportunities),
          ],

          if (result.largestExpenses.isNotEmpty &&
              result.intent == "largest_expenses") ...[
            const SizedBox(height: 16),
            Text(
              "TOP EXPENSES",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...result.largestExpenses.map((e) => _buildExpenseTile(colors, e)),
          ],

          // Follow-up Suggestion Chips
          if (result.followUpSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Follow-up Questions",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.followUpSuggestions.map((s) {
                return ActionChip(
                  backgroundColor: colors.background,
                  side: BorderSide(color: colors.cardBorder),
                  label: Text(
                    s.label.isNotEmpty ? s.label : s.question,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                  onPressed: () => _selectSuggestedQuestion(s),
                );
              }).toList(),
            ),
          ],

          // Calculation Provenance
          if (result.provenance != null) ...[
            const SizedBox(height: 16),
            Divider(color: colors.divider),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.provenance!.disclaimer,
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationCard(dynamic colors, FinNavigationAction nav) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.explore_rounded, size: 20, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nav.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                context.push(nav.route);
              } catch (_) {
                context.go(nav.route);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Open",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(dynamic colors, CategorySpendingItem item) {
    final pct = double.tryParse(item.percentage) ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "₹${item.total.toStringAsFixed(2)} (${item.percentage}%)",
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: colors.elevated,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryComparisonCard(
    dynamic colors,
    AnalyticsQueryResult result,
  ) {
    final categories = result.comparisonCategories;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "MONTH-OVER-MONTH CHANGES",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...categories.take(4).map((c) {
            final isIncrease = c.difference > 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    "₹${c.currentTotal.toStringAsFixed(0)}",
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isIncrease
                          ? Colors.red.withValues(alpha: 0.15)
                          : Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "${isIncrease ? '+' : ''}${c.percentChange}%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isIncrease ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetCard(dynamic colors, CategoryBudgetDetail budget) {
    final pct = double.tryParse(budget.percentage) ?? 0.0;
    final isExceeded = budget.status == 'exceeded';
    final isWarning = budget.status == 'approaching_limit';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${budget.categoryName.toUpperCase()} BUDGET PROGRESS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? Colors.red.withValues(alpha: 0.15)
                      : isWarning
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isExceeded
                      ? "EXCEEDED"
                      : isWarning
                      ? "WARNING"
                      : "ON TRACK",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isExceeded
                        ? Colors.red
                        : isWarning
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: colors.elevated,
            valueColor: AlwaysStoppedAnimation<Color>(
              isExceeded
                  ? Colors.red
                  : isWarning
                  ? Colors.orange
                  : colors.primary,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Spent: ₹${budget.spent.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              Text(
                "Limit: ₹${budget.budgetLimit.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTile(dynamic colors, AnalyticsBudgetItem item) {
    Color statusColor = colors.success;
    if (item.status == 'exceeded') statusColor = colors.danger;
    if (item.status == 'approaching_limit') statusColor = colors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoryName,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Spent ₹${item.spent.toStringAsFixed(2)} of ₹${item.budgetLimit.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "${item.percentage}%",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnusualSpendingCard(
    dynamic colors,
    List<UnusualSpendingIndicator> indicators,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "UNUSUAL SPENDING INDICATORS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...indicators.map((ind) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                "• ${ind.description}",
                style: TextStyle(fontSize: 12, color: colors.textPrimary),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSavingsOpportunitiesCard(
    dynamic colors,
    List<SavingsOpportunityItem> opportunities,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_outlined, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                "DETERMINISTIC SAVINGS OPPORTUNITIES",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...opportunities.map((opp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                "• ${opp.reason}",
                style: TextStyle(fontSize: 12, color: colors.textPrimary),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(dynamic colors, AnalyticsLargestExpenseItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${item.category} • ${item.date}",
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            "₹${item.amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefusalCard(dynamic colors, AnalyticsQueryResult result) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FinCharacter(size: 40, state: FinCharacterState.confused),
              const SizedBox(width: 10),
              Text(
                "Policy & Scope Notice",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.answer,
            style: TextStyle(
              fontSize: 13,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Try asking one of these supported queries instead:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.suggestions.map((s) {
                return ActionChip(
                  backgroundColor: colors.elevated,
                  label: Text(
                    s.label.isNotEmpty ? s.label : s.question,
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                  onPressed: () => _selectSuggestedQuestion(s),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultInsightsView(dynamic colors, AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InsightsFeedView(),
        if (provider.insights.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            "Current Month Insights",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...provider.insights.map((item) => _buildInsightCard(colors, item)),
        ],
      ],
    );
  }

  Widget _buildInsightCard(dynamic colors, AnalyticsInsightItem item) {
    IconData icon = Icons.info_outline_rounded;
    Color iconColor = colors.info;

    if (item.type.contains("highest") || item.type.contains("category")) {
      icon = Icons.pie_chart_outline_rounded;
      iconColor = colors.primary;
    } else if (item.type.contains("trend")) {
      icon = Icons.trending_up_rounded;
      iconColor = colors.warning;
    } else if (item.type.contains("savings") || item.type.contains("cash")) {
      icon = Icons.savings_outlined;
      iconColor = colors.success;
    } else if (item.type.contains("budget")) {
      icon = Icons.account_balance_wallet_outlined;
      iconColor = colors.danger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
