import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/open_router_service.dart';
import '../../data/database.dart';

// ---------------------------------------------------------------------------
// FutureSelfVision — a single vision of the user's future self for one goal
// ---------------------------------------------------------------------------

class FutureSelfVision {
  final String goalId;
  final String goalName;
  final String imagePrompt;
  final double brightness;
  final int daysToMeetFutureSelf;
  final DateTime? targetDate;
  final String visionDescriptionUA;
  final String visionDescriptionEN;
  final Map<String, dynamic> nudgeStats;

  const FutureSelfVision({
    required this.goalId,
    required this.goalName,
    required this.imagePrompt,
    this.brightness = 0.3,
    required this.daysToMeetFutureSelf,
    this.targetDate,
    this.visionDescriptionUA = '',
    this.visionDescriptionEN = '',
    this.nudgeStats = const {},
  });

  FutureSelfVision copyWith({
    String? goalId,
    String? goalName,
    String? imagePrompt,
    double? brightness,
    int? daysToMeetFutureSelf,
    DateTime? targetDate,
    String? visionDescriptionUA,
    String? visionDescriptionEN,
    Map<String, dynamic>? nudgeStats,
  }) {
    return FutureSelfVision(
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      imagePrompt: imagePrompt ?? this.imagePrompt,
      brightness: brightness ?? this.brightness,
      daysToMeetFutureSelf: daysToMeetFutureSelf ?? this.daysToMeetFutureSelf,
      targetDate: targetDate ?? this.targetDate,
      visionDescriptionUA: visionDescriptionUA ?? this.visionDescriptionUA,
      visionDescriptionEN: visionDescriptionEN ?? this.visionDescriptionEN,
      nudgeStats: nudgeStats ?? this.nudgeStats,
    );
  }
}

// ---------------------------------------------------------------------------
// FutureSelfState — state holder for all visions
// ---------------------------------------------------------------------------

class FutureSelfState {
  final Map<String, FutureSelfVision> visions;
  final FutureSelfVision? activeVision;
  final bool isGenerating;
  final String? error;

  const FutureSelfState({
    this.visions = const {},
    this.activeVision,
    this.isGenerating = false,
    this.error,
  });

  FutureSelfState copyWith({
    Map<String, FutureSelfVision>? visions,
    FutureSelfVision? activeVision,
    bool clearActiveVision = false,
    bool? isGenerating,
    String? error,
    bool clearError = false,
  }) {
    return FutureSelfState(
      visions: visions ?? this.visions,
      activeVision:
          clearActiveVision ? null : (activeVision ?? this.activeVision),
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// FutureSelfNotifier — business logic & AI integration
// ---------------------------------------------------------------------------

class FutureSelfNotifier extends StateNotifier<FutureSelfState> {
  final Ref _ref;

  FutureSelfNotifier(this._ref) : super(const FutureSelfState());

  // ---- public API ----------------------------------------------------------

  /// Generate a vivid cyberpunk vision of the user's future self for [goal].
  Future<void> generateVision(Goal goal, List<Deposit> deposits) async {
    state = state.copyWith(isGenerating: true, clearError: true);

    try {
      // Calculate progress & brightness
      final double progress = goal.targetAmount > 0
          ? (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0)
          : 0.0;
      final double brightness = (0.3 + progress * 0.7).clamp(0.0, 1.0);

      // Days remaining
      final int daysToMeetFutureSelf = goal.targetDate != null
          ? goal.targetDate!.difference(DateTime.now()).inDays
          : 365;

      // Nudge stats
      final double totalSaved = deposits.fold<double>(
        0.0,
        (sum, d) => sum + d.amount,
      );
      final double avgDeposit = deposits.isNotEmpty ? totalSaved / deposits.length : 0.0;

      final Map<String, dynamic> nudgeStats = {
        'depositCount': deposits.length,
        'totalSaved': totalSaved,
        'avgDeposit': avgDeposit,
      };

      // Image prompt for future image generation
      final String imagePrompt =
          'Cyberpunk neon-lit future cityscape, person achieving ${goal.name}, '
          'holographic displays showing savings progress at ${(progress * 100).toStringAsFixed(0)}%, '
          'vibrant neon pink and electric blue palette, rain-slicked streets, '
          'determined futuristic silhouette';

      // Generate AI description (Ukrainian)
      String visionDescriptionUA;
      try {
        visionDescriptionUA =
            await _generateAIDescription(goal.name, progress);
      } catch (_) {
        visionDescriptionUA = _localFallbackUA(goal.name, progress);
      }

      // English version — simple deterministic translation
      final String visionDescriptionEN =
          _localFallbackEN(goal.name, progress);

      final vision = FutureSelfVision(
        goalId: goal.id.toString(),
        goalName: goal.name,
        imagePrompt: imagePrompt,
        brightness: brightness,
        daysToMeetFutureSelf: daysToMeetFutureSelf,
        targetDate: goal.targetDate,
        visionDescriptionUA: visionDescriptionUA,
        visionDescriptionEN: visionDescriptionEN,
        nudgeStats: nudgeStats,
      );

      final updatedVisions = Map<String, FutureSelfVision>.from(state.visions);
      updatedVisions[vision.goalId] = vision;

      state = state.copyWith(
        visions: updatedVisions,
        activeVision: vision,
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Помилка генерації бачення: $e',
      );
    }
  }

  /// Dim the vision when the user considers spending.
  void dimVision(String goalId) {
    final vision = state.visions[goalId];
    if (vision == null) return;

    final updatedVision = vision.copyWith(
      brightness: (vision.brightness - 0.12).clamp(0.0, 1.0),
    );

    final updatedVisions = Map<String, FutureSelfVision>.from(state.visions);
    updatedVisions[goalId] = updatedVision;

    final bool isActive = state.activeVision?.goalId == goalId;

    state = state.copyWith(
      visions: updatedVisions,
      activeVision: isActive ? updatedVision : null,
    );
  }

  /// Brighten the vision after a deposit. [depositRatio] is deposit / remaining.
  void brightenVision(String goalId, double depositRatio) {
    final vision = state.visions[goalId];
    if (vision == null) return;

    final double increment = (0.05 + depositRatio * 0.15).clamp(0.05, 0.2);
    final updatedVision = vision.copyWith(
      brightness: (vision.brightness + increment).clamp(0.0, 1.0),
    );

    final updatedVisions = Map<String, FutureSelfVision>.from(state.visions);
    updatedVisions[goalId] = updatedVision;

    final bool isActive = state.activeVision?.goalId == goalId;

    state = state.copyWith(
      visions: updatedVisions,
      activeVision: isActive ? updatedVision : null,
    );
  }

  /// Return a Ukrainian warning message based on current brightness level.
  String getWarningMessage(String goalId) {
    final vision = state.visions[goalId];
    if (vision == null) return '';

    if (vision.brightness < 0.3) {
      return "Future Self зникає... Ти майже втратив зв'язок із собою майбутнім.";
    } else if (vision.brightness < 0.5) {
      return "Твій майбутній я втрачає яскравість! Збережи його — внеси депозит.";
    } else if (vision.brightness < 0.7) {
      return "Майбутній я ще поруч, але потребує твоєї підтримки.";
    }

    return '';
  }

  // ---- private helpers -----------------------------------------------------

  /// Call OpenRouter API for a vivid cyberpunk vision description in Ukrainian.
  Future<String> _generateAIDescription(String goalName, double progress) async {
    final String progressPercent = (progress * 100).toStringAsFixed(0);

    final openRouter = _ref.read(openRouterServiceProvider);

    final String systemPrompt =
        'Ти — AI-наратор кіберпанк-світу NEONCRED. Твориш яскраві, '
        'емоційні описи майбутнього я користувача. Стиль: неоновий кіберпанк, '
        'дощ, голограми, електричні кольори. Мова: українська.';

    final String userPrompt =
        'Опиши 2-3 речення яскравого кіберпанк-бачення: людина досягає мети '
        '"$goalName". Прогрес заощаджень: $progressPercent%. '
        'Зроби опис живим, емоційним, з неоновими деталями. '
        'Використовуй українську мову з кіберпанк-атмосферою.';

    final result = await openRouter.chat(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.9,
      maxTokens: 200,
    );

    if (result != null && result.trim().isNotEmpty) return result;

    // API returned null or empty — fall back
    return _localFallbackUA(goalName, progress);
  }

  // ---- local fallback descriptions -----------------------------------------

  static String _localFallbackUA(String goalName, double progress) {
    if (progress >= 0.8) {
      return "Твій майбутній я стоїть на даху неонового хмарочоса, тримаючи "
          "голограму «$goalName» у руках. Дощ стікає по лінзах, але посмішка "
          "яскравіша за неонові вивіски — мета майже досягнута.";
    } else if (progress >= 0.5) {
      return "Крізь дим і неонове мерехтіння ти бачиш себе — впевненішого, "
          "сильнішого. «$goalName» вже не мрія, а шлях, який вимальовується "
          "лініями електричного синього.";
    } else if (progress >= 0.2) {
      return "Тінь твого майбутнього я ледь проглядає крізь кіберпанк-імерію. "
          "«$goalName» — це маяк у тумані, що стає яскравішим з кожним депозитом.";
    } else {
      return "У темряві неонового міста ледь блимає силует — це ти, який "
          "досяг «$goalName». Але контури розмиті... Збережи його, внеси "
          "перший депозит.";
    }
  }

  static String _localFallbackEN(String goalName, double progress) {
    if (progress >= 0.8) {
      return "Your future self stands on a neon rooftop, holding a hologram "
          "of \"$goalName\". Rain streams down the lenses, but the smile "
          "outshines the neon signs — the goal is almost within reach.";
    } else if (progress >= 0.5) {
      return "Through smoke and neon flicker you see yourself — more confident, "
          "stronger. \"$goalName\" is no longer a dream but a path illuminated "
          "in electric blue.";
    } else if (progress >= 0.2) {
      return "The shadow of your future self barely shows through the "
          "cyberpunk haze. \"$goalName\" is a beacon in the fog, growing "
          "brighter with every deposit.";
    } else {
      return "In the darkness of the neon city a silhouette flickers — "
          "it's you, having achieved \"$goalName\". But the outlines are "
          "blurred... Save the vision, make a deposit.";
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final futureSelfProvider =
    StateNotifierProvider<FutureSelfNotifier, FutureSelfState>(
  (ref) => FutureSelfNotifier(ref),
);
