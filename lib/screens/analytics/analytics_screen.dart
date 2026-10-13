import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/analytics_model.dart';
import '../../providers/analytics_provider.dart';
import 'widgets/alert_preferences_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AnalyticsProvider>();
      provider.loadCapabilities();
      provider.loadInsights();
      provider.initializeAlertPreferences().then((_) {
        provider.loadAlerts();
      });
      if (widget.initialQuestion != null && widget.initialQuestion!.trim().isNotEmpty) {
        _submitQuestion(widget.initialQuestion!.trim());
      }
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    super.dispose();
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
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
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
                    child: Icon(Icons.shield_outlined, color: colors.primary, size: 24),
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
                          "FinTrack 2.0 — Phase 5B Private Assistant",
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
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
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Understood", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
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
            Text(
              "AI Financial Insights",
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Alert Preferences",
            icon: Icon(Icons.tune_rounded, color: colors.textSecondary),
            onPressed: () => AlertPreferencesSheet.show(context),
          ),
          if (provider.messages.isNotEmpty)
            IconButton(
              tooltip: "Reset Conversation",
              icon: Icon(Icons.refresh_rounded, color: colors.textSecondary),
              onPressed: () => provider.clearConversation(),
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
          padding: const EdgeInsets.all(AppDimensions.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Privacy Banner
              _buildPrivacyBanner(colors),

              const SizedBox(height: 16),

              // 2. Question Input Field
              _buildQuestionInput(colors, provider),

              const SizedBox(height: 16),

              // 3. Suggested Questions Chips
              _buildSuggestedChips(colors, provider),

              const SizedBox(height: 20),

              // 4. Conversation History (if multi-turn messages exist)
              if (provider.messages.length > 1) ...[
                _buildConversationHistory(colors, provider),
                const SizedBox(height: 20),
              ],

              // 5. Active Result / State Views
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
              style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.bold),
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
                hintText: "Ask about your spending, trends, budgets...",
                hintStyle: TextStyle(fontSize: 13, color: colors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            SuggestedQuestion(intent: "total_spending", question: "How much did I spend this month?", label: "Total Spending"),
            SuggestedQuestion(intent: "spending_by_category", question: "Show spending by category", label: "By Category"),
            SuggestedQuestion(intent: "spending_trend", question: "How does my spending compare to last month?", label: "Spending Trend"),
            SuggestedQuestion(intent: "category_comparison", question: "Which category increased the most?", label: "Category Comparison"),
            SuggestedQuestion(intent: "budget_status", question: "Am I exceeding my food budget?", label: "Food Budget"),
            SuggestedQuestion(intent: "remaining_allowance", question: "How much can I still spend?", label: "Remaining Allowance"),
            SuggestedQuestion(intent: "unusual_spending", question: "Any unusual spending this month?", label: "Unusual Spending"),
            SuggestedQuestion(intent: "savings_opportunities", question: "Where can I save money?", label: "Savings Opportunities"),
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
    // Show previous turns (excluding the latest assistant answer which is displayed in ResultView)
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
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 6),
              Text(
                "Conversation Context",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...previousMessages.map((m) {
            final isUser = m.sender == MessageSender.user;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? "You: " : "Assistant: ",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isUser ? colors.primary : colors.textSecondary,
                    ),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 16),
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
          Icon(Icons.wifi_off_rounded, color: colors.warning, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Offline Mode",
                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
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
          Icon(Icons.hourglass_empty_rounded, color: colors.warning, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rate Limit Reached",
                  style: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                Text(
                  "Too many requests. Please wait a moment before asking another question.",
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
          Icon(Icons.error_outline_rounded, color: colors.danger, size: 28),
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
          // Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              const Spacer(),
              if (result.period != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.elevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 12, color: colors.textSecondary),
                      const SizedBox(width: 5),
                      Text(
                        result.period!.label,
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Natural Language Answer
          Text(
            result.answer,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),

          // Structured Metrics Details (Categories, Budgets, Comparisons, Indicators)
          if (result.categories.isNotEmpty && result.intent == "spending_by_category") ...[
            const SizedBox(height: 16),
            Text(
              "Category Breakdown",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...result.categories.map((c) => _buildCategoryTile(colors, c)),
          ],

          if (result.comparisonCategories.isNotEmpty && result.intent == "category_comparison") ...[
            const SizedBox(height: 16),
            _buildCategoryComparisonCard(colors, result),
          ],

          if (result.categoryBudget != null) ...[
            const SizedBox(height: 16),
            _buildCategoryBudgetCard(colors, result.categoryBudget!),
          ],

          if (result.budgetItems.isNotEmpty && result.intent == "budget_status" && result.categoryBudget == null) ...[
            const SizedBox(height: 16),
            Text(
              "BUDGET STATUS",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
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

          if (result.largestExpenses.isNotEmpty && result.intent == "largest_expenses") ...[
            const SizedBox(height: 16),
            Text(
              "TOP EXPENSES",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...result.largestExpenses.map((e) => _buildExpenseTile(colors, e)),
          ],

          // Follow-up Suggestion Chips
          if (result.followUpSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Follow-up Questions",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
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
              Text(
                item.name,
                style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w500),
              ),
              Text(
                "₹${item.total.toStringAsFixed(2)} (${item.percentage}%)",
                style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.bold),
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

  Widget _buildCategoryComparisonCard(dynamic colors, AnalyticsQueryResult result) {
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
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
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
                    ),
                  ),
                  Text("₹${c.currentTotal.toStringAsFixed(0)}", style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isIncrease ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
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
              Text(
                "${budget.categoryName.toUpperCase()} BUDGET PROGRESS",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.textSecondary),
              ),
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
                  isExceeded ? "EXCEEDED" : isWarning ? "WARNING" : "ON TRACK",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isExceeded ? Colors.red : isWarning ? Colors.orange : Colors.green,
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
              isExceeded ? Colors.red : isWarning ? Colors.orange : colors.primary,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Spent: ₹${budget.spent.toStringAsFixed(2)}", style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              Text("Limit: ₹${budget.budgetLimit.toStringAsFixed(2)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textPrimary)),
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
                  style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w600),
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnusualSpendingCard(dynamic colors, List<UnusualSpendingIndicator> indicators) {
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
              const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              const Text(
                "UNUSUAL SPENDING INDICATORS",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...indicators.map((ind) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text("• ${ind.description}", style: TextStyle(fontSize: 12, color: colors.textPrimary)),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSavingsOpportunitiesCard(dynamic colors, List<SavingsOpportunityItem> opportunities) {
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
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...opportunities.map((opp) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text("• ${opp.reason}", style: TextStyle(fontSize: 12, color: colors.textPrimary)),
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
                  style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.w600),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
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
              Icon(Icons.privacy_tip_outlined, color: colors.warning, size: 24),
              const SizedBox(width: 10),
              Text(
                "Policy & Scope Notice",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.answer,
            style: TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.4),
          ),
          if (result.suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Try asking one of these supported queries instead:",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.textPrimary),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
