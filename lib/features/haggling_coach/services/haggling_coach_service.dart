import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/data/ukrainian_stores.dart';
import '../../../core/utils/open_router_service.dart';

// === MODELS ===

class CompetitorPrice {
  final String store;
  final double price;
  final String url;
  final DateTime fetched;

  const CompetitorPrice({
    required this.store,
    required this.price,
    this.url = '',
    required this.fetched,
  });
}

class HagglingScript {
  final String step;
  final String dialogue;
  final String tips;

  const HagglingScript({
    required this.step,
    required this.dialogue,
    required this.tips,
  });
}

class HagglingSession {
  final String id;
  final String productName;
  final double storePrice;
  final double targetPrice;
  final double bestCompetitorPrice;
  final List<CompetitorPrice> competitorPrices;
  final List<HagglingScript> script;
  final double savingsPotential;
  final String successRate;
  final String aiCoachTip;
  final DateTime lastUpdated;
  final String category;
  final String status;

  const HagglingSession({
    required this.id,
    required this.productName,
    required this.storePrice,
    required this.targetPrice,
    required this.bestCompetitorPrice,
    this.competitorPrices = const [],
    this.script = const [],
    required this.savingsPotential,
    this.successRate = '',
    this.aiCoachTip = '',
    required this.lastUpdated,
    this.category = '',
    this.status = 'ready',
  });

  HagglingSession copyWith({
    String? id,
    String? productName,
    double? storePrice,
    double? targetPrice,
    double? bestCompetitorPrice,
    List<CompetitorPrice>? competitorPrices,
    List<HagglingScript>? script,
    double? savingsPotential,
    String? successRate,
    String? aiCoachTip,
    DateTime? lastUpdated,
    String? category,
    String? status,
  }) {
    return HagglingSession(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      storePrice: storePrice ?? this.storePrice,
      targetPrice: targetPrice ?? this.targetPrice,
      bestCompetitorPrice: bestCompetitorPrice ?? this.bestCompetitorPrice,
      competitorPrices: competitorPrices ?? this.competitorPrices,
      script: script ?? this.script,
      savingsPotential: savingsPotential ?? this.savingsPotential,
      successRate: successRate ?? this.successRate,
      aiCoachTip: aiCoachTip ?? this.aiCoachTip,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }
}

class HagglingState {
  final List<HagglingSession> sessions;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const HagglingState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  HagglingState copyWith({
    List<HagglingSession>? sessions,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return HagglingState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// === CATALOG (UAH prices) ===

const _hagglingCatalog = [
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

class HagglingCoachNotifier extends StateNotifier<HagglingState> {
  final Ref _ref;

  HagglingCoachNotifier(this._ref) : super(const HagglingState());

  List<Map<String, dynamic>> get predefinedCatalog => _hagglingCatalog;

  Future<void> prepareHaggling(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final env = _ref.read(envProvider);
      double storePrice = 0;
      String category = '';

      // Try to find real listings from Ukrainian stores
      final realListings = getListingsForProduct(query);
      if (realListings.isNotEmpty) {
        // Use the highest price as the "store price" (worst case for buyer)
        realListings.sort((a, b) => b.priceUAH.compareTo(a.priceUAH));
        storePrice = realListings.first.priceUAH;
        category = realListings.first.category;
      }

      // Also try SerpAPI for live prices
      final serpPrices = await _ref.read(serpApiServiceProvider).fetchAllPrices('$query ціна купити Україна');
      if (serpPrices.isNotEmpty && storePrice == 0) {
        storePrice = serpPrices.reduce((a, b) => a > b ? a : b);
      }

      // Check catalog fallback
      final catalogMatch = _hagglingCatalog.firstWhere(
        (item) => item['name'].toString().toLowerCase().contains(query.toLowerCase()) ||
            query.toLowerCase().contains(item['name'].toString().toLowerCase()),
        orElse: () => <String, Object>{'name': '', 'category': 'Other', 'price': 0.0},
      );

      if (storePrice == 0 && catalogMatch.isNotEmpty) {
        storePrice = (catalogMatch['price'] as num).toDouble();
      }
      if (catalogMatch.isNotEmpty && category.isEmpty) {
        category = catalogMatch['category'] as String;
      }
      if (category.isEmpty) {
        category = _inferCategory(query);
      }

      if (storePrice == 0) storePrice = 9999.0;

      final competitors = _generateCompetitors(query, storePrice);
      final bestCompetitor = competitors.isEmpty
          ? storePrice * 0.9
          : competitors.map((c) => c.price).reduce((a, b) => a < b ? a : b);
      final targetPrice = double.parse((bestCompetitor * 0.95).toStringAsFixed(0));
      final savings = ((1 - targetPrice / storePrice) * 100);
      final script = await _generateScript(query, storePrice, bestCompetitor, competitors);
      final coachTip = await _generateCoachTip(query, storePrice, targetPrice, savings);

      final session = HagglingSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productName: query,
        storePrice: double.parse(storePrice.toStringAsFixed(0)),
        targetPrice: targetPrice,
        bestCompetitorPrice: double.parse(bestCompetitor.toStringAsFixed(0)),
        competitorPrices: competitors,
        script: script,
        savingsPotential: double.parse(savings.toStringAsFixed(1)),
        successRate: _estimateSuccessRate(savings),
        aiCoachTip: coachTip,
        lastUpdated: DateTime.now(),
        category: category,
      );

      state = state.copyWith(
        sessions: [...state.sessions, session],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }



  List<CompetitorPrice> _generateCompetitors(String product, double basePrice) {
    final rand = Random();
    final competitors = <CompetitorPrice>[];

    // Use real listings if available
    final realListings = getListingsForProduct(product);
    if (realListings.isNotEmpty) {
      for (final listing in realListings.take(7)) {
        competitors.add(CompetitorPrice(
          store: getStoreNameById(listing.storeId),
          price: listing.priceUAH,
          url: listing.url,
          fetched: DateTime.now(),
        ));
      }
      // Sort by price ascending
      competitors.sort((a, b) => a.price.compareTo(b.price));
      return competitors;
    }

    // Fallback: generate from store database
    final storeNames = getRandomStoreNames(6);
    for (int i = 0; i < storeNames.length; i++) {
      final discount = 0.03 + rand.nextDouble() * 0.12;
      competitors.add(CompetitorPrice(
        store: storeNames[i],
        price: double.parse((basePrice * (1 - discount)).toStringAsFixed(0)),
        fetched: DateTime.now(),
      ));
    }
    return competitors..sort((a, b) => a.price.compareTo(b.price));
  }

  Future<List<HagglingScript>> _generateScript(String product, double storePrice, double bestComp, List<CompetitorPrice> competitors) async {
    final compText = competitors.take(3).map((c) => '${c.store}: ${c.price.toStringAsFixed(0)} грн').join(', ');

    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk negotiation AI called HAGGLE PROTOCOL. Generate a 4-step negotiation script in Ukrainian with cyberpunk flavor. Each step should have: step name, dialogue (what to say), and a tip. Format as JSON array: [{"step":"...","dialogue":"...","tips":"..."}]',
        userPrompt: 'Product: $product, Store price: ${storePrice.toStringAsFixed(0)} грн, Best competitor: ${bestComp.toStringAsFixed(0)} грн, Other prices: $compText. Generate 4-step negotiation script in Ukrainian.',
        temperature: 0.9,
        maxTokens: 800,
      );

      if (response == null) throw Exception('AI unavailable');
      final cleaned = response.trim();
      final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(cleaned);
      if (jsonMatch != null) {
        final List<dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
        return parsed.map((s) => HagglingScript(
          step: s['step']?.toString() ?? 'Step',
          dialogue: s['dialogue']?.toString() ?? '',
          tips: s['tips']?.toString() ?? '',
        )).toList();
      }
    } catch (_) {}

    return [
      HagglingScript(step: 'Розвідка', dialogue: 'Я бачив цю модель за ${bestComp.toStringAsFixed(0)} грн в іншому магазині.', tips: 'Завжди починай з фактом конкурента.'),
      HagglingScript(step: 'Установка', dialogue: 'Чи можете ви відповісти на цю ціну? Я готовий купити зараз.', tips: 'Покажіть, що ви маєте вибір.'),
      HagglingScript(step: 'Тиск', dialogue: 'Якщо ціна не зміниться, я піду до конкурента.', tips: 'Бути впевненим, але не агресивним.'),
      HagglingScript(step: 'Угода', dialogue: 'Дякую! Можемо домовитись на ${(bestComp * 0.95).toStringAsFixed(0)} грн?', tips: 'Завжди спробуйте попросити навіть менше.'),
    ];
  }

  Future<String> _generateCoachTip(String product, double storePrice, double target, double savings) async {
    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk negotiation coach AI. Respond in Ukrainian with cyberpunk flavor. Be concise (1-2 sentences). Give a coaching tip.',
        userPrompt: 'Product: $product, Store: ${storePrice.toStringAsFixed(0)} грн, Target: ${target.toStringAsFixed(0)} грн, Potential savings: ${savings.toStringAsFixed(1)}%. Quick coaching tip in Ukrainian?',
        temperature: 0.9,
      );
      return response?.trim() ?? '';
    } catch (_) {
      return 'Haggle Protocol: дані конкурентів завантажено. Готовий до переговорів.';
    }
  }

  String _estimateSuccessRate(double savings) {
    if (savings > 20) return '90%';
    if (savings > 15) return '75%';
    if (savings > 10) return '60%';
    if (savings > 5) return '40%';
    return '20%';
  }

  String _inferCategory(String query) {
    final q = query.toLowerCase();
    if (q.contains('ps5') || q.contains('xbox') || q.contains('switch') || q.contains('playstation')) return 'Gaming';
    if (q.contains('iphone') || q.contains('samsung') || q.contains('pixel')) return 'Smartphones';
    if (q.contains('macbook') || q.contains('laptop') || q.contains('ноутбук')) return 'Laptops';
    if (q.contains('monitor') || q.contains('монітор') || q.contains('display')) return 'Monitors';
    if (q.contains('rtx') || q.contains('gpu') || q.contains('відеокарта')) return 'Components';
    return 'Other';
  }

  void removeSession(String id) {
    state = state.copyWith(sessions: state.sessions.where((s) => s.id != id).toList());
  }

  void markSessionWon(String id) {
    final idx = state.sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final newSessions = [...state.sessions];
    newSessions[idx] = newSessions[idx].copyWith(status: 'won');
    state = state.copyWith(sessions: newSessions);
  }

  void markSessionLost(String id) {
    final idx = state.sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    final newSessions = [...state.sessions];
    newSessions[idx] = newSessions[idx].copyWith(status: 'lost');
    state = state.copyWith(sessions: newSessions);
  }

  void addPredefinedProduct(int catalogIndex) {
    if (catalogIndex < 0 || catalogIndex >= _hagglingCatalog.length) return;
    final entry = _hagglingCatalog[catalogIndex];
    final name = entry['name'] as String;
    if (state.sessions.any((s) => s.productName == name)) return;
    final price = (entry['price'] as num).toDouble();
    final competitors = _generateCompetitors(name, price);
    final bestComp = competitors.map((c) => c.price).reduce((a, b) => a < b ? a : b);
    final target = double.parse((bestComp * 0.95).toStringAsFixed(0));
    final savings = ((1 - target / price) * 100);

    final session = HagglingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: name,
      storePrice: price,
      targetPrice: target,
      bestCompetitorPrice: bestComp,
      competitorPrices: competitors,
      savingsPotential: double.parse(savings.toStringAsFixed(1)),
      successRate: _estimateSuccessRate(savings),
      lastUpdated: DateTime.now(),
      category: entry['category'] as String,
    );
    state = state.copyWith(sessions: [...state.sessions, session]);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === PROVIDER ===

final hagglingCoachProvider = StateNotifierProvider<HagglingCoachNotifier, HagglingState>(
  (ref) => HagglingCoachNotifier(ref),
);
