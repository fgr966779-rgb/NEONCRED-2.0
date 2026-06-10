import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Price Shark Tracker — Real-time price tracking across 20+ stores
// =============================================================================
//
// Tracks prices for wish-list items across multiple online stores, builds a
// 90-day price history, computes a fairness score, and alerts the user when
// prices hit their target. AI generates fairness analysis and buy/wait
// recommendations in Ukrainian cyberpunk style.
//
// APIs:  PriceAPI.com (primary) + SerpAPI Shopping (fallback)
//       + OpenRouter (AI fairness analysis & buy/wait advice)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// A single price point in the 90-day history.
class PricePoint {
  final String date;
  final double price;
  final String store;

  const PricePoint({
    required this.date,
    required this.price,
    required this.store,
  });

  PricePoint copyWith({String? date, double? price, String? store}) {
    return PricePoint(
      date: date ?? this.date,
      price: price ?? this.price,
      store: store ?? this.store,
    );
  }
}

/// A tracked product with full price history and fairness data.
class PriceSharkItem {
  final String id;
  final String name;
  final String searchQuery;
  final double currentPrice;
  final double minPrice90d;
  final double maxPrice90d;
  final double targetPrice;
  final String currency;
  final List<PricePoint> priceHistory;
  final String bestStore;
  final double bestStorePrice;
  final bool isFairPrice;
  final double fairnessScore;
  final String lastUpdated;

  const PriceSharkItem({
    required this.id,
    required this.name,
    required this.searchQuery,
    this.currentPrice = 0.0,
    this.minPrice90d = 0.0,
    this.maxPrice90d = 0.0,
    this.targetPrice = 0.0,
    this.currency = 'UAH',
    this.priceHistory = const [],
    this.bestStore = '',
    this.bestStorePrice = 0.0,
    this.isFairPrice = false,
    this.fairnessScore = 50.0,
    this.lastUpdated = '',
  });

  PriceSharkItem copyWith({
    String? id,
    String? name,
    String? searchQuery,
    double? currentPrice,
    double? minPrice90d,
    double? maxPrice90d,
    double? targetPrice,
    String? currency,
    List<PricePoint>? priceHistory,
    String? bestStore,
    double? bestStorePrice,
    bool? isFairPrice,
    double? fairnessScore,
    String? lastUpdated,
  }) {
    return PriceSharkItem(
      id: id ?? this.id,
      name: name ?? this.name,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPrice: currentPrice ?? this.currentPrice,
      minPrice90d: minPrice90d ?? this.minPrice90d,
      maxPrice90d: maxPrice90d ?? this.maxPrice90d,
      targetPrice: targetPrice ?? this.targetPrice,
      currency: currency ?? this.currency,
      priceHistory: priceHistory ?? this.priceHistory,
      bestStore: bestStore ?? this.bestStore,
      bestStorePrice: bestStorePrice ?? this.bestStorePrice,
      isFairPrice: isFairPrice ?? this.isFairPrice,
      fairnessScore: fairnessScore ?? this.fairnessScore,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Alert for price events.
class PriceAlert {
  final String itemId;
  final String itemName;
  final double previousPrice;
  final double newPrice;
  final double dropPercent;
  final String store;
  final String timestamp;

  const PriceAlert({
    required this.itemId,
    required this.itemName,
    required this.previousPrice,
    required this.newPrice,
    required this.dropPercent,
    required this.store,
    required this.timestamp,
  });
}

/// State for the Price Shark feature.
class PriceSharkState {
  final List<PriceSharkItem> trackedItems;
  final bool isLoading;
  final String? error;
  final List<PriceAlert> alerts;

  const PriceSharkState({
    this.trackedItems = const [],
    this.isLoading = false,
    this.error,
    this.alerts = const [],
  });

  PriceSharkState copyWith({
    List<PriceSharkItem>? trackedItems,
    bool? isLoading,
    String? error,
    List<PriceAlert>? alerts,
  }) {
    return PriceSharkState(
      trackedItems: trackedItems ?? this.trackedItems,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      alerts: alerts ?? this.alerts,
    );
  }
}

// -----------------------------------------------------------------------------
// Predefined product catalog (12 items)
// -----------------------------------------------------------------------------

const _predefinedCatalog = [
  PriceSharkItem(
    id: 'ps5_slim',
    name: 'PlayStation 5 Slim',
    searchQuery: 'PlayStation 5 Slim купить Україна ціна',
    targetPrice: 17999,
  ),
  PriceSharkItem(
    id: 'iphone_16',
    name: 'iPhone 16',
    searchQuery: 'iPhone 16 купить Україна ціна',
    targetPrice: 44999,
  ),
  PriceSharkItem(
    id: 'macbook_air_m3',
    name: 'MacBook Air M3',
    searchQuery: 'MacBook Air M3 13 купить Україна ціна',
    targetPrice: 52999,
  ),
  PriceSharkItem(
    id: 'samsung_s24',
    name: 'Samsung Galaxy S24',
    searchQuery: 'Samsung Galaxy S24 купить Україна ціна',
    targetPrice: 32999,
  ),
  PriceSharkItem(
    id: 'lg_oled_c3',
    name: 'LG OLED C3 55"',
    searchQuery: 'LG OLED C3 55 купить Україна ціна',
    targetPrice: 42999,
  ),
  PriceSharkItem(
    id: 'sony_wh1000xm5',
    name: 'Sony WH-1000XM5',
    searchQuery: 'Sony WH-1000XM5 купить Україна ціна',
    targetPrice: 11999,
  ),
  PriceSharkItem(
    id: 'ipad_air',
    name: 'iPad Air',
    searchQuery: 'iPad Air купить Україна ціна',
    targetPrice: 28999,
  ),
  PriceSharkItem(
    id: 'nintendo_switch_oled',
    name: 'Nintendo Switch OLED',
    searchQuery: 'Nintendo Switch OLED купить Україна ціна',
    targetPrice: 13999,
  ),
  PriceSharkItem(
    id: 'asus_rog_ally',
    name: 'ASUS ROG Ally',
    searchQuery: 'ASUS ROG Ally купить Україна ціна',
    targetPrice: 24999,
  ),
  PriceSharkItem(
    id: 'dji_mini_4_pro',
    name: 'DJI Mini 4 Pro',
    searchQuery: 'DJI Mini 4 Pro купить Україна ціна',
    targetPrice: 24999,
  ),
  PriceSharkItem(
    id: 'gopro_hero_12',
    name: 'GoPro Hero 12',
    searchQuery: 'GoPro Hero 12 купить Україна ціна',
    targetPrice: 14999,
  ),
  PriceSharkItem(
    id: 'steam_deck_oled',
    name: 'Steam Deck OLED',
    searchQuery: 'Steam Deck OLED купить Україна ціна',
    targetPrice: 22999,
  ),
];

// -----------------------------------------------------------------------------
// PriceAPI.com integration
// -----------------------------------------------------------------------------

Future<Map<String, dynamic>> _fetchPriceApiPrices(
  String query,
  String priceApiKey,
) async {
  if (priceApiKey.isEmpty) {
    return {'error': 'PriceAPI key not configured'};
  }

  final uri = Uri.https('api.priceapi.com', '/v2/jobs', {
    'source': 'google_shopping',
    'country': 'ua',
    'key': priceApiKey,
    'query': query,
  });

  try {
    final response = await http.post(uri);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'error': 'PriceAPI returned ${response.statusCode}'};
  } catch (e) {
    return {'error': 'PriceAPI request failed: $e'};
  }
}



// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class PriceSharkNotifier extends StateNotifier<PriceSharkState> {
  final Ref _ref;

  PriceSharkNotifier(this._ref) : super(const PriceSharkState());

  // ---------------------------------------------------------------------------
  // Search for a product using PriceAPI + SerpAPI
  // ---------------------------------------------------------------------------

  Future<List<PricePoint>> searchProduct(String query) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final env = _ref.read(envProvider);
      final priceApiKey = env.priceApiApiKey;
      final usdUahRate = 41.5;

      // Try PriceAPI first
      Map<String, dynamic> result =
          await _fetchPriceApiPrices(query, priceApiKey);

      List<dynamic> shoppingResults =
          result['shopping_results'] as List? ?? [];

      // If PriceAPI failed, try SerpAPI via centralized service
      if (shoppingResults.isEmpty) {
        result = await _ref.read(serpApiServiceProvider).searchShoppingRaw(query);
        shoppingResults = result['shopping_results'] as List? ?? [];
      }

      final prices = <PricePoint>[];
      for (final r in shoppingResults) {
        final priceStr =
            (r['extracted_price'] ?? r['price'] ?? '0').toString();
        final price = double.tryParse(
          priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ?? 0.0;
        final store = (r['store'] ?? r['source'] ?? '').toString();

        if (price > 0) {
          final priceUAH = price < 1000 ? price * usdUahRate : price;
          prices.add(PricePoint(
            date: DateTime.now().toIso8601String().substring(0, 10),
            price: priceUAH,
            store: store,
          ));
        }
      }

      state = state.copyWith(isLoading: false);
      return prices;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Pomylka poshuku akuly: $e',
      );
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Track an item
  // ---------------------------------------------------------------------------

  void trackItem(PriceSharkItem item) {
    final updated = [...state.trackedItems, item];
    state = state.copyWith(trackedItems: updated);
  }

  // ---------------------------------------------------------------------------
  // Remove a tracked item
  // ---------------------------------------------------------------------------

  void removeItem(String id) {
    final updated = state.trackedItems.where((i) => i.id != id).toList();
    state = state.copyWith(trackedItems: updated);
  }

  // ---------------------------------------------------------------------------
  // Set target price for an item
  // ---------------------------------------------------------------------------

  void setTargetPrice(String itemId, double target) {
    final updated = state.trackedItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(targetPrice: target);
      }
      return item;
    }).toList();
    state = state.copyWith(trackedItems: updated);
  }

  // ---------------------------------------------------------------------------
  // Refresh all tracked item prices
  // ---------------------------------------------------------------------------

  Future<void> refreshAllPrices() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final env = _ref.read(envProvider);
      final priceApiKey = env.priceApiApiKey;
      final usdUahRate = 41.5;

      final updatedItems = <PriceSharkItem>[];
      final newAlerts = <PriceAlert>[];

      for (final item in state.trackedItems) {
        // Try PriceAPI first, fall back to SerpAPI
        Map<String, dynamic> result =
            await _fetchPriceApiPrices(item.searchQuery, priceApiKey);

        List<dynamic> shoppingResults =
            result['shopping_results'] as List? ?? [];

        if (shoppingResults.isEmpty) {
          result = await _ref.read(serpApiServiceProvider).searchShoppingRaw(item.searchQuery);
          shoppingResults = result['shopping_results'] as List? ?? [];
        }

        double lowestPrice = double.maxFinite;
        String bestStore = '';
        final pricePoints = <PricePoint>[];

        for (final r in shoppingResults) {
          final priceStr =
              (r['extracted_price'] ?? r['price'] ?? '0').toString();
          final price = double.tryParse(
            priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
          ) ?? 0.0;
          final store = (r['store'] ?? r['source'] ?? '').toString();

          if (price > 0) {
            final priceUAH = price < 1000 ? price * usdUahRate : price;
            pricePoints.add(PricePoint(
              date: DateTime.now().toIso8601String().substring(0, 10),
              price: priceUAH,
              store: store,
            ));

            if (priceUAH < lowestPrice) {
              lowestPrice = priceUAH;
              bestStore = store;
            }
          }
        }

        final newPrice =
            lowestPrice < double.maxFinite ? lowestPrice : item.currentPrice;
        final previousPrice = item.currentPrice;

        // Build updated price history
        final updatedHistory = [...item.priceHistory, ...pricePoints];
        // Keep last 90 entries
        final trimmedHistory = updatedHistory.length > 90
            ? updatedHistory.sublist(updatedHistory.length - 90)
            : updatedHistory;

        // Compute 90-day stats
        final prices = trimmedHistory.map((p) => p.price).toList();
        final minPrice = prices.isNotEmpty ? prices.reduce(min) : newPrice;
        final maxPrice = prices.isNotEmpty ? prices.reduce(max) : newPrice;
        final avgPrice = prices.isNotEmpty
            ? prices.reduce((a, b) => a + b) / prices.length
            : newPrice;

        // Fairness score: 0-100, higher = better deal
        final range = maxPrice - minPrice;
        double fairness = 50.0;
        if (range > 0 && newPrice > 0) {
          fairness = ((1.0 - (newPrice - minPrice) / range) * 100)
              .clamp(0.0, 100.0);
        }
        final isFair = newPrice <= avgPrice;

        final updatedItem = item.copyWith(
          currentPrice: newPrice,
          minPrice90d: minPrice,
          maxPrice90d: maxPrice,
          bestStore: bestStore.isNotEmpty ? bestStore : item.bestStore,
          bestStorePrice: bestStore.isNotEmpty ? lowestPrice : item.bestStorePrice,
          priceHistory: trimmedHistory,
          isFairPrice: isFair,
          fairnessScore: fairness,
          lastUpdated: DateTime.now().toIso8601String(),
        );

        updatedItems.add(updatedItem);

        // Check for price alerts
        if (item.targetPrice > 0 && newPrice <= item.targetPrice && previousPrice > item.targetPrice) {
          final dropPercent = previousPrice > 0
              ? ((previousPrice - newPrice) / previousPrice) * 100
              : 0.0;
          newAlerts.add(PriceAlert(
            itemId: item.id,
            itemName: item.name,
            previousPrice: previousPrice,
            newPrice: newPrice,
            dropPercent: dropPercent,
            store: bestStore,
            timestamp: DateTime.now().toIso8601String(),
          ));
        }
      }

      state = state.copyWith(
        trackedItems: updatedItems,
        alerts: [...newAlerts, ...state.alerts],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Pomylka onovlennya tsin: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generate AI fairness insight for an item
  // ---------------------------------------------------------------------------

  Future<String> generateInsight(PriceSharkItem item) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      return 'AI nedostupnyi — kliuch ne nalashtovanyi. '
          'Tsina ${item.currentPrice.toStringAsFixed(0)} hrn, '
          'chesnist: ${item.fairnessScore.toStringAsFixed(0)}/100';
    }

    final storeList = item.priceHistory
        .take(5)
        .map((p) => '${p.store}: ${p.price.toStringAsFixed(0)} hrn')
        .join('\n');

    final systemPrompt =
        'Ty VAULT-17 — kyberpunk AI-orakul dodatku NEONCRED. '
        'Ty analizuesh tsiny ta daiesh porady kupuvaty/chekaty. '
        'Hovorysh ukrainskoiu z tekhno-metaforamy. Styl: kyberpunk, rizkyi, informatyvnyi.';

    final userPrompt =
        'Proanalizui tsinu na tovar: ${item.name}\n'
        'Potochna tsina: ${item.currentPrice.toStringAsFixed(0)} hrn\n'
        'Minimum 90 dniv: ${item.minPrice90d.toStringAsFixed(0)} hrn\n'
        'Maksimum 90 dniv: ${item.maxPrice90d.toStringAsFixed(0)} hrn\n'
        'Naikrashchyi mahazyn: ${item.bestStore}\n'
        'Chesnist: ${item.fairnessScore.toStringAsFixed(0)}/100\n'
        'Tsiny u mahazynakh:\n$storeList\n\n'
        'Dai korotkyi zvit (3-4 rechennia):\n'
        '1. Chy chesna zaraz tsina?\n'
        '2. Kupuvaty zaraz chy zachehaty?\n'
        '3. Yakyi ochikuvanyi naikrashchyi chas dlya pokupky?\n'
        'Vykorystovui kyberpunk metafory (akuly, hlybyny, sonar, syhnaly).';

    try {
      final result = await openRouter.chat(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      return result ?? 'Sonar movchyt... Ne vdalosia zeneruvaty zvit.';
    } catch (e) {
      return 'Pomylka heneratsii zvitu: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // Check if any item dropped below target price
  // ---------------------------------------------------------------------------

  List<PriceAlert> checkPriceAlerts() {
    final activeAlerts = <PriceAlert>[];
    for (final item in state.trackedItems) {
      if (item.targetPrice > 0 && item.currentPrice <= item.targetPrice) {
        activeAlerts.add(PriceAlert(
          itemId: item.id,
          itemName: item.name,
          previousPrice: item.currentPrice * 1.05,
          newPrice: item.currentPrice,
          dropPercent: 5.0,
          store: item.bestStore,
          timestamp: DateTime.now().toIso8601String(),
        ));
      }
    }
    return activeAlerts;
  }

  // ---------------------------------------------------------------------------
  // Get predefined products catalog
  // ---------------------------------------------------------------------------

  List<PriceSharkItem> get predefinedCatalog => _predefinedCatalog;

  // ---------------------------------------------------------------------------
  // Add item from predefined catalog
  // ---------------------------------------------------------------------------

  void addPredefinedProduct(String itemId) {
    final product = _predefinedCatalog.firstWhere(
      (p) => p.id == itemId,
      orElse: () => throw Exception('Tovar ne znaideno v katalozi'),
    );
    trackItem(product);
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final priceSharkProvider =
    StateNotifierProvider<PriceSharkNotifier, PriceSharkState>((ref) {
  return PriceSharkNotifier(ref);
});
