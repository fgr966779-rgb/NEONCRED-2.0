import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';

// ---------------------------------------------------------------------------
// WishlistStatus — lifecycle of a shareable wishlist
// ---------------------------------------------------------------------------

enum WishlistStatus {
  active,
  completed,
  expired,
}

extension WishlistStatusX on WishlistStatus {
  String get labelUA => switch (this) {
        WishlistStatus.active => 'Активний',
        WishlistStatus.completed => 'Завершено',
        WishlistStatus.expired => 'Минув термін',
      };

  String get iconEmoji => switch (this) {
        WishlistStatus.active => '\u{1F31F}',
        WishlistStatus.completed => '\u{1F389}',
        WishlistStatus.expired => '\u{231B}',
      };
}

// ---------------------------------------------------------------------------
// WishlistOccasion — why the wishlist was created
// ---------------------------------------------------------------------------

enum WishlistOccasion {
  birthday,
  holiday,
  justBecause,
}

extension WishlistOccasionX on WishlistOccasion {
  String get labelUA => switch (this) {
        WishlistOccasion.birthday => 'День народження',
        WishlistOccasion.holiday => 'Свято',
        WishlistOccasion.justBecause => 'Просто так',
      };

  String get iconEmoji => switch (this) {
        WishlistOccasion.birthday => '\u{1F382}',
        WishlistOccasion.holiday => '\u{1F384}',
        WishlistOccasion.justBecause => '\u{2728}',
      };
}

// ---------------------------------------------------------------------------
// CrowdFundContribution — a single contribution from a friend
// ---------------------------------------------------------------------------

class CrowdFundContribution {
  final String contributionId;
  final String wishListId;
  final String contributorName;
  final String contributorAvatar;
  final double amount;
  final String message;
  final DateTime createdAt;
  final bool thankYouSent;

  const CrowdFundContribution({
    required this.contributionId,
    required this.wishListId,
    required this.contributorName,
    this.contributorAvatar = '',
    required this.amount,
    this.message = '',
    required this.createdAt,
    this.thankYouSent = false,
  });

  CrowdFundContribution copyWith({
    String? contributionId,
    String? wishListId,
    String? contributorName,
    String? contributorAvatar,
    double? amount,
    String? message,
    DateTime? createdAt,
    bool? thankYouSent,
  }) {
    return CrowdFundContribution(
      contributionId: contributionId ?? this.contributionId,
      wishListId: wishListId ?? this.wishListId,
      contributorName: contributorName ?? this.contributorName,
      contributorAvatar: contributorAvatar ?? this.contributorAvatar,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      thankYouSent: thankYouSent ?? this.thankYouSent,
    );
  }

  /// Formatted amount in UAH.
  String get amountUAH => '${amount.toStringAsFixed(0)} ₴';
}

// ---------------------------------------------------------------------------
// WishlistEntry — a shareable savings wishlist
// ---------------------------------------------------------------------------

class WishlistEntry {
  final String wishListId;
  final int goalId;
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final WishlistOccasion occasion;
  final String shareCode;
  final bool isPublic;
  final List<CrowdFundContribution> contributions;
  final WishlistStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const WishlistEntry({
    required this.wishListId,
    required this.goalId,
    required this.goalName,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.occasion,
    this.shareCode = '',
    this.isPublic = true,
    this.contributions = const [],
    this.status = WishlistStatus.active,
    required this.createdAt,
    required this.expiresAt,
  });

  WishlistEntry copyWith({
    String? wishListId,
    int? goalId,
    String? goalName,
    double? targetAmount,
    double? currentAmount,
    WishlistOccasion? occasion,
    String? shareCode,
    bool? isPublic,
    List<CrowdFundContribution>? contributions,
    WishlistStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return WishlistEntry(
      wishListId: wishListId ?? this.wishListId,
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      occasion: occasion ?? this.occasion,
      shareCode: shareCode ?? this.shareCode,
      isPublic: isPublic ?? this.isPublic,
      contributions: contributions ?? this.contributions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Progress as a fraction 0.0 – 1.0.
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Progress as a percentage string.
  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';

  /// Remaining amount in UAH.
  String get remainingUAH =>
      '${(targetAmount - currentAmount).clamp(0.0, double.infinity).toStringAsFixed(0)} ₴';

  /// Target amount formatted in UAH.
  String get targetAmountUAH => '${targetAmount.toStringAsFixed(0)} ₴';

  /// Current amount formatted in UAH.
  String get currentAmountUAH => '${currentAmount.toStringAsFixed(0)} ₴';

  /// Number of unique friends who contributed.
  int get friendsContributed =>
      contributions.map((c) => c.contributorName).toSet().length;

  /// Whether the wishlist has expired based on current time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether the goal is fully funded.
  bool get isFullyFunded => currentAmount >= targetAmount;

  /// Days remaining until expiration.
  int get daysRemaining =>
      expiresAt.difference(DateTime.now()).inDays.clamp(0, 999);
}

// ---------------------------------------------------------------------------
// CrowdFundStats — aggregate statistics
// ---------------------------------------------------------------------------

class CrowdFundStats {
  final int totalWishlists;
  final int totalContributions;
  final double totalRaised;
  final double biggestContribution;
  final int friendsContributed;

  const CrowdFundStats({
    this.totalWishlists = 0,
    this.totalContributions = 0,
    this.totalRaised = 0.0,
    this.biggestContribution = 0.0,
    this.friendsContributed = 0,
  });

  CrowdFundStats copyWith({
    int? totalWishlists,
    int? totalContributions,
    double? totalRaised,
    double? biggestContribution,
    int? friendsContributed,
  }) {
    return CrowdFundStats(
      totalWishlists: totalWishlists ?? this.totalWishlists,
      totalContributions: totalContributions ?? this.totalContributions,
      totalRaised: totalRaised ?? this.totalRaised,
      biggestContribution:
          biggestContribution ?? this.biggestContribution,
      friendsContributed: friendsContributed ?? this.friendsContributed,
    );
  }

  /// Total raised formatted in UAH.
  String get totalRaisedUAH => '${totalRaised.toStringAsFixed(0)} ₴';

  /// Biggest contribution formatted in UAH.
  String get biggestContributionUAH =>
      '${biggestContribution.toStringAsFixed(0)} ₴';
}

// ---------------------------------------------------------------------------
// CrowdFundState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class CrowdFundState {
  final List<WishlistEntry> wishlists;
  final WishlistEntry? activeWishlist;
  final bool isCreating;
  final bool isLoading;
  final String? error;
  final CrowdFundStats stats;

  const CrowdFundState({
    this.wishlists = const [],
    this.activeWishlist,
    this.isCreating = false,
    this.isLoading = false,
    this.error,
    this.stats = const CrowdFundStats(),
  });

  CrowdFundState copyWith({
    List<WishlistEntry>? wishlists,
    WishlistEntry? activeWishlist,
    bool clearActiveWishlist = false,
    bool? isCreating,
    bool? isLoading,
    String? error,
    CrowdFundStats? stats,
  }) {
    return CrowdFundState(
      wishlists: wishlists ?? this.wishlists,
      activeWishlist: clearActiveWishlist
          ? null
          : (activeWishlist ?? this.activeWishlist),
      isCreating: isCreating ?? this.isCreating,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }

  /// Convenience: active wishlists only.
  List<WishlistEntry> get activeWishlists =>
      wishlists.where((w) => w.status == WishlistStatus.active).toList();

  /// Convenience: completed wishlists only.
  List<WishlistEntry> get completedWishlists =>
      wishlists.where((w) => w.status == WishlistStatus.completed).toList();
}

// ---------------------------------------------------------------------------
// CrowdFundNotifier — core business logic
// ---------------------------------------------------------------------------

class CrowdFundNotifier extends StateNotifier<CrowdFundState> {
  final Ref _ref;

  /// XP awarded when a new wishlist is created.
  static const int xpWishlistCreated = 15;

  /// XP awarded when a contribution is received.
  static const int xpContributionReceived = 5;

  /// XP awarded when a wishlist goal is fully completed.
  static const int xpWishlistCompleted = 50;

  /// Default wishlist lifetime.
  static const Duration defaultExpiry = Duration(days: 30);

  /// In-memory store — will migrate to Firestore.
  final List<WishlistEntry> _wishlistStore = [];

  /// In-memory contributions — will migrate to Firestore.
  final List<CrowdFundContribution> _contributionStore = [];

  CrowdFundNotifier(this._ref) : super(const CrowdFundState());

  // =========================================================================
  // Public API
  // =========================================================================

  /// Load all wishlists from the local store and recompute stats.
  Future<void> loadWishlists() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final database = _ref.read(databaseProvider);

      // Fetch goals from the database so we can cross-reference goal names
      // and amounts.  The wishlists themselves live in-memory for now.
      final goals = await database.getAllGoals();
      final goalMap = {for (final g in goals) g.id: g};

      // Sync currentAmount from database goals into in-memory wishlists
      for (var i = 0; i < _wishlistStore.length; i++) {
        final entry = _wishlistStore[i];
        final goal = goalMap[entry.goalId];
        if (goal != null) {
          _wishlistStore[i] = entry.copyWith(
            currentAmount: goal.savedAmount,
            goalName: goal.name,
            targetAmount: goal.targetAmount,
          );
        }
        // Auto-expire
        if (_wishlistStore[i].status == WishlistStatus.active &&
            _wishlistStore[i].isExpired) {
          _wishlistStore[i] = _wishlistStore[i].copyWith(
            status: WishlistStatus.expired,
          );
        }
      }

      // Rebuild contributions from store (attach to correct wishlists)
      final rebuilt = _wishlistStore.map((w) {
        final contribs = _contributionStore
            .where((c) => c.wishListId == w.wishListId)
            .toList();
        return w.copyWith(contributions: contribs);
      }).toList();

      state = state.copyWith(
        wishlists: rebuilt,
        stats: _computeStats(rebuilt),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new wishlist linked to an existing savings goal.
  Future<WishlistEntry?> createWishlist(
    int goalId,
    String occasion,
  ) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final database = _ref.read(databaseProvider);
      final goals = await database.getAllGoals();
      final goal = goals.where((g) => g.id == goalId).firstOrNull;

      if (goal == null) {
        state = state.copyWith(
          isCreating: false,
          error: 'Ціль не знайдено',
        );
        return null;
      }

      final now = DateTime.now();
      final wishListId = 'wl_${now.millisecondsSinceEpoch}';
      final shareCode = _generateShareCode();

      final parsedOccasion = WishlistOccasion.values.firstWhere(
        (o) => o.name == occasion,
        orElse: () => WishlistOccasion.justBecause,
      );

      final entry = WishlistEntry(
        wishListId: wishListId,
        goalId: goalId,
        goalName: goal.name,
        targetAmount: goal.targetAmount,
        currentAmount: goal.savedAmount,
        occasion: parsedOccasion,
        shareCode: shareCode,
        isPublic: true,
        contributions: const [],
        status: WishlistStatus.active,
        createdAt: now,
        expiresAt: now.add(defaultExpiry),
      );

      _wishlistStore.add(entry);

      // Award XP for creating a wishlist
      await database.addXP(xpWishlistCreated, source: 'crowd_fund_create');

      // Firestore placeholder — persist to cloud when integrated
      await _firestorePlaceholderUpsert(entry);

      final updatedList = List<WishlistEntry>.from(state.wishlists)..add(entry);

      state = state.copyWith(
        wishlists: updatedList,
        activeWishlist: entry,
        isCreating: false,
        stats: _computeStats(updatedList),
      );

      return entry;
    } catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }

  /// Generate (or regenerate) a share code for the given wishlist.
  Future<String> shareWishlist(String wishListId) async {
    try {
      final index =
          _wishlistStore.indexWhere((w) => w.wishListId == wishListId);
      if (index == -1) {
        state = state.copyWith(error: 'Вішліст не знайдено');
        return '';
      }

      final newShareCode = _generateShareCode();
      _wishlistStore[index] = _wishlistStore[index].copyWith(
        shareCode: newShareCode,
        isPublic: true,
      );

      // Firestore placeholder
      await _firestorePlaceholderUpsert(_wishlistStore[index]);

      final updatedList = List<WishlistEntry>.from(state.wishlists);
      final listIndex =
          updatedList.indexWhere((w) => w.wishListId == wishListId);
      if (listIndex != -1) {
        updatedList[listIndex] = _wishlistStore[index];
      }

      state = state.copyWith(
        wishlists: updatedList,
        activeWishlist: _wishlistStore[index],
      );

      return newShareCode;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return '';
    }
  }

  /// Add a contribution from a friend to a wishlist.
  Future<CrowdFundContribution?> addContribution(
    String wishListId,
    String contributorName,
    double amount,
    String message,
  ) async {
    try {
      final database = _ref.read(databaseProvider);
      final wlIndex =
          _wishlistStore.indexWhere((w) => w.wishListId == wishListId);

      if (wlIndex == -1) {
        state = state.copyWith(error: 'Вішліст не знайдено');
        return null;
      }

      if (amount <= 0) {
        state = state.copyWith(error: 'Сума має бути більшою за 0 ₴');
        return null;
      }

      final wishlist = _wishlistStore[wlIndex];

      if (wishlist.status != WishlistStatus.active) {
        state = state.copyWith(
          error: 'Неможливо додати внесок до неактивного вішлісту',
        );
        return null;
      }

      final now = DateTime.now();
      final contributionId = 'contrib_${now.millisecondsSinceEpoch}';

      final contribution = CrowdFundContribution(
        contributionId: contributionId,
        wishListId: wishListId,
        contributorName: contributorName,
        amount: amount,
        message: message,
        createdAt: now,
      );

      _contributionStore.add(contribution);

      // Update the wishlist current amount
      final newCurrentAmount = wishlist.currentAmount + amount;
      final updatedContribs = List<CrowdFundContribution>.from(
        wishlist.contributions,
      )..add(contribution);

      _wishlistStore[wlIndex] = wishlist.copyWith(
        currentAmount: newCurrentAmount,
        contributions: updatedContribs,
      );

      // If the goal is now fully funded, auto-complete
      if (newCurrentAmount >= wishlist.targetAmount) {
        _wishlistStore[wlIndex] = _wishlistStore[wlIndex].copyWith(
          status: WishlistStatus.completed,
        );
        await database.addXP(xpWishlistCompleted, source: 'crowd_fund_complete');
      }

      // Award XP for receiving a contribution
      await database.addXP(xpContributionReceived, source: 'crowd_fund_contribution');

      // Also add a deposit to the underlying goal in the database
      final goals = await database.getAllGoals();
      final goal = goals.where((g) => g.id == wishlist.goalId).firstOrNull;
      if (goal != null) {
        await database.addXP(0, source: 'crowd_fund_deposit_sync');
        // Note: actual deposit insertion would go through the deposit table
        // when the full Drift schema includes crowd_fund contributions.
      }

      // Firestore placeholder
      await _firestorePlaceholderAddContribution(contribution);

      final updatedList = List<WishlistEntry>.from(state.wishlists);
      final listIdx =
          updatedList.indexWhere((w) => w.wishListId == wishListId);
      if (listIdx != -1) {
        updatedList[listIdx] = _wishlistStore[wlIndex];
      }

      state = state.copyWith(
        wishlists: updatedList,
        activeWishlist: _wishlistStore[wlIndex],
        stats: _computeStats(updatedList),
      );

      return contribution;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Send an auto thank-you message for a contribution.
  Future<void> sendThankYouMessage(String contributionId) async {
    try {
      final cIndex = _contributionStore.indexWhere(
        (c) => c.contributionId == contributionId,
      );
      if (cIndex == -1) {
        state = state.copyWith(error: 'Внесок не знайдено');
        return;
      }

      // Mark as thanked
      _contributionStore[cIndex] = _contributionStore[cIndex].copyWith(
        thankYouSent: true,
      );

      // Update the contribution inside the relevant wishlist
      final wishListId = _contributionStore[cIndex].wishListId;
      final wlIndex =
          _wishlistStore.indexWhere((w) => w.wishListId == wishListId);
      if (wlIndex != -1) {
        final contribs = List<CrowdFundContribution>.from(
          _wishlistStore[wlIndex].contributions,
        );
        final innerIdx = contribs.indexWhere(
          (c) => c.contributionId == contributionId,
        );
        if (innerIdx != -1) {
          contribs[innerIdx] = _contributionStore[cIndex];
          _wishlistStore[wlIndex] = _wishlistStore[wlIndex].copyWith(
            contributions: contribs,
          );
        }
      }

      // Firestore placeholder — send notification to contributor
      await _firestorePlaceholderSendThankYou(contributionId);

      final updatedList = List<WishlistEntry>.from(state.wishlists);
      final listIdx =
          updatedList.indexWhere((w) => w.wishListId == wishListId);
      if (listIdx != -1 && wlIndex != -1) {
        updatedList[listIdx] = _wishlistStore[wlIndex];
      }

      state = state.copyWith(
        wishlists: updatedList,
        activeWishlist: wlIndex != -1 ? _wishlistStore[wlIndex] : null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Manually mark a wishlist as completed (e.g. user achieved the goal).
  Future<void> markWishlistCompleted(String wishListId) async {
    try {
      final database = _ref.read(databaseProvider);
      final index =
          _wishlistStore.indexWhere((w) => w.wishListId == wishListId);

      if (index == -1) {
        state = state.copyWith(error: 'Вішліст не знайдено');
        return;
      }

      if (_wishlistStore[index].status == WishlistStatus.completed) {
        return; // Already completed
      }

      _wishlistStore[index] = _wishlistStore[index].copyWith(
        status: WishlistStatus.completed,
      );

      // Award completion XP
      await database.addXP(xpWishlistCompleted, source: 'crowd_fund_complete');

      // Firestore placeholder
      await _firestorePlaceholderUpsert(_wishlistStore[index]);

      final updatedList = List<WishlistEntry>.from(state.wishlists);
      final listIdx =
          updatedList.indexWhere((w) => w.wishListId == wishListId);
      if (listIdx != -1) {
        updatedList[listIdx] = _wishlistStore[index];
      }

      state = state.copyWith(
        wishlists: updatedList,
        activeWishlist: _wishlistStore[index],
        stats: _computeStats(updatedList),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Generate a deep-link that friends can tap to contribute.
  String generateShareLink(String wishListId) {
    final wishlist = _wishlistStore
        .where((w) => w.wishListId == wishListId)
        .firstOrNull;

    if (wishlist == null) return '';

    final code = wishlist.shareCode.isEmpty
        ? _generateShareCode()
        : wishlist.shareCode;

    // Placeholder deep-link format; will integrate with Firebase Dynamic Links
    return 'https://neoncred.app/crowd-fund/$code';
  }

  /// Find a wishlist by its share code (for contributors landing via link).
  WishlistEntry? findByShareCode(String shareCode) {
    return _wishlistStore
        .where((w) => w.shareCode == shareCode)
        .firstOrNull;
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  /// Generate a random 8-character alphanumeric share code.
  String _generateShareCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Compute aggregate stats from the full list of wishlists.
  CrowdFundStats _computeStats(List<WishlistEntry> wishlists) {
    final allContributions = wishlists
        .expand((w) => w.contributions)
        .toList();

    final totalRaised = allContributions.fold<double>(
      0.0,
      (sum, c) => sum + c.amount,
    );

    final biggest = allContributions.fold<double>(
      0.0,
      (max, c) => c.amount > max ? c.amount : max,
    );

    final uniqueFriends = allContributions
        .map((c) => c.contributorName)
        .toSet()
        .length;

    return CrowdFundStats(
      totalWishlists: wishlists.length,
      totalContributions: allContributions.length,
      totalRaised: totalRaised,
      biggestContribution: biggest,
      friendsContributed: uniqueFriends,
    );
  }

  // =========================================================================
  // Firestore placeholders — to be replaced with real integration
  // =========================================================================

  /// Placeholder: upsert a wishlist document to Firestore.
  Future<void> _firestorePlaceholderUpsert(WishlistEntry entry) async {
    // TODO: Implement Firestore integration
    // final firestore = FirebaseFirestore.instance;
    // await firestore
    //     .collection('crowd_fund_wishlists')
    //     .doc(entry.wishListId)
    //     .set(entry.toJson());
  }

  /// Placeholder: add a contribution sub-document to Firestore.
  Future<void> _firestorePlaceholderAddContribution(
    CrowdFundContribution contribution,
  ) async {
    // TODO: Implement Firestore integration
    // final firestore = FirebaseFirestore.instance;
    // await firestore
    //     .collection('crowd_fund_wishlists')
    //     .doc(contribution.wishListId)
    //     .collection('contributions')
    //     .doc(contribution.contributionId)
    //     .set(contribution.toJson());
  }

  /// Placeholder: send a thank-you notification via Firestore.
  Future<void> _firestorePlaceholderSendThankYou(
    String contributionId,
  ) async {
    // TODO: Implement Firestore integration
    // final firestore = FirebaseFirestore.instance;
    // await firestore
    //     .collection('crowd_fund_thank_yous')
    //     .doc()
    //     .set({
    //   'contributionId': contributionId,
    //   'sentAt': FieldValue.serverTimestamp(),
    //   'message': 'Дякую за твій внесок!',
    // });
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final crowdFundProvider =
    StateNotifierProvider<CrowdFundNotifier, CrowdFundState>(
  (ref) => CrowdFundNotifier(ref),
);
