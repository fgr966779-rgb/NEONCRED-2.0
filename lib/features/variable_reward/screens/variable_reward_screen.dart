import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/variable_reward_vault_service.dart';

// =========================================================================
// VariableRewardScreen — Neon Jackpot slot machine
// =========================================================================

class VariableRewardScreen extends ConsumerWidget {
  const VariableRewardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(variableRewardProvider);
    final notifier = ref.read(variableRewardProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1F3B0} Неоновий Джекпот',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: CustomScrollView(
        slivers: [
          // Current probability & encouragement
          SliverToBoxAdapter(
            child: _ProbabilityCard(
              stats: state.stats,
              encouragement: notifier.encouragementMessage,
              currentChance: notifier.currentChance,
            ),
          ),

          // Last result
          if (state.lastResult != null)
            SliverToBoxAdapter(
              child: _JackpotResultCard(result: state.lastResult!),
            ),

          // Stats overview
          SliverToBoxAdapter(
            child: _StatsOverviewCard(stats: state.stats),
          ),

          // Tier info
          const SliverToBoxAdapter(child: _TierInfoCard()),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// =========================================================================
// Probability card
// =========================================================================

class _ProbabilityCard extends StatelessWidget {
  final JackpotStats stats;
  final String encouragement;
  final double currentChance;

  const _ProbabilityCard({
    required this.stats,
    required this.encouragement,
    required this.currentChance,
  });

  @override
  Widget build(BuildContext context) {
    final isHighChance = currentChance >= 12;
    final accentColor =
        isHighChance ? const Color(0xFFFF6B00) : const Color(0xFF00F0FF);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.15), const Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(isHighChance ? 0.5 : 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${currentChance.toStringAsFixed(0)}%',
            style: TextStyle(
              color: accentColor,
              fontSize: 56,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'ШАНС ДЖЕКПОТУ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A2E).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              encouragement,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${stats.totalDepositsSinceLastJackpot} депозитів без джекпоту',
            style: const TextStyle(color: Color(0xFF8888AA), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Jackpot result card
// =========================================================================

class _JackpotResultCard extends StatelessWidget {
  final JackpotResult result;

  const _JackpotResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isWin = result.tier != JackpotTier.none;
    final tierColor = _tierColor(result.tier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tierColor.withOpacity(isWin ? 0.6 : 0.2),
          width: isWin ? 2 : 1,
        ),
        boxShadow: isWin
            ? [BoxShadow(color: tierColor.withOpacity(0.3), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          Text(
            '${result.tier.emoji} ${result.tier.labelUA}',
            style: TextStyle(
              color: tierColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${result.baseXP}',
                style: const TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 20,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${result.enhancedXP} XP',
                style: TextStyle(
                  color: tierColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (result.multiplier > 1) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'x${result.multiplier.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: tierColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (result.isNearMiss && result.nearMissMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                result.nearMissMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFF6B00),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            result.descriptionUA,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB088FF), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _tierColor(JackpotTier tier) => switch (tier) {
        JackpotTier.none => const Color(0xFF8888AA),
        JackpotTier.mini => const Color(0xFF00F0FF),
        JackpotTier.rare => const Color(0xFF6B00FF),
        JackpotTier.epic => const Color(0xFFFF6B00),
        JackpotTier.legendary => const Color(0xFFFFD700),
      };
}

// =========================================================================
// Stats overview card
// =========================================================================

class _StatsOverviewCard extends StatelessWidget {
  final JackpotStats stats;

  const _StatsOverviewCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'СТАТИСТИКА ДЖЕКПОТУ',
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
                label: 'Виграшів',
                value: '${stats.totalJackpotsWon}',
                color: const Color(0xFF00FF88),
              ),
              _StatItem(
                label: 'Без джекпоту',
                value: '${stats.currentStreakWithoutJackpot}',
                color: const Color(0xFFFF6B00),
              ),
              _StatItem(
                label: 'Останній',
                value: stats.lastJackpotTier.labelUA,
                color: const Color(0xFF00F0FF),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: JackpotTier.values
                .where((t) => t != JackpotTier.none)
                .map((tier) => _StatItem(
                      label: tier.emoji,
                      value: '${stats.jackpotsByTier[tier] ?? 0}',
                      color: const Color(0xFFB088FF),
                    ))
                .toList(),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8888AA), fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// =========================================================================
// Tier info card
// =========================================================================

class _TierInfoCard extends StatelessWidget {
  const _TierInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'РІВНІ ДЖЕКПОТУ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...JackpotTier.values
              .where((t) => t != JackpotTier.none)
              .map((tier) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(tier.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tier.labelUA,
                                style: const TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'x${tier.xpMultiplier} XP',
                                style: const TextStyle(
                                  color: Color(0xFF8888AA),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }
}
