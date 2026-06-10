import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// =============================================================================
// MODELS
// =============================================================================

class HabitLoopItem {
  final String habitId;
  final String name;
  final double dailyAmountUah;
  final String trigger;
  final int currentDay;
  final int targetDays;
  final int streakDays;
  final int longestStreak;
  final double totalSavedUah;
  final bool isActive;
  final bool isCompleted21;
  final DateTime? lastCheckIn;
  final int xpAwarded;
  final DateTime createdAt;

  const HabitLoopItem({
    required this.habitId,
    required this.name,
    required this.dailyAmountUah,
    this.trigger = '',
    this.currentDay = 0,
    this.targetDays = 21,
    this.streakDays = 0,
    this.longestStreak = 0,
    this.totalSavedUah = 0,
    this.isActive = true,
    this.isCompleted21 = false,
    this.lastCheckIn,
    this.xpAwarded = 0,
    required this.createdAt,
  });

  HabitLoopItem copyWith({
    String? habitId,
    String? name,
    double? dailyAmountUah,
    String? trigger,
    int? currentDay,
    int? targetDays,
    int? streakDays,
    int? longestStreak,
    double? totalSavedUah,
    bool? isActive,
    bool? isCompleted21,
    DateTime? lastCheckIn,
    int? xpAwarded,
    DateTime? createdAt,
  }) {
    return HabitLoopItem(
      habitId: habitId ?? this.habitId,
      name: name ?? this.name,
      dailyAmountUah: dailyAmountUah ?? this.dailyAmountUah,
      trigger: trigger ?? this.trigger,
      currentDay: currentDay ?? this.currentDay,
      targetDays: targetDays ?? this.targetDays,
      streakDays: streakDays ?? this.streakDays,
      longestStreak: longestStreak ?? this.longestStreak,
      totalSavedUah: totalSavedUah ?? this.totalSavedUah,
      isActive: isActive ?? this.isActive,
      isCompleted21: isCompleted21 ?? this.isCompleted21,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Progress as 0.0-1.0
  double get progress => (currentDay / targetDays).clamp(0.0, 1.0);

  /// Whether check-in is available today (hasn't checked in today)
  bool get canCheckInToday {
    if (lastCheckIn == null) return true;
    final now = DateTime.now();
    return now.year != lastCheckIn!.year ||
        now.month != lastCheckIn!.month ||
        now.day != lastCheckIn!.day;
  }

  /// Days since last check-in
  int get daysSinceLastCheckIn {
    if (lastCheckIn == null) return currentDay == 0 ? 0 : 999;
    return DateTime.now().difference(lastCheckIn!).inDays;
  }

  /// Whether the streak is broken (missed a day)
  bool get isStreakBroken {
    if (lastCheckIn == null && currentDay > 0) return true;
    if (lastCheckIn == null) return false;
    return daysSinceLastCheckIn > 1;
  }

  /// Ring label like Apple Fitness
  String get ringLabel => '$currentDay/$targetDays';
}

class HabitLoopStats {
  final int activeHabits;
  final int completed21;
  final int longestActiveStreak;
  final double totalSavedAllHabits;
  final bool hasKovalBadge;

  const HabitLoopStats({
    this.activeHabits = 0,
    this.completed21 = 0,
    this.longestActiveStreak = 0,
    this.totalSavedAllHabits = 0,
    this.hasKovalBadge = false,
  });
}

class HabitLoopForgeState {
  final List<HabitLoopItem> habits;
  final bool isLoading;
  final String? error;
  final String? aiSuggestionText;
  final HabitLoopStats stats;

  const HabitLoopForgeState({
    this.habits = const [],
    this.isLoading = false,
    this.error,
    this.aiSuggestionText,
    this.stats = const HabitLoopStats(),
  });

  HabitLoopForgeState copyWith({
    List<HabitLoopItem>? habits,
    bool? isLoading,
    String? error,
    String? aiSuggestionText,
    HabitLoopStats? stats,
  }) {
    return HabitLoopForgeState(
      habits: habits ?? this.habits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      aiSuggestionText: aiSuggestionText,
      stats: stats ?? this.stats,
    );
  }
}

// =============================================================================
// NOTIFIER — Habit Loop Forge Business Logic
// =============================================================================

class HabitLoopForgeNotifier extends StateNotifier<HabitLoopForgeState> {
  final Ref _ref;

  HabitLoopForgeNotifier(this._ref) : super(const HabitLoopForgeState()) {
    _init();
  }

  void _init() {
    // Check for broken streaks on init
    _checkStreaks();
  }

  // ---- Create New Habit ----

  void createHabit({
    required String name,
    required double dailyAmountUah,
    String trigger = '',
    int targetDays = 21,
  }) {
    final now = DateTime.now();
    final habitId = 'HL-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(5, '0')}';

    final habit = HabitLoopItem(
      habitId: habitId,
      name: name.trim(),
      dailyAmountUah: dailyAmountUah,
      trigger: trigger.trim(),
      targetDays: targetDays,
      createdAt: now,
    );

    final newHabits = [habit, ...state.habits];
    state = state.copyWith(
      habits: newHabits,
      stats: _computeStats(newHabits),
      error: null,
    );
  }

  // ---- Daily Check-In ----

  void checkIn(String habitId) {
    final idx = state.habits.indexWhere((h) => h.habitId == habitId);
    if (idx == -1) return;

    final habit = state.habits[idx];
    if (!habit.canCheckInToday || !habit.isActive) return;

    final now = DateTime.now();
    final newCurrentDay = habit.currentDay + 1;
    final newStreakDays = habit.isStreakBroken ? 1 : habit.streakDays + 1;
    final newLongestStreak = newStreakDays > habit.longestStreak ? newStreakDays : habit.longestStreak;
    final newTotalSaved = habit.totalSavedUah + habit.dailyAmountUah;
    final justCompleted21 = !habit.isCompleted21 && newCurrentDay >= habit.targetDays;

    var xpToAward = 5; // +5 XP per daily check-in
    if (justCompleted21) {
      xpToAward += 5 * 21; // x2 bonus: additional 105 XP for 21-day chain
    }

    final updated = habit.copyWith(
      currentDay: newCurrentDay,
      streakDays: newStreakDays,
      longestStreak: newLongestStreak,
      totalSavedUah: newTotalSaved,
      lastCheckIn: now,
      isCompleted21: justCompleted21 || habit.isCompleted21,
      isActive: !justCompleted21, // Auto-complete after 21 days
      xpAwarded: habit.xpAwarded + xpToAward,
    );

    final newHabits = [...state.habits];
    newHabits[idx] = updated;

    state = state.copyWith(
      habits: newHabits,
      stats: _computeStats(newHabits),
    );

    _awardXP(xpToAward, source: justCompleted21 ? 'habit_21_day_chain' : 'habit_daily_checkin');
  }

  // ---- Pause/Resume Habit ----

  void toggleHabit(String habitId) {
    final idx = state.habits.indexWhere((h) => h.habitId == habitId);
    if (idx == -1) return;

    final habit = state.habits[idx];
    final updated = habit.copyWith(isActive: !habit.isActive);

    final newHabits = [...state.habits];
    newHabits[idx] = updated;

    state = state.copyWith(
      habits: newHabits,
      stats: _computeStats(newHabits),
    );
  }

  // ---- Delete Habit ----

  void deleteHabit(String habitId) {
    final newHabits = state.habits.where((h) => h.habitId != habitId).toList();
    state = state.copyWith(
      habits: newHabits,
      stats: _computeStats(newHabits),
    );
  }

  // ---- Check Streaks (detect broken) ----

  void _checkStreaks() {
    bool changed = false;
    final newHabits = [...state.habits];

    for (int i = 0; i < newHabits.length; i++) {
      final habit = newHabits[i];
      if (habit.isActive && habit.isStreakBroken && habit.currentDay > 0) {
        // Reset streak to 0 but keep currentDay
        newHabits[i] = habit.copyWith(streakDays: 0);
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(
        habits: newHabits,
        stats: _computeStats(newHabits),
      );
    }
  }

  // ---- AI Micro-Habit Suggestion ----

  Future<void> generateSuggestion() async {
    state = state.copyWith(isLoading: true);

    try {
      final ai = _ref.read(openRouterServiceProvider);
      final activeHabitsSummary = state.habits
          .where((h) => h.isActive)
          .map((h) => '- ${h.name}: ${h.dailyAmountUah.toStringAsFixed(0)} грн/день, день ${h.currentDay}/${h.targetDays}')
          .join('\n');

      final response = await ai.chat(
        systemPrompt:
            'Ти -- Коваль Звичок. Пропонуй мікро-звички для заощаджень -- маленькі, конкретні дії. '
            'Стиль: кіберпанк-мотиватор. Використовуй українську мову. '
            'Дай 3 мікро-звички у форматі: "Відкладай X грн щодня перед/після Y". '
            'Не додавай зайвих пояснень -- лише 3 рядки.',
        userPrompt:
            'Поточні звички користувача:\n${activeHabitsSummary.isEmpty ? "Жодних активних звичок" : activeHabitsSummary}\n\n'
            'Запропонуй 3 нові мікро-звички для заощаджень в умовах України.',
        temperature: 0.9,
        maxTokens: 300,
      );

      state = state.copyWith(
        isLoading: false,
        aiSuggestionText: response ?? _fallbackSuggestion(),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        aiSuggestionText: _fallbackSuggestion(),
      );
    }
  }

  void clearSuggestion() {
    state = state.copyWith(aiSuggestionText: null);
  }

  // ---- XP Awarding ----

  void _awardXP(int amount, {String source = 'habit_loop_forge'}) {
    try {
      final db = _ref.read(databaseProvider);
      db.addXP(amount, source: source);
    } catch (_) {}
  }

  // ---- Stats Computation ----

  HabitLoopStats _computeStats(List<HabitLoopItem> habits) {
    int activeHabits = 0;
    int completed21 = 0;
    int longestActiveStreak = 0;
    double totalSavedAllHabits = 0;

    for (final h in habits) {
      totalSavedAllHabits += h.totalSavedUah;
      if (h.isActive) {
        activeHabits++;
        if (h.streakDays > longestActiveStreak) {
          longestActiveStreak = h.streakDays;
        }
      }
      if (h.isCompleted21) completed21++;
    }

    return HabitLoopStats(
      activeHabits: activeHabits,
      completed21: completed21,
      longestActiveStreak: longestActiveStreak,
      totalSavedAllHabits: totalSavedAllHabits,
      hasKovalBadge: completed21 >= 3,
    );
  }

  // ---- Clear Error ----

  void clearError() {
    state = state.copyWith(error: null);
  }

  // ---- Fallback Suggestion ----

  String _fallbackSuggestion() {
    return '1. Відкладай 50 грн щодня перед кавою\n'
        '2. Відкладай 100 грн щодня після отримання зарплати\n'
        '3. Відкладай ціну одного еспресо (35 грн) щоразу, коли хочеш купити каву поза домом';
  }
}

// =============================================================================
// PROVIDER
// =============================================================================

final habitLoopForgeProvider =
    StateNotifierProvider<HabitLoopForgeNotifier, HabitLoopForgeState>(
  (ref) => HabitLoopForgeNotifier(ref),
);
