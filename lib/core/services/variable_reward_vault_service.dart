import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../../data/database.dart';

// ---------------------------------------------------------------------------
// JackpotTier — tier of the neon jackpot
// ---------------------------------------------------------------------------

enum JackpotTier {
  none,
  mini,
  rare,
  epic,
  legendary,
}

extension JackpotTierX on JackpotTier {
  String get emoji => switch (this) {
        JackpotTier.none      => '',
        JackpotTier.mini      => '✨',
        JackpotTier.rare      => '💫',
        JackpotTier.epic      => '💎',
        JackpotTier.legendary => '👑',
      };

  String get labelUA => switch (this) {
        JackpotTier.none      => 'Без джекпоту',
        JackpotTier.mini      => 'Міні Джекпот',
        JackpotTier.rare      => 'Рідкісний Джекпот',
        JackpotTier.epic      => 'Епічний Джекпот',
        JackpotTier.legendary => 'Легендарний Джекпот',
      };

  double get xpMultiplier => switch (this) {
        JackpotTier.none      => 1.0,
        JackpotTier.mini      => 2.0,
        JackpotTier.rare      => 3.0,
        JackpotTier.epic      => 5.0,
        JackpotTier.legendary => 10.0,
      };

  String get descriptionUA => switch (this) {
        JackpotTier.none      => 'Без джекпоту — наступного разу пощастить!',
        JackpotTier.mini      => '✨ МІНІ ДЖЕКПОТ! x2 XP!',
        JackpotTier.rare      => '💫 РІДКІСНИЙ ДЖЕКПОТ! x3 XP + косметика!',
        JackpotTier.epic      => '💎 ЕПІЧНИЙ ДЖЕКПОТ! x5 XP + мутація пета!',
        JackpotTier.legendary =>
          '👑 ЛЕГЕНДАРНИЙ ДЖЕКПОТ! x10 XP + ексклюзивний бейдж + еволюція пета!',
      };
}

// ---------------------------------------------------------------------------
// JackpotResult — outcome of a single roll
// ---------------------------------------------------------------------------

class JackpotResult {
  final JackpotTier tier;
  final int baseXP;
  final int enhancedXP;
  final double multiplier;
  final String descriptionUA;
  final bool isNearMiss;
  final String nearMissMessage;

  const JackpotResult({
    required this.tier,
    required this.baseXP,
    required this.enhancedXP,
    required this.multiplier,
    required this.descriptionUA,
    required this.isNearMiss,
    required this.nearMissMessage,
  });
}

// ---------------------------------------------------------------------------
// JackpotStats — running statistics across sessions
// ---------------------------------------------------------------------------

class JackpotStats {
  final int totalDepositsSinceLastJackpot;
  final int totalJackpotsWon;
  final JackpotTier lastJackpotTier;
  final double currentProbability;
  final Map<JackpotTier, int> jackpotsByTier;
  final int currentStreakWithoutJackpot;

  const JackpotStats({
    this.totalDepositsSinceLastJackpot = 0,
    this.totalJackpotsWon = 0,
    this.lastJackpotTier = JackpotTier.none,
    this.currentProbability = 0.05,
    this.jackpotsByTier = const {
      JackpotTier.mini: 0,
      JackpotTier.rare: 0,
      JackpotTier.epic: 0,
      JackpotTier.legendary: 0,
    },
    this.currentStreakWithoutJackpot = 0,
  });

  JackpotStats copyWith({
    int? totalDepositsSinceLastJackpot,
    int? totalJackpotsWon,
    JackpotTier? lastJackpotTier,
    double? currentProbability,
    Map<JackpotTier, int>? jackpotsByTier,
    int? currentStreakWithoutJackpot,
  }) {
    return JackpotStats(
      totalDepositsSinceLastJackpot:
          totalDepositsSinceLastJackpot ?? this.totalDepositsSinceLastJackpot,
      totalJackpotsWon: totalJackpotsWon ?? this.totalJackpotsWon,
      lastJackpotTier: lastJackpotTier ?? this.lastJackpotTier,
      currentProbability: currentProbability ?? this.currentProbability,
      jackpotsByTier: jackpotsByTier ?? this.jackpotsByTier,
      currentStreakWithoutJackpot:
          currentStreakWithoutJackpot ?? this.currentStreakWithoutJackpot,
    );
  }
}

// ---------------------------------------------------------------------------
// VariableRewardState — state exposed to the UI
// ---------------------------------------------------------------------------

class VariableRewardState {
  final JackpotStats stats;
  final JackpotResult? lastResult;
  final bool isAnimating;

  const VariableRewardState({
    required this.stats,
    this.lastResult,
    this.isAnimating = false,
  });

  VariableRewardState copyWith({
    JackpotStats? stats,
    JackpotResult? lastResult,
    bool? isAnimating,
  }) {
    return VariableRewardState(
      stats: stats ?? this.stats,
      lastResult: lastResult ?? this.lastResult,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

// ---------------------------------------------------------------------------
// VariableRewardNotifier — core logic / state management
// ---------------------------------------------------------------------------

class VariableRewardNotifier extends StateNotifier<VariableRewardState> {
  final Ref _ref;
  final Random _rng = Random();

  // Probability constants
  static const double _baseProbability = 0.05; // 5 %
  static const double _accumulationBonus = 0.01; // +1 % per deposit since last jackpot
  static const double _maxProbability = 0.15; // 15 % cap

  // Tier weight thresholds (cumulative within a hit)
  static const double _miniThreshold = 0.70; // 70 %
  static const double _rareThreshold = 0.90; // 20 % (cumulative)
  static const double _epicThreshold = 0.98; // 8 %  (cumulative)
  // legendary covers the remaining 2 % (0.98 – 1.0)

  VariableRewardNotifier(this._ref)
      : super(const VariableRewardState(
          stats: JackpotStats(),
        ));

  // ----- Public API -------------------------------------------------------

  /// The core method — call on every deposit.
  ///
  /// Probability formula:
  ///   base 5 % + 1 % × deposits since last jackpot (capped at 15 %).
  ///
  /// If the roll hits, a second roll determines the tier:
  ///   mini 70 %, rare 20 %, epic 8 %, legendary 2 %.
  JackpotResult rollJackpot(int baseXP) {
    final int deposits = state.stats.totalDepositsSinceLastJackpot + 1;

    // --- Calculate probability with accumulation bonus ---
    final double probability =
        (_baseProbability + _accumulationBonus * deposits).clamp(0.0, _maxProbability);

    // --- Roll the main jackpot check ---
    final double mainRoll = _rng.nextDouble();
    final bool isHit = mainRoll < probability;

    // --- Near-miss detection (within 2 % of next threshold) ---
    bool isNearMiss = false;
    String nearMissMessage = '';

    if (!isHit) {
      final double deficit = mainRoll - probability; // how far past the threshold
      if (deficit <= 0.02 && deficit >= 0) {
        isNearMiss = true;
        final double percentShort = (deficit * 100);
        nearMissMessage =
            'Майже ДЖЕКПОТ! Не вистачило всього ${percentShort.toStringAsFixed(1)}%!';
      }
    }

    JackpotTier tier = JackpotTier.none;

    if (isHit) {
      // --- Determine tier ---
      final double tierRoll = _rng.nextDouble();

      if (tierRoll < _miniThreshold) {
        tier = JackpotTier.mini;
      } else if (tierRoll < _rareThreshold) {
        tier = JackpotTier.rare;
      } else if (tierRoll < _epicThreshold) {
        tier = JackpotTier.epic;
      } else {
        tier = JackpotTier.legendary;
      }

      // Near-miss for next tier (within 2 % of the upper threshold boundary)
      if (tier != JackpotTier.legendary) {
        final double distanceToNext = _distanceToNextTier(tierRoll, tier);
        if (distanceToNext <= 0.02 && distanceToNext >= 0) {
          isNearMiss = true;
          final JackpotTier nextTier = _nextTier(tier);
          final double percentShort = (distanceToNext * 100);
          nearMissMessage =
              'Майже ${nextTier.labelUA}! На ${percentShort.toStringAsFixed(1)}% менше!';
        }
      }
    }

    // --- Build result ---
    final double multiplier = tier.xpMultiplier;
    final int enhancedXP = (baseXP * multiplier).round();

    final String description;
    if (tier == JackpotTier.none) {
      description = isNearMiss ? nearMissMessage : tier.descriptionUA;
    } else {
      description = tier.descriptionUA;
    }

    final result = JackpotResult(
      tier: tier,
      baseXP: baseXP,
      enhancedXP: enhancedXP,
      multiplier: multiplier,
      descriptionUA: description,
      isNearMiss: isNearMiss,
      nearMissMessage: nearMissMessage,
    );

    // --- Update stats ---
    final bool wonJackpot = tier != JackpotTier.none;

    final Map<JackpotTier, int> updatedTiers =
        Map<JackpotTier, int>.from(state.stats.jackpotsByTier);
    if (wonJackpot) {
      updatedTiers[tier] = (updatedTiers[tier] ?? 0) + 1;
    }

    final int newStreak = wonJackpot ? 0 : state.stats.currentStreakWithoutJackpot + 1;
    final int newDepositsSinceLast = wonJackpot ? 0 : deposits;

    final double newProbability =
        (_baseProbability + _accumulationBonus * (newDepositsSinceLast + 1))
            .clamp(0.0, _maxProbability);

    final newStats = state.stats.copyWith(
      totalDepositsSinceLastJackpot: newDepositsSinceLast,
      totalJackpotsWon:
          wonJackpot ? state.stats.totalJackpotsWon + 1 : state.stats.totalJackpotsWon,
      lastJackpotTier: wonJackpot ? tier : state.stats.lastJackpotTier,
      currentProbability: newProbability,
      jackpotsByTier: updatedTiers,
      currentStreakWithoutJackpot: newStreak,
    );

    state = state.copyWith(
      stats: newStats,
      lastResult: result,
    );

    return result;
  }

  /// Begin the slot-machine animation in the UI.
  void startAnimation() {
    state = state.copyWith(isAnimating: true);
  }

  /// End the slot-machine animation.
  void stopAnimation() {
    state = state.copyWith(isAnimating: false);
  }

  /// Current jackpot probability formatted as a percentage string.
  double get currentChance =>
      state.stats.currentProbability * 100;

  /// Ukrainian encouragement message based on current accumulation streak.
  String get encouragementMessage {
    final int streak = state.stats.currentStreakWithoutJackpot;
    final double nextProb =
        (_baseProbability + _accumulationBonus * (streak + 1)).clamp(0.0, _maxProbability);
    final double nextPct = nextProb * 100;

    if (streak == 0) {
      return 'Перший депозит — шанс джекпоту ${nextPct.toStringAsFixed(0)}%!';
    }

    if (nextProb >= _maxProbability) {
      return '🔥 Максимальний шанс джекпоту ${nextPct.toStringAsFixed(0)}%! Тижуу!';
    }

    final int depositsToMax =
        ((_maxProbability - _baseProbability) / _accumulationBonus - streak).ceil();

    return 'Ще $depositsToMax депозити і шанс джекпоту ${nextPct.toStringAsFixed(0)}%!';
  }

  // ----- Private helpers ---------------------------------------------------

  /// How far [tierRoll] was from crossing into the next tier.
  double _distanceToNextTier(double tierRoll, JackpotTier currentTier) {
    switch (currentTier) {
      case JackpotTier.none:
      case JackpotTier.mini:
        return _miniThreshold - tierRoll;
      case JackpotTier.rare:
        return _rareThreshold - tierRoll;
      case JackpotTier.epic:
        return _epicThreshold - tierRoll;
      case JackpotTier.legendary:
        return double.infinity; // already at the top
    }
  }

  /// Returns the tier immediately above [current].
  JackpotTier _nextTier(JackpotTier current) => switch (current) {
        JackpotTier.none      => JackpotTier.mini,
        JackpotTier.mini      => JackpotTier.rare,
        JackpotTier.rare      => JackpotTier.epic,
        JackpotTier.epic      => JackpotTier.legendary,
        JackpotTier.legendary => JackpotTier.legendary,
      };
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final variableRewardProvider =
    StateNotifierProvider<VariableRewardNotifier, VariableRewardState>(
  (ref) => VariableRewardNotifier(ref),
);
