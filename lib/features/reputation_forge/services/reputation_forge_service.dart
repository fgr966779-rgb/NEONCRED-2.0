import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// Reputation title thresholds
// ---------------------------------------------------------------------------

enum ReputationTier {
  neonInitiate, // 0 – 25
  circuitRunner, // 25 – 50
  dataSentinel, // 50 – 75
  neonGuardian, // 75 – 90
  vaultLegend, // 90 – 100
}

extension ReputationTierX on ReputationTier {
  String get titleUA => switch (this) {
        ReputationTier.neonInitiate => 'Неоновий Ініціат',
        ReputationTier.circuitRunner => 'Бігун Схем',
        ReputationTier.dataSentinel => 'Сентинел Даних',
        ReputationTier.neonGuardian => 'Неоновий Вартовий',
        ReputationTier.vaultLegend => 'Легенда Сховища',
      };

  String get iconEmoji => switch (this) {
        ReputationTier.neonInitiate => '\u{1F531}',
        ReputationTier.circuitRunner => '\u{26A1}',
        ReputationTier.dataSentinel => '\u{1F6E1}\u{FE0F}',
        ReputationTier.neonGuardian => '\u{1F48E}',
        ReputationTier.vaultLegend => '\u{1F451}',
      };

  double get minScore => switch (this) {
        ReputationTier.neonInitiate => 0,
        ReputationTier.circuitRunner => 25,
        ReputationTier.dataSentinel => 50,
        ReputationTier.neonGuardian => 75,
        ReputationTier.vaultLegend => 90,
      };
}

// ---------------------------------------------------------------------------
// ReputationForgeState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class ReputationForgeState {
  final ReputationProfile? profile;
  final List<PublicCommitment> activeCommitments;
  final bool isLoading;
  final String? error;

  const ReputationForgeState({
    this.profile,
    this.activeCommitments = const [],
    this.isLoading = false,
    this.error,
  });

  ReputationForgeState copyWith({
    ReputationProfile? profile,
    List<PublicCommitment>? activeCommitments,
    bool? isLoading,
    String? error,
    bool clearProfile = false,
  }) {
    return ReputationForgeState(
      profile: clearProfile ? null : (profile ?? this.profile),
      activeCommitments: activeCommitments ?? this.activeCommitments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// ReputationForgeNotifier — core logic & AI integration
// ---------------------------------------------------------------------------

class ReputationForgeNotifier extends StateNotifier<ReputationForgeState> {
  final Ref _ref;

  ReputationForgeNotifier(this._ref)
      : super(const ReputationForgeState());

  // =========================================================================
  // Public API
  // =========================================================================

  /// Load the reputation profile and active commitments from the database.
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final database = _ref.read(databaseProvider);
      final userProfile = await database.getUserProfile();

      if (userProfile == null) {
        state = state.copyWith(isLoading: false, error: 'User not found');
        return;
      }

      final userId = userProfile.firebaseUid;
      var profile = await database.getReputationProfile(userId);

      // Create profile if it doesn't exist yet
      if (profile == null) {
        await database.insertReputationProfile(
          ReputationProfilesCompanion.insert(
            userId: userId,
          ),
        );
        profile = await database.getReputationProfile(userId);
      }

      final commitments = await database.getActiveCommitments(userId);

      state = state.copyWith(
        profile: profile,
        activeCommitments: commitments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new public commitment tied to a goal.
  Future<void> createCommitment(
    int goalId,
    String commitmentText,
    int stakeKarma,
    DateTime deadline,
  ) async {
    try {
      final database = _ref.read(databaseProvider);
      final userProfile = await database.getUserProfile();
      if (userProfile == null) return;

      final userId = userProfile.firebaseUid;

      await database.insertCommitment(
        PublicCommitmentsCompanion.insert(
          userId: userId,
          goalId: goalId,
          commitmentText: commitmentText,
          deadlineDate: deadline,
          stakeKarma: Value(stakeKarma),
        ),
      );

      // Update profile commitment count
      final profile = state.profile;
      if (profile != null) {
        final updated = profile.copyWith(
          publicCommitmentsCount: profile.publicCommitmentsCount + 1,
          updatedAt: DateTime.now(),
        );
        await database.updateReputationProfile(updated);
      }

      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Fulfill a commitment — boosts reputation.
  Future<void> fulfillCommitment(int commitmentId) async {
    try {
      final database = _ref.read(databaseProvider);
      final commitments = state.activeCommitments;
      final commitment = commitments.where((c) => c.id == commitmentId).firstOrNull;
      if (commitment == null) return;

      final updated = commitment.copyWith(
        isFulfilled: true,
      );
      await database.updateCommitment(updated);

      // Update profile — boost reputation
      final profile = state.profile;
      if (profile != null) {
        final newFulfilled = profile.fulfilledCommitmentsCount + 1;
        final newScore = _calculateReputationScore(
          profile.publicCommitmentsCount,
          newFulfilled,
          profile.circleReliability,
          profile.karmaContribution,
        );
        final newTitle = _determineTitle(newScore);

        final updatedProfile = profile.copyWith(
          fulfilledCommitmentsCount: newFulfilled,
          reputationScore: newScore,
          title: Value(newTitle),
          updatedAt: DateTime.now(),
        );
        await database.updateReputationProfile(updatedProfile);

        // Award XP for fulfilling commitment
        await database.addXP(100, source: 'commitment_fulfilled');
      }

      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Fail a commitment — deducts karma, reduces reputation.
  Future<void> failCommitment(int commitmentId) async {
    try {
      final database = _ref.read(databaseProvider);
      final commitments = state.activeCommitments;
      final commitment = commitments.where((c) => c.id == commitmentId).firstOrNull;
      if (commitment == null) return;

      // Deduct staked karma
      final profile = state.profile;
      if (profile != null && commitment.stakeKarma > 0) {
        final newScore = (profile.reputationScore - commitment.stakeKarma * 0.5)
            .clamp(0.0, 100.0);
        final newTitle = _determineTitle(newScore);

        final updatedProfile = profile.copyWith(
          reputationScore: newScore,
          title: Value(newTitle),
          karmaContribution:
              (profile.karmaContribution - commitment.stakeKarma * 0.1)
                  .clamp(0.0, double.infinity),
          updatedAt: DateTime.now(),
        );
        await database.updateReputationProfile(updatedProfile);
      }

      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Generate a dramatic AI commitment nudge in Ukrainian.
  Future<String> generateCommitmentNudge(
    String goalName,
    double targetAmount,
  ) async {
    final openRouter = _ref.read(openRouterServiceProvider);

    try {
      final prompt = '''
You are VAULT-17, the AI oracle of NEONCRED. Generate a DRAMATIC PUBLIC COMMITMENT 
declaration in Ukrainian for a user who wants to save $targetAmount UAH for "$goalName".

The declaration should:
- Be 2-3 sentences, cyberpunk/sci-fi style
- Use VAULT-17 persona (AI oracle, system references)
- Include stakes ("if I break my word, my karma burns in neon fire")
- Be dramatic and memorable
- Use Ukrainian language

Example tone: "Я, Оператор NEXUS-7, публічно клянусь зібрати 5000₴ на MacBook Pro до 15 березня. Якщо зламаю слово — нехай мій карма згорить у неоновому вогні!"

Respond with ONLY the declaration text, no JSON, no quotes, no markdown.
''';

      final result = await openRouter.chat(
        systemPrompt:
            'You are VAULT-17, a dramatic AI oracle. You write cyberpunk commitment '
                'declarations in Ukrainian. Respond with plain text only.',
        userPrompt: prompt,
        temperature: 0.9,
        maxTokens: 200,
      );

      if (result != null && result.trim().isNotEmpty) return result;

      return _fallbackNudge(goalName);
    } catch (_) {
      return _fallbackNudge(goalName);
    }
  }

  /// Get the current reputation tier based on score.
  ReputationTier get currentTier {
    final score = state.profile?.reputationScore ?? 0;
    return _tierFromScore(score);
  }

  // =========================================================================
  // Scoring & Title logic
  // =========================================================================

  double _calculateReputationScore(
    int totalCommitments,
    int fulfilledCommitments,
    double circleReliability,
    double karmaContribution,
  ) {
    // Base score from commitment fulfillment ratio
    final fulfillmentRatio =
        totalCommitments > 0 ? fulfilledCommitments / totalCommitments : 0.5;

    // Weighted score components
    final commitmentScore = fulfillmentRatio * 60; // 0-60 points
    final circleScore = circleReliability * 25; // 0-25 points
    final karmaScore = (karmaContribution / 100).clamp(0.0, 1.0) * 15; // 0-15 points

    final totalScore = commitmentScore + circleScore + karmaScore;
    return totalScore.clamp(0.0, 100.0);
  }

  String _determineTitle(double score) {
    return _tierFromScore(score).titleUA;
  }

  ReputationTier _tierFromScore(double score) {
    if (score >= 90) return ReputationTier.vaultLegend;
    if (score >= 75) return ReputationTier.neonGuardian;
    if (score >= 50) return ReputationTier.dataSentinel;
    if (score >= 25) return ReputationTier.circuitRunner;
    return ReputationTier.neonInitiate;
  }

  // =========================================================================
  // Fallback & Utility
  // =========================================================================

  String _fallbackNudge(String goalName) {
    return 'Я публічно клянусь зібрати на "$goalName"! '
        'Якщо зламаю слово — нехай мій карма згорить у неоновому вогні VAULT-17!';
  }

}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final reputationForgeProvider =
    StateNotifierProvider<ReputationForgeNotifier, ReputationForgeState>(
  (ref) => ReputationForgeNotifier(ref),
);
