import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/serp_api_service.dart';

// =============================================================================
// Wishlist URL Scanner — LTV Phase 2 Feature #1
// =============================================================================
//
// Юзер вставляє посилання на товар з Rozetka/Comfy/Allo/Click — додаток
// витягує назву, ціну, магазин і авто-прив'язує до цілі.
//
// API: SerpAPI searchShopping() + URL parsing для Rozetka/Comfy/Allo/Click
// XP: +3 за кожний відсканований URL
// =============================================================================

/// Supported Ukrainian store domains for URL recognition.
class UkrainianStore {
  final String domain;
  final String name;
  final String color;

  const UkrainianStore(this.domain, this.name, this.color);

  static const List<UkrainianStore> all = [
    UkrainianStore('rozetka.com.ua', 'Rozetka', '#4BC4F0'),
    UkrainianStore('comfy.ua', 'Comfy', '#FF6B00'),
    UkrainianStore('allo.ua', 'Allo', '#FF2D55'),
    UkrainianStore('elmir.ua', 'Elmir', '#00A651'),
    UkrainianStore('click.ua', 'Click', '#FFD700'),
    UkrainianStore('foxtrot.com.ua', 'Foxtrot', '#E4002B'),
    UkrainianStore('brain.com.ua', 'Brain', '#6B00FF'),
    UkrainianStore('mta.ua', 'MTA', '#00F0FF'),
    UkrainianStore('ktc.ua', 'KTC', '#FF3366'),
    UkrainianStore('sota.ua', 'Sota', '#00FF88'),
    UkrainianStore('compx.com.ua', 'Compx', '#FF8C00'),
    UkrainianStore('jabko.me', 'Jabko', '#B8FF00'),
    UkrainianStore('citrus.ua', 'Citrus', '#FF9500'),
    UkrainianStore('hotline.ua', 'Hotline', '#FFD700'),
    UkrainianStore('ekatalog.ua', 'eKatalog', '#00B4D8'),
  ];

  /// Tries to identify the store from a URL.
  static UkrainianStore? identify(String url) {
    final lower = url.toLowerCase();
    for (final store in all) {
      if (lower.contains(store.domain)) return store;
    }
    return null;
  }
}

/// Rich data model for a scanned wishlist URL.
class WishlistUrlModel {
  final WishlistUrl data;
  final String goalName;
  final UkrainianStore? store;
  final bool isPriceOutdated;

  const WishlistUrlModel({
    required this.data,
    this.goalName = '',
    this.store,
    this.isPriceOutdated = false,
  });

  /// True if the URL was scanned more than 24 hours ago.
  bool get needsRescan {
    if (data.lastScannedAt == null) return true;
    return DateTime.now().difference(data.lastScannedAt!).inHours >= 24;
  }

  WishlistUrlModel copyWith({
    WishlistUrl? data,
    String? goalName,
    UkrainianStore? store,
    bool? isPriceOutdated,
  }) {
    return WishlistUrlModel(
      data: data ?? this.data,
      goalName: goalName ?? this.goalName,
      store: store ?? this.store,
      isPriceOutdated: isPriceOutdated ?? this.isPriceOutdated,
    );
  }
}

/// State for the Wishlist URL Scanner feature.
class WishlistUrlScannerState {
  final List<WishlistUrlModel> urls;
  final bool isLoading;
  final String? error;
  final int serpApiCallsToday;
  final int serpApiCallsThisMonth;

  const WishlistUrlScannerState({
    this.urls = const [],
    this.isLoading = false,
    this.error,
    this.serpApiCallsToday = 0,
    this.serpApiCallsThisMonth = 0,
  });

  int get totalUrls => urls.length;
  int get urlsNeedingRescan => urls.where((u) => u.needsRescan).length;
  int get serpApiCallsRemaining => 95 - serpApiCallsThisMonth;
  bool get isSerpApiLimitReached => serpApiCallsThisMonth >= 95;

  WishlistUrlScannerState copyWith({
    List<WishlistUrlModel>? urls,
    bool? isLoading,
    String? error,
    int? serpApiCallsToday,
    int? serpApiCallsThisMonth,
  }) {
    return WishlistUrlScannerState(
      urls: urls ?? this.urls,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      serpApiCallsToday: serpApiCallsToday ?? this.serpApiCallsToday,
      serpApiCallsThisMonth: serpApiCallsThisMonth ?? this.serpApiCallsThisMonth,
    );
  }
}

/// StateNotifier for Wishlist URL Scanner.
class WishlistUrlScannerNotifier extends StateNotifier<WishlistUrlScannerState> {
  final AppDatabase _db;
  final SerpApiService _serpApi;

  WishlistUrlScannerNotifier(this._db, this._serpApi)
      : super(const WishlistUrlScannerState());

  /// Loads all wishlist URLs from the database.
  Future<void> loadUrls() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final urls = await _db.getAllWishlistUrls();
      final goals = await _db.getAllGoals();
      final goalMap = {for (final g in goals) g.id: g.name};

      final models = urls.map((u) {
        return WishlistUrlModel(
          data: u,
          goalName: goalMap[u.goalId] ?? '',
          store: UkrainianStore.identify(u.url),
          isPriceOutdated: u.lastScannedAt == null ||
              DateTime.now().difference(u.lastScannedAt!).inHours >= 24,
        );
      }).toList();

      state = state.copyWith(urls: models, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Scans a URL: identifies store, fetches price via SerpAPI, saves to DB.
  Future<void> scanUrl(String url, int goalId) async {
    if (url.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final store = UkrainianStore.identify(url);
      String productName = '';
      double extractedPrice = 0.0;

      // Try to get price from SerpAPI if not at limit
      if (!_isAtSerpApiLimit()) {
        // Extract a search query from the URL — use store name + generic term
        final searchQuery = store != null
            ? '${store.name} товар'
            : url;

        final results = await _serpApi.searchShopping(searchQuery, numResults: 5);
        if (results.isNotEmpty) {
          productName = results.first.title;
          extractedPrice = results.first.price;
          state = state.copyWith(
            serpApiCallsThisMonth: state.serpApiCallsThisMonth + 1,
            serpApiCallsToday: state.serpApiCallsToday + 1,
          );
        }
      }

      // Insert into database
      await _db.insertWishlistUrl(WishlistUrlsCompanion.insert(
        goalId: goalId,
        url: url,
        storeName: Value(store?.name ?? 'Невідомий'),
        productName: Value(productName),
        extractedPrice: Value(extractedPrice),
        lastScannedAt: Value(DateTime.now()),
      ));

      // +3 XP for scanning a URL
      await _db.addXP(3, source: 'wishlist_url_scan');

      await loadUrls();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Re-scans all URLs that need updating (24h+ since last scan).
  Future<void> rescanOutdated() async {
    if (_isAtSerpApiLimit()) {
      state = state.copyWith(error: 'SerpAPI ліміт вичерпано (95/100)');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final outdated = state.urls.where((u) => u.needsRescan).toList();
      int apiCalls = 0;

      for (final model in outdated) {
        if (state.serpApiCallsThisMonth + apiCalls >= 95) break;

        final searchQuery = model.store != null
            ? '${model.store!.name} ${model.data.productName}'
            : model.data.productName;

        if (searchQuery.isNotEmpty) {
          final results = await _serpApi.searchShopping(
            searchQuery,
            numResults: 3,
          );
          apiCalls++;

          if (results.isNotEmpty) {
            await _db.updateWishlistUrl(
              model.data.id,
              WishlistUrlsCompanion(
                extractedPrice: Value(results.first.price),
                productName: Value(results.first.title),
                lastScannedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }

      state = state.copyWith(
        serpApiCallsThisMonth: state.serpApiCallsThisMonth + apiCalls,
        serpApiCallsToday: state.serpApiCallsToday + apiCalls,
      );

      await loadUrls();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Deletes a wishlist URL.
  Future<void> deleteUrl(int id) async {
    await _db.deleteWishlistUrl(id);
    await loadUrls();
  }

  bool _isAtSerpApiLimit() => state.serpApiCallsThisMonth >= 95;
}

/// Provider for the Wishlist URL Scanner.
final wishlistUrlScannerProvider =
    StateNotifierProvider<WishlistUrlScannerNotifier, WishlistUrlScannerState>(
  (ref) {
    final db = ref.read(databaseProvider);
    final serpApi = ref.read(serpApiServiceProvider);
    return WishlistUrlScannerNotifier(db, serpApi);
  },
);
