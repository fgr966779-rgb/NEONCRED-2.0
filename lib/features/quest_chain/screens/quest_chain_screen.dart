import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/quest_chain_provider.dart';

// =============================================================================
// Savings Quest Chain Screen — Retention 2026 Feature #1
// =============================================================================
// Cyberpunk-themed UI for gamified savings quest chains with XP multipliers.
// =============================================================================

class QuestChainScreen extends ConsumerStatefulWidget {
  const QuestChainScreen({super.key});

  @override
  ConsumerState<QuestChainScreen> createState() => _QuestChainScreenState();
}

class _QuestChainScreenState extends ConsumerState<QuestChainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questChainProvider.notifier).loadQuests();
    });
  }

  static const _bg = Color(0xFF0A0E17);
  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questChainProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ЛАНЦЮГ КВЕСТІВ',
          style: GoogleFonts.orbitron(
            color: _cyan,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _cyan, _purple, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Stats Banner ──────────────────────────────────────────
          SliverToBoxAdapter(child: _StatsBanner(state: state)),

          // ── Error Banner ──────────────────────────────────────────
          if (state.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(error: state.error!)),

          // ── Loading ───────────────────────────────────────────────
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _cyan)),
              ),
            ),

          // ── Quest List ────────────────────────────────────────────
          if (state.quests.isEmpty && !state.isLoading)
            SliverToBoxAdapter(
              child: _EmptyStateCard(onGenerate: _generateChain),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _QuestCard(model: state.quests[index]),
                childCount: state.quests.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateChain,
        backgroundColor: _purple,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  void _generateChain() {
    ref.read(questChainProvider.notifier).generateNewChain();
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _StatsBanner extends StatelessWidget {
  final QuestChainState state;
  const _StatsBanner({required this.state});

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _yellow = Color(0xFFFFD700);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D0A28), Color(0xFF0A0E17)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'КВЕСТИ ЗААОЩАДЖЕННЯ',
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: 'АКТИВНІ',
                value: '${state.activeQuestCount}',
                color: _cyan,
              ),
              _StatItem(
                label: 'ЛАНЦЮГИ',
                value: '${state.activeChains}',
                color: _purple,
              ),
              _StatItem(
                label: 'ВИКОНАНО',
                value: '${state.completedChains}',
                color: _green,
              ),
              _StatItem(
                label: 'XP ЗАРОБЛЕНО',
                value: '${state.totalXpEarned}',
                color: _yellow,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multiplier explanation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _yellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _yellow.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: _yellow, size: 14),
                const SizedBox(width: 4),
                Text(
                  'x1.5 за 3 підряд  |  x2 за 5 підряд  |  +25 XP за весь ланцюг',
                  style: GoogleFonts.shareTechMono(color: _yellow, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(color: color, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 8),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3366).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF3366)),
      ),
      child: Text(
        error,
        style: GoogleFonts.shareTechMono(color: const Color(0xFFFF3366), fontSize: 12),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyStateCard({required this.onGenerate});

  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'ЛАНЦЮГ КВЕСТІВ',
            style: GoogleFonts.orbitron(color: _cyan, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Виконуй мікро-квести підряд — отримай множник XP! '
            '3 квести поспіль = x1.5, 5 квестів = x2. Пропустиш — ланцюг згорить!',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.auto_awesome),
            label: Text('ГЕНЕРУВАТИ КВЕСТИ', style: GoogleFonts.orbitron(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: _cyan),
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends ConsumerWidget {
  final QuestModel model;
  const _QuestCard({required this.model});

  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = model.isActive;
    final isComplete = model.isQuestComplete;
    final isFailed = model.isQuestFailed;

    final accentColor = isComplete
        ? _green
        : isFailed
            ? _pink
            : _cyan;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Chain position + Quest type ───────────────
          Row(
            children: [
              // Chain position badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _purple.withOpacity(0.4)),
                ),
                child: Text(
                  '${model.data.chainPosition}/${model.data.chainLength}',
                  style: GoogleFonts.orbitron(
                    color: _purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Quest type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  model.data.questType.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: accentColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              // Status icon
              if (isComplete)
                const Icon(Icons.check_circle, color: _green, size: 20)
              else if (isFailed)
                const Icon(Icons.cancel, color: _pink, size: 20)
              else
                const Icon(Icons.pending, color: _yellow, size: 20),
            ],
          ),
          const SizedBox(height: 10),

          // ── Quest Name ────────────────────────────────────────
          Text(
            model.data.questName,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // ── Progress Bar ──────────────────────────────────────
          if (isActive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${model.data.currentValue.toStringAsFixed(0)} / ${model.data.targetValue.toStringAsFixed(0)}',
                  style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
                ),
                Text(
                  '${(model.questProgress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.shareTechMono(color: accentColor, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: model.questProgress,
                backgroundColor: const Color(0xFF1A1A2E),
                color: accentColor,
                minHeight: 6,
              ),
            ),
          ],

          // ── Completed info ────────────────────────────────────
          if (isComplete) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: _green, size: 14),
                const SizedBox(width: 6),
                Text(
                  'ВИКОНАНО',
                  style: GoogleFonts.orbitron(color: _green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // XP reward with multiplier
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _yellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+${model.actualXpReward} XP',
                    style: GoogleFonts.orbitron(
                      color: _yellow,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (model.effectiveXpMultiplier > 1.0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: _pink.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'x${model.effectiveXpMultiplier.toStringAsFixed(1)}',
                      style: GoogleFonts.orbitron(
                        color: _pink,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // ── Failed info ───────────────────────────────────────
          if (isFailed) ...[
            Row(
              children: [
                const Icon(Icons.cancel_outlined, color: _pink, size: 14),
                const SizedBox(width: 6),
                Text(
                  'ПРОВАЛЕНО - ЛАНЦЮГ ЗГОРИВ',
                  style: GoogleFonts.orbitron(color: _pink, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          // ── Expires info ──────────────────────────────────────
          if (isActive) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.timer, color: Colors.white24, size: 12),
                const SizedBox(width: 4),
                Text(
                  _formatExpiry(model.data.expiresAt),
                  style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          ],

          // ── Actions ───────────────────────────────────────────
          if (isActive) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => ref
                      .read(questChainProvider.notifier)
                      .failQuest(model.data.id),
                  icon: const Icon(Icons.close, color: _pink, size: 14),
                  label: Text(
                    'ПРОВАЛИТИ',
                    style: GoogleFonts.shareTechMono(color: _pink, fontSize: 9),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatExpiry(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inHours <= 0) return 'МИНУВ';
    if (diff.inDays > 0) return '${diff.inDays}д ${diff.inHours % 24}год';
    return '${diff.inHours}год ${diff.inMinutes % 60}хв';
  }
}
