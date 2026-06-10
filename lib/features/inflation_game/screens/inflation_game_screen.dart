import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/inflation_game_provider.dart';

// =============================================================================
// Anti-Inflation Shield Game Screen — Retention 2026 Feature #10
// =============================================================================
// Cyberpunk-themed visual game where user builds a wall against inflation.
// =============================================================================

class InflationGameScreen extends ConsumerStatefulWidget {
  const InflationGameScreen({super.key});

  @override
  ConsumerState<InflationGameScreen> createState() =>
      _InflationGameScreenState();
}

class _InflationGameScreenState extends ConsumerState<InflationGameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inflationGameProvider.notifier).loadWaves();
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
    final state = ref.watch(inflationGameProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ЩИТ ІНФЛЯЦІЇ',
          style: GoogleFonts.orbitron(
            color: _pink,
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
                colors: [Colors.transparent, _pink, _yellow, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Main Battle Scene ──────────────────────────────────
          SliverToBoxAdapter(child: _BattleScene(state: state)),

          // ── Error Banner ───────────────────────────────────────
          if (state.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(error: state.error!)),

          // ── Loading ────────────────────────────────────────────
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _pink)),
              ),
            ),

          // ── Action Buttons ─────────────────────────────────────
          SliverToBoxAdapter(child: _ActionPanel(state: state)),

          // ── Wave History ───────────────────────────────────────
          if (state.waves.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(
                  'ІСТОРІЯ ХВИЛЬ',
                  style: GoogleFonts.orbitron(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          if (state.waves.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _WaveHistoryCard(model: state.waves[index]),
                childCount: state.waves.length,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _BattleScene extends StatelessWidget {
  final InflationGameState state;
  const _BattleScene({required this.state});

  static const _bg = Color(0xFF0A0E17);
  static const _pink = Color(0xFFFF3366);
  static const _green = Color(0xFF00FF88);
  static const _yellow = Color(0xFFFFD700);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context) {
    final current = state.currentWave;
    final isHolding = current?.isWallHolding ?? false;
    final health = current?.healthRemaining ?? 0;
    final severityColor = health >= 80
        ? _green
        : health >= 50
            ? _yellow
            : health >= 20
                ? _pink
                : const Color(0xFFFF0000);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            severityColor.withOpacity(0.05),
            const Color(0xFF0A0E17),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // ── Wave Info ────────────────────────────────────────
          if (current != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHolding ? Icons.shield : Icons.warning_amber,
                  color: severityColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  current.data.monthLabel.isNotEmpty
                      ? current.data.monthLabel
                      : 'ХВИЛЯ ІНФЛЯЦІЇ',
                  style: GoogleFonts.orbitron(
                    color: severityColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Inflation Rate ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'ІНФЛЯЦІЯ: ',
                  style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11),
                ),
                Text(
                  '${current.data.inflationRate.toStringAsFixed(1)}%',
                  style: GoogleFonts.orbitron(
                    color: _pink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Visual Wall ────────────────────────────────────
            _VisualWall(
              wallBlocks: current.wallBlocks,
              isHolding: isHolding,
              severityColor: severityColor,
            ),
            const SizedBox(height: 12),

            // ── Health Bar ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  current.severityLabel,
                  style: GoogleFonts.orbitron(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${health.toStringAsFixed(1)}%',
                  style: GoogleFonts.orbitron(
                    color: severityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: health / 100,
                backgroundColor: const Color(0xFF1A1A2E),
                color: severityColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats Row ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BattleStat(
                  label: 'СТІНА',
                  value: '${current.data.wallStrength.toStringAsFixed(0)} грн',
                  color: _green,
                ),
                _BattleStat(
                  label: 'УРОН',
                  value: '${current.data.wallDamage.toStringAsFixed(0)} грн',
                  color: _pink,
                ),
                _BattleStat(
                  label: 'СЕРІЯ',
                  value: '${state.currentStreak}',
                  color: _yellow,
                ),
              ],
            ),
          ] else ...[
            // No active wave
            const Icon(Icons.shield_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'СТІНА НЕ ПОБУДОВАНА',
              style: GoogleFonts.orbitron(color: _pink, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Інфляція знищує твої заощадження кожен місяць. '
              'Побудуй стіну депозитами щоб захиститись!',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13),
            ),
          ],

          // ── Streak Bonus ────────────────────────────────────
          if (state.currentStreak > 0) ...[
            const SizedBox(height: 12),
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
                  const SizedBox(width: 6),
                  Text(
                    'Серія: ${state.currentStreak} міс. | Бонус: +${state.currentStreak * 5} XP',
                    style: GoogleFonts.shareTechMono(color: _yellow, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VisualWall extends StatelessWidget {
  final int wallBlocks;
  final bool isHolding;
  final Color severityColor;

  const _VisualWall({
    required this.wallBlocks,
    required this.isHolding,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Inflation wave (top)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            10,
            (i) => Container(
              width: 28,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3366).withOpacity(0.3 + (i % 3) * 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Wall blocks (middle)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            10,
            (i) => Container(
              width: 28,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: i < wallBlocks
                    ? const Color(0xFF00FF88).withOpacity(0.8)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: i < wallBlocks
                      ? const Color(0xFF00FF88)
                      : const Color(0xFF333333),
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
        // Foundation
        Container(
          width: 300,
          height: 4,
          decoration: BoxDecoration(
            color: isHolding ? _green.withOpacity(0.4) : _pink.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
}

class _BattleStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BattleStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 8),
        ),
      ],
    );
  }
}

class _ActionPanel extends ConsumerWidget {
  final InflationGameState state;
  const _ActionPanel({required this.state});

  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // ── Start Wave Button ───────────────────────────────
          if (state.currentWave == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref
                    .read(inflationGameProvider.notifier)
                    .startNewWave(inflationRate: 7.5),
                icon: const Icon(Icons.play_arrow, color: Color(0xFF0A0E17)),
                label: Text(
                  'ПОЧАТИ ХВИЛЮ',
                  style: GoogleFonts.orbitron(
                    color: Color(0xFF0A0E17),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: _pink),
              ),
            ),

          // ── Reinforce Wall Buttons ──────────────────────────
          if (state.currentWave != null) ...[
            Text(
              'ПІДСИЛИТИ СТІНУ ДЕПОЗИТОМ',
              style: GoogleFonts.orbitron(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _ReinforceButton(
                  amount: 100,
                  onTap: () => ref
                      .read(inflationGameProvider.notifier)
                      .reinforceWall(100),
                ),
                const SizedBox(width: 8),
                _ReinforceButton(
                  amount: 500,
                  onTap: () => ref
                      .read(inflationGameProvider.notifier)
                      .reinforceWall(500),
                ),
                const SizedBox(width: 8),
                _ReinforceButton(
                  amount: 1000,
                  onTap: () => ref
                      .read(inflationGameProvider.notifier)
                      .reinforceWall(1000),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Custom deposit
            OutlinedButton.icon(
              onPressed: () => _showCustomDepositDialog(context, ref),
              icon: const Icon(Icons.edit, color: _cyan, size: 16),
              label: Text(
                'ІНША СУМА',
                style: GoogleFonts.orbitron(color: _cyan, fontSize: 10),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _cyan),
                minimumSize: const Size.fromHeight(36),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCustomDepositDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _green, width: 1),
        ),
        title: Text(
          'ПІДСИЛИТИ СТІНУ',
          style: GoogleFonts.orbitron(color: _green, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Сума депозиту (грн)',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF0A0E17),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _green),
            ),
          ),
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
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                ref.read(inflationGameProvider.notifier).reinforceWall(amount);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _green),
            child: Text(
              'ВІДКЛАСТИ',
              style: GoogleFonts.orbitron(
                color: Color(0xFF0A0E17),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReinforceButton extends StatelessWidget {
  final double amount;
  final VoidCallback onTap;

  const _ReinforceButton({required this.amount, required this.onTap});

  static const _green = Color(0xFF00FF88);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green.withOpacity(0.15),
          side: const BorderSide(color: _green),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text(
          '${amount.toStringAsFixed(0)}',
          style: GoogleFonts.orbitron(
            color: _green,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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

class _WaveHistoryCard extends StatelessWidget {
  final InflationWaveModel model;
  const _WaveHistoryCard({required this.model});

  static const _cardBg = Color(0xFF111827);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    final held = model.data.wallHeld;
    final accentColor = held ? _green : _pink;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            held ? Icons.shield : Icons.shield_outlined,
            color: accentColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.data.monthLabel,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Інфляція: ${model.data.inflationRate.toStringAsFixed(1)}% | '
                  'Урон: ${model.data.wallDamage.toStringAsFixed(0)} грн',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                held ? 'ТРИМАЄ' : 'ПРОРВА',
                style: GoogleFonts.orbitron(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (model.data.xpEarned > 0)
                Text(
                  '+${model.data.xpEarned} XP',
                  style: GoogleFonts.shareTechMono(color: _yellow, fontSize: 9),
                ),
              if (model.data.consecutiveWallsHeld > 0)
                Text(
                  'Серія: ${model.data.consecutiveWallsHeld}',
                  style: GoogleFonts.shareTechMono(color: _cyan, fontSize: 9),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
