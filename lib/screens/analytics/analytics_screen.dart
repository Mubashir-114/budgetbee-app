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

class FinSuggestionCategory {
  final String category;
  final IconData icon;
  final List<SuggestedQuestion> questions;

  const FinSuggestionCategory({
    required this.category,
    required this.icon,
    required this.questions,
  });
}

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

  static const List<FinSuggestionCategory> _allCategories = [
    FinSuggestionCategory(
      category: "Overview",
      icon: Icons.dashboard_outlined,
      questions: [
        SuggestedQuestion(
          intent: "total_spending",
          question: "How much did I spend this month?",
          label: "Total Spending",
        ),
        SuggestedQuestion(
          intent: "income_vs_expense",
          question: "Show my income versus expenses",
          label: "Income vs Expenses",
        ),
        SuggestedQuestion(
          intent: "overview_insights",
          question: "Give me an overview of my finances",
          label: "Financial Insights",
        ),
      ],
    ),
    FinSuggestionCategory(
      category: "Spending",
      icon: Icons.shopping_bag_outlined,
      questions: [
        SuggestedQuestion(
          intent: "spending_by_category",
          question: "Show spending by category",
          label: "Spending by Category",
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
          intent: "largest_expenses",
          question: "What were my largest expenses?",
          label: "Largest Expenses",
        ),
        SuggestedQuestion(
          intent: "unusual_spending",
          question: "Do I have any unusual spending?",
          label: "Unusual Spending",
        ),
      ],
    ),
    FinSuggestionCategory(
      category: "Budgeting",
      icon: Icons.pie_chart_outline_rounded,
      questions: [
        SuggestedQuestion(
          intent: "budget_status",
          question: "Am I exceeding my food budget?",
          label: "Food Budget Status",
        ),
        SuggestedQuestion(
          intent: "remaining_allowance",
          question: "How much can I still spend?",
          label: "Remaining Allowance",
        ),
      ],
    ),
    FinSuggestionCategory(
      category: "Savings",
      icon: Icons.savings_outlined,
      questions: [
        SuggestedQuestion(
          intent: "savings_opportunities",
          question: "Where can I save money?",
          label: "Savings Opportunities",
        ),
        SuggestedQuestion(
          intent: "savings_affordability",
          question: "Can I afford to save more?",
          label: "Savings Affordability",
        ),
        SuggestedQuestion(
          intent: "recommended_saving",
          question: "How much should I save?",
          label: "Recommended Saving",
        ),
      ],
    ),
    FinSuggestionCategory(
      category: "Goals & Forecasts",
      icon: Icons.flag_outlined,
      questions: [
        SuggestedQuestion(
          intent: "goal_status",
          question: "How are my savings goals tracking?",
          label: "Goal Status",
        ),
        SuggestedQuestion(
          intent: "forecast_explanation",
          question: "Explain my spending forecast",
          label: "Forecast Explanation",
        ),
      ],
    ),
    FinSuggestionCategory(
      category: "Transparency",
      icon: Icons.verified_user_outlined,
      questions: [
        SuggestedQuestion(
          intent: "methodology",
          question: "How do you calculate spending and trends?",
          label: "Calculation Methodology",
        ),
      ],
    ),
  ];

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
        !_scrollController.hasClients || _scrollController.offset < 240;
    if (visible != _isFinHeroVisible && mounted) {
      setState(() => _isFinHeroVisible = visible);
    }
  }

  void _submitQuestion(String text) {
    if (text.trim().isEmpty) return;
    _focusNode.unfocus();
    _questionController.clear();
    setState(() {});
    context.read<AnalyticsProvider>().askQuestion(text.trim());
    _scrollToBottom();
  }

  void _selectSuggestedQuestion(SuggestedQuestion suggestion) {
    _submitQuestion(suggestion.question);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                  "Calculations use exact mathematical formulas and safe templates. External AI never receives financial data.",
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor:
                          colors.isDark ? Colors.black : Colors.white,
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

  void _showMoreSuggestionsSheet(BuildContext context) {
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
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollSheetController) {
            return Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.explore_outlined,
                          color: colors.primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "More suggestions",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              "Select any question to analyze your FinTrack data",
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        tooltip: "Close",
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                Expanded(
                  child: ListView.builder(
                    controller: scrollSheetController,
                    padding: EdgeInsets.fromLTRB(
                        16, 12, 16, 20 + media.viewInsets.bottom),
                    itemCount: _allCategories.length,
                    itemBuilder: (context, catIdx) {
                      final cat = _allCategories[catIdx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 12, bottom: 8, left: 4),
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 16, color: colors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  cat.category.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...cat.questions.map((q) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Material(
                                color: colors.background,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _selectSuggestedQuestion(q);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: colors.cardBorder
                                            .withValues(alpha: 0.6),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                q.label,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                q.question,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: colors.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. FIN Compact Hero Card (~25% vertical reduction, full character visible)
                    _buildFinHero(colors, provider),

                    const SizedBox(height: 10),

                    // 2. Compact Privacy Banner
                    _buildPrivacyBanner(colors),

                    const SizedBox(height: 12),

                    // 3. Compact Suggested Questions (4-6 max + More Suggestions)
                    _buildSuggestedChips(colors, provider),

                    const SizedBox(height: 16),

                    // 4. Conversational History & Results Flow
                    if (provider.messages.isNotEmpty)
                      _buildConversationThread(colors, provider)
                    else if (provider.isLoading)
                      _buildLoadingBubble(colors)
                    else if (provider.isOffline)
                      _buildOfflineState(colors, provider)
                    else if (provider.isRateLimited)
                      _buildRateLimitedState(colors, provider)
                    else if (provider.errorMessage != null)
                      _buildErrorBubble(
                          colors, provider.errorMessage!, provider)
                    else if (provider.latestResult != null)
                      _buildResultView(colors, provider.latestResult!)
                    else
                      _buildDefaultInsightsView(colors, provider),
                  ],
                ),
              ),
            ),

            // 5. Sticky Bottom Composer
            _buildStickyComposer(colors, provider),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Complete 2.5D character kept fully visible, reduced ~25% from 150-220 to 105-115
          final characterSize = constraints.maxWidth < 360 ? 95.0 : 110.0;

          return Row(
            children: [
              FinCharacter(
                size: characterSize,
                state: state,
                animationsEnabled: prefs.animationsEnabled,
                animationActive: _isFinHeroVisible,
                onTap: () => CompanionPreferencesSheet.show(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          "FIN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            letterSpacing: .5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: state == FinCharacterState.error
                                  ? colors.danger.withValues(alpha: .12)
                                  : colors.primary.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: state == FinCharacterState.error
                                    ? colors.danger
                                    : colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      name != null && name.isNotEmpty
                          ? "Hey $name! Ready to inspect your spending or plan goals?"
                          : "Your private financial companion. Ask about spending, budgets, or plans.",
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
          );
        },
      ),
    );
  }

  Widget _buildPrivacyBanner(dynamic colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: colors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Private & Read-Only: Analyzes only saved records",
              style: TextStyle(
                fontSize: 11,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _showPrivacyDialog,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(48, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "View Guarantee",
              style: TextStyle(
                fontSize: 11,
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips(dynamic colors, AnalyticsProvider provider) {
    final List<SuggestedQuestion> topSuggestions;
    if (provider.suggestedQuestions.isNotEmpty) {
      topSuggestions = provider.suggestedQuestions.take(6).toList();
    } else {
      topSuggestions = const [
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
          intent: "budget_status",
          question: "Am I exceeding my food budget?",
          label: "Budget Status",
        ),
        SuggestedQuestion(
          intent: "savings_opportunities",
          question: "Where can I save money?",
          label: "Savings Opportunities",
        ),
        SuggestedQuestion(
          intent: "income_vs_expense",
          question: "Show my income versus expenses",
          label: "Income vs Expenses",
        ),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Suggested Questions",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
            InkWell(
              onTap: () => _showMoreSuggestionsSheet(context),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 12, color: colors.primary),
                    const SizedBox(width: 4),
                    Text(
                      "More",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: topSuggestions.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == topSuggestions.length) {
                return ActionChip(
                  backgroundColor: colors.surface,
                  side:
                      BorderSide(color: colors.primary.withValues(alpha: 0.3)),
                  avatar: Icon(Icons.grid_view_rounded,
                      size: 13, color: colors.primary),
                  label: Text(
                    "More Suggestions",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                  onPressed: () => _showMoreSuggestionsSheet(context),
                );
              }
              final s = topSuggestions[index];
              return ActionChip(
                backgroundColor: colors.surface,
                side: BorderSide(color: colors.cardBorder),
                label: Text(
                  s.label.isNotEmpty ? s.label : s.question,
                  style: TextStyle(fontSize: 11, color: colors.textPrimary),
                ),
                onPressed: () => _selectSuggestedQuestion(s),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStickyComposer(dynamic colors, AnalyticsProvider provider) {
    final canSend =
        _questionController.text.trim().isNotEmpty && !provider.isLoading;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.cardBorder.withValues(alpha: 0.6)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _submitQuestion,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            "Ask FIN anything about your FinTrack finances...",
                        hintStyle: TextStyle(
                            fontSize: 12, color: colors.textSecondary),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_questionController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 18, color: colors.textSecondary),
                      onPressed: () {
                        _questionController.clear();
                        setState(() {});
                      },
                      tooltip: "Clear",
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: "Ask Question",
            style: IconButton.styleFrom(
              backgroundColor: canSend ? colors.primary : colors.elevated,
              foregroundColor: canSend
                  ? (colors.isDark ? Colors.black : Colors.white)
                  : colors.textSecondary,
              minimumSize: const Size(48, 48),
              shape: const CircleBorder(),
            ),
            icon: provider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.isDark ? Colors.black : Colors.white,
                    ),
                  )
                : const Icon(Icons.arrow_upward_rounded, size: 20),
            onPressed: provider.isLoading
                ? null
                : () => _submitQuestion(_questionController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationThread(
      dynamic colors, AnalyticsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...provider.messages.map((m) {
          if (m.sender == MessageSender.user) {
            return Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12, left: 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(3),
                  ),
                  border:
                      Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  m.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            );
          } else {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: m.result != null
                  ? _buildResultView(colors, m.result!)
                  : _buildAssistantSimpleBubble(colors, m),
            );
          }
        }),

        // Thinking state when loading
        if (provider.isLoading) _buildLoadingBubble(colors),

        // Contextual error state
        if (provider.isOffline)
          _buildOfflineState(colors, provider)
        else if (provider.isRateLimited)
          _buildRateLimitedState(colors, provider)
        else if (provider.errorMessage != null)
          _buildErrorBubble(colors, provider.errorMessage!, provider),
      ],
    );
  }

  Widget _buildAssistantSimpleBubble(dynamic colors, ChatMessage m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinCharacter(
            size: 32,
            state: FinCharacterState.fromString(m.characterState),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              m.text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(dynamic colors) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const FinCharacter(size: 36, state: FinCharacterState.thinking),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "FIN is analyzing verified records...",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: colors.elevated,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineState(dynamic colors, AnalyticsProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FinCharacter(size: 36, state: FinCharacterState.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Offline Mode",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      "Unable to connect to local server. Please check your network.",
                      style:
                          TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (provider.lastQuestion != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor:
                      colors.isDark ? Colors.black : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(48, 32),
                ),
                onPressed: () => provider.retryLastQuestion(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateLimitedState(dynamic colors, AnalyticsProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.warning),
      ),
      child: Row(
        children: [
          const FinCharacter(size: 36, state: FinCharacterState.concerned),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rate Limit Reached",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
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

  Widget _buildErrorBubble(
      dynamic colors, String message, AnalyticsProvider provider) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.danger.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FinCharacter(size: 36, state: FinCharacterState.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          if (provider.lastQuestion != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor:
                      colors.isDark ? Colors.black : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(48, 32),
                ),
                onPressed: () => provider.retryLastQuestion(),
              ),
            ),
          ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.intent.replaceAll("_", " ").toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
              if (result.period != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        result.period!.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinCharacter(
                size: 34,
                state: provider.characterState,
                animationsEnabled:
                    provider.companionPreferences.animationsEnabled,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.answer,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),

          if (result.actionPreview != null) ...[
            const SizedBox(height: 14),
            FinActionPreviewCard(actionPreview: result.actionPreview!),
          ],

          if (result.navigationAction != null) ...[
            const SizedBox(height: 12),
            _buildNavigationCard(colors, result.navigationAction!),
          ],

          if (result.categories.isNotEmpty &&
              result.intent == "spending_by_category") ...[
            const SizedBox(height: 14),
            Text(
              "Category Breakdown",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...result.categories.map((c) => _buildCategoryTile(colors, c)),
          ],

          if (result.comparisonCategories.isNotEmpty &&
              result.intent == "category_comparison") ...[
            const SizedBox(height: 14),
            _buildCategoryComparisonCard(colors, result),
          ],

          if (result.categoryBudget != null) ...[
            const SizedBox(height: 14),
            _buildCategoryBudgetCard(colors, result.categoryBudget!),
          ],

          if (result.budgetItems.isNotEmpty &&
              result.intent == "budget_status" &&
              result.categoryBudget == null) ...[
            const SizedBox(height: 14),
            Text(
              "BUDGET STATUS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...result.budgetItems.map((b) => _buildBudgetTile(colors, b)),
          ],

          if (result.unusualIndicators.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildUnusualSpendingCard(colors, result.unusualIndicators),
          ],

          if (result.savingsOpportunities.isNotEmpty) ...[
            const SizedBox(height: 14),
            _buildSavingsOpportunitiesCard(colors, result.savingsOpportunities),
          ],

          if (result.largestExpenses.isNotEmpty &&
              result.intent == "largest_expenses") ...[
            const SizedBox(height: 14),
            Text(
              "TOP EXPENSES",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            ...result.largestExpenses.map((e) => _buildExpenseTile(colors, e)),
          ],

          if (result.followUpSuggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              "Follow-up Questions",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.followUpSuggestions.map((s) {
                return ActionChip(
                  backgroundColor: colors.background,
                  side: BorderSide(color: colors.cardBorder),
                  label: Text(
                    s.label.isNotEmpty ? s.label : s.question,
                    style: TextStyle(fontSize: 11, color: colors.textPrimary),
                  ),
                  onPressed: () => _selectSuggestedQuestion(s),
                );
              }).toList(),
            ),
          ],

          if (result.provenance != null) ...[
            const SizedBox(height: 14),
            Divider(color: colors.divider),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.shield_outlined, size: 13, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.provenance!.disclaimer,
                    style: TextStyle(fontSize: 10, color: colors.textSecondary),
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.explore_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              nav.label,
              style: TextStyle(
                fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(48, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Open",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12),
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
                    fontSize: 12,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "₹${item.total.toStringAsFixed(2)} (${item.percentage}%)",
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: colors.elevated,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            minHeight: 5,
            borderRadius: BorderRadius.circular(3),
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
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ...categories.take(4).map((c) {
            final isIncrease = c.difference > 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
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
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
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
                        fontSize: 10,
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                    fontSize: 9,
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
          const SizedBox(height: 6),
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
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Spent: ₹${budget.spent.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              Text(
                "Limit: ₹${budget.budgetLimit.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 11,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoryName,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Spent ₹${item.spent.toStringAsFixed(2)} of ₹${item.budgetLimit.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${item.percentage}%",
              style: TextStyle(
                fontSize: 10,
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
                size: 15,
                color: Colors.amber,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "UNUSUAL SPENDING INDICATORS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...indicators.map((ind) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "• ${ind.description}",
                style: TextStyle(fontSize: 11, color: colors.textPrimary),
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
              const Icon(Icons.savings_outlined, size: 15, color: Colors.green),
              const SizedBox(width: 8),
              const Text(
                "DETERMINISTIC SAVINGS OPPORTUNITIES",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...opportunities.map((opp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                "• ${opp.reason}",
                style: TextStyle(fontSize: 11, color: colors.textPrimary),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(dynamic colors, AnalyticsLargestExpenseItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${item.category} • ${item.date}",
                  style: TextStyle(fontSize: 10, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            "₹${item.amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FinCharacter(size: 36, state: FinCharacterState.confused),
              const SizedBox(width: 10),
              Text(
                "Policy & Scope Notice",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            result.answer,
            style: TextStyle(
              fontSize: 12,
              color: colors.textPrimary,
              height: 1.35,
            ),
          ),
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Try asking one of these supported queries instead:",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.suggestions.map((s) {
                return ActionChip(
                  backgroundColor: colors.elevated,
                  label: Text(
                    s.label.isNotEmpty ? s.label : s.question,
                    style: TextStyle(fontSize: 11, color: colors.textPrimary),
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
          const SizedBox(height: 20),
          Text(
            "Current Month Insights",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 11,
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
