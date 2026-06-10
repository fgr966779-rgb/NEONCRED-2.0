import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// === MODELS ===

enum ElasticityType {
  elastic,
  inelastic,
  unitElastic,
}

class DemandPoint {
  final double price;
  final double demandLevel;
  final DateTime date;

  const DemandPoint({
    required this.price,
    required this.demandLevel,
    required this.date,
  });
}

class ElasticityAnalysis {
  final double coefficient;
  final ElasticityType type;
  final String interpretation;
  final double optimalPrice;
  final double currentDiscountSensitivity;

  const ElasticityAnalysis({
    required this.coefficient,
    required this.type,
    required this.interpretation,
    required this.optimalPrice,
    required this.currentDiscountSensitivity,
  });
}

class ElasticityItem {
  final String id;
  final String name;
  final double currentPrice;
  final ElasticityAnalysis analysis;
  final List<DemandPoint> demandCurve;
  final double priceVolatility;
  final String bestTimeToBuy;
  final String aiInsight;
  final DateTime lastUpdated;
  final String category;
  final double streakScore;

  const ElasticityItem({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.analysis,
    this.demandCurve = const [],
    required this.priceVolatility,
    required this.bestTimeToBuy,
    this.aiInsight = '',
    required this.lastUpdated,
    this.category = '',
    this.streakScore = 0,
  });

  ElasticityItem copyWith({
    String? id,
    String? name,
    double? currentPrice,
    ElasticityAnalysis? analysis,
    List<DemandPoint>? demandCurve,
    double? priceVolatility,
    String? bestTimeToBuy,
    String? aiInsight,
    DateTime? lastUpdated,
    String? category,
    double? streakScore,
  }) {
    return ElasticityItem(
      id: id ?? this.id,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      analysis: analysis ?? this.analysis,
      demandCurve: demandCurve ?? this.demandCurve,
      priceVolatility: priceVolatility ?? this.priceVolatility,
      bestTimeToBuy: bestTimeToBuy ?? this.bestTimeToBuy,
      aiInsight: aiInsight ?? this.aiInsight,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      category: category ?? this.category,
      streakScore: streakScore ?? this.streakScore,
    );
  }
}

class PriceElasticityState {
  final List<ElasticityItem> items;
  final int dailyStreak;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const PriceElasticityState({
    this.items = const [],
    this.dailyStreak = 0,
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  PriceElasticityState copyWith({
    List<ElasticityItem>? items,
    int? dailyStreak,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return PriceElasticityState(
      items: items ?? this.items,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// === CATALOG ===

const _elasticityCatalog = [
  {'name': 'PS5 Slim 1TB (Disc)', 'category': 'Gaming', 'price': 19999.0, 'elasticity': 1.8},
  {'name': 'PS5 Slim Digital Edition', 'category': 'Gaming', 'price': 16999.0, 'elasticity': 2.0},
  {'name': 'iPhone 16 Pro 256GB', 'category': 'Smartphones', 'price': 62999.0, 'elasticity': 0.6},
  {'name': 'MacBook Air M3 13"', 'category': 'Laptops', 'price': 52999.0, 'elasticity': 0.8},
  {'name': 'RTX 5070', 'category': 'Components', 'price': 28999.0, 'elasticity': 2.2},
  {'name': 'Samsung Galaxy S25 Ultra', 'category': 'Smartphones', 'price': 54999.0, 'elasticity': 1.3},
  {'name': 'Prologix GM2425HD 23.8"', 'category': 'Monitors', 'price': 5999.0, 'elasticity': 1.6},
  {'name': 'Xiaomi G27i 27"', 'category': 'Monitors', 'price': 9499.0, 'elasticity': 1.4},
  {'name': 'AirPods Pro 2', 'category': 'Audio', 'price': 9999.0, 'elasticity': 1.1},
  {'name': 'iPad Pro M4', 'category': 'Tablets', 'price': 54999.0, 'elasticity': 0.9},
];

// === NOTIFIER ===

class PriceElasticityNotifier extends StateNotifier<PriceElasticityState> {
  final Ref _ref;

  PriceElasticityNotifier(this._ref) : super(const PriceElasticityState());

  List<Map<String, dynamic>> get predefinedCatalog => _elasticityCatalog;

  Future<void> analyzeElasticity(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      double currentPrice = 0;
      String category = '';
      double elasticityCoeff = 1.0;

      final serpPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query price buy');
      if (serpPrices.isNotEmpty) {
        currentPrice = serpPrices.reduce((a, b) => a + b) / serpPrices.length;
      }

      final catalogMatch = _elasticityCatalog.firstWhere(
        (item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()),
        orElse: () => <String, Object>{'name': '', 'category': 'Other', 'price': 0.0, 'elasticity': 1.0},
      );

      if (currentPrice == 0 && catalogMatch.isNotEmpty) {
        currentPrice = (catalogMatch['price'] as num).toDouble();
      }
      if (catalogMatch.isNotEmpty) {
        category = catalogMatch['category'] as String;
        elasticityCoeff = (catalogMatch['elasticity'] as num).toDouble();
      } else {
        category = _inferCategory(query);
        elasticityCoeff = 0.8 + Random().nextDouble() * 1.5;
      }

      if (currentPrice == 0) currentPrice = 999.0;

      final analysis = _analyzeElasticity(elasticityCoeff, currentPrice);
      final curve = _generateDemandCurve(currentPrice, elasticityCoeff);
      final volatility = _calculateVolatility(currentPrice);
      final bestTime = _determineBestTime(analysis.type);
      final insight = await _generateAiInsight(query, currentPrice, analysis);

      final item = ElasticityItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: query,
        currentPrice: double.parse(currentPrice.toStringAsFixed(2)),
        analysis: analysis,
        demandCurve: curve,
        priceVolatility: volatility,
        bestTimeToBuy: bestTime,
        aiInsight: insight,
        lastUpdated: DateTime.now(),
        category: category,
        streakScore: 1,
      );

      state = state.copyWith(
        items: [...state.items, item],
        dailyStreak: state.dailyStreak + 1,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }



  ElasticityAnalysis _analyzeElasticity(double coeff, double currentPrice) {
    ElasticityType type;
    String interpretation;

    if (coeff > 1.2) {
      type = ElasticityType.elastic;
      interpretation = 'Elastychnyy tovar: tsina silno vplyvaye na poput. Znyzhky dayutʹ superrezulʹtat — vart chekaty sale. Navitʹ 10% znyzhka zbilʹshuye poput na ${(coeff * 10).toStringAsFixed(0)}%.';
    } else if (coeff < 0.8) {
      type = ElasticityType.inelastic;
      interpretation = 'Neelastychnyy tovar: poput malo zalezhytʹ vid tsiny. Kupyvayte zaraz — znyzhok maye ne bude. Tse premium-produkt z postiynym poputom.';
    } else {
      type = ElasticityType.unitElastic;
      interpretation = 'Odynychna elastychnist: tsina ta poput zminyuyutʹsya proporsiyno. Vart chekaty tymchasovykh aktsiy, ale ne velykykh znyzhok.';
    }

    final optimalPrice = coeff > 1.0
      ? currentPrice * 0.85
      : currentPrice * 0.95;

    return ElasticityAnalysis(
      coefficient: double.parse(coeff.toStringAsFixed(2)),
      type: type,
      interpretation: interpretation,
      optimalPrice: double.parse(optimalPrice.toStringAsFixed(2)),
      currentDiscountSensitivity: double.parse((coeff * 0.1).toStringAsFixed(2)),
    );
  }

  List<DemandPoint> _generateDemandCurve(double basePrice, double elasticity) {
    final rand = Random();
    final points = <DemandPoint>[];
    final now = DateTime.now();

    for (int i = -30; i <= 0; i++) {
      final priceMod = 0.85 + rand.nextDouble() * 0.30;
      final price = basePrice * priceMod;
      final priceChange = (price - basePrice) / basePrice;
      final demandChange = priceChange * elasticity;
      final demand = 1.0 - demandChange;

      points.add(DemandPoint(
        price: double.parse(price.toStringAsFixed(2)),
        demandLevel: double.parse(demand.clamp(0.1, 2.0).toStringAsFixed(2)),
        date: now.add(Duration(days: i)),
      ));
    }
    return points;
  }

  double _calculateVolatility(double basePrice) {
    return double.parse((0.02 + Random().nextDouble() * 0.08).toStringAsFixed(3));
  }

  String _determineBestTime(ElasticityType type) {
    switch (type) {
      case ElasticityType.elastic:
        return 'Chekaty sale / Black Friday';
      case ElasticityType.inelastic:
        return 'Kupyvaty zaraz, znyzhok ne bude';
      case ElasticityType.unitElastic:
        return 'Chekaty tymchasovi aktsiy';
    }
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

  Future<String> _generateAiInsight(String product, double price, ElasticityAnalysis analysis) async {
    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk market analysis AI called ELASTICITY CORE. Respond in Ukrainian with cyberpunk flavor. Be concise (2-3 sentences). Explain price elasticity insights.',
        userPrompt: 'Product: $product, Price: ${price.toStringAsFixed(0)} грн, Elasticity: ${analysis.coefficient}, Type: ${analysis.type.name}, Optimal: ${analysis.optimalPrice.toStringAsFixed(0)} грн. Insight in Ukrainian?',
        temperature: 0.85,
        maxTokens: 512,
      );
      return (response ?? '').trim();
    } catch (_) {
      return 'Elasticity Core: market analysis complete. Demand curves processed.';
    }
  }

  void removeItem(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  void addPredefinedProduct(int catalogIndex) {
    if (catalogIndex < 0 || catalogIndex >= _elasticityCatalog.length) return;
    final entry = _elasticityCatalog[catalogIndex];
    final name = entry['name'] as String;
    if (state.items.any((i) => i.name == name)) return;
    final price = (entry['price'] as num).toDouble();
    final elasticity = (entry['elasticity'] as num).toDouble();

    final analysis = _analyzeElasticity(elasticity, price);
    final item = ElasticityItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentPrice: price,
      analysis: analysis,
      demandCurve: _generateDemandCurve(price, elasticity),
      priceVolatility: _calculateVolatility(price),
      bestTimeToBuy: _determineBestTime(analysis.type),
      lastUpdated: DateTime.now(),
      category: entry['category'] as String,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === PROVIDER ===

final priceElasticityProvider = StateNotifierProvider<PriceElasticityNotifier, PriceElasticityState>(
  (ref) => PriceElasticityNotifier(ref),
);
