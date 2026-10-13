import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/companion_model.dart';
import '../../models/goal_model.dart';
import '../../providers/currency_provider.dart';
import '../../providers/goal_provider.dart';
import '../analytics/widgets/fin_character.dart';
import 'widgets/add_edit_goal_sheet.dart';
import 'widgets/forecast_view.dart';
import 'widgets/goal_card.dart';
import 'widgets/simulator_view.dart';

class PlanningScreen extends StatefulWidget {
  final int initialTabIndex;

  const PlanningScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all'; // 'all', 'active', 'completed', 'archived'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<GoalProvider>();
    await Future.wait([
      provider.loadGoals(forceRefresh: true),
      provider.loadSummary(),
      provider.loadCashFlowForecast(),
    ]);
  }

  void _showPrivacyNotice(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXL)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security_rounded, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Financial Safety & Privacy Boundary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• All financial planning projections and goals are deterministic mathematical models computed entirely within FinTrack.\n'
              '• No financial data, account balances, or goal targets are ever shared with third-party AI or external services.\n'
              '• Savings goal allocations are planning trackers only: they do not transfer funds or debit bank accounts.\n'
              '• What-if simulations are isolated scenario calculations and never modify your actual financial history.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                child: const Text('Understood'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    GoalsSummaryModel? summary,
    dynamic colors,
    CurrencyProvider currency,
  ) {
    final target = summary?.totalTarget ?? 0;
    final saved = summary?.totalSaved ?? 0;
    final progress = summary?.overallProgressPercentage ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 8),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.isDark
              ? [colors.elevated, colors.surface]
              : [colors.surface, colors.background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: colors.isDark
              ? colors.surface.withValues(alpha: 0.8)
              : colors.divider.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tracked Savings',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${progress.toStringAsFixed(0)}% Overall',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currency.format(saved),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'of ${currency.format(target)} target',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.isDark ? colors.surface : colors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active: ${summary?.activeGoalsCount ?? 0}',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              Text(
                'Completed: ${summary?.completedGoalsCount ?? 0}',
                style: TextStyle(fontSize: 11, color: AppColors.success),
              ),
              Text(
                'Archived: ${summary?.archivedGoalsCount ?? 0}',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(dynamic colors) {
    final filters = [
      {'id': 'all', 'label': 'All Goals'},
      {'id': 'active', 'label': 'Active'},
      {'id': 'completed', 'label': 'Achieved'},
      {'id': 'archived', 'label': 'Archived'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 4),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: colors.primary,
              backgroundColor: colors.isDark ? colors.elevated : colors.surface,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedFilter = f['id']!;
                  });
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<GoalModel> _getFilteredGoals(List<GoalModel> goals) {
    switch (_selectedFilter) {
      case 'active':
        return goals.where((g) => g.status == 'active').toList();
      case 'completed':
        return goals.where((g) => g.status == 'completed').toList();
      case 'archived':
        return goals.where((g) => g.status == 'archived').toList();
      case 'all':
      default:
        return goals.where((g) => g.status != 'archived').toList();
    }
  }

  Widget _buildGoalsTab(GoalProvider provider, dynamic colors, CurrencyProvider currency) {
    if (provider.isLoading && provider.goals.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colors.primary),
      );
    }

    if (provider.errorMessage != null && provider.goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(
                'Unable to load savings goals',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                provider.errorMessage!,
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _getFilteredGoals(provider.goals);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: colors.primary,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          _buildSummaryCard(provider.summary, colors, currency),
          _buildFilterChips(colors),
          const SizedBox(height: 8),

          if (filtered.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FinCharacter(
                      size: 56,
                      state: FinCharacterState.greeting,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _selectedFilter == 'all'
                          ? 'No savings goals created yet'
                          : 'No $_selectedFilter goals found',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define your aspirations—emergency funds, travel, gadgets—and track progress securely.',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => AddEditGoalSheet.show(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Create Savings Goal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
              child: Column(
                children: filtered.map((g) => GoalCard(goal: g)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>();
    final provider = context.watch<GoalProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Financial Planning',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shield_outlined, color: colors.textSecondary),
            tooltip: 'Privacy & Safety',
            onPressed: () => _showPrivacyNotice(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Savings Goals'),
            Tab(text: 'Cash-Flow'),
            Tab(text: 'What-If'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => AddEditGoalSheet.show(context),
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalsTab(provider, colors, currency),
          const ForecastView(),
          const SimulatorView(),
        ],
      ),
    );
  }
}
