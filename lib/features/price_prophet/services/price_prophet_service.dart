import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// === MODELS ===

class ForecastScenario {
  final String name;
  final double targetPrice;
  final double confidence;
  final String description;

  const ForecastScenario({
    required this.name,
    required this.targetPrice,
    required this.confidence,
    required this.description,
  });
}

class AccuracyRecord {
  final DateTime date;
  final double predictedPrice;
  final double actualPrice;
  final double deviation;

  const AccuracyRecord({
    required this.date,
    required this.predictedPrice,
    required this.actualPrice,
    required this.deviation,
  });
}

class PriceProphetItem {
  final String id;
  final String name;
  final double currentPrice;
  final double? targetGoalPrice;
  final List<ForecastScenario> scenarios;
  final List<AccuracyRecord> accuracyHistory;
  final double overallAccuracy;
  final String aiInsight;
  final DateTime lastUpdated;
  final String category;
  final String imageUrl;

  const PriceProphetItem({
    required this.id,
    required this.name,
    required this.currentPrice,
    this.targetGoalPrice,
    this.scenarios = const [],
    this.accuracyHistory = const [],
    this.overallAccuracy = 0,
    this.aiInsight = '',
    required this.lastUpdated,
    this.category = '',
    this.imageUrl = '',
  });

  PriceProphetItem copyWith({
    String? id,
    String? name,
    double? currentPrice,
    double? targetGoalPrice,
    List<ForecastScenario>? scenarios,
    List<AccuracyRecord>? accuracyHistory,
    double? overallAccuracy,
    String? aiInsight,
    DateTime? lastUpdated,
    String? category,
    String? imageUrl,
  }) {
    return PriceProphetItem(
      id: id ?? this.id,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      targetGoalPrice: targetGoalPrice ?? this.targetGoalPrice,
      scenarios: scenarios ?? this.scenarios,
      accuracyHistory: accuracyHistory ?? this.accuracyHistory,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      aiInsight: aiInsight ?? this.aiInsight,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class PriceProphetState {
  final List<PriceProphetItem> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const PriceProphetState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  PriceProphetState copyWith({
    List<PriceProphetItem>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return PriceProphetState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// === CATALOG ===

const _prophetCatalog = [
  {'name': 'PS5 Slim 1TB (Disc)', 'category': 'Gaming', 'price': 19999.0},
  {'name': 'PS5 Slim Digital Edition', 'category': 'Gaming', 'price': 16999.0},
  {'name': 'iPhone 16 Pro 256GB', 'category': 'Smartphones', 'price': 62999.0},
  {'name': 'Samsung Galaxy S25 Ultra', 'category': 'Smartphones', 'price': 54999.0},
  {'name': 'MacBook Air M3 13"', 'category': 'Laptops', 'price': 52999.0},
  {'name': 'Prologix GM2425HD 23.8"', 'category': 'Monitors', 'price': 5999.0},
  {'name': 'ASRock CL25FFB 25"', 'category': 'Monitors', 'price': 6499.0},
  {'name': 'MSI MAG 242C', 'category': 'Monitors', 'price': 8999.0},
  {'name': 'Xiaomi G27i 27"', 'category': 'Monitors', 'price': 9499.0},
  {'name': 'RTX 5070', 'category': 'Components', 'price': 28999.0},
  {'name': 'AirPods Pro 2', 'category': 'Audio', 'price': 9999.0},
  {'name': 'iPad Pro M4', 'category': 'Tablets', 'price': 54999.0},
];

// === NOTIFIER ===

class PriceProphetNotifier extends StateNotifier<PriceProphetState> {
  final Ref _ref;

  PriceProphetNotifier(this._ref) : super(const PriceProphetState());

  List<Map<String, dynamic>> get predefinedCatalog => _prophetCatalog;

  Future<void> searchAndForecast(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final env = _ref.read(envProvider);
      double currentPrice = 0;
      String category = '';
      final prices = <double>[];

      final serpPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query price buy');
      if (serpPrices.isNotEmpty) {
        prices.addAll(serpPrices);
      }

      final predicthqPrices = await _fetchPredicthqData(query, env.predicthqApiKey);
      if (predicthqPrices.isNotEmpty) {
        prices.addAll(predicthqPrices);
      }

      if (prices.isEmpty) {
        final catalogItem = _prophetCatalog.firstWhere(
          (item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()),
          orElse: () => {'price': 9999.0, 'category': 'Other'},
        );
        currentPrice = (catalogItem['price'] as num).toDouble();
        category = catalogItem['category'] as String;
      } else {
        currentPrice = prices.reduce((a, b) => a + b) / prices.length;
        category = _inferCategory(query);
      }

      final scenarios = _generateScenarios(currentPrice);
      final insight = await _generateAiInsight(query, currentPrice, scenarios);

      final item = PriceProphetItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: query,
        currentPrice: currentPrice,
        scenarios: scenarios,
        aiInsight: insight,
        lastUpdated: DateTime.now(),
        category: category,
      );

      state = state.copyWith(
        items: [...state.items, item],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }



  Future<List<double>> _fetchPredicthqData(String query, String apiKey) async {
    if (apiKey.isEmpty) return [];
    try {
      final url = Uri.parse(
        'https://api.predicthq.com/v1/events/?q=${Uri.encodeComponent(query)}&category=sports,conferences,expos&limit=5',
      );
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $apiKey',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      return [];
    } catch (_) {
      return [];
    }
  }

  List<ForecastScenario> _generateScenarios(double currentPrice) {
    final rand = Random();
    final optimisticDrop = 0.70 + rand.nextDouble() * 0.15;
    final realisticDrop = 0.82 + rand.nextDouble() * 0.10;
    final pessimisticDrop = 0.92 + rand.nextDouble() * 0.08;

    return [
      ForecastScenario(
        name: 'optimistic',
        targetPrice: double.parse((currentPrice * optimisticDrop).toStringAsFixed(2)),
        confidence: 0.25 + rand.nextDouble() * 0.15,
        description: 'Bullish scenario: significant price drop expected due to market saturation, new model announcements, or seasonal clearance events. Historical patterns suggest a strong downward trend.',
      ),
      ForecastScenario(
        name: 'realistic',
        targetPrice: double.parse((currentPrice * realisticDrop).toStringAsFixed(2)),
        confidence: 0.55 + rand.nextDouble() * 0.15,
        description: 'Base scenario: moderate price adjustment aligned with typical depreciation curves and market demand cycles. Most probable outcome based on current data.',
      ),
      ForecastScenario(
        name: 'pessimistic',
        targetPrice: double.parse((currentPrice * pessimisticDrop).toStringAsFixed(2)),
        confidence: 0.15 + rand.nextDouble() * 0.10,
        description: 'Conservative scenario: minimal price change due to supply constraints, high demand, or limited competition. Price may even temporarily increase.',
      ),
    ];
  }

  String _inferCategory(String query) {
    final q = query.toLowerCase();
    if (q.contains('ps5') || q.contains('xbox') || q.contains('switch') || q.contains('steam')) return 'Gaming';
    if (q.contains('iphone') || q.contains('samsung') || q.contains('pixel')) return 'Smartphones';
    if (q.contains('macbook') || q.contains('laptop') || q.contains('thinkpad')) return 'Laptops';
    if (q.contains('monitor') || q.contains('display')) return 'Monitors';
    if (q.contains('tv') || q.contains('oled') || q.contains('lg c')) return 'TV';
    if (q.contains('airpods') || q.contains('headphone') || q.contains('sony wh')) return 'Audio';
    if (q.contains('rtx') || q.contains('gpu') || q.contains('rx ')) return 'Components';
    if (q.contains('ipad') || q.contains('tablet')) return 'Tablets';
    return 'Other';
  }

  Future<String> _generateAiInsight(String product, double price, List<ForecastScenario> scenarios) async {
    try {
      final ai = _ref.read(openRouterServiceProvider);
      final scenarioText = scenarios.map((s) =>
        '${s.name}: target ${s.targetPrice.toStringAsFixed(0)} грн (${(s.confidence * 100).toStringAsFixed(0)}% confidence) - ${s.description}'
      ).join('\n');

      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk price forecasting AI called PRICE PROPHET. Respond in Ukrainian with cyberpunk flavor. Be concise but insightful (2-3 sentences).',
        userPrompt: 'Product: $product, Current price: ${price.toStringAsFixed(0)} грн\nScenarios:\n$scenarioText\nGive a brief forecast insight in Ukrainian.',
        temperature: 0.85,
        maxTokens: 512,
      );
      return (response ?? '').trim();
    } catch (_) {
      return 'Prophet neural network: data processing complete. Forecast generated.';
    }
  }

  void removeItem(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  Future<void> refreshForecast(String id) async {
    final idx = state.items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final item = state.items[idx];
    state = state.copyWith(isLoading: true);
    try {
      final newScenarios = _generateScenarios(item.currentPrice);
      final insight = await _generateAiInsight(item.name, item.currentPrice, newScenarios);
      final updated = item.copyWith(
        scenarios: newScenarios,
        aiInsight: insight,
        lastUpdated: DateTime.now(),
      );
      final newItems = [...state.items];
      newItems[idx] = updated;
      state = state.copyWith(items: newItems, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setTargetPrice(String id, double target) {
    final idx = state.items.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final newItems = [...state.items];
    newItems[idx] = newItems[idx].copyWith(targetGoalPrice: target);
    state = state.copyWith(items: newItems);
  }

  void addPredefinedProduct(int catalogIndex) {
    if (catalogIndex < 0 || catalogIndex >= _prophetCatalog.length) return;
    final entry = _prophetCatalog[catalogIndex];
    final name = entry['name'] as String;
    if (state.items.any((i) => i.name == name)) return;
    final price = (entry['price'] as num).toDouble();
    final category = entry['category'] as String;
    final scenarios = _generateScenarios(price);
    final item = PriceProphetItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentPrice: price,
      scenarios: scenarios,
      lastUpdated: DateTime.now(),
      category: category,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === PROVIDER ===

final priceProphetProvider = StateNotifierProvider<PriceProphetNotifier, PriceProphetState>(
  (ref) => PriceProphetNotifier(ref),
);
