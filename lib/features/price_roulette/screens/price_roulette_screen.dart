import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/price_roulette_provider.dart';

// =============================================================================
// Price Drop Roulette Screen — Gamified waiting for price drops
// =============================================================================

class PriceRouletteScreen extends ConsumerStatefulWidget {
  const PriceRouletteScreen({super.key});

  @override
  ConsumerState<PriceRouletteScreen> createState() =>
      _PriceRouletteScreenState();
}

class _PriceRouletteScreenState extends ConsumerState<PriceRouletteScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceRouletteProvider);
    final notifier = ref.read(priceRouletteProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(
          'PRICE DROP ROULETTE',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: CustomScrollView(
        slivers: [
          // XP counter at top
          SliverToBoxAdapter(child: _buildXpCounter(state.totalXpWon)),

          // Active roulette items
          if (state.items.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.casino,
                title: 'Ruletka pochekaye...',
                subtitle:
                    'Dodai tovar dlia vidstezhennia i obertai koleso shchodnia!',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildRouletteItemCard(state.items[index], notifier),
                childCount: state.items.length,
              ),
            ),

          // Spin history
          if (state.items.any((i) => i.spinHistory.isNotEmpty))
            SliverToBoxAdapter(
              child: _buildSpinHistorySection(state.items),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddItemDialog(context, notifier),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // XP counter
  // ---------------------------------------------------------------------------

  Widget _buildXpCounter(int totalXp) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Color(0xFFFFD700), size: 28),
          const SizedBox(width: 12),
          Text(
            'XP ZAROBLENNO: $totalXp',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFFFD700),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Roulette item card
  // ---------------------------------------------------------------------------

  Widget _buildRouletteItemCard(
    RouletteItem item,
    PriceRouletteNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.jackpotWon
              ? const Color(0xFFFFD700)
              : const Color(0xFF00F0FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + drop chance
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B00FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.dropChance.toStringAsFixed(0)}%',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF6B00FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current vs target price
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Zaraz',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8B95A5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${item.currentPrice.toStringAsFixed(0)} hrn',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00F0FF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tsili',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8B95A5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${item.targetPrice.toStringAsFixed(0)} hrn',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF00FF88),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spyny',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8B95A5),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${item.dailySpins}/${item.maxDailySpins}',
                    style: GoogleFonts.shareTechMono(
                      color: item.canSpin
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFF3366),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Deposit progress bar
          _buildDepositProgress(item),

          const SizedBox(height: 12),

          // Drop chance label
          Row(
            children: [
              Text(
                'Shans znyzhky: ',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                  fontSize: 12,
                ),
              ),
              Text(
                '${item.dropChance.toStringAsFixed(1)}%',
                style: GoogleFonts.shareTechMono(
                  color: item.dropChance >= 50
                      ? const Color(0xFF00FF88)
                      : item.dropChance >= 25
                          ? const Color(0xFFFFD700)
                          : const Color(0xFFFF3366),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Depozyt: ${item.depositAmount.toStringAsFixed(0)} hrn',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Deposit button
              TextButton.icon(
                icon: const Icon(Icons.savings, size: 16),
                label: Text(
                  'Depozyt',
                  style: GoogleFonts.shareTechMono(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                ),
                onPressed: () =>
                    _showDepositDialog(context, item, notifier),
              ),
              const SizedBox(width: 4),

              // Refresh price button
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: Color(0xFF00F0FF), size: 18),
                onPressed: () => notifier.refreshPrice(item.id),
              ),

              // Spin button with animation
              _buildSpinButton(item, notifier),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Deposit progress bar
  // ---------------------------------------------------------------------------

  Widget _buildDepositProgress(RouletteItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prohres depozytu',
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF8B95A5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.depositProgress,
            backgroundColor: const Color(0xFF0D1117),
            color: const Color(0xFF6B00FF),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Animated spin button
  // ---------------------------------------------------------------------------

  Widget _buildSpinButton(
    RouletteItem item,
    PriceRouletteNotifier notifier,
  ) {
    final isSpinning = ref.watch(priceRouletteProvider).isSpinning;

    return AnimatedBuilder(
      animation: _spinController,
      builder: (context, child) {
        final spinAngle =
            isSpinning ? _spinController.value * 6.28 * 4 : 0.0;

        return Transform.rotate(
          angle: spinAngle,
          child: child,
        );
      },
      child: ElevatedButton.icon(
        icon: const Icon(Icons.casino, size: 18),
        label: Text(
          'OBERTATY',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: item.canSpin
              ? const Color(0xFF00F0FF)
              : const Color(0xFF4A5568),
          foregroundColor: const Color(0xFF0A0E17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: item.canSpin && !isSpinning
            ? () => _performSpin(item, notifier)
            : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Perform a spin
  // ---------------------------------------------------------------------------

  Future<void> _performSpin(
    RouletteItem item,
    PriceRouletteNotifier notifier,
  ) async {
    // Start spinning animation
    _spinController.reset();
    _spinController.forward();

    final result = await notifier.spinRoulette(item.id);

    // Wait for animation to complete
    await _spinController.forward();

    if (mounted) {
      _showSpinResultDialog(context, result);
    }
  }

  // ---------------------------------------------------------------------------
  // Spin result dialog
  // ---------------------------------------------------------------------------

  void _showSpinResultDialog(BuildContext context, SpinResult result) {
    final resultColor = result.xpBonus >= 500
        ? const Color(0xFFFFD700)
        : result.isDrop
            ? const Color(0xFF00FF88)
            : const Color(0xFF8B95A5);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          result.xpBonus >= 500
              ? 'DZHEKPOT!!'
              : result.isDrop
                  ? 'ZNYZHKA!'
                  : 'BEZ ZMIN',
          style: GoogleFonts.orbitron(
            color: resultColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price change
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.priceBefore.toStringAsFixed(0)}',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8B95A5),
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Color(0xFF00F0FF)),
                const SizedBox(width: 8),
                Text(
                  '${result.priceAfter.toStringAsFixed(0)} hrn',
                  style: GoogleFonts.orbitron(
                    color: resultColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (result.isDrop) ...[
              const SizedBox(height: 8),
              Text(
                '-${result.dropPercent.toStringAsFixed(1)}%',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF00FF88),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // XP earned
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '+${result.xpBonus.toInt()} XP',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI narrative
            if (result.narrative.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6B00FF).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  result.narrative,
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8B95A5),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B00FF),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Prodovzhyty',
                style: GoogleFonts.shareTechMono(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Spin history section
  // ---------------------------------------------------------------------------

  Widget _buildSpinHistorySection(List<RouletteItem> items) {
    final allSpins = items
        .expand((item) => item.spinHistory.map(
              (spin) => MapEntry(item.productName, spin),
            ))
        .toList()
      ..sort((a, b) => b.value.timestamp.compareTo(a.value.timestamp));

    if (allSpins.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ISTORYIA OBERTAN',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF6B00FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...allSpins.take(10).map((entry) {
            final productName = entry.key;
            final spin = entry.value;
            final timeStr = spin.timestamp.isNotEmpty
                ? spin.timestamp.substring(11, 16)
                : '--:--';

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F2E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: spin.isDrop
                      ? const Color(0xFF00FF88).withOpacity(0.3)
                      : const Color(0xFF4A5568).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    spin.isDrop ? Icons.trending_down : Icons.remove,
                    color: spin.isDrop
                        ? const Color(0xFF00FF88)
                        : const Color(0xFF8B95A5),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$productName: ${spin.priceBefore.toStringAsFixed(0)} -> ${spin.priceAfter.toStringAsFixed(0)} hrn',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '+${spin.xpBonus.toInt()}XP',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFFFFD700),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8B95A5),
                      fontSize: 10,
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

  // ---------------------------------------------------------------------------
  // Add item dialog
  // ---------------------------------------------------------------------------

  void _showAddItemDialog(
    BuildContext context,
    PriceRouletteNotifier notifier,
  ) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          'Dodaty v ruletku',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.shareTechMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nazva tovaru',
                labelStyle: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00F0FF)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              style: GoogleFonts.shareTechMono(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tsilova tsina (hrn)',
                labelStyle: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00F0FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Skasuvaty',
              style:
                  GoogleFonts.shareTechMono(color: const Color(0xFF8B95A5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B00FF),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              if (name.isNotEmpty && price > 0) {
                notifier.addItem(name, price);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Dodaty',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Deposit dialog
  // ---------------------------------------------------------------------------

  void _showDepositDialog(
    BuildContext context,
    RouletteItem item,
    PriceRouletteNotifier notifier,
  ) {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          'Zrobyty depozyt',
          style: GoogleFonts.orbitron(
            color: const Color(0xFFFFD700),
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tovar: ${item.productName}',
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Zahalna suma depozytiv: ${item.depositAmount.toStringAsFixed(0)} hrn',
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF8B95A5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              style: GoogleFonts.shareTechMono(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Suma depozytu (hrn)',
                labelStyle: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFFD700)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kozhen depozyt zbilshuie shans znyzhky na 2%!',
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF00FF88),
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Skasuvaty',
              style:
                  GoogleFonts.shareTechMono(color: const Color(0xFF8B95A5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
            ),
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amount > 0) {
                notifier.makeDeposit(item.id, amount);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Depozyt',
              style: GoogleFonts.shareTechMono(color: const Color(0xFF0A0E17)),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: const Color(0xFF6B00FF).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF8B95A5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


