import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Cyber-Pet Companion — Tamagotchi-style savings motivation
// =============================================================================
//
// A virtual cyber-pet (NeonCat / CircuitDog / DataDragon) whose health and
// happiness directly reflect the user's savings behavior. The pet "eats"
// deposits, gets sick without activity, and evolves through 5 stages.
// AI generates pet dialogues for emotional connection.
//
// API:  OpenRouter (pet dialogue generation)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// Pet species the user can choose from.
enum PetSpecies {
  neonCat('neon_cat', 'NeonCat', 'Нейонова Кішка', '🐱'),
  circuitDog('circuit_dog', 'CircuitDog', 'Кібер-Пес', '🐕'),
  dataDragon('data_dragon', 'DataDragon', 'Дракон Даних', '🐉');

  final String id;
  final String enName;
  final String uaName;
  final String emoji;
  const PetSpecies(this.id, this.enName, this.uaName, this.emoji);
}

/// Pet evolution stages — 5 levels of growth.
enum PetEvolution {
  egg('egg', 'Яйце', 0, '🥚'),
  baby('baby', 'Малюк', 500, '🐣'),
  teen('teen', 'Підліток', 2000, '🔥'),
  adult('adult', 'Дорослий', 5000, '⚡'),
  ultimate('ultimate', 'Ультима', 15000, '🌟');

  final String id;
  final String labelUA;
  final int xpRequired;
  final String emoji;
  const PetEvolution(this.id, this.labelUA, this.xpRequired, this.emoji);

  static PetEvolution fromXP(int totalPetXP) {
    if (totalPetXP >= 15000) return PetEvolution.ultimate;
    if (totalPetXP >= 5000) return PetEvolution.adult;
    if (totalPetXP >= 2000) return PetEvolution.teen;
    if (totalPetXP >= 500) return PetEvolution.baby;
    return PetEvolution.egg;
  }

  PetEvolution get next {
    switch (this) {
      case PetEvolution.egg: return PetEvolution.baby;
      case PetEvolution.baby: return PetEvolution.teen;
      case PetEvolution.teen: return PetEvolution.adult;
      case PetEvolution.adult: return PetEvolution.ultimate;
      case PetEvolution.ultimate: return PetEvolution.ultimate;
    }
  }
}

/// Pet mood — affects dialogue and visuals.
enum PetMood {
  ecstatic('ecstatic', 'Щасливий!', 90, '🤩'),
  happy('happy', 'Задоволений', 70, '😊'),
  neutral('neutral', 'Нормальний', 50, '😐'),
  sad('sad', 'Сумний...', 30, '😢'),
  critical('critical', 'Хворіє!', 10, '🤒');

  final String id;
  final String labelUA;
  final int healthThreshold;
  final String emoji;
  const PetMood(this.id, this.labelUA, this.healthThreshold, this.emoji);

  static PetMood fromHealth(double health) {
    if (health >= 90) return PetMood.ecstatic;
    if (health >= 70) return PetMood.happy;
    if (health >= 50) return PetMood.neutral;
    if (health >= 30) return PetMood.sad;
    return PetMood.critical;
  }
}

/// A dialogue line the pet can say.
class PetDialogue {
  final String textUA;
  final PetMood mood;
  final PetEvolution minEvolution;

  const PetDialogue({
    required this.textUA,
    required this.mood,
    this.minEvolution = PetEvolution.egg,
  });
}

/// Pet accessory / cosmetic item.
class PetAccessory {
  final String accessoryId;
  final String nameUA;
  final String emoji;
  final int xpCost;
  final PetEvolution minEvolution;

  const PetAccessory({
    required this.accessoryId,
    required this.nameUA,
    required this.emoji,
    required this.xpCost,
    this.minEvolution = PetEvolution.egg,
  });
}

/// The full cyber-pet state.
class CyberPetData {
  final String petId;
  final PetSpecies species;
  final String name;
  final double health; // 0-100, decreases without deposits
  final double happiness; // 0-100, boosted by deposits + interactions
  final int petXP; // separate from user XP
  final PetEvolution evolution;
  final PetMood mood;
  final DateTime lastFedAt; // last deposit time
  final DateTime lastPetAt; // last interaction
  final DateTime createdAt;
  final int totalFeedings; // total deposits that fed the pet
  final int totalPettings; // total interactions
  final int streakDays; // consecutive days with deposits
  final List<String> equippedAccessories; // equipped accessory IDs
  final String? currentDialogue;

  CyberPetData({
    required this.petId,
    required this.species,
    required this.name,
    this.health = 100.0,
    this.happiness = 80.0,
    this.petXP = 0,
    this.evolution = PetEvolution.egg,
    this.mood = PetMood.happy,
    DateTime? lastFedAt,
    DateTime? lastPetAt,
    DateTime? createdAt,
    this.totalFeedings = 0,
    this.totalPettings = 0,
    this.streakDays = 0,
    this.equippedAccessories = const [],
    this.currentDialogue,
  })  : lastFedAt = lastFedAt ?? DateTime(2000),
        lastPetAt = lastPetAt ?? DateTime(2000),
        createdAt = createdAt ?? DateTime(2000);

  double get healthPercent => (health / 100).clamp(0.0, 1.0);
  double get happinessPercent => (happiness / 100).clamp(0.0, 1.0);
  double get evolutionProgress {
    final nextEvo = evolution.next;
    if (nextEvo == evolution) return 1.0;
    final currentReq = evolution.xpRequired;
    final nextReq = nextEvo.xpRequired;
    return ((petXP - currentReq) / (nextReq - currentReq)).clamp(0.0, 1.0);
  }

  CyberPetData copyWith({
    String? petId,
    PetSpecies? species,
    String? name,
    double? health,
    double? happiness,
    int? petXP,
    PetEvolution? evolution,
    PetMood? mood,
    DateTime? lastFedAt,
    DateTime? lastPetAt,
    DateTime? createdAt,
    int? totalFeedings,
    int? totalPettings,
    int? streakDays,
    List<String>? equippedAccessories,
    String? currentDialogue,
  }) {
    return CyberPetData(
      petId: petId ?? this.petId,
      species: species ?? this.species,
      name: name ?? this.name,
      health: health ?? this.health,
      happiness: happiness ?? this.happiness,
      petXP: petXP ?? this.petXP,
      evolution: evolution ?? this.evolution,
      mood: mood ?? this.mood,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastPetAt: lastPetAt ?? this.lastPetAt,
      createdAt: createdAt ?? this.createdAt,
      totalFeedings: totalFeedings ?? this.totalFeedings,
      totalPettings: totalPettings ?? this.totalPettings,
      streakDays: streakDays ?? this.streakDays,
      equippedAccessories: equippedAccessories ?? this.equippedAccessories,
      currentDialogue: currentDialogue ?? this.currentDialogue,
    );
  }
}

/// Pet stats for display.
class CyberPetStats {
  final int daysTogether;
  final int totalFeedings;
  final int totalPettings;
  final int evolutionsReached;
  final int longestStreak;
  final double avgHealth;
  final double avgHappiness;

  const CyberPetStats({
    this.daysTogether = 0,
    this.totalFeedings = 0,
    this.totalPettings = 0,
    this.evolutionsReached = 0,
    this.longestStreak = 0,
    this.avgHealth = 100.0,
    this.avgHappiness = 80.0,
  });
}

// -----------------------------------------------------------------------------
// Predefined dialogues per mood
// -----------------------------------------------------------------------------

const _moodDialogues = <PetMood, List<PetDialogue>>{
  PetMood.ecstatic: [
    PetDialogue(textUA: 'Мій нейронний мозок співає! Ти найкращий хазяїн!', mood: PetMood.ecstatic),
    PetDialogue(textUA: 'Стрік продовжується! Я відчуваю енергію заощаджень!', mood: PetMood.ecstatic),
    PetDialogue(textUA: 'Ще один депозит — і я еволюціоную! Давай!', mood: PetMood.ecstatic),
  ],
  PetMood.happy: [
    PetDialogue(textUA: 'Дякую за поповнення! Мої батареї заряджені!', mood: PetMood.happy),
    PetDialogue(textUA: 'Хороший стрік! Продовжуй в тому ж дусі!', mood: PetMood.happy),
    PetDialogue(textUA: 'Я відчуваю тепло твоїх заощаджень...', mood: PetMood.happy),
  ],
  PetMood.neutral: [
    PetDialogue(textUA: 'Я тут, чекаю на наступний депозит...', mood: PetMood.neutral),
    PetDialogue(textUA: 'Не забувай про свої цілі! Відкрий скарбничку!', mood: PetMood.neutral),
    PetDialogue(textUA: 'Мої сенсори виявляють нестачу поповнень...', mood: PetMood.neutral),
  ],
  PetMood.sad: [
    PetDialogue(textUA: 'Я сумую без депозитів... Моя енергія згасає...', mood: PetMood.sad),
    PetDialogue(textUA: 'Стрік розірвано... Я відчуваю порожнечу...', mood: PetMood.sad),
    PetDialogue(textUA: 'Будь ласка, не забувай про мене і свої цілі!', mood: PetMood.sad),
  ],
  PetMood.critical: [
    PetDialogue(textUA: 'СИСТЕМА НЕСПРАВНА! Потрібен депозит для перезапуску!', mood: PetMood.critical),
    PetDialogue(textUA: 'Критичний рівень енергії... Терміново потрібне поповнення!', mood: PetMood.critical),
    PetDialogue(textUA: 'Мої процесори зупиняються... Збережи мене!', mood: PetMood.critical),
  ],
};

// -----------------------------------------------------------------------------
// Accessories catalog
// -----------------------------------------------------------------------------

const _accessoriesCatalog = <PetAccessory>[
  PetAccessory(accessoryId: 'neon_collar', nameUA: 'Неоновий нашийник', emoji: '💎', xpCost: 200, minEvolution: PetEvolution.baby),
  PetAccessory(accessoryId: 'laser_eyes', nameUA: 'Лазерні очі', emoji: '🔴', xpCost: 500, minEvolution: PetEvolution.teen),
  PetAccessory(accessoryId: 'hover_board', nameUA: 'Говерборд', emoji: '🛹', xpCost: 1000, minEvolution: PetEvolution.teen),
  PetAccessory(accessoryId: 'wings', nameUA: 'Кібер-крила', emoji: '🦋', xpCost: 2000, minEvolution: PetEvolution.adult),
  PetAccessory(accessoryId: 'aura_shield', nameUA: 'Аура-Щит', emoji: '🛡️', xpCost: 3000, minEvolution: PetEvolution.adult),
  PetAccessory(accessoryId: 'quantum_crown', nameUA: 'Квантова Корона', emoji: '👑', xpCost: 5000, minEvolution: PetEvolution.ultimate),
  PetAccessory(accessoryId: 'plasma_tail', nameUA: 'Плазмовий хвіст', emoji: '🔥', xpCost: 1500, minEvolution: PetEvolution.adult),
  PetAccessory(accessoryId: 'holo_tag', nameUA: 'Голо-бейджик', emoji: '🏷️', xpCost: 100, minEvolution: PetEvolution.egg),
];

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class CyberPetState {
  final CyberPetData? pet;
  final CyberPetStats stats;
  final bool isCreating;
  final bool isFeeding;
  final bool isTalking;
  final String? error;

  const CyberPetState({
    this.pet,
    this.stats = const CyberPetStats(),
    this.isCreating = false,
    this.isFeeding = false,
    this.isTalking = false,
    this.error,
  });

  CyberPetState copyWith({
    CyberPetData? pet,
    CyberPetStats? stats,
    bool? isCreating,
    bool? isFeeding,
    bool? isTalking,
    String? error,
  }) {
    return CyberPetState(
      pet: pet ?? this.pet,
      stats: stats ?? this.stats,
      isCreating: isCreating ?? this.isCreating,
      isFeeding: isFeeding ?? this.isFeeding,
      isTalking: isTalking ?? this.isTalking,
      error: error,
    );
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class CyberPetNotifier extends StateNotifier<CyberPetState> {
  final Ref _ref;
  final AppDatabase _db;

  CyberPetNotifier(this._ref, this._db) : super(const CyberPetState());

  // ---------------------------------------------------------------------------
  // Load pet from DB
  // ---------------------------------------------------------------------------

  Future<void> loadPet() async {
    try {
      final rows = await _db.getAllCyberPets();
      if (rows.isEmpty) {
        // No pet yet — user needs to create one
        state = const CyberPetState();
        return;
      }

      final row = rows.first;
      final species = PetSpecies.values.firstWhere(
        (s) => s.id == row.species,
        orElse: () => PetSpecies.neonCat,
      );

      // Calculate current health based on time since last deposit
      final now = DateTime.now();
      final hoursSinceFed = now.difference(row.lastFedAt).inHours;
      final healthDecay = (hoursSinceFed * 1.5).clamp(0.0, 80.0); // 1.5/hour decay
      final happinessDecay = (hoursSinceFed * 2.0).clamp(0.0, 90.0);

      final currentHealth = (row.health - healthDecay).clamp(0.0, 100.0);
      final currentHappiness = (row.happiness - happinessDecay).clamp(0.0, 100.0);
      final petXP = row.petXp;
      final evolution = PetEvolution.fromXP(petXP);
      final mood = PetMood.fromHealth(currentHealth);

      final pet = CyberPetData(
        petId: row.petId,
        species: species,
        name: row.name,
        health: currentHealth,
        happiness: currentHappiness,
        petXP: petXP,
        evolution: evolution,
        mood: mood,
        lastFedAt: row.lastFedAt,
        lastPetAt: row.lastPetAt,
        createdAt: row.createdAt,
        totalFeedings: row.totalFeedings,
        totalPettings: row.totalPettings,
        streakDays: row.streakDays,
        equippedAccessories: row.equippedAccessories.split(',').where((s) => s.isNotEmpty).toList(),
      );

      // Generate a random dialogue
      final dialogue = _getRandomDialogue(mood, evolution);

      state = state.copyWith(
        pet: pet.copyWith(currentDialogue: dialogue),
        stats: CyberPetStats(
          daysTogether: now.difference(row.createdAt).inDays,
          totalFeedings: row.totalFeedings,
          totalPettings: row.totalPettings,
          evolutionsReached: evolution.index,
          longestStreak: row.streakDays,
          avgHealth: currentHealth,
          avgHappiness: currentHappiness,
        ),
      );

      // Update DB with decayed values
      await _db.updateCyberPet(row.id, CyberPetsCompanion(
        health: Value(currentHealth),
        happiness: Value(currentHappiness),
      ));
    } catch (e) {
      state = state.copyWith(error: 'Помилка завантаження піта: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Create a new pet
  // ---------------------------------------------------------------------------

  Future<void> createPet(PetSpecies species, String name) async {
    state = state.copyWith(isCreating: true, error: null);

    try {
      final petId = 'pet_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();

      final pet = CyberPetData(
        petId: petId,
        species: species,
        name: name.isEmpty ? species.uaName : name,
        health: 100.0,
        happiness: 100.0,
        petXP: 0,
        evolution: PetEvolution.egg,
        mood: PetMood.happy,
        lastFedAt: now,
        lastPetAt: now,
        createdAt: now,
        currentDialogue: 'Привіт! Я ${name.isEmpty ? species.uaName : name}! Годуй мене депозитами!',
      );

      await _db.insertCyberPet(CyberPetsCompanion(
        petId: Value(petId),
        species: Value(species.id),
        name: Value(pet.name),
        health: Value(pet.health),
        happiness: Value(pet.happiness),
        petXp: Value(pet.petXP),
        evolution: Value(pet.evolution.id),
        lastFedAt: Value(now),
        lastPetAt: Value(now),
        createdAt: Value(now),
        totalFeedings: Value(0),
        totalPettings: Value(0),
        streakDays: Value(0),
        equippedAccessories: Value(''),
      ));

      await _db.addXP(25, source: 'cyber_pet_created');

      state = state.copyWith(
        pet: pet,
        isCreating: false,
      );
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: 'Помилка створення піта: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Feed pet (triggered by deposit)
  // ---------------------------------------------------------------------------

  Future<void> feedPet(double depositAmount) async {
    if (state.pet == null) return;

    state = state.copyWith(isFeeding: true);

    try {
      final pet = state.pet!;
      final now = DateTime.now();

      // Calculate feed impact based on deposit size
      final healthBoost = (depositAmount / 100).clamp(3.0, 30.0);
      final happinessBoost = (depositAmount / 50).clamp(5.0, 40.0);
      final xpGain = (depositAmount / 10).round().clamp(5, 200);

      // Check streak
      final lastFedDate = DateTime(
        pet.lastFedAt.year,
        pet.lastFedAt.month,
        pet.lastFedAt.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      final daysDiff = today.difference(lastFedDate).inDays;

      int newStreak = pet.streakDays;
      if (daysDiff == 1) {
        newStreak++; // consecutive day
      } else if (daysDiff > 1) {
        newStreak = 1; // streak broken, restart
      }

      // Streak bonus
      final streakBonus = (newStreak * 0.5).clamp(0.0, 20.0);

      final newHealth = (pet.health + healthBoost + streakBonus).clamp(0.0, 100.0);
      final newHappiness = (pet.happiness + happinessBoost + streakBonus).clamp(0.0, 100.0);
      final newPetXP = pet.petXP + xpGain + (newStreak > 3 ? 10 : 0);
      final newEvolution = PetEvolution.fromXP(newPetXP);
      final newMood = PetMood.fromHealth(newHealth);

      final justEvolved = newEvolution != pet.evolution;
      final dialogue = justEvolved
          ? 'ЕВОЛЮЦІЯ! Я перетворився на ${newEvolution.labelUA}! 🎉'
          : _getRandomDialogue(newMood, newEvolution);

      final updatedPet = pet.copyWith(
        health: newHealth,
        happiness: newHappiness,
        petXP: newPetXP,
        evolution: newEvolution,
        mood: newMood,
        lastFedAt: now,
        totalFeedings: pet.totalFeedings + 1,
        streakDays: newStreak,
        currentDialogue: dialogue,
      );

      // Update DB
      final feedDbId = await _db.getCyberPetDbId(pet.petId);
      await _db.updateCyberPet(feedDbId, CyberPetsCompanion(
        health: Value(newHealth),
        happiness: Value(newHappiness),
        petXp: Value(newPetXP),
        evolution: Value(newEvolution.id),
        lastFedAt: Value(now),
        totalFeedings: Value(pet.totalFeedings + 1),
        streakDays: Value(newStreak),
      ));

      // Award user XP
      await _db.addXP(
        justEvolved ? 100 : 15,
        source: justEvolved ? 'pet_evolved' : 'pet_fed',
      );

      state = state.copyWith(
        pet: updatedPet,
        isFeeding: false,
      );
    } catch (e) {
      state = state.copyWith(
        isFeeding: false,
        error: 'Помилка годування: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Pet the pet (interaction — small happiness boost)
  // ---------------------------------------------------------------------------

  Future<void> petThePet() async {
    if (state.pet == null) return;

    final pet = state.pet!;
    final now = DateTime.now();

    // Cooldown: 1 interaction per hour
    if (now.difference(pet.lastPetAt).inMinutes < 60) {
      state = state.copyWith(
        pet: pet.copyWith(currentDialogue: 'Мені потрібно відпочити... Повернись через годину!'),
      );
      return;
    }

    final newHappiness = (pet.happiness + 5).clamp(0.0, 100.0);
    final dialogue = _getRandomDialogue(pet.mood, pet.evolution);

    final updatedPet = pet.copyWith(
      happiness: newHappiness,
      lastPetAt: now,
      totalPettings: pet.totalPettings + 1,
      currentDialogue: dialogue,
    );

    final petDbId = await _db.getCyberPetDbId(pet.petId);
    await _db.updateCyberPet(petDbId, CyberPetsCompanion(
      happiness: Value(newHappiness),
      lastPetAt: Value(now),
      totalPettings: Value(pet.totalPettings + 1),
    ));

    await _db.addXP(5, source: 'pet_interaction');

    state = state.copyWith(pet: updatedPet);
  }

  // ---------------------------------------------------------------------------
  // Generate AI dialogue
  // ---------------------------------------------------------------------------

  Future<String> generateAiDialogue() async {
    if (state.pet == null) return '';

    state = state.copyWith(isTalking: true);

    final openRouter = _ref.read(openRouterServiceProvider);
    final pet = state.pet!;

    try {
      final dialogue = (await openRouter.chat(
        systemPrompt: 'Ти ${pet.species.uaName} на ім\'я ${pet.name} — кібер-піт у додатку заощаджень NEONCRED. Скажи одну фразу (1-2 речення) українською: Якщо здоров\'я низьке — благай про депозит, Якщо стрік довгий — хвали хазяїна, Якщо еволюція близько — надихай. Стиль: кіберпанк, милота, використовуй техно-емоції',
        userPrompt: 'Настрій: ${pet.mood.labelUA}\nЕволюція: ${pet.evolution.labelUA}\nЗдоров\'я: ${pet.health.toStringAsFixed(0)}%\nЩастя: ${pet.happiness.toStringAsFixed(0)}%\nСтрік: ${pet.streakDays} днів\nОстаннє годування: ${DateTime.now().difference(pet.lastFedAt).inHours} годин тому',
        temperature: 0.9,
        maxTokens: 256,
      )) ?? _getRandomDialogue(pet.mood, pet.evolution);
      state = state.copyWith(isTalking: false);
      return dialogue;
    } catch (e) {
      state = state.copyWith(isTalking: false);
      return _getRandomDialogue(pet.mood, pet.evolution);
    }
  }

  // ---------------------------------------------------------------------------
  // Buy accessory
  // ---------------------------------------------------------------------------

  Future<bool> buyAccessory(String accessoryId) async {
    if (state.pet == null) return false;

    final accessory = _accessoriesCatalog.firstWhere(
      (a) => a.accessoryId == accessoryId,
      orElse: () => throw Exception('Accessory not found'),
    );

    // Check evolution requirement
    if (state.pet!.evolution.index < accessory.minEvolution.index) {
      state = state.copyWith(
        error: 'Потрібна еволюція: ${accessory.minEvolution.labelUA}',
      );
      return false;
    }

    // Deduct XP
    final newPetXP = state.pet!.petXP - accessory.xpCost;
    if (newPetXP < 0) {
      state = state.copyWith(error: 'Недостатньо XP!');
      return false;
    }

    final newAccessories = [...state.pet!.equippedAccessories, accessoryId];

    final updatedPet = state.pet!.copyWith(
      petXP: newPetXP,
      equippedAccessories: newAccessories,
    );

    final accDbId = await _db.getCyberPetDbId(state.pet!.petId);
    await _db.updateCyberPet(accDbId, CyberPetsCompanion(
      petXp: Value(newPetXP),
      equippedAccessories: Value(newAccessories.join(',')),
    ));

    state = state.copyWith(pet: updatedPet);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Get accessories catalog
  // ---------------------------------------------------------------------------

  List<PetAccessory> get accessoriesCatalog => _accessoriesCatalog;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _getRandomDialogue(PetMood mood, PetEvolution evolution) {
    final dialogues = _moodDialogues[mood] ?? _moodDialogues[PetMood.neutral]!;
    final eligible = dialogues.where(
      (d) => evolution.index >= d.minEvolution.index,
    );
    if (eligible.isEmpty) return '...';
    return eligible.elementAt(Random().nextInt(eligible.length)).textUA;
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final cyberPetProvider =
    StateNotifierProvider<CyberPetNotifier, CyberPetState>((ref) {
  final db = ref.watch(databaseProvider);
  return CyberPetNotifier(ref, db);
});
