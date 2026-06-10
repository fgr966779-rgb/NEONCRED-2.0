import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../core/data/ukrainian_stores.dart';

// === MODELS ===

class PriceBattle {
  final String retailerA;
  final String retailerB;
  final double priceA;
  final double priceB;
  final String product;
  final DateTime detected;
  final double warIntensity;

  const PriceBattle({
    required this.retailerA,
    required this.retailerB,
    required this.priceA,
    required this.priceB,
    required this.product,
    required this.detected,
    required this.warIntensity,
  });
}

class PriceWarItem {
  final String id;
  final String productName;
  final double currentBestPrice;
  final double originalPrice;
  final double totalSavings;
  final String buyRecommendation;
  final List<PriceBattle> battles;
  final int warDay;
  final double warIntensity;
  final String aiCommentary;
  final DateTime lastUpdated;
  final String category;
  final bool isWarActive;

  const PriceWarItem({
    required this.id,
    required this.productName,
    required this.currentBestPrice,
    required this.originalPrice,
    required this.totalSavings,
    required this.buyRecommendation,
    this.battles = const [],
    required this.warDay,
    required this.warIntensity,
    this.aiCommentary = '',
    required this.lastUpdated,
    this.category = '',
    this.isWarActive = true,
  });

  PriceWarItem copyWith({
    String? id,
    String? productName,
    double? currentBestPrice,
    double? originalPrice,
    double? totalSavings,
    String? buyRecommendation,
    List<PriceBattle>? battles,
    int? warDay,
    double? warIntensity,
    String? aiCommentary,
    DateTime? lastUpdated,
    String? category,
    bool? isWarActive,
  }) {
    return PriceWarItem(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      currentBestPrice: currentBestPrice ?? this.currentBestPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      totalSavings: totalSavings ?? this.totalSavings,
      buyRecommendation: buyRecommendation ?? this.buyRecommendation,
      battles: battles ?? this.battles,
      warDay: warDay ?? this.warDay,
      warIntensity: warIntensity ?? this.warIntensity,
      aiCommentary: aiCommentary ?? this.aiCommentary,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      category: category ?? this.category,
      isWarActive: isWarActive ?? this.isWarActive,
    );
  }
}

class PriceWarState {
  final List<PriceWarItem> activeWars;
  final List<PriceWarItem> pastWars;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const PriceWarState({
    this.activeWars = const [],
    this.pastWars = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  PriceWarState copyWith({
    List<PriceWarItem>? activeWars,
    List<PriceWarItem>? pastWars,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return PriceWarState(
      activeWars: activeWars ?? this.activeWars,
      pastWars: pastWars ?? this.pastWars,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// === RETAILERS ===

const _retailers = ['Rozetka', 'Comfy', 'Allo', 'Citrus', 'MOYO', 'Eldorado', 'Foxtrot', 'Click', 'Itbox', 'Brain', 'Jabko', 'Elmir', 'Denika', 'Sota', 'MTA', 'Compx', 'KTC'];

// === CATALOG ===

const _warCatalog = [
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

class PriceWarNotifier extends StateNotifier<PriceWarState> {
  final Ref _ref;

  PriceWarNotifier(this._ref) : super(const PriceWarState());

  List<Map<String, dynamic>> get predefinedCatalog => _warCatalog;

  Future<void> scanForWars(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final env = _ref.read(envProvider);
      double originalPrice = 0;
      String category = '';

      final serpPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query ціна купити Україна');
      if (serpPrices.isNotEmpty) {
        originalPrice = serpPrices.reduce((a, b) => a > b ? a : b);
      }

      final catalogMatch = _warCatalog.firstWhere(
        (item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()),
        orElse: () => <String, Object>{'name': '', 'category': 'Other', 'price': 0.0},
      );

      if (originalPrice == 0 && catalogMatch.isNotEmpty) {
        originalPrice = (catalogMatch['price'] as num).toDouble();
      }
      if (catalogMatch.isNotEmpty) {
        category = catalogMatch['category'] as String;
      } else {
        category = _inferCategory(query);
      }

      if (originalPrice == 0) originalPrice = 9999.0;

      final battles = _detectBattles(query, originalPrice);
      final bestPrice = battles.isNotEmpty
        ? battles.map((b) => b.priceA < b.priceB ? b.priceA : b.priceB).reduce((a, b) => a < b ? a : b)
        : originalPrice * 0.92;
      final savings = ((1 - bestPrice / originalPrice) * 100);
      final intensity = _calculateWarIntensity(battles);
      final recommendation = _getBuyRecommendation(intensity, savings);
      final commentary = await _generateAiCommentary(query, originalPrice, bestPrice, battles);

      final item = PriceWarItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productName: query,
        currentBestPrice: double.parse(bestPrice.toStringAsFixed(2)),
        originalPrice: double.parse(originalPrice.toStringAsFixed(2)),
        totalSavings: double.parse(savings.toStringAsFixed(1)),
        buyRecommendation: recommendation,
        battles: battles,
        warDay: 1 + Random().nextInt(14),
        warIntensity: double.parse(intensity.toStringAsFixed(2)),
        aiCommentary: commentary,
        lastUpdated: DateTime.now(),
        category: category,
      );

      state = state.copyWith(
        activeWars: [...state.activeWars, item],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }



  List<PriceBattle> _detectBattles(String product, double basePrice) {
    final rand = Random();
    final battles = <PriceBattle>[];

    // Use real listings from Ukrainian stores if available
    final realListings = getListingsForProduct(product);
    if (realListings.length >= 2) {
      final sorted = List<ProductListing>.from(realListings)
        ..sort((a, b) => a.priceUAH.compareTo(b.priceUAH));
      for (int i = 0; i < sorted.length - 1 && battles.length < 5; i += 2) {
        battles.add(PriceBattle(
          retailerA: getStoreNameById(sorted[i].storeId),
          retailerB: getStoreNameById(sorted[i + 1].storeId),
          priceA: sorted[i].priceUAH,
          priceB: sorted[i + 1].priceUAH,
          product: product,
          detected: DateTime.now().subtract(Duration(hours: rand.nextInt(72))),
          warIntensity: (sorted[i].priceUAH - sorted[i + 1].priceUAH).abs() / basePrice,
        ));
      }
      return battles..sort((a, b) => a.priceA.compareTo(b.priceA));
    }

    // Fallback: generate from store list
    final numBattles = 2 + rand.nextInt(3);
    final usedRetailers = <int>{};
    for (int i = 0; i < numBattles; i++) {
      int idxA, idxB;
      do { idxA = rand.nextInt(_retailers.length); } while (usedRetailers.contains(idxA) && usedRetailers.length < _retailers.length);
      usedRetailers.add(idxA);
      do { idxB = rand.nextInt(_retailers.length); } while (idxB == idxA || (usedRetailers.contains(idxB) && usedRetailers.length < _retailers.length));
      usedRetailers.add(idxB);

      final discountA = 0.05 + rand.nextDouble() * 0.15;
      final discountB = 0.03 + rand.nextDouble() * 0.12;

      battles.add(PriceBattle(
        retailerA: _retailers[idxA],
        retailerB: _retailers[idxB],
        priceA: double.parse((basePrice * (1 - discountA)).toStringAsFixed(0)),
        priceB: double.parse((basePrice * (1 - discountB)).toStringAsFixed(0)),
        product: product,
        detected: DateTime.now().subtract(Duration(hours: rand.nextInt(72))),
        warIntensity: discountA.abs() + discountB.abs(),
      ));
    }

    return battles..sort((a, b) => a.priceA.compareTo(b.priceA));
  }

  double _calculateWarIntensity(List<PriceBattle> battles) {
    if (battles.isEmpty) return 0.3;
    return battles.map((b) => b.warIntensity).reduce((a, b) => a + b) / battles.length;
  }

  String _getBuyRecommendation(double intensity, double savings) {
    if (intensity > 0.3 && savings > 15) return 'buy_now';
    if (intensity > 0.2 && savings > 10) return 'watch_closely';
    if (savings > 8) return 'wait_for_escalation';
    return 'no_war_detected';
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

  Future<String> _generateAiCommentary(String product, double original, double best, List<PriceBattle> battles) async {
    final battleText = battles.map((b) =>
      '${b.retailerA} vs ${b.retailerB}: ${b.priceA.toStringAsFixed(0)} грн vs ${b.priceB.toStringAsFixed(0)} грн'
    ).join('\n');

    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk war correspondent AI called PRICE WAR SENTINEL. Respond in Ukrainian with cyberpunk military flavor. Be dramatic and concise (2-3 sentences). Cover price wars like battle reports.',
        userPrompt: 'Product: $product, Original: ${original.toStringAsFixed(0)} грн, Best: ${best.toStringAsFixed(0)} грн\nBattles:\n$battleText\nWar report in Ukrainian?',
        temperature: 0.85,
        maxTokens: 512,
      );
      return (response ?? '').trim();
    } catch (_) {
      return 'Sentinel: price war detected on multiple fronts. Monitoring continues.';
    }
  }

  void removeWar(String id) {
    state = state.copyWith(
      activeWars: state.activeWars.where((w) => w.id != id).toList(),
    );
  }

  void archiveWar(String id) {
    final war = state.activeWars.firstWhere((w) => w.id == id);
    final archived = war.copyWith(isWarActive: false);
    state = state.copyWith(
      activeWars: state.activeWars.where((w) => w.id != id).toList(),
      pastWars: [...state.pastWars, archived],
    );
  }

  void addPredefinedProduct(int catalogIndex) {
    if (catalogIndex < 0 || catalogIndex >= _warCatalog.length) return;
    final entry = _warCatalog[catalogIndex];
    final name = entry['name'] as String;
    if (state.activeWars.any((w) => w.productName == name)) return;
    final price = (entry['price'] as num).toDouble();
    final battles = _detectBattles(name, price);
    final bestPrice = battles.map((b) => b.priceA < b.priceB ? b.priceA : b.priceB).reduce((a, b) => a < b ? a : b);
    final savings = ((1 - bestPrice / price) * 100);
    final intensity = _calculateWarIntensity(battles);

    final item = PriceWarItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: name,
      currentBestPrice: double.parse(bestPrice.toStringAsFixed(2)),
      originalPrice: price,
      totalSavings: double.parse(savings.toStringAsFixed(1)),
      buyRecommendation: _getBuyRecommendation(intensity, savings),
      battles: battles,
      warDay: 1 + Random().nextInt(14),
      warIntensity: intensity,
      lastUpdated: DateTime.now(),
      category: entry['category'] as String,
    );
    state = state.copyWith(activeWars: [...state.activeWars, item]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === PROVIDER ===

final priceWarProvider = StateNotifierProvider<PriceWarNotifier, PriceWarState>(
  (ref) => PriceWarNotifier(ref),
);
