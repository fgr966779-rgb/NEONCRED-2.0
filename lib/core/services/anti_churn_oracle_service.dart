import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/open_router_service.dart';
import '../../data/database.dart';

// ---------------------------------------------------------------------------
// ChurnSignal — behavioral signals that indicate a user may churn
// ---------------------------------------------------------------------------

enum ChurnSignal {
  depositFrequencyDrop,
  streakAtRisk,
  appOpenDecline,
  amountDecline,
  pushIgnored,
  goalAbandonmentRisk,
}

// ---------------------------------------------------------------------------
// ChurnAnalysis — result of the oracle's analysis
// ---------------------------------------------------------------------------

class ChurnAnalysis {
  final double churnProbability; // 0.0 – 1.0
  final List<ChurnSignal> detectedSignals;
  final String rescueNarrativeUA; // AI-generated Ukrainian rescue narrative
  final String rescueNarrativeEN;
  final List<String> recommendedActions;
  final int rescueQuestXP; // 200 – 1000 based on severity
  final DateTime analyzedAt;

  const ChurnAnalysis({
    required this.churnProbability,
    required this.detectedSignals,
    required this.rescueNarrativeUA,
    required this.rescueNarrativeEN,
    required this.recommendedActions,
    required this.rescueQuestXP,
    required this.analyzedAt,
  });

  ChurnAnalysis copyWith({
    double? churnProbability,
    List<ChurnSignal>? detectedSignals,
    String? rescueNarrativeUA,
    String? rescueNarrativeEN,
    List<String>? recommendedActions,
    int? rescueQuestXP,
    DateTime? analyzedAt,
  }) {
    return ChurnAnalysis(
      churnProbability: churnProbability ?? this.churnProbability,
      detectedSignals: detectedSignals ?? this.detectedSignals,
      rescueNarrativeUA: rescueNarrativeUA ?? this.rescueNarrativeUA,
      rescueNarrativeEN: rescueNarrativeEN ?? this.rescueNarrativeEN,
      recommendedActions: recommendedActions ?? this.recommendedActions,
      rescueQuestXP: rescueQuestXP ?? this.rescueQuestXP,
      analyzedAt: analyzedAt ?? this.analyzedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// RescueMission — a personalized quest designed to re-engage the user
// ---------------------------------------------------------------------------

class RescueMission {
  final String id;
  final String titleUA;
  final String descriptionUA;
  final int targetDeposits; // e.g. "make 3 deposits in 5 days"
  final int daysToComplete;
  final int bonusXP;
  final bool isCompleted;
  final DateTime createdAt;

  const RescueMission({
    required this.id,
    required this.titleUA,
    required this.descriptionUA,
    required this.targetDeposits,
    required this.daysToComplete,
    required this.bonusXP,
    required this.isCompleted,
    required this.createdAt,
  });

  RescueMission copyWith({
    String? id,
    String? titleUA,
    String? descriptionUA,
    int? targetDeposits,
    int? daysToComplete,
    int? bonusXP,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return RescueMission(
      id: id ?? this.id,
      titleUA: titleUA ?? this.titleUA,
      descriptionUA: descriptionUA ?? this.descriptionUA,
      targetDeposits: targetDeposits ?? this.targetDeposits,
      daysToComplete: daysToComplete ?? this.daysToComplete,
      bonusXP: bonusXP ?? this.bonusXP,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ---------------------------------------------------------------------------
// AntiChurnState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class AntiChurnState {
  final ChurnAnalysis? lastAnalysis;
  final List<RescueMission> activeMissions;
  final bool isAnalyzing;
  final String? error;

  const AntiChurnState({
    this.lastAnalysis,
    this.activeMissions = const [],
    this.isAnalyzing = false,
    this.error,
  });

  AntiChurnState copyWith({
    ChurnAnalysis? lastAnalysis,
    List<RescueMission>? activeMissions,
    bool? isAnalyzing,
    String? error,
  }) {
    return AntiChurnState(
      lastAnalysis: lastAnalysis ?? this.lastAnalysis,
      activeMissions: activeMissions ?? this.activeMissions,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// AntiChurnOracleNotifier — the oracle that predicts churn & launches rescue
// ---------------------------------------------------------------------------

class AntiChurnOracleNotifier extends StateNotifier<AntiChurnState> {
  final Ref _ref;

  static const _churnThreshold = 0.6;
  static const _weightDepositFrequencyDrop = 0.25;
  static const _weightStreakRisk = 0.20;
  static const _weightGoalAbandonment = 0.20;
  static const _weightAmountDecline = 0.15;
  static const _weightPushIgnored = 0.10;
  static const _weightAppOpenDecline = 0.10;

  AntiChurnOracleNotifier(this._ref) : super(const AntiChurnState());

  bool get isAtRisk =>
      state.lastAnalysis?.churnProbability != null &&
      state.lastAnalysis!.churnProbability > _churnThreshold;

  // -----------------------------------------------------------------------
  // analyzeChurnRisk — main entry point
  // -----------------------------------------------------------------------

  Future<void> analyzeChurnRisk() async {
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final database = _ref.read(databaseProvider);
      final profile = await database.getUserProfile();
      final goals = await database.getAllGoals();
      final deposits = await database.getAllDeposits();

      if (profile == null) {
        state = state.copyWith(
          isAnalyzing: false,
          error: "User profile not found",
        );
        return;
      }

      // Step 1 — Calculate raw churn score from weighted signals
      final churnScore = _calculateChurnScore(profile, goals, deposits);

      // Step 2 — Determine which signals are active
      final detectedSignals = <ChurnSignal>[];

      final depositFrequencyScore =
          _depositFrequencyDropScore(profile, deposits);
      if (depositFrequencyScore > 0.3) {
        detectedSignals.add(ChurnSignal.depositFrequencyDrop);
      }

      final streakScore = _streakRiskScore(profile);
      if (streakScore > 0.3) {
        detectedSignals.add(ChurnSignal.streakAtRisk);
      }

      final goalAbandonmentScore = _goalAbandonmentScore(goals);
      if (goalAbandonmentScore > 0.3) {
        detectedSignals.add(ChurnSignal.goalAbandonmentRisk);
      }

      final amountDeclineScore = _amountDeclineScore(deposits);
      if (amountDeclineScore > 0.3) {
        detectedSignals.add(ChurnSignal.amountDecline);
      }

      final pushIgnoreScore = _pushIgnoreScore(profile);
      if (pushIgnoreScore > 0.3) {
        detectedSignals.add(ChurnSignal.pushIgnored);
      }

      final appOpenScore = _appOpenDeclineScore(profile);
      if (appOpenScore > 0.3) {
        detectedSignals.add(ChurnSignal.appOpenDecline);
      }

      // Step 3 — Build recommended actions
      final recommendedActions = _buildRecommendedActions(detectedSignals);

      // Step 4 — Determine rescue XP (200–1000 based on severity)
      final rescueQuestXP = _calculateRescueXP(churnScore);

      // Step 5 — Generate AI rescue narratives
      String rescueNarrativeUA = "";
      String rescueNarrativeEN = "";

      if (churnScore > _churnThreshold) {
        final narratives = await _generateRescueNarratives(
          churnScore,
          detectedSignals,
          profile,
          goals,
          deposits,
        );
        rescueNarrativeUA = narratives["ua"] ?? "";
        rescueNarrativeEN = narratives["en"] ?? "";
      }

      // Step 6 — Assemble analysis
      final analysis = ChurnAnalysis(
        churnProbability: churnScore.clamp(0.0, 1.0),
        detectedSignals: detectedSignals,
        rescueNarrativeUA: rescueNarrativeUA,
        rescueNarrativeEN: rescueNarrativeEN,
        recommendedActions: recommendedActions,
        rescueQuestXP: rescueQuestXP,
        analyzedAt: DateTime.now(),
      );

      // Step 7 — If at risk, generate a rescue mission
      List<RescueMission> currentMissions =
          List<RescueMission>.from(state.activeMissions);

      if (churnScore > _churnThreshold) {
        final mission = await generateRescueMission(analysis);
        if (mission != null) {
          currentMissions.add(mission);
        }
      }

      state = state.copyWith(
        lastAnalysis: analysis,
        activeMissions: currentMissions,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }

  // -----------------------------------------------------------------------
  // generateRescueMission — creates a personalized rescue quest via AI
  // -----------------------------------------------------------------------

  Future<RescueMission?> generateRescueMission(
    ChurnAnalysis analysis,
  ) async {
    try {
      final openRouter = _ref.read(openRouterServiceProvider);

      final targetDeposits = analysis.churnProbability > 0.8 ? 5 : 3;
      final daysToComplete = analysis.churnProbability > 0.8 ? 7 : 5;

      final signalDescriptions = analysis.detectedSignals.map((signal) {
        switch (signal) {
          case ChurnSignal.depositFrequencyDrop:
            return "Deposit frequency has dropped significantly";
          case ChurnSignal.streakAtRisk:
            return "User's savings streak is at risk of breaking";
          case ChurnSignal.appOpenDecline:
            return "App open rate has declined";
          case ChurnSignal.amountDecline:
            return "Deposit amounts are declining";
          case ChurnSignal.pushIgnored:
            return "Push notifications are being ignored";
          case ChurnSignal.goalAbandonmentRisk:
            return "Goal abandonment signals detected";
        }
      }).join("; ");

      final missionData = await openRouter.chatJson(
        systemPrompt: 'You are VAULT-17, a dramatic AI oracle in a gamified savings app. '
            'You speak in a sci-fi narrative tone, mixing Ukrainian and tech jargon. '
            'You always respond in valid JSON format only.',
        userPrompt: 'A user is at ${_formatPercent(analysis.churnProbability)} risk of churning.\n'
            'Detected signals: $signalDescriptions\n\n'
            'Generate a RESCUE MISSION in Ukrainian (with a compelling sci-fi narrative).\n'
            'The mission requires the user to make $targetDeposits deposits within $daysToComplete days.\n\n'
            'Respond in EXACTLY this JSON format (no markdown, no code fences):\n'
            '{"title_ua": "Ukrainian title for the rescue mission", '
            '"description_ua": "Ukrainian narrative description. Be dramatic, use VAULT-17 persona. '
            'Mention the specific threat and the rescue objective. Use the VAULT-17 sci-fi tone."}\n\n'
            'Example tone: "VAULT-17 виявив аномалію... твій стрік під загрозою колапсу. '
            'Стабілізуй систему 3 депозитами за 5 днів!"',
        temperature: 0.85,
        maxTokens: 512,
      );

      if (missionData != null) {
        return RescueMission(
          id: "rescue_${DateTime.now().millisecondsSinceEpoch}",
          titleUA: missionData['title_ua'] as String? ?? "Рятівна місія VAULT-17",
          descriptionUA:
              missionData['description_ua'] as String? ??
              "VAULT-17 виявив аномалію. Стабілізуй систему депозитами!",
          targetDeposits: targetDeposits,
          daysToComplete: daysToComplete,
          bonusXP: analysis.rescueQuestXP,
          isCompleted: false,
          createdAt: DateTime.now(),
        );
      } else {
        return _createFallbackMission(analysis, targetDeposits, daysToComplete);
      }
    } catch (e) {
      return _createFallbackMission(
        analysis,
        analysis.churnProbability > 0.8 ? 5 : 3,
        analysis.churnProbability > 0.8 ? 7 : 5,
      );
    }
  }

  // -----------------------------------------------------------------------
  // completeRescueMission — marks mission complete, awards bonus XP
  // -----------------------------------------------------------------------

  Future<void> completeRescueMission(String missionId) async {
    final missions = List<RescueMission>.from(state.activeMissions);
    final index = missions.indexWhere((m) => m.id == missionId);

    if (index == -1) return;

    final mission = missions[index];
    missions[index] = mission.copyWith(isCompleted: true);

    // Award bonus XP through the gamification system
    try {
      final database = _ref.read(databaseProvider);
      await database.addXP(mission.bonusXP, source: "rescue_mission");
    } catch (_) {
      // XP award failed silently — mission still marked complete
    }

    state = state.copyWith(activeMissions: missions);
  }

  // -----------------------------------------------------------------------
  // _calculateChurnScore — weighted scoring engine
  // -----------------------------------------------------------------------

  double _calculateChurnScore(
    User profile,
    List<Goal> goals,
    List<Deposit> deposits,
  ) {
    final depositFreqScore = _depositFrequencyDropScore(profile, deposits);
    final streakScore = _streakRiskScore(profile);
    final goalAbandonScore = _goalAbandonmentScore(goals);
    final amountScore = _amountDeclineScore(deposits);
    final pushScore = _pushIgnoreScore(profile);

    final appOpenScore = _appOpenDeclineScore(profile);

    final weightedScore =
        (depositFreqScore * _weightDepositFrequencyDrop) +
        (streakScore * _weightStreakRisk) +
        (goalAbandonScore * _weightGoalAbandonment) +
        (amountScore * _weightAmountDecline) +
        (pushScore * _weightPushIgnored) +
        (appOpenScore * _weightAppOpenDecline);

    return weightedScore.clamp(0.0, 1.0);
  }

  // -----------------------------------------------------------------------
  // Individual signal scoring helpers (each returns 0.0 – 1.0)
  // -----------------------------------------------------------------------

  /// Deposit frequency drop: compares recent 14-day deposit count vs prior 14-day.
  double _depositFrequencyDropScore(
    User profile,
    List<Deposit> deposits,
  ) {
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 14));
    final priorCutoff = now.subtract(const Duration(days: 28));

    final recentCount =
        deposits.where((d) => d.createdAt.isAfter(recentCutoff)).length;
    final priorCount = deposits
        .where((d) =>
            d.createdAt.isAfter(priorCutoff) &&
            d.createdAt.isBefore(recentCutoff))
        .length;

    if (priorCount == 0) return recentCount == 0 ? 0.8 : 0.0;

    final ratio = recentCount / priorCount;
    if (ratio >= 0.8) return 0.0;
    if (ratio >= 0.5) return 0.4;
    if (ratio >= 0.25) return 0.7;
    return 1.0;
  }

  /// Streak risk: how close is the user to losing their streak?
  double _streakRiskScore(User profile) {
    final streak = profile.currentStreak;
    final lastDepositDate = profile.lastDepositAt;

    if (streak == 0) return 0.9;
    if (lastDepositDate == null) return 0.8;

    final hoursSinceLastDeposit = DateTime.now()
        .difference(lastDepositDate)
        .inHours;

    // Assuming streak resets every 48 hours without a deposit
    if (hoursSinceLastDeposit > 36) return 0.9; // very close to losing streak
    if (hoursSinceLastDeposit > 24) return 0.7;
    if (hoursSinceLastDeposit > 12) return 0.4;
    return 0.0;
  }

  /// Goal abandonment: checks for stale or underfunded goals
  double _goalAbandonmentScore(List<Goal> goals) {
    if (goals.isEmpty) return 0.5; // no goals at all is a mild signal

    final now = DateTime.now();
    int abandonedSignals = 0;

    for (final goal in goals) {
      final progress = goal.savedAmount / goal.targetAmount;
      final ageDays = now.difference(goal.createdAt).inDays;

      // Goal older than 30 days with less than 10% progress
      if (ageDays > 30 && progress < 0.1) {
        abandonedSignals++;
      }
      // Goal older than 60 days with less than 25% progress
      else if (ageDays > 60 && progress < 0.25) {
        abandonedSignals++;
      }
      // No deposits to this goal in the last 21 days
      else if (goal.lastDepositAt != null &&
          now.difference(goal.lastDepositAt!).inDays > 21) {
        abandonedSignals++;
      }
    }

    final ratio = abandonedSignals / goals.length;
    return ratio.clamp(0.0, 1.0);
  }

  /// Amount decline: compares average deposit amounts (recent vs prior)
  double _amountDeclineScore(List<Deposit> deposits) {
    if (deposits.length < 4) return 0.0;

    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 14));
    final priorCutoff = now.subtract(const Duration(days: 28));

    final recentDeposits =
        deposits.where((d) => d.createdAt.isAfter(recentCutoff)).toList();
    final priorDeposits = deposits
        .where((d) =>
            d.createdAt.isAfter(priorCutoff) &&
            d.createdAt.isBefore(recentCutoff))
        .toList();

    if (recentDeposits.isEmpty) return 0.6;
    if (priorDeposits.isEmpty) return 0.0;

    final recentAvg = recentDeposits
            .map((d) => d.amount)
            .reduce((a, b) => a + b) /
        recentDeposits.length;
    final priorAvg = priorDeposits
            .map((d) => d.amount)
            .reduce((a, b) => a + b) /
        priorDeposits.length;

    if (priorAvg == 0) return 0.0;

    final ratio = recentAvg / priorAvg;
    if (ratio >= 0.8) return 0.0;
    if (ratio >= 0.5) return 0.4;
    if (ratio >= 0.25) return 0.7;
    return 1.0;
  }

  /// Push notification ignore rate (heuristic based on profile data)
  double _pushIgnoreScore(User profile) {
    // If the user has disabled notifications, that's a strong signal
    if (profile.notificationsEnabled == false) return 0.8;

    // If we have push interaction data, use it
    final lastPushInteraction = profile.lastPushInteractionAt;
    if (lastPushInteraction == null) return 0.5;

    final daysSincePushInteraction =
        DateTime.now().difference(lastPushInteraction).inDays;
    if (daysSincePushInteraction > 14) return 0.9;
    if (daysSincePushInteraction > 7) return 0.6;
    if (daysSincePushInteraction > 3) return 0.3;
    return 0.0;
  }

  /// App open decline (heuristic based on last session)
  double _appOpenDeclineScore(User profile) {
    final lastSession = profile.lastAppOpenAt;
    if (lastSession == null) return 0.7;

    final daysSinceOpen = DateTime.now().difference(lastSession).inDays;
    if (daysSinceOpen > 7) return 1.0;
    if (daysSinceOpen > 5) return 0.8;
    if (daysSinceOpen > 3) return 0.5;
    if (daysSinceOpen > 1) return 0.2;
    return 0.0;
  }

  // -----------------------------------------------------------------------
  // AI narrative generation via OpenRouter
  // -----------------------------------------------------------------------

  Future<Map<String, String>> _generateRescueNarratives(
    double churnScore,
    List<ChurnSignal> signals,
    User profile,
    List<Goal> goals,
    List<Deposit> deposits,
  ) async {
    try {
      final openRouter = _ref.read(openRouterServiceProvider);

      final signalNames = signals.map((s) {
        switch (s) {
          case ChurnSignal.depositFrequencyDrop:
            return "deposit_frequency_drop";
          case ChurnSignal.streakAtRisk:
            return "streak_at_risk";
          case ChurnSignal.appOpenDecline:
            return "app_open_decline";
          case ChurnSignal.amountDecline:
            return "amount_decline";
          case ChurnSignal.pushIgnored:
            return "push_ignored";
          case ChurnSignal.goalAbandonmentRisk:
            return "goal_abandonment_risk";
        }
      }).join(", ");

      final goalSummary = goals.isEmpty
          ? "No active goals"
          : goals
                .take(3)
                .map((g) =>
                    "${g.name}: ${g.currentAmount}/${g.targetAmount}")
                .join("; ");

      final streakInfo = "Current streak: ${profile.currentStreak} days";

      final narrativeData = await openRouter.chatJson(
        systemPrompt: 'You are VAULT-17, a dramatic AI oracle in a gamified savings app. '
            'You detect churn risk and create compelling rescue narratives. '
            'You always respond in valid JSON format only. No markdown. No code fences.',
        userPrompt: 'A user is at ${_formatPercent(churnScore)} risk of churning within the next 7-14 days.\n\n'
            'Signals detected: $signalNames\n$streakInfo\nGoals: $goalSummary\n\n'
            'Generate TWO rescue narratives that will be shown to the user:\n'
            '1. A Ukrainian (UA) version — dramatic, sci-fi themed, using the VAULT-17 persona\n'
            '2. An English (EN) version — same tone adapted for English speakers\n\n'
            'Also suggest 3 specific recommended actions to re-engage the user.\n\n'
            'Respond in EXACTLY this JSON format (no markdown, no code fences):\n'
            '{"narrative_ua": "Ukrainian narrative here — use sci-fi VAULT-17 tone. Be dramatic but encouraging. Reference specific threats detected.", '
            '"narrative_en": "English narrative here — same dramatic sci-fi tone as VAULT-17.", '
            '"actions": ["action 1", "action 2", "action 3"]}\n\n'
            'Important: For Ukrainian text, use double quotes for strings with apostrophes.\n'
            'Example UA tone: "VAULT-17 виявив аномалію в твоєму збереженні... Система стріку під загрозою колапсу. Термінова стабілізація необхідна!"',
        temperature: 0.9,
        maxTokens: 1024,
      );

      if (narrativeData != null) {
        return {
          "ua": narrativeData['narrative_ua'] as String? ?? "",
          "en": narrativeData['narrative_en'] as String? ?? "",
        };
      } else {
        return _fallbackNarratives(churnScore, signals);
      }
    } catch (e) {
      return _fallbackNarratives(churnScore, signals);
    }
  }

  // -----------------------------------------------------------------------
  // Fallback helpers (when AI is unavailable)
  // -----------------------------------------------------------------------

  Map<String, String> _fallbackNarratives(
    double churnScore,
    List<ChurnSignal> signals,
  ) {
    final severity = churnScore > 0.8 ? "КРИТИЧНИЙ" : "ПІДВИЩЕНИЙ";
    final severityEN = churnScore > 0.8 ? "CRITICAL" : "ELEVATED";

    return {
      "ua":
          "VAULT-17 виявив ${severity} рівень загрози твоєму збереженню. "
          "Система детектувала ${signals.length} аномалій. "
          "Твоя скринька потребує термінової стабілізації — здійсни депозит щоб відновити захист!",
      "en":
          "VAULT-17 has detected a ${severityEN} threat level to your savings. "
          "The system has identified ${signals.length} anomalies. "
          "Your vault requires urgent stabilization — make a deposit to restore protection!",
    };
  }

  RescueMission _createFallbackMission(
    ChurnAnalysis analysis,
    int targetDeposits,
    int daysToComplete,
  ) {
    final severity = analysis.churnProbability > 0.8 ? "КРИТИЧНУ" : "ПІДВИЩЕНУ";

    return RescueMission(
      id: "rescue_${DateTime.now().millisecondsSinceEpoch}",
      titleUA: "Рятівна місія VAULT-17",
      descriptionUA:
          "VAULT-17 виявив ${severity} аномалію в твоєму збереженні. "
          "Стабілізуй систему ${targetDeposits} депозитами за ${daysToComplete} днів!",
      targetDeposits: targetDeposits,
      daysToComplete: daysToComplete,
      bonusXP: analysis.rescueQuestXP,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
  }

  // -----------------------------------------------------------------------
  // Utility helpers
  // -----------------------------------------------------------------------

  List<String> _buildRecommendedActions(List<ChurnSignal> signals) {
    final actions = <String>[];

    for (final signal in signals) {
      switch (signal) {
        case ChurnSignal.depositFrequencyDrop:
          actions.add(
            "Schedule a micro-deposit reminder for every other day",
          );
        case ChurnSignal.streakAtRisk:
          actions.add(
            "Make a minimum deposit today to preserve your streak",
          );
        case ChurnSignal.appOpenDecline:
          actions.add(
            "Enable daily vault check-in notifications",
          );
        case ChurnSignal.amountDecline:
          actions.add(
            "Try the round-up deposit feature to boost amounts effortlessly",
          );
        case ChurnSignal.pushIgnored:
          actions.add(
            "Switch to in-app motivational alerts instead of push",
          );
        case ChurnSignal.goalAbandonmentRisk:
          actions.add(
            "Review and adjust your goal targets to be more achievable",
          );
      }
    }

    return actions;
  }

  int _calculateRescueXP(double churnScore) {
    // Map churn probability to XP: 0.6 → 200, 1.0 → 1000
    if (churnScore <= _churnThreshold) return 200;

    final normalizedScore = (churnScore - _churnThreshold) /
        (1.0 - _churnThreshold); // 0.0 – 1.0
    final xp = 200 + (normalizedScore * 800).round();
    return xp.clamp(200, 1000);
  }

  String _formatPercent(double value) {
    return "${(value * 100).round()}%";
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final antiChurnOracleProvider =
    StateNotifierProvider<AntiChurnOracleNotifier, AntiChurnState>(
  (ref) => AntiChurnOracleNotifier(ref),
);
