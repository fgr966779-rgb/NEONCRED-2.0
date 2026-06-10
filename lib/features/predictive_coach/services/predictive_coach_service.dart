import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Predictive Savings Coach — Retention 2026 Feature #6
// =============================================================================
//
// AI аналізує патерн депозитів і прогнозує "небезпечні вікна" — дні коли
// юзер найімовірніше не відкладе. За 24 години до небезпечного дня —
// проактивний нудж: "Завтра ти зазвичай витрачаєш на 200 грн більше.
// Відклади зараз 100 грн щоб не втратити серію."
//
// API: OpenRouter для аналізу патернів + прогнозу
// XP: +3 за кожен нудж на який юзер відреагував
// =============================================================================

/// Prediction type definitions.
enum PredictionType {
  dangerWindow('danger_window', 'Небезпечне вікно'),
  noSpendRisk('no_spend_risk', 'Ризик невідкладення'),
  streakThreat('streak_threat', 'Загроза серії'),
  overspendAlert('overspend_alert', 'Перевитрати');

  const PredictionType(this.id, this.labelUA);
  final String id;
  final String labelUA;
}

/// Rich model for a coach prediction.
class CoachPredictionModel {
  final CoachPrediction data;
  final bool isImminent; // danger date is within 24 hours

  const CoachPredictionModel({
    required this.data,
    this.isImminent = false,
  });

  /// Time until danger date.
  Duration get timeUntilDanger => data.dangerDate.difference(DateTime.now());

  /// Human-readable time until danger.
  String get timeUntilDangerStr {
    final d = timeUntilDanger;
    if (d.inDays > 0) return '${d.inDays}д ${d.inHours % 24}год';
    if (d.inHours > 0) return '${d.inHours}год ${d.inMinutes % 60}хв';
    return '${d.inMinutes}хв';
  }

  /// Is this prediction still relevant (danger date in the future).
  bool get isRelevant => data.dangerDate.isAfter(DateTime.now());

  /// Severity color indicator.
  String get severityLabel {
    final hours = timeUntilDanger.inHours;
    if (hours <= 6) return 'КРИТИЧНО';
    if (hours <= 24) return 'ТЕРМІНОВО';
    if (hours <= 72) return 'НЕЗАБАРОМ';
    return 'СПОСТЕРЕЖЕННЯ';
  }
}

/// State for the Predictive Savings Coach.
class PredictiveCoachState {
  final List<CoachPredictionModel> predictions;
  final bool isLoading;
  final String? error;
  final int totalNudgesActedOn;
  final double averageConfidence;

  const PredictiveCoachState({
    this.predictions = const [],
    this.isLoading = false,
    this.error,
    this.totalNudgesActedOn = 0,
    this.averageConfidence = 0.0,
  });

  int get activeAlerts =>
      predictions.where((p) => p.isRelevant && !p.data.isUserActed).length;
  int get criticalAlerts =>
      predictions.where((p) => p.isImminent && !p.data.isUserActed).length;

  PredictiveCoachState copyWith({
    List<CoachPredictionModel>? predictions,
    bool? isLoading,
    String? error,
    int? totalNudgesActedOn,
    double? averageConfidence,
  }) {
    return PredictiveCoachState(
      predictions: predictions ?? this.predictions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalNudgesActedOn: totalNudgesActedOn ?? this.totalNudgesActedOn,
      averageConfidence: averageConfidence ?? this.averageConfidence,
    );
  }
}

/// StateNotifier for Predictive Savings Coach.
class PredictiveCoachNotifier extends StateNotifier<PredictiveCoachState> {
  final AppDatabase _db;
  final OpenRouterService _ai;

  PredictiveCoachNotifier(this._db, this._ai)
      : super(const PredictiveCoachState());

  /// Loads all predictions from the database.
  Future<void> loadPredictions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final predictions = await _db.getAllCoachPredictions();
      final now = DateTime.now();

      int actedOn = 0;
      double totalConfidence = 0;

      final models = predictions.map((p) {
        final isImminent = p.dangerDate.difference(now).inHours <= 24;
        if (p.isUserActed) actedOn++;
        totalConfidence += p.confidenceScore;
        return CoachPredictionModel(data: p, isImminent: isImminent);
      }).toList();

      final avgConfidence =
          predictions.isNotEmpty ? totalConfidence / predictions.length : 0.0;

      state = state.copyWith(
        predictions: models,
        isLoading: false,
        totalNudgesActedOn: actedOn,
        averageConfidence: avgConfidence,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Analyzes deposit patterns and generates predictions.
  Future<void> analyzeAndPredict() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deposits = await _db.getAllDeposits();
      final goals = await _db.getActiveGoals();
      final user = await _db.getUserProfile();

      // Build deposit pattern summary for AI
      final depositDates = deposits.map((d) => d.createdAt.toIso8601String()).toList();
      final depositAmounts = deposits.map((d) => d.amount).toList();
      final avgDeposit = depositAmounts.isNotEmpty
          ? depositAmounts.reduce((a, b) => a + b) / depositAmounts.length
          : 0.0;
      final currentStreak = user?.currentStreak ?? 0;
      final lastDeposit = deposits.isNotEmpty
          ? deposits.last.createdAt
          : null;

      // Find gaps in deposit history (days without deposits)
      List<String> gapDays = [];
      if (deposits.length >= 3) {
        final sortedDeposits = List.of(deposits)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        for (int i = 1; i < sortedDeposits.length; i++) {
          final gap = sortedDeposits[i]
              .createdAt
              .difference(sortedDeposits[i - 1].createdAt)
              .inDays;
          if (gap > 3) {
            gapDays.add(
                '${sortedDeposits[i - 1].createdAt.day}/${sortedDeposits[i - 1].createdAt.month} - ${sortedDeposits[i].createdAt.day}/${sortedDeposits[i].createdAt.month} ($gap днів)');
          }
        }
      }

      final predictionId = 'CP-${_randomId()}';

      final result = await _ai.chatJson(
        systemPrompt:
            'Ти VAULT-17, кібернетичний аналітик поведінки в NEONCRED. '
            'Аналізуй патерн депозитів і передбачай "небезпечні вікна" — '
            'дні коли юзер найімовірніше не відкладе гроші. '
            'Враховуй: день тижня, час місяця (зарплата/кінець місяця), '
            'історію пропусків, тривалість серії. '
            'Відповідай ТІЛЬКИ JSON.',
        userPrompt:
            'Кількість депозитів: ${deposits.length}\n'
            'Середній депозит: ${avgDeposit.toStringAsFixed(0)} грн\n'
            'Поточна серія: $currentStreak днів\n'
            'Останній депозит: ${lastDeposit?.toIso8601String() ?? "немає"}\n'
            'Пропуски в історії: ${gapDays.take(5).join("; ")}\n'
            'Активні цілі: ${goals.map((g) => g.name).join(", ")}\n'
            'Сьогодні: ${DateTime.now().toIso8601String()}\n\n'
            'Згенеруй 1-3 прогнози у форматі:\n'
            '[\n'
            '  {\n'
            '    "type": "danger_window|no_spend_risk|streak_threat|overspend_alert",\n'
            '    "danger_date": "YYYY-MM-DD",\n'
            '    "confidence": <0-100>,\n'
            '    "recommendation": "<порада українською, 1-2 речення>",\n'
            '    "suggested_amount": <сума для депозиту>\n'
            '  }\n'
            ']',
        temperature: 0.7,
        maxTokens: 500,
      );

      if (result != null) {
        final List<dynamic> predList;
        if (result is List) {
          predList = result as List<dynamic>;
        } else if (result['predictions'] is List) {
          predList = result['predictions'] as List<dynamic>;
        } else {
          predList = [];
        }
        for (final predJson in predList) {
          if (predJson is Map<String, dynamic>) {
            final dangerDateStr = predJson['danger_date'] as String? ??
                DateTime.now().add(const Duration(days: 1)).toIso8601String();
            final dangerDate = DateTime.tryParse(dangerDateStr) ??
                DateTime.now().add(const Duration(days: 1));

            await _db.insertCoachPrediction(CoachPredictionsCompanion.insert(
              predictionId: predictionId,
              predictionType: predJson['type'] as String? ?? 'danger_window',
              dangerDate: dangerDate,
              confidenceScore:
                  Value((predJson['confidence'] as num?)?.toDouble() ?? 60.0),
              aiRecommendation:
                  Value(predJson['recommendation'] as String? ?? ''),
              suggestedDepositAmount:
                  Value((predJson['suggested_amount'] as num?)?.toDouble() ?? 100.0),
            ));
          }
        }
        if (predList.isEmpty) {
          await _generateFallbackPrediction(predictionId, avgDeposit, currentStreak);
        }
      } else {
        // Fallback: generate a basic danger window prediction
        await _generateFallbackPrediction(predictionId, avgDeposit, currentStreak);
      }

      await loadPredictions();
    } catch (e) {
      // Fallback on error
      final predictionId = 'CP-${_randomId()}';
      await _generateFallbackPrediction(predictionId, 100, 0);
      await loadPredictions();
    }
  }

  /// User acted on a prediction (made a deposit).
  Future<void> markActed(int predictionId) async {
    await _db.updateCoachPrediction(
      predictionId,
      const CoachPredictionsCompanion(
        isUserActed: Value(true),
        xpAwarded: Value(3),
      ),
    );
    await _db.addXP(3, source: 'coach_prediction_acted');
    await loadPredictions();
  }

  /// Dismiss a prediction.
  Future<void> dismiss(int id) async {
    await _db.deleteCoachPrediction(id);
    await loadPredictions();
  }

  /// Generates a fallback prediction if AI is unavailable.
  Future<void> _generateFallbackPrediction(
      String predictionId, double avgDeposit, int streak) async {
    final now = DateTime.now();

    // Predict danger: end of month is typically high-spend
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysUntilEnd = endOfMonth.difference(now).inDays;

    await _db.insertCoachPrediction(CoachPredictionsCompanion.insert(
      predictionId: predictionId,
      predictionType: 'danger_window',
      dangerDate: now.add(Duration(days: daysUntilEnd.clamp(1, 3))),
      confidenceScore: Value(65.0),
      aiRecommendation:
          Value('Кінець місяця — час підвищених витрат. Відклади '
          '${avgDeposit.toStringAsFixed(0)} грн зараз, щоб не втратити серію.'),
      suggestedDepositAmount: Value(avgDeposit * 0.5),
    ));

    // Also predict weekend risk
    final nextFriday = now.add(Duration(days: (5 - now.weekday) % 7));
    if (nextFriday.isAfter(now)) {
      await _db.insertCoachPrediction(CoachPredictionsCompanion.insert(
        predictionId: predictionId,
        predictionType: 'overspend_alert',
        dangerDate: nextFriday,
        confidenceScore: Value(55.0),
        aiRecommendation:
            Value('Вихідні наближаються — витрати зростають. Зроби депозит до пятниці.'),
        suggestedDepositAmount: Value(avgDeposit),
      ));
    }
  }

  String _randomId() {
    final rng = Random();
    return '${rng.nextInt(90000) + 10000}';
  }
}

/// Provider for the Predictive Savings Coach.
final predictiveCoachProvider =
    StateNotifierProvider<PredictiveCoachNotifier, PredictiveCoachState>(
  (ref) {
    final db = ref.read(databaseProvider);
    final ai = ref.read(openRouterServiceProvider);
    return PredictiveCoachNotifier(db, ai);
  },
);
