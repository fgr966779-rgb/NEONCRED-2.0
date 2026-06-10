import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/savings_time_machine_provider.dart';

// =============================================================================
// Savings Time Machine Screen — LTV Phase 2 Feature #10
// =============================================================================
// Cyberpunk-themed UI for savings projections with price forecasts.
// =============================================================================

class SavingsTimeMachineScreen extends ConsumerStatefulWidget {
  const SavingsTimeMachineScreen({super.key});

  @override
  ConsumerState<SavingsTimeMachineScreen> createState() =>
      _SavingsTimeMachineScreenState();
}

class _SavingsTimeMachineScreenState
    extends ConsumerState<SavingsTimeMachineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(savingsTimeMachineProvider.notifier).loadProjections();
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
    final state = ref.watch(savingsTimeMachineProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'МАШИНА ЧАСУ',
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
                colors: [Colors.transparent, _yellow, _purple, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Header Text ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Побач своє майбутнє — коли саме ти зможеш купити бажане',
                textAlign: TextAlign.center,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // ── Error Banner ─────────────────────────────────────────
          if (state.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(error: state.error!)),

          // ── Loading ──────────────────────────────────────────────
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _yellow)),
              ),
            ),

          // ── Projection List ──────────────────────────────────────
          if (state.projections.isEmpty && !state.isLoading)
            SliverToBoxAdapter(
              child: _EmptyStateCard(onCreate: _showCreateDialog),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _ProjectionCard(model: state.projections[index]),
                childCount: state.projections.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: _yellow,
        child: const Icon(Icons.timeline, color: _bg),
      ),
    );
  }

  void _showCreateDialog() {
    int? selectedGoalId;
    final depositController = TextEditingController(text: '500');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _yellow, width: 1),
              ),
              title: Text(
                'СТВОРИТИ ПРОГНОЗ',
                style: GoogleFonts.orbitron(color: _yellow, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<List<Goal>>(
                    future: ref.read(databaseProvider).getAllGoals(),
                    builder: (ctx, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text(
                          'Немає цілей — створіть спочатку ціль',
                          style: GoogleFonts.shareTechMono(
                            color: _pink,
                            fontSize: 12,
                          ),
                        );
                      }
                      final goals = snapshot.data!;
                      return DropdownButtonFormField<int>(
                        value: selectedGoalId,
                        dropdownColor: _cardBg,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Ціль',
                          labelStyle: GoogleFonts.shareTechMono(color: _yellow),
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _yellow),
                          ),
                        ),
                        items: goals
                            .map((g) => DropdownMenuItem(
                                  value: g.id,
                                  child: Text(g.name),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedGoalId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: depositController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Щомісячний внесок (грн)',
                      labelStyle: GoogleFonts.shareTechMono(color: _yellow),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _yellow),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _yellow, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _purple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _purple),
                        ),
                        child: Text(
                          '+5 XP',
                          style: GoogleFonts.orbitron(
                            color: _yellow,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Скасувати',
                    style: GoogleFonts.shareTechMono(color: Colors.white38),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final deposit = double.tryParse(depositController.text) ?? 0;
                    if (selectedGoalId != null && deposit > 0) {
                      ref
                          .read(savingsTimeMachineProvider.notifier)
                          .createProjection(
                            goalId: selectedGoalId!,
                            monthlyDeposit: deposit,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _yellow),
                  child: Text(
                    'ПРОГНОЗУВАТИ',
                    style: GoogleFonts.orbitron(
                      color: _bg,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

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
  final VoidCallback onCreate;
  const _EmptyStateCard({required this.onCreate});

  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.timeline, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'МАШИНА ЧАСУ',
            style: GoogleFonts.orbitron(color: _yellow, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Створи прогноз — побач конкретну дату коли зможеш купити бажане. '
            'Ми проаналізуємо ціну, знецінення і твої заощадження',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text('СТВОРИТИ ПРОГНОЗ', style: GoogleFonts.orbitron(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: _yellow),
          ),
        ],
      ),
    );
  }
}

class _ProjectionCard extends ConsumerWidget {
  final TimeMachineModel model;
  const _ProjectionCard({required this.model});

  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final willAfford = model.willAfford;
    final accentColor = willAfford ? _green : _pink;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Goal name + confidence ────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  model.goalName,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ConfidenceBadge(score: model.data.confidenceScore),
            ],
          ),
          const SizedBox(height: 16),

          // ── Key Numbers ───────────────────────────────────────────
          Row(
            children: [
              // Projected price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ПРОГНОЗ ЦІНИ',
                      style: GoogleFonts.shareTechMono(color: _cyan, fontSize: 9),
                    ),
                    Text(
                      '${model.data.projectedPrice.toStringAsFixed(0)} грн',
                      style: GoogleFonts.orbitron(
                        color: _cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (model.data.priceDropPercent > 0)
                      Text(
                        '-${model.data.priceDropPercent.toStringAsFixed(1)}%',
                        style: GoogleFonts.shareTechMono(color: _green, fontSize: 11),
                      ),
                  ],
                ),
              ),
              // Projected savings
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ПРОГНОЗ ЗАОЩАДЖЕНЬ',
                      style: GoogleFonts.shareTechMono(color: _yellow, fontSize: 9),
                    ),
                    Text(
                      '${model.data.projectedSavings.toStringAsFixed(0)} грн',
                      style: GoogleFonts.orbitron(
                        color: _yellow,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${model.data.monthlyDeposit.toStringAsFixed(0)} грн/міс',
                      style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Progress Bar ──────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ПРОГРЕС',
                    style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9),
                  ),
                  Text(
                    '${model.progressPercent.toStringAsFixed(1)}%',
                    style: GoogleFonts.shareTechMono(color: accentColor, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: model.progressPercent / 100,
                  backgroundColor: const Color(0xFF1A1A2E),
                  color: accentColor,
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Estimated Date ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  willAfford ? Icons.check_circle : Icons.access_time,
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        willAfford ? 'ТИ ЗМОЖЕШ КУПИТИ' : 'ЩЕ НЕ ДОСТАТНЬО',
                        style: GoogleFonts.orbitron(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(model.data.projectedDate),
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${model.monthsToGoal} міс.',
                  style: GoogleFonts.orbitron(
                    color: accentColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),

          // ── AI Analysis ───────────────────────────────────────────
          if (model.data.aiAnalysis.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _purple.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: _purple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      model.data.aiAnalysis,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Actions ───────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => ref
                    .read(savingsTimeMachineProvider.notifier)
                    .refreshProjection(model.data.id, model.data.goalId),
                icon: const Icon(Icons.refresh, color: _cyan, size: 16),
                label: Text(
                  'ОНОВИТИ (+3 XP)',
                  style: GoogleFonts.shareTechMono(color: _cyan, fontSize: 10),
                ),
              ),
              IconButton(
                onPressed: () => ref
                    .read(savingsTimeMachineProvider.notifier)
                    .deleteProjection(model.data.id),
                icon: const Icon(Icons.delete_outline, color: _pink, size: 20),
                tooltip: 'Видалити',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    const months = [
      '', 'січня', 'лютого', 'березня', 'квітня', 'травня', 'червня',
      'липня', 'серпня', 'вересня', 'жовтня', 'листопада', 'грудня',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double score;
  const _ConfidenceBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? const Color(0xFF00FF88)
        : score >= 60
            ? const Color(0xFFFFD700)
            : const Color(0xFFFF3366);

    final label = score >= 80
        ? 'ВИСОКА'
        : score >= 60
            ? 'СЕРЕДНЯ'
            : 'НИЗЬКА';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
