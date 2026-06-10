import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../core/data/ukrainian_stores.dart';
import '../../../data/database.dart';

// =============================================================================
// MODELS
// =============================================================================

class GoalProductLinkItem {
  final String linkId;
  final int goalId;
  final String goalName;
  final String productName;
  final String searchQuery;
  final double targetPriceUah;
  final double bestPriceUah;
  final String bestStoreName;
  final String bestStoreUrl;
  final double remainingUah;
  final bool priceBelowTarget;
  final int xpAwarded;
  final DateTime lastChecked;
  final DateTime createdAt;

  const GoalProductLinkItem({
    required this.linkId,
    required this.goalId,
    required this.goalName,
    required this.productName,
    required this.searchQuery,
    this.targetPriceUah = 0,
    this.bestPriceUah = 0,
    this.bestStoreName = '',
    this.bestStoreUrl = '',
    this.remainingUah = 0,
    this.priceBelowTarget = false,
    this.xpAwarded = 0,
    required this.lastChecked,
    required this.createdAt,
  });

  GoalProductLinkItem copyWith({
    String? linkId,
    int? goalId,
    String? goalName,
    String? productName,
    String? searchQuery,
    double? targetPriceUah,
    double? bestPriceUah,
    String? bestStoreName,
    String? bestStoreUrl,
    double? remainingUah,
    bool? priceBelowTarget,
    int? xpAwarded,
    DateTime? lastChecked,
    DateTime? createdAt,
  }) {
    return GoalProductLinkItem(
      linkId: linkId ?? this.linkId,
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      productName: productName ?? this.productName,
      searchQuery: searchQuery ?? this.searchQuery,
      targetPriceUah: targetPriceUah ?? this.targetPriceUah,
      bestPriceUah: bestPriceUah ?? this.bestPriceUah,
      bestStoreName: bestStoreName ?? this.bestStoreName,
      bestStoreUrl: bestStoreUrl ?? this.bestStoreUrl,
      remainingUah: remainingUah ?? this.remainingUah,
      priceBelowTarget: priceBelowTarget ?? this.priceBelowTarget,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      lastChecked: lastChecked ?? this.lastChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get statusMessage {
    if (bestPriceUah <= 0) return 'Очікування перевірки цін...';
    if (priceBelowTarget) {
      return 'Ціна нижче цільової! $productName вже за ${_fmtPrice(bestPriceUah)} грн у $bestStoreName';
    }
    return 'Залишилось ${_fmtPrice(remainingUah)} грн -- $productName за ${_fmtPrice(bestPriceUah)} грн у $bestStoreName';
  }
}

class GoalPriceIntegratorStats {
  final int totalLinks;
  final int pricesBelowTarget;
  final double totalSavingsPotential;
  final bool hasIntegratorBadge;

  const GoalPriceIntegratorStats({
    this.totalLinks = 0,
    this.pricesBelowTarget = 0,
    this.totalSavingsPotential = 0,
    this.hasIntegratorBadge = false,
  });
}

class GoalPriceIntegratorState {
  final List<GoalProductLinkItem> links;
  final bool isLoading;
  final String? error;
  final String? aiAnalysisText;
  final String? aiAnalysisForLinkId;
  final GoalPriceIntegratorStats stats;

  const GoalPriceIntegratorState({
    this.links = const [],
    this.isLoading = false,
    this.error,
    this.aiAnalysisText,
    this.aiAnalysisForLinkId,
    this.stats = const GoalPriceIntegratorStats(),
  });

  GoalPriceIntegratorState copyWith({
    List<GoalProductLinkItem>? links,
    bool? isLoading,
    String? error,
    String? aiAnalysisText,
    String? aiAnalysisForLinkId,
    GoalPriceIntegratorStats? stats,
  }) {
    return GoalPriceIntegratorState(
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      aiAnalysisText: aiAnalysisText,
      aiAnalysisForLinkId: aiAnalysisForLinkId,
      stats: stats ?? this.stats,
    );
  }
}

// =============================================================================
// NOTIFIER — Goal Price Integrator Business Logic
// =============================================================================

class GoalPriceIntegratorNotifier extends StateNotifier<GoalPriceIntegratorState> {
  final Ref _ref;

  GoalPriceIntegratorNotifier(this._ref) : super(const GoalPriceIntegratorState());

  // ---- Create New Goal-Product Link ----

  void createLink({
    required int goalId,
    required String goalName,
    required String productName,
    required String searchQuery,
    required double targetPriceUah,
    double goalCurrentAmount = 0,
  }) {
    final now = DateTime.now();
    final linkId = 'GPI-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(5, '0')}';
    final remaining = targetPriceUah - goalCurrentAmount;

    final link = GoalProductLinkItem(
      linkId: linkId,
      goalId: goalId,
      goalName: goalName,
      productName: productName.trim(),
      searchQuery: searchQuery.trim().isNotEmpty ? searchQuery.trim() : productName.trim(),
      targetPriceUah: targetPriceUah,
      remainingUah: remaining > 0 ? remaining : 0,
      lastChecked: now,
      createdAt: now,
    );

    final newLinks = [link, ...state.links];
    state = state.copyWith(
      links: newLinks,
      stats: _computeStats(newLinks),
      error: null,
    );
  }

  // ---- Check Prices via SerpAPI ----

  Future<void> checkPrices(String linkId) async {
    final idx = state.links.indexWhere((l) => l.linkId == linkId);
    if (idx == -1) return;

    state = state.copyWith(isLoading: true);

    try {
      final link = state.links[idx];
      double bestPrice = 0;
      String bestStore = '';
      String bestUrl = '';

      final serpApi = _ref.read(serpApiServiceProvider);
      if (serpApi.isConfigured) {
        final result = await serpApi.findCheapestOffer('${link.searchQuery} ціна Україна');
        bestPrice = result['price'] as double? ?? 0;
        bestStore = result['store'] as String? ?? '';
        bestUrl = result['url'] as String? ?? '';
      }

      // Fallback: use Ukrainian stores data
      if (bestPrice <= 0) {
        final listings = getListingsSortedByPrice(link.searchQuery);
        if (listings.isNotEmpty) {
          final cheapest = listings.first;
          bestPrice = cheapest.priceUAH;
          bestStore = getStoreNameById(cheapest.storeId) ?? cheapest.storeId;
          bestUrl = cheapest.url;
        }
      }

      final wasBelowTarget = link.priceBelowTarget;
      final isBelowTarget = bestPrice > 0 && bestPrice <= link.targetPriceUah;
      final newRemaining = bestPrice > 0 ? bestPrice - 0 : link.remainingUah; // remaining = price - current goal savings

      final updated = link.copyWith(
        bestPriceUah: bestPrice,
        bestStoreName: bestStore,
        bestStoreUrl: bestUrl,
        priceBelowTarget: isBelowTarget,
        remainingUah: newRemaining > 0 ? newRemaining : 0,
        lastChecked: DateTime.now(),
      );

      final newLinks = [...state.links];
      newLinks[idx] = updated;

      // Award +25 XP when price drops below target for the first time
      if (isBelowTarget && !wasBelowTarget) {
        final updatedWithXP = updated.copyWith(xpAwarded: 25);
        newLinks[idx] = updatedWithXP;
        _awardXP(25, source: 'goal_price_below_target');
      }

      state = state.copyWith(
        links: newLinks,
        isLoading: false,
        stats: _computeStats(newLinks),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка перевірки цін: $e',
      );
    }
  }

  // ---- Check All Prices ----

  Future<void> checkAllPrices() async {
    for (final link in state.links) {
      await checkPrices(link.linkId);
    }
  }

  // ---- AI Analysis via OpenRouter ----

  Future<void> generateAnalysis(String linkId) async {
    final link = state.links.where((l) => l.linkId == linkId).firstOrNull;
    if (link == null) return;

    state = state.copyWith(isLoading: true, aiAnalysisForLinkId: linkId);

    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt:
            'Ти -- Ціновий Інтегратор. Аналізуй зв\'язок цільових заощаджень з реальними цінами товарів. '
            'Стиль: кіберпанк-аналітик. Використовуй українську мову. '
            'Дай короткий аналіз (2-3 речення): наскільки реальна ціль, чи варто чекати знижки, альтернативи. '
            'Не додавай зайвих пояснень.',
        userPrompt:
            'Ціль: ${link.goalName}, цільова ціна: ${_fmtPrice(link.targetPriceUah)} грн, '
            'найкраща поточна ціна: ${_fmtPrice(link.bestPriceUah)} грн у ${link.bestStoreName}, '
            'залишилось: ${_fmtPrice(link.remainingUah)} грн, '
            'ціна нижче цільової: ${link.priceBelowTarget ? 'так' : 'ні'}.',
        temperature: 0.8,
        maxTokens: 300,
      );

      state = state.copyWith(
        isLoading: false,
        aiAnalysisText: response ?? _fallbackAnalysis(link),
        aiAnalysisForLinkId: linkId,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        aiAnalysisText: _fallbackAnalysis(link),
        aiAnalysisForLinkId: linkId,
      );
    }
  }

  void clearAnalysis() {
    state = state.copyWith(aiAnalysisText: null, aiAnalysisForLinkId: null);
  }

  // ---- Delete Link ----

  void deleteLink(String linkId) {
    final newLinks = state.links.where((l) => l.linkId != linkId).toList();
    state = state.copyWith(
      links: newLinks,
      stats: _computeStats(newLinks),
    );
  }



  // ---- XP Awarding ----

  void _awardXP(int amount, {String source = 'goal_price_integrator'}) {
    try {
      final db = _ref.read(databaseProvider);
      db.addXP(amount, source: source);
    } catch (_) {}
  }

  // ---- Stats Computation ----

  GoalPriceIntegratorStats _computeStats(List<GoalProductLinkItem> links) {
    int pricesBelowTarget = 0;
    double totalSavingsPotential = 0;

    for (final l in links) {
      if (l.priceBelowTarget) {
        pricesBelowTarget++;
        totalSavingsPotential += l.targetPriceUah - l.bestPriceUah;
      }
    }

    return GoalPriceIntegratorStats(
      totalLinks: links.length,
      pricesBelowTarget: pricesBelowTarget,
      totalSavingsPotential: totalSavingsPotential,
      hasIntegratorBadge: pricesBelowTarget >= 3,
    );
  }

  // ---- Clear Error ----

  void clearError() {
    state = state.copyWith(error: null);
  }

  // ---- Fallback Analysis ----

  String _fallbackAnalysis(GoalProductLinkItem link) {
    if (link.priceBelowTarget) {
      return '${link.productName} вже за ${_fmtPrice(link.bestPriceUah)} грн у ${link.bestStoreName} -- '
          'ціна нижче твоєї цільової! Час діяти та купувати.';
    }
    if (link.bestPriceUah > 0) {
      return '${link.productName} коштує ${_fmtPrice(link.bestPriceUah)} грн -- '
          'ще ${_fmtPrice(link.remainingUah)} грн до цільової. Продовжуй заощаджувати!';
    }
    return 'Ціни ще не перевірені. Натисни "Перевірити ціни" для пошуку найкращих пропозицій.';
  }
}

// =============================================================================
// HELPERS
// =============================================================================

String _fmtPrice(double v) {
  return v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ' ',
  );
}

// =============================================================================
// PROVIDER
// =============================================================================

final goalPriceIntegratorProvider =
    StateNotifierProvider<GoalPriceIntegratorNotifier, GoalPriceIntegratorState>(
  (ref) => GoalPriceIntegratorNotifier(ref),
);
