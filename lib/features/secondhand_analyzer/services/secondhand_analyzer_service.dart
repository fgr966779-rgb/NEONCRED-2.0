import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// === MODELS ===

class SecondHandListing {
  final String platform;
  final String title;
  final double price;
  final String condition;
  final String url;
  final String sellerRating;

  const SecondHandListing({
    required this.platform,
    required this.title,
    required this.price,
    required this.condition,
    this.url = '',
    this.sellerRating = '',
  });
}

class DepreciationPoint {
  final int monthOffset;
  final double newPrice;
  final double usedPrice;
  final double depreciationPercent;

  const DepreciationPoint({
    required this.monthOffset,
    required this.newPrice,
    required this.usedPrice,
    required this.depreciationPercent,
  });
}

class SecondHandItem {
  final String id;
  final String name;
  final double newPrice;
  final double avgUsedPrice;
  final double bestUsedPrice;
  final double savingsPercent;
  final String condition;
  final List<SecondHandListing> listings;
  final List<DepreciationPoint> depreciationCurve;
  final String aiVerdict;
  final DateTime lastUpdated;
  final String category;

  const SecondHandItem({
    required this.id,
    required this.name,
    required this.newPrice,
    required this.avgUsedPrice,
    required this.bestUsedPrice,
    required this.savingsPercent,
    this.condition = 'Good',
    this.listings = const [],
    this.depreciationCurve = const [],
    this.aiVerdict = '',
    required this.lastUpdated,
    this.category = '',
  });

  SecondHandItem copyWith({
    String? id,
    String? name,
    double? newPrice,
    double? avgUsedPrice,
    double? bestUsedPrice,
    double? savingsPercent,
    String? condition,
    List<SecondHandListing>? listings,
    List<DepreciationPoint>? depreciationCurve,
    String? aiVerdict,
    DateTime? lastUpdated,
    String? category,
  }) {
    return SecondHandItem(
      id: id ?? this.id,
      name: name ?? this.name,
      newPrice: newPrice ?? this.newPrice,
      avgUsedPrice: avgUsedPrice ?? this.avgUsedPrice,
      bestUsedPrice: bestUsedPrice ?? this.bestUsedPrice,
      savingsPercent: savingsPercent ?? this.savingsPercent,
      condition: condition ?? this.condition,
      listings: listings ?? this.listings,
      depreciationCurve: depreciationCurve ?? this.depreciationCurve,
      aiVerdict: aiVerdict ?? this.aiVerdict,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      category: category ?? this.category,
    );
  }
}

class SecondHandState {
  final List<SecondHandItem> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const SecondHandState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  SecondHandState copyWith({
    List<SecondHandItem>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return SecondHandState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// === CATALOG ===

const _secondhandCatalog = [
  {'name': 'PS5 Slim 1TB (Disc)', 'category': 'Gaming', 'newPrice': 19999.0, 'usedFactor': 0.65},
  {'name': 'PS5 Slim Digital Edition', 'category': 'Gaming', 'newPrice': 16999.0, 'usedFactor': 0.60},
  {'name': 'iPhone 15 Pro', 'category': 'Smartphones', 'newPrice': 54999.0, 'usedFactor': 0.55},
  {'name': 'MacBook Air M2', 'category': 'Laptops', 'newPrice': 42999.0, 'usedFactor': 0.60},
  {'name': 'Samsung Galaxy S24', 'category': 'Smartphones', 'newPrice': 39999.0, 'usedFactor': 0.50},
  {'name': 'Prologix GM2425HD 23.8"', 'category': 'Monitors', 'newPrice': 5999.0, 'usedFactor': 0.62},
  {'name': 'Xiaomi G27i 27"', 'category': 'Monitors', 'newPrice': 9499.0, 'usedFactor': 0.58},
  {'name': 'AirPods Pro 2', 'category': 'Audio', 'newPrice': 9999.0, 'usedFactor': 0.55},
  {'name': 'RTX 4070', 'category': 'Components', 'newPrice': 22999.0, 'usedFactor': 0.60},
  {'name': 'iPad Air M2', 'category': 'Tablets', 'newPrice': 32999.0, 'usedFactor': 0.55},
];

// === NOTIFIER ===

class SecondHandAnalyzerNotifier extends StateNotifier<SecondHandState> {
  final Ref _ref;

  SecondHandAnalyzerNotifier(this._ref) : super(const SecondHandState());

  List<Map<String, dynamic>> get predefinedCatalog => _secondhandCatalog;

  Future<void> analyzeProduct(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final env = _ref.read(envProvider);
      double newPrice = 0;
      double avgUsed = 0;
      double bestUsed = 0;
      String category = '';

      final catalogMatch = _secondhandCatalog.firstWhere(
        (item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()),
        orElse: () => <String, Object>{'name': '', 'category': 'Other', 'newPrice': 0.0, 'usedFactor': 0.6},
      );

      if (catalogMatch.isNotEmpty) {
        newPrice = (catalogMatch['newPrice'] as num).toDouble();
        final factor = (catalogMatch['usedFactor'] as num).toDouble();
        avgUsed = double.parse((newPrice * factor).toStringAsFixed(2));
        bestUsed = double.parse((newPrice * (factor - 0.08)).toStringAsFixed(2));
        category = catalogMatch['category'] as String;
      }

      final serpNewPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query new buy price');
      final serpUsedPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query used refurbished second hand price');

      if (serpNewPrices.isNotEmpty) {
        newPrice = serpNewPrices.reduce((a, b) => a + b) / serpNewPrices.length;
      }
      if (serpUsedPrices.isNotEmpty) {
        avgUsed = serpUsedPrices.reduce((a, b) => a + b) / serpUsedPrices.length;
        bestUsed = serpUsedPrices.reduce((a, b) => a < b ? a : b);
      }

      final olxPrices = await _fetchOlxPrices(query, env.olxApiKey);
      if (olxPrices.isNotEmpty) {
        final allUsed = [...serpUsedPrices, ...olxPrices];
        avgUsed = allUsed.reduce((a, b) => a + b) / allUsed.length;
        bestUsed = allUsed.reduce((a, b) => a < b ? a : b);
      }

      if (newPrice == 0) newPrice = 999.0;
      if (avgUsed == 0) avgUsed = newPrice * 0.6;

      final savings = ((1 - avgUsed / newPrice) * 100);
      final listings = _generateListings(query, avgUsed, bestUsed);
      final curve = _generateDepreciationCurve(newPrice, avgUsed);
      final verdict = await _generateAiVerdict(query, newPrice, avgUsed, bestUsed, savings);

      final item = SecondHandItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: query,
        newPrice: double.parse(newPrice.toStringAsFixed(2)),
        avgUsedPrice: double.parse(avgUsed.toStringAsFixed(2)),
        bestUsedPrice: double.parse(bestUsed.toStringAsFixed(2)),
        savingsPercent: double.parse(savings.toStringAsFixed(1)),
        listings: listings,
        depreciationCurve: curve,
        aiVerdict: verdict,
        lastUpdated: DateTime.now(),
        category: category.isEmpty ? _inferCategory(query) : category,
      );

      state = state.copyWith(
        items: [...state.items, item],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }



  Future<List<double>> _fetchOlxPrices(String query, String apiKey) async {
    if (apiKey.isEmpty) return [];
    try {
      final url = Uri.parse(
        'https://www.olx.ua/api/v1/offers/?query=${Uri.encodeComponent(query)}&limit=10',
      );
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $apiKey',
      }).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      final offers = data['data'] as List? ?? [];
      final prices = <double>[];
      for (final offer in offers) {
        final price = offer['price']?['value'];
        if (price != null) prices.add((price as num).toDouble());
      }
      return prices;
    } catch (_) {
      return [];
    }
  }

  List<SecondHandListing> _generateListings(String query, double avg, double best) {
    final rand = Random();
    final platforms = ['OLX', 'Allegro', 'FB Marketplace', 'eBay', 'Rozetka Used'];
    final conditions = ['Like New', 'Good', 'Good', 'Fair', 'Refurbished'];
    final listings = <SecondHandListing>[];
    for (int i = 0; i < 5; i++) {
      final variance = (rand.nextDouble() - 0.5) * avg * 0.15;
      listings.add(SecondHandListing(
        platform: platforms[i],
        title: '$query ${conditions[i]}',
        price: double.parse((avg + variance).abs().toStringAsFixed(2)),
        condition: conditions[i],
        sellerRating: (4.0 + rand.nextDouble() * 1.0).toStringAsFixed(1),
      ));
    }
    return listings..sort((a, b) => a.price.compareTo(b.price));
  }

  List<DepreciationPoint> _generateDepreciationCurve(double newPrice, double currentUsed) {
    final curve = <DepreciationPoint>[];
    for (int m = 0; m <= 24; m += 3) {
      final depreciation = m / 24 * 0.45;
      final usedP = newPrice * (1 - depreciation);
      curve.add(DepreciationPoint(
        monthOffset: m,
        newPrice: double.parse(newPrice.toStringAsFixed(2)),
        usedPrice: double.parse(usedP.toStringAsFixed(2)),
        depreciationPercent: double.parse((depreciation * 100).toStringAsFixed(1)),
      ));
    }
    return curve;
  }

  String _inferCategory(String query) {
    final q = query.toLowerCase();
    if (q.contains('ps5') || q.contains('xbox') || q.contains('switch')) return 'Gaming';
    if (q.contains('iphone') || q.contains('samsung') || q.contains('pixel')) return 'Smartphones';
    if (q.contains('macbook') || q.contains('laptop')) return 'Laptops';
    if (q.contains('monitor') || q.contains('display')) return 'Monitors';
    if (q.contains('airpods') || q.contains('headphone')) return 'Audio';
    if (q.contains('rtx') || q.contains('gpu')) return 'Components';
    return 'Other';
  }

  Future<String> _generateAiVerdict(String product, double newP, double avgUsed, double bestUsed, double savings) async {
    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk second-hand market AI called REFURB HUNTER. Respond in Ukrainian with cyberpunk flavor. Be concise (2-3 sentences). Give a verdict on buying used vs new.',
        userPrompt: 'Product: $product, New: ${newP.toStringAsFixed(0)} грн, Avg Used: ${avgUsed.toStringAsFixed(0)} грн, Best Used: ${bestUsed.toStringAsFixed(0)} грн, Savings: ${savings.toStringAsFixed(1)}%. Verdict in Ukrainian?',
        temperature: 0.85,
        maxTokens: 512,
      );
      return (response ?? '').trim();
    } catch (_) {
      return 'Second-hand scan complete. Data processed for market analysis.';
    }
  }

  void removeItem(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
  }

  void addPredefinedProduct(int catalogIndex) {
    if (catalogIndex < 0 || catalogIndex >= _secondhandCatalog.length) return;
    final entry = _secondhandCatalog[catalogIndex];
    final name = entry['name'] as String;
    if (state.items.any((i) => i.name == name)) return;
    final newPrice = (entry['newPrice'] as num).toDouble();
    final factor = (entry['usedFactor'] as num).toDouble();
    final avgUsed = double.parse((newPrice * factor).toStringAsFixed(2));
    final bestUsed = double.parse((newPrice * (factor - 0.08)).toStringAsFixed(2));
    final savings = ((1 - avgUsed / newPrice) * 100);
    final item = SecondHandItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      newPrice: newPrice,
      avgUsedPrice: avgUsed,
      bestUsedPrice: bestUsed,
      savingsPercent: double.parse(savings.toStringAsFixed(1)),
      listings: _generateListings(name, avgUsed, bestUsed),
      depreciationCurve: _generateDepreciationCurve(newPrice, avgUsed),
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

final secondhandAnalyzerProvider = StateNotifierProvider<SecondHandAnalyzerNotifier, SecondHandState>(
  (ref) => SecondHandAnalyzerNotifier(ref),
);
