import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Price Arena -- competitive price finding tournaments with AI commentary
// =============================================================================
//
// Weekly tournaments where users find the lowest price for a product.
// AI validates submissions via SerpAPI and generates cyberpunk commentary.
// XP is awarded to winners; leaderboard tracks all-time stats.
//
// APIs:  SerpAPI Shopping (price validation) + OpenRouter (AI commentary)
//        + Firebase Firestore (tournaments, submissions, leaderboard)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// A price arena tournament for a specific product.
class ArenaTournament {
  final String id;
  final String tournamentId;
  final String productName;
  final String productCategory;
  final double referencePrice; // MSRP or average
  final String startDate;
  final String endDate;
  final bool isActive;
  final List<ArenaSubmission> submissions;
  final ArenaSubmission? winner;
  final int participantCount;
  final String aiCommentary; // AI commentary on results

  const ArenaTournament({
    required this.id,
    required this.tournamentId,
    required this.productName,
    this.productCategory = '',
    this.referencePrice = 0.0,
    this.startDate = '',
    this.endDate = '',
    this.isActive = false,
    this.submissions = const [],
    this.winner,
    this.participantCount = 0,
    this.aiCommentary = '',
  });

  ArenaTournament copyWith({
    List<ArenaSubmission>? submissions,
    ArenaSubmission? winner,
    int? participantCount,
    String? aiCommentary,
    bool? isActive,
  }) {
    return ArenaTournament(
      id: id,
      tournamentId: tournamentId,
      productName: productName,
      productCategory: productCategory,
      referencePrice: referencePrice,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive ?? this.isActive,
      submissions: submissions ?? this.submissions,
      winner: winner ?? this.winner,
      participantCount: participantCount ?? this.participantCount,
      aiCommentary: aiCommentary ?? this.aiCommentary,
    );
  }
}

/// A user's price submission in a tournament.
class ArenaSubmission {
  final String id;
  final String tournamentDbId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double submittedPrice;
  final String storeName;
  final String storeUrl;
  final bool isValid; // AI/SerpAPI verified
  final int xpAwarded;
  final String submittedAt;

  const ArenaSubmission({
    required this.id,
    required this.tournamentDbId,
    this.userId = '',
    this.userName = '',
    this.userAvatar = '',
    this.submittedPrice = 0.0,
    this.storeName = '',
    this.storeUrl = '',
    this.isValid = false,
    this.xpAwarded = 0,
    this.submittedAt = '',
  });
}

/// A leaderboard entry for a user.
class ArenaLeaderboardEntry {
  final String userId;
  final String userName;
  final int tournamentsWon;
  final int totalSubmissions;
  final double totalSavingsFound;
  final int xp;
  final String rank; // "Price Ninja Novice", "Deal Hunter", etc.

  const ArenaLeaderboardEntry({
    required this.userId,
    this.userName = '',
    this.tournamentsWon = 0,
    this.totalSubmissions = 0,
    this.totalSavingsFound = 0.0,
    this.xp = 0,
    this.rank = 'Price Ninja Novice',
  });
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class PriceArenaState {
  final List<ArenaTournament> tournaments;
  final ArenaTournament? activeTournament;
  final List<ArenaLeaderboardEntry> leaderboard;
  final bool isLoading;
  final String? error;
  final int userXp;
  final String userRank;

  const PriceArenaState({
    this.tournaments = const [],
    this.activeTournament,
    this.leaderboard = const [],
    this.isLoading = false,
    this.error,
    this.userXp = 0,
    this.userRank = 'Price Ninja Novice',
  });

  PriceArenaState copyWith({
    List<ArenaTournament>? tournaments,
    ArenaTournament? activeTournament,
    bool clearActiveTournament = false,
    List<ArenaLeaderboardEntry>? leaderboard,
    bool? isLoading,
    String? error,
    int? userXp,
    String? userRank,
  }) {
    return PriceArenaState(
      tournaments: tournaments ?? this.tournaments,
      activeTournament: clearActiveTournament
          ? null
          : (activeTournament ?? this.activeTournament),
      leaderboard: leaderboard ?? this.leaderboard,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userXp: userXp ?? this.userXp,
      userRank: userRank ?? this.userRank,
    );
  }
}



// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class PriceArenaNotifier extends StateNotifier<PriceArenaState> {
  final Ref _ref;

  PriceArenaNotifier(this._ref) : super(const PriceArenaState());

  // ---------------------------------------------------------------------------
  // Fetch active tournament (simulated -- in production from Firebase)
  // ---------------------------------------------------------------------------

  Future<void> fetchActiveTournament() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // In production, this would fetch from Firebase Firestore:
      // final snapshot = await FirebaseFirestore.instance
      //     .collection('tournaments')
      //     .where('isActive', isEqualTo: true)
      //     .limit(1)
      //     .get();

      // Simulated active tournament
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      final tournament = ArenaTournament(
        id: 'arena_${now.millisecondsSinceEpoch}',
        tournamentId: 'week_${now.year}_${_weekOfYear(now)}',
        productName: 'Sony WH-1000XM5',
        productCategory: 'Навушники',
        referencePrice: 14999.0,
        startDate: now.toIso8601String(),
        endDate: weekEnd.toIso8601String(),
        isActive: true,
        participantCount: 0,
        submissions: const [],
      );

      state = state.copyWith(
        activeTournament: tournament,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка завантаження турніру: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Submit a price find to the active tournament
  // ---------------------------------------------------------------------------

  Future<void> submitPrice(
    String tournamentId,
    double price,
    String storeName,
    String storeUrl,
  ) async {
    try {
      final active = state.activeTournament;
      if (active == null) {
        state = state.copyWith(
          error: 'Немає активного турніру',
        );
        return;
      }

      final submissionId =
          'sub_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

      final submission = ArenaSubmission(
        id: submissionId,
        tournamentDbId: active.id,
        userId: 'user_local',
        userName: 'Кібер-мисливець',
        submittedPrice: price,
        storeName: storeName,
        storeUrl: storeUrl,
        isValid: false, // will be validated
        submittedAt: DateTime.now().toIso8601String(),
      );

      // Add submission first as pending
      final updatedSubmissions = [...active.submissions, submission];
      final updatedTournament = active.copyWith(
        submissions: updatedSubmissions,
        participantCount: updatedSubmissions.length,
      );

      state = state.copyWith(activeTournament: updatedTournament);

      // Validate submission via SerpAPI
      await validateSubmission(submission);
    } catch (e) {
      state = state.copyWith(
        error: 'Помилка відправки ціни: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Validate a submission via SerpAPI
  // ---------------------------------------------------------------------------

  Future<void> validateSubmission(ArenaSubmission submission) async {
    final active = state.activeTournament;
    if (active == null) return;

    try {
      bool isValid = false;

      final serpApi = _ref.read(serpApiServiceProvider);
      if (serpApi.isConfigured) {
        final result = await serpApi.searchShoppingRaw(
          active.productName,
        );
        final shoppingResults =
            result['shopping_results'] as List<dynamic>? ?? [];

        // Check if the submitted price is within a reasonable range
        // of prices found on the market
        for (final r in shoppingResults) {
          final priceStr =
              (r['extracted_price'] ?? r['price'] ?? '0').toString();
          final price = double.tryParse(
                  priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ??
              0.0;
          final store =
              (r['store'] ?? r['source'] ?? '').toString();

          // Valid if submitted price is within 20% of a found price
          // and store name matches (partial)
          if (price > 0 &&
              (submission.submittedPrice - price).abs() / price <
                  0.2) {
            isValid = true;
            break;
          }
        }
      } else {
        // Without API key, auto-validate for demo purposes
        isValid = submission.submittedPrice > 0 &&
            submission.submittedPrice < active.referencePrice;
      }

      // Update submission validity
      final updatedSubmissions =
          active.submissions.map((s) {
        if (s.id == submission.id) {
          return ArenaSubmission(
            id: s.id,
            tournamentDbId: s.tournamentDbId,
            userId: s.userId,
            userName: s.userName,
            userAvatar: s.userAvatar,
            submittedPrice: s.submittedPrice,
            storeName: s.storeName,
            storeUrl: s.storeUrl,
            isValid: isValid,
            xpAwarded: isValid ? 25 : 0,
            submittedAt: s.submittedAt,
          );
        }
        return s;
      }).toList();

      // Find the new winner (lowest valid price)
      ArenaSubmission? winner;
      final validSubmissions =
          updatedSubmissions.where((s) => s.isValid).toList();
      if (validSubmissions.isNotEmpty) {
        validSubmissions
            .sort((a, b) => a.submittedPrice.compareTo(b.submittedPrice));
        winner = validSubmissions.first;
      }

      final updatedTournament = active.copyWith(
        submissions: updatedSubmissions,
        winner: winner,
      );

      // Award XP
      if (isValid) {
        final newXp = state.userXp + 25;
        state = state.copyWith(
          activeTournament: updatedTournament,
          userXp: newXp,
          userRank: _computeRank(newXp),
        );
      } else {
        state = state.copyWith(activeTournament: updatedTournament);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Помилка валідації: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // AI commentary on tournament results
  // ---------------------------------------------------------------------------

  Future<void> generateCommentary(ArenaTournament tournament) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      state = state.copyWith(
        error: 'AI недоступний -- API ключ не налаштований',
      );
      return;
    }

    try {
      final winnerPrice = tournament.winner?.submittedPrice ?? 0.0;
      final winnerStore = tournament.winner?.storeName ?? 'Невідомо';
      final savings = tournament.referencePrice > 0 && winnerPrice > 0
          ? ((tournament.referencePrice - winnerPrice) /
                  tournament.referencePrice) *
              100
          : 0.0;

      final prompt =
          'Generate a fun cyberpunk-themed commentary for this Price Arena tournament: '
          'Product=${tournament.productName}, Reference price=${tournament.referencePrice.toStringAsFixed(0)} UAH. '
          'There were ${tournament.participantCount} participants. '
          'The winner found it for ${winnerPrice.toStringAsFixed(0)} UAH at $winnerStore, saving ${savings.toStringAsFixed(1)}%! '
          'Be entertaining and use Ukrainian cyberpunk slang. 3-4 sentences.';

      final result = await openRouter.chat(
        systemPrompt:
            'Ти VAULT-17 -- кіберпанк коментатор Арени Цін NEONCRED. Генеруєш розважальні коментарі українською.',
        userPrompt: prompt,
        temperature: 0.95,
        maxTokens: 256,
      );

      if (result != null) {
        final updatedTournament = tournament.copyWith(
          aiCommentary: result,
        );

        state = state.copyWith(activeTournament: updatedTournament);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Помилка генерації коментаря: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch leaderboard (simulated -- in production from Firebase)
  // ---------------------------------------------------------------------------

  Future<void> fetchLeaderboard() async {
    try {
      // In production, this would fetch from Firebase Firestore:
      // final snapshot = await FirebaseFirestore.instance
      //     .collection('leaderboard')
      //     .orderBy('xp', descending: true)
      //     .limit(20)
      //     .get();

      // Simulated leaderboard
      final leaderboard = <ArenaLeaderboardEntry>[
        const ArenaLeaderboardEntry(
          userId: 'user_1',
          userName: 'NeonShopper',
          tournamentsWon: 12,
          totalSubmissions: 45,
          totalSavingsFound: 28500.0,
          xp: 1250,
          rank: 'Grandmaster',
        ),
        const ArenaLeaderboardEntry(
          userId: 'user_2',
          userName: 'CyberDealHunter',
          tournamentsWon: 8,
          totalSubmissions: 32,
          totalSavingsFound: 19200.0,
          xp: 890,
          rank: 'Price Sensei',
        ),
        const ArenaLeaderboardEntry(
          userId: 'user_3',
          userName: 'GridWalker',
          tournamentsWon: 5,
          totalSubmissions: 21,
          totalSavingsFound: 11800.0,
          xp: 560,
          rank: 'Deal Hunter',
        ),
        const ArenaLeaderboardEntry(
          userId: 'user_4',
          userName: 'VoidScout',
          tournamentsWon: 2,
          totalSubmissions: 14,
          totalSavingsFound: 6500.0,
          xp: 280,
          rank: 'Deal Hunter',
        ),
        const ArenaLeaderboardEntry(
          userId: 'user_local',
          userName: 'Кібер-мисливець',
          tournamentsWon: 0,
          totalSubmissions: 0,
          totalSavingsFound: 0.0,
          xp: 0,
          rank: 'Price Ninja Novice',
        ),
      ];

      // Update current user position
      final currentUserXp = state.userXp;
      final updatedLeaderboard = leaderboard.map((entry) {
        if (entry.userId == 'user_local') {
          return ArenaLeaderboardEntry(
            userId: entry.userId,
            userName: entry.userName,
            tournamentsWon: entry.tournamentsWon,
            totalSubmissions: entry.totalSubmissions,
            totalSavingsFound: entry.totalSavingsFound,
            xp: currentUserXp,
            rank: state.userRank,
          );
        }
        return entry;
      }).toList();

      // Sort by XP descending
      updatedLeaderboard
          .sort((a, b) => b.xp.compareTo(a.xp));

      state = state.copyWith(leaderboard: updatedLeaderboard);
    } catch (e) {
      state = state.copyWith(
        error: 'Помилка завантаження рейтингу: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Create a new tournament (admin function)
  // ---------------------------------------------------------------------------

  Future<void> createTournament(
    String productName,
    double referencePrice,
  ) async {
    try {
      final now = DateTime.now();
      final weekEnd = now.add(const Duration(days: 7));

      final tournament = ArenaTournament(
        id: 'arena_${now.millisecondsSinceEpoch}',
        tournamentId: 'week_${now.year}_${_weekOfYear(now)}',
        productName: productName,
        referencePrice: referencePrice,
        startDate: now.toIso8601String(),
        endDate: weekEnd.toIso8601String(),
        isActive: true,
        participantCount: 0,
        submissions: const [],
      );

      // In production, save to Firebase:
      // await FirebaseFirestore.instance
      //     .collection('tournaments')
      //     .add(tournament.toMap());

      final updatedTournaments = [
        tournament,
        ...state.tournaments.where((t) => t.isActive),
      ];

      state = state.copyWith(
        activeTournament: tournament,
        tournaments: updatedTournaments,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Помилка створення турніру: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Award XP to a user
  // ---------------------------------------------------------------------------

  void awardXp(String userId, int xp) {
    if (userId == 'user_local') {
      final newXp = state.userXp + xp;
      state = state.copyWith(
        userXp: newXp,
        userRank: _computeRank(newXp),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private: compute rank title from XP
  // ---------------------------------------------------------------------------

  String _computeRank(int xp) {
    if (xp >= 1000) return 'Grandmaster';
    if (xp >= 500) return 'Price Sensei';
    if (xp >= 200) return 'Deal Hunter';
    if (xp >= 50) return 'Price Ninja Novice';
    return 'Price Ninja Novice';
  }

  /// Calculate ISO week number of the year.
  static int _weekOfYear(DateTime date) {
    // ISO 8601: week 1 is the week containing the first Thursday of the year
    final jan4 = DateTime(date.year, 1, 4);
    final startOfWeek = jan4.subtract(Duration(days: jan4.weekday - 1));
    return ((date.difference(startOfWeek).inDays) / 7).ceil();
  }
}

// =============================================================================
// Provider
// =============================================================================

final priceArenaProvider =
    StateNotifierProvider<PriceArenaNotifier, PriceArenaState>(
  (ref) => PriceArenaNotifier(ref),
);
