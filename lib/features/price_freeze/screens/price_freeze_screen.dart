import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/price_freeze_provider.dart';

// =============================================================================
// Price Freeze Challenge Screen -- Cyberpunk themed
// =============================================================================
//
// Active challenges: cards showing product, frozen price, current price,
// progress bar, days active. Daily deposit button. Economy gain display.
// Inflation rate indicator. AI progress insight per challenge.
// =============================================================================

class PriceFreezeScreen extends ConsumerStatefulWidget {
  const PriceFreezeScreen({super.key});

  @override
  ConsumerState<PriceFreezeScreen> createState() =>
      _PriceFreezeScreenState();
}

class _PriceFreezeScreenState extends ConsumerState<PriceFreezeScreen> {
  // ---------------------------------------------------------------------------
  // Design tokens
  // ---------------------------------------------------------------------------
  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _pink = Color(0xFFFF3366);
  static const _green = Color(0xFF00FF88);
  static const _yellow = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(priceFreezeProvider.notifier).refreshInflationRate();
    });
  }

  String _fmtMoney(double v) => '${v.toStringAsFixed(0)}₴';

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final freezeState = ref.watch(priceFreezeProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'PRICE FREEZE CHALLENGE',
          style: GoogleFonts.orbitron(
            color: _cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.ac_unit, color: _cyan),
            onPressed: () => _showStartChallengeDialog(),
          ),
        ],
      ),
      body: freezeState.isLoading && freezeState.challenges.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: _cyan),
            )
          : RefreshIndicator(
              color: _cyan,
              backgroundColor: _card,
              onRefresh: () async {
                await ref
                    .read(priceFreezeProvider.notifier)
                    .refreshInflationRate();
                for (final c in freezeState.challenges) {
                  if (c.isActive) {
                    await ref
                        .read(priceFreezeProvider.notifier)
                        .refreshCurrentPrice(c.id);
                  }
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Error display
                  if (freezeState.error != null)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _pink.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          freezeState.error!,
                          style: const TextStyle(color: _pink, fontSize: 13),
                        ),
                      ),
                    ),

                  // Economy gain + Inflation rate banner
                  SliverToBoxAdapter(
                    child: _StatsBanner(
                      totalEconomyGain: freezeState.totalEconomyGain,
                      inflationRate: freezeState.inflationRate,
                    ),
                  ),

                  // Active challenges header
                  if (freezeState.challenges
                      .where((c) => c.isActive)
                      .isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'АКТИВНІ ЧЕЛЕНДЖІ',
                          style: GoogleFonts.orbitron(
                            color: _cyan,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                  // Active challenge cards
                  ...freezeState.challenges
                      .where((c) => c.isActive)
                      .map((challenge) => SliverToBoxAdapter(
                            child: _ActiveChallengeCard(
                              challenge: challenge,
                              onDeposit: () => _showDepositDialog(challenge),
                              onRefreshPrice: () => ref
                                  .read(priceFreezeProvider.notifier)
                                  .refreshCurrentPrice(challenge.id),
                              onEnd: () => ref
                                  .read(priceFreezeProvider.notifier)
                                  .endChallenge(challenge.id),
                              onAiInsight: () async {
                                final insight = await ref
                                    .read(priceFreezeProvider.notifier)
                                    .generateProgressInsight(challenge);
                                if (mounted) {
                                  _showInsightDialog(insight);
                                }
                              },
                            ),
                          )),

                  // Completed challenges section
                  if (freezeState.challenges
                      .where((c) => !c.isActive)
                      .isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'ЗАВЕРШЕНІ',
                          style: GoogleFonts.orbitron(
                            color: _purple,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    ...freezeState.challenges
                        .where((c) => !c.isActive)
                        .map((challenge) => SliverToBoxAdapter(
                              child: _CompletedChallengeCard(
                                challenge: challenge,
                              ),
                            )),
                  ],

                  // Empty state
                  if (freezeState.challenges.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyChallengeState(
                        onStart: () => _showStartChallengeDialog(),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Start challenge dialog
  // ---------------------------------------------------------------------------
  void _showStartChallengeDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final depositController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _cyan.withOpacity(0.4)),
          ),
          title: Text(
            'НОВИЙ ЧЕЛЕНДЖ',
            style: GoogleFonts.orbitron(
              color: _cyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Назва товару',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Заморожена цiна (грн)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: '₴',
                  suffixStyle: const TextStyle(color: _cyan),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: depositController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Щоденний депозит (грн)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: '₴/день',
                  suffixStyle: const TextStyle(color: _green),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cyan),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text) ?? 0;
                final deposit = double.tryParse(depositController.text) ?? 0;
                if (name.isNotEmpty && price > 0 && deposit > 0) {
                  Navigator.of(dialogContext).pop();
                  ref
                      .read(priceFreezeProvider.notifier)
                      .startChallenge(name, price, deposit);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Заморозити'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Daily deposit dialog
  // ---------------------------------------------------------------------------
  void _showDepositDialog(FreezeChallenge challenge) {
    final amountController = TextEditingController(
      text: challenge.dailyDepositAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _green.withOpacity(0.4)),
          ),
          title: Text(
            'ЩОДЕННИЙ ДЕПОЗИТ',
            style: GoogleFonts.orbitron(
              color: _green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                challenge.productName,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Сума депозиту',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: '₴',
                  suffixStyle: const TextStyle(color: _green),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _green.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _green),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  Navigator.of(dialogContext).pop();
                  ref
                      .read(priceFreezeProvider.notifier)
                      .addDailyDeposit(challenge.id, amount);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: _bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Внести'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AI insight dialog
  // ---------------------------------------------------------------------------
  void _showInsightDialog(String insight) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _purple.withOpacity(0.4)),
          ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: _purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'VAULT-17',
                style: GoogleFonts.orbitron(
                  color: _purple,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            insight,
            style: GoogleFonts.shareTechMono(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Зрозуміло'),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

/// Stats banner showing economy gain and inflation rate.
class _StatsBanner extends StatelessWidget {
  final double totalEconomyGain;
  final double inflationRate;

  const _StatsBanner({
    required this.totalEconomyGain,
    required this.inflationRate,
  });

  static const _card = Color(0xFF1A1F2E);
  static const _green = Color(0xFF00FF88);
  static const _cyan = Color(0xFF00F0FF);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green.withOpacity(0.1), _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Economy gain
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ЕКОНОМІЯ ВІД ЗАМОРОЖЕННЯ',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalEconomyGain.toStringAsFixed(0)}₴',
                  style: GoogleFonts.orbitron(
                    color: _green,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: _green.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 40,
            color: Colors.white10,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          // Inflation rate
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ІНФЛЯЦІЯ',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    inflationRate > 10 ? Icons.trending_up : Icons.trending_flat,
                    color: inflationRate > 10 ? _yellow : _cyan,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${inflationRate.toStringAsFixed(1)}%',
                    style: GoogleFonts.orbitron(
                      color: inflationRate > 10 ? _yellow : _cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Active challenge card with progress and actions.
class _ActiveChallengeCard extends StatelessWidget {
  final FreezeChallenge challenge;
  final VoidCallback onDeposit;
  final VoidCallback onRefreshPrice;
  final VoidCallback onEnd;
  final VoidCallback onAiInsight;

  const _ActiveChallengeCard({
    required this.challenge,
    required this.onDeposit,
    required this.onRefreshPrice,
    required this.onEnd,
    required this.onAiInsight,
  });

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context) {
    final isPriceAdvantage = challenge.currentPrice < challenge.frozenPrice;
    final progressColor = challenge.progressPercent >= 80
        ? _green
        : challenge.progressPercent >= 40
            ? _cyan
            : _purple;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: progressColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: product name + days active
          Row(
            children: [
              const Icon(Icons.ac_unit, color: _cyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  challenge.productName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _purple.withOpacity(0.5)),
                ),
                child: Text(
                  '${challenge.daysActive} дн.',
                  style: GoogleFonts.shareTechMono(
                    color: _purple,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Price comparison: frozen vs current
          Row(
            children: [
              // Frozen price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ЗАМОРОЖЕНО',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${challenge.frozenPrice.toStringAsFixed(0)}₴',
                      style: GoogleFonts.orbitron(
                        color: _cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow / comparison
              Column(
                children: [
                  Icon(
                    isPriceAdvantage
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: isPriceAdvantage ? _green : _pink,
                    size: 20,
                  ),
                  if (challenge.savingsVsFrozen > 0)
                    Text(
                      '-${challenge.savingsVsFrozen.toStringAsFixed(0)}₴',
                      style: GoogleFonts.shareTechMono(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              // Current price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ЗАРАЗ',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${challenge.currentPrice.toStringAsFixed(0)}₴',
                      style: GoogleFonts.orbitron(
                        color: isPriceAdvantage ? _green : _pink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ПРОГРЕС',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '${challenge.totalSaved.toStringAsFixed(0)} / ${challenge.frozenPrice.toStringAsFixed(0)}₴  '
                    '(${challenge.progressPercent.toStringAsFixed(1)}%)',
                    style: GoogleFonts.shareTechMono(
                      color: progressColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (challenge.progressPercent / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Economy gain text
          if (challenge.savingsVsFrozen > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_down, color: _green, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Ви зекономили ${challenge.savingsVsFrozen.toStringAsFixed(0)}₴ завдяки ранньому замороженню',
                    style: GoogleFonts.shareTechMono(
                      color: _green,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Price trend visualization
          if (challenge.snapshots.isNotEmpty) ...[
            Text(
              'ТРЕНД ЦІНИ',
              style: GoogleFonts.shareTechMono(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            _PriceTrendChart(
              frozenPrice: challenge.frozenPrice,
              snapshots: challenge.snapshots,
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.add_circle_outline,
                label: 'Депозит',
                color: _green,
                onTap: onDeposit,
              ),
              _ActionButton(
                icon: Icons.refresh,
                label: 'Цiна',
                color: _cyan,
                onTap: onRefreshPrice,
              ),
              _ActionButton(
                icon: Icons.auto_awesome,
                label: 'AI',
                color: _purple,
                onTap: onAiInsight,
              ),
              _ActionButton(
                icon: Icons.stop_circle_outlined,
                label: 'Завершити',
                color: _pink,
                onTap: onEnd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simple price trend chart showing frozen line vs actual prices.
class _PriceTrendChart extends StatelessWidget {
  final double frozenPrice;
  final List<DailySnapshot> snapshots;

  const _PriceTrendChart({
    required this.frozenPrice,
    required this.snapshots,
  });

  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);

  @override
  Widget build(BuildContext context) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _TrendPainter(
          frozenPrice: frozenPrice,
          snapshots: snapshots,
          frozenColor: _cyan,
          priceColor: _green,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  final double frozenPrice;
  final List<DailySnapshot> snapshots;
  final Color frozenColor;
  final Color priceColor;

  _TrendPainter({
    required this.frozenPrice,
    required this.snapshots,
    required this.frozenColor,
    required this.priceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.isEmpty || frozenPrice <= 0) return;

    // Draw frozen price line (dashed)
    final frozenY = size.height * 0.3;
    final frozenPaint = Paint()
      ..color = frozenColor.withOpacity(0.5)
      ..strokeWidth = 1.5;

    // Dashed frozen line
    final dashWidth = 6.0;
    final dashSpace = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, frozenY),
        Offset((startX + dashWidth).clamp(0, size.width), frozenY),
        frozenPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw price points
    final pricePaint = Paint()
      ..color = priceColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minPrice = snapshots
        .map((s) => s.price)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = snapshots
        .map((s) => s.price)
        .reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final usableHeight = size.height - 8;

    if (priceRange <= 0 || snapshots.length < 2) {
      // Just draw a straight line if all prices are the same
      final y = size.height / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pricePaint);
      return;
    }

    final points = <Offset>[];
    for (var i = 0; i < snapshots.length; i++) {
      final x = (i / (snapshots.length - 1)) * size.width;
      final normalizedPrice =
          (snapshots[i].price - minPrice) / priceRange;
      final y = 4 + normalizedPrice * usableHeight;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, pricePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Action button widget for challenge cards.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Completed challenge card.
class _CompletedChallengeCard extends StatelessWidget {
  final FreezeChallenge challenge;

  const _CompletedChallengeCard({required this.challenge});

  static const _card = Color(0xFF1A1F2E);
  static const _green = Color(0xFF00FF88);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: _green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.productName,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Накопичено ${challenge.totalSaved.toStringAsFixed(0)}₴ з ${challenge.frozenPrice.toStringAsFixed(0)}₴  '
                  '| ${challenge.daysActive} дн.',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (challenge.savingsVsFrozen > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _green.withOpacity(0.4)),
              ),
              child: Text(
                '+${challenge.savingsVsFrozen.toStringAsFixed(0)}₴',
                style: GoogleFonts.shareTechMono(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Empty state when no challenges exist.
class _EmptyChallengeState extends StatelessWidget {
  final VoidCallback onStart;

  const _EmptyChallengeState({required this.onStart});

  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cyan.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.ac_unit, color: _cyan, size: 48),
            const SizedBox(height: 16),
            Text(
              'НІЯКИХ ЧЕЛЕНДЖІВ',
              style: GoogleFonts.orbitron(
                color: _cyan,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Заморозьте цiну на товар, щоб почати накопичувати з перевагою',
              style: GoogleFonts.shareTechMono(
                color: Colors.white54,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: const Color(0xFF0A0E17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ПОЧАТИ ЧЕЛЕНДЖ',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
