import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../services/reputation_forge_service.dart';

// =========================================================================
// ReputationForgeScreen — cyberpunk reputation dashboard
// =========================================================================

class ReputationForgeScreen extends ConsumerStatefulWidget {
  const ReputationForgeScreen({super.key});

  @override
  ConsumerState<ReputationForgeScreen> createState() =>
      _ReputationForgeScreenState();
}

class _ReputationForgeScreenState
    extends ConsumerState<ReputationForgeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reputationForgeProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reputationForgeProvider);
    final tier = ref.read(reputationForgeProvider.notifier).currentTier;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(
          '${tier.iconEmoji} Кузня Репутації',
          style: const TextStyle(
            color: Color(0xFF00F0FF),
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
                  ref.read(reputationForgeProvider.notifier).loadProfile(),
              child: CustomScrollView(
                slivers: [
                  // Reputation Score Card
                  SliverToBoxAdapter(
                    child: _ReputationScoreCard(
                      profile: state.profile,
                      tier: tier,
                    ),
                  ),

                  // Tier Progress Bar
                  SliverToBoxAdapter(
                    child: _TierProgressBar(
                      score: state.profile?.reputationScore ?? 0,
                    ),
                  ),

                  // Active Commitments
                  SliverToBoxAdapter(
                    child: _CommitmentsSection(
                      commitments: state.activeCommitments,
                    ),
                  ),

                  // Commitment cards
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _CommitmentCard(
                        commitment: state.activeCommitments[index],
                      ),
                      childCount: state.activeCommitments.length,
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }
}

// =========================================================================
// Reputation score card
// =========================================================================

class _ReputationScoreCard extends StatelessWidget {
  final ReputationProfile? profile;
  final ReputationTier tier;

  const _ReputationScoreCard({required this.profile, required this.tier});

  @override
  Widget build(BuildContext context) {
    final score = profile?.reputationScore ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A0A2E),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            tier.iconEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            tier.titleUA,
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            '/ 100',
            style: TextStyle(color: Color(0xFF8888AA), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStat(
                label: 'Клятви',
                value: '${profile?.publicCommitmentsCount ?? 0}',
              ),
              _ProfileStat(
                label: 'Виконано',
                value: '${profile?.fulfilledCommitmentsCount ?? 0}',
              ),
              _ProfileStat(
                label: 'Надійність',
                value:
                    '${((profile?.circleReliability ?? 0) * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8888AA),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// Tier progress bar
// =========================================================================

class _TierProgressBar extends StatelessWidget {
  final double score;

  const _TierProgressBar({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'РІВНІ РЕПУТАЦІЇ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          // Tier markers
          Row(
            children: ReputationTier.values.map((tier) {
              final isActive = score >= tier.minScore;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF00F0FF)
                            : const Color(0xFF1A0A2E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.iconEmoji,
                      style: TextStyle(
                        fontSize: isActive ? 16 : 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Commitments section
// =========================================================================

class _CommitmentsSection extends StatelessWidget {
  final List<PublicCommitment> commitments;

  const _CommitmentsSection({required this.commitments});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          const Text(
            '\u{1F91D} АКТИВНІ КЛЯТВИ',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Text(
            '${commitments.length}',
            style: const TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Commitment card
// =========================================================================

class _CommitmentCard extends StatelessWidget {
  final PublicCommitment commitment;

  const _CommitmentCard({required this.commitment});

  @override
  Widget build(BuildContext context) {
    final daysLeft = commitment.deadlineDate.difference(DateTime.now()).inDays;
    final isUrgent = daysLeft <= 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent
              ? const Color(0xFFFF3366).withOpacity(0.5)
              : const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            commitment.commitmentText,
            style: const TextStyle(
              color: Color(0xFFB088FF),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: isUrgent
                    ? const Color(0xFFFF3366)
                    : const Color(0xFF8888AA),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                daysLeft > 0
                    ? '$daysLeft дн. залишилось'
                    : 'Термін вичерпано!',
                style: TextStyle(
                  color: isUrgent
                      ? const Color(0xFFFF3366)
                      : const Color(0xFF8888AA),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (commitment.stakeKarma > 0)
                Text(
                  '\u{1F525} ${commitment.stakeKarma} карма',
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
