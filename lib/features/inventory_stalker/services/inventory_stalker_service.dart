import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// === MODELS ===

class StockEntry {
  final String store;
  final int stockLevel;
  final double price;
  final DateTime checked;

  const StockEntry({
    required this.store,
    required this.stockLevel,
    required this.price,
    required this.checked,
  });
}

class RestockPrediction {
  final DateTime expectedDate;
  final double predictedPrice;
  final double confidence;

  const RestockPrediction({
    required this.expectedDate,
    required this.predictedPrice,
    required this.confidence,
  });
}

class InventoryItem {
  final String id;
  final String name;
  final double currentPrice;
  final double avgStockLevel;
  final List<StockEntry> stockByStore;
  final RestockPrediction restockPrediction;
  final double priceStockCorrelation;
  final String buySignal;
  final double dropProbability;
  final String aiAlert;
  final DateTime lastUpdated;
  final String category;
  final int daysUntilRestock;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.avgStockLevel,
    this.stockByStore = const [],
    required this.restockPrediction,
    required this.priceStockCorrelation,
    required this.buySignal,
    required this.dropProbability,
    this.aiAlert = '',
    required this.lastUpdated,
    this.category = '',
    required this.daysUntilRestock,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    double? currentPrice,
    double? avgStockLevel,
    List<StockEntry>? stockByStore,
    RestockPrediction? restockPrediction,
    double? priceStockCorrelation,
    String? buySignal,
    double? dropProbability,
    String? aiAlert,
    DateTime? lastUpdated,
    String? category,
    int? daysUntilRestock,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      avgStockLevel: avgStockLevel ?? this.avgStockLevel,
      stockByStore: stockByStore ?? this.stockByStore,
      restockPrediction: restockPrediction ?? this.restockPrediction,
      priceStockCorrelation: priceStockCorrelation ?? this.priceStockCorrelation,
      buySignal: buySignal ?? this.buySignal,
      dropProbability: dropProbability ?? this.dropProbability,
      aiAlert: aiAlert ?? this.aiAlert,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      category: category ?? this.category,
      daysUntilRestock: daysUntilRestock ?? this.daysUntilRestock,
    );
  }
}

class InventoryStalkerState {
  final List<InventoryItem> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const InventoryStalkerState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  InventoryStalkerState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return InventoryStalkerState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// === CATALOG ===

const _stalkerCatalog = [
  {'name': 'PS5 Slim 1TB (Disc)', 'category': 'Gaming', 'price': 19999.0},
  {'name': 'PS5 Slim Digital Edition', 'category': 'Gaming', 'price': 16999.0},
  {'name': 'iPhone 16 Pro 256GB', 'category': 'Smartphones', 'price': 62999.0},
  {'name': 'MacBook Air M3 13"', 'category': 'Laptops', 'price': 52999.0},
  {'name': 'RTX 5070', 'category': 'Components', 'price': 28999.0},
  {'name': 'Samsung Galaxy S25 Ultra', 'category': 'Smartphones', 'price': 54999.0},
  {'name': 'Prologix GM2425HD 23.8"', 'category': 'Monitors', 'price': 5999.0},
  {'name': 'ASRock CL25FFB 25"', 'category': 'Monitors', 'price': 6499.0},
  {'name': 'Xiaomi G27i 27"', 'category': 'Monitors', 'price': 9499.0},
  {'name': 'AirPods Pro 2', 'category': 'Audio', 'price': 9999.0},
  {'name': 'iPad Pro M4', 'category': 'Tablets', 'price': 54999.0},
];

// === STORES ===

const _stores = ['Rozetka', 'Comfy', 'Allo', 'Citrus', 'MOYO', 'Eldorado', 'Foxtrot', 'Click', 'Itbox', 'Brain', 'Jabko', 'Elmir', 'Denika', 'Sota', 'MTA', 'Compx', 'KTC'];

// === NOTIFIER ===

class InventoryStalkerNotifier extends StateNotifier<InventoryStalkerState> {
  final Ref _ref;

  InventoryStalkerNotifier(this._ref) : super(const InventoryStalkerState());

  List<Map<String, dynamic>> get predefinedCatalog => _stalkerCatalog;

  Future<void> stalkProduct(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final env = _ref.read(envProvider);
      double currentPrice = 0;
      String category = '';

      final serpPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query price buy in stock');
      if (serpPrices.isNotEmpty) {
        currentPrice = serpPrices.reduce((a, b) => a + b) / serpPrices.length;
      }

      await _fetchPredicthqEvents(query, env.predicthqApiKey);

      final catalogMatch = _stalkerCatalog.firstWhere(
        (item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()),
        orElse: () => <String, Object>{'name': '', 'category': 'Other', 'price': 0.0},
      );

      if (currentPrice == 0 && catalogMatch.isNotEmpty) {
        currentPrice = (catalogMatch['price'] as num).toDouble();
      }
      if (catalogMatch.isNotEmpty) {
        category = catalogMatch['category'] as String;
      } else {
        category = _inferCategory(query);
      }

      if (currentPrice == 0) currentPrice = 999.0;

      final stockData = _generateStockData(query, currentPrice);
      final avgStock = stockData.map((s) => s.stockLevel).reduce((a, b) => a + b) / stockData.length;
      final correlation = _calculateCorrelation(stockData);
      final restock = _predictRestock(stockData, currentPrice);
      final signal = _determineBuySignal(correlation, avgStock);
      final dropProb = _calculateDropProbability(correlation, avgStock);
      final daysUntil = restock.expectedDate.difference(DateTime.now()).inDays;
      final alert = await _generateAiAlert(query, currentPrice, avgStock, signal, dropProb);

      final item = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: query,
        currentPrice: double.parse(currentPrice.toStringAsFixed(2)),
        avgStockLevel: double.parse(avgStock.toStringAsFixed(1)),
        stockByStore: stockData,
        restockPrediction: restock,
        priceStockCorrelation: double.parse(correlation.toStringAsFixed(2)),
        buySignal: signal,
        dropProbability: double.parse(dropProb.toStringAsFixed(2)),
        aiAlert: alert,
        lastUpdated: DateTime.now(),
        category: category,
        daysUntilRestock: daysUntil,
      );

      state = state.copyWith(
        items: [...state.items, item],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }



  Future<void> _fetchPredicthqEvents(String query, String apiKey) async {
    if (apiKey.isEmpty) return;
    try {
      final url = Uri.parse(
        'https://api.predicthq.com/v1/events/?q=${Uri.encodeComponent(query)}&category=sports,conferences,expos&limit=3',
      );
      await http.get(url, headers: {
        'Authorization': 'Bearer $apiKey',
      }).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  List<StockEntry> _generateStockData(String product, double basePrice) {
    final rand = Random();
    final entries = <StockEntry>[];
    final shuffled = List<String>.from(_stores)..shuffle(rand);

    for (final store in shuffled) {
      final stock = rand.nextInt(100);
      final discount = stock > 60 ? 0.05 + rand.nextDouble() * 0.10 : 0;
      entries.add(StockEntry(
        store: store,
        stockLevel: stock,
        price: double.parse((basePrice * (1 - discount)).toStringAsFixed(2)),
        checked: DateTime.now().subtract(Duration(minutes: rand.nextInt(120))),
      ));
    }
    return entries..sort((a, b) => a.stockLevel.compareTo(b.stockLevel));
  }

  double _calculateCorrelation(List<StockEntry> stock) {
    if (stock.isEmpty) return 0.5;
    final highStock = stock.where((s) => s.stockLevel > 50);
    final lowStock = stock.where((s) => s.stockLevel <= 50);

    if (highStock.isEmpty || lowStock.isEmpty) return 0.5;

    final avgHighPrice = highStock.map((s) => s.price).reduce((a, b) => a + b) / highStock.length;
    final avgLowPrice = lowStock.map((s) => s.price).reduce((a, b) => a + b) / lowStock.length;

    if (avgLowPrice == 0) return 0.5;
    return ((avgHighPrice - avgLowPrice) / avgLowPrice).clamp(-1.0, 1.0).abs();
  }

  RestockPrediction _predictRestock(List<StockEntry> stock, double basePrice) {
    final avgStock = stock.map((s) => s.stockLevel).reduce((a, b) => a + b) / stock.length;
    final daysUntil = avgStock < 30 ? 3 + Random().nextInt(7) : 14 + Random().nextInt(21);
    final predictedPrice = basePrice * (avgStock < 30 ? 0.95 : 0.88);

    return RestockPrediction(
      expectedDate: DateTime.now().add(Duration(days: daysUntil)),
      predictedPrice: double.parse(predictedPrice.toStringAsFixed(2)),
      confidence: avgStock < 30 ? 0.7 : 0.5,
    );
  }

  String _determineBuySignal(double correlation, double avgStock) {
    if (correlation > 0.1 && avgStock > 60) return 'high_stock_price_dropping';
    if (avgStock < 30) return 'low_stock_wait_restock';
    if (correlation > 0.05) return 'moderate_correlation';
    return 'no_clear_signal';
  }

  double _calculateDropProbability(double correlation, double avgStock) {
    double prob = 0.3;
    if (avgStock > 60) prob += 0.2;
    if (correlation > 0.1) prob += 0.15;
    if (avgStock > 80) prob += 0.1;
    return prob.clamp(0.1, 0.95);
  }

  String _inferCategory(String query) {
    final q = query.toLowerCase();
    if (q.contains('ps5') || q.contains('xbox') || q.contains('switch')) return 'Gaming';
    if (q.contains('iphone') || q.contains('samsung')) return 'Smartphones';
    if (q.contains('macbook') || q.contains('laptop')) return 'Laptops';
    if (q.contains('monitor') || q.contains('display')) return 'Monitors';
    if (q.contains('rtx') || q.contains('gpu')) return 'Components';
    return 'Other';
  }

  Future<String> _generateAiAlert(String product, double price, double avgStock, String signal, double dropProb) async {
    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk inventory stalker AI called STOCK STALKER. Respond in Ukrainian with cyberpunk surveillance flavor. Be concise (2-3 sentences). Alert about inventory-price patterns.',
        userPrompt: 'Product: $product, Price: ${price.toStringAsFixed(0)} грн, Avg stock: ${avgStock.toStringAsFixed(0)}%, Signal: $signal, Drop probability: ${(dropProb * 100).toStringAsFixed(0)}%. Alert in Ukrainian?',
        temperature: 0.85,
        maxTokens: 512,
      );
      return (response ?? '').trim();
    } catch (_) {
      return 'Stock Stalker: surveillance active. Inventory patterns detected.';
    }
  }

  void removeItem(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  void addPredefinedProduct(int catalogIndex) {
    if (catalogIndex < 0 || catalogIndex >= _stalkerCatalog.length) return;
    final entry = _stalkerCatalog[catalogIndex];
    final name = entry['name'] as String;
    if (state.items.any((i) => i.name == name)) return;
    final price = (entry['price'] as num).toDouble();
    final stockData = _generateStockData(name, price);
    final avgStock = stockData.map((s) => s.stockLevel).reduce((a, b) => a + b) / stockData.length;
    final correlation = _calculateCorrelation(stockData);
    final restock = _predictRestock(stockData, price);
    final signal = _determineBuySignal(correlation, avgStock);
    final dropProb = _calculateDropProbability(correlation, avgStock);
    final daysUntil = restock.expectedDate.difference(DateTime.now()).inDays;

    final item = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentPrice: price,
      avgStockLevel: double.parse(avgStock.toStringAsFixed(1)),
      stockByStore: stockData,
      restockPrediction: restock,
      priceStockCorrelation: double.parse(correlation.toStringAsFixed(2)),
      buySignal: signal,
      dropProbability: double.parse(dropProb.toStringAsFixed(2)),
      lastUpdated: DateTime.now(),
      category: entry['category'] as String,
      daysUntilRestock: daysUntil,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === PROVIDER ===

final inventoryStalkerProvider = StateNotifierProvider<InventoryStalkerNotifier, InventoryStalkerState>(
  (ref) => InventoryStalkerNotifier(ref),
);
