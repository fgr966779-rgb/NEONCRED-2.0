import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../core/utils/serp_api_service.dart';

// =============================================================================
// Showroom Price Shield — LTV Phase 2 Feature #8
// =============================================================================
//
// Юзер сканує ціну в магазині → додаток миттєво показує найдешевшу
// онлайн-ціну в Ukrainian stores. Генерує "Price Match Request" для касира.
//
// API: SerpAPI для миттєвої перевірки + OpenRouter для аналізу
// XP: +5 за кожен скан, +10 якщо юзер скористався price match
// =============================================================================

/// Rich data model for a Price Shield scan result.
class PriceShieldScanModel {
  final PriceShieldScan data;
  final String? savingsPercent;
  final String? aiTip;

  const PriceShieldScanModel({
    required this.data,
    this.savingsPercent,
    this.aiTip,
  });

  /// True if online price is cheaper than in-store.
  bool get hasSavings => data.bestOnlinePrice > 0 && data.bestOnlinePrice < data.inStorePrice;

  /// Savings in UAH.
  double get savingsAmount => hasSavings ? data.inStorePrice - data.bestOnlinePrice : 0.0;

  /// Savings percentage.
  String get savingsPercentStr {
    if (!hasSavings) return '0%';
    final pct = ((data.inStorePrice - data.bestOnlinePrice) / data.inStorePrice * 100);
    return '${pct.toStringAsFixed(1)}%';
  }
}

/// State for the Price Shield feature.
class PriceShieldState {
  final List<PriceShieldScanModel> scans;
  final bool isLoading;
  final String? error;
  final int totalSavingsUah;

  const PriceShieldState({
    this.scans = const [],
    this.isLoading = false,
    this.error,
    this.totalSavingsUah = 0,
  });

  int get totalScans => scans.length;
  int get priceMatchOpportunities => scans.where((s) => s.hasSavings).length;

  PriceShieldState copyWith({
    List<PriceShieldScanModel>? scans,
    bool? isLoading,
    String? error,
    int? totalSavingsUah,
  }) {
    return PriceShieldState(
      scans: scans ?? this.scans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalSavingsUah: totalSavingsUah ?? this.totalSavingsUah,
    );
  }
}

/// StateNotifier for Showroom Price Shield.
class PriceShieldNotifier extends StateNotifier<PriceShieldState> {
  final AppDatabase _db;
  final SerpApiService _serpApi;
  final OpenRouterService _ai;

  PriceShieldNotifier(this._db, this._serpApi, this._ai)
      : super(const PriceShieldState());

  /// Loads all Price Shield scans from the database.
  Future<void> loadScans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final scans = await _db.getAllPriceShieldScans();
      int totalSavings = 0;

      final models = scans.map((s) {
        final model = PriceShieldScanModel(data: s);
        if (model.hasSavings) {
          totalSavings += model.savingsAmount.round();
        }
        return model;
      }).toList();

      state = state.copyWith(scans: models, isLoading: false, totalSavingsUah: totalSavings);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Scans a product: searches SerpAPI for the best online price.
  Future<void> scanProduct({
    required String productName,
    required double inStorePrice,
    required String inStoreName,
  }) async {
    if (productName.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Search for the cheapest online price via SerpAPI
      final cheapest = await _serpApi.findCheapestOffer(
        '$productName купити Україна ціна',
        numResults: 10,
      );

      final bestOnlinePrice = cheapest['price'] as double? ?? 0.0;
      final bestOnlineStore = cheapest['store'] as String? ?? '';

      final savingsUah = (bestOnlinePrice > 0 && bestOnlinePrice < inStorePrice)
          ? inStorePrice - bestOnlinePrice
          : 0.0;

      // Get AI price match tip
      String aiTip = '';
      if (savingsUah > 0) {
        aiTip = await _generatePriceMatchTip(
          productName: productName,
          inStorePrice: inStorePrice,
          inStoreName: inStoreName,
          bestOnlinePrice: bestOnlinePrice,
          bestOnlineStore: bestOnlineStore,
          savingsUah: savingsUah,
        );
      }

      // Insert scan into database
      await _db.insertPriceShieldScan(PriceShieldScansCompanion.insert(
        productName: productName,
        inStorePrice: inStorePrice,
        bestOnlinePrice: Value(bestOnlinePrice),
        bestOnlineStore: Value(bestOnlineStore),
        savingsUah: Value(savingsUah),
      ));

      // +5 XP for scanning
      await _db.addXP(5, source: 'price_shield_scan');

      await loadScans();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Marks a scan as price-match used (+10 XP bonus).
  Future<void> markPriceMatchUsed(int scanId) async {
    await _db.updatePriceShieldScan(
      scanId,
      const PriceShieldScansCompanion(priceMatchUsed: Value(true)),
    );
    await _db.addXP(10, source: 'price_match_used');
    await loadScans();
  }

  /// Deletes a scan.
  Future<void> deleteScan(int id) async {
    await _db.deletePriceShieldScan(id);
    await loadScans();
  }

  /// Generates an AI-powered price match tip via OpenRouter.
  Future<String> _generatePriceMatchTip({
    required String productName,
    required double inStorePrice,
    required String inStoreName,
    required double bestOnlinePrice,
    required String bestOnlineStore,
    required double savingsUah,
  }) async {
    final result = await _ai.chat(
      systemPrompt:
          'Ти VAULT-17, кібернетичний радник з економії в NEONCRED. '
          'Відповідай українською. Дай коротку пораду (1-2 речення) як '
          'використати price match політику магазину, щоб знизити ціну.',
      userPrompt:
          'Товар: $productName\n'
          'Ціна в магазині $inStoreName: ${inStorePrice.toStringAsFixed(0)} грн\n'
          'Найдешевша онлайн-ціна ($bestOnlineStore): ${bestOnlinePrice.toStringAsFixed(0)} грн\n'
          'Економія: ${savingsUah.toStringAsFixed(0)} грн\n'
          'Як показати касиру і отримати знижку?',
      temperature: 0.8,
      maxTokens: 150,
    );
    return result ?? '';
  }
}

/// Provider for the Showroom Price Shield.
final priceShieldProvider =
    StateNotifierProvider<PriceShieldNotifier, PriceShieldState>(
  (ref) {
    final db = ref.read(databaseProvider);
    final serpApi = ref.read(serpApiServiceProvider);
    final ai = ref.read(openRouterServiceProvider);
    return PriceShieldNotifier(db, serpApi, ai);
  },
);
