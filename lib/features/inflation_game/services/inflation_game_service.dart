import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';

// =============================================================================
// Anti-Inflation Shield Game — Retention 2026 Feature #10
// =============================================================================
//
// Реал-тайм міні-гра: інфляція "їсть" заощадження візуально (анімація монет
// що тануть). Щоб захиститися — треба робити депозити які "побудовують стіну".
// Чим більше відклав — тим міцніша стіна. Щомісячна інфляція = "хвиля" що
// б'є по стіні. Якщо стіна тримає = XP бонус.
//
// API: Локальні розрахунки (інфляція ввідється вручну або з НБУ)
// XP: +10 за кожну хвилю що тримає, +5 бонус за серію
// =============================================================================

/// Month names in Ukrainian.
const _monthNames = [
  '', 'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
  'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень',
];

/// Rich model for an inflation wave.
class InflationWaveModel {
  final InflationWave data;
  final double wallHealthPercent; // wallStrength vs wallDamage
  final bool isCurrentMonth;
  final int xpPotential; // XP that can be earned

  const InflationWaveModel({
    required this.data,
    this.wallHealthPercent = 0.0,
    this.isCurrentMonth = false,
    this.xpPotential = 10,
  });

  /// Wall is holding (strength > damage).
  bool get isWallHolding => data.wallStrength >= data.wallDamage;

  /// Wall damage as percent of strength.
  double get damagePercent =>
      data.wallStrength > 0 ? (data.wallDamage / data.wallStrength * 100).clamp(0, 100) : 100;

  /// Wall health remaining (0-100%).
  double get healthRemaining =>
      data.wallStrength > 0
          ? ((data.wallStrength - data.wallDamage) / data.wallStrength * 100).clamp(0, 100)
          : 0;

  /// Is the wave still active.
  bool get isActive => data.waveEndAt == null || data.waveEndAt!.isAfter(DateTime.now());

  /// Visual wall segments (0-10 blocks).
  int get wallBlocks => (wallHealthPercent / 10).round().clamp(0, 10);

  /// Inflation damage color severity.
  String get severityLabel {
    final hp = healthRemaining;
    if (hp >= 80) return 'СТІНА ТРИМАЄ';
    if (hp >= 50) return 'ПОШКОДЖЕННЯ';
    if (hp >= 20) return 'КРИТИЧНО';
    return 'ПРОРВА';
  }
}

/// State for the Anti-Inflation Shield Game.
class InflationGameState {
  final List<InflationWaveModel> waves;
  final InflationWaveModel? currentWave;
  final bool isLoading;
  final String? error;
  final int totalWallsHeld;
  final int totalXpEarned;
  final int currentStreak;

  const InflationGameState({
    this.waves = const [],
    this.currentWave,
    this.isLoading = false,
    this.error,
    this.totalWallsHeld = 0,
    this.totalXpEarned = 0,
    this.currentStreak = 0,
  });

  InflationGameState copyWith({
    List<InflationWaveModel>? waves,
    InflationWaveModel? currentWave,
    bool? isLoading,
    String? error,
    int? totalWallsHeld,
    int? totalXpEarned,
    int? currentStreak,
  }) {
    return InflationGameState(
      waves: waves ?? this.waves,
      currentWave: currentWave ?? this.currentWave,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalWallsHeld: totalWallsHeld ?? this.totalWallsHeld,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}

/// StateNotifier for Anti-Inflation Shield Game.
class InflationGameNotifier extends StateNotifier<InflationGameState> {
  final AppDatabase _db;

  InflationGameNotifier(this._db) : super(const InflationGameState());

  /// Loads all inflation waves.
  Future<void> loadWaves() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final allWaves = await _db.getAllInflationWaves();
      final activeWave = await _db.getActiveInflationWave();

      final now = DateTime.now();
      int wallsHeld = 0;
      int xpTotal = 0;
      int streak = 0;

      final models = allWaves.map((w) {
        final healthPercent = w.wallStrength > 0
            ? ((w.wallStrength - w.wallDamage) / w.wallStrength * 100).clamp(0, 100)
            : 0;
        final isCurrent = w.waveStartAt.month == now.month &&
            w.waveStartAt.year == now.year;

        if (w.wallHeld) {
          wallsHeld++;
          streak = w.consecutiveWallsHeld;
        }
        xpTotal += w.xpEarned;

        return InflationWaveModel(
          data: w,
          wallHealthPercent: healthPercent.toDouble(),
          isCurrentMonth: isCurrent,
          xpPotential: 10 + (w.consecutiveWallsHeld * 5),
        );
      }).toList();

      InflationWaveModel? currentModel;
      if (activeWave != null) {
        final healthPercent = activeWave.wallStrength > 0
            ? ((activeWave.wallStrength - activeWave.wallDamage) /
                    activeWave.wallStrength *
                    100)
                .clamp(0, 100)
            : 0;
        currentModel = InflationWaveModel(
          data: activeWave,
          wallHealthPercent: healthPercent.toDouble(),
          isCurrentMonth: true,
        );
      }

      state = state.copyWith(
        waves: models,
        currentWave: currentModel,
        isLoading: false,
        totalWallsHeld: wallsHeld,
        totalXpEarned: xpTotal,
        currentStreak: streak,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Starts a new inflation wave for the current month.
  Future<void> startNewWave({double inflationRate = 7.5}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();
      final waveId = 'IW-${now.year}${now.month.toString().padLeft(2, '0')}';

      // Check if wave already exists for this month
      final existing = await _db.getActiveInflationWave();
      if (existing != null &&
          existing.waveStartAt.month == now.month &&
          existing.waveStartAt.year == now.year) {
        // Wave already exists for this month
        await loadWaves();
        return;
      }

      // Get last month's streak
      final allWaves = await _db.getAllInflationWaves();
      int consecutiveHeld = 0;
      if (allWaves.isNotEmpty) {
        final lastWave = allWaves.last;
        consecutiveHeld = lastWave.consecutiveWallsHeld;
        if (!lastWave.wallHeld) consecutiveHeld = 0;
      }

      // Calculate wall damage based on inflation rate and user's savings
      final user = await _db.getUserProfile();
      final goals = await _db.getActiveGoals();
      final totalSavings = goals.fold<double>(0.0, (sum, g) => sum + g.savedAmount);

      // Inflation erosion = savings * (inflation_rate / 100 / 12)
      final monthlyErosion = totalSavings * (inflationRate / 100 / 12);

      final monthLabel = '${_monthNames[now.month]} ${now.year}';

      await _db.insertInflationWave(InflationWavesCompanion.insert(
        waveId: waveId,
        inflationRate: Value(inflationRate),
        wallDamage: Value(monthlyErosion),
        consecutiveWallsHeld: Value(consecutiveHeld),
        monthLabel: Value(monthLabel),
        waveStartAt: now,
      ));

      await loadWaves();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reinforces the wall by making a deposit (adds to wall strength).
  Future<void> reinforceWall(double depositAmount) async {
    try {
      var activeWave = await _db.getActiveInflationWave();

      // If no active wave, create one
      if (activeWave == null) {
        await startNewWave();
        activeWave = await _db.getActiveInflationWave();
      }

      if (activeWave == null) return;

      final newStrength = activeWave.wallStrength + depositAmount;
      final isHolding = newStrength >= activeWave.wallDamage;

      await _db.updateInflationWave(
        activeWave.id,
        InflationWavesCompanion(
          wallStrength: Value(newStrength),
          wallHeld: Value(isHolding),
        ),
      );

      // Check if wall just became held (milestone)
      if (isHolding && !activeWave.wallHeld) {
        final xpReward = 10 + (activeWave.consecutiveWallsHeld * 5);
        await _db.addXP(xpReward, source: 'inflation_wall_held');
      }

      await loadWaves();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Ends the current wave (month over) and calculates results.
  Future<void> endCurrentWave() async {
    try {
      final activeWave = await _db.getActiveInflationWave();
      if (activeWave == null) return;

      final isHolding = activeWave.wallStrength >= activeWave.wallDamage;
      int newConsecutive = isHolding
          ? activeWave.consecutiveWallsHeld + 1
          : 0;

      final xpReward = isHolding ? 10 + (activeWave.consecutiveWallsHeld * 5) : 0;

      await _db.updateInflationWave(
        activeWave.id,
        InflationWavesCompanion(
          wallHeld: Value(isHolding),
          consecutiveWallsHeld: Value(newConsecutive),
          xpEarned: Value(xpReward),
          waveEndAt: Value(DateTime.now()),
        ),
      );

      if (isHolding) {
        await _db.addXP(xpReward, source: 'inflation_wave_complete');
      }

      await loadWaves();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Sets the inflation rate for the current wave.
  Future<void> setInflationRate(double rate) async {
    try {
      final activeWave = await _db.getActiveInflationWave();
      if (activeWave == null) return;

      // Recalculate damage based on new rate
      final goals = await _db.getActiveGoals();
      final totalSavings = goals.fold<double>(0.0, (sum, g) => sum + g.savedAmount);
      final monthlyErosion = totalSavings * (rate / 100 / 12);

      await _db.updateInflationWave(
        activeWave.id,
        InflationWavesCompanion(
          inflationRate: Value(rate),
          wallDamage: Value(monthlyErosion),
        ),
      );

      await loadWaves();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Deletes a wave record.
  Future<void> deleteWave(int id) async {
    await _db.deleteInflationWave(id);
    await loadWaves();
  }
}

/// Provider for the Anti-Inflation Shield Game.
final inflationGameProvider =
    StateNotifierProvider<InflationGameNotifier, InflationGameState>(
  (ref) {
    final db = ref.read(databaseProvider);
    return InflationGameNotifier(db);
  },
);
