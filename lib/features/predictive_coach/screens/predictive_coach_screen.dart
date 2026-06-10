import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/predictive_coach_provider.dart';

// =============================================================================
// Predictive Savings Coach Screen — Retention 2026 Feature #6
// =============================================================================
// Cyberpunk-themed UI for AI-powered savings predictions and danger windows.
// =============================================================================

class PredictiveCoachScreen extends ConsumerStatefulWidget {
  const PredictiveCoachScreen({super.key});

  @override
  ConsumerState<PredictiveCoachScreen> createState() =>
      _PredictiveCoachScreenState();
}

class _PredictiveCoachScreenState
    extends ConsumerState<PredictiveCoachScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(predictiveCoachProvider.notifier).loadPredictions();
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
    final state = ref.watch(predictiveCoachProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'КОУЧ ПРОГНОЗ',
          style: GoogleFonts.orbitron(
            color: _yellow,
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
                colors: [Colors.transparent, _yellow, _pink, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Alert Summary ──────────────────────────────────────
          SliverToBoxAdapter(child: _AlertSummary(state: state)),

          // ── Error Banner ───────────────────────────────────────
          if (state.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(error: state.error!)),

          // ── Loading ────────────────────────────────────────────
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _yellow)),
              ),
            ),

          // ── Prediction List ────────────────────────────────────
          if (state.predictions.isEmpty && !state.isLoading)
            SliverToBoxAdapter(
              child: _EmptyStateCard(onAnalyze: _analyze),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _PredictionCard(model: state.predictions[index]),
                childCount: state.predictions.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _analyze,
        backgroundColor: _yellow,
        child: const Icon(Icons.psychology, color: Color(0xFF0A0E17)),
      ),
    );
  }

  void _analyze() {
    ref.read(predictiveCoachProvider.notifier).analyzeAndPredict();
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _AlertSummary extends StatelessWidget {
  final PredictiveCoachState state;
  const _AlertSummary({required this.state});

  static const _bg = Color(0xFF0A0E17);
  static const _yellow = Color(0xFFFFD700);
  static const _pink = Color(0xFFFF3366);
  static const _green = Color(0xFF00FF88);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A00), Color(0xFF0A0E17)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.criticalAlerts > 0
              ? _pink.withOpacity(0.4)
              : _yellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'ПРОГНОЗ БЕЗПЕКИ',
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AlertStat(
                label: 'АКТИВНІ',
                value: '${state.activeAlerts}',
                color: state.activeAlerts > 0 ? _yellow : _green,
              ),
              _AlertStat(
                label: 'КРИТИЧНІ',
                value: '${state.criticalAlerts}',
                color: state.criticalAlerts > 0 ? _pink : _green,
              ),
              _AlertStat(
                label: 'СПОСТЕРЕЖЕННЯ',
                value: '${state.totalNudgesActedOn}',
                color: _cyan,
              ),
              _AlertStat(
                label: 'ВПЕВНЕНІСТЬ',
                value: '${state.averageConfidence.toStringAsFixed(0)}%',
                color: _yellow,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.criticalAlerts > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _pink.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber, color: _pink, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Виявлено ${state.criticalAlerts} критичних небезпечних вікон!',
                    style: GoogleFonts.shareTechMono(color: _pink, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _AlertStat({required this.label, required this.value, required this.color});

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
  final VoidCallback onAnalyze;
  const _EmptyStateCard({required this.onAnalyze});

  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.psychology, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'ПРОГНОСТИЧНИЙ КОУЧ',
            style: GoogleFonts.orbitron(color: _yellow, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'AI аналізує твої патерни заощаджень і попереджає про небезпечні '
            'вікна заздалегідь. Реагуй на нуджі — отримуй +3 XP',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAnalyze,
            icon: const Icon(Icons.psychology),
            label: Text('АНАЛІЗУВАТИ', style: GoogleFonts.orbitron(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: _yellow),
          ),
        ],
      ),
    );
  }
}

class _PredictionCard extends ConsumerWidget {
  final CoachPredictionModel model;
  const _PredictionCard({required this.model});

  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActed = model.data.isUserActed;
    final isImminent = model.isImminent;
    final isRelevant = model.isRelevant;

    final severityColor = !isRelevant
        ? Colors.white24
        : isImminent
            ? _pink
            : model.timeUntilDanger.inHours <= 72
                ? _yellow
                : _cyan;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: severityColor.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Severity + Type ────────────────────────────
          Row(
            children: [
              // Severity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: severityColor.withOpacity(0.4)),
                ),
                child: Text(
                  model.severityLabel,
                  style: GoogleFonts.orbitron(
                    color: severityColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Prediction type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  model.data.predictionType.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: _purple,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (isActed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'РЕАГОВАНО +3 XP',
                    style: GoogleFonts.shareTechMono(color: _green, fontSize: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Countdown Timer ────────────────────────────────────
          if (isRelevant && !isActed)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    severityColor.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: severityColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    isImminent ? Icons.warning_amber : Icons.access_time,
                    color: severityColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'НЕБЕЗПЕЧНЕ ВІКНО ЧЕРЕЗ',
                        style: GoogleFonts.shareTechMono(
                            color: Colors.white38, fontSize: 9),
                      ),
                      Text(
                        model.timeUntilDangerStr,
                        style: GoogleFonts.orbitron(
                          color: severityColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(model.data.dangerDate),
                    style: GoogleFonts.shareTechMono(
                        color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // ── AI Recommendation ──────────────────────────────────
          if (model.data.aiRecommendation.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _purple.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: _purple, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.data.aiRecommendation,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),

          // ── Confidence + Suggested Amount ──────────────────────
          Row(
            children: [
              // Confidence
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ВПЕВНЕНІСТЬ',
                    style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 8),
                  ),
                  Text(
                    '${model.data.confidenceScore.toStringAsFixed(0)}%',
                    style: GoogleFonts.orbitron(
                      color: model.data.confidenceScore >= 70
                          ? _green
                          : model.data.confidenceScore >= 50
                              ? _yellow
                              : _pink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Suggested deposit
              if (model.data.suggestedDepositAmount > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'РЕКОМЕНДОВАНИЙ ДЕПОЗИТ',
                      style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 8),
                    ),
                    Text(
                      '${model.data.suggestedDepositAmount.toStringAsFixed(0)} грн',
                      style: GoogleFonts.orbitron(
                        color: _green,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Actions ────────────────────────────────────────────
          if (isRelevant && !isActed) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => ref
                      .read(predictiveCoachProvider.notifier)
                      .dismiss(model.data.id),
                  icon: const Icon(Icons.close, color: Colors.white38, size: 14),
                  label: Text(
                    'ПРОПУСТИТИ',
                    style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(predictiveCoachProvider.notifier)
                      .markActed(model.data.id),
                  icon: const Icon(Icons.check, color: Color(0xFF0A0E17), size: 14),
                  label: Text(
                    'ВІДКЛАСТИ (+3 XP)',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF0A0E17),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: _green),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'січ', 'лют', 'бер', 'кві', 'тра', 'чер',
      'лип', 'сер', 'вер', 'жов', 'лис', 'гру',
    ];
    return '${date.day} ${months[date.month]}';
  }
}
