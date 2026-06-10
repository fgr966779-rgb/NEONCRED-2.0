import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../providers/cyber_pet_provider.dart';

// =============================================================================
// Cyber-Pet Companion Screen — Cyberpunk Tamagotchi UI
// =============================================================================

class CyberPetScreen extends ConsumerStatefulWidget {
  const CyberPetScreen({super.key});

  @override
  ConsumerState<CyberPetScreen> createState() => _CyberPetScreenState();
}

class _CyberPetScreenState extends ConsumerState<CyberPetScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Design tokens
  // ---------------------------------------------------------------------------
  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _red = Color(0xFFFF2244);

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    Future.microtask(
      () => ref.read(cyberPetProvider.notifier).loadPet(),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Mood → glow colour
  // ---------------------------------------------------------------------------
  Color _moodGlowColor(PetMood mood) {
    switch (mood) {
      case PetMood.ecstatic:
        return _green;
      case PetMood.happy:
        return _cyan;
      case PetMood.neutral:
        return _purple;
      case PetMood.sad:
        return _pink;
      case PetMood.critical:
        return _red;
    }
  }

  // ---------------------------------------------------------------------------
  // Species description map
  // ---------------------------------------------------------------------------
  String _speciesDescription(PetSpecies species) {
    switch (species) {
      case PetSpecies.neonCat:
        return 'Елегантна та незалежна. Нейонові лапки світяться у темряві, а мурчання заряджає скарбничку.';
      case PetSpecies.circuitDog:
        return 'Відданий та енергійний. Схема на шерсті пульсує разом із депозитами.';
      case PetSpecies.dataDragon:
        return 'Могутній та мудрий. Дані течуть крізь крила, а вогонь живиться стріками.';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final petState = ref.watch(cyberPetProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: petState.pet == null
          ? _buildCreationScreen(petState)
          : _buildPetView(petState),
    );
  }

  // =============================================================================
  // CREATION SCREEN
  // =============================================================================

  Widget _buildCreationScreen(CyberPetState petState) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Title -----------------------------------------------------------
            Text(
              'ОБЕРИ СВОГО КІБЕР-ПІТА',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: _cyan,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: _cyan.withOpacity(0.4), blurRadius: 16),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Твій компаньйон заощаджень чекає на тебе',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Species cards ----------------------------------------------------
            ...PetSpecies.values.map(
              (species) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SpeciesCard(
                  species: species,
                  description: _speciesDescription(species),
                  cyan: _cyan,
                  onTap: () => _showNameDialog(species),
                ),
              ),
            ),

            // Error indicator
            if (petState.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  petState.error!,
                  style: const TextStyle(color: _pink, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Name dialog
  // ---------------------------------------------------------------------------
  void _showNameDialog(PetSpecies species) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _cyan.withOpacity(0.4)),
          ),
          title: Text(
            'Як звати твого ${species.uaName}?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${species.emoji} ${species.uaName}',
                style: TextStyle(
                  fontSize: 28,
                  color: _cyan,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 20,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Введи ім\'я...',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cyan),
                  ),
                  counterStyle: TextStyle(color: Colors.white38),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Скасувати',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref
                    .read(cyberPetProvider.notifier)
                    .createPet(species, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Створити'),
            ),
          ],
        );
      },
    );
  }

  // =============================================================================
  // PET VIEW
  // =============================================================================

  Widget _buildPetView(CyberPetState petState) {
    final pet = petState.pet!;
    final stats = petState.stats;
    final glowColor = _moodGlowColor(pet.mood);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // 1. Pet display ---------------------------------------------------
            _buildPetDisplay(pet, glowColor),
            const SizedBox(height: 16),

            // 2. Dialogue bubble -----------------------------------------------
            _buildDialogueBubble(pet),
            const SizedBox(height: 20),

            // 3. Stats bars ----------------------------------------------------
            _buildStatsBars(pet),
            const SizedBox(height: 20),

            // 4. Evolution progress --------------------------------------------
            _buildEvolutionProgress(pet),
            const SizedBox(height: 20),

            // 5. Action buttons ------------------------------------------------
            _buildActionButtons(petState),
            const SizedBox(height: 20),

            // 6. Stats card ----------------------------------------------------
            _buildStatsCard(pet, stats),
            const SizedBox(height: 20),

            // 7. Accessories ---------------------------------------------------
            _buildAccessories(pet),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Pet display — 200×200 circle with pulse glow
  // ---------------------------------------------------------------------------
  Widget _buildPetDisplay(CyberPetData pet, Color glowColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.5 + 0.5 * _pulseController.value;
        final glowRadius = 20.0 + 16.0 * pulseValue;

        return Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF111827),
              border: Border.all(
                color: glowColor.withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.35 * pulseValue),
                  blurRadius: glowRadius,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: glowColor.withOpacity(0.15),
                  blurRadius: glowRadius * 2,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Species emoji
                Text(
                  pet.species.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                // Evolution badge — top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _purple.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${pet.evolution.emoji} ${pet.evolution.labelUA}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Mood indicator — bottom
                Positioned(
                  bottom: 14,
                  child: Text(
                    pet.mood.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Dialogue bubble
  // ---------------------------------------------------------------------------
  Widget _buildDialogueBubble(CyberPetData pet) {
    final dialogue = pet.currentDialogue ?? '...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _cyan.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pet.species.emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _cyan,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dialogue,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Stats bars — Health + Happiness
  // ---------------------------------------------------------------------------
  Widget _buildStatsBars(CyberPetData pet) {
    return Column(
      children: [
        _StatBar(
          label: 'Здоров\'я',
          value: pet.health,
          color: pet.health >= 70
              ? _green
              : pet.health >= 40
                  ? _cyan
                  : pet.health >= 20
                      ? _pink
                      : _red,
        ),
        const SizedBox(height: 12),
        _StatBar(
          label: 'Щастя',
          value: pet.happiness,
          color: pet.happiness >= 70
              ? _green
              : pet.happiness >= 40
                  ? _cyan
                  : pet.happiness >= 20
                      ? _pink
                      : _red,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Evolution progress
  // ---------------------------------------------------------------------------
  Widget _buildEvolutionProgress(CyberPetData pet) {
    final nextEvo = pet.evolution.next;
    final isMaxEvolution = nextEvo == pet.evolution;
    final progress = isMaxEvolution ? 1.0 : pet.evolutionProgress;
    final nextReq = nextEvo.xpRequired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ЕВОЛЮЦІЯ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _purple,
                  letterSpacing: 2,
                ),
              ),
              Text(
                isMaxEvolution
                    ? 'МАКС'
                    : '${pet.petXP} / ${nextReq} XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${pet.evolution.emoji} ${pet.evolution.labelUA}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!isMaxEvolution) ...[
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 14, color: _purple),
                const SizedBox(width: 8),
                Text(
                  '${nextEvo.emoji} ${nextEvo.labelUA}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                isMaxEvolution ? _green : _purple,
              ),
            ),
          ),
          if (!isMaxEvolution) ...[
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% до наступної еволюції',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white38,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Action buttons row
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons(CyberPetState petState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionButton(
          emoji: '🤚',
          label: 'Погладити',
          color: _cyan,
          isLoading: false,
          onTap: () => ref.read(cyberPetProvider.notifier).petThePet(),
        ),
        _ActionButton(
          emoji: '💬',
          label: 'Поговорити',
          color: _purple,
          isLoading: petState.isTalking,
          onTap: () async {
            final dialogue =
                await ref.read(cyberPetProvider.notifier).generateAiDialogue();
            if (mounted && dialogue.isNotEmpty) {
              ref.read(cyberPetProvider.notifier).loadPet();
            }
          },
        ),
        _ActionButton(
          emoji: '🍖',
          label: 'Годувати 100₴',
          color: _green,
          isLoading: petState.isFeeding,
          onTap: () => ref.read(cyberPetProvider.notifier).feedPet(100),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Stats card
  // ---------------------------------------------------------------------------
  Widget _buildStatsCard(CyberPetData pet, CyberPetStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _cyan.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'СТАТИСТИКА',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _cyan,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                emoji: '📅',
                value: '${stats.daysTogether}',
                label: 'Днів разом',
              ),
              _StatItem(
                emoji: '🍖',
                value: '${stats.totalFeedings}',
                label: 'Годувань',
              ),
              _StatItem(
                emoji: '🔥',
                value: '${pet.streakDays}',
                label: 'Стрік',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. Accessories grid
  // ---------------------------------------------------------------------------
  Widget _buildAccessories(CyberPetData pet) {
    final catalog = ref.read(cyberPetProvider.notifier).accessoriesCatalog;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'АКСЕСУАРИ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: _purple,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: catalog.map((accessory) {
            final isOwned =
                pet.equippedAccessories.contains(accessory.accessoryId);
            final isLocked =
                pet.evolution.index < accessory.minEvolution.index;
            final canAfford = pet.petXP >= accessory.xpCost;
            final isAvailable = !isOwned && !isLocked;

            Color borderColor;
            Color bgColor;
            Color textColor;

            if (isOwned) {
              borderColor = _green;
              bgColor = _green.withOpacity(0.12);
              textColor = _green;
            } else if (isLocked) {
              borderColor = Colors.white12;
              bgColor = Colors.white.withOpacity(0.03);
              textColor = Colors.white24;
            } else if (canAfford) {
              borderColor = _cyan.withOpacity(0.5);
              bgColor = _cyan.withOpacity(0.08);
              textColor = _cyan;
            } else {
              borderColor = _pink.withOpacity(0.3);
              bgColor = _pink.withOpacity(0.05);
              textColor = _pink;
            }

            return GestureDetector(
              onTap: isAvailable
                  ? () => _onAccessoryTap(accessory, canAfford)
                  : null,
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 3,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      accessory.emoji,
                      style: TextStyle(
                        fontSize: 28,
                        color: isLocked ? Colors.white12 : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accessory.nameUA,
                      style: TextStyle(
                        fontSize: 10,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (isOwned)
                      Text(
                        '✓ Маєш',
                        style: TextStyle(
                          fontSize: 9,
                          color: _green,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else if (isLocked)
                      Text(
                        '🔒 ${accessory.minEvolution.labelUA}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white24,
                        ),
                      )
                    else
                      Text(
                        '${accessory.xpCost} XP',
                        style: TextStyle(
                          fontSize: 9,
                          color: canAfford ? _cyan : _pink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Accessory tap handler
  // ---------------------------------------------------------------------------
  void _onAccessoryTap(PetAccessory accessory, bool canAfford) {
    if (!canAfford) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          content: Text(
            'Недостатньо XP! Потрібно ${accessory.xpCost} XP',
            style: const TextStyle(color: _pink),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _purple.withOpacity(0.4)),
          ),
          title: Text(
            '${accessory.emoji} ${accessory.nameUA}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Купити за ${accessory.xpCost} XP?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Ні',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final success = await ref
                    .read(cyberPetProvider.notifier)
                    .buyAccessory(accessory.accessoryId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF111827),
                      content: Text(
                        success
                            ? '${accessory.emoji} ${accessory.nameUA} придбано!'
                            : 'Не вдалося купити аксессуар',
                        style: TextStyle(
                          color: success ? _green : _pink,
                        ),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Купити'),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

/// Species selection card on the creation screen.
class _SpeciesCard extends StatelessWidget {
  final PetSpecies species;
  final String description;
  final Color cyan;
  final VoidCallback onTap;

  const _SpeciesCard({
    required this.species,
    required this.description,
    required this.cyan,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cyan.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cyan.withOpacity(0.06),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cyan.withOpacity(0.08),
                border: Border.all(
                  color: cyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  species.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.uaName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cyan,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: cyan.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat bar with label, percentage and progress indicator.
class _StatBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value.clamp(0.0, 100.0) / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Circular action button.
class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Text(
                      emoji,
                      style: const TextStyle(fontSize: 26),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat item for the stats card.
class _StatItem extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatItem({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
