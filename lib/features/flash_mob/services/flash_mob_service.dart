import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// FlashMobEventType — types of flash mob events
// ---------------------------------------------------------------------------

enum FlashMobEventType {
  neonStorm,
  quantumRush,
  cyberBlitz,
  vaultBreaker,
}

extension FlashMobEventTypeX on FlashMobEventType {
  String get titleUA => switch (this) {
        FlashMobEventType.neonStorm => 'Неонова Буря',
        FlashMobEventType.quantumRush => 'Квантовий Руш',
        FlashMobEventType.cyberBlitz => 'Кібер Бліц',
        FlashMobEventType.vaultBreaker => 'Руйнівник Сховища',
      };

  String get descriptionUA => switch (this) {
        FlashMobEventType.neonStorm =>
          'Неонова Буря накриває місто! Множник x1.5 на всі депозити!',
        FlashMobEventType.quantumRush =>
          'Квантовий стрибок! x2 XP за кожен депозит під час Рушу!',
        FlashMobEventType.cyberBlitz =>
          'Кібер Бліц! x3 множник — швидкий як світло!',
        FlashMobEventType.vaultBreaker =>
          'РУЙНІВНИК СХОВИЩА! x5 XP — легендарна подія! Не проґав!',
      };

  double get baseMultiplier => switch (this) {
        FlashMobEventType.neonStorm => 1.5,
        FlashMobEventType.quantumRush => 2.0,
        FlashMobEventType.cyberBlitz => 3.0,
        FlashMobEventType.vaultBreaker => 5.0,
      };

  Duration get typicalDuration => switch (this) {
        FlashMobEventType.neonStorm => const Duration(hours: 2),
        FlashMobEventType.quantumRush => const Duration(minutes: 90),
        FlashMobEventType.cyberBlitz => const Duration(minutes: 60),
        FlashMobEventType.vaultBreaker => const Duration(minutes: 30),
      };

  String get iconEmoji => switch (this) {
        FlashMobEventType.neonStorm => '\u{26C8}\u{FE0F}',
        FlashMobEventType.quantumRush => '\u{26A1}',
        FlashMobEventType.cyberBlitz => '\u{1F4A5}',
        FlashMobEventType.vaultBreaker => '\u{1F525}',
      };
}

// ---------------------------------------------------------------------------
// FlashMobState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class FlashMobState {
  final FlashMobEvent? activeEvent;
  final List<FlashMobEvent> upcomingEvents;
  final List<FlashMobEvent> joinedEvents;
  final bool isJoining;
  final String? error;

  const FlashMobState({
    this.activeEvent,
    this.upcomingEvents = const [],
    this.joinedEvents = const [],
    this.isJoining = false,
    this.error,
  });

  FlashMobState copyWith({
    FlashMobEvent? activeEvent,
    bool clearActiveEvent = false,
    List<FlashMobEvent>? upcomingEvents,
    List<FlashMobEvent>? joinedEvents,
    bool? isJoining,
    String? error,
  }) {
    return FlashMobState(
      activeEvent:
          clearActiveEvent ? null : (activeEvent ?? this.activeEvent),
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      joinedEvents: joinedEvents ?? this.joinedEvents,
      isJoining: isJoining ?? this.isJoining,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// FlashMobNotifier — core logic
// ---------------------------------------------------------------------------

class FlashMobNotifier extends StateNotifier<FlashMobState> {
  final Ref _ref;

  /// Participant thresholds for scaling multiplier.
  static const int _scaleThreshold1 = 25;
  static const int _scaleThreshold2 = 50;
  static const int _scaleThreshold3 = 100;

  FlashMobNotifier(this._ref) : super(const FlashMobState());

  // =========================================================================
  // Public API
  // =========================================================================

  /// Check for active flash mob events in the database.
  Future<void> checkForActiveEvents() async {
    try {
      final database = _ref.read(databaseProvider);
      final allEvents = await database.getAllFlashMobEvents();

      final active = allEvents.where((e) => e.isActive).firstOrNull;
      final upcoming = allEvents
          .where((e) => !e.isActive && !e.isJoined)
          .toList();
      final joined = allEvents.where((e) => e.isJoined).toList();

      state = state.copyWith(
        activeEvent: active,
        upcomingEvents: upcoming,
        joinedEvents: joined,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Join the currently active flash mob event.
  Future<void> joinEvent(String eventId) async {
    state = state.copyWith(isJoining: true, error: null);

    try {
      final database = _ref.read(databaseProvider);
      final event = state.activeEvent;

      if (event == null || event.eventId != eventId) {
        state = state.copyWith(isJoining: false, error: 'Event not found');
        return;
      }

      // Mark as joined and increment participant count
      final updated = event.copyWith(
        isJoined: true,
        participantCount: event.participantCount + 1,
      );

      await database.updateFlashMobEvent(updated);

      // Update joined events list
      final joinedList = List<FlashMobEvent>.from(state.joinedEvents)
        ..add(updated);

      state = state.copyWith(
        activeEvent: updated,
        joinedEvents: joinedList,
        isJoining: false,
      );
    } catch (e) {
      state = state.copyWith(isJoining: false, error: e.toString());
    }
  }

  /// Create a random flash mob event (system/admin trigger).
  Future<void> createRandomEvent() async {
    try {
      final database = _ref.read(databaseProvider);
      final typeIndex = DateTime.now().millisecond % FlashMobEventType.values.length;
      final type = FlashMobEventType.values[typeIndex];

      final now = DateTime.now();
      final endsAt = now.add(type.typicalDuration);
      final eventId = 'flash_${now.millisecondsSinceEpoch}';

      await database.insertFlashMobEvent(
        FlashMobEventsCompanion.insert(
          eventId: eventId,
          titleUA: type.titleUA,
          descriptionUA: type.descriptionUA,
          multiplier: Value(type.baseMultiplier),
          startsAt: now,
          endsAt: endsAt,
          isActive: const Value(true),
        ),
      );

      await checkForActiveEvents();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Complete a flash mob event — award XP to participants.
  Future<void> completeEvent(String eventId) async {
    try {
      final database = _ref.read(databaseProvider);
      final event = state.activeEvent;

      if (event == null || event.eventId != eventId) return;

      // Mark event as inactive
      final updated = event.copyWith(isActive: false);
      await database.updateFlashMobEvent(updated);

      // If user joined, award bonus XP
      if (event.isJoined) {
        final bonusXP = (50 * event.multiplier).round();
        await database.addXP(bonusXP, source: 'flash_mob');
      }

      state = state.copyWith(clearActiveEvent: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Calculate the actual multiplier based on participant count.
  double calculateMultiplier(FlashMobEventType type, int participants) {
    final base = type.baseMultiplier;

    // Scale bonus: more participants = higher multiplier (up to +0.5)
    double scaleBonus = 0.0;
    if (participants >= _scaleThreshold3) {
      scaleBonus = 0.5;
    } else if (participants >= _scaleThreshold2) {
      scaleBonus = 0.3;
    } else if (participants >= _scaleThreshold1) {
      scaleBonus = 0.15;
    }

    return base + scaleBonus;
  }

  /// Time remaining for the active event.
  Duration timeRemaining() {
    final event = state.activeEvent;
    if (event == null) return Duration.zero;

    final remaining = event.endsAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Generate a FOMO message in Ukrainian based on participants and time.
  String fomoMessage() {
    final event = state.activeEvent;
    if (event == null) return '';

    final remaining = timeRemaining();
    final minutes = remaining.inMinutes;
    final participants = event.participantCount;
    final multiplier = calculateMultiplier(
      _typeFromMultiplier(event.multiplier),
      participants,
    );

    if (minutes <= 5) {
      return '\u{1F525} ОСТАННІ $minutes ХВ! ${event.titleUA}! '
          'Множник x${multiplier.toStringAsFixed(1)}! $participants операторів вже тут!';
    } else if (minutes <= 15) {
      return '\u{26A1} ${event.titleUA}! x${multiplier.toStringAsFixed(1)} множник! '
          'Залишилось $minutes хв... $participants операторів приєднались!';
    } else {
      return '\u{2728} ${event.titleUA} активна! Множник x${multiplier.toStringAsFixed(1)}! '
          '$participants операторів вже в справі. Час: $minutes хв.';
    }
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  FlashMobEventType _typeFromMultiplier(double multiplier) {
    if (multiplier >= 5.0) return FlashMobEventType.vaultBreaker;
    if (multiplier >= 3.0) return FlashMobEventType.cyberBlitz;
    if (multiplier >= 2.0) return FlashMobEventType.quantumRush;
    return FlashMobEventType.neonStorm;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final flashMobProvider =
    StateNotifierProvider<FlashMobNotifier, FlashMobState>(
  (ref) => FlashMobNotifier(ref),
);
