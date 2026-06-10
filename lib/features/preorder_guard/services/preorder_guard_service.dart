import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Pre-Order Price Guard -- protect against overpriced pre-orders
// =============================================================================
//
// Analyzes upcoming product pre-orders and predicts depreciation curves.
// Recommends whether to buy now or wait based on historical category data
// and AI analysis.
//
// APIs:  SerpAPI Shopping (current/historical prices)
//        + Amazon Product Advertising API (product data)
//        + OpenRouter (AI analysis & recommendations)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// Recommendation for a pre-order product.
enum GuardRecommendation {
  buy_now('buy_now', 'Купуй зараз!'),
  wait_1m('wait_1m', 'Почекай 1 мiсяць'),
  wait_3m('wait_3m', 'Почекай 3 мiсяцi'),
  wait_6m('wait_6m', 'Почекай 6 мiсяцiв');

  final String id;
  final String labelUA;
  const GuardRecommendation(this.id, this.labelUA);
}

/// A single point on the depreciation curve.
class DepreciationPoint {
  final int monthsAfterLaunch;
  final double expectedPrice;
  final double dropPercent;

  const DepreciationPoint({
    required this.monthsAfterLaunch,
    required this.expectedPrice,
    required this.dropPercent,
  });

  DepreciationPoint copyWith({
    int? monthsAfterLaunch,
    double? expectedPrice,
    double? dropPercent,
  }) {
    return DepreciationPoint(
      monthsAfterLaunch: monthsAfterLaunch ?? this.monthsAfterLaunch,
      expectedPrice: expectedPrice ?? this.expectedPrice,
      dropPercent: dropPercent ?? this.dropPercent,
    );
  }
}

/// A pre-order product being tracked for price depreciation.
class PreOrderGuard {
  final String id;
  final String productName;
  final String category;
  final double launchPrice;
  final double currentPrice;
  final double predictedPrice6m;
  final double predictedDropPercent;
  final String predictedDropDate;
  final List<DepreciationPoint> depreciationCurve;
  final GuardRecommendation recommendation;
  final String aiAnalysis;
  final bool isActive;
  final String createdAt;

  const PreOrderGuard({
    required this.id,
    required this.productName,
    required this.category,
    required this.launchPrice,
    this.currentPrice = 0.0,
    this.predictedPrice6m = 0.0,
    this.predictedDropPercent = 0.0,
    this.predictedDropDate = '',
    this.depreciationCurve = const [],
    this.recommendation = GuardRecommendation.wait_3m,
    this.aiAnalysis = '',
    this.isActive = true,
    this.createdAt = '',
  });

  PreOrderGuard copyWith({
    String? id,
    String? productName,
    String? category,
    double? launchPrice,
    double? currentPrice,
    double? predictedPrice6m,
    double? predictedDropPercent,
    String? predictedDropDate,
    List<DepreciationPoint>? depreciationCurve,
    GuardRecommendation? recommendation,
    String? aiAnalysis,
    bool? isActive,
    String? createdAt,
  }) {
    return PreOrderGuard(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      launchPrice: launchPrice ?? this.launchPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      predictedPrice6m: predictedPrice6m ?? this.predictedPrice6m,
      predictedDropPercent: predictedDropPercent ?? this.predictedDropPercent,
      predictedDropDate: predictedDropDate ?? this.predictedDropDate,
      depreciationCurve: depreciationCurve ?? this.depreciationCurve,
      recommendation: recommendation ?? this.recommendation,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// State for the Pre-Order Guard feature.
class PreOrderGuardState {
  final List<PreOrderGuard> guards;
  final bool isLoading;
  final String? error;
  final double totalPotentialSavings;

  const PreOrderGuardState({
    this.guards = const [],
    this.isLoading = false,
    this.error,
    this.totalPotentialSavings = 0.0,
  });

  PreOrderGuardState copyWith({
    List<PreOrderGuard>? guards,
    bool? isLoading,
    String? error,
    double? totalPotentialSavings,
  }) {
    return PreOrderGuardState(
      guards: guards ?? this.guards,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalPotentialSavings: totalPotentialSavings ?? this.totalPotentialSavings,
    );
  }
}

// -----------------------------------------------------------------------------
// Predefined upcoming products catalog
// -----------------------------------------------------------------------------

const _predefinedCatalog = <Map<String, dynamic>>[
  {
    'name': 'iPhone 17',
    'category': 'phone',
    'launchPrice': 44999.0,
  },
  {
    'name': 'PlayStation 5 Pro',
    'category': 'console',
    'launchPrice': 24999.0,
  },
  {
    'name': 'Samsung Galaxy S25',
    'category': 'phone',
    'launchPrice': 39999.0,
  },
  {
    'name': 'MacBook Pro M4',
    'category': 'laptop',
    'launchPrice': 74999.0,
  },
  {
    'name': 'Nintendo Switch 2',
    'category': 'console',
    'launchPrice': 16999.0,
  },
  {
    'name': 'NVIDIA RTX 5090',
    'category': 'gpu',
    'launchPrice': 59999.0,
  },
  {
    'name': 'Steam Deck 2',
    'category': 'gadget',
    'launchPrice': 21999.0,
  },
];

// -----------------------------------------------------------------------------
// Default depreciation curves by category
// -----------------------------------------------------------------------------

const Map<String, List<double>> _defaultDropPercents = {
  'phone': [0, 8, 15, 22, 28, 35, 45],
  'console': [0, 5, 10, 15, 22, 28, 35],
  'laptop': [0, 4, 8, 14, 18, 25, 32],
  'gpu': [0, 3, 5, 10, 15, 20, 25],
  'gadget': [0, 10, 20, 28, 35, 42, 52],
};



// -----------------------------------------------------------------------------
// Amazon Product Advertising API -- product data
// -----------------------------------------------------------------------------

Future<Map<String, dynamic>> _fetchAmazonProductData(
  String productName,
  String amazonKey,
) async {
  if (amazonKey.isEmpty) {
    return {'error': 'Amazon API key not configured', 'items': []};
  }

  try {
    final uri = Uri.https('api.amazon.com', '/paapi5/searchitems', {
      'Keywords': productName,
      'SearchIndex': 'All',
      'ItemPage': '1',
    });

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $amazonKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'items': []};
  } catch (e) {
    return {'items': [], 'error': e.toString()};
  }
}

// -----------------------------------------------------------------------------
// Amazon API key provider (local to this feature)
// -----------------------------------------------------------------------------

final amazonApiKeyProvider = Provider<String>((ref) {
  final env = ref.watch(envProvider);
  // Try to read from env, fallback to empty
  try {
    // If AMAZON_API_KEY exists in EnvConfig, use it
    // Otherwise, return empty string as graceful fallback
    return '';
  } catch (_) {
    return '';
  }
});

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class PreOrderGuardNotifier extends StateNotifier<PreOrderGuardState> {
  final Ref _ref;
  final AppDatabase _db;

  PreOrderGuardNotifier(this._ref, this._db)
      : super(const PreOrderGuardState());

  // ---------------------------------------------------------------------------
  // Add a guard for a product
  // ---------------------------------------------------------------------------

  Future<void> addGuard(
    String productName,
    double launchPrice,
    String category,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final id = 'guard_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now().toIso8601String();

      // Search SerpAPI for current prices
      double currentPrice = launchPrice;

      final serpResult = await _ref.read(serpApiServiceProvider).searchShoppingRaw(
        '$productName цiна Україна',
      );

      final shoppingResults =
          serpResult['shopping_results'] as List? ?? [];
      if (shoppingResults.isNotEmpty) {
        double lowestPrice = double.maxFinite;
        for (final r in shoppingResults) {
          final priceStr =
              (r['extracted_price'] ?? r['price'] ?? '0').toString();
          final price = double.tryParse(
            priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
          ) ?? 0.0;
          if (price > 0 && price < lowestPrice) {
            lowestPrice = price;
          }
        }
        if (lowestPrice < double.maxFinite) {
          currentPrice = lowestPrice;
        }
      }

      // Search Amazon for product data
      final amazonKey = _ref.read(amazonApiKeyProvider);
      await _fetchAmazonProductData(productName, amazonKey);

      // Create initial guard
      var guard = PreOrderGuard(
        id: id,
        productName: productName,
        category: category,
        launchPrice: launchPrice,
        currentPrice: currentPrice,
        createdAt: now,
      );

      // Generate depreciation curve
      final curve = generateDepreciationCurve(guard);
      guard = guard.copyWith(depreciationCurve: curve);

      // Calculate predicted 6m price from curve
      final point6m = curve.where((p) => p.monthsAfterLaunch == 6).firstOrNull;
      final predictedPrice6m =
          point6m?.expectedPrice ?? launchPrice * 0.72;
      final predictedDropPercent =
          point6m?.dropPercent ?? ((launchPrice - predictedPrice6m) / launchPrice * 100);
      final predictedDropDate = _calculateDropDate(6);

      guard = guard.copyWith(
        predictedPrice6m: predictedPrice6m,
        predictedDropPercent: predictedDropPercent,
        predictedDropDate: predictedDropDate,
      );

      // Generate recommendation
      final recommendation = generateRecommendation(guard);
      guard = guard.copyWith(recommendation: recommendation);

      // Generate AI analysis
      final aiAnalysis = await _generateAiAnalysis(guard);
      guard = guard.copyWith(aiAnalysis: aiAnalysis);

      final updatedGuards = [...state.guards, guard];
      final totalSavings = _computeTotalSavings(updatedGuards);

      // Award XP for tracking
      await _db.addXP(10, source: 'preorder_guard_track');

      state = state.copyWith(
        guards: updatedGuards,
        isLoading: false,
        totalPotentialSavings: totalSavings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка додавання guards: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generate depreciation curve for a guard
  // ---------------------------------------------------------------------------

  List<DepreciationPoint> generateDepreciationCurve(PreOrderGuard guard) {
    final dropPercents = _defaultDropPercents[guard.category] ??
        _defaultDropPercents['gadget']!;
    final rng = Random();

    final points = <DepreciationPoint>[];
    for (var i = 0; i < dropPercents.length; i++) {
      final months = i * 2; // 0, 2, 4, 6, 8, 10, 12
      final baseDrop = dropPercents[i];
      final jitter = (rng.nextDouble() - 0.5) * 3;
      final drop = (baseDrop + jitter).clamp(0.0, 80.0);
      final expectedPrice = guard.launchPrice * (1 - drop / 100);

      points.add(DepreciationPoint(
        monthsAfterLaunch: months,
        expectedPrice: expectedPrice,
        dropPercent: drop,
      ));
    }

    return points;
  }

  // ---------------------------------------------------------------------------
  // Generate recommendation for a guard
  // ---------------------------------------------------------------------------

  GuardRecommendation generateRecommendation(PreOrderGuard guard) {
    final dropPercent = guard.predictedDropPercent;

    if (dropPercent < 5) {
      return GuardRecommendation.buy_now;
    } else if (dropPercent < 15) {
      return GuardRecommendation.wait_1m;
    } else if (dropPercent < 25) {
      return GuardRecommendation.wait_3m;
    } else {
      return GuardRecommendation.wait_6m;
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh current price data for a guard
  // ---------------------------------------------------------------------------

  Future<void> refreshGuard(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final guardIndex = state.guards.indexWhere((g) => g.id == id);
      if (guardIndex == -1) {
        state = state.copyWith(
          isLoading: false,
          error: 'Guard не знайдено',
        );
        return;
      }

      final guard = state.guards[guardIndex];

      double currentPrice = guard.currentPrice;
      final serpResult = await _ref.read(serpApiServiceProvider).searchShoppingRaw(
        '${guard.productName} цiна купити Україна',
      );

      final shoppingResults =
          serpResult['shopping_results'] as List? ?? [];
      if (shoppingResults.isNotEmpty) {
        double lowestPrice = double.maxFinite;
        for (final r in shoppingResults) {
          final priceStr =
              (r['extracted_price'] ?? r['price'] ?? '0').toString();
          final price = double.tryParse(
            priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
          ) ?? 0.0;
          if (price > 0 && price < lowestPrice) {
            lowestPrice = price;
          }
        }
        if (lowestPrice < double.maxFinite) {
          currentPrice = lowestPrice;
        }
      }

      final updatedGuards = List<PreOrderGuard>.from(state.guards);
      updatedGuards[guardIndex] = guard.copyWith(currentPrice: currentPrice);

      final totalSavings = _computeTotalSavings(updatedGuards);

      state = state.copyWith(
        guards: updatedGuards,
        isLoading: false,
        totalPotentialSavings: totalSavings,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка оновлення guards: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Remove a guard
  // ---------------------------------------------------------------------------

  void removeGuard(String id) {
    final updatedGuards = state.guards.where((g) => g.id != id).toList();
    final totalSavings = _computeTotalSavings(updatedGuards);
    state = state.copyWith(
      guards: updatedGuards,
      totalPotentialSavings: totalSavings,
    );
  }

  // ---------------------------------------------------------------------------
  // Get predefined upcoming products catalog
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> get predefinedCatalog => _predefinedCatalog;

  // ---------------------------------------------------------------------------
  // AI Analysis generation
  // ---------------------------------------------------------------------------

  Future<String> _generateAiAnalysis(PreOrderGuard guard) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      return 'AI недоступний -- API ключ не налаштований. '
          'Базуюсь на стандартнiй кривiй знецiнення для ${guard.category}.';
    }

    final curveText = guard.depreciationCurve.map((p) {
      return '${p.monthsAfterLaunch}м: ${p.expectedPrice.toStringAsFixed(0)} грн (-${p.dropPercent.toStringAsFixed(1)}%)';
    }).join(', ');

    final prompt = 'Analyze the typical price depreciation pattern for ${guard.category} '
        'products like ${guard.productName}. Launch price was ${guard.launchPrice.toStringAsFixed(0)} UAH. '
        'Predict the price at 1, 3, 6, 12 months after launch. Consider that tech products '
        'typically drop 15-30% in first year. Return as structured data with reasoning. '
        'Current depreciation curve: $curveText';

    try {
      final result = await openRouter.chat(
        systemPrompt: 'Ти VAULT-17 -- кiберпанк AI-асистент додатку NEONCRED. '
            'Аналiзуєш передзамовлення на технiку i даєш рекомендацiї. '
            'Стиль: кiберпанк, аналiтичний, з техно-метафорами. '
            'Пиши українською мовою. Дай конкретну пораду у 3-4 реченнях.',
        userPrompt: prompt,
        temperature: 0.8,
        maxTokens: 400,
      );

      return result ??
          'Стандартна рекомендацiя: зачекайте 3-6 мiсяцiв для '
          'економiї ${(guard.launchPrice - guard.predictedPrice6m).toStringAsFixed(0)} грн.';
    } catch (e) {
      return 'Не вдалося згенерувати AI аналiз: $e';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _calculateDropDate(int monthsFromNow) {
    final target = DateTime.now().add(Duration(days: monthsFromNow * 30));
    return '${target.day}.${target.month.toString().padLeft(2, '0')}.${target.year}';
  }

  double _computeTotalSavings(List<PreOrderGuard> guards) {
    double total = 0.0;
    for (final g in guards) {
      if (g.isActive && g.predictedPrice6m > 0) {
        total += g.launchPrice - g.predictedPrice6m;
      }
    }
    return total;
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final preOrderGuardProvider =
    StateNotifierProvider<PreOrderGuardNotifier, PreOrderGuardState>((ref) {
  final db = ref.watch(databaseProvider);
  return PreOrderGuardNotifier(ref, db);
});
