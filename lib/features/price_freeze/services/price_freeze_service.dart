import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Price Freeze Challenge -- freeze a price, deposit grows while price drops
// =============================================================================
//
// The user "freezes" the current market price of an item they want to buy.
// Each day they make a deposit towards that frozen price. If the market price
// drops below the frozen price, they gain a savings advantage. If the market
// price rises, they locked in a better deal by starting early.
//
// APIs:  SerpAPI Shopping (market price checks) + Twelve Data (inflation)
//        + OpenRouter (AI insights via VAULT-17 persona)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// A single daily snapshot of price and savings.
class DailySnapshot {
  final String date;
  final double price;
  final double savedAmount;
  final double cumulativeSaved;

  const DailySnapshot({
    required this.date,
    this.price = 0.0,
    this.savedAmount = 0.0,
    this.cumulativeSaved = 0.0,
  });

  DailySnapshot copyWith({
    String? date,
    double? price,
    double? savedAmount,
    double? cumulativeSaved,
  }) {
    return DailySnapshot(
      date: date ?? this.date,
      price: price ?? this.price,
      savedAmount: savedAmount ?? this.savedAmount,
      cumulativeSaved: cumulativeSaved ?? this.cumulativeSaved,
    );
  }
}

/// A freeze challenge tracking savings progress.
class FreezeChallenge {
  final String id;
  final String productName;
  final double frozenPrice;
  final double currentPrice;
  final double dailyDepositAmount;
  final double totalSaved;
  final int daysActive;
  final double savingsVsFrozen;
  final double inflationAdjustedTarget;
  final double progressPercent;
  final bool isActive;
  final String startedAt;
  final List<DailySnapshot> snapshots;

  const FreezeChallenge({
    required this.id,
    required this.productName,
    this.frozenPrice = 0.0,
    this.currentPrice = 0.0,
    this.dailyDepositAmount = 0.0,
    this.totalSaved = 0.0,
    this.daysActive = 0,
    this.savingsVsFrozen = 0.0,
    this.inflationAdjustedTarget = 0.0,
    this.progressPercent = 0.0,
    this.isActive = true,
    this.startedAt = '',
    this.snapshots = const [],
  });

  FreezeChallenge copyWith({
    String? id,
    String? productName,
    double? frozenPrice,
    double? currentPrice,
    double? dailyDepositAmount,
    double? totalSaved,
    int? daysActive,
    double? savingsVsFrozen,
    double? inflationAdjustedTarget,
    double? progressPercent,
    bool? isActive,
    String? startedAt,
    List<DailySnapshot>? snapshots,
  }) {
    return FreezeChallenge(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      frozenPrice: frozenPrice ?? this.frozenPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      dailyDepositAmount: dailyDepositAmount ?? this.dailyDepositAmount,
      totalSaved: totalSaved ?? this.totalSaved,
      daysActive: daysActive ?? this.daysActive,
      savingsVsFrozen: savingsVsFrozen ?? this.savingsVsFrozen,
      inflationAdjustedTarget:
          inflationAdjustedTarget ?? this.inflationAdjustedTarget,
      progressPercent: progressPercent ?? this.progressPercent,
      isActive: isActive ?? this.isActive,
      startedAt: startedAt ?? this.startedAt,
      snapshots: snapshots ?? this.snapshots,
    );
  }
}

/// State for the Price Freeze feature.
class PriceFreezeState {
  final List<FreezeChallenge> challenges;
  final bool isLoading;
  final String? error;
  final double totalEconomyGain;
  final double inflationRate;

  const PriceFreezeState({
    this.challenges = const [],
    this.isLoading = false,
    this.error,
    this.totalEconomyGain = 0.0,
    this.inflationRate = 7.5,
  });

  PriceFreezeState copyWith({
    List<FreezeChallenge>? challenges,
    bool? isLoading,
    String? error,
    double? totalEconomyGain,
    double? inflationRate,
  }) {
    return PriceFreezeState(
      challenges: challenges ?? this.challenges,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalEconomyGain: totalEconomyGain ?? this.totalEconomyGain,
      inflationRate: inflationRate ?? this.inflationRate,
    );
  }
}



// -----------------------------------------------------------------------------
// Twelve Data -- fetch inflation context
// -----------------------------------------------------------------------------

Future<double> _fetchInflationRate(String twelveDataKey) async {
  if (twelveDataKey.isEmpty) return 7.5;

  try {
    final uri = Uri.https('api.twelvedata.com', '/time_series', {
      'symbol': 'USD/UAH',
      'interval': '1day',
      'outputsize': '30',
      'apikey': twelveDataKey,
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) return 7.5;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final values = body['values'] as List? ?? [];
    if (values.length >= 2) {
      final latestRate = double.tryParse(
            (values[0]['close'] ?? '41.5').toString(),
          ) ??
          41.5;
      final monthAgoRate = double.tryParse(
            (values[values.length - 1]['close'] ?? '39.5').toString(),
          ) ??
          39.5;
      if (monthAgoRate > 0) {
        return ((latestRate - monthAgoRate) / monthAgoRate) * 100 * 12;
      }
    }

    return 7.5;
  } catch (_) {
    return 7.5;
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class PriceFreezeNotifier extends StateNotifier<PriceFreezeState> {
  final Ref _ref;
  final AppDatabase _db;

  PriceFreezeNotifier(this._ref, this._db)
      : super(const PriceFreezeState());

  // ---------------------------------------------------------------------------
  // Start a freeze challenge
  // ---------------------------------------------------------------------------

  Future<void> startChallenge(
    String productName,
    double frozenPrice,
    double dailyDeposit,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final id = 'freeze_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final startedAt = now.toIso8601String();

      // Calculate inflation adjusted target
      final inflationRate = state.inflationRate;
      final monthlyInflation = inflationRate / 12;
      final inflationAdjustedTarget =
          frozenPrice * (1 + monthlyInflation / 100 * 6);

      final challenge = FreezeChallenge(
        id: id,
        productName: productName,
        frozenPrice: frozenPrice,
        currentPrice: frozenPrice,
        dailyDepositAmount: dailyDeposit,
        totalSaved: 0.0,
        daysActive: 0,
        savingsVsFrozen: 0.0,
        inflationAdjustedTarget: inflationAdjustedTarget,
        progressPercent: 0.0,
        isActive: true,
        startedAt: startedAt,
        snapshots: [],
      );

      final updatedChallenges = [...state.challenges, challenge];

      // Award XP for starting a challenge
      await _db.addXP(20, source: 'price_freeze_start');

      state = state.copyWith(
        challenges: updatedChallenges,
        isLoading: false,
        totalEconomyGain: _computeTotalEconomyGain(updatedChallenges),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка запуску челенджу: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Add daily deposit to a challenge
  // ---------------------------------------------------------------------------

  Future<void> addDailyDeposit(String challengeId, double amount) async {
    try {
      final index =
          state.challenges.indexWhere((c) => c.id == challengeId);
      if (index == -1) {
        state = state.copyWith(error: 'Челендж не знайдено');
        return;
      }

      final challenge = state.challenges[index];
      final newTotalSaved = challenge.totalSaved + amount;
      final newDaysActive = challenge.daysActive + 1;
      final newProgress = challenge.frozenPrice > 0
          ? (newTotalSaved / challenge.frozenPrice * 100).clamp(0.0, 100.0)
          : 0.0;

      // Calculate savings vs frozen price
      final newSavingsVsFrozen =
          challenge.frozenPrice - challenge.currentPrice;

      // Create daily snapshot
      final snapshot = DailySnapshot(
        date: DateTime.now().toIso8601String().split('T').first,
        price: challenge.currentPrice,
        savedAmount: amount,
        cumulativeSaved: newTotalSaved,
      );

      final updatedSnapshots = [...challenge.snapshots, snapshot];

      final updatedChallenge = challenge.copyWith(
        totalSaved: newTotalSaved,
        daysActive: newDaysActive,
        progressPercent: newProgress,
        savingsVsFrozen: newSavingsVsFrozen > 0 ? newSavingsVsFrozen : 0.0,
        snapshots: updatedSnapshots,
      );

      final updatedChallenges = List<FreezeChallenge>.from(state.challenges);
      updatedChallenges[index] = updatedChallenge;

      // Award XP for daily deposit
      int xpAward = 5;
      // Streak bonus
      if (newDaysActive >= 30) {
        xpAward = 25;
      } else if (newDaysActive >= 7) {
        xpAward = 10;
      } else if (newDaysActive >= 3) {
        xpAward = 7;
      }
      await _db.addXP(xpAward, source: 'price_freeze_deposit');

      // Check if challenge is complete
      if (newTotalSaved >= challenge.frozenPrice && challenge.isActive) {
        await endChallenge(challengeId);
        return;
      }

      state = state.copyWith(
        challenges: updatedChallenges,
        totalEconomyGain: _computeTotalEconomyGain(updatedChallenges),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка депозиту: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh current price for a challenge
  // ---------------------------------------------------------------------------

  Future<void> refreshCurrentPrice(String challengeId) async {
    try {
      final index =
          state.challenges.indexWhere((c) => c.id == challengeId);
      if (index == -1) return;

      final challenge = state.challenges[index];

      final marketPrice =
          await _ref.read(serpApiServiceProvider).findLowestPrice(challenge.productName);

      double newCurrentPrice = challenge.currentPrice;
      if (marketPrice > 0) {
        newCurrentPrice = marketPrice;
      }

      final newSavingsVsFrozen =
          challenge.frozenPrice - newCurrentPrice;

      final updatedChallenge = challenge.copyWith(
        currentPrice: newCurrentPrice,
        savingsVsFrozen: newSavingsVsFrozen > 0 ? newSavingsVsFrozen : 0.0,
      );

      final updatedChallenges = List<FreezeChallenge>.from(state.challenges);
      updatedChallenges[index] = updatedChallenge;

      state = state.copyWith(
        challenges: updatedChallenges,
        totalEconomyGain: _computeTotalEconomyGain(updatedChallenges),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка оновлення цiни: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh inflation rate from Twelve Data
  // ---------------------------------------------------------------------------

  Future<void> refreshInflationRate() async {
    try {
      final twelveKey = _ref.read(twelveDataApiKeyProvider);
      final rate = await _fetchInflationRate(twelveKey);

      state = state.copyWith(inflationRate: rate);
    } catch (e) {
      // Keep the default inflation rate
    }
  }

  // ---------------------------------------------------------------------------
  // Generate AI progress insight for a challenge
  // ---------------------------------------------------------------------------

  Future<String> generateProgressInsight(FreezeChallenge challenge) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      return 'AI недоступний -- API ключ не налаштований. '
          'Продовжуй щоденнi депозити!';
    }

    final prompt =
        'Analyze this savings challenge: User is saving for ${challenge.productName} '
        'which was ${challenge.frozenPrice.toStringAsFixed(0)} UAH when they started '
        '${challenge.daysActive} days ago. Current price is ${challenge.currentPrice.toStringAsFixed(0)}. '
        'They saved ${challenge.totalSaved.toStringAsFixed(0)} UAH so far '
        '(${challenge.progressPercent.toStringAsFixed(1)}%). Current inflation rate is '
        '${state.inflationRate.toStringAsFixed(1)}%. Give a motivational cyberpunk-themed '
        'insight in Ukrainian about their progress.';

    try {
      final result = await openRouter.chat(
        systemPrompt: 'Ти VAULT-17 -- кiберпанк AI-асистент NEONCRED. '
            'Говори українською з техно-метафорами про крiо-замороження цiн, '
            'матрицi економiї, замерзлi данi. Мотивуй продовжувати.',
        userPrompt: prompt,
        temperature: 0.9,
        maxTokens: 400,
      );
      return result ?? 'Продовжуй заморожувати цiни! Крiо-матриця працює.';
    } catch (e) {
      return 'Не вдалося згенерувати iнсайт: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // End a challenge
  // ---------------------------------------------------------------------------

  Future<void> endChallenge(String challengeId) async {
    try {
      final index =
          state.challenges.indexWhere((c) => c.id == challengeId);
      if (index == -1) return;

      final challenge = state.challenges[index];

      final updatedChallenge = challenge.copyWith(
        isActive: false,
      );

      final updatedChallenges = List<FreezeChallenge>.from(state.challenges);
      updatedChallenges[index] = updatedChallenge;

      // Award completion XP
      await _db.addXP(100, source: 'price_freeze_complete');

      // Bonus for savings
      if (challenge.savingsVsFrozen > 0) {
        final bonusXp =
            (challenge.savingsVsFrozen / 100).floor() * 10;
        if (bonusXp > 0) {
          await _db.addXP(bonusXp, source: 'price_freeze_savings_bonus');
        }
      }

      state = state.copyWith(
        challenges: updatedChallenges,
        totalEconomyGain: _computeTotalEconomyGain(updatedChallenges),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка завершення челенджу: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _computeTotalEconomyGain(List<FreezeChallenge> challenges) {
    double total = 0.0;
    for (final c in challenges) {
      if (c.isActive && c.savingsVsFrozen > 0) {
        total += c.savingsVsFrozen;
      }
    }
    return total;
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final priceFreezeProvider =
    StateNotifierProvider<PriceFreezeNotifier, PriceFreezeState>((ref) {
  final db = ref.watch(databaseProvider);
  return PriceFreezeNotifier(ref, db);
});
