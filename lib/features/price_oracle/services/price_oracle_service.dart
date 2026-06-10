import 'dart:math';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// =============================================================================
// Price Oracle — Real-time price tracking for wish-list items
// =============================================================================
//
// Tracks actual market prices for items the user is saving towards (PS5,
// iPhone, monitor, car, etc.). Shows progress as "% of current price saved"
// and alerts on price drops — turning real-world price changes into
// instant motivation to deposit.
//
// APIs:  SerpAPI Shopping (product prices) + Twelve Data (forex for UAH/USD)
//        + OpenRouter (AI price insights & wish-phrase parsing)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// A product the user wants to track the price of.
class PriceWatchItem {
  final String itemId;
  final String name;
  final String query; // search query for SerpAPI Shopping
  final double currentPriceUAH;
  final double previousPriceUAH;
  final double targetPriceUAH; // user's target / budget
  final int? goalId; // linked savings goal
  final String currency;
  final String imageUrl;
  final String storeName;
  final DateTime lastUpdated;
  final List<PricePoint> priceHistory; // last 30 days

  PriceWatchItem({
    required this.itemId,
    required this.name,
    required this.query,
    this.currentPriceUAH = 0.0,
    this.previousPriceUAH = 0.0,
    this.targetPriceUAH = 0.0,
    this.goalId,
    this.currency = 'UAH',
    this.imageUrl = '',
    this.storeName = '',
    DateTime? lastUpdated,
    this.priceHistory = const [],
  }) : lastUpdated = lastUpdated ?? DateTime(2000);

  // Non-const factory for use in non-const contexts
  factory PriceWatchItem.create({
    required String itemId,
    required String name,
    required String query,
    double currentPriceUAH = 0.0,
    double previousPriceUAH = 0.0,
    double targetPriceUAH = 0.0,
    int? goalId,
    String currency = 'UAH',
    String imageUrl = '',
    String storeName = '',
    DateTime? lastUpdated,
    List<PricePoint> priceHistory = const [],
  }) {
    return PriceWatchItem(
      itemId: itemId,
      name: name,
      query: query,
      currentPriceUAH: currentPriceUAH,
      previousPriceUAH: previousPriceUAH,
      targetPriceUAH: targetPriceUAH,
      goalId: goalId,
      currency: currency,
      imageUrl: imageUrl,
      storeName: storeName,
      lastUpdated: lastUpdated,
      priceHistory: priceHistory,
    );
  }

  double get priceChangePercent =>
      previousPriceUAH > 0
          ? ((currentPriceUAH - previousPriceUAH) / previousPriceUAH) * 100
          : 0.0;

  bool get isPriceDrop => priceChangePercent < -1.0;

  /// How much the user has saved towards this item (from linked goal).
  double savedAmount(Ref ref) {
    if (goalId == null) return 0.0;
    // Read from database — actual amount comes from goal
    return 0.0; // placeholder; screen will compute from goal
  }

  PriceWatchItem copyWith({
    String? itemId,
    String? name,
    String? query,
    double? currentPriceUAH,
    double? previousPriceUAH,
    double? targetPriceUAH,
    int? goalId,
    String? currency,
    String? imageUrl,
    String? storeName,
    DateTime? lastUpdated,
    List<PricePoint>? priceHistory,
  }) {
    return PriceWatchItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      query: query ?? this.query,
      currentPriceUAH: currentPriceUAH ?? this.currentPriceUAH,
      previousPriceUAH: previousPriceUAH ?? this.previousPriceUAH,
      targetPriceUAH: targetPriceUAH ?? this.targetPriceUAH,
      goalId: goalId ?? this.goalId,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      storeName: storeName ?? this.storeName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }
}

class PricePoint {
  final DateTime date;
  final double priceUAH;

  const PricePoint({required this.date, required this.priceUAH});
}

/// Price alert configuration.
enum PriceAlertType {
  priceDrop('price_drop', 'Зниження ціни'),
  targetReached('target_reached', 'Ціль досягнута'),
  priceSpike('price_spike', 'Різкий ріст ціни'),
  weeklyReport('weekly_report', 'Тижневий звіт');

  final String id;
  final String labelUA;
  const PriceAlertType(this.id, this.labelUA);
}

class PriceAlert {
  final String alertId;
  final String itemId;
  final PriceAlertType type;
  final String messageUA;
  final double priceAtAlert;
  final double thresholdValue;
  final DateTime triggeredAt;
  final bool isRead;

  PriceAlert({
    required this.alertId,
    required this.itemId,
    required this.type,
    required this.messageUA,
    this.priceAtAlert = 0.0,
    this.thresholdValue = 0.0,
    DateTime? triggeredAt,
    this.isRead = false,
  }) : triggeredAt = triggeredAt ?? DateTime(2000);
}

/// Overall stats for the Price Oracle feature.
class PriceOracleStats {
  final int totalItems;
  final int activeAlerts;
  final double totalSavingsProgress; // 0.0 - 1.0
  final double biggestPriceDropPercent;
  final int priceDropAlertsTriggered;
  final double potentialSavingsUAH; // money saved by price drops

  const PriceOracleStats({
    this.totalItems = 0,
    this.activeAlerts = 0,
    this.totalSavingsProgress = 0.0,
    this.biggestPriceDropPercent = 0.0,
    this.priceDropAlertsTriggered = 0,
    this.potentialSavingsUAH = 0.0,
  });
}

// -----------------------------------------------------------------------------
// Predefined product catalog (quick-add for common wishes)
// -----------------------------------------------------------------------------

final _predefinedProducts = [
  PriceWatchItem(
    itemId: 'ps5_disc',
    name: 'PlayStation 5 (Disc Edition)',
    query: 'PlayStation 5 Disc Edition купить Україна ціна',
    targetPriceUAH: 18999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'ps5_digital',
    name: 'PlayStation 5 (Digital Edition)',
    query: 'PlayStation 5 Digital Edition купить Україна ціна',
    targetPriceUAH: 15999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'iphone_16',
    name: 'iPhone 16 (128GB)',
    query: 'iPhone 16 128GB купить Україна ціна',
    targetPriceUAH: 42999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'iphone_16_pro',
    name: 'iPhone 16 Pro (256GB)',
    query: 'iPhone 16 Pro 256GB купить Україна ціна',
    targetPriceUAH: 62999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'macbook_air_m3',
    name: 'MacBook Air M3 (13")',
    query: 'MacBook Air M3 13 купить Україна ціна',
    targetPriceUAH: 52999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'samsung_s24_ultra',
    name: 'Samsung Galaxy S24 Ultra',
    query: 'Samsung Galaxy S24 Ultra купить Україна ціна',
    targetPriceUAH: 49999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'monitor_4k_27',
    name: '4K Monitor 27" (IPS)',
    query: '4K монітор 27 IPS купить Україна ціна',
    targetPriceUAH: 14999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'gaming_pc',
    name: 'Gaming PC (RTX 4070)',
    query: 'ігровий ПК RTX 4070 купить Україна ціна',
    targetPriceUAH: 59999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'airpods_pro_2',
    name: 'AirPods Pro 2',
    query: 'AirPods Pro 2 купить Україна ціна',
    targetPriceUAH: 9999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'nintendo_switch_oled',
    name: 'Nintendo Switch OLED',
    query: 'Nintendo Switch OLED купить Україна ціна',
    targetPriceUAH: 13999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'drone_dji_mini',
    name: 'DJI Mini 4 Pro',
    query: 'DJI Mini 4 Pro купить Україна ціна',
    targetPriceUAH: 24999,
    currency: 'UAH',
  ),
  PriceWatchItem(
    itemId: 'electric_scooter',
    name: 'Електросамокат (Premium)',
    query: 'електросамокат преміум купить Україна ціна',
    targetPriceUAH: 29999,
    currency: 'UAH',
  ),
];



// -----------------------------------------------------------------------------
// Twelve Data forex (USD/UAH rate)
// -----------------------------------------------------------------------------

Future<double> _fetchUsdUahRate(String twelveDataKey) async {
  if (twelveDataKey.isEmpty) return 41.5; // fallback rate

  final uri = Uri.https('api.twelvedata.com', '/price', {
    'symbol': 'USD/UAH',
    'apikey': twelveDataKey,
  });

  // In production: final response = await http.get(uri);
  // For now, return approximate rate
  return 41.5;
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class PriceOracleState {
  final List<PriceWatchItem> watchItems;
  final List<PriceAlert> alerts;
  final PriceOracleStats stats;
  final bool isRefreshing;
  final bool isAddingItem;
  final String? error;

  const PriceOracleState({
    this.watchItems = const [],
    this.alerts = const [],
    this.stats = const PriceOracleStats(),
    this.isRefreshing = false,
    this.isAddingItem = false,
    this.error,
  });

  PriceOracleState copyWith({
    List<PriceWatchItem>? watchItems,
    List<PriceAlert>? alerts,
    PriceOracleStats? stats,
    bool? isRefreshing,
    bool? isAddingItem,
    String? error,
  }) {
    return PriceOracleState(
      watchItems: watchItems ?? this.watchItems,
      alerts: alerts ?? this.alerts,
      stats: stats ?? this.stats,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isAddingItem: isAddingItem ?? this.isAddingItem,
      error: error,
    );
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class PriceOracleNotifier extends StateNotifier<PriceOracleState> {
  final Ref _ref;
  final AppDatabase _db;

  PriceOracleNotifier(this._ref, this._db) : super(const PriceOracleState());

  // ---------------------------------------------------------------------------
  // Fetch all watched items from DB + refresh prices
  // ---------------------------------------------------------------------------

  Future<void> loadWatchItems() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final rows = await _db.getAllPriceWatchItems();
      final items = rows.map((row) => PriceWatchItem(
        itemId: row.itemId,
        name: row.name,
        query: row.searchQuery,
        currentPriceUAH: row.currentPriceUah,
        previousPriceUAH: row.previousPriceUah,
        targetPriceUAH: row.targetPriceUah,
        goalId: row.goalId,
        currency: row.currency,
        imageUrl: row.imageUrl,
        storeName: row.storeName,
        lastUpdated: row.lastUpdated,
      )).toList();

      state = state.copyWith(
        watchItems: items,
        isRefreshing: false,
        stats: _computeStats(items),
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Помилка завантаження: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh prices from SerpAPI Shopping
  // ---------------------------------------------------------------------------

  Future<void> refreshPrices() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      final twelveKey = _ref.read(twelveDataApiKeyProvider);
      final usdUah = await _fetchUsdUahRate(twelveKey);

      final updatedItems = <PriceWatchItem>[];
      final newAlerts = <PriceAlert>[];

      final serpApi = _ref.read(serpApiServiceProvider);

      for (final item in state.watchItems) {
        final result = await serpApi.searchShoppingRaw(item.query);

        double newPrice = item.currentPriceUAH;

        // Parse shopping results if available
        final shoppingResults = result['shopping_results'] as List? ?? [];
        if (shoppingResults.isNotEmpty) {
          // Find lowest price from results
          double lowestPrice = double.maxFinite;
          String storeName = item.storeName;
          String imageUrl = item.imageUrl;

          for (final r in shoppingResults) {
            final priceStr = (r['extracted_price'] ?? r['price'] ?? '0')
                .toString();
            final price = double.tryParse(
              priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
            ) ?? 0.0;
            if (price > 0 && price < lowestPrice) {
              lowestPrice = price;
              storeName = (r['store'] ?? r['source'] ?? item.storeName)
                  .toString();
              imageUrl = (r['thumbnail'] ?? item.imageUrl).toString();
            }
          }

          if (lowestPrice < double.maxFinite) {
            // Check if price is in USD and convert
            if (lowestPrice < 1000 && lowestPrice > 0) {
              // Likely USD if under 1000 for electronics
              newPrice = lowestPrice * usdUah;
            } else {
              newPrice = lowestPrice;
            }
          }
        }

        final previousPrice = item.currentPriceUAH;
        final updated = item.copyWith(
          currentPriceUAH: newPrice,
          previousPriceUAH: previousPrice,
          storeName: item.storeName,
          lastUpdated: DateTime.now(),
        );

        updatedItems.add(updated);

        // Generate price drop alert
        if (updated.isPriceDrop) {
          newAlerts.add(PriceAlert(
            alertId: 'alert_${item.itemId}_${DateTime.now().millisecondsSinceEpoch}',
            itemId: item.itemId,
            type: PriceAlertType.priceDrop,
            messageUA: 'Ціна на ${item.name} впала на ${updated.priceChangePercent.abs().toStringAsFixed(1)}%! '
                'Зараз ${newPrice.toStringAsFixed(0)}₴',
            priceAtAlert: newPrice,
            thresholdValue: previousPrice,
            triggeredAt: DateTime.now(),
          ));

          // Award XP for price awareness
          await _db.addXP(15, source: 'price_drop_alert');
        }

        // Check if savings goal is reachable
        if (updated.goalId != null && updated.targetPriceUAH > 0) {
          final goals = await _db.getAllGoals();
          final goal = goals.where((g) => g.id == updated.goalId).firstOrNull;
          if (goal != null && goal.currentAmount >= newPrice) {
            newAlerts.add(PriceAlert(
              alertId: 'target_${item.itemId}_${DateTime.now().millisecondsSinceEpoch}',
              itemId: item.itemId,
              type: PriceAlertType.targetReached,
              messageUA: 'У тебе вже достатньо коштів для ${item.name}! 🎯',
              priceAtAlert: newPrice,
              triggeredAt: DateTime.now(),
            ));
          }
        }

        // Update DB
        final dbId = await _db.getPriceWatchItemId(item.itemId);
        await _db.updatePriceWatchItem(dbId, PriceWatchItemsCompanion(
          currentPriceUah: Value(newPrice),
          previousPriceUah: Value(previousPrice),
          storeName: Value(updated.storeName),
          imageUrl: Value(updated.imageUrl),
          lastUpdated: Value(DateTime.now()),
        ));
      }

      state = state.copyWith(
        watchItems: updatedItems,
        alerts: [...newAlerts, ...state.alerts],
        isRefreshing: false,
        stats: _computeStats(updatedItems),
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Помилка оновлення цін: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Add a new item to watch list
  // ---------------------------------------------------------------------------

  Future<void> addWatchItem(PriceWatchItem item) async {
    state = state.copyWith(isAddingItem: true, error: null);

    try {
      await _db.insertPriceWatchItem(PriceWatchItemsCompanion(
        itemId: Value(item.itemId),
        name: Value(item.name),
        searchQuery: Value(item.query),
        currentPriceUah: Value(item.currentPriceUAH),
        previousPriceUah: Value(item.previousPriceUAH),
        targetPriceUah: Value(item.targetPriceUAH),
        goalId: Value(item.goalId),
        currency: Value(item.currency),
        imageUrl: Value(item.imageUrl),
        storeName: Value(item.storeName),
        lastUpdated: Value(DateTime.now()),
      ));

      final updated = [...state.watchItems, item];
      state = state.copyWith(
        watchItems: updated,
        isAddingItem: false,
        stats: _computeStats(updated),
      );

      await _db.addXP(10, source: 'price_oracle_add_item');
    } catch (e) {
      state = state.copyWith(
        isAddingItem: false,
        error: 'Помилка додавання: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Add from predefined catalog
  // ---------------------------------------------------------------------------

  Future<void> addPredefinedItem(String itemId) async {
    final item = _predefinedProducts.firstWhere(
      (p) => p.itemId == itemId,
      orElse: () => throw Exception('Product not found'),
    );
    await addWatchItem(item);
  }

  // ---------------------------------------------------------------------------
  // Remove item from watch list
  // ---------------------------------------------------------------------------

  Future<void> removeWatchItem(String itemId) async {
    try {
      await _db.deletePriceWatchItemByItemId(itemId);
      final updated = state.watchItems.where((i) => i.itemId != itemId).toList();
      state = state.copyWith(
        watchItems: updated,
        stats: _computeStats(updated),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка видалення: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Link a goal to a watch item
  // ---------------------------------------------------------------------------

  Future<void> linkGoal(String itemId, int goalId) async {
    final updated = state.watchItems.map((item) {
      if (item.itemId == itemId) {
        return item.copyWith(goalId: goalId);
      }
      return item;
    }).toList();

    state = state.copyWith(watchItems: updated);
  }

  // ---------------------------------------------------------------------------
  // Dismiss alert
  // ---------------------------------------------------------------------------

  void dismissAlert(String alertId) {
    state = state.copyWith(
      alerts: state.alerts.where((a) => a.alertId != alertId).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // AI insight — generate personalized buying advice
  // ---------------------------------------------------------------------------

  Future<String> generateInsight(PriceWatchItem item) async {
    final openRouter = _ref.read(openRouterServiceProvider);

    try {
      return (await openRouter.chat(
        systemPrompt: 'Ти VAULT-17 — кіберпанк AI-асистент додатку NEONCRED. Дай коротку (2-3 речення) пораду українською: 1. Чи варто купувати зараз чи зачекати? 2. Який прогноз ціни на найближчі 2 тижні? Стиль: кіберпанк, використовуй техно-метафори.',
        userPrompt: 'Користувач відстежує ціну на товар: ${item.name}\nПоточна ціна: ${item.currentPriceUAH.toStringAsFixed(0)}₴\nПопередня ціна: ${item.previousPriceUAH.toStringAsFixed(0)}₴\nЗміна: ${item.priceChangePercent.toStringAsFixed(1)}%',
        temperature: 0.85,
        maxTokens: 256,
      )) ?? 'Не вдалося згенерувати інсайт';
    } catch (e) {
      return 'Не вдалося згенерувати інсайт: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // Get predefined products catalog
  // ---------------------------------------------------------------------------

  List<PriceWatchItem> get predefinedProducts => _predefinedProducts;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  PriceOracleStats _computeStats(List<PriceWatchItem> items) {
    if (items.isEmpty) return const PriceOracleStats();

    double biggestDrop = 0.0;
    double totalProgress = 0.0;
    int dropCount = 0;
    double potentialSavings = 0.0;

    for (final item in items) {
      if (item.isPriceDrop) {
        dropCount++;
        final drop = item.priceChangePercent.abs();
        if (drop > biggestDrop) biggestDrop = drop;
        potentialSavings += item.previousPriceUAH - item.currentPriceUAH;
      }
      if (item.targetPriceUAH > 0) {
        totalProgress += (item.currentPriceUAH / item.targetPriceUAH).clamp(0.0, 1.0);
      }
    }

    return PriceOracleStats(
      totalItems: items.length,
      activeAlerts: state.alerts.where((a) => !a.isRead).length,
      totalSavingsProgress: items.isNotEmpty ? totalProgress / items.length : 0.0,
      biggestPriceDropPercent: biggestDrop,
      priceDropAlertsTriggered: dropCount,
      potentialSavingsUAH: potentialSavings,
    );
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final priceOracleProvider =
    StateNotifierProvider<PriceOracleNotifier, PriceOracleState>((ref) {
  final db = ref.watch(databaseProvider);
  return PriceOracleNotifier(ref, db);
});
