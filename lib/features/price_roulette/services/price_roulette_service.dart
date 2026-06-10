import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Price Drop Roulette — Gamified waiting for price drops with daily spins
// =============================================================================
//
// Each tracked item gets a daily spin on the Price Drop Roulette. The longer
// you wait and the more you deposit, the higher your chances of landing a
// price drop. Real price data from SerpAPI validates actual drops.
// AI generates cyberpunk narratives for each spin.
//
// API:  SerpAPI Shopping (real price checks during spin)
//       + OpenRouter (AI spin narrative generation)
// =============================================================================

// -----------------------------------------------------------------------------
// Random singleton
// -----------------------------------------------------------------------------

final _rng = Random();

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// A single spin result.
class SpinResult {
  final String id;
  final String timestamp;
  final double priceBefore;
  final double priceAfter;
  final bool isDrop;
  final double xpBonus;
  final String narrative;

  const SpinResult({
    required this.id,
    required this.timestamp,
    required this.priceBefore,
    required this.priceAfter,
    required this.isDrop,
    required this.xpBonus,
    required this.narrative,
  });

  double get dropPercent =>
      priceBefore > 0 ? ((priceBefore - priceAfter) / priceBefore) * 100 : 0.0;

  double get dropAmount => priceBefore - priceAfter;
}

/// An item enrolled in the Price Drop Roulette.
class RouletteItem {
  final String id;
  final String productName;
  final double currentPrice;
  final double initialPrice;
  final double targetPrice;
  final double depositAmount;
  final int totalDeposits;
  final int dailySpins;
  final int maxDailySpins;
  final double dropChance;
  final List<SpinResult> spinHistory;
  final bool jackpotWon;
  final String lastSpunAt;

  const RouletteItem({
    required this.id,
    required this.productName,
    this.currentPrice = 0.0,
    this.initialPrice = 0.0,
    this.targetPrice = 0.0,
    this.depositAmount = 0.0,
    this.totalDeposits = 0,
    this.dailySpins = 0,
    this.maxDailySpins = 3,
    this.dropChance = 5.0,
    this.spinHistory = const [],
    this.jackpotWon = false,
    this.lastSpunAt = '',
  });

  bool get canSpin => dailySpins < maxDailySpins;

  double get depositProgress =>
      targetPrice > 0 ? (depositAmount / targetPrice).clamp(0.0, 1.0) : 0.0;

  RouletteItem copyWith({
    String? id,
    String? productName,
    double? currentPrice,
    double? initialPrice,
    double? targetPrice,
    double? depositAmount,
    int? totalDeposits,
    int? dailySpins,
    int? maxDailySpins,
    double? dropChance,
    List<SpinResult>? spinHistory,
    bool? jackpotWon,
    String? lastSpunAt,
  }) {
    return RouletteItem(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      currentPrice: currentPrice ?? this.currentPrice,
      initialPrice: initialPrice ?? this.initialPrice,
      targetPrice: targetPrice ?? this.targetPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      totalDeposits: totalDeposits ?? this.totalDeposits,
      dailySpins: dailySpins ?? this.dailySpins,
      maxDailySpins: maxDailySpins ?? this.maxDailySpins,
      dropChance: dropChance ?? this.dropChance,
      spinHistory: spinHistory ?? this.spinHistory,
      jackpotWon: jackpotWon ?? this.jackpotWon,
      lastSpunAt: lastSpunAt ?? this.lastSpunAt,
    );
  }
}

/// State for the Price Drop Roulette feature.
class PriceRouletteState {
  final List<RouletteItem> items;
  final bool isSpinning;
  final String? error;
  final SpinResult? lastResult;
  final int totalXpWon;

  const PriceRouletteState({
    this.items = const [],
    this.isSpinning = false,
    this.error,
    this.lastResult,
    this.totalXpWon = 0,
  });

  PriceRouletteState copyWith({
    List<RouletteItem>? items,
    bool? isSpinning,
    String? error,
    SpinResult? lastResult,
    int? totalXpWon,
  }) {
    return PriceRouletteState(
      items: items ?? this.items,
      isSpinning: isSpinning ?? this.isSpinning,
      error: error,
      lastResult: lastResult ?? this.lastResult,
      totalXpWon: totalXpWon ?? this.totalXpWon,
    );
  }
}



// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class PriceRouletteNotifier extends StateNotifier<PriceRouletteState> {
  final Ref _ref;

  PriceRouletteNotifier(this._ref) : super(const PriceRouletteState());

  // ---------------------------------------------------------------------------
  // Add a new item to the roulette
  // ---------------------------------------------------------------------------

  void addItem(String name, double targetPrice) {
    final item = RouletteItem(
      id: 'roulette_${DateTime.now().millisecondsSinceEpoch}',
      productName: name,
      targetPrice: targetPrice,
      initialPrice: targetPrice * 1.3,
      currentPrice: targetPrice * 1.3,
      dropChance: 5.0,
    );
    final updated = [...state.items, item];
    state = state.copyWith(items: updated);
  }

  // ---------------------------------------------------------------------------
  // Make a deposit — increases drop chance
  // ---------------------------------------------------------------------------

  void makeDeposit(String itemId, double amount) {
    final updated = state.items.map((item) {
      if (item.id == itemId) {
        final newDeposits = item.totalDeposits + 1;
        final newAmount = item.depositAmount + amount;
        // Drop chance: base 5% + (totalDeposits * 2%) capped at 85%
        final daysWaiting = DateTime.now()
            .difference(DateTime.parse(
              item.lastSpunAt.isNotEmpty
                  ? item.lastSpunAt
                  : DateTime.now().toIso8601String(),
            ))
            .inDays;
        final newChance = (5.0 + (newDeposits * 2.0) + (daysWaiting * 0.5))
            .clamp(5.0, 85.0);
        return item.copyWith(
          depositAmount: newAmount,
          totalDeposits: newDeposits,
          dropChance: newChance,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  // ---------------------------------------------------------------------------
  // Spin the roulette for a specific item
  // ---------------------------------------------------------------------------

  Future<SpinResult> spinRoulette(String itemId) async {
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) {
      return const SpinResult(
        id: 'error',
        timestamp: '',
        priceBefore: 0,
        priceAfter: 0,
        isDrop: false,
        xpBonus: 0,
        narrative: 'Pomylka: tovar ne znaideno',
      );
    }

    final item = state.items[itemIndex];

    if (!item.canSpin) {
      return SpinResult(
        id: 'cooldown_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now().toIso8601String(),
        priceBefore: item.currentPrice,
        priceAfter: item.currentPrice,
        isDrop: false,
        xpBonus: 10,
        narrative:
            'Koleso vzhe obertilosia siohodni! Povernys zavtra, viine.',
      );
    }

    state = state.copyWith(isSpinning: true, error: null);

    try {
      // Fetch real price from SerpAPI
      final realPrice =
          await _ref.read(serpApiServiceProvider).findLowestPrice('${item.productName} ціна');
      final priceBefore = item.currentPrice;
      final priceNow = realPrice > 0 ? realPrice : priceBefore;

      // Determine if this is a real price drop
      final realPriceDrop = realPrice > 0 && realPrice < priceBefore;

      // Calculate random outcome
      final roll = _rng.nextDouble() * 100.0;
      final hitDrop = roll < item.dropChance;

      double priceAfter = priceNow;
      bool isDrop = false;
      double xpBonus = 10; // Base XP for spinning

      if (realPriceDrop) {
        // Guaranteed jackpot — real price actually dropped!
        isDrop = true;
        priceAfter = priceNow;
        xpBonus = 500; // Jackpot XP
      } else if (hitDrop) {
        // Minor drop — random chance hit
        isDrop = true;
        final dropPercent = 1.0 + _rng.nextDouble() * 4.0; // 1-5%
        priceAfter = priceNow * (1.0 - dropPercent / 100.0);
        xpBonus = 50; // Minor drop XP
      } else {
        // No drop
        xpBonus = 10; // Consolation XP
      }

      // Create the spin result
      final spinResult = SpinResult(
        id: 'spin_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now().toIso8601String(),
        priceBefore: priceBefore,
        priceAfter: priceAfter,
        isDrop: isDrop,
        xpBonus: xpBonus,
        narrative: '', // Will be filled by AI
      );

      // Generate AI narrative
      final narrative = await generateSpinNarrative(spinResult, item);

      final finalResult = SpinResult(
        id: spinResult.id,
        timestamp: spinResult.timestamp,
        priceBefore: spinResult.priceBefore,
        priceAfter: spinResult.priceAfter,
        isDrop: spinResult.isDrop,
        xpBonus: spinResult.xpBonus,
        narrative: narrative,
      );

      // Update the item
      final updatedItem = item.copyWith(
        currentPrice: priceAfter,
        dailySpins: item.dailySpins + 1,
        jackpotWon: realPriceDrop || item.jackpotWon,
        lastSpunAt: DateTime.now().toIso8601String(),
        spinHistory: [finalResult, ...item.spinHistory],
      );

      // Update state
      final updatedItems = List<RouletteItem>.from(state.items);
      updatedItems[itemIndex] = updatedItem;

      state = state.copyWith(
        items: updatedItems,
        isSpinning: false,
        lastResult: finalResult,
        totalXpWon: state.totalXpWon + xpBonus.toInt(),
      );

      return finalResult;
    } catch (e) {
      state = state.copyWith(
        isSpinning: false,
        error: 'Pomylka obertannia ruletky: $e',
      );
      return SpinResult(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now().toIso8601String(),
        priceBefore: item.currentPrice,
        priceAfter: item.currentPrice,
        isDrop: false,
        xpBonus: 10,
        narrative: 'Zbii systemy! Koleso zastryhlo... Sprobui shche raz.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh current price for an item
  // ---------------------------------------------------------------------------

  Future<void> refreshPrice(String itemId) async {
    final itemIndex = state.items.indexWhere((i) => i.id == itemId);
    if (itemIndex == -1) return;

    final item = state.items[itemIndex];
    final realPrice =
        await _ref.read(serpApiServiceProvider).findLowestPrice('${item.productName} ціна');

    if (realPrice > 0) {
      final updatedItems = List<RouletteItem>.from(state.items);
      updatedItems[itemIndex] = item.copyWith(currentPrice: realPrice);
      state = state.copyWith(items: updatedItems);
    }
  }

  // ---------------------------------------------------------------------------
  // Generate AI narrative for a spin result
  // ---------------------------------------------------------------------------

  Future<String> generateSpinNarrative(
    SpinResult result,
    RouletteItem item,
  ) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      if (result.isDrop && result.xpBonus >= 500) {
        return 'DZHEKPOT!! Tsina vpadala na ${result.dropPercent.toStringAsFixed(1)}%! '
            'Skarbnytsia trishchyt vid ekonomic!';
      } else if (result.isDrop) {
        return 'Nevelychke znyzhennia tsiny vyyavleno! '
            'Znyzhka ${result.dropPercent.toStringAsFixed(1)}%.';
      }
      return 'Koleso obernulos... Tsina bez zmin. Terpinnia, viine!';
    }

    final systemPrompt =
        'Ty VAULT-17 — kyberpunk AI-orakul dodatku NEONCRED. '
        'Ty opysuesh rezultaty obertannia "Ruletky Znyzhok Tsin" — '
        'heimifikovanoi systemy vidstezhennia tsin. Hovorysh ukrainskoiu z '
        'kyberpunk tekhno-metaforamy (ruletka, syhnal, hlybyna, sonar, '
        'akuly, volty, neirony). Bud dramatychnyi ale veselyi. 2-3 rechennia.';

    final userPrompt = 'Rezultat obertannia ruletky:\n'
        'Tovar: ${item.productName}\n'
        'Tsina do: ${result.priceBefore.toStringAsFixed(0)} hrn\n'
        'Tsina pislia: ${result.priceAfter.toStringAsFixed(0)} hrn\n'
        'Znyzhka: ${result.dropPercent.toStringAsFixed(1)}%\n'
        'Rezultat: ${result.isDrop ? (result.xpBonus >= 500 ? "DZHEKPOT" : "Nevelychke znyzhennia") : "Bez zmin"}\n'
        'XP zarobleno: ${result.xpBonus}\n\n'
        'Zenerui korotku kyberpunk-opovid (2-3 rechennia) pro tsiy rezultat. '
        'Yakshcho znyzhka — sviatkuia. Yakshcho ni — nadikhai prodovzhuvaly.';

    try {
      final narrative = await openRouter.chat(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      return narrative ??
          (result.isDrop
              ? 'Syhnal znyzhky vyyavleno! Tsina vpadala.'
              : 'Koleso obernulos... Chas chekaty.');
    } catch (_) {
      return result.isDrop
          ? 'Znyzhka vyyavlena! Zekonomleno ${result.dropAmount.toStringAsFixed(0)} hrn!'
          : 'Koleso movchyt... Chas chekaty.';
    }
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final priceRouletteProvider =
    StateNotifierProvider<PriceRouletteNotifier, PriceRouletteState>((ref) {
  return PriceRouletteNotifier(ref);
});
