import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// === MODELS ===

enum MomentumPhase {
  growth,
  peak,
  stable,
  drop,
  stagnation,
}

class MomentumDataPoint {
  final DateTime date;
  final double price;
  final double momentum;

  const MomentumDataPoint({
    required this.date,
    required this.price,
    required this.momentum,
  });
}

class MomentumItem {
  final String id;
  final String name;
  final double currentPrice;
  final MomentumPhase phase;
  final double phaseConfidence;
  final double dropProbability;
  final double stagnationDays;
  final List<MomentumDataPoint> history;
  final double priceChange7d;
  final double priceChange30d;
  final String aiAnalysis;
  final DateTime lastUpdated;
  final String category;

  const MomentumItem({
    required this.id,
    required this.name,
    required this.currentPrice,
    required this.phase,
    required this.phaseConfidence,
    required this.dropProbability,
    required this.stagnationDays,
    this.history = const [],
    this.priceChange7d = 0,
    this.priceChange30d = 0,
    this.aiAnalysis = '',
    required this.lastUpdated,
    this.category = '',
  });

  MomentumItem copyWith({
    String? id,
    String? name,
    double? currentPrice,
    MomentumPhase? phase,
    double? phaseConfidence,
    double? dropProbability,
    double? stagnationDays,
    List<MomentumDataPoint>? history,
    double? priceChange7d,
    double? priceChange30d,
    String? aiAnalysis,
    DateTime? lastUpdated,
    String? category,
  }) {
    return MomentumItem(
      id: id ?? this.id,
      name: name ?? this.name,
      currentPrice: currentPrice ?? this.currentPrice,
      phase: phase ?? this.phase,
      phaseConfidence: phaseConfidence ?? this.phaseConfidence,
      dropProbability: dropProbability ?? this.dropProbability,
      stagnationDays: stagnationDays ?? this.stagnationDays,
      history: history ?? this.history,
      priceChange7d: priceChange7d ?? this.priceChange7d,
      priceChange30d: priceChange30d ?? this.priceChange30d,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      category: category ?? this.category,
    );
  }
}

class PriceMomentumState {
  final List<MomentumItem> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const PriceMomentumState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  PriceMomentumState copyWith({
    List<MomentumItem>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return PriceMomentumState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// === CATALOG ===

const _momentumCatalog = [
  {'name': 'PS5 Slim 1TB (Disc)', 'category': 'Gaming', 'price': 19999.0, 'phase': 'stable'},
  {'name': 'PS5 Slim Digital Edition', 'category': 'Gaming', 'price': 16999.0, 'phase': 'drop'},
  {'name': 'iPhone 16 Pro 256GB', 'category': 'Smartphones', 'price': 62999.0, 'phase': 'peak'},
  {'name': 'MacBook Air M3 13"', 'category': 'Laptops', 'price': 52999.0, 'phase': 'stable'},
  {'name': 'RTX 5070', 'category': 'Components', 'price': 28999.0, 'phase': 'growth'},
  {'name': 'Samsung Galaxy S25 Ultra', 'category': 'Smartphones', 'price': 54999.0, 'phase': 'drop'},
  {'name': 'Prologix GM2425HD 23.8"', 'category': 'Monitors', 'price': 5999.0, 'phase': 'stable'},
  {'name': 'ASRock CL25FFB 25"', 'category': 'Monitors', 'price': 6499.0, 'phase': 'stagnation'},
  {'name': 'Xiaomi G27i 27"', 'category': 'Monitors', 'price': 9499.0, 'phase': 'growth'},
  {'name': 'AirPods Pro 2', 'category': 'Audio', 'price': 9999.0, 'phase': 'growth'},
];

// === NOTIFIER ===

class PriceMomentumNotifier extends StateNotifier<PriceMomentumState> {
  final Ref _ref;

  PriceMomentumNotifier(this._ref) : super(const PriceMomentumState());

  List<Map<String, dynamic>> get predefinedCatalog => _momentumCatalog;

  Future<void> analyzeMomentum(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final env = _ref.read(envProvider);
      double currentPrice = 0;
      String categoryStr = '';

      final serpPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query price buy');
      if (serpPrices.isNotEmpty) {
        currentPrice = serpPrices.reduce((a, b) => a + b) / serpPrices.length;
      }

      final twelveData = await _fetchTwelveData(query, env.twelveDataApiKey);
      if (twelveData.isNotEmpty) {
        currentPrice = currentPrice == 0 ? twelveData.last : currentPrice;
      }

      final catalogMatch = _momentumCatalog.firstWhere(
        (item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()),
        orElse: () => <String, Object>{'name': '', 'category': 'Other', 'price': 0.0, 'phase': 'stable'},
      );

      if (currentPrice == 0 && catalogMatch.isNotEmpty) {
        currentPrice = (catalogMatch['price'] as num).toDouble();
      }
      if (catalogMatch.isNotEmpty) {
        categoryStr = catalogMatch['category'] as String;
      } else {
        categoryStr = _inferCategory(query);
      }

      if (currentPrice == 0) currentPrice = 999.0;

      final history = _generateHistory(currentPrice);
      final phase = _detectPhase(history, catalogMatch);
      final phaseConfidence = 0.6 + Random().nextDouble() * 0.3;
      final dropProbability = _calculateDropProbability(phase);
      final stagnationDays = _calculateStagnation(phase);
      final change7d = _calculateChange(history, 7);
      final change30d = _calculateChange(history, 30);
      final analysis = await _generateAiAnalysis(query, currentPrice, phase, dropProbability);

      final item = MomentumItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: query,
        currentPrice: double.parse(currentPrice.toStringAsFixed(2)),
        phase: phase,
        phaseConfidence: double.parse(phaseConfidence.toStringAsFixed(2)),
        dropProbability: double.parse(dropProbability.toStringAsFixed(2)),
        stagnationDays: stagnationDays,
        history: history,
        priceChange7d: double.parse(change7d.toStringAsFixed(2)),
        priceChange30d: double.parse(change30d.toStringAsFixed(2)),
        aiAnalysis: analysis,
        lastUpdated: DateTime.now(),
        category: categoryStr,
      );

      state = state.copyWith(
        items: [...state.items, item],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }



  Future<List<double>> _fetchTwelveData(String query, String apiKey) async {
    if (apiKey.isEmpty) return [];
    try {
      final url = Uri.parse(
        'https://api.twelvedata.com/time_series?symbol=AAPL&interval=1day&outputsize=30&apikey=$apiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final values = data['values'] as List? ?? [];
      final prices = <double>[];
      for (final v in values.reversed) {
        final close = v['close'];
        if (close != null) prices.add(double.parse(close.toString()));
      }
      return prices;
    } catch (_) {
      return [];
    }
  }

  List<MomentumDataPoint> _generateHistory(double currentPrice) {
    final rand = Random();
    final history = <MomentumDataPoint>[];
    final now = DateTime.now();
    double price = currentPrice * (1.05 + rand.nextDouble() * 0.15);

    for (int i = 90; i >= 0; i--) {
      final change = (rand.nextDouble() - 0.48) * currentPrice * 0.02;
      price = (price + change).clamp(currentPrice * 0.7, currentPrice * 1.2);
      final momentum = change.abs() > currentPrice * 0.005 ? change.sign.toDouble() : 0.0;
      history.add(MomentumDataPoint(
        date: now.subtract(Duration(days: i)),
        price: double.parse(price.toStringAsFixed(2)),
        momentum: momentum,
      ));
    }
    return history;
  }

  MomentumPhase _detectPhase(List<MomentumDataPoint> history, Map<String, dynamic> catalogMatch) {
    if (catalogMatch.isNotEmpty && catalogMatch['phase'] != null) {
      final phaseStr = catalogMatch['phase'] as String;
      switch (phaseStr) {
        case 'growth': return MomentumPhase.growth;
        case 'peak': return MomentumPhase.peak;
        case 'drop': return MomentumPhase.drop;
        case 'stagnation': return MomentumPhase.stagnation;
        default: return MomentumPhase.stable;
      }
    }

    if (history.length < 14) return MomentumPhase.stable;
    final recent = history.sublist(history.length - 7);
    final older = history.sublist(history.length - 14, history.length - 7);
    final recentAvg = recent.map((p) => p.price).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((p) => p.price).reduce((a, b) => a + b) / older.length;
    final change = (recentAvg - olderAvg) / olderAvg;

    if (change > 0.03) return MomentumPhase.growth;
    if (change > 0.01) return MomentumPhase.peak;
    if (change < -0.03) return MomentumPhase.drop;
    if (change.abs() < 0.005) return MomentumPhase.stagnation;
    return MomentumPhase.stable;
  }

  double _calculateDropProbability(MomentumPhase phase) {
    switch (phase) {
      case MomentumPhase.peak: return 0.70 + Random().nextDouble() * 0.20;
      case MomentumPhase.growth: return 0.20 + Random().nextDouble() * 0.15;
      case MomentumPhase.stable: return 0.35 + Random().nextDouble() * 0.15;
      case MomentumPhase.drop: return 0.80 + Random().nextDouble() * 0.15;
      case MomentumPhase.stagnation: return 0.50 + Random().nextDouble() * 0.20;
    }
  }

  double _calculateStagnation(MomentumPhase phase) {
    switch (phase) {
      case MomentumPhase.stagnation: return 14 + Random().nextDouble() * 30;
      case MomentumPhase.stable: return 5 + Random().nextDouble() * 10;
      case MomentumPhase.peak: return 3 + Random().nextDouble() * 7;
      default: return Random().nextDouble() * 5;
    }
  }

  double _calculateChange(List<MomentumDataPoint> history, int days) {
    if (history.length < days + 1) return 0;
    final current = history.last.price;
    final past = history[history.length - days - 1].price;
    return ((current - past) / past) * 100;
  }

  String _inferCategory(String query) {
    final q = query.toLowerCase();
    if (q.contains('ps5') || q.contains('xbox') || q.contains('switch') || q.contains('steam')) return 'Gaming';
    if (q.contains('iphone') || q.contains('samsung') || q.contains('pixel')) return 'Smartphones';
    if (q.contains('macbook') || q.contains('laptop')) return 'Laptops';
    if (q.contains('monitor') || q.contains('display')) return 'Monitors';
    if (q.contains('rtx') || q.contains('gpu')) return 'Components';
    return 'Other';
  }

  Future<String> _generateAiAnalysis(String product, double price, MomentumPhase phase, double dropProb) async {
    final phaseStr = phase.name;
    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk momentum analysis AI called MOMENTUM CORE. Respond in Ukrainian with cyberpunk flavor. Be concise (2-3 sentences). Analyze price momentum phase.',
        userPrompt: 'Product: $product, Price: ${price.toStringAsFixed(0)} грн, Phase: $phaseStr, Drop probability: ${(dropProb * 100).toStringAsFixed(0)}%. Analysis in Ukrainian?',
        temperature: 0.85,
        maxTokens: 512,
      );
      return (response ?? '').trim();
    } catch (_) {
      return 'Momentum Core: phase detection complete. Data stream processed.';
    }
  }

  void removeItem(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  void addPredefinedProduct(int catalogIndex) {
    if (catalogIndex < 0 || catalogIndex >= _momentumCatalog.length) return;
    final entry = _momentumCatalog[catalogIndex];
    final name = entry['name'] as String;
    if (state.items.any((i) => i.name == name)) return;
    final price = (entry['price'] as num).toDouble();
    final phaseStr = entry['phase'] as String;
    final phase = _phaseFromString(phaseStr);
    final history = _generateHistory(price);
    final dropProb = _calculateDropProbability(phase);
    final stag = _calculateStagnation(phase);
    final change7d = _calculateChange(history, 7);
    final change30d = _calculateChange(history, 30);

    final item = MomentumItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      currentPrice: price,
      phase: phase,
      phaseConfidence: 0.6 + Random().nextDouble() * 0.3,
      dropProbability: dropProb,
      stagnationDays: stag,
      history: history,
      priceChange7d: change7d,
      priceChange30d: change30d,
      lastUpdated: DateTime.now(),
      category: entry['category'] as String,
    );
    state = state.copyWith(items: [...state.items, item]);
  }

  MomentumPhase _phaseFromString(String s) {
    switch (s) {
      case 'growth': return MomentumPhase.growth;
      case 'peak': return MomentumPhase.peak;
      case 'drop': return MomentumPhase.drop;
      case 'stagnation': return MomentumPhase.stagnation;
      default: return MomentumPhase.stable;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === PROVIDER ===

final priceMomentumProvider = StateNotifierProvider<PriceMomentumNotifier, PriceMomentumState>(
  (ref) => PriceMomentumNotifier(ref),
);
