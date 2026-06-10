import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../services/nudge_lab_service.dart';

// =========================================================================
// NudgeLabScreen — behavioral nudge A/B testing dashboard
// =========================================================================

class NudgeLabScreen extends ConsumerStatefulWidget {
  const NudgeLabScreen({super.key});

  @override
  ConsumerState<NudgeLabScreen> createState() => _NudgeLabScreenState();
}

class _NudgeLabScreenState extends ConsumerState<NudgeLabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(nudgeLabProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nudgeLabProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1F9EA} Лабораторія Нуджів',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: state.isRunning
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
          : RefreshIndicator(
              color: const Color(0xFF00F0FF),
              backgroundColor: const Color(0xFF0D1117),
              onRefresh: () =>
                  ref.read(nudgeLabProvider.notifier).loadProfile(),
              child: CustomScrollView(
                slivers: [
                  // Current dominant nudge
                  if (state.currentNudge != null)
                    SliverToBoxAdapter(
                      child: _DominantNudgeCard(
                        nudgeType: state.currentNudge!,
                        message: state.nudgeMessage,
                      ),
                    ),

                  // Persuasion profile
                  if (state.profile != null)
                    SliverToBoxAdapter(
                      child: _PersuasionProfileCard(profile: state.profile!),
                    ),

                  // Nudge types effectiveness
                  const SliverToBoxAdapter(
                    child: _NudgeTypesInfo(),
                  ),

                  // Active experiments
                  if (state.activeExperiments.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          '\u{1F52C} АКТИВНІ ЕКСПЕРИМЕНТИ',
                          style: TextStyle(
                            color: Color(0xFF6B00FF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ExperimentCard(
                          experiment: state.activeExperiments[index],
                        ),
                        childCount: state.activeExperiments.length,
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }
}

// =========================================================================
// Dominant nudge card
// =========================================================================

class _DominantNudgeCard extends StatelessWidget {
  final NudgeType nudgeType;
  final String? message;

  const _DominantNudgeCard({
    required this.nudgeType,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
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
          color: const Color(0xFF00F0FF).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            nudgeType.iconEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          const Text(
            'ТВОЙ ГОЛОВНИЙ НУДЖ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            nudgeType.labelUA,
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B00FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6B00FF).withOpacity(0.2),
                ),
              ),
              child: Text(
                '"$message"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB088FF),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =========================================================================
// Persuasion profile card
// =========================================================================

class _PersuasionProfileCard extends StatelessWidget {
  final PersuasionProfile profile;

  const _PersuasionProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    // Parse effectiveness scores from JSON
    Map<String, dynamic> scores = {};
    try {
      scores = jsonDecode(profile.effectivenessScores) as Map<String, dynamic>;
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Row(
            children: [
              const Text(
                'ПРОФІЛЬ ПЕРСУАЗІЇ',
                style: TextStyle(
                  color: Color(0xFF6B00FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '${profile.totalExperiments} експ.',
                style: const TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Effectiveness bars
          ...NudgeType.values.map((type) {
            final score = (scores[type.key] as num?)?.toDouble() ?? 0.5;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(type.iconEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type.labelUA,
                              style: const TextStyle(
                                color: Color(0xFFB088FF),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(score * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF00F0FF),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: score,
                            backgroundColor: const Color(0xFF1A0A2E),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF00F0FF),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =========================================================================
// Experiment card
// =========================================================================

class _ExperimentCard extends StatelessWidget {
  final NudgeExperiment experiment;

  const _ExperimentCard({required this.experiment});

  @override
  Widget build(BuildContext context) {
    final conversionRate = experiment.impressions > 0
        ? experiment.conversions / experiment.impressions
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Variant badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: experiment.variant == 'A'
                  ? const Color(0xFF00FF88).withOpacity(0.15)
                  : const Color(0xFFFF6B00).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              experiment.variant,
              style: TextStyle(
                color: experiment.variant == 'A'
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFFF6B00),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  experiment.nudgeType,
                  style: const TextStyle(
                    color: Color(0xFFB088FF),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${experiment.impressions} показів | ${experiment.conversions} конверсій | '
                  '${(conversionRate * 100).toStringAsFixed(1)}%',
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
    );
  }
}

// =========================================================================
// Nudge types info
// =========================================================================

class _NudgeTypesInfo extends StatelessWidget {
  const _NudgeTypesInfo();

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
            'ТИПИ НУДЖІВ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...NudgeType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(type.iconEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      type.labelUA,
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 13,
                      ),
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
}


