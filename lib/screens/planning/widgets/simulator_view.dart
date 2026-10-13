import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/goal_model.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/goal_provider.dart';

class SimulatorView extends StatefulWidget {
  const SimulatorView({super.key});

  @override
  State<SimulatorView> createState() => _SimulatorViewState();
}

class _SimulatorViewState extends State<SimulatorView> {
  String _selectedScenario = 'savings_adjustment'; // 'savings_adjustment', 'expense_reduction', 'target_deadline', 'income_change'
  int? _selectedGoalId;

  // Controllers for inputs
  final _savingAmountController = TextEditingController(text: '2000');
  final _reductionAmountController = TextEditingController(text: '1500');
  final _targetMonthsController = TextEditingController(text: '6');
  final _incomeChangeController = TextEditingController(text: '5000');

  double _reductionPercentage = 15;
  bool _usePercentageReduction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goals = context.read<GoalProvider>().goals;
      if (goals.isNotEmpty && _selectedGoalId == null) {
        setState(() {
          _selectedGoalId = goals.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _savingAmountController.dispose();
    _reductionAmountController.dispose();
    _targetMonthsController.dispose();
    _incomeChangeController.dispose();
    super.dispose();
  }

  Future<void> _runSimulation() async {
    final provider = context.read<GoalProvider>();
    final Map<String, dynamic> scenario = {
      'scenarioType': _selectedScenario,
    };

    if (_selectedScenario != 'income_change' && _selectedGoalId != null) {
      scenario['goalId'] = _selectedGoalId;
    }

    switch (_selectedScenario) {
      case 'savings_adjustment':
        scenario['parameters'] = {
          'savingAmount': double.tryParse(_savingAmountController.text.trim()) ?? 0,
        };
        break;
      case 'expense_reduction':
        if (_usePercentageReduction) {
          scenario['parameters'] = {'reductionPercentage': _reductionPercentage};
        } else {
          scenario['parameters'] = {
            'reductionAmount': double.tryParse(_reductionAmountController.text.trim()) ?? 0,
          };
        }
        break;
      case 'target_deadline':
        scenario['parameters'] = {
          'targetMonths': int.tryParse(_targetMonthsController.text.trim()) ?? 6,
        };
        break;
      case 'income_change':
        scenario['parameters'] = {
          'incomeChangeAmount': double.tryParse(_incomeChangeController.text.trim()) ?? 0,
        };
        break;
    }

    await provider.runSimulation(scenario);
  }

  void _resetSimulation() {
    context.read<GoalProvider>().resetSimulation();
    setState(() {
      _savingAmountController.text = '2000';
      _reductionAmountController.text = '1500';
      _targetMonthsController.text = '6';
      _incomeChangeController.text = '5000';
      _reductionPercentage = 15;
      _usePercentageReduction = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final currency = context.watch<CurrencyProvider>();
    final provider = context.watch<GoalProvider>();
    final activeGoals = provider.goals.where((g) => g.status != 'archived').toList();

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.md),
      children: [
        // Prominent Hypothetical Notice Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.science_rounded, color: colors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive What-If Simulator',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Simulations are isolated mathematical scenarios. They do not alter your transactions, bank accounts, or saved goal targets.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Scenario Type Selection
        Text(
          'Select Scenario Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildScenarioChip(
              id: 'savings_adjustment',
              label: 'Adjust Monthly Saving',
              icon: Icons.savings_outlined,
              colors: colors,
            ),
            _buildScenarioChip(
              id: 'expense_reduction',
              label: 'Expense Reduction',
              icon: Icons.trending_down_rounded,
              colors: colors,
            ),
            _buildScenarioChip(
              id: 'target_deadline',
              label: 'Deadline Change',
              icon: Icons.event_repeat_rounded,
              colors: colors,
            ),
            _buildScenarioChip(
              id: 'income_change',
              label: 'Income Change',
              icon: Icons.account_balance_rounded,
              colors: colors,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Goal selector (if not pure income change)
        if (_selectedScenario != 'income_change') ...[
          Text(
            'Target Savings Goal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (activeGoals.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.isDark ? colors.elevated : colors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Text(
                'No active savings goals found. Create a goal to simulate completion timelines.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.isDark ? colors.elevated : colors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: activeGoals.any((g) => g.id == _selectedGoalId)
                      ? _selectedGoalId
                      : activeGoals.first.id,
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down_rounded, color: colors.primary),
                  items: activeGoals.map((g) {
                    return DropdownMenuItem<int>(
                      value: g.id,
                      child: Text(
                        '${g.name} (Target: ${currency.format(g.targetAmount)}, Saved: ${currency.format(g.savedAmount)})',
                        style: TextStyle(fontSize: 13, color: colors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGoalId = val;
                      });
                    }
                  },
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],

        // Dynamic Scenario Inputs Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
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
              Text(
                'Scenario Parameters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildScenarioSpecificInputs(colors, currency),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.isSimulating ? null : _runSimulation,
                      icon: provider.isSimulating
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(
                        provider.isSimulating ? 'Simulating...' : 'Run Simulation',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        ),
                      ),
                    ),
                  ),
                  if (provider.simulation != null) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: _resetSimulation,
                      icon: const Icon(Icons.restart_alt_rounded, size: 18),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Simulation Error display
        if (provider.errorMessage != null && provider.simulation == null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(fontSize: 12, color: AppColors.danger),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Results Card (if simulation has run)
        if (provider.simulation != null)
          _buildResultsCard(provider.simulation!, colors, currency),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildScenarioChip({
    required String id,
    required String label,
    required IconData icon,
    required dynamic colors,
  }) {
    final isSelected = _selectedScenario == id;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : colors.textSecondary,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.isDark ? colors.elevated : colors.background,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : colors.textPrimary,
      ),
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedScenario = id;
          });
          context.read<GoalProvider>().resetSimulation();
        }
      },
    );
  }

  Widget _buildScenarioSpecificInputs(dynamic colors, CurrencyProvider currency) {
    switch (_selectedScenario) {
      case 'savings_adjustment':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hypothetical Monthly Allocation',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _savingAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '${currency.currencySymbol} ',
                hintText: 'e.g. 2000 or 3500',
                filled: true,
                fillColor: colors.isDark ? colors.elevated : colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );

      case 'expense_reduction':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _usePercentageReduction
                      ? 'Reduction: ${_reductionPercentage.toStringAsFixed(0)}%'
                      : 'Fixed Amount Reduction',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _usePercentageReduction = !_usePercentageReduction;
                    });
                  },
                  child: Text(
                    _usePercentageReduction ? 'Switch to Fixed Amount' : 'Switch to Percentage',
                    style: TextStyle(fontSize: 11, color: colors.primary),
                  ),
                ),
              ],
            ),
            if (_usePercentageReduction) ...[
              Slider(
                value: _reductionPercentage,
                min: 1,
                max: 50,
                divisions: 49,
                activeColor: colors.primary,
                label: '${_reductionPercentage.toStringAsFixed(0)}%',
                onChanged: (val) {
                  setState(() {
                    _reductionPercentage = val;
                  });
                },
              ),
            ] else ...[
              TextFormField(
                controller: _reductionAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '${currency.currencySymbol} ',
                  hintText: 'e.g. 1500',
                  helperText: 'Monthly reduction redirected to savings',
                  filled: true,
                  fillColor: colors.isDark ? colors.elevated : colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        );

      case 'target_deadline':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Completion Timeline (Months)',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _targetMonthsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'months',
                hintText: 'e.g. 6 or 12',
                helperText: 'Calculates required monthly savings to hit target',
                filled: true,
                fillColor: colors.isDark ? colors.elevated : colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );

      case 'income_change':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Income Change (Positive or Negative)',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _incomeChangeController,
              keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
              decoration: InputDecoration(
                prefixText: '${currency.currencySymbol} ',
                hintText: 'e.g. 5000 or -3000',
                helperText: 'Use negative number for income drops',
                filled: true,
                fillColor: colors.isDark ? colors.elevated : colors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildResultsCard(
    WhatIfSimulationModel result,
    dynamic colors,
    CurrencyProvider currency,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: colors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(Icons.assessment_outlined, color: colors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Simulation Outcome',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary explanation text
          Text(
            result.explanation,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Side-by-side comparison
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Baseline Cash Flow',
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currency.format(result.baselineNetCashFlow)}/mo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 36,
                width: 1,
                color: colors.divider,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simulated Cash Flow',
                      style: TextStyle(fontSize: 11, color: colors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currency.format(result.simulatedNetCashFlow)}/mo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Timeline / Monthly differences
          if (result.monthsSaved != null && result.monthsSaved! != 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (result.monthsSaved! > 0 ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    result.monthsSaved! > 0
                        ? Icons.speed_rounded
                        : Icons.schedule_rounded,
                    size: 16,
                    color: result.monthsSaved! > 0
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    result.monthsSaved! > 0
                        ? '${result.monthsSaved!.abs().toStringAsFixed(1)} months faster'
                        : '${result.monthsSaved!.abs().toStringAsFixed(1)} months slower',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: result.monthsSaved! > 0
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (result.requiredMonthlySaving != null) ...[
            Text(
              'Required Monthly Saving: ${currency.format(result.requiredMonthlySaving!)}/mo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Assumptions and limitations
          if (result.assumptions.isNotEmpty) ...[
            Text(
              'Assumptions & Limitations:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            ...result.assumptions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $a',
                  style: TextStyle(fontSize: 10, color: colors.textSecondary, height: 1.3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
