import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// NudgeType — types of behavioral nudges
// ---------------------------------------------------------------------------

enum NudgeType {
  lossAversion,
  socialProof,
  endowment,
  achievement,
  scarcity,
  commitment,
}

extension NudgeTypeX on NudgeType {
  String get key => switch (this) {
        NudgeType.lossAversion => 'loss_aversion',
        NudgeType.socialProof => 'social_proof',
        NudgeType.endowment => 'endowment',
        NudgeType.achievement => 'achievement',
        NudgeType.scarcity => 'scarcity',
        NudgeType.commitment => 'commitment',
      };

  String get labelUA => switch (this) {
        NudgeType.lossAversion => 'Відчуття втрати',
        NudgeType.socialProof => 'Соціальний доказ',
        NudgeType.endowment => 'Ефект володіння',
        NudgeType.achievement => 'Досягнення',
        NudgeType.scarcity => 'Дефіцит',
        NudgeType.commitment => 'Зобов\'язання',
      };

  String get iconEmoji => switch (this) {
        NudgeType.lossAversion => '\u{1F4B8}',
        NudgeType.socialProof => '\u{1F465}',
        NudgeType.endowment => '\u{1F512}',
        NudgeType.achievement => '\u{1F3C6}',
        NudgeType.scarcity => '\u{23F0}',
        NudgeType.commitment => '\u{1F91D}',
      };

  /// Default fallback message in Ukrainian for each nudge type.
  String get fallbackMessage => switch (this) {
        NudgeType.lossAversion =>
          'Ти втратиш 500\u{20B4} якщо не внесеш депозит! VAULT-17 фіксує збитки!',
        NudgeType.socialProof =>
          '87% операторів твого рівня вже зробили депозит сьогодні. А ти?',
        NudgeType.endowment =>
          'Твої 12,500\u{20B4} чекають на захист — не дай їм зникнути!',
        NudgeType.achievement =>
          'Лише 1 депозит до нового рівня! Тижууу!',
        NudgeType.scarcity =>
          'Множник x2 доступний лише ще 2 години! Дій зараз!',
        NudgeType.commitment =>
          'Ти обіцяв зібрати 5000\u{20B4} цього місяця. Час діяти.',
      };

  /// Parse a nudge type from its [key] string.
  static NudgeType fromKey(String key) {
    return NudgeType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => NudgeType.lossAversion,
    );
  }
}

// ---------------------------------------------------------------------------
// NudgeLabState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class NudgeLabState {
  final PersuasionProfile? profile;
  final List<NudgeExperiment> activeExperiments;
  final NudgeType? currentNudge;
  final String? nudgeMessage;
  final bool isRunning;
  final String? error;

  const NudgeLabState({
    this.profile,
    this.activeExperiments = const [],
    this.currentNudge,
    this.nudgeMessage,
    this.isRunning = false,
    this.error,
  });

  NudgeLabState copyWith({
    PersuasionProfile? profile,
    List<NudgeExperiment>? activeExperiments,
    NudgeType? currentNudge,
    bool clearCurrentNudge = false,
    String? nudgeMessage,
    bool clearNudgeMessage = false,
    bool? isRunning,
    String? error,
  }) {
    return NudgeLabState(
      profile: profile ?? this.profile,
      activeExperiments: activeExperiments ?? this.activeExperiments,
      currentNudge:
          clearCurrentNudge ? null : (currentNudge ?? this.currentNudge),
      nudgeMessage:
          clearNudgeMessage ? null : (nudgeMessage ?? this.nudgeMessage),
      isRunning: isRunning ?? this.isRunning,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// NudgeLabNotifier — core logic & AI integration
// ---------------------------------------------------------------------------

class NudgeLabNotifier extends StateNotifier<NudgeLabState> {
  final Ref _ref;

  /// Minimum impressions before an experiment can be evaluated.
  static const int _minImpressionsForEval = 10;

  NudgeLabNotifier(this._ref) : super(const NudgeLabState());

  // =========================================================================
  // Public API
  // =========================================================================

  /// Load the persuasion profile and active experiments.
  Future<void> loadProfile() async {
    state = state.copyWith(isRunning: true, error: null);

    try {
      final database = _ref.read(databaseProvider);
      final userProfile = await database.getUserProfile();
      if (userProfile == null) {
        state = state.copyWith(isRunning: false, error: 'User not found');
        return;
      }

      final userId = userProfile.firebaseUid;

      var profile = await database.getPersuasionProfile(userId);

      // Create profile if it doesn't exist
      if (profile == null) {
        await database.insertPersuasionProfile(
          PersuasionProfilesCompanion.insert(
            userId: userId,
          ),
        );
        profile = await database.getPersuasionProfile(userId);
      }

      final experiments = await database.getExperiments(userId);
      final active = experiments.where((e) => e.completedAt == null).toList();

      // Select the best nudge for this user
      final bestNudge = _selectNudgeForUser(experiments);
      String? message;
      if (bestNudge != null) {
        message = bestNudge.fallbackMessage;
      }

      state = state.copyWith(
        profile: profile,
        activeExperiments: active,
        currentNudge: bestNudge,
        nudgeMessage: message,
        isRunning: false,
      );
    } catch (e) {
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  /// Start an A/B experiment for a specific nudge type.
  Future<void> startExperiment(NudgeType type) async {
    try {
      final database = _ref.read(databaseProvider);
      final userProfile = await database.getUserProfile();
      if (userProfile == null) return;

      final userId = userProfile.firebaseUid;
      final variant = DateTime.now().millisecond % 2 == 0 ? 'A' : 'B';

      await database.insertExperiment(
        NudgeExperimentsCompanion.insert(
          userId: userId,
          nudgeType: type.key,
          variant: Value(variant),
        ),
      );

      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Record that the user saw the nudge (impression).
  Future<void> recordImpression(int experimentId) async {
    try {
      final database = _ref.read(databaseProvider);
      final experiments = state.activeExperiments;
      final experiment =
          experiments.where((e) => e.id == experimentId).firstOrNull;
      if (experiment == null) return;

      final updated = experiment.copyWith(
        impressions: experiment.impressions + 1,
      );
      await database.updateExperiment(updated);

      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Record that the user acted on the nudge (conversion).
  Future<void> recordConversion(int experimentId) async {
    try {
      final database = _ref.read(databaseProvider);
      final experiments = state.activeExperiments;
      final experiment =
          experiments.where((e) => e.id == experimentId).firstOrNull;
      if (experiment == null) return;

      final updated = experiment.copyWith(
        conversions: experiment.conversions + 1,
      );
      await database.updateExperiment(updated);

      // Check if experiment has enough data to evaluate
      if (updated.impressions >= _minImpressionsForEval) {
        await _evaluateAndComplete(updated);
      }

      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update the persuasion profile based on all experiment results.
  Future<void> updateProfile() async {
    try {
      final database = _ref.read(databaseProvider);
      final userProfile = await database.getUserProfile();
      if (userProfile == null) return;

      final userId = userProfile.firebaseUid;
      final experiments = await database.getExperiments(userId);

      // Calculate effectiveness scores for each nudge type
      final effectiveness = _calculateEffectiveness(experiments);

      // Find dominant nudge type (highest effectiveness)
      NudgeType dominant = NudgeType.lossAversion;
      double bestScore = -1.0;

      for (final entry in effectiveness.entries) {
        if (entry.value > bestScore) {
          bestScore = entry.value;
          dominant = entry.key;
        }
      }

      // Update the profile
      final profile = state.profile;
      if (profile != null) {
        final updated = profile.copyWith(
          dominantNudgeType: dominant.key,
          effectivenessScores: jsonEncode(
            effectiveness.map((k, v) => MapEntry(k.key, v)),
          ),
          totalExperiments: experiments.length,
          updatedAt: DateTime.now(),
        );
        await database.updatePersuasionProfile(updated);
      }

      await loadProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Generate a personalized nudge message via AI.
  Future<String> generateNudgeMessage(
    NudgeType type, {
    String? context,
  }) async {
    final openRouter = _ref.read(openRouterServiceProvider);

    try {
      final contextLine = context != null ? 'Context: $context' : '';

      final prompt = '''
You are VAULT-17, the AI oracle of NEONCRED. Generate a SHORT behavioral nudge 
message in Ukrainian using the "${type.labelUA}" persuasion technique.

${type.name} technique description:
- ${_techniqueDescription(type)}

$contextLine

The message should:
- Be 1-2 sentences maximum
- Use cyberpunk/sci-fi style with VAULT-17 persona
- Be in Ukrainian
- Be motivating and action-oriented
- Apply the specific persuasion technique

Respond with ONLY the nudge message text, no JSON, no quotes, no markdown.
''';

      final result = await openRouter.chat(
        systemPrompt:
            'You are VAULT-17, a dramatic AI oracle. You write short '
                'behavioral nudge messages in Ukrainian. Respond with '
                'plain text only.',
        userPrompt: prompt,
        temperature: 0.85,
        maxTokens: 100,
      );

      if (result != null && result.trim().isNotEmpty) return result;

      return type.fallbackMessage;
    } catch (_) {
      return type.fallbackMessage;
    }
  }

  // =========================================================================
  // Effectiveness calculation
  // =========================================================================

  /// Calculate effectiveness scores (0.0-1.0) for each nudge type
  /// based on conversion rates across all experiments.
  Map<NudgeType, double> _calculateEffectiveness(
    List<NudgeExperiment> experiments,
  ) {
    final scores = <NudgeType, List<double>>{};

    for (final type in NudgeType.values) {
      scores[type] = [];
    }

    for (final experiment in experiments) {
      if (experiment.impressions < 3) continue; // too few impressions

      final type = NudgeTypeX.fromKey(experiment.nudgeType);
      final rate = experiment.conversions / experiment.impressions;
      scores[type]?.add(rate);
    }

    // Average the conversion rates per nudge type
    final result = <NudgeType, double>{};
    for (final entry in scores.entries) {
      if (entry.value.isEmpty) {
        result[entry.key] = 0.5; // default middle score
      } else {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        result[entry.key] = avg.clamp(0.0, 1.0);
      }
    }

    return result;
  }

  /// Select the best nudge type for this user based on their profile.
  NudgeType? _selectNudgeForUser(List<NudgeExperiment> experiments) {
    final effectiveness = _calculateEffectiveness(experiments);

    NudgeType best = NudgeType.lossAversion;
    double bestScore = -1.0;

    for (final entry in effectiveness.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        best = entry.key;
      }
    }

    return best;
  }

  // =========================================================================
  // Experiment evaluation
  // =========================================================================

  Future<void> _evaluateAndComplete(NudgeExperiment experiment) async {
    try {
      final database = _ref.read(databaseProvider);
      final completed = experiment.copyWith(
        completedAt: Value(DateTime.now()),
      );
      await database.updateExperiment(completed);

      // Update the profile after completing an experiment
      await updateProfile();
    } catch (_) {
      // Silently fail — profile update is non-critical
    }
  }

  // =========================================================================
  // Helpers
  // =========================================================================

  String _techniqueDescription(NudgeType type) {
    return switch (type) {
      NudgeType.lossAversion =>
        'Frame the message as what the user will LOSE if they don\'t act. '
            'People fear losses 2x more than they value gains.',
      NudgeType.socialProof =>
        'Show that many other users are already doing the desired action. '
            'People follow the crowd.',
      NudgeType.endowment =>
        'Remind the user of what they already own and risk losing. '
            'People value what they own more than equivalent gains.',
      NudgeType.achievement =>
        'Highlight proximity to a milestone or reward. '
            'Near-complete goals are more motivating than distant ones.',
      NudgeType.scarcity =>
        'Emphasize limited time or limited availability. '
            'Scarcity increases perceived value.',
      NudgeType.commitment =>
        'Remind the user of their past promises or commitments. '
            'People want to appear consistent.',
    };
  }

}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final nudgeLabProvider =
    StateNotifierProvider<NudgeLabNotifier, NudgeLabState>(
  (ref) => NudgeLabNotifier(ref),
);
