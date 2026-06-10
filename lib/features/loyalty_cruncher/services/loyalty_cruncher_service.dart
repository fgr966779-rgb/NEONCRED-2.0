import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Store Loyalty Price Cruncher -- compare prices accounting for loyalty
// =============================================================================
//
// Tracks loyalty cards, promo codes, and cashback programs across Ukrainian
// stores. Compares final prices after all discounts, cashback, and promos
// to find the best deal for any product.
//
// APIs:  SerpAPI Shopping (base prices) + CouponAPI (promo codes)
//        + OpenRouter (AI recommendations via VAULT-17 persona)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// A user's loyalty card for a specific store.
class LoyaltyCard {
  final String id;
  final String storeName;
  final String cardNumber;
  final double cashbackPercent;
  final double currentPoints;
  final double pointsValue;
  final String color;

  const LoyaltyCard({
    required this.id,
    required this.storeName,
    required this.cardNumber,
    this.cashbackPercent = 0.0,
    this.currentPoints = 0.0,
    this.pointsValue = 0.0,
    this.color = '#00F0FF',
  });

  LoyaltyCard copyWith({
    String? id,
    String? storeName,
    String? cardNumber,
    double? cashbackPercent,
    double? currentPoints,
    double? pointsValue,
    String? color,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      cardNumber: cardNumber ?? this.cardNumber,
      cashbackPercent: cashbackPercent ?? this.cashbackPercent,
      currentPoints: currentPoints ?? this.currentPoints,
      pointsValue: pointsValue ?? this.pointsValue,
      color: color ?? this.color,
    );
  }
}

/// A coupon code for a specific store.
class CouponCode {
  final String code;
  final String store;
  final double discountAmount;
  final String expiryDate;
  final String description;

  const CouponCode({
    required this.code,
    required this.store,
    this.discountAmount = 0.0,
    this.expiryDate = '',
    this.description = '',
  });

  CouponCode copyWith({
    String? code,
    String? store,
    double? discountAmount,
    String? expiryDate,
    String? description,
  }) {
    return CouponCode(
      code: code ?? this.code,
      store: store ?? this.store,
      discountAmount: discountAmount ?? this.discountAmount,
      expiryDate: expiryDate ?? this.expiryDate,
      description: description ?? this.description,
    );
  }
}

/// Price info for one store.
class StorePrice {
  final String storeName;
  final double basePrice;
  final double cashbackAmount;
  final double couponDiscount;
  final double effectivePrice;

  const StorePrice({
    required this.storeName,
    required this.basePrice,
    this.cashbackAmount = 0.0,
    this.couponDiscount = 0.0,
    this.effectivePrice = 0.0,
  });

  StorePrice copyWith({
    String? storeName,
    double? basePrice,
    double? cashbackAmount,
    double? couponDiscount,
    double? effectivePrice,
  }) {
    return StorePrice(
      storeName: storeName ?? this.storeName,
      basePrice: basePrice ?? this.basePrice,
      cashbackAmount: cashbackAmount ?? this.cashbackAmount,
      couponDiscount: couponDiscount ?? this.couponDiscount,
      effectivePrice: effectivePrice ?? this.effectivePrice,
    );
  }
}

/// Comparison result for a product across stores.
class EffectivePrice {
  final String id;
  final String productName;
  final List<StorePrice> storePrices;
  final double bestEffectivePrice;
  final String bestStore;
  final String bestDealReason;
  final double savingsVsHighest;
  final List<CouponCode> availableCoupons;

  const EffectivePrice({
    required this.id,
    required this.productName,
    this.storePrices = const [],
    this.bestEffectivePrice = 0.0,
    this.bestStore = '',
    this.bestDealReason = '',
    this.savingsVsHighest = 0.0,
    this.availableCoupons = const [],
  });

  EffectivePrice copyWith({
    String? id,
    String? productName,
    List<StorePrice>? storePrices,
    double? bestEffectivePrice,
    String? bestStore,
    String? bestDealReason,
    double? savingsVsHighest,
    List<CouponCode>? availableCoupons,
  }) {
    return EffectivePrice(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      storePrices: storePrices ?? this.storePrices,
      bestEffectivePrice: bestEffectivePrice ?? this.bestEffectivePrice,
      bestStore: bestStore ?? this.bestStore,
      bestDealReason: bestDealReason ?? this.bestDealReason,
      savingsVsHighest: savingsVsHighest ?? this.savingsVsHighest,
      availableCoupons: availableCoupons ?? this.availableCoupons,
    );
  }
}

/// State for the Loyalty Cruncher feature.
class LoyaltyCruncherState {
  final List<LoyaltyCard> cards;
  final List<EffectivePrice> priceComparisons;
  final bool isLoading;
  final String? error;
  final double totalSavings;

  const LoyaltyCruncherState({
    this.cards = const [],
    this.priceComparisons = const [],
    this.isLoading = false,
    this.error,
    this.totalSavings = 0.0,
  });

  LoyaltyCruncherState copyWith({
    List<LoyaltyCard>? cards,
    List<EffectivePrice>? priceComparisons,
    bool? isLoading,
    String? error,
    double? totalSavings,
  }) {
    return LoyaltyCruncherState(
      cards: cards ?? this.cards,
      priceComparisons: priceComparisons ?? this.priceComparisons,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalSavings: totalSavings ?? this.totalSavings,
    );
  }
}

// -----------------------------------------------------------------------------
// Predefined store loyalty programs (Ukraine)
// -----------------------------------------------------------------------------

const _predefinedStores = <LoyaltyCard>[
  LoyaltyCard(
    id: 'rozetka_preset',
    storeName: 'Rozetka',
    cardNumber: '',
    cashbackPercent: 3.0,
    pointsValue: 0.01,
    color: '#6B00FF',
  ),
  LoyaltyCard(
    id: 'comfy_preset',
    storeName: 'Comfy',
    cardNumber: '',
    cashbackPercent: 4.5,
    pointsValue: 0.01,
    color: '#FF3366',
  ),
  LoyaltyCard(
    id: 'atb_preset',
    storeName: 'ATB',
    cardNumber: '',
    cashbackPercent: 1.5,
    pointsValue: 0.005,
    color: '#00FF88',
  ),
  LoyaltyCard(
    id: 'silpo_preset',
    storeName: 'Silpo',
    cardNumber: '',
    cashbackPercent: 2.0,
    pointsValue: 0.01,
    color: '#FFD700',
  ),
  LoyaltyCard(
    id: 'allo_preset',
    storeName: 'Allo',
    cardNumber: '',
    cashbackPercent: 2.5,
    pointsValue: 0.01,
    color: '#00F0FF',
  ),
  LoyaltyCard(
    id: 'moyo_preset',
    storeName: 'MOYO',
    cardNumber: '',
    cashbackPercent: 3.5,
    pointsValue: 0.01,
    color: '#FF8800',
  ),
];



// -----------------------------------------------------------------------------
// CouponAPI -- fetch promo codes
// -----------------------------------------------------------------------------

Future<List<CouponCode>> _fetchCouponApi(
  String storeName,
  String couponApiKey,
) async {
  if (couponApiKey.isEmpty) return [];

  try {
    final uri = Uri.https('api.couponapi.io', '/v1/coupons', {
      'store': storeName,
      'api_key': couponApiKey,
      'country': 'UA',
      'limit': '10',
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) return [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final coupons = body['coupons'] as List<dynamic>? ?? [];

    return coupons.map((c) {
      final map = c as Map<String, dynamic>;
      final discountStr = (map['discount'] ?? '0').toString();
      final discountVal = double.tryParse(
            discountStr.replaceAll(RegExp(r'[^\d.]'), ''),
          ) ??
          0.0;

      return CouponCode(
        code: (map['code'] ?? '').toString(),
        store: storeName,
        discountAmount: discountVal,
        expiryDate: (map['expiry'] ?? '').toString(),
        description: (map['description'] ?? '').toString(),
      );
    }).toList();
  } catch (e) {
    return [];
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class LoyaltyCruncherNotifier extends StateNotifier<LoyaltyCruncherState> {
  final Ref _ref;
  final AppDatabase _db;

  LoyaltyCruncherNotifier(this._ref, this._db)
      : super(const LoyaltyCruncherState()) {
    // Initialize with predefined stores
    _initWithPredefined();
  }

  void _initWithPredefined() {
    if (state.cards.isEmpty) {
      state = state.copyWith(cards: _predefinedStores);
    }
  }

  // ---------------------------------------------------------------------------
  // Add a loyalty card
  // ---------------------------------------------------------------------------

  Future<void> addCard(
    String storeName,
    String cardNumber,
    double cashbackPercent,
  ) async {
    try {
      final id = 'card_${DateTime.now().millisecondsSinceEpoch}';
      final brandColor = _getStoreColor(storeName);

      final card = LoyaltyCard(
        id: id,
        storeName: storeName,
        cardNumber: cardNumber,
        cashbackPercent: cashbackPercent,
        pointsValue: 0.01,
        color: brandColor,
      );

      // Check if card for this store already exists
      final existing = state.cards.where((c) => c.storeName == storeName).toList();
      List<LoyaltyCard> updatedCards;
      if (existing.isNotEmpty) {
        updatedCards = state.cards.map((c) {
          if (c.storeName == storeName) {
            return card.copyWith(id: c.id);
          }
          return c;
        }).toList();
      } else {
        updatedCards = [...state.cards, card];
      }

      // Award XP for adding a card
      await _db.addXP(5, source: 'loyalty_cruncher_add_card');

      state = state.copyWith(
        cards: updatedCards,
        totalSavings: _computeTotalSavings(state.priceComparisons),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка додавання картки: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Remove a loyalty card
  // ---------------------------------------------------------------------------

  void removeCard(String id) {
    final updatedCards = state.cards.where((c) => c.id != id).toList();
    state = state.copyWith(cards: updatedCards);
  }

  // ---------------------------------------------------------------------------
  // Compare prices across stores for a product
  // ---------------------------------------------------------------------------

  Future<void> comparePrices(String productName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final couponKey = _ref.read(couponApiKeyProvider);

      // Fetch shopping results from SerpAPI via centralized service
      final result = await _ref.read(serpApiServiceProvider).searchShoppingRaw(
        '$productName купити Україна цiна',
      );

      final shoppingResults =
          result['shopping_results'] as List<dynamic>? ?? [];

      // Build store prices from results
      final storePrices = <StorePrice>[];
      final allCoupons = <CouponCode>[];

      for (final r in shoppingResults) {
        final storeName = (r['store'] ?? r['source'] ?? '').toString();
        final priceStr =
            (r['extracted_price'] ?? r['price'] ?? '0').toString();
        final basePrice = double.tryParse(
              priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
            ) ??
            0.0;

        if (basePrice <= 0 || storeName.isEmpty) continue;

        // Find loyalty card for this store
        final card = _findCardForStore(storeName);
        final cashbackAmount = card != null
            ? basePrice * card.cashbackPercent / 100
            : 0.0;

        // Fetch coupons for this store
        if (couponKey.isNotEmpty) {
          final storeCoupons = await _fetchCouponApi(storeName, couponKey);
          allCoupons.addAll(storeCoupons);
        }

        // Find best coupon for this store
        final storeCoupons = allCoupons
            .where((c) => c.store.toLowerCase() == storeName.toLowerCase())
            .toList();
        double bestCouponDiscount = 0.0;
        for (final coupon in storeCoupons) {
          if (coupon.discountAmount > bestCouponDiscount) {
            bestCouponDiscount = coupon.discountAmount;
          }
        }

        final effectivePrice =
            (basePrice - cashbackAmount - bestCouponDiscount)
                .clamp(0.0, basePrice);

        storePrices.add(StorePrice(
          storeName: storeName,
          basePrice: basePrice,
          cashbackAmount: cashbackAmount,
          couponDiscount: bestCouponDiscount,
          effectivePrice: effectivePrice,
        ));
      }

      // Determine best deal
      String bestStore = '';
      double bestEffectivePrice = double.maxFinite;
      String bestDealReason = '';

      for (final sp in storePrices) {
        if (sp.effectivePrice < bestEffectivePrice) {
          bestEffectivePrice = sp.effectivePrice;
          bestStore = sp.storeName;

          if (sp.couponDiscount > 0 && sp.couponDiscount >= sp.cashbackAmount) {
            bestDealReason = 'coupon applied';
          } else if (sp.cashbackAmount > 0) {
            bestDealReason = 'best cashback';
          } else {
            bestDealReason = 'lowest base price';
          }
        }
      }

      if (bestEffectivePrice == double.maxFinite) {
        bestEffectivePrice = 0.0;
      }

      // Calculate savings vs highest
      double savingsVsHighest = 0.0;
      if (storePrices.length >= 2) {
        final sorted = List<StorePrice>.from(storePrices)
          ..sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        savingsVsHighest =
            sorted.first.effectivePrice - sorted.last.effectivePrice;
      }

      final comparison = EffectivePrice(
        id: 'comp_${DateTime.now().millisecondsSinceEpoch}',
        productName: productName,
        storePrices: storePrices,
        bestEffectivePrice: bestEffectivePrice,
        bestStore: bestStore,
        bestDealReason: bestDealReason,
        savingsVsHighest: savingsVsHighest,
        availableCoupons: allCoupons,
      );

      final updatedComparisons = [
        comparison,
        ...state.priceComparisons
            .where((c) => c.productName != productName),
      ];

      // Award XP for comparing
      await _db.addXP(10, source: 'loyalty_cruncher_compare');

      // Bonus XP if savings found
      if (savingsVsHighest > 100) {
        await _db.addXP(25, source: 'loyalty_cruncher_savings');
      }

      final totalSavings = _computeTotalSavings(updatedComparisons);

      state = state.copyWith(
        priceComparisons: updatedComparisons,
        isLoading: false,
        totalSavings: totalSavings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка порiвняння цiн: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch coupons for a store
  // ---------------------------------------------------------------------------

  Future<List<CouponCode>> fetchCoupons(String storeName) async {
    final couponKey = _ref.read(couponApiKeyProvider);
    return _fetchCouponApi(storeName, couponKey);
  }

  // ---------------------------------------------------------------------------
  // Generate AI savings tip
  // ---------------------------------------------------------------------------

  Future<String> generateSavingsTip() async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      return 'AI недоступний -- API ключ не налаштований.';
    }

    final stores = state.cards.map((c) => c.storeName).join(', ');
    final cashbacks = state.cards
        .map((c) => '${c.storeName}: ${c.cashbackPercent}%')
        .join(', ');

    final prompt =
        'Generate a personalized savings tip in Ukrainian for a user who shops at $stores. '
        'Consider their cashback rates: $cashbacks and current promotions. '
        'Be specific and actionable. Use cyberpunk techno-metaphors.';

    try {
      final result = await openRouter.chat(
        systemPrompt: 'Ти VAULT-17 -- кiберпанк AI-асистент NEONCRED. '
            'Говори українською з техно-метафорами. Ти аналiзуєш кешбек та лояльнiсть магазинiв.',
        userPrompt: prompt,
        temperature: 0.9,
        maxTokens: 300,
      );
      return result ?? 'VAULT-17 мовчить... Спробуй ще раз.';
    } catch (e) {
      return 'Не вдалося згенерувати пораду: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  LoyaltyCard? _findCardForStore(String storeName) {
    final normalized = storeName.toLowerCase();
    for (final card in state.cards) {
      if (card.storeName.toLowerCase() == normalized) return card;
      if (normalized.contains(card.storeName.toLowerCase()) ||
          card.storeName.toLowerCase().contains(normalized)) {
        return card;
      }
    }
    return null;
  }

  String _getStoreColor(String storeName) {
    final normalized = storeName.toLowerCase();
    if (normalized.contains('rozetka')) return '#6B00FF';
    if (normalized.contains('comfy')) return '#FF3366';
    if (normalized.contains('atb')) return '#00FF88';
    if (normalized.contains('silpo')) return '#FFD700';
    if (normalized.contains('allo')) return '#00F0FF';
    if (normalized.contains('moyo')) return '#FF8800';
    // Random color for unknown stores
    final rng = Random();
    return '#${(rng.nextInt(0xFFFFFF)).toRadixString(16).padLeft(6, '0')}';
  }

  double _computeTotalSavings(List<EffectivePrice> comparisons) {
    double total = 0.0;
    for (final c in comparisons) {
      total += c.savingsVsHighest;
    }
    return total;
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final loyaltyCruncherProvider =
    StateNotifierProvider<LoyaltyCruncherNotifier, LoyaltyCruncherState>(
        (ref) {
  final db = ref.watch(databaseProvider);
  return LoyaltyCruncherNotifier(ref, db);
});
