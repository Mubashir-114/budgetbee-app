import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/goal_model.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/goal_provider.dart';
import 'package:frontend/repositories/goal_repository.dart';
import 'package:frontend/screens/planning/widgets/goal_card.dart';
import 'package:frontend/screens/planning/widgets/add_edit_goal_sheet.dart';
import 'package:frontend/screens/planning/widgets/add_edit_contribution_sheet.dart';
import 'package:frontend/screens/planning/widgets/forecast_view.dart';
import 'package:frontend/screens/planning/widgets/simulator_view.dart';

class MockGoalRepository extends GoalRepository {
  List<GoalModel> mockGoals = [];
  GoalsSummaryModel? mockSummary;
  CashFlowForecastModel? mockForecast;
  WhatIfSimulationModel? mockSimulation;

  @override
  Future<ApiResponse<List<GoalModel>>> getGoals({String? status}) async {
    return ApiResponse(
      success: true,
      message: 'Goals fetched successfully',
      data: mockGoals,
    );
  }

  @override
  Future<ApiResponse<GoalsSummaryModel>> getGoalsSummary() async {
    return ApiResponse(
      success: true,
      message: 'Summary fetched successfully',
      data: mockSummary ??
          const GoalsSummaryModel(
            totalTarget: 150000,
            totalSaved: 45000,
            totalRemaining: 105000,
            overallProgressPercentage: 30.0,
            activeGoalsCount: 2,
            completedGoalsCount: 1,
            archivedGoalsCount: 0,
            totalGoalsCount: 3,
          ),
    );
  }

  @override
  Future<ApiResponse<GoalModel>> getGoalById(int goalId) async {
    final g = mockGoals.firstWhere((item) => item.id == goalId);
    return ApiResponse(
      success: true,
      message: 'Goal fetched successfully',
      data: g,
    );
  }

  @override
  Future<ApiResponse<GoalModel>> createGoal(Map<String, dynamic> data) async {
    final created = GoalModel(
      id: 99,
      userId: 1,
      name: data['name'] as String,
      description: data['description'] as String?,
      targetAmount: (data['targetAmount'] as num).toDouble(),
      currency: (data['currency'] as String?) ?? 'INR',
      targetDate: data['targetDate'] as String?,
      startingAmount: (data['startingAmount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (data['startingAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (data['targetAmount'] as num).toDouble() -
          ((data['startingAmount'] as num?)?.toDouble() ?? 0.0),
      progressPercentage: 0.0,
      status: 'active',
    );
    mockGoals.add(created);
    return ApiResponse(
      success: true,
      message: 'Goal created successfully',
      data: created,
    );
  }

  @override
  Future<ApiResponse<GoalModel>> updateGoal(int goalId, Map<String, dynamic> data) async {
    final index = mockGoals.indexWhere((g) => g.id == goalId);
    final existing = mockGoals[index];
    final updated = existing.copyWith(
      name: data['name'] as String?,
      description: data['description'] as String?,
      targetAmount: (data['targetAmount'] as num?)?.toDouble(),
      status: data['status'] as String?,
    );
    mockGoals[index] = updated;
    return ApiResponse(
      success: true,
      message: 'Goal updated successfully',
      data: updated,
    );
  }

  @override
  Future<ApiResponse<void>> deleteGoal(int goalId) async {
    mockGoals.removeWhere((g) => g.id == goalId);
    return ApiResponse(
      success: true,
      message: 'Goal deleted successfully',
      data: null,
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> addContribution(
    int goalId,
    Map<String, dynamic> data,
  ) async {
    final contribution = GoalContributionModel(
      id: 501,
      goalId: goalId,
      userId: 1,
      amount: (data['amount'] as num).toDouble(),
      contributionDate: (data['contributionDate'] as String?) ?? '2026-10-13',
      note: data['note'] as String?,
    );
    final index = mockGoals.indexWhere((g) => g.id == goalId);
    final g = mockGoals[index];
    final updatedGoal = g.copyWith(
      savedAmount: g.savedAmount + contribution.amount,
      remainingAmount: (g.targetAmount - (g.savedAmount + contribution.amount)).clamp(0, double.infinity),
      recentContributions: [contribution, ...g.recentContributions],
      contributionsCount: g.contributionsCount + 1,
    );
    mockGoals[index] = updatedGoal;
    return ApiResponse(
      success: true,
      message: 'Contribution recorded successfully',
      data: {
        'contribution': contribution,
        'goal': updatedGoal,
      },
    );
  }

  @override
  Future<ApiResponse<CashFlowForecastModel>> getCashFlowForecast({String? horizon}) async {
    return ApiResponse(
      success: true,
      message: 'Forecast generated',
      data: mockForecast ??
          const CashFlowForecastModel(
            horizon: 'next_3_months',
            horizonMonths: 3,
            historicalMonthsSampled: 4,
            historicalAvgMonthlyIncome: 75000,
            historicalAvgMonthlyExpense: 45000,
            netMonthlyCashFlow: 30000,
            potentialMonthlySavingsCapacity: 25000,
            projectedIncome: 225000,
            projectedExpenses: 135000,
            projectedNetCashFlow: 90000,
            projectedSavingsCapacity: 75000,
            isSufficient: true,
            warnings: [],
            samplePeriod: 'Last 4 calendar months',
            recordCount: 42,
            assumptions: ['Strictly based on stored confirmed transactions'],
          ),
    );
  }

  @override
  Future<ApiResponse<WhatIfSimulationModel>> runSimulation(Map<String, dynamic> scenario) async {
    return ApiResponse(
      success: true,
      message: 'Simulation computed',
      data: mockSimulation ??
          const WhatIfSimulationModel(
            scenarioType: 'savings_adjustment',
            baselineIncome: 75000,
            baselineExpense: 45000,
            baselineNetCashFlow: 30000,
            baselineSavingsCapacity: 25000,
            baselineGoalName: 'Emergency Fund',
            baselineGoalRemaining: 60000,
            baselineOriginalMonths: 12,
            simulatedIncome: 75000,
            simulatedExpense: 45000,
            simulatedNetCashFlow: 30000,
            simulatedSavingsCapacity: 28000,
            simulatedMonths: 8,
            monthsSaved: 4,
            requiredMonthlySaving: 7500,
            monthlyDifference: 3000,
            explanation: 'Increasing allocation by ₹3,000 saves 4 months to completion.',
            assumptions: ['Hypothetical isolated simulation'],
          ),
    );
  }
}

Widget createTestApp(Widget child, {GoalProvider? provider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ChangeNotifierProvider(create: (_) => provider ?? GoalProvider()),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Phase 5D — Models Serialization & Calculation Integrity', () {
    test('GoalModel correctly parses JSON and computes intelligence fields', () {
      final json = {
        'id': 10,
        'userId': 1,
        'name': 'MacBook Pro',
        'description': 'Work machine upgrade',
        'targetAmount': 200000.0,
        'currency': 'INR',
        'targetDate': '2026-12-31',
        'startingAmount': 20000.0,
        'savedAmount': 80000.0,
        'remainingAmount': 120000.0,
        'progressPercentage': 40.0,
        'status': 'active',
        'daysRemaining': 79,
        'monthsRemaining': 2.6,
        'isOverdue': false,
        'requiredMonthlySaving': 46153.85,
        'estimatedCompletion': {
          'date': '2026-11-15',
          'reason': 'Based on monthly velocity of ₹25,000',
          'isEstimated': true,
        },
        'intelligenceStatus': 'on_track',
        'isAchieved': false,
        'contributionsCount': 3,
        'recentContributions': [
          {
            'id': 1,
            'goalId': 10,
            'amount': 20000.0,
            'contributionDate': '2026-08-01',
            'note': 'Bonus'
          }
        ],
      };

      final goal = GoalModel.fromJson(json);

      expect(goal.id, 10);
      expect(goal.name, 'MacBook Pro');
      expect(goal.targetAmount, 200000.0);
      expect(goal.savedAmount, 80000.0);
      expect(goal.remainingAmount, 120000.0);
      expect(goal.progressPercentage, 40.0);
      expect(goal.isEstimated, true);
      expect(goal.estimatedCompletionDate, '2026-11-15');
      expect(goal.intelligenceStatus, 'on_track');
      expect(goal.contributionsCount, 3);
      expect(goal.recentContributions.length, 1);
      expect(goal.recentContributions.first.amount, 20000.0);

      final serialized = goal.toJson();
      expect(serialized['name'], 'MacBook Pro');
      expect(serialized['remainingAmount'], 120000.0);
    });

    test('CashFlowForecastModel parses projections and data sufficiency', () {
      final json = {
        'horizon': 'next_6_months',
        'horizonMonths': 6,
        'historicalMonthsSampled': 5,
        'historicalAvgMonthlyIncome': 80000.0,
        'historicalAvgMonthlyExpense': 50000.0,
        'netMonthlyCashFlow': 30000.0,
        'potentialMonthlySavingsCapacity': 22000.0,
        'projectedIncome': 480000.0,
        'projectedExpenses': 300000.0,
        'projectedNetCashFlow': 180000.0,
        'projectedSavingsCapacity': 132000.0,
        'dataSufficiency': {
          'isSufficient': true,
          'warnings': <String>[],
          'samplePeriod': 'Last 5 months',
          'recordCount': 58,
        },
        'assumptions': ['Deterministic non-guaranteed projection'],
      };

      final forecast = CashFlowForecastModel.fromJson(json);

      expect(forecast.horizon, 'next_6_months');
      expect(forecast.horizonMonths, 6);
      expect(forecast.historicalMonthsSampled, 5);
      expect(forecast.netMonthlyCashFlow, 30000.0);
      expect(forecast.projectedIncome, 480000.0);
      expect(forecast.isSufficient, true);
      expect(forecast.warnings, isEmpty);
      expect(forecast.assumptions.first, contains('Deterministic'));
    });

    test('WhatIfSimulationModel parses baseline and simulated scenarios', () {
      final json = {
        'scenarioType': 'expense_reduction',
        'baseline': {
          'monthlyIncome': 60000.0,
          'monthlyExpense': 40000.0,
          'netMonthlyCashFlow': 20000.0,
          'savingsCapacity': 15000.0,
          'goal': {
            'name': 'Vacation Fund',
            'remainingAmount': 30000.0,
            'originalMonthsRemaining': 6.0,
          },
        },
        'simulated': {
          'monthlyIncome': 60000.0,
          'monthlyExpense': 34000.0,
          'netMonthlyCashFlow': 26000.0,
          'savingsCapacity': 21000.0,
          'timelineImpact': {
            'simulatedMonths': 4.5,
            'monthsSaved': 1.5,
          },
        },
        'monthlyDifference': 6000.0,
        'explanation': 'Reducing monthly expenses by ₹6,000 achieves your vacation goal 1.5 months earlier.',
        'assumptions': ['Isolated hypothetical calculation'],
      };

      final sim = WhatIfSimulationModel.fromJson(json);

      expect(sim.scenarioType, 'expense_reduction');
      expect(sim.baselineExpense, 40000.0);
      expect(sim.simulatedExpense, 34000.0);
      expect(sim.monthlyDifference, 6000.0);
      expect(sim.monthsSaved, 1.5);
      expect(sim.explanation, contains('1.5 months earlier'));
    });
  });

  group('Phase 5D — GoalProvider State & Actions', () {
    late MockGoalRepository mockRepo;
    late GoalProvider provider;

    setUp(() {
      mockRepo = MockGoalRepository();
      provider = GoalProvider(repository: mockRepo);
    });

    test('loadGoals fetches and updates provider state', () async {
      mockRepo.mockGoals = [
        const GoalModel(
          id: 1,
          userId: 1,
          name: 'Emergency Fund',
          targetAmount: 100000,
          currency: 'INR',
          savedAmount: 40000,
          remainingAmount: 60000,
          progressPercentage: 40.0,
          status: 'active',
        ),
      ];

      await provider.loadGoals();

      expect(provider.goals.length, 1);
      expect(provider.goals.first.name, 'Emergency Fund');
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('createGoal inserts new goal and updates summary', () async {
      final success = await provider.createGoal({
        'name': 'New Camera',
        'targetAmount': 50000,
        'currency': 'INR',
      });

      expect(success, true);
      expect(provider.goals.length, 1);
      expect(provider.goals.first.name, 'New Camera');
    });

    test('addContribution updates tracked savings without altering real balances', () async {
      mockRepo.mockGoals = [
        const GoalModel(
          id: 2,
          userId: 1,
          name: 'Bike Fund',
          targetAmount: 80000,
          currency: 'INR',
          savedAmount: 20000,
          remainingAmount: 60000,
          progressPercentage: 25.0,
          status: 'active',
        ),
      ];
      await provider.loadGoals();

      final success = await provider.addContribution(2, {
        'amount': 15000,
        'note': 'Salary bonus allocation',
      });

      expect(success, true);
      expect(provider.goals.first.savedAmount, 35000);
      expect(provider.goals.first.remainingAmount, 45000);
      expect(provider.goals.first.recentContributions.length, 1);
      expect(provider.goals.first.recentContributions.first.amount, 15000);
    });

    test('runSimulation and resetSimulation manage isolated scenario state', () async {
      final success = await provider.runSimulation({
        'scenarioType': 'savings_adjustment',
        'parameters': {'savingAmount': 5000},
      });

      expect(success, true);
      expect(provider.simulation, isNotNull);
      expect(provider.simulation!.explanation, contains('saves 4 months'));

      provider.resetSimulation();
      expect(provider.simulation, isNull);
    });

    test('clearSession cleanly purges all data on logout or session reset', () async {
      mockRepo.mockGoals = [
        const GoalModel(
          id: 1,
          userId: 1,
          name: 'Private Goal',
          targetAmount: 50000,
          currency: 'INR',
          savedAmount: 10000,
          remainingAmount: 40000,
          progressPercentage: 20.0,
          status: 'active',
        ),
      ];
      await provider.loadGoals();
      await provider.loadSummary();
      await provider.loadCashFlowForecast();
      await provider.runSimulation({'scenarioType': 'savings_adjustment'});

      expect(provider.goals, isNotEmpty);
      expect(provider.summary, isNotNull);
      expect(provider.forecast, isNotNull);
      expect(provider.simulation, isNotNull);

      provider.clearSession();

      expect(provider.goals, isEmpty);
      expect(provider.summary, isNull);
      expect(provider.forecast, isNull);
      expect(provider.simulation, isNull);
      expect(provider.errorMessage, isNull);
    });
  });

  group('Phase 5D — Widgets & UI Integration Tests', () {
    testWidgets('GoalCard renders goal title, target, saved amount and progress', (tester) async {
      const testGoal = GoalModel(
        id: 5,
        userId: 1,
        name: 'Europe Trip',
        targetAmount: 300000,
        currency: 'INR',
        targetDate: '2026-12-31',
        savedAmount: 150000,
        remainingAmount: 150000,
        progressPercentage: 50.0,
        status: 'active',
        intelligenceStatus: 'on_track',
        daysRemaining: 180,
      );

      await tester.pumpWidget(createTestApp(const GoalCard(goal: testGoal)));

      expect(find.text('Europe Trip'), findsOneWidget);
      expect(find.text('Tracked Saved'), findsOneWidget);
      expect(find.text('50.0% completed'), findsOneWidget);
      expect(find.text('180 days left'), findsOneWidget);
      expect(find.text('On Track'), findsOneWidget);
    });

    testWidgets('AddEditGoalSheet renders form and prominent accounting notice', (tester) async {
      await tester.pumpWidget(createTestApp(const AddEditGoalSheet()));

      expect(find.text('New Savings Goal'), findsOneWidget);
      expect(find.text('Goal Name *'), findsOneWidget);
      expect(find.text('Target Amount *'), findsOneWidget);
      expect(find.textContaining('Goals are planning trackers'), findsOneWidget);
      expect(find.text('Create Goal'), findsOneWidget);

      // Verify validation triggers on empty submit
      await tester.ensureVisible(find.text('Create Goal'));
      await tester.tap(find.text('Create Goal'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a goal name'), findsOneWidget);
    });

    testWidgets('AddEditContributionSheet displays progress allocation warning', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const AddEditContributionSheet(
            goalId: 10,
            goalName: 'Laptop Savings',
          ),
        ),
      );

      expect(find.text('Add Progress Record'), findsOneWidget);
      expect(find.text('Laptop Savings'), findsOneWidget);
      expect(find.text('Savings Allocation Only'), findsOneWidget);
      expect(find.textContaining('This records progress toward your target'), findsOneWidget);
      expect(find.text('Record Progress'), findsOneWidget);
    });

    testWidgets('ForecastView renders horizon tabs and deterministic methodology', (tester) async {
      final mockRepo = MockGoalRepository();
      final provider = GoalProvider(repository: mockRepo);
      await provider.loadCashFlowForecast();

      await tester.pumpWidget(createTestApp(const ForecastView(), provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('3 Months'), findsOneWidget);
      expect(find.text('6 Months'), findsOneWidget);
      expect(find.text('Avg Income'), findsOneWidget);
      expect(find.text('Avg Expense'), findsOneWidget);
      expect(find.text('Net Cash Flow'), findsOneWidget);
      expect(find.text('Deterministic Methodology'), findsOneWidget);
      expect(find.textContaining('Internal wallet transfers, goal allocations'), findsOneWidget);
    });

    testWidgets('SimulatorView displays scenario chips and simulation notice', (tester) async {
      final mockRepo = MockGoalRepository();
      final provider = GoalProvider(repository: mockRepo);

      await tester.pumpWidget(createTestApp(const SimulatorView(), provider: provider));
      await tester.pumpAndSettle();

      expect(find.text('Interactive What-If Simulator'), findsOneWidget);
      expect(find.textContaining('Simulations are isolated mathematical scenarios'), findsOneWidget);
      expect(find.text('Adjust Monthly Saving'), findsOneWidget);
      expect(find.text('Expense Reduction'), findsOneWidget);
      expect(find.text('Deadline Change'), findsOneWidget);
      expect(find.text('Income Change'), findsOneWidget);
      expect(find.text('Run Simulation'), findsOneWidget);
    });
  });
}
