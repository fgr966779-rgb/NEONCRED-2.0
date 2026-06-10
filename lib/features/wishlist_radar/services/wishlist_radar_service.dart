import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Wish-List Price Radar — smart wishlist with AI price monitoring & forecasts
// =============================================================================
//
// Monitors wish-list items, fetches current prices via PriceAPI + SerpAPI,
// generates AI price forecasts, urgency badges, and weekly buy guides.
//
// APIs:  PriceAPI.com (primary prices) + SerpAPI Shopping (fallback prices)
//        + OpenRouter (AI forecasts & weekly guides)
// =============================================================================

// -----------------------------------------------------------------------------
// Urgency level enum
// -----------------------------------------------------------------------------

enum UrgencyLevel {
  buy_now('buy_now', 'Купуй зараз'),
  soon('soon', 'Скоро'),
  can_wait('can_wait', 'Може зачекати');

  final String id;
  final String labelUA;
  const UrgencyLevel(this.id, this.labelUA);
}

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// A wish-list item tracked by the radar with price history and AI forecast.
class RadarWishItem {
  final String id;
  final String name;
  final double currentPrice;
  final double lowestPrice;
  final double highestPrice;
  final double priceChange7d;
  final double priceChange30d;
  final String aiForecast; // "up", "down", "stable"
  final double forecastConfidence; // 0-100
  final String forecastReasoning;
  final UrgencyLevel urgency;
  final String bestStore;
  final double bestStorePrice;
  final String lastScanned;
  final double totalSaved; // vs highest price seen

  const RadarWishItem({
    required this.id,
    required this.name,
    this.currentPrice = 0.0,
    this.lowestPrice = 0.0,
    this.highestPrice = 0.0,
    this.priceChange7d = 0.0,
    this.priceChange30d = 0.0,
    this.aiForecast = 'stable',
    this.forecastConfidence = 50.0,
    this.forecastReasoning = '',
    this.urgency = UrgencyLevel.can_wait,
    this.bestStore = '',
    this.bestStorePrice = 0.0,
    this.lastScanned = '',
    this.totalSaved = 0.0,
  });

  RadarWishItem copyWith({
    String? id,
    String? name,
    double? currentPrice,
    double? lowestPrice,
    double? highestPrice,
    double? priceChange7d,
    double? priceChange30d,
    String? aiForecast,
    double? forecastConfidence,
    String? forecastReasoning,
    UrgencyLevel? urgency,
    String? bestStore,
    double? bestStorePrice,
    String? lastScanned,
    double? totalSaved,
  }) {
    return RadarWishItem(
      id: id ?? this.id,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      lowestPrice: lowestPrice ?? this.lowestPrice,
      highestPrice: highestPrice ?? this.highestPrice,
      priceChange7d: priceChange7d ?? this.priceChange7d,
      priceChange30d: priceChange30d ?? this.priceChange30d,
      aiForecast: aiForecast ?? this.aiForecast,
      forecastConfidence: forecastConfidence ?? this.forecastConfidence,
      forecastReasoning: forecastReasoning ?? this.forecastReasoning,
      urgency: urgency ?? this.urgency,
      bestStore: bestStore ?? this.bestStore,
      bestStorePrice: bestStorePrice ?? this.bestStorePrice,
      lastScanned: lastScanned ?? this.lastScanned,
      totalSaved: totalSaved ?? this.totalSaved,
    );
  }
}

/// A single buy recommendation within a weekly guide.
class BuyRecommendation {
  final String itemName;
  final double currentPrice;
  final double savingsVsAvg;
  final String reason;
  final UrgencyLevel urgency;

  const BuyRecommendation({
    required this.itemName,
    this.currentPrice = 0.0,
    this.savingsVsAvg = 0.0,
    this.reason = '',
    this.urgency = UrgencyLevel.can_wait,
  });
}

/// AI-generated weekly buy guide ranking items by urgency.
class WeeklyBuyGuide {
  final String weekLabel;
  final List<BuyRecommendation> recommendations;
  final String aiSummary;

  const WeeklyBuyGuide({
    required this.weekLabel,
    this.recommendations = const [],
    this.aiSummary = '',
  });
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class WishlistRadarState {
  final List<RadarWishItem> wishItems;
  final WeeklyBuyGuide? weeklyGuide;
  final bool isLoading;
  final String? error;
  final double totalPotentialSavings;

  const WishlistRadarState({
    this.wishItems = const [],
    this.weeklyGuide,
    this.isLoading = false,
    this.error,
    this.totalPotentialSavings = 0.0,
  });

  WishlistRadarState copyWith({
    List<RadarWishItem>? wishItems,
    WeeklyBuyGuide? weeklyGuide,
    bool clearGuide = false,
    bool? isLoading,
    String? error,
    double? totalPotentialSavings,
  }) {
    return WishlistRadarState(
      wishItems: wishItems ?? this.wishItems,
      weeklyGuide: clearGuide ? null : (weeklyGuide ?? this.weeklyGuide),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalPotentialSavings: totalPotentialSavings ?? this.totalPotentialSavings,
    );
  }
}

// -----------------------------------------------------------------------------
// PriceAPI.com integration
// -----------------------------------------------------------------------------

Future<Map<String, dynamic>> _fetchPriceApi(
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
    'q': query,
  });

  try {
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'error': 'PriceAPI returned ${response.statusCode}'};
  } catch (e) {
    return {'error': 'PriceAPI request failed: $e'};
  }
}



// -----------------------------------------------------------------------------
// Price fetching with fallback — moved INSIDE the notifier class
// -----------------------------------------------------------------------------

class _PriceFetchResult {
  final double price;
  final String storeName;
  final String url;
  final int storesScanned;

  const _PriceFetchResult({
    required this.price,
    required this.storeName,
    required this.url,
    required this.storesScanned,
  });
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class WishlistRadarNotifier extends StateNotifier<WishlistRadarState> {
  final Ref _ref;

  WishlistRadarNotifier(this._ref) : super(const WishlistRadarState());

  // ---------------------------------------------------------------------------
  // Add a new wish item and fetch its current price
  // ---------------------------------------------------------------------------

  Future<void> addWishItem(String name, double expectedPrice) async {
    final itemId = 'wish_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    final newItem = RadarWishItem(
      id: itemId,
      name: name,
      currentPrice: expectedPrice,
      lowestPrice: expectedPrice,
      highestPrice: expectedPrice,
      bestStorePrice: expectedPrice,
      lastScanned: DateTime.now().toIso8601String(),
    );

    final updatedItems = [...state.wishItems, newItem];
    final totalSavings = _computeTotalSavings(updatedItems);

    state = state.copyWith(
      wishItems: updatedItems,
      totalPotentialSavings: totalSavings,
    );

    // Fetch current price in background
    await _fetchAndUpdatePrice(newItem);
  }

  // ---------------------------------------------------------------------------
  // Remove a wish item
  // ---------------------------------------------------------------------------

  void removeWishItem(String id) {
    final updatedItems = state.wishItems.where((i) => i.id != id).toList();
    final totalSavings = _computeTotalSavings(updatedItems);

    state = state.copyWith(
      wishItems: updatedItems,
      totalPotentialSavings: totalSavings,
    );
  }

  // ---------------------------------------------------------------------------
  // Scan all wish item prices via PriceAPI + SerpAPI
  // ---------------------------------------------------------------------------

  Future<void> scanAllPrices() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final priceApiKey = _ref.read(priceApiApiKeyProvider);

      final updatedItems = <RadarWishItem>[];

      for (final item in state.wishItems) {
        final result = await _fetchBestPrice(
          item.name,
          priceApiKey,
        );

        double newPrice = item.currentPrice;
        String newStore = item.bestStore;

        if (result.price > 0) {
          newPrice = result.price;
          newStore = result.storeName;
        }

        final previousPrice = item.currentPrice;
        final priceDiff = previousPrice > 0
            ? ((newPrice - previousPrice) / previousPrice) * 100
            : 0.0;

        final newLowest = (item.lowestPrice <= 0 || newPrice < item.lowestPrice)
            ? newPrice
            : item.lowestPrice;
        final newHighest = newPrice > item.highestPrice
            ? newPrice
            : item.highestPrice;
        final totalSaved = newHighest - newPrice;

        final urgency = _computeUrgency(
          newPrice,
          newLowest,
          priceDiff,
          item.priceChange7d,
        );

        updatedItems.add(item.copyWith(
          currentPrice: newPrice,
          lowestPrice: newLowest,
          highestPrice: newHighest,
          priceChange7d: priceDiff,
          bestStore: newStore,
          bestStorePrice: newPrice,
          lastScanned: DateTime.now().toIso8601String(),
          totalSaved: totalSaved,
          urgency: urgency,
        ));
      }

      final totalSavings = _computeTotalSavings(updatedItems);

      state = state.copyWith(
        wishItems: updatedItems,
        isLoading: false,
        totalPotentialSavings: totalSavings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка сканування цін: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AI forecast price trend for next 7 days
  // ---------------------------------------------------------------------------

  Future<void> generateForecast(RadarWishItem item) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      state = state.copyWith(
        error: 'AI недоступний -- API ключ не налаштований',
      );
      return;
    }

    try {
      final prompt =
          'Based on current price data for ${item.name}: current=${item.currentPrice.toStringAsFixed(0)}, 7d change=${item.priceChange7d.toStringAsFixed(1)}%, 30d change=${item.priceChange30d.toStringAsFixed(1)}%. '
          'Forecast the price trend for next 7 days. Is it likely to go up, down, or stay stable? '
          'Give confidence level 0-100 and reasoning. Consider seasonal patterns, sales events. Respond in Ukrainian. '
          'Output ONLY a JSON object with keys: "forecast" ("up"/"down"/"stable"), "confidence" (number 0-100), "reasoning" (string in Ukrainian).';

      final result = await openRouter.chatJson(
        systemPrompt:
            'Ти VAULT-17 -- кіберпанк AI прогнозист NEONCRED. Генеруєш лише JSON, без маркдауну.',
        userPrompt: prompt,
        temperature: 0.7,
        maxTokens: 512,
      );

      if (result != null) {
        final forecast = result['forecast']?.toString() ?? 'stable';
        final confidence =
            (result['confidence'] as num?)?.toDouble() ?? 50.0;
        final reasoning =
            result['reasoning']?.toString() ?? 'Прогноз недоступний';

        final updatedItems = state.wishItems.map((i) {
          if (i.id == item.id) {
            return i.copyWith(
              aiForecast: forecast,
              forecastConfidence: confidence,
              forecastReasoning: reasoning,
            );
          }
          return i;
        }).toList();

        state = state.copyWith(wishItems: updatedItems);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Помилка генерації прогнозу: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AI weekly buy guide ranking items by urgency
  // ---------------------------------------------------------------------------

  Future<void> generateWeeklyGuide() async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      state = state.copyWith(
        error: 'AI недоступний -- API ключ не налаштований',
      );
      return;
    }

    try {
      final itemsSummary = state.wishItems.map((item) {
        return '- ${item.name}: поточна=${item.currentPrice.toStringAsFixed(0)} грн, зміна7д=${item.priceChange7d.toStringAsFixed(1)}%, терміновість=${item.urgency.labelUA}';
      }).join('\n');

      final now = DateTime.now();
      final weekLabel =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')} - ${(now.add(const Duration(days: 6))).day.toString().padLeft(2, '0')}.${(now.add(const Duration(days: 6))).month.toString().padLeft(2, '0')}';

      final prompt =
          'Згенеруй тижневий гайд покупок для користувача NEONCRED на основі вішлисту. '
          'Товари:\n$itemsSummary\n\n'
          'Ранжуй за терміновістю покупки. Для кожного товару вкажи: чи варто купити цього тижня і чому. '
          'Враховуй сезонні знижки та тренди цін. Дай короткий підсумок тиждня. '
          'Формат: лише JSON з ключами: "recommendations" (масив обєктів з itemName, currentPrice, savingsVsAvg, reason, urgency="buy_now"/"soon"/"can_wait"), "summary" (рядок українською, кіберпанк стиль).';

      final result = await openRouter.chatJson(
        systemPrompt:
            'Ти VAULT-17 -- кіберпанк AI-асистент NEONCRED. Генеруєш лише JSON, без маркдауну.',
        userPrompt: prompt,
        temperature: 0.8,
        maxTokens: 1024,
      );

      if (result != null) {
        final recsList = result['recommendations'] as List<dynamic>? ?? [];
        final recommendations = recsList.map((r) {
          return BuyRecommendation(
            itemName: r['itemName']?.toString() ?? '',
            currentPrice: (r['currentPrice'] as num?)?.toDouble() ?? 0.0,
            savingsVsAvg: (r['savingsVsAvg'] as num?)?.toDouble() ?? 0.0,
            reason: r['reason']?.toString() ?? '',
            urgency: _parseUrgency(r['urgency']?.toString() ?? 'can_wait'),
          );
        }).toList();

        final summary = result['summary']?.toString() ??
            'Тижневий гайд недоступний.';

        final guide = WeeklyBuyGuide(
          weekLabel: weekLabel,
          recommendations: recommendations,
          aiSummary: summary,
        );

        state = state.copyWith(weeklyGuide: guide);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Помилка генерації тижневого гайду: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Manual urgency override
  // ---------------------------------------------------------------------------

  void setUrgency(String itemId, UrgencyLevel urgency) {
    final updatedItems = state.wishItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(urgency: urgency);
      }
      return item;
    }).toList();

    state = state.copyWith(wishItems: updatedItems);
  }

  // ---------------------------------------------------------------------------
  // Private: fetch price for a single item and update state
  // ---------------------------------------------------------------------------

  Future<void> _fetchAndUpdatePrice(RadarWishItem item) async {
    final priceApiKey = _ref.read(priceApiApiKeyProvider);

    final result = await _fetchBestPrice(item.name, priceApiKey);

    if (result.price > 0) {
      final updatedItems = state.wishItems.map((i) {
        if (i.id == item.id) {
          return i.copyWith(
            currentPrice: result.price,
            lowestPrice: result.price,
            highestPrice: item.highestPrice > 0 ? item.highestPrice : result.price,
            bestStore: result.storeName,
            bestStorePrice: result.price,
            lastScanned: DateTime.now().toIso8601String(),
          );
        }
        return i;
      }).toList();

      final totalSavings = _computeTotalSavings(updatedItems);
      state = state.copyWith(
        wishItems: updatedItems,
        totalPotentialSavings: totalSavings,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private: fetch best price (PriceAPI primary, SerpAPI fallback)
  // ---------------------------------------------------------------------------

  Future<_PriceFetchResult> _fetchBestPrice(
    String query,
    String priceApiKey,
  ) async {
    // Try PriceAPI first
    if (priceApiKey.isNotEmpty) {
      final result = await _fetchPriceApi(query, priceApiKey);
      final offers = result['offers'] as List<dynamic>? ?? [];
      if (offers.isNotEmpty) {
        double lowestPrice = double.maxFinite;
        String storeName = '';
        String url = '';

        for (final offer in offers) {
          final priceStr =
              (offer['price'] ?? offer['total_price'] ?? '0').toString();
          final price =
              double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
          if (price > 0 && price < lowestPrice) {
            lowestPrice = price;
            storeName = (offer['shop_name'] ?? offer['store'] ?? '').toString();
            url = (offer['url'] ?? '').toString();
          }
        }

        if (lowestPrice < double.maxFinite) {
          return _PriceFetchResult(
            price: lowestPrice,
            storeName: storeName,
            url: url,
            storesScanned: offers.length,
          );
        }
      }
    }

    // Fallback to SerpAPI Shopping via centralized service
    final serpApi = _ref.read(serpApiServiceProvider);
    if (serpApi.isConfigured) {
      final result = await serpApi.searchShoppingRaw(query);
      final shoppingResults =
          result['shopping_results'] as List<dynamic>? ?? [];
      if (shoppingResults.isNotEmpty) {
        double lowestPrice = double.maxFinite;
        String storeName = '';
        String url = '';

        for (final r in shoppingResults) {
          final priceStr =
              (r['extracted_price'] ?? r['price'] ?? '0').toString();
          final price =
              double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
          if (price > 0 && price < lowestPrice) {
            lowestPrice = price;
            storeName = (r['store'] ?? r['source'] ?? '').toString();
            url = (r['product_link'] ?? r['link'] ?? '').toString();
          }
        }

        if (lowestPrice < double.maxFinite) {
          return _PriceFetchResult(
            price: lowestPrice,
            storeName: storeName,
            url: url,
            storesScanned: shoppingResults.length,
          );
        }
      }
    }

    return const _PriceFetchResult(
      price: 0.0,
      storeName: '',
      url: '',
      storesScanned: 0,
    );
  }

  // ---------------------------------------------------------------------------
  // Private: compute urgency from price data
  // ---------------------------------------------------------------------------

  UrgencyLevel _computeUrgency(
    double currentPrice,
    double lowestPrice,
    double priceDiff,
    double change7d,
  ) {
    // Price near all-time low and dropping
    if (lowestPrice > 0 && currentPrice <= lowestPrice * 1.05) {
      return UrgencyLevel.buy_now;
    }
    // Significant price drop
    if (priceDiff < -10.0 || change7d < -15.0) {
      return UrgencyLevel.buy_now;
    }
    // Moderate drop
    if (priceDiff < -5.0 || change7d < -8.0) {
      return UrgencyLevel.soon;
    }
    return UrgencyLevel.can_wait;
  }

  // ---------------------------------------------------------------------------
  // Private: compute total potential savings
  // ---------------------------------------------------------------------------

  double _computeTotalSavings(List<RadarWishItem> items) {
    double total = 0.0;
    for (final item in items) {
      total += item.totalSaved;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Private: parse urgency from string
  // ---------------------------------------------------------------------------

  UrgencyLevel _parseUrgency(String value) {
    switch (value) {
      case 'buy_now':
        return UrgencyLevel.buy_now;
      case 'soon':
        return UrgencyLevel.soon;
      case 'can_wait':
        return UrgencyLevel.can_wait;
      default:
        return UrgencyLevel.can_wait;
    }
  }
}

// =============================================================================
// Provider
// =============================================================================

final wishlistRadarProvider =
    StateNotifierProvider<WishlistRadarNotifier, WishlistRadarState>(
  (ref) => WishlistRadarNotifier(ref),
);
