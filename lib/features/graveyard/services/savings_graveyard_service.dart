import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// GraveyardStatus — lifecycle status of a dead goal
// ---------------------------------------------------------------------------

enum GraveyardStatus { dead, resurrected, expired }

extension GraveyardStatusX on GraveyardStatus {
  String get labelUA => switch (this) {
        GraveyardStatus.dead => 'Мертвий',
        GraveyardStatus.resurrected => 'Воскреслий',
        GraveyardStatus.expired => 'Цифровий пил',
      };

  String get iconEmoji => switch (this) {
        GraveyardStatus.dead => '\u{1FAA6}',
        GraveyardStatus.resurrected => '\u{26A1}',
        GraveyardStatus.expired => '\u{1F300}',
      };
}

// ---------------------------------------------------------------------------
// GraveyardStats — aggregated stats for the graveyard
// ---------------------------------------------------------------------------

class GraveyardStats {
  final int totalDeaths;
  final int totalResurrections;
  final int necromancerCount;
  final double totalLostValue;
  final double totalResurrectedValue;

  const GraveyardStats({
    this.totalDeaths = 0,
    this.totalResurrections = 0,
    this.necromancerCount = 0,
    this.totalLostValue = 0.0,
    this.totalResurrectedValue = 0.0,
  });

  GraveyardStats copyWith({
    int? totalDeaths,
    int? totalResurrections,
    int? necromancerCount,
    double? totalLostValue,
    double? totalResurrectedValue,
  }) {
    return GraveyardStats(
      totalDeaths: totalDeaths ?? this.totalDeaths,
      totalResurrections: totalResurrections ?? this.totalResurrections,
      necromancerCount: necromancerCount ?? this.necromancerCount,
      totalLostValue: totalLostValue ?? this.totalLostValue,
      totalResurrectedValue: totalResurrectedValue ?? this.totalResurrectedValue,
    );
  }
}

// ---------------------------------------------------------------------------
// SavingsGraveyardState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class SavingsGraveyardState {
  final List<GraveyardEntry> entries;
  final GraveyardStats stats;
  final bool isLoading;
  final String? error;

  const SavingsGraveyardState({
    this.entries = const [],
    this.stats = const GraveyardStats(),
    this.isLoading = false,
    this.error,
  });

  SavingsGraveyardState copyWith({
    List<GraveyardEntry>? entries,
    GraveyardStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return SavingsGraveyardState(
      entries: entries ?? this.entries,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// SavingsGraveyardNotifier — core logic & AI integration
// ---------------------------------------------------------------------------

class SavingsGraveyardNotifier extends StateNotifier<SavingsGraveyardState> {
  final Ref _ref;

  /// The resurrection window — 7 days after death to revive a goal.
  static const Duration resurrectionWindow = Duration(days: 7);

  /// Resurrections needed to earn the "Necromancer" achievement.
  static const int necromancerThreshold = 3;

  SavingsGraveyardNotifier(this._ref)
      : super(const SavingsGraveyardState());

  // =========================================================================
  // Public API
  // =========================================================================

  /// Load all graveyard entries from the database.
  Future<void> loadGraveyard() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final database = _ref.read(databaseProvider);
      final entries = await database.getAllGraveyardEntries();
      final stats = _computeStats(entries);

      state = state.copyWith(
        entries: entries,
        stats: stats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Bury a goal — move it from active to the graveyard.
  ///
  /// Generates an AI epitaph via OpenRouter and creates a GraveyardEntry.
  Future<void> buryGoal(Goal goal, String deathReason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Generate AI epitaph
      String epitaph;
      try {
        epitaph = await _generateEpitaph(
          goal.name,
          goal.savedAmount,
          goal.targetAmount,
          deathReason,
        );
      } catch (_) {
        epitaph = _fallbackEpitaph(goal.name, goal.savedAmount, goal.targetAmount);
      }

      final database = _ref.read(databaseProvider);

      await database.insertGraveyardEntry(
        GraveyardEntriesCompanion.insert(
          goalId: goal.id,
          goalName: goal.name,
          targetAmount: goal.targetAmount,
          savedAmount: Value(goal.savedAmount),
          epitaph: Value(epitaph),
          deathDate: DateTime.now(),
          deathReason: Value(deathReason),
        ),
      );

      // Reload graveyard
      await loadGraveyard();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Attempt to resurrect a dead goal within the 7-day window.
  ///
  /// Returns `true` if resurrection succeeded, `false` if the window expired.
  Future<bool> resurrectGoal(int graveyardEntryId) async {
    try {
      final database = _ref.read(databaseProvider);
      final entries = await database.getAllGraveyardEntries();
      final entry = entries.where((e) => e.id == graveyardEntryId).firstOrNull;

      if (entry == null) return false;

      if (!canResurrect(entry)) return false;

      // Mark as resurrected
      final updated = entry.copyWith(
        isResurrected: true,
        resurrectionDate: Value(DateTime.now()),
        necromancerUsed: true,
      );

      await database.updateGraveyardEntry(updated);

      // Award XP for resurrection
      await database.addXP(150, source: 'graveyard_resurrection');

      // Reload
      await loadGraveyard();

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Check if a graveyard entry is still within the 7-day resurrection window.
  bool canResurrect(GraveyardEntry entry) {
    if (entry.isResurrected) return false;

    final now = DateTime.now();
    final deadline = entry.deathDate.add(resurrectionWindow);
    return now.isBefore(deadline);
  }

  /// Returns the remaining time before the resurrection window closes.
  Duration resurrectionTimeRemaining(GraveyardEntry entry) {
    if (entry.isResurrected) return Duration.zero;
    final deadline = entry.deathDate.add(resurrectionWindow);
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if the user has earned the "Necromancer" achievement
  /// (3+ resurrections).
  bool checkNecromancerAchievement() {
    return state.stats.necromancerCount >= necromancerThreshold;
  }

  // =========================================================================
  // AI Epitaph Generation via OpenRouter
  // =========================================================================

  Future<String> _generateEpitaph(
    String goalName,
    double savedAmount,
    double targetAmount,
    String deathReason,
  ) async {
    final openRouter = _ref.read(openRouterServiceProvider);

    final progress = targetAmount > 0
        ? ((savedAmount / targetAmount) * 100).toStringAsFixed(0)
        : '0';

    final prompt = '''
You are VAULT-17, the AI oracle of NEONCRED — a gamified savings app.
A savings goal has been abandoned and "died". Generate a dramatic CYBERPUNK EPITAPH in Ukrainian.

Goal: $goalName
Progress: $progress% (saved $savedAmount of $targetAmount)
Death reason: $deathReason

The epitaph should:
- Be 1-2 sentences long
- Use cyberpunk / neon / dystopian imagery
- Reference the goal name and progress
- Be dramatic and slightly dark humor
- Use the VAULT-17 persona

Example tone: "Тут спочиває PS5 Cyber-Demon, зраджений на 47-й день стріку. Неоновий вічний пілот охороняє його спомин."

Respond with ONLY the epitaph text, no JSON, no quotes, no markdown.
''';

    final result = await openRouter.chat(
      systemPrompt:
          'You are VAULT-17, a dramatic AI oracle. You write cyberpunk epitaphs in Ukrainian. '
              'Respond with plain text only — no JSON, no code fences, no quotes.',
      userPrompt: prompt,
      temperature: 0.9,
      maxTokens: 150,
    );

    if (result != null && result.trim().isNotEmpty) return result;

    return _fallbackEpitaph(goalName, savedAmount, targetAmount);
  }

  // =========================================================================
  // Fallback epitaphs (when AI is unavailable)
  // =========================================================================

  String _fallbackEpitaph(String goalName, double saved, double target) {
    final progress = target > 0 ? saved / target : 0.0;

    if (progress >= 0.75) {
      return 'Тут спочиває "$goalName" — майже досягнувши мети, але зламаний на '
          'останньому рубежі. Неоновий пілот схиляє голову.';
    } else if (progress >= 0.50) {
      return '"$goalName" згас на півдорозі. Половина шляху пройдена, але '
          'неонове мерехтіння згасло назавжди.';
    } else if (progress >= 0.25) {
      return '"$goalName" лишився лише спогадом у димі кіберпанк-міста. '
          'Кілька депозитів не врятували його від цифрового пилу.';
    } else {
      return '"$goalName" навіть не розпочав свій шлях. Тінь у темряві '
          'неонового міста, що так і не стала світлом.';
    }
  }

  // =========================================================================
  // Stats computation
  // =========================================================================

  GraveyardStats _computeStats(List<GraveyardEntry> entries) {
    int deaths = 0;
    int resurrections = 0;
    int necromancer = 0;
    double lostValue = 0.0;
    double resurrectedValue = 0.0;

    for (final entry in entries) {
      deaths++;
      if (entry.isResurrected) {
        resurrections++;
        resurrectedValue += entry.savedAmount;
      } else {
        lostValue += entry.targetAmount - entry.savedAmount;
      }
      if (entry.necromancerUsed) {
        necromancer++;
      }
    }

    return GraveyardStats(
      totalDeaths: deaths,
      totalResurrections: resurrections,
      necromancerCount: necromancer,
      totalLostValue: lostValue,
      totalResurrectedValue: resurrectedValue,
    );
  }

  // =========================================================================
  // Utility
  // =========================================================================

}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final savingsGraveyardProvider =
    StateNotifierProvider<SavingsGraveyardNotifier, SavingsGraveyardState>(
  (ref) => SavingsGraveyardNotifier(ref),
);
