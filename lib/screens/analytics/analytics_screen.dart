import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/analytics_model.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

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
    context.read<AnalyticsProvider>().askQuestion(text);
  }

  void _selectSuggestedQuestion(SuggestedQuestion suggestion) {
    _questionController.text = suggestion.question;
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
                          "FinTrack 2.0 — Phase 5A",
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

              // 3. Suggested Questions
              _buildSuggestedChips(colors, provider),

              const SizedBox(height: 20),

              // 4. Content State Views
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
              minimumSize: const Size(50, 30),
            ),
            child: Text(
              "Details",
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
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _questionController,
              focusNode: _focusNode,
              maxLength: 200,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ask about your spending, budgets, or trends...",
                hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.7), fontSize: 13),
                border: InputBorder.none,
                counterText: "",
              ),
              onSubmitted: _submitQuestion,
            ),
          ),
          if (_questionController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 18),
              onPressed: () {
                _questionController.clear();
                setState(() {});
              },
            ),
          IconButton(
            icon: Icon(Icons.arrow_forward_rounded, color: colors.primary),
            onPressed: () => _submitQuestion(_questionController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedChips(dynamic colors, AnalyticsProvider provider) {
    final suggestions = provider.suggestedQuestions.isNotEmpty
        ? provider.suggestedQuestions
        : const [
            SuggestedQuestion(intent: "total_spending", question: "How much did I spend this month?", label: "Total Spending"),
            SuggestedQuestion(intent: "spending_by_category", question: "Show spending by category", label: "By Category"),
            SuggestedQuestion(intent: "spending_trend", question: "How does my spending compare to last month?", label: "Spending Trend"),
            SuggestedQuestion(intent: "budget_status", question: "How are my budgets doing?", label: "Budgets"),
            SuggestedQuestion(intent: "income_vs_expense", question: "What is my income vs expenses?", label: "Cashflow"),
            SuggestedQuestion(intent: "largest_expenses", question: "What were my largest expenses?", label: "Top Expenses"),
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
                s.label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              avatar: Icon(Icons.chat_bubble_outline_rounded, size: 14, color: colors.primary),
              onPressed: () => _selectSuggestedQuestion(s),
            );
          }).toList(),
        ),
      ],
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

          // Templated Natural Language Answer
          Text(
            result.answer,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),

          // Detail breakdowns (if applicable)
          if (result.categories.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "Category Breakdown",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...result.categories.map((c) => _buildCategoryTile(colors, c)),
          ],

          if (result.budgetItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "Budget Progress",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...result.budgetItems.map((b) => _buildBudgetTile(colors, b)),
          ],

          if (result.largestExpenses.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              "Top Expenses",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colors.textSecondary),
            ),
            const SizedBox(height: 8),
            ...result.largestExpenses.map((e) => _buildExpenseTile(colors, e)),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Provenance Footer
          if (result.provenance != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_outlined, size: 16, color: colors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.provenance!.disclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
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
                  "₹${item.spent.toStringAsFixed(0)} of ₹${item.budgetLimit.toStringAsFixed(0)} (${item.percentage}%)",
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
              item.status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.danger),
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
            ...result.suggestions.take(3).map(
              (s) => TextButton(
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onPressed: () => _selectSuggestedQuestion(s),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_rounded, color: colors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        s.question,
                        style: TextStyle(fontSize: 12, color: colors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultInsightsView(dynamic colors, AnalyticsProvider provider) {
    final insights = provider.insights;

    if (insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.insights_rounded, color: colors.primary, size: 40),
              const SizedBox(height: 12),
              Text(
                "Ask a Question Above",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Select a suggested question or type your own to view deterministic analytics on your saved transactions.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Current Period Insights",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...insights.map((i) => _buildInsightCard(colors, i)),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
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
                const SizedBox(height: 3),
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
