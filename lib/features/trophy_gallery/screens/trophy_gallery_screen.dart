import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../services/trophy_gallery_service.dart';

// =========================================================================
// TrophyGalleryScreen — 3D trophy collection gallery
// =========================================================================

class TrophyGalleryScreen extends ConsumerStatefulWidget {
  const TrophyGalleryScreen({super.key});

  @override
  ConsumerState<TrophyGalleryScreen> createState() => _TrophyGalleryScreenState();
}

class _TrophyGalleryScreenState extends ConsumerState<TrophyGalleryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trophyGalleryProvider.notifier).loadGallery();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trophyGalleryProvider);
    final notifier = ref.read(trophyGalleryProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1F3C6} 3D \u{0413}\u{0430}\u{043B}\u{0435}\u{0440}\u{0435}\u{044F} \u{0422}\u{0440}\u{043E}\u{0444}\u{0435}\u{0457}\u{0432}',
          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 20),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF0D1117),
        onRefresh: () => notifier.loadGallery(),
        child: CustomScrollView(
          slivers: [
            // Completion progress card
            SliverToBoxAdapter(child: _CompletionCard(stats: state.stats)),

            // Unlocked trophies
            if (state.unlockedTrophies.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    '\u{2705} РОЗБЛОКОВАНІ',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TrophyCard(
                      trophy: state.unlockedTrophies[index],
                      isUnlocked: true,
                      onTap: () => notifier.selectTrophy(state.unlockedTrophies[index]),
                    ),
                    childCount: state.unlockedTrophies.length,
                  ),
                ),
              ),
            ],

            // Locked trophies
            if (state.lockedTrophies.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    '\u{1F512} ЗАБЛОКОВАНІ',
                    style: TextStyle(
                      color: Color(0xFF8888AA),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TrophyCard(
                      trophy: state.lockedTrophies[index],
                      isUnlocked: false,
                      onTap: null,
                    ),
                    childCount: state.lockedTrophies.length,
                  ),
                ),
              ),
            ],

            // Selected trophy detail
            if (state.selectedTrophy != null)
              SliverToBoxAdapter(
                child: _TrophyDetailCard(
                  trophy: state.selectedTrophy!,
                  viewerUrl: state.sketchfabViewerUrl,
                  onClose: () => notifier.clearSelection(),
                ),
              ),

            // Tier legend
            const SliverToBoxAdapter(child: _TierLegend()),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Completion card
// =========================================================================

class _CompletionCard extends StatelessWidget {
  final TrophyGalleryStats stats;

  const _CompletionCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${stats.unlockedCount}/${stats.totalTrophies}',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${stats.completionPercent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Color(0xFFB088FF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.completionPercent / 100,
              backgroundColor: const Color(0xFF1A0A2E),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00F0FF)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TierBadge(count: stats.commonCount, color: const Color(0xFF00FF88), label: 'C'),
              _TierBadge(count: stats.rareCount, color: const Color(0xFF00F0FF), label: 'R'),
              _TierBadge(count: stats.epicCount, color: const Color(0xFFFFAA00), label: 'E'),
              _TierBadge(count: stats.legendaryCount, color: const Color(0xFFFF3366), label: 'L'),
              _TierBadge(count: stats.mythicCount, color: const Color(0xFFB088FF), label: 'M'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  final int count;
  final Color color;
  final String label;

  const _TierBadge({required this.count, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// =========================================================================
// Trophy card (unlocked or locked)
// =========================================================================

class _TrophyCard extends StatelessWidget {
  final Trophy3D trophy;
  final bool isUnlocked;
  final VoidCallback? onTap;

  const _TrophyCard({required this.trophy, required this.isUnlocked, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColor(trophy.tier);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnlocked
              ? tierColor.withOpacity(0.08)
              : const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? tierColor.withOpacity(0.4)
                : const Color(0xFF333355),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isUnlocked) ...[
              Text(trophy.tier.iconEmoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(
                trophy.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tierColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trophy.descriptionUA,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 11,
                ),
              ),
              if (trophy.isAnimated || trophy.hasAR) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (trophy.isAnimated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F0FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '3D',
                          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (trophy.hasAR) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B00FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AR',
                          style: TextStyle(color: Color(0xFF6B00FF), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ] else ...[
              const Text('\u{2753}', style: TextStyle(fontSize: 36, color: Color(0xFF333355))),
              const SizedBox(height: 8),
              Text(
                '???',
                style: TextStyle(
                  color: const Color(0xFF333355),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trophy.milestoneAmount > 0)
                Text(
                  '${trophy.milestoneAmount.toStringAsFixed(0)} грн',
                  style: const TextStyle(
                    color: Color(0xFF444466),
                    fontSize: 11,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Trophy detail card (when selected)
// =========================================================================

class _TrophyDetailCard extends StatelessWidget {
  final Trophy3D trophy;
  final String? viewerUrl;
  final VoidCallback onClose;

  const _TrophyDetailCard({
    required this.trophy,
    this.viewerUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final tierColor = _tierColor(trophy.tier);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor.withOpacity(0.15), const Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tierColor.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(color: tierColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(trophy.tier.iconEmoji, style: const TextStyle(fontSize: 48)),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Color(0xFF8888AA))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trophy.name,
            style: TextStyle(color: tierColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            trophy.tier.labelUA,
            style: TextStyle(color: tierColor.withOpacity(0.7), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            trophy.descriptionUA,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB088FF), fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (trophy.milestoneAmount > 0)
            Text(
              'Milestone: ${trophy.milestoneAmount.toStringAsFixed(0)} грн',
              style: const TextStyle(color: Color(0xFF8888AA), fontSize: 12),
            ),
          if (viewerUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.view_in_ar, color: Color(0xFF00F0FF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sketchfab 3D Viewer available',
                      style: TextStyle(color: const Color(0xFF00F0FF), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (trophy.isAnimated)
                _Badge(text: 'Animated', color: const Color(0xFF00F0FF)),
              if (trophy.hasAR) ...[
                const SizedBox(width: 8),
                _Badge(text: 'AR Ready', color: const Color(0xFF6B00FF)),
              ],
              const SizedBox(width: 8),
              _Badge(text: '+${trophy.tier.xpReward} XP', color: const Color(0xFFFFAA00)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// =========================================================================
// Tier legend
// =========================================================================

class _TierLegend extends StatelessWidget {
  const _TierLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'РІДКІСТЬ ТРОФЕЇВ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...TrophyTier.values.map(
            (tier) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(tier.iconEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Text(
                    tier.labelUA,
                    style: TextStyle(color: _tierColor(tier), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '+${tier.xpReward} XP',
                    style: const TextStyle(color: Color(0xFF8888AA), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Utility
// =========================================================================

Color _tierColor(TrophyTier tier) => switch (tier) {
      TrophyTier.common => const Color(0xFF00FF88),
      TrophyTier.rare => const Color(0xFF00F0FF),
      TrophyTier.epic => const Color(0xFFFFAA00),
      TrophyTier.legendary => const Color(0xFFFF3366),
      TrophyTier.mythic => const Color(0xFFB088FF),
    };
