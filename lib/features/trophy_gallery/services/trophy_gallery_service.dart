import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// TrophyTier
// ---------------------------------------------------------------------------

enum TrophyTier { common, rare, epic, legendary, mythic }

extension TrophyTierX on TrophyTier {
  String get labelUA => switch (this) {
        TrophyTier.common => 'Звичайний',
        TrophyTier.rare => 'Рідкісний',
        TrophyTier.epic => 'Епічний',
        TrophyTier.legendary => 'Легендарний',
        TrophyTier.mythic => 'Міфічний',
      };

  String get iconEmoji => switch (this) {
        TrophyTier.common => '\u{1F7E2}',
        TrophyTier.rare => '\u{1F535}',
        TrophyTier.epic => '\u{1F7E1}',
        TrophyTier.legendary => '\u{1F534}',
        TrophyTier.mythic => '\u{1F48E}',
      };

  int get xpReward => switch (this) {
        TrophyTier.common => 100,
        TrophyTier.rare => 300,
        TrophyTier.epic => 750,
        TrophyTier.legendary => 2000,
        TrophyTier.mythic => 5000,
      };
}

// ---------------------------------------------------------------------------
// Trophy3D
// ---------------------------------------------------------------------------

class Trophy3D {
  final String trophyId;
  final String name;
  final String descriptionUA;
  final TrophyTier tier;
  final String sketchfabModelId;
  final String thumbnailUrl;
  final double milestoneAmount;
  final String achievementTag;
  final bool isAnimated;
  final bool hasAR;

  const Trophy3D({
    required this.trophyId,
    required this.name,
    required this.descriptionUA,
    required this.tier,
    required this.sketchfabModelId,
    this.thumbnailUrl = '',
    required this.milestoneAmount,
    required this.achievementTag,
    this.isAnimated = false,
    this.hasAR = false,
  });
}

// ---------------------------------------------------------------------------
// TrophyUnlockResult
// ---------------------------------------------------------------------------

class TrophyUnlockResult {
  final Trophy3D trophy;
  final bool isNewlyUnlocked;
  final int xpAwarded;

  const TrophyUnlockResult({
    required this.trophy,
    required this.isNewlyUnlocked,
    this.xpAwarded = 0,
  });
}

// ---------------------------------------------------------------------------
// TrophyGalleryStats
// ---------------------------------------------------------------------------

class TrophyGalleryStats {
  final int totalTrophies;
  final int unlockedCount;
  final int commonCount;
  final int rareCount;
  final int epicCount;
  final int legendaryCount;
  final int mythicCount;
  final double completionPercent;

  const TrophyGalleryStats({
    this.totalTrophies = 12,
    this.unlockedCount = 0,
    this.commonCount = 0,
    this.rareCount = 0,
    this.epicCount = 0,
    this.legendaryCount = 0,
    this.mythicCount = 0,
    this.completionPercent = 0.0,
  });

  TrophyGalleryStats copyWith({
    int? totalTrophies,
    int? unlockedCount,
    int? commonCount,
    int? rareCount,
    int? epicCount,
    int? legendaryCount,
    int? mythicCount,
    double? completionPercent,
  }) {
    return TrophyGalleryStats(
      totalTrophies: totalTrophies ?? this.totalTrophies,
      unlockedCount: unlockedCount ?? this.unlockedCount,
      commonCount: commonCount ?? this.commonCount,
      rareCount: rareCount ?? this.rareCount,
      epicCount: epicCount ?? this.epicCount,
      legendaryCount: legendaryCount ?? this.legendaryCount,
      mythicCount: mythicCount ?? this.mythicCount,
      completionPercent: completionPercent ?? this.completionPercent,
    );
  }
}

// ---------------------------------------------------------------------------
// TrophyGalleryState
// ---------------------------------------------------------------------------

class TrophyGalleryState {
  final List<Trophy3D> unlockedTrophies;
  final List<Trophy3D> lockedTrophies;
  final TrophyGalleryStats stats;
  final Trophy3D? selectedTrophy;
  final String? sketchfabViewerUrl;
  final bool isLoading;
  final String? error;

  const TrophyGalleryState({
    this.unlockedTrophies = const [],
    this.lockedTrophies = const [],
    this.stats = const TrophyGalleryStats(),
    this.selectedTrophy,
    this.sketchfabViewerUrl,
    this.isLoading = false,
    this.error,
  });

  TrophyGalleryState copyWith({
    List<Trophy3D>? unlockedTrophies,
    List<Trophy3D>? lockedTrophies,
    TrophyGalleryStats? stats,
    Trophy3D? selectedTrophy,
    String? sketchfabViewerUrl,
    bool? isLoading,
    String? error,
    bool clearSelection = false,
  }) {
    return TrophyGalleryState(
      unlockedTrophies: unlockedTrophies ?? this.unlockedTrophies,
      lockedTrophies: lockedTrophies ?? this.lockedTrophies,
      stats: stats ?? this.stats,
      selectedTrophy: clearSelection ? null : (selectedTrophy ?? this.selectedTrophy),
      sketchfabViewerUrl: sketchfabViewerUrl ?? this.sketchfabViewerUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// TrophyGalleryNotifier
// ---------------------------------------------------------------------------

class TrophyGalleryNotifier extends StateNotifier<TrophyGalleryState> {
  final Ref _ref;

  static const String _sketchfabApiUrl = 'https://api.sketchfab.com/v3';

  static const List<Trophy3D> catalog = [
    // Common (4)
    Trophy3D(
      trophyId: 'neon_seed',
      name: 'Neon Seed',
      descriptionUA: 'Перше заощадження посіяно. Зерно світла у темряві.',
      tier: TrophyTier.common,
      sketchfabModelId: 'neon-seed-v1',
      milestoneAmount: 100,
      achievementTag: 'first_deposit',
    ),
    Trophy3D(
      trophyId: 'pixel_piggy',
      name: 'Pixel Piggy',
      descriptionUA: 'Піксельна свинка-скарбничка. Класика кіберпанк-збережень.',
      tier: TrophyTier.common,
      sketchfabModelId: 'pixel-piggy-v1',
      milestoneAmount: 500,
      achievementTag: 'savings_500',
    ),
    Trophy3D(
      trophyId: 'circuit_coin',
      name: 'Circuit Coin',
      descriptionUA: 'Монета з неоновими ланцюгами. Перша тисяча збережена.',
      tier: TrophyTier.common,
      sketchfabModelId: 'circuit-coin-v1',
      milestoneAmount: 1000,
      achievementTag: 'savings_1k',
    ),
    Trophy3D(
      trophyId: 'data_crystal',
      name: 'Data Crystal',
      descriptionUA: 'Кристал даних. Твій перший стрік завершено.',
      tier: TrophyTier.common,
      sketchfabModelId: 'data-crystal-v1',
      milestoneAmount: 2000,
      achievementTag: 'first_streak',
    ),
    // Rare (3)
    Trophy3D(
      trophyId: 'quantum_vault',
      name: 'Quantum Vault',
      descriptionUA: 'Квантовий сейф відкривається лише для обраних. 10K досягнуто.',
      tier: TrophyTier.rare,
      sketchfabModelId: 'quantum-vault-v1',
      milestoneAmount: 10000,
      achievementTag: 'savings_10k',
      isAnimated: true,
    ),
    Trophy3D(
      trophyId: 'neon_phoenix',
      name: 'Neon Phoenix',
      descriptionUA: 'Неоновий фенікс — воскресив ціль з кладовища!',
      tier: TrophyTier.rare,
      sketchfabModelId: 'neon-phoenix-v1',
      milestoneAmount: 0,
      achievementTag: 'graveyard_resurrection',
      isAnimated: true,
    ),
    Trophy3D(
      trophyId: 'cyber_chalice',
      name: 'Cyber Chalice',
      descriptionUA: 'Кібер-потир. 3 цілі завершено одночасно.',
      tier: TrophyTier.rare,
      sketchfabModelId: 'cyber-chalice-v1',
      milestoneAmount: 20000,
      achievementTag: 'multi_goal',
    ),
    // Epic (2)
    Trophy3D(
      trophyId: 'holo_dragon',
      name: 'Holo Dragon',
      descriptionUA: 'Голограма дракона охороняє твої 50K.',
      tier: TrophyTier.epic,
      sketchfabModelId: 'holo-dragon-v1',
      milestoneAmount: 50000,
      achievementTag: 'savings_50k',
      isAnimated: true,
      hasAR: true,
    ),
    Trophy3D(
      trophyId: 'plasma_crown',
      name: 'Plasma Crown',
      descriptionUA: 'Плазмова корона — ти в топ-3 ліги заощаджень!',
      tier: TrophyTier.epic,
      sketchfabModelId: 'plasma-crown-v1',
      milestoneAmount: 0,
      achievementTag: 'league_top3',
      isAnimated: true,
      hasAR: true,
    ),
    // Legendary (2)
    Trophy3D(
      trophyId: 'cyber_dragon',
      name: 'Cyber Dragon',
      descriptionUA: 'Кібер-дракон! 100K збережено. Ти — легенда.',
      tier: TrophyTier.legendary,
      sketchfabModelId: 'cyber-dragon-v1',
      milestoneAmount: 100000,
      achievementTag: 'savings_100k',
      isAnimated: true,
      hasAR: true,
    ),
    Trophy3D(
      trophyId: 'void_emperor',
      name: 'Void Emperor',
      descriptionUA: 'Імператор Порожнечі. 30-денний стрік без пропуску.',
      tier: TrophyTier.legendary,
      sketchfabModelId: 'void-emperor-v1',
      milestoneAmount: 0,
      achievementTag: 'streak_30',
      isAnimated: true,
      hasAR: true,
    ),
    // Mythic (1)
    Trophy3D(
      trophyId: 'infinity_core',
      name: 'Infinity Core',
      descriptionUA: 'Ядро Вічності. 500K+ збережено. Ти поза часовістю.',
      tier: TrophyTier.mythic,
      sketchfabModelId: 'infinity-core-v1',
      milestoneAmount: 500000,
      achievementTag: 'savings_500k',
      isAnimated: true,
      hasAR: true,
    ),
  ];

  TrophyGalleryNotifier(this._ref) : super(const TrophyGalleryState());

  // =========================================================================
  // Public API
  // =========================================================================

  Future<void> loadGallery() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final database = _ref.read(databaseProvider);
      final entries = await database.getAllTrophyEntries();
      final unlockedIds = entries.map((e) => e.trophyId).toSet();

      final unlocked = <Trophy3D>[];
      final locked = <Trophy3D>[];

      for (final trophy in catalog) {
        if (unlockedIds.contains(trophy.trophyId)) {
          unlocked.add(trophy);
        } else {
          locked.add(trophy);
        }
      }

      state = state.copyWith(
        unlockedTrophies: unlocked,
        lockedTrophies: locked,
        stats: _computeStats(unlocked),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<List<TrophyUnlockResult>> checkForUnlocks(double totalSaved) async {
    final results = <TrophyUnlockResult>[];
    for (final trophy in catalog) {
      if (trophy.milestoneAmount <= 0) continue;
      if (state.unlockedTrophies.any((t) => t.trophyId == trophy.trophyId)) continue;
      if (totalSaved >= trophy.milestoneAmount) {
        results.add(await _unlockTrophy(trophy));
      }
    }
    return results;
  }

  Future<TrophyUnlockResult?> unlockByAchievement(String tag) async {
    if (state.unlockedTrophies.any((t) => t.achievementTag == tag)) return null;
    final trophy = catalog.where((t) => t.achievementTag == tag).firstOrNull;
    if (trophy == null) return null;
    return _unlockTrophy(trophy);
  }

  void selectTrophy(Trophy3D trophy) {
    state = state.copyWith(selectedTrophy: trophy);
    _fetchSketchfabData(trophy.sketchfabModelId);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  // =========================================================================
  // Sketchfab API
  // =========================================================================

  Future<void> _fetchSketchfabData(String modelId) async {
    final apiKey = _ref.read(sketchfabApiKeyProvider);
    if (apiKey.isEmpty) {
      state = state.copyWith(
        sketchfabViewerUrl: 'https://sketchfab.com/models/$modelId/embed',
      );
      return;
    }

    try {
      final uri = Uri.parse('$_sketchfabApiUrl/models/$modelId');
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $apiKey'});

      if (response.statusCode == 200) {
        state = state.copyWith(
          sketchfabViewerUrl: 'https://sketchfab.com/models/$modelId/embed',
        );
      }
    } catch (_) {
      state = state.copyWith(
        sketchfabViewerUrl: 'https://sketchfab.com/models/$modelId/embed',
      );
    }
  }

  // =========================================================================
  // Private
  // =========================================================================

  Future<TrophyUnlockResult> _unlockTrophy(Trophy3D trophy) async {
    final database = _ref.read(databaseProvider);
    final xp = trophy.tier.xpReward;

    await database.insertTrophyEntry(
      TrophyEntriesCompanion.insert(
        trophyId: trophy.trophyId,
        name: trophy.name,
        tier: trophy.tier.name,
        sketchfabModelId: Value(trophy.sketchfabModelId),
        milestoneAmount: Value(trophy.milestoneAmount),
        achievementTag: Value(trophy.achievementTag),
      ),
    );

    await database.addXP(xp, source: 'trophy_${trophy.trophyId}');
    await loadGallery();

    return TrophyUnlockResult(
      trophy: trophy,
      isNewlyUnlocked: true,
      xpAwarded: xp,
    );
  }

  TrophyGalleryStats _computeStats(List<Trophy3D> unlocked) {
    int common = 0, rare = 0, epic = 0, legendary = 0, mythic = 0;
    for (final t in unlocked) {
      switch (t.tier) {
        case TrophyTier.common: common++;
        case TrophyTier.rare: rare++;
        case TrophyTier.epic: epic++;
        case TrophyTier.legendary: legendary++;
        case TrophyTier.mythic: mythic++;
      }
    }
    final total = catalog.length;
    return TrophyGalleryStats(
      totalTrophies: total,
      unlockedCount: unlocked.length,
      commonCount: common,
      rareCount: rare,
      epicCount: epic,
      legendaryCount: legendary,
      mythicCount: mythic,
      completionPercent: total > 0 ? (unlocked.length / total) * 100 : 0.0,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final trophyGalleryProvider =
    StateNotifierProvider<TrophyGalleryNotifier, TrophyGalleryState>(
  (ref) => TrophyGalleryNotifier(ref),
);
