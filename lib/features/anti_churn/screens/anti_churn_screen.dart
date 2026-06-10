import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/anti_churn_oracle_service.dart';

// =========================================================================
// AntiChurnScreen — churn prediction & rescue mission dashboard
// =========================================================================

class AntiChurnScreen extends ConsumerStatefulWidget {
  const AntiChurnScreen({super.key});

  @override
  ConsumerState<AntiChurnScreen> createState() => _AntiChurnScreenState();
}

class _AntiChurnScreenState extends ConsumerState<AntiChurnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(antiChurnOracleProvider.notifier).analyzeChurnRisk();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(antiChurnOracleProvider);
    final isAtRisk = ref.read(antiChurnOracleProvider.notifier).isAtRisk;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1F52E} Анти-Чурн Оракул',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: state.isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6B00FF)),
                  SizedBox(height: 16),
                  Text(
                    'VAULT-17 аналізує ризики...',
                    style: TextStyle(color: Color(0xFFB088FF), fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF6B00FF),
              backgroundColor: const Color(0xFF0D1117),
              onRefresh: () => ref
                  .read(antiChurnOracleProvider.notifier)
                  .analyzeChurnRisk(),
              child: CustomScrollView(
                slivers: [
                  // Churn risk card
                  if (state.lastAnalysis != null)
                    SliverToBoxAdapter(
                      child: _ChurnRiskCard(
                        analysis: state.lastAnalysis!,
                        isAtRisk: isAtRisk,
                      ),
                    ),

                  // Rescue narrative
                  if (state.lastAnalysis != null &&
                      state.lastAnalysis!.rescueNarrativeUA.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _RescueNarrativeCard(
                        narrativeUA: state.lastAnalysis!.rescueNarrativeUA,
                      ),
                    ),

                  // Detected signals
                  if (state.lastAnalysis != null &&
                      state.lastAnalysis!.detectedSignals.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _SignalsCard(
                        signals: state.lastAnalysis!.detectedSignals,
                      ),
                    ),

                  // Recommended actions
                  if (state.lastAnalysis != null &&
                      state.lastAnalysis!.recommendedActions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _ActionsCard(
                        actions: state.lastAnalysis!.recommendedActions,
                      ),
                    ),

                  // Active rescue missions
                  if (state.activeMissions.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          '\u{1F680} РЯТІВНІ МІСІЇ',
                          style: TextStyle(
                            color: Color(0xFFFF3366),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _RescueMissionCard(
                          mission: state.activeMissions[index],
                        ),
                        childCount: state.activeMissions.length,
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
// Churn risk card
// =========================================================================

class _ChurnRiskCard extends StatelessWidget {
  final ChurnAnalysis analysis;
  final bool isAtRisk;

  const _ChurnRiskCard({
    required this.analysis,
    required this.isAtRisk,
  });

  @override
  Widget build(BuildContext context) {
    final probability = analysis.churnProbability;
    final riskColor = probability >= 0.8
        ? const Color(0xFFFF3366)
        : probability >= 0.6
            ? const Color(0xFFFF6B00)
            : const Color(0xFF00FF88);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            riskColor.withOpacity(0.15),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            isAtRisk ? '\u{26A0}\u{FE0F}' : '\u{2705}',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            isAtRisk ? 'РИЗИК ЧУРНУ ВИЯВЛЕНО' : 'СТАБІЛЬНИЙ РЕЖИМ',
            style: TextStyle(
              color: riskColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${(probability * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: riskColor,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'ймовірність чурну',
            style: TextStyle(color: Color(0xFF8888AA), fontSize: 14),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: probability,
              backgroundColor: const Color(0xFF1A0A2E),
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+${analysis.rescueQuestXP} XP за рятувальну місію',
            style: const TextStyle(color: Color(0xFF00F0FF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Rescue narrative card
// =========================================================================

class _RescueNarrativeCard extends StatelessWidget {
  final String narrativeUA;

  const _RescueNarrativeCard({required this.narrativeUA});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF6B00FF), size: 16),
              SizedBox(width: 6),
              Text(
                'ПОВІДОМЛЕННЯ VAULT-17',
                style: TextStyle(
                  color: Color(0xFF6B00FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            narrativeUA,
            style: const TextStyle(
              color: Color(0xFFB088FF),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Signals card
// =========================================================================

class _SignalsCard extends StatelessWidget {
  final List<ChurnSignal> signals;

  const _SignalsCard({required this.signals});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF3366).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u{1F4E1} ВИЯВЛЕНІ СИГНАЛИ',
            style: TextStyle(
              color: Color(0xFFFF3366),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...signals.map((signal) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Color(0xFFFF6B00), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _signalLabel(signal),
                        style: const TextStyle(
                          color: Color(0xFFB088FF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _signalLabel(ChurnSignal signal) => switch (signal) {
        ChurnSignal.depositFrequencyDrop => 'Частота депозитів впала',
        ChurnSignal.streakAtRisk => 'Стрік під загрозою',
        ChurnSignal.appOpenDecline => 'Зменшення відкриттів додатку',
        ChurnSignal.amountDecline => 'Суми депозитів зменшуються',
        ChurnSignal.pushIgnored => 'Push-сповіщення ігноруються',
        ChurnSignal.goalAbandonmentRisk => 'Ризик покидання цілей',
      };
}

// =========================================================================
// Actions card
// =========================================================================

class _ActionsCard extends StatelessWidget {
  final List<String> actions;

  const _ActionsCard({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FF88).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u{1F4CB} РЕКОМЕНДАЦІЇ',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...actions.map((action) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('\u{2192}',
                        style: TextStyle(
                            color: Color(0xFF00FF88), fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(
                          color: Color(0xFFB088FF),
                          fontSize: 13,
                        ),
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

// =========================================================================
// Rescue mission card
// =========================================================================

class _RescueMissionCard extends ConsumerWidget {
  final RescueMission mission;

  const _RescueMissionCard({required this.mission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF3366).withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rocket_launch,
                  color: Color(0xFFFF3366), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.titleUA,
                  style: const TextStyle(
                    color: Color(0xFFFF3366),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.descriptionUA,
            style: const TextStyle(
              color: Color(0xFFB088FF),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${mission.targetDeposits} депозитів',
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${mission.daysToComplete} днів',
                  style: const TextStyle(
                    color: Color(0xFFFF6B00),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${mission.bonusXP} XP',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!mission.isCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => ref
                    .read(antiChurnOracleProvider.notifier)
                    .completeRescueMission(mission.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('ВИКОНАТИ МІСІЮ'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
