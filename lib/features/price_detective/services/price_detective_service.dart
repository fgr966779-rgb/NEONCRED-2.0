import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../core/data/ukrainian_stores.dart';
import '../../../data/database.dart';

// =============================================================================
// MODELS
// =============================================================================

class PriceHistoryPoint {
  final DateTime date;
  final double priceUah;
  final String storeName;

  const PriceHistoryPoint({
    required this.date,
    required this.priceUah,
    this.storeName = '',
  });
}

class DetectiveItem {
  final String itemId;
  final String productName;
  final String searchQuery;
  final double currentPriceUah;
  final double minPrice30d;
  final double minPrice90d;
  final double minPrice180d;
  final int daysSinceMin;
  final String signal; // buy_now / wait / price_dropping
  final String aiAnalysis;
  final int? goalId;
  final int xpAwarded;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final List<PriceHistoryPoint> priceHistory;

  const DetectiveItem({
    required this.itemId,
    required this.productName,
    required this.searchQuery,
    this.currentPriceUah = 0,
    this.minPrice30d = 0,
    this.minPrice90d = 0,
    this.minPrice180d = 0,
    this.daysSinceMin = 0,
    this.signal = 'wait',
    this.aiAnalysis = '',
    this.goalId,
    this.xpAwarded = 0,
    required this.lastUpdated,
    required this.createdAt,
    this.priceHistory = const [],
  });

  DetectiveItem copyWith({
    String? itemId,
    String? productName,
    String? searchQuery,
    double? currentPriceUah,
    double? minPrice30d,
    double? minPrice90d,
    double? minPrice180d,
    int? daysSinceMin,
    String? signal,
    String? aiAnalysis,
    int? goalId,
    int? xpAwarded,
    DateTime? lastUpdated,
    DateTime? createdAt,
    List<PriceHistoryPoint>? priceHistory,
  }) {
    return DetectiveItem(
      itemId: itemId ?? this.itemId,
      productName: productName ?? this.productName,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPriceUah: currentPriceUah ?? this.currentPriceUah,
      minPrice30d: minPrice30d ?? this.minPrice30d,
      minPrice90d: minPrice90d ?? this.minPrice90d,
      minPrice180d: minPrice180d ?? this.minPrice180d,
      daysSinceMin: daysSinceMin ?? this.daysSinceMin,
      signal: signal ?? this.signal,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      goalId: goalId ?? this.goalId,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }

  /// Signal display name
  String get signalLabel {
    switch (signal) {
      case 'buy_now':
        return 'КУПУЙ';
      case 'price_dropping':
        return 'ЦІНА ПАДАЄ';
      case 'wait':
      default:
        return 'ЧИКАЙ';
    }
  }

  /// Signal color (0xFF...)
  int get signalColor {
    switch (signal) {
      case 'buy_now':
        return 0xFF00FF88; // green
      case 'price_dropping':
        return 0xFFFFD700; // yellow
      case 'wait':
      default:
        return 0xFFFF3366; // pink/red
    }
  }

  /// Price vs minimum comparison
  String get priceVsMin {
    if (minPrice30d <= 0) return 'Недостатньо даних';
    final diff = currentPriceUah - minPrice30d;
    final pct = ((diff / minPrice30d) * 100).toStringAsFixed(0);
    if (diff <= 0) return 'Ціна на мінімумі!';
    return 'На $pct% вище мінімуму ${_fmtPrice(minPrice30d)} грн';
  }
}

class PriceDetectiveStats {
  final int totalTracked;
  final int buyNowCount;
  final int priceDroppingCount;
  final bool hasDetectiveBadge;

  const PriceDetectiveStats({
    this.totalTracked = 0,
    this.buyNowCount = 0,
    this.priceDroppingCount = 0,
    this.hasDetectiveBadge = false,
  });
}

class PriceDetectiveState {
  final List<DetectiveItem> items;
  final bool isLoading;
  final String? error;
  final PriceDetectiveStats stats;

  const PriceDetectiveState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.stats = const PriceDetectiveStats(),
  });

  PriceDetectiveState copyWith({
    List<DetectiveItem>? items,
    bool? isLoading,
    String? error,
    PriceDetectiveStats? stats,
  }) {
    return PriceDetectiveState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

// =============================================================================
// NOTIFIER — Price History Detective Business Logic
// =============================================================================

class PriceDetectiveNotifier extends StateNotifier<PriceDetectiveState> {
  final Ref _ref;

  PriceDetectiveNotifier(this._ref) : super(const PriceDetectiveState());

  // ---- Track New Product ----

  void trackProduct({
    required String productName,
    required String searchQuery,
    int? goalId,
  }) {
    final now = DateTime.now();
    final itemId = 'DET-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(5, '0')}';

    // Build initial price history from Ukrainian stores data
    final listings = getListingsSortedByPrice(searchQuery.isNotEmpty ? searchQuery : productName);
    final initialHistory = <PriceHistoryPoint>[];
    double bestPrice = 0;
    String bestStore = '';

    if (listings.isNotEmpty) {
      for (final listing in listings.take(5)) {
        initialHistory.add(PriceHistoryPoint(
          date: now,
          priceUah: listing.priceUAH,
          storeName: getStoreNameById(listing.storeId) ?? listing.storeId,
        ));
      }
      final cheapest = listings.first;
      bestPrice = cheapest.priceUAH;
      bestStore = getStoreNameById(cheapest.storeId) ?? cheapest.storeId;
    }

    // Determine initial signal
    String signal = 'wait';
    if (bestPrice > 0) {
      signal = 'price_dropping'; // Initial detection
    }

    final item = DetectiveItem(
      itemId: itemId,
      productName: productName.trim(),
      searchQuery: searchQuery.trim().isNotEmpty ? searchQuery.trim() : productName.trim(),
      currentPriceUah: bestPrice,
      minPrice30d: bestPrice,
      minPrice90d: bestPrice,
      minPrice180d: bestPrice,
      daysSinceMin: 0,
      signal: signal,
      goalId: goalId,
      lastUpdated: now,
      createdAt: now,
      priceHistory: initialHistory,
    );

    final newItems = [item, ...state.items];
    state = state.copyWith(
      items: newItems,
      stats: _computeStats(newItems),
      error: null,
    );
  }

  // ---- Poll Prices via SerpAPI ----

  Future<void> pollPrices(String itemId) async {
    final idx = state.items.indexWhere((i) => i.itemId == itemId);
    if (idx == -1) return;

    state = state.copyWith(isLoading: true);

    try {
      final item = state.items[idx];
      double bestPrice = item.currentPriceUah;
      String bestStore = '';

      final serpApi = _ref.read(serpApiServiceProvider);
      if (serpApi.isConfigured) {
        final result = await serpApi.findCheapestOffer('${item.searchQuery} ціна Україна');
        final serpPrice = result['price'] as double? ?? 0;
        if (serpPrice > 0) {
          bestPrice = serpPrice;
          bestStore = result['store'] as String? ?? '';
        }
      }

      // Also check Ukrainian stores data
      final listings = getListingsSortedByPrice(item.searchQuery);
      if (listings.isNotEmpty) {
        final cheapest = listings.first;
        if (cheapest.priceUAH < bestPrice || bestPrice <= 0) {
          bestPrice = cheapest.priceUAH;
          bestStore = getStoreNameById(cheapest.storeId) ?? cheapest.storeId;
        }
      }

      // Add new price history point
      final now = DateTime.now();
      final newHistory = [
        ...item.priceHistory,
        PriceHistoryPoint(
          date: now,
          priceUah: bestPrice,
          storeName: bestStore,
        ),
      ];

      // Calculate min prices from history
      final last30 = newHistory.where((p) => now.difference(p.date).inDays <= 30).toList();
      final last90 = newHistory.where((p) => now.difference(p.date).inDays <= 90).toList();

      double min30 = bestPrice;
      double min90 = bestPrice;
      double min180 = bestPrice;

      if (last30.isNotEmpty) min30 = last30.map((p) => p.priceUah).reduce((a, b) => a < b ? a : b);
      if (last90.isNotEmpty) min90 = last90.map((p) => p.priceUah).reduce((a, b) => a < b ? a : b);
      if (newHistory.isNotEmpty) min180 = newHistory.map((p) => p.priceUah).reduce((a, b) => a < b ? a : b);

      // Calculate days since minimum
      int daysSinceMin = 0;
      final minPoints = last30.where((p) => p.priceUah == min30).toList();
      if (minPoints.isNotEmpty) {
        daysSinceMin = now.difference(minPoints.last.date).inDays;
      }

      // Determine signal
      String signal = 'wait';
      if (bestPrice <= min30 && bestPrice > 0) {
        signal = 'buy_now';
      } else if (item.currentPriceUah > 0 && bestPrice < item.currentPriceUah) {
        signal = 'price_dropping';
      }

      // Award +40 XP if bought at minimum
      var xpToAward = 0;
      if (signal == 'buy_now' && item.signal != 'buy_now') {
        xpToAward = 40;
      }

      final updated = item.copyWith(
        currentPriceUah: bestPrice,
        minPrice30d: min30,
        minPrice90d: min90,
        minPrice180d: min180,
        daysSinceMin: daysSinceMin,
        signal: signal,
        xpAwarded: item.xpAwarded + xpToAward,
        lastUpdated: now,
        priceHistory: newHistory,
      );

      final newItems = [...state.items];
      newItems[idx] = updated;

      state = state.copyWith(
        items: newItems,
        isLoading: false,
        stats: _computeStats(newItems),
      );

      if (xpToAward > 0) {
        _awardXP(xpToAward, source: 'price_detective_buy_at_min');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка опитування цін: $e',
      );
    }
  }

  // ---- Poll All Products ----

  Future<void> pollAllPrices() async {
    for (final item in state.items) {
      await pollPrices(item.itemId);
    }
  }

  // ---- AI Analysis via OpenRouter ----

  Future<void> generateAnalysis(String itemId) async {
    final item = state.items.where((i) => i.itemId == itemId).firstOrNull;
    if (item == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final ai = _ref.read(openRouterServiceProvider);
      final historySummary = item.priceHistory.isNotEmpty
          ? 'Мінімум ${_fmtPrice(item.minPrice30d)} грн був ${item.daysSinceMin} дн. тому'
          : 'Історія цін відсутня';

      final response = await ai.chat(
        systemPrompt:
            'Ти -- Ціновий Детектив. Аналізуй історію цін та давай рекомендації купувати/чекати. '
            'Стиль: кіберпанк-детектив. Використовуй українську мову. '
            'Дай короткий аналіз (2-3 речення): тенденція цін, чи варто купувати зараз, прогноз. '
            'Не додавай зайвих пояснень.',
        userPrompt:
            'Товар: ${item.productName}, поточна ціна: ${_fmtPrice(item.currentPriceUah)} грн, '
            'мін 30д: ${_fmtPrice(item.minPrice30d)} грн, мін 90д: ${_fmtPrice(item.minPrice90d)} грн, '
            'мін 180д: ${_fmtPrice(item.minPrice180d)} грн, $historySummary, '
            'сигнал: ${item.signalLabel}.',
        temperature: 0.8,
        maxTokens: 300,
      );

      final idx = state.items.indexWhere((i) => i.itemId == itemId);
      if (idx == -1) return;

      final updated = state.items[idx].copyWith(aiAnalysis: response ?? _fallbackAnalysis(item));
      final newItems = [...state.items];
      newItems[idx] = updated;

      state = state.copyWith(
        items: newItems,
        isLoading: false,
      );
    } catch (_) {
      final idx = state.items.indexWhere((i) => i.itemId == itemId);
      if (idx == -1) return;

      final updated = state.items[idx].copyWith(aiAnalysis: _fallbackAnalysis(item));
      final newItems = [...state.items];
      newItems[idx] = updated;

      state = state.copyWith(isLoading: false);
    }
  }

  // ---- Delete Item ----

  void deleteItem(String itemId) {
    final newItems = state.items.where((i) => i.itemId != itemId).toList();
    state = state.copyWith(
      items: newItems,
      stats: _computeStats(newItems),
    );
  }

  // ---- Mark as Bought (+40 XP) ----

  void markAsBought(String itemId) {
    final idx = state.items.indexWhere((i) => i.itemId == itemId);
    if (idx == -1) return;

    final item = state.items[idx];
    if (item.xpAwarded < 40) {
      final updated = item.copyWith(xpAwarded: 40);
      final newItems = [...state.items];
      newItems[idx] = updated;

      state = state.copyWith(
        items: newItems,
        stats: _computeStats(newItems),
      );

      _awardXP(40, source: 'price_detective_bought');
    }
  }



  // ---- XP Awarding ----

  void _awardXP(int amount, {String source = 'price_detective'}) {
    try {
      final db = _ref.read(databaseProvider);
      db.addXP(amount, source: source);
    } catch (_) {}
  }

  // ---- Stats Computation ----

  PriceDetectiveStats _computeStats(List<DetectiveItem> items) {
    int buyNow = 0;
    int priceDropping = 0;
    int boughtAtMin = 0;

    for (final i in items) {
      if (i.signal == 'buy_now') buyNow++;
      if (i.signal == 'price_dropping') priceDropping++;
      if (i.xpAwarded >= 40) boughtAtMin++;
    }

    return PriceDetectiveStats(
      totalTracked: items.length,
      buyNowCount: buyNow,
      priceDroppingCount: priceDropping,
      hasDetectiveBadge: boughtAtMin >= 3,
    );
  }

  // ---- Clear Error ----

  void clearError() {
    state = state.copyWith(error: null);
  }

  // ---- Fallback Analysis ----

  String _fallbackAnalysis(DetectiveItem item) {
    if (item.signal == 'buy_now') {
      return '${item.productName} на мінімумі -- ${_fmtPrice(item.currentPriceUah)} грн. '
          'Це найкращий момент для покупки, ціна зросте.';
    }
    if (item.signal == 'price_dropping') {
      return '${item.productName} дешевшає -- зараз ${_fmtPrice(item.currentPriceUah)} грн. '
          'Мінімум був ${item.daysSinceMin} дн. тому. Можливо, варто почекати ще.';
    }
    return '${item.productName} коштує ${_fmtPrice(item.currentPriceUah)} грн. '
        'Мінімум за 30 днів: ${_fmtPrice(item.minPrice30d)} грн. Чекай сигналу "КУПУЙ".';
  }
}

// =============================================================================
// HELPERS
// =============================================================================

String _fmtPrice(double v) {
  return v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ' ',
  );
}

// =============================================================================
// PROVIDER
// =============================================================================

final priceDetectiveProvider =
    StateNotifierProvider<PriceDetectiveNotifier, PriceDetectiveState>(
  (ref) => PriceDetectiveNotifier(ref),
);
