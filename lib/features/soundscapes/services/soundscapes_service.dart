import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Deposit Soundscapes — Sound design for deposits in NEONCRED
// =============================================================================
//
// Every deposit triggers a unique cyberpunk sound effect based on amount.
// Users unlock new sounds, collect them, and can set a default deposit
// sound. Streaks and jackpots get escalating, epic audio feedback.
// AI generates custom sound descriptions tied to goals.
//
// Currency: UAH (грн). All text in Ukrainian.
// XP: +5 per sound unlocked, +2 per deposit sound played.
//
// API: OpenRouter (custom sound description generation)
// =============================================================================

// -----------------------------------------------------------------------------
// SoundTier — tier based on deposit amount
// -----------------------------------------------------------------------------

/// Sound tier determined by deposit amount in UAH.
enum SoundTier {
  tiny('tiny', 'Краплина', 0, 100),
  small('small', 'Іскра', 100, 500),
  medium('medium', 'Імпульс', 500, 2000),
  large('large', 'Вибух', 2000, 10000),
  epic('epic', 'Симфонія', 10000, double.infinity),
  jackpot('jackpot', 'Джекпот', double.infinity, double.infinity);

  final String id;
  final String labelUA;
  final double minAmount;
  final double maxAmount;

  const SoundTier(this.id, this.labelUA, this.minAmount, this.maxAmount);

  /// Determine tier from deposit amount.
  static SoundTier fromAmount(double amount) {
    if (amount < 0) return SoundTier.tiny;
    if (amount < 100) return SoundTier.tiny;
    if (amount < 500) return SoundTier.small;
    if (amount < 2000) return SoundTier.medium;
    if (amount < 10000) return SoundTier.large;
    return SoundTier.epic;
  }

  /// Emoji for visual display.
  String get emoji => switch (this) {
        SoundTier.tiny => '💧',
        SoundTier.small => '⚡',
        SoundTier.medium => '🔊',
        SoundTier.large => '💥',
        SoundTier.epic => '🎼',
        SoundTier.jackpot => '🎰',
      };
}

// -----------------------------------------------------------------------------
// SoundEffect
// -----------------------------------------------------------------------------

/// A single sound effect in the deposit soundscape catalog.
class SoundEffect {
  final String soundId;
  final String nameUA;
  final String descriptionUA;
  final SoundTier tier;
  final int frequencyHz;
  final int durationMs;
  final bool isUnlocked;
  final String? unlockRequirement;
  final String sketchfabModelId;

  const SoundEffect({
    required this.soundId,
    required this.nameUA,
    required this.descriptionUA,
    required this.tier,
    required this.frequencyHz,
    required this.durationMs,
    this.isUnlocked = false,
    this.unlockRequirement,
    this.sketchfabModelId = '',
  });

  SoundEffect copyWith({
    String? soundId,
    String? nameUA,
    String? descriptionUA,
    SoundTier? tier,
    int? frequencyHz,
    int? durationMs,
    bool? isUnlocked,
    String? unlockRequirement,
    String? sketchfabModelId,
  }) {
    return SoundEffect(
      soundId: soundId ?? this.soundId,
      nameUA: nameUA ?? this.nameUA,
      descriptionUA: descriptionUA ?? this.descriptionUA,
      tier: tier ?? this.tier,
      frequencyHz: frequencyHz ?? this.frequencyHz,
      durationMs: durationMs ?? this.durationMs,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      sketchfabModelId: sketchfabModelId ?? this.sketchfabModelId,
    );
  }

  /// Human-readable frequency label.
  String get frequencyLabel => '${frequencyHz} Гц';

  /// Human-readable duration label.
  String get durationLabel => '${durationMs} мс';
}

// -----------------------------------------------------------------------------
// SoundCollection
// -----------------------------------------------------------------------------

/// User's sound collection — unlocked sounds and active selection.
class SoundCollection {
  final Set<String> unlockedSounds;
  final String? activeSoundId;
  final int totalSoundsUnlocked;

  const SoundCollection({
    this.unlockedSounds = const {},
    this.activeSoundId,
    this.totalSoundsUnlocked = 0,
  });

  SoundCollection copyWith({
    Set<String>? unlockedSounds,
    String? activeSoundId,
    bool clearActiveSound = false,
    int? totalSoundsUnlocked,
  }) {
    return SoundCollection(
      unlockedSounds: unlockedSounds ?? this.unlockedSounds,
      activeSoundId:
          clearActiveSound ? null : (activeSoundId ?? this.activeSoundId),
      totalSoundsUnlocked:
          totalSoundsUnlocked ?? this.totalSoundsUnlocked,
    );
  }
}

// -----------------------------------------------------------------------------
// DepositSoundEvent
// -----------------------------------------------------------------------------

/// Event fired when a deposit triggers a sound.
class DepositSoundEvent {
  final String eventId;
  final double amount;
  final SoundTier tier;
  final String soundId;
  final bool isStreakBonus;
  final bool isJackpot;
  final DateTime playedAt;

  DepositSoundEvent({
    required this.eventId,
    required this.amount,
    required this.tier,
    required this.soundId,
    this.isStreakBonus = false,
    this.isJackpot = false,
    DateTime? playedAt,
  }) : playedAt = playedAt ?? DateTime(2000);

  /// Formatted amount string with currency.
  String get amountLabel =>
      '${amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2)} ₴';
}

// -----------------------------------------------------------------------------
// SoundscapesState
// -----------------------------------------------------------------------------

/// State for the Deposit Soundscapes feature.
class SoundscapesState {
  final SoundCollection collection;
  final List<SoundEffect> soundCatalog;
  final DepositSoundEvent? lastEvent;
  final bool isPlaying;
  final int streakCount;
  final String? error;

  const SoundscapesState({
    this.collection = const SoundCollection(),
    this.soundCatalog = const [],
    this.lastEvent,
    this.isPlaying = false,
    this.streakCount = 0,
    this.error,
  });

  SoundscapesState copyWith({
    SoundCollection? collection,
    List<SoundEffect>? soundCatalog,
    DepositSoundEvent? lastEvent,
    bool clearLastEvent = false,
    bool? isPlaying,
    int? streakCount,
    String? error,
  }) {
    return SoundscapesState(
      collection: collection ?? this.collection,
      soundCatalog: soundCatalog ?? this.soundCatalog,
      lastEvent:
          clearLastEvent ? null : (lastEvent ?? this.lastEvent),
      isPlaying: isPlaying ?? this.isPlaying,
      streakCount: streakCount ?? this.streakCount,
      error: error,
    );
  }
}

// -----------------------------------------------------------------------------
// Predefined sound catalog — 15+ sounds across tiers
// -----------------------------------------------------------------------------

const _soundCatalog = <SoundEffect>[
  // ── Tiny (0–100 ₴) ──────────────────────────────────────────────────────
  SoundEffect(
    soundId: 'neon_ping',
    nameUA: 'Неоновий Пінг',
    descriptionUA: 'Легкий неоновий сигнал — краплина в скарбницю.',
    tier: SoundTier.tiny,
    frequencyHz: 880,
    durationMs: 150,
    isUnlocked: true,
    sketchfabModelId: 'neon-ping-v1',
  ),
  SoundEffect(
    soundId: 'byte_chirp',
    nameUA: 'Байт-Цвірінь',
    descriptionUA: 'Короткий цифровий цвірінь — навіть байт важливий!',
    tier: SoundTier.tiny,
    frequencyHz: 1200,
    durationMs: 100,
    isUnlocked: true,
    sketchfabModelId: 'byte-chirp-v1',
  ),
  SoundEffect(
    soundId: 'pixel_drop',
    nameUA: 'Піксель-Крапля',
    descriptionUA: 'Піксельна крапля падає у ванну даних.',
    tier: SoundTier.tiny,
    frequencyHz: 660,
    durationMs: 180,
    unlockRequirement: '5 депозитів',
    sketchfabModelId: 'pixel-drop-v1',
  ),

  // ── Small (100–500 ₴) ──────────────────────────────────────────────────
  SoundEffect(
    soundId: 'circuit_chime',
    nameUA: 'Схемо-Дзвіночок',
    descriptionUA: 'Кристальний дзвіночок замикання кола — струм тече!',
    tier: SoundTier.small,
    frequencyHz: 1047,
    durationMs: 300,
    unlockRequirement: 'Накопичити 500 ₴',
    sketchfabModelId: 'circuit-chime-v1',
  ),
  SoundEffect(
    soundId: 'glitch_bell',
    nameUA: 'Глітч-Дзвін',
    descriptionUA: 'Дзвін з цифровим глітчем — дані стукають у двері.',
    tier: SoundTier.small,
    frequencyHz: 1319,
    durationMs: 250,
    unlockRequirement: '10 депозитів',
    sketchfabModelId: 'glitch-bell-v1',
  ),
  SoundEffect(
    soundId: 'neo_whistle',
    nameUA: 'Нео-Свист',
    descriptionUA: 'Неоновий свист прокидається у матриці.',
    tier: SoundTier.small,
    frequencyHz: 1568,
    durationMs: 280,
    unlockRequirement: 'Стрік 3 дні',
    sketchfabModelId: 'neo-whistle-v1',
  ),

  // ── Medium (500–2000 ₴) ────────────────────────────────────────────────
  SoundEffect(
    soundId: 'data_pulse',
    nameUA: 'Пульс Даних',
    descriptionUA: 'Глибокий пульс даних — потік прискорюється.',
    tier: SoundTier.medium,
    frequencyHz: 440,
    durationMs: 500,
    unlockRequirement: 'Накопичити 2000 ₴',
    sketchfabModelId: 'data-pulse-v1',
  ),
  SoundEffect(
    soundId: 'matrix_hum',
    nameUA: 'Гул Матриці',
    descriptionUA: 'Низькочастотний гул — матриця працює на тебе.',
    tier: SoundTier.medium,
    frequencyHz: 220,
    durationMs: 600,
    unlockRequirement: '20 депозитів',
    sketchfabModelId: 'matrix-hum-v1',
  ),
  SoundEffect(
    soundId: 'cyber_echo',
    nameUA: 'Кібер-Відлуння',
    descriptionUA: 'Відлуння крізь неонові коридори скарбниці.',
    tier: SoundTier.medium,
    frequencyHz: 523,
    durationMs: 450,
    unlockRequirement: 'Стрік 7 днів',
    sketchfabModelId: 'cyber-echo-v1',
  ),

  // ── Large (2000–10000 ₴) ───────────────────────────────────────────────
  SoundEffect(
    soundId: 'quantum_burst',
    nameUA: 'Квантовий Вибух',
    descriptionUA: 'Потужний квантовий вибух — скарбниця здригається!',
    tier: SoundTier.large,
    frequencyHz: 330,
    durationMs: 800,
    unlockRequirement: 'Накопичити 10000 ₴',
    sketchfabModelId: 'quantum-burst-v1',
  ),
  SoundEffect(
    soundId: 'plasma_wave',
    nameUA: 'Плазмова Хвиля',
    descriptionUA: 'Хвиля плазми розходиться від твого депозиту.',
    tier: SoundTier.large,
    frequencyHz: 294,
    durationMs: 900,
    unlockRequirement: '50 депозитів',
    sketchfabModelId: 'plasma-wave-v1',
  ),
  SoundEffect(
    soundId: 'void_rumble',
    nameUA: 'Гуркіт Порожнечі',
    descriptionUA: 'Глибокий гуркіт порожнечі заповнюється сенсом.',
    tier: SoundTier.large,
    frequencyHz: 165,
    durationMs: 1000,
    unlockRequirement: 'Стрік 14 днів',
    sketchfabModelId: 'void-rumble-v1',
  ),

  // ── Epic (10000+ ₴) ────────────────────────────────────────────────────
  SoundEffect(
    soundId: 'cyber_orchestra',
    nameUA: 'Кібер-Оркестр',
    descriptionUA: 'Повний кібер-оркестр — твій депозит — симфонія!',
    tier: SoundTier.epic,
    frequencyHz: 262,
    durationMs: 1500,
    unlockRequirement: 'Накопичити 50000 ₴',
    sketchfabModelId: 'cyber-orchestra-v1',
  ),
  SoundEffect(
    soundId: 'nebula_fanfare',
    nameUA: 'Фанфари Туманності',
    descriptionUA: 'Фанфари розлітаються крізь туманність даних.',
    tier: SoundTier.epic,
    frequencyHz: 196,
    durationMs: 2000,
    unlockRequirement: '100 депозитів',
    sketchfabModelId: 'nebula-fanfare-v1',
  ),

  // ── Jackpot ─────────────────────────────────────────────────────────────
  SoundEffect(
    soundId: 'vault_eruption',
    nameUA: 'Виверження Сейфу',
    descriptionUA:
        'Сейф вивергається неоновою лавою! Абсолютний джекпот!',
    tier: SoundTier.jackpot,
    frequencyHz: 131,
    durationMs: 3000,
    unlockRequirement: 'Виграти джекпот',
    sketchfabModelId: 'vault-eruption-v1',
  ),

  // ── Streak sounds ───────────────────────────────────────────────────────
  SoundEffect(
    soundId: 'streak_day_3',
    nameUA: 'Стрік День 3',
    descriptionUA: 'Три дні поспіль — ритм встановлено!',
    tier: SoundTier.tiny,
    frequencyHz: 523,
    durationMs: 400,
    unlockRequirement: 'Стрік 3 дні',
    sketchfabModelId: 'streak-day3-v1',
  ),
  SoundEffect(
    soundId: 'streak_day_7',
    nameUA: 'Стрік День 7',
    descriptionUA: 'Тиждень без пропуску — мелодія зростає!',
    tier: SoundTier.small,
    frequencyHz: 659,
    durationMs: 600,
    unlockRequirement: 'Стрік 7 днів',
    sketchfabModelId: 'streak-day7-v1',
  ),
  SoundEffect(
    soundId: 'streak_day_14',
    nameUA: 'Стрік День 14',
    descriptionUA: 'Два тижні! Гармонія сили пульсує!',
    tier: SoundTier.medium,
    frequencyHz: 784,
    durationMs: 800,
    unlockRequirement: 'Стрік 14 днів',
    sketchfabModelId: 'streak-day14-v1',
  ),
  SoundEffect(
    soundId: 'streak_day_30',
    nameUA: 'Стрік День 30',
    descriptionUA: 'Місяць! Легендарна мелодія нескінченності!',
    tier: SoundTier.large,
    frequencyHz: 1047,
    durationMs: 1200,
    unlockRequirement: 'Стрік 30 днів',
    sketchfabModelId: 'streak-day30-v1',
  ),
];

// -----------------------------------------------------------------------------
// SoundscapesNotifier
// -----------------------------------------------------------------------------

class SoundscapesNotifier extends StateNotifier<SoundscapesState> {
  final Ref _ref;
  final AppDatabase _db;

  SoundscapesNotifier(this._ref, this._db)
      : super(const SoundscapesState(
          soundCatalog: _soundCatalog,
        ));

  // ---------------------------------------------------------------------------
  // Load collection from DB
  // ---------------------------------------------------------------------------

  Future<void> loadCollection() async {
    try {
      // Load unlocked sound IDs and active sound from DB via user preferences
      final unlockedIds = await _loadUnlockedSoundIds();
      final activeSoundId = await _loadActiveSoundId();
      final streakCount = await _loadStreakCount();

      // Build catalog with unlock status
      final catalog = _soundCatalog.map((sound) {
        final isUnlocked =
            unlockedIds.contains(sound.soundId) || sound.isUnlocked;
        return sound.copyWith(isUnlocked: isUnlocked);
      }).toList();

      final collection = SoundCollection(
        unlockedSounds: unlockedIds,
        activeSoundId: activeSoundId,
        totalSoundsUnlocked: unlockedIds.length,
      );

      state = state.copyWith(
        collection: collection,
        soundCatalog: catalog,
        streakCount: streakCount,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка завантаження колекції: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Play deposit sound — select and "play" appropriate sound
  // ---------------------------------------------------------------------------

  Future<void> playDepositSound(double amount) async {
    final sound = getSoundForAmount(amount);
    final tier = SoundTier.fromAmount(amount);

    state = state.copyWith(isPlaying: true);

    // Simulate playback duration
    await Future.delayed(Duration(milliseconds: sound.durationMs));

    final event = DepositSoundEvent(
      eventId: 'snd_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      tier: tier,
      soundId: sound.soundId,
      isStreakBonus: false,
      isJackpot: false,
      playedAt: DateTime.now(),
    );

    // Award XP for playing a deposit sound
    await _db.addXP(2, source: 'sound_played_${sound.soundId}');

    state = state.copyWith(
      lastEvent: event,
      isPlaying: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Play streak sound — escalating melody
  // ---------------------------------------------------------------------------

  Future<void> playStreakSound(int streakDays) async {
    // Pick the highest streak sound the user qualifies for
    SoundEffect? streakSound;

    if (streakDays >= 30) {
      streakSound = _findSound('streak_day_30');
    } else if (streakDays >= 14) {
      streakSound = _findSound('streak_day_14');
    } else if (streakDays >= 7) {
      streakSound = _findSound('streak_day_7');
    } else if (streakDays >= 3) {
      streakSound = _findSound('streak_day_3');
    }

    if (streakSound == null) return;

    state = state.copyWith(isPlaying: true);

    // Simulate escalating playback — longer for higher streaks
    await Future.delayed(Duration(milliseconds: streakSound.durationMs));

    final event = DepositSoundEvent(
      eventId: 'streak_${DateTime.now().millisecondsSinceEpoch}',
      amount: 0,
      tier: streakSound.tier,
      soundId: streakSound.soundId,
      isStreakBonus: true,
      isJackpot: false,
      playedAt: DateTime.now(),
    );

    // Award XP
    await _db.addXP(2, source: 'streak_sound_${streakSound.soundId}');

    // Auto-unlock streak sound if not yet unlocked
    if (!streakSound.isUnlocked) {
      await unlockSound(streakSound.soundId);
    }

    state = state.copyWith(
      lastEvent: event,
      isPlaying: false,
      streakCount: streakDays,
    );
  }

  // ---------------------------------------------------------------------------
  // Play jackpot sound — epic orchestral hit
  // ---------------------------------------------------------------------------

  Future<void> playJackpotSound() async {
    final jackpotSound = _findSound('vault_eruption');
    if (jackpotSound == null) return;

    state = state.copyWith(isPlaying: true);

    // Epic duration for jackpot
    await Future.delayed(const Duration(milliseconds: 3000));

    final event = DepositSoundEvent(
      eventId: 'jackpot_${DateTime.now().millisecondsSinceEpoch}',
      amount: 0,
      tier: SoundTier.jackpot,
      soundId: jackpotSound.soundId,
      isStreakBonus: false,
      isJackpot: true,
      playedAt: DateTime.now(),
    );

    // Award XP for jackpot
    await _db.addXP(2, source: 'jackpot_sound');

    // Auto-unlock jackpot sound
    if (!jackpotSound.isUnlocked) {
      await unlockSound(jackpotSound.soundId);
    }

    state = state.copyWith(
      lastEvent: event,
      isPlaying: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Unlock a new sound
  // ---------------------------------------------------------------------------

  Future<void> unlockSound(String soundId) async {
    try {
      final sound = _findSound(soundId);
      if (sound == null) {
        state = state.copyWith(error: 'Звук не знайдено: $soundId');
        return;
      }

      // Already unlocked?
      if (state.collection.unlockedSounds.contains(soundId)) return;

      // Update collection
      final newUnlocked = {...state.collection.unlockedSounds, soundId};
      final newCollection = state.collection.copyWith(
        unlockedSounds: newUnlocked,
        totalSoundsUnlocked: newUnlocked.length,
      );

      // Update catalog
      final newCatalog = state.soundCatalog.map((s) {
        if (s.soundId == soundId) {
          return s.copyWith(isUnlocked: true);
        }
        return s;
      }).toList();

      // Award XP for unlocking
      await _db.addXP(5, source: 'sound_unlocked_$soundId');

      // Persist unlocked state
      await _saveUnlockedSoundId(soundId);

      state = state.copyWith(
        collection: newCollection,
        soundCatalog: newCatalog,
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка розблокування звуку: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Set active (default) deposit sound
  // ---------------------------------------------------------------------------

  Future<void> setActiveSound(String soundId) async {
    // Verify sound exists and is unlocked
    final sound = _findSound(soundId);
    if (sound == null) {
      state = state.copyWith(error: 'Звук не знайдено: $soundId');
      return;
    }

    if (!state.collection.unlockedSounds.contains(soundId) && !sound.isUnlocked) {
      state =
          state.copyWith(error: 'Спочатку розблокуйте звук: ${sound.nameUA}');
      return;
    }

    final newCollection = state.collection.copyWith(
      activeSoundId: soundId,
    );

    await _saveActiveSoundId(soundId);

    state = state.copyWith(collection: newCollection);
  }

  // ---------------------------------------------------------------------------
  // Get sound for amount — returns SoundEffect based on deposit size
  // ---------------------------------------------------------------------------

  SoundEffect getSoundForAmount(double amount) {
    final tier = SoundTier.fromAmount(amount);

    // If user has an active sound and it matches or exceeds the tier, use it
    if (state.collection.activeSoundId != null) {
      final active = _findSound(state.collection.activeSoundId!);
      if (active != null &&
          active.isUnlocked &&
          active.tier.index <= tier.index) {
        return active;
      }
    }

    // Otherwise, pick a random unlocked sound from the matching tier
    final tierSounds = state.soundCatalog
        .where((s) => s.tier == tier && s.isUnlocked)
        .toList();

    if (tierSounds.isNotEmpty) {
      return tierSounds[Random().nextInt(tierSounds.length)];
    }

    // Fallback: pick the first unlocked sound of any lower tier
    for (var t = tier.index; t >= 0; t--) {
      final fallback = state.soundCatalog
          .where(
              (s) => s.tier == SoundTier.values[t] && s.isUnlocked)
          .toList();
      if (fallback.isNotEmpty) {
        return fallback[Random().nextInt(fallback.length)];
      }
    }

    // Ultimate fallback: Neon Ping (always unlocked)
    return _soundCatalog.first;
  }

  // ---------------------------------------------------------------------------
  // Generate custom AI sound description via OpenRouter
  // ---------------------------------------------------------------------------

  Future<String> generateCustomSoundDescription(
    double amount,
    String goalName,
  ) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      return _fallbackSoundDescription(amount, goalName);
    }

    final tier = SoundTier.fromAmount(amount);

    final result = await openRouter.chat(
      systemPrompt: 'Ти — аудіо-дизайнер у кіберпанк-додатку заощаджень '
          'NEONCRED. Твориш описи звуків для депозитів. '
          'Стиль: неоновий кіберпанк, атмосферно, коротко (1-2 речення). '
          'Мова: українська. Валюта: грн (UAH).',
      userPrompt: 'Опиши унікальний кіберпанк-звук для депозиту '
          '${amount.toStringAsFixed(0)} ₴ у ціль "$goalName". '
          'Тір звуку: ${tier.labelUA}. '
          'Опиши тембр, частоту та настрій цього звуку.',
      temperature: 0.9,
      maxTokens: 256,
    );

    if (result != null && result.trim().isNotEmpty) {
      return result.trim();
    }

    return _fallbackSoundDescription(amount, goalName);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  SoundEffect? _findSound(String soundId) {
    for (final s in state.soundCatalog) {
      if (s.soundId == soundId) return s;
    }
    return null;
  }

  /// Fallback sound description when AI is unavailable.
  String _fallbackSoundDescription(double amount, String goalName) {
    final tier = SoundTier.fromAmount(amount);
    return 'Звук ${tier.labelUA} для депозиту '
        '${amount.toStringAsFixed(0)} ₴ у ціль "$goalName". '
        '${tier.emoji} ${tier.labelUA} резонанс наповнює скарбницю!';
  }

  // ---------------------------------------------------------------------------
  // Persistence helpers (via database)
  // ---------------------------------------------------------------------------

  Future<Set<String>> _loadUnlockedSoundIds() async {
    try {
      final entries = await _db.getAllTrophyEntries();
      // Re-use trophy entries table to store sound unlock state
      // Sound unlocks are stored with trophyId starting with 'sound_'
      return entries
          .where((e) => e.trophyId.startsWith('sound_'))
          .map((e) => e.trophyId.replaceFirst('sound_', ''))
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<String?> _loadActiveSoundId() async {
    try {
      final entries = await _db.getAllTrophyEntries();
      final activeEntry = entries
          .where((e) => e.trophyId == 'soundscapes_active')
          .firstOrNull;
      return activeEntry?.name;
    } catch (_) {
      return null;
    }
  }

  Future<int> _loadStreakCount() async {
    // Streak count is derived from the deposit history / cyber-pet data
    // For now, return 0 as a safe default; real implementation would
    // query the deposits table for consecutive days.
    return 0;
  }

  Future<void> _saveUnlockedSoundId(String soundId) async {
    try {
      await _db.insertTrophyEntry(
        TrophyEntriesCompanion.insert(
          trophyId: 'sound_$soundId',
          name: soundId,
          tier: 'sound_unlock',
        ),
      );
    } catch (_) {
      // Already saved — ignore duplicate
    }
  }

  Future<void> _saveActiveSoundId(String soundId) async {
    try {
      // Delete old active entry if exists
      final entries = await _db.getAllTrophyEntries();
      final oldEntry = entries
          .where((e) => e.trophyId == 'soundscapes_active')
          .firstOrNull;

      if (oldEntry != null) {
        // Update by re-inserting (upsert behavior)
        await _db.insertTrophyEntry(
          TrophyEntriesCompanion.insert(
            trophyId: 'soundscapes_active',
            name: soundId,
            tier: 'soundscapes_config',
          ),
        );
      } else {
        await _db.insertTrophyEntry(
          TrophyEntriesCompanion.insert(
            trophyId: 'soundscapes_active',
            name: soundId,
            tier: 'soundscapes_config',
          ),
        );
      }
    } catch (_) {
      // Persistence issue — non-critical
    }
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final soundscapesProvider =
    StateNotifierProvider<SoundscapesNotifier, SoundscapesState>((ref) {
  final db = ref.watch(databaseProvider);
  return SoundscapesNotifier(ref, db);
});
