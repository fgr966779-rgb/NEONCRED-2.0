import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../services/savings_graveyard_service.dart';

// =========================================================================
// SavingsGraveyardScreen — cyberpunk graveyard with tombstones
// =========================================================================

class SavingsGraveyardScreen extends ConsumerStatefulWidget {
  const SavingsGraveyardScreen({super.key});

  @override
  ConsumerState<SavingsGraveyardScreen> createState() =>
      _SavingsGraveyardScreenState();
}

class _SavingsGraveyardScreenState
    extends ConsumerState<SavingsGraveyardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savingsGraveyardProvider.notifier).loadGraveyard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(savingsGraveyardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1FAA6} Цвинтар Заощаджень',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontFamily: 'Cyberpunk',
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
          : RefreshIndicator(
              color: const Color(0xFF00F0FF),
              backgroundColor: const Color(0xFF0D1117),
              onRefresh: () =>
                  ref.read(savingsGraveyardProvider.notifier).loadGraveyard(),
              child: CustomScrollView(
                slivers: [
                  // Stats header
                  SliverToBoxAdapter(child: _GraveyardStatsCard(stats: state.stats)),

                  // Necromancer achievement badge
                  if (ref
                      .read(savingsGraveyardProvider.notifier)
                      .checkNecromancerAchievement())
                    const SliverToBoxAdapter(
                      child: _NecromancerAchievementBadge(),
                    ),

                  // Error message
                  if (state.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: Color(0xFFFF3366)),
                        ),
                      ),
                    ),

                  // Empty state
                  if (state.entries.isEmpty && !state.isLoading)
                    const SliverToBoxAdapter(
                      child: _EmptyGraveyardState(),
                    ),

                  // Tombstone list
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _TombstoneCard(entry: state.entries[index]),
                      childCount: state.entries.length,
                    ),
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
    );
  }
}

// =========================================================================
// Stats card
// =========================================================================

class _GraveyardStatsCard extends StatelessWidget {
  final GraveyardStats stats;

  const _GraveyardStatsCard({required this.stats});

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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'СТАТИСТИКА ЦВИНТАРЯ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Поховань',
                value: '${stats.totalDeaths}',
                color: const Color(0xFFFF3366),
              ),
              _StatItem(
                label: 'Воскресінь',
                value: '${stats.totalResurrections}',
                color: const Color(0xFF00F0FF),
              ),
              _StatItem(
                label: 'Втрачено',
                value: '${stats.totalLostValue.toStringAsFixed(0)}\u{20B4}',
                color: const Color(0xFFFF6B00),
              ),
              _StatItem(
                label: 'Врятовано',
                value:
                    '${stats.totalResurrectedValue.toStringAsFixed(0)}\u{20B4}',
                color: const Color(0xFF00FF88),
              ),
            ],
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

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8888AA),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// Necromancer achievement badge
// =========================================================================

class _NecromancerAchievementBadge extends StatelessWidget {
  const _NecromancerAchievementBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B00FF), Color(0xFF00F0FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B00FF).withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Row(
        children: [
          Text(
            '\u{26A1}',
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'НЕКРОМАНТ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '3+ воскресінь цілей! Ти пануєш над цифровою смертю!',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Tombstone card — the core UI element of the graveyard
// =========================================================================

class _TombstoneCard extends ConsumerWidget {
  final GraveyardEntry entry;

  const _TombstoneCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(savingsGraveyardProvider.notifier);
    final canRevive = notifier.canResurrect(entry);
    final remaining = notifier.resurrectionTimeRemaining(entry);

    final isResurrected = entry.isResurrected;
    final progress = entry.targetAmount > 0
        ? (entry.savedAmount / entry.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    // Color coding based on status
    final borderColor = isResurrected
        ? const Color(0xFF00FF88)
        : canRevive
            ? const Color(0xFF00F0FF)
            : const Color(0xFFFF3366);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — goal name + status
          Row(
            children: [
              Text(
                isResurrected
                    ? '\u{26A1}'
                    : canRevive
                        ? '\u{1FAA6}'
                        : '\u{1F300}',
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.goalName,
                  style: TextStyle(
                    color: borderColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StatusBadge(
                isResurrected: isResurrected,
                canRevive: canRevive,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Epitaph
          if (entry.epitaph != null && entry.epitaph!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0A2E).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6B00FF).withOpacity(0.2),
                ),
              ),
              child: Text(
                '"${entry.epitaph}"',
                style: const TextStyle(
                  color: Color(0xFFB088FF),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.savedAmount.toStringAsFixed(0)}\u{20B4}',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${entry.targetAmount.toStringAsFixed(0)}\u{20B4}',
                    style: const TextStyle(
                      color: Color(0xFFFF3366),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: const Color(0xFF1A0A2E),
                  valueColor: AlwaysStoppedAnimation<Color>(borderColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Death date & reason
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF8888AA),
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'Дата смерті: ${_formatDate(entry.deathDate)}',
                style: const TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          if (entry.deathReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Причина: ${entry.deathReason}',
              style: const TextStyle(
                color: Color(0xFF666688),
                fontSize: 11,
              ),
            ),
          ],

          // Resurrection info
          if (canRevive && !isResurrected) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00F0FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\u{26A1} Вікно воскресіння: ${_formatDuration(remaining)}',
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await ref
                            .read(savingsGraveyardProvider.notifier)
                            .resurrectGoal(entry.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '\u{26A1} Ціль воскрешено! +150 XP!'
                                    : '\u{1F480} Вікно воскресіння закрито...',
                              ),
                              backgroundColor: success
                                  ? const Color(0xFF00FF88)
                                  : const Color(0xFFFF3366),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00F0FF),
                        foregroundColor: const Color(0xFF0A0E17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '\u{26A1} ВОСКРЕСИТИ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isResurrected && entry.resurrectionDate != null) ...[
            const SizedBox(height: 12),
            Text(
              '\u{26A1} Воскреслено: ${_formatDate(entry.resurrectionDate!)}',
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatDuration(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;

    if (days > 0) return '$daysд ${hours}г ${minutes}хв';
    if (hours > 0) return '$hoursг ${minutes}хв';
    return '$minutesхв';
  }
}

// =========================================================================
// Status badge widget
// =========================================================================

class _StatusBadge extends StatelessWidget {
  final bool isResurrected;
  final bool canRevive;

  const _StatusBadge({
    required this.isResurrected,
    required this.canRevive,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = isResurrected
        ? ('ВОСКРЕШЕНО', const Color(0xFF00FF88))
        : canRevive
            ? ('МОЖНА ВИРЯТУВАТИ', const Color(0xFF00F0FF))
            : ('ЦИФРОВИЙ ПИЛ', const Color(0xFFFF3366));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// =========================================================================
// Empty state
// =========================================================================

class _EmptyGraveyardState extends StatelessWidget {
  const _EmptyGraveyardState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withOpacity(0.2),
        ),
      ),
      child: const Column(
        children: [
          Text(
            '\u{1F3F0}',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 16),
          Text(
            'Цвинтар порожній',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Твої цілі ще живі! Продовжуй зберігати — '
            'не дай їм потрапити сюди.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
