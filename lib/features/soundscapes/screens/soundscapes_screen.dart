import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/soundscapes_provider.dart';

// =============================================================================
// SoundscapesScreen — Cyberpunk deposit sound design UI
// =============================================================================
//
// Two-tab screen: ЗВУКИ (catalog) + ПРЕВ'Ю (test/playback).
// All text in Ukrainian. Neon gradient cyberpunk aesthetic.
// =============================================================================

class SoundscapesScreen extends ConsumerStatefulWidget {
  const SoundscapesScreen({super.key});

  @override
  ConsumerState<SoundscapesScreen> createState() => _SoundscapesScreenState();
}

class _SoundscapesScreenState extends ConsumerState<SoundscapesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController(text: '500');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load collection on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundscapesProvider.notifier).loadCollection();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Color constants
  // ---------------------------------------------------------------------------

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);

  /// Border color per tier for visual differentiation.
  Color _tierColor(SoundTier tier) => switch (tier) {
        SoundTier.tiny => _green,
        SoundTier.small => _cyan,
        SoundTier.medium => _purple,
        SoundTier.large => _pink,
        SoundTier.epic => const Color(0xFFFFD700), // Gold
        SoundTier.jackpot => const Color(0xFFFF00FF), // Magenta
      };

  /// Gradient per tier for card decoration.
  LinearGradient _tierGradient(SoundTier tier) => switch (tier) {
        SoundTier.tiny => LinearGradient(
            colors: [_green.withValues(alpha: 0.15), _bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        SoundTier.small => LinearGradient(
            colors: [_cyan.withValues(alpha: 0.15), _bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        SoundTier.medium => LinearGradient(
            colors: [_purple.withValues(alpha: 0.15), _bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        SoundTier.large => LinearGradient(
            colors: [_pink.withValues(alpha: 0.15), _bg],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        SoundTier.epic => LinearGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: 0.2),
              _bg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        SoundTier.jackpot => LinearGradient(
            colors: [
              const Color(0xFFFF00FF).withValues(alpha: 0.25),
              _bg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
      };

  // ---------------------------------------------------------------------------
  // Group sounds by tier, filtering out streak/jackpot into separate section
  // ---------------------------------------------------------------------------

  List<SoundEffect> _soundsForTier(List<SoundEffect> catalog, SoundTier tier) {
    // Streak and jackpot sounds are shown in separate sections
    final streakIds = {
      'streak_day_3',
      'streak_day_7',
      'streak_day_14',
      'streak_day_30',
    };
    final jackpotIds = {'vault_eruption'};

    if (tier == SoundTier.jackpot) {
      return catalog.where((s) => jackpotIds.contains(s.soundId)).toList();
    }

    return catalog
        .where((s) => s.tier == tier && !streakIds.contains(s.soundId) && !jackpotIds.contains(s.soundId))
        .toList();
  }

  List<SoundEffect> _streakSounds(List<SoundEffect> catalog) {
    const ids = [
      'streak_day_3',
      'streak_day_7',
      'streak_day_14',
      'streak_day_30',
    ];
    return ids
        .map((id) => catalog.where((s) => s.soundId == id).firstOrNull)
        .whereType<SoundEffect>()
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(soundscapesProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSoundsTab(state),
                _buildPreviewTab(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: true,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_cyan, _purple, _pink],
        ).createShader(bounds),
        child: const Text(
          'SOUNDSCAPES',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            color: Colors.white,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: _cyan),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_cyan, _purple, _pink]),
          ),
          child: SizedBox(height: 1, width: double.infinity),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab Bar
  // ---------------------------------------------------------------------------

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withValues(alpha: 0.3), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [_cyan, _purple]),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          letterSpacing: 1.5,
        ),
        tabs: const [
          Tab(text: 'ЗВУКИ'),
          Tab(text: 'ПРЕВ\'Ю'),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1 — ЗВУКИ (Sound Catalog)
  // ===========================================================================

  Widget _buildSoundsTab(SoundscapesState state) {
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.error!,
            style: const TextStyle(color: _pink, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final catalog = state.soundCatalog;
    final collection = state.collection;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ── Active sound card ─────────────────────────────────────────────
        _buildActiveSoundCard(collection, catalog),
        const SizedBox(height: 20),

        // ── Tier sections ─────────────────────────────────────────────────
        ...SoundTier.values.expand((tier) {
          final sounds = _soundsForTier(catalog, tier);
          if (sounds.isEmpty) return <Widget>[];
          return [
            _buildTierHeader(tier),
            const SizedBox(height: 8),
            ...sounds.map((s) => _buildSoundCard(s, collection)),
            const SizedBox(height: 16),
          ];
        }),

        // ── Streak section ────────────────────────────────────────────────
        _buildStreakSectionHeader(),
        const SizedBox(height: 8),
        ..._streakSounds(catalog).map((s) => _buildSoundCard(s, collection)),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Active sound card
  // ---------------------------------------------------------------------------

  Widget _buildActiveSoundCard(SoundCollection collection, List<SoundEffect> catalog) {
    final activeSound = collection.activeSoundId != null
        ? catalog.where((s) => s.soundId == collection.activeSoundId).firstOrNull
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1035), Color(0xFF0A0E17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _cyan.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _cyan.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_cyan, _purple]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'АКТИВНИЙ ЗВУК',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.volume_up,
                color: _cyan.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activeSound != null) ...[
            Text(
              '${activeSound.tier.emoji}  ${activeSound.nameUA}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeSound.descriptionUA,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip('${activeSound.frequencyLabel}', _cyan),
                const SizedBox(width: 8),
                _buildInfoChip('${activeSound.durationLabel}', _purple),
                const SizedBox(width: 8),
                _buildInfoChip(activeSound.tier.labelUA, _tierColor(activeSound.tier)),
              ],
            ),
          ] else ...[
            Text(
              'Оберіть активний звук',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Натисніть на розблокований звук у каталозі нижче',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tier section header
  // ---------------------------------------------------------------------------

  Widget _buildTierHeader(SoundTier tier) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_tierColor(tier), _tierColor(tier).withValues(alpha: 0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${tier.emoji}  ${tier.labelUA.toUpperCase()}',
          style: TextStyle(
            color: _tierColor(tier),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          tier == SoundTier.jackpot
              ? ''
              : tier == SoundTier.epic
                  ? '10000+ ₴'
                  : '${tier.minAmount.toStringAsFixed(0)}–${tier.maxAmount == double.infinity ? '∞' : tier.maxAmount.toStringAsFixed(0)} ₴',
          style: TextStyle(
            color: _tierColor(tier).withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Streak section header
  // ---------------------------------------------------------------------------

  Widget _buildStreakSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_green, _green.withValues(alpha: 0.3)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          '🔥  СТРІК',
          style: TextStyle(
            color: _green,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Бонусні звуки',
          style: TextStyle(
            color: _green.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Individual sound card
  // ---------------------------------------------------------------------------

  Widget _buildSoundCard(SoundEffect sound, SoundCollection collection) {
    final isUnlocked = collection.unlockedSounds.contains(sound.soundId) ||
        sound.isUnlocked;
    final isActive = collection.activeSoundId == sound.soundId;
    final tierCol = _tierColor(sound.tier);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _onSoundTap(sound, isUnlocked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: _tierGradient(sound.tier),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? _cyan
                  : isUnlocked
                      ? tierCol.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _cyan.withValues(alpha: 0.2),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // ── Icon area ──────────────────────────────────────────────
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: [
                            tierCol.withValues(alpha: 0.3),
                            tierCol.withValues(alpha: 0.1),
                          ],
                        )
                      : null,
                  color: isUnlocked ? null : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isUnlocked
                        ? tierCol.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Center(
                  child: isUnlocked
                      ? Icon(
                          isActive ? Icons.equalizer : Icons.music_note,
                          color: isActive ? _cyan : tierCol,
                          size: 22,
                        )
                      : Icon(
                          Icons.lock_outline,
                          color: Colors.white.withValues(alpha: 0.25),
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Text area ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sound.nameUA,
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTierBadge(sound.tier),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [_cyan, _purple]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'АКТИВ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sound.descriptionUA,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: isUnlocked ? 0.5 : 0.25),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isUnlocked && sound.unlockRequirement != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '🔓 ${sound.unlockRequirement}',
                        style: TextStyle(
                          color: _pink.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Right indicator ────────────────────────────────────────
              if (isUnlocked)
                Icon(
                  isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isActive ? _cyan : tierCol.withValues(alpha: 0.4),
                  size: 20,
                )
              else
                Icon(
                  Icons.lock,
                  color: Colors.white.withValues(alpha: 0.15),
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tier badge
  // ---------------------------------------------------------------------------

  Widget _buildTierBadge(SoundTier tier) {
    final col = _tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: col.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        tier.labelUA,
        style: TextStyle(
          color: col,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Info chip (for active sound card)
  // ---------------------------------------------------------------------------

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sound tap handler
  // ---------------------------------------------------------------------------

  void _onSoundTap(SoundEffect sound, bool isUnlocked) {
    if (isUnlocked) {
      // Set as active
      ref.read(soundscapesProvider.notifier).setActiveSound(sound.soundId);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _cyan.withValues(alpha: 0.4)),
          ),
          content: Row(
            children: [
              Icon(Icons.equalizer, color: _cyan, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${sound.tier.emoji} ${sound.nameUA} — активний звук',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Attempt to unlock
      _showUnlockDialog(sound);
    }
  }

  // ---------------------------------------------------------------------------
  // Unlock confirmation dialog
  // ---------------------------------------------------------------------------

  void _showUnlockDialog(SoundEffect sound) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _tierColor(sound.tier).withValues(alpha: 0.5)),
        ),
        title: Row(
          children: [
            Text(sound.tier.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                sound.nameUA,
                style: TextStyle(
                  color: _tierColor(sound.tier),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sound.descriptionUA,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _pink.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: _pink, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Вимога: ${sound.unlockRequirement ?? "Невідомо"}',
                      style: const TextStyle(
                        color: _pink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Розблокувати цей звук? (+5 XP)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Скасувати',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(soundscapesProvider.notifier).unlockSound(sound.soundId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF111827),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: _green.withValues(alpha: 0.5)),
                  ),
                  content: Row(
                    children: [
                      const Icon(Icons.lock_open, color: _green, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${sound.tier.emoji} ${sound.nameUA} розблоковано! +5 XP',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _green.withValues(alpha: 0.2),
              foregroundColor: _green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: _green, width: 1),
              ),
            ),
            child: const Text('Розблокувати'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2 — ПРЕВ'Ю (Test Sounds)
  // ===========================================================================

  Widget _buildPreviewTab(SoundscapesState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // ── Amount input section ──────────────────────────────────────────
        _buildSectionTitle('🎤  ТЕСТ ЗВУКУ ДЕПОЗИТУ'),
        const SizedBox(height: 12),
        _buildAmountInputCard(state),
        const SizedBox(height: 24),

        // ── Last event display ────────────────────────────────────────────
        _buildSectionTitle('📡  ОСТАННЯ ПОДІЯ'),
        const SizedBox(height: 12),
        _buildLastEventCard(state),
        const SizedBox(height: 24),

        // ── Streak test section ───────────────────────────────────────────
        _buildSectionTitle('🔥  ТЕСТ СТРІКУ'),
        const SizedBox(height: 12),
        _buildStreakTestCard(state),
        const SizedBox(height: 24),

        // ── Jackpot test ─────────────────────────────────────────────────
        _buildSectionTitle('🎰  ТЕСТ ДЖЕКПОТУ'),
        const SizedBox(height: 12),
        _buildJackpotTestCard(state),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section title
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: _cyan.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_cyan.withValues(alpha: 0.3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Amount input card
  // ---------------------------------------------------------------------------

  Widget _buildAmountInputCard(SoundscapesState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сума депозиту (₴)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: _bg,
              hintText: 'Введіть суму...',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
              ),
              suffixText: '₴',
              suffixStyle: const TextStyle(
                color: _cyan,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _cyan.withValues(alpha: 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _cyan, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 6),
          // Quick amount buttons
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [50, 100, 500, 1000, 5000, 15000].map((amount) {
              return GestureDetector(
                onTap: () => _amountController.text = amount.toString(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _cyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: _cyan.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Text(
                    '$amount ₴',
                    style: TextStyle(
                      color: _cyan.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Play button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: state.isPlaying ? null : _playDepositSound,
              style: ElevatedButton.styleFrom(
                backgroundColor: _bg,
                foregroundColor: _cyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: state.isPlaying
                      ? Colors.white.withValues(alpha: 0.1)
                      : _cyan.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: state.isPlaying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: _cyan,
                        strokeWidth: 2,
                      ),
                    )
                  : ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_cyan, _purple],
                      ).createShader(bounds),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'ГРАТИ ЗВУК',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Last event card
  // ---------------------------------------------------------------------------

  Widget _buildLastEventCard(SoundscapesState state) {
    final event = state.lastEvent;

    if (event == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: Text(
            'Жодних подій ще не відтворено',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final soundName = state.soundCatalog
            .where((s) => s.soundId == event.soundId)
            .firstOrNull
            ?.nameUA ??
        event.soundId;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _tierColor(event.tier).withValues(alpha: 0.1),
            const Color(0xFF111827),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _tierColor(event.tier).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: _tierColor(event.tier).withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _tierColor(event.tier).withValues(alpha: 0.3),
                      _tierColor(event.tier).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  event.tier.labelUA.toUpperCase(),
                  style: TextStyle(
                    color: _tierColor(event.tier),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              if (event.isStreakBonus)
                _buildEventBadge('СТРІК', _green),
              if (event.isJackpot)
                _buildEventBadge('ДЖЕКПОТ', const Color(0xFFFF00FF)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${event.tier.emoji}  $soundName',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildInfoChip('Сума: ${event.amountLabel}', _cyan),
              const SizedBox(width: 8),
              _buildInfoChip('Тір: ${event.tier.labelUA}', _tierColor(event.tier)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${event.eventId}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Streak test card
  // ---------------------------------------------------------------------------

  Widget _buildStreakTestCard(SoundscapesState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: _green, size: 18),
              const SizedBox(width: 8),
              Text(
                'Стрік: ${state.streakCount} днів',
                style: const TextStyle(
                  color: _green,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [3, 7, 14, 30].map((days) {
              final isPlaying = state.isPlaying;
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 80) / 4,
                child: ElevatedButton(
                  onPressed: isPlaying
                      ? null
                      : () => ref
                          .read(soundscapesProvider.notifier)
                          .playStreakSound(days),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _bg,
                    foregroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(
                      color: _green.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$days',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'днів',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Jackpot test card
  // ---------------------------------------------------------------------------

  Widget _buildJackpotTestCard(SoundscapesState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A25), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF00FF).withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF00FF).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎰  ВИВЕРЖЕННЯ СЕЙФУ',
            style: TextStyle(
              color: Color(0xFFFF00FF),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Натисніть для тесту джекпот-звуку',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: state.isPlaying
                  ? null
                  : () =>
                      ref.read(soundscapesProvider.notifier).playJackpotSound(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF00FF).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFFFF00FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: const BorderSide(
                  color: Color(0xFFFF00FF),
                  width: 1.5,
                ),
              ),
              child: state.isPlaying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF00FF),
                        strokeWidth: 2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.casino, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ГРАТИ ДЖЕКПОТ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Play deposit sound handler
  // ---------------------------------------------------------------------------

  Future<void> _playDepositSound() async {
    final text = _amountController.text.trim();
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF111827),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: _pink.withValues(alpha: 0.5)),
          ),
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: _pink, size: 18),
              SizedBox(width: 10),
              Text(
                'Введіть коректну суму',
                style: TextStyle(color: _pink, fontSize: 13),
              ),
            ],
          ),
        ),
      );
      return;
    }

    await ref.read(soundscapesProvider.notifier).playDepositSound(amount);
  }
}
