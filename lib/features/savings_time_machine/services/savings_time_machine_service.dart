import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../core/utils/serp_api_service.dart';

// =============================================================================
// Savings Time Machine — LTV Phase 2 Feature #10
// =============================================================================
//
// Покажи юзеру майбутнє: "Якщо відкладатимеш 500 грн/місяць, то до березня
// 2027 матимеш 6000 грн — достатньо на PS5 Slim за прогнозованою ціною
// 18500 грн (зараз 28000, падіння 34% за 9 місяців)".
//
// API: OpenRouter для прогнозу ціни + SerpAPI для поточної ціни
// XP: +5 за створення прогнозу, +3 за щомісячне оновлення
// =============================================================================

/// Rich data model for a Time Machine projection.
class TimeMachineModel {
  final TimeMachineProjection data;
  final String goalName;
  final double goalTargetAmount;
  final double currentSavings;

  const TimeMachineModel({
    required this.data,
    this.goalName = '',
    this.goalTargetAmount = 0.0,
    this.currentSavings = 0.0,
  });

  /// Months until projected savings reach projected price.
  int get monthsToGoal {
    if (data.monthlyDeposit <= 0) return 999;
    final remaining = data.projectedPrice - currentSavings;
    if (remaining <= 0) return 0;
    return (remaining / data.monthlyDeposit).ceil();
  }

  /// Estimated purchase date.
  DateTime get estimatedPurchaseDate {
    final months = monthsToGoal;
    return DateTime(
      DateTime.now().year + (DateTime.now().month + months) ~/ 12,
      (DateTime.now().month + months) % 12 + 1,
    );
  }

  /// Progress percentage: current savings vs projected price.
  double get progressPercent {
    if (data.projectedPrice <= 0) return 0;
    return (currentSavings / data.projectedPrice * 100).clamp(0.0, 100.0);
  }

  /// Whether savings will be sufficient.
  bool get willAfford => data.projectedSavings >= data.projectedPrice;

  /// Confidence level label.
  String get confidenceLabel {
    final score = data.confidenceScore;
    if (score >= 80) return 'ВИСОКА';
    if (score >= 60) return 'СЕРЕДНЯ';
    if (score >= 40) return 'НИЗЬКА';
    return 'НЕВИЗНАЧЕНА';
  }
}

/// State for the Savings Time Machine feature.
class SavingsTimeMachineState {
  final List<TimeMachineModel> projections;
  final bool isLoading;
  final String? error;

  const SavingsTimeMachineState({
    this.projections = const [],
    this.isLoading = false,
    this.error,
  });

  int get totalProjections => projections.length;

  SavingsTimeMachineState copyWith({
    List<TimeMachineModel>? projections,
    bool? isLoading,
    String? error,
  }) {
    return SavingsTimeMachineState(
      projections: projections ?? this.projections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier for Savings Time Machine.
class SavingsTimeMachineNotifier extends StateNotifier<SavingsTimeMachineState> {
  final AppDatabase _db;
  final SerpApiService _serpApi;
  final OpenRouterService _ai;

  SavingsTimeMachineNotifier(this._db, this._serpApi, this._ai)
      : super(const SavingsTimeMachineState());

  /// Loads all projections from the database.
  Future<void> loadProjections() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projections = await _db.getAllTimeMachineProjections();
      final goals = await _db.getAllGoals();
      final goalMap = {for (final g in goals) g.id: g};

      final models = projections.map((p) {
        final goal = goalMap[p.goalId];
        return TimeMachineModel(
          data: p,
          goalName: goal?.name ?? '',
          goalTargetAmount: goal?.targetAmount ?? 0.0,
          currentSavings: goal?.savedAmount ?? 0.0,
        );
      }).toList();

      state = state.copyWith(projections: models, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Creates a new projection for a goal.
  Future<void> createProjection({
    required int goalId,
    required double monthlyDeposit,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final goal = await _db.getGoalById(goalId);
      if (goal == null) {
        state = state.copyWith(isLoading: false, error: 'Ціль не знайдено');
        return;
      }

      // Step 1: Get current market price via SerpAPI
      final productName = goal.name;
      final cheapest = await _serpApi.findCheapestOffer(
        '$productName купити Україна ціна',
        numResults: 10,
      );
      final currentPrice = cheapest['price'] as double? ?? goal.targetAmount;

      // Step 2: Get AI price forecast via OpenRouter
      final forecast = await _ai.chatJson(
        systemPrompt:
            'Ти VAULT-17, кібернетичний аналітик цін в NEONCRED. '
            'Відповідай ТІЛЬКИ JSON. Прогнозуй ціну товару в Україні через 6-12 місяців. '
            'Враховуй: сезонні знижки, річне знецінення електроніки (15-25%), '
            'випуск нових моделей, інфляцію грн.',
        userPrompt:
            'Товар: $productName\n'
            'Поточная ціна: ${currentPrice.toStringAsFixed(0)} грн\n'
            'Місячний внесок: ${monthlyDeposit.toStringAsFixed(0)} грн\n'
            'Поточні заощадження: ${goal.savedAmount.toStringAsFixed(0)} грн\n'
            'Цільова сума: ${goal.targetAmount.toStringAsFixed(0)} грн\n\n'
            'Верни JSON:\n'
            '{\n'
            '  "projected_price": <ціна через 9 місяців>,\n'
            '  "price_drop_percent": <відсоток падіння>,\n'
            '  "confidence_score": <0-100>,\n'
            '  "projected_date_months": <місяців до покупки>,\n'
            '  "analysis": "<короткий аналіз українською>"\n'
            '}',
        temperature: 0.7,
        maxTokens: 400,
      );

      double projectedPrice = currentPrice;
      double priceDropPercent = 0.0;
      double confidenceScore = 50.0;
      int projectedDateMonths = 9;
      String analysis = '';

      if (forecast != null) {
        projectedPrice =
            (forecast['projected_price'] as num?)?.toDouble() ?? currentPrice;
        priceDropPercent =
            (forecast['price_drop_percent'] as num?)?.toDouble() ?? 0.0;
        confidenceScore =
            (forecast['confidence_score'] as num?)?.toDouble() ?? 50.0;
        projectedDateMonths =
            (forecast['projected_date_months'] as num?)?.toInt() ?? 9;
        analysis = (forecast['analysis'] as String?) ?? '';
      }

      // Calculate projected date
      final projectedDate = DateTime(
        DateTime.now().year + (DateTime.now().month + projectedDateMonths) ~/ 12,
        (DateTime.now().month + projectedDateMonths) % 12 + 1,
      );

      // Calculate projected savings
      final projectedSavings =
          goal.savedAmount + (monthlyDeposit * projectedDateMonths);

      // Delete existing projection for this goal
      await _db.deleteTimeMachineProjectionsByGoalId(goalId);

      // Insert new projection
      await _db.insertTimeMachineProjection(TimeMachineProjectionsCompanion.insert(
        goalId: goalId,
        monthlyDeposit: monthlyDeposit,
        projectedDate: Value(projectedDate),
        projectedSavings: Value(projectedSavings),
        projectedPrice: Value(projectedPrice),
        priceDropPercent: Value(priceDropPercent),
        confidenceScore: Value(confidenceScore),
        aiAnalysis: Value(analysis),
        lastUpdatedAt: Value(DateTime.now()),
      ));

      // +5 XP for creating a projection
      await _db.addXP(5, source: 'time_machine_projection');

      await loadProjections();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updates an existing projection (re-forecast).
  Future<void> refreshProjection(int projectionId, int goalId) async {
    final existing = state.projections
        .where((p) => p.data.id == projectionId)
        .firstOrNull;

    if (existing == null) return;

    await createProjection(
      goalId: goalId,
      monthlyDeposit: existing.data.monthlyDeposit,
    );

    // +3 XP for refreshing
    await _db.addXP(3, source: 'time_machine_refresh');
  }

  /// Deletes a projection.
  Future<void> deleteProjection(int id) async {
    await _db.deleteTimeMachineProjection(id);
    await loadProjections();
  }
}

/// Provider for Savings Time Machine.
final savingsTimeMachineProvider =
    StateNotifierProvider<SavingsTimeMachineNotifier, SavingsTimeMachineState>(
  (ref) {
    final db = ref.read(databaseProvider);
    final serpApi = ref.read(serpApiServiceProvider);
    final ai = ref.read(openRouterServiceProvider);
    return SavingsTimeMachineNotifier(db, serpApi, ai);
  },
);
