import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/price_momentum_provider.dart';

class PriceMomentumScreen extends ConsumerStatefulWidget {
  const PriceMomentumScreen({super.key});

  @override
  ConsumerState<PriceMomentumScreen> createState() => _PriceMomentumScreenState();
}

class _PriceMomentumScreenState extends ConsumerState<PriceMomentumScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceMomentumProvider);
    final notifier = ref.read(priceMomentumProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('PRICE MOMENTUM', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFFFF3366)),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3366)))
          : state.items.isEmpty
              ? _buildEmptyState(notifier)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSearchBar(notifier),
                    const SizedBox(height: 16),
                    ...state.items.map((item) => _buildMomentumCard(item, notifier)),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.add, color: Color(0xFFFF3366)),
        onPressed: () => _showSearchDialog(notifier),
      ),
    );
  }

  Widget _buildSearchBar(PriceMomentumNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.shareTechMono(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Shukay produkt dlya analizu momenumu...',
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFFF3366)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFFFF3366)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                notifier.analyzeMomentum(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            notifier.analyzeMomentum(v.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildMomentumCard(MomentumItem item, PriceMomentumNotifier notifier) {
    final phaseColor = _getPhaseColor(item.phase);
    final phaseLabel = _getPhaseLabel(item.phase);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.name, style: GoogleFonts.orbitron(color: phaseColor, fontSize: 16))),
                Text('${item.currentPrice.toStringAsFixed(0)} грн', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: phaseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: phaseColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPhaseIcon(item.phase), color: phaseColor, size: 18),
                  const SizedBox(width: 8),
                  Text(phaseLabel, style: GoogleFonts.orbitron(color: phaseColor, fontSize: 13)),
                  const SizedBox(width: 12),
                  Text('${(item.phaseConfidence * 100).toStringAsFixed(0)}%', style: GoogleFonts.shareTechMono(color: phaseColor.withOpacity(0.7), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('7d', item.priceChange7d, const Color(0xFF00F0FF)),
                const SizedBox(width: 16),
                _buildStatItem('30d', item.priceChange30d, const Color(0xFF6B00FF)),
                const SizedBox(width: 16),
                _buildStatItem('DROP', item.dropProbability * 100, const Color(0xFFFF3366), suffix: '%'),
                const SizedBox(width: 16),
                _buildStatItem('STAG', item.stagnationDays, const Color(0xFFFFD700), suffix: 'd'),
              ],
            ),
            const SizedBox(height: 12),
            if (item.history.length > 10)
              _buildMiniChart(item, phaseColor),
            if (item.aiAnalysis.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.4)),
                ),
                child: Text(item.aiAnalysis, style: GoogleFonts.shareTechMono(color: const Color(0xFF6B00FF), fontSize: 12)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(item.category, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFFF3366), size: 20),
                  onPressed: () => notifier.removeItem(item.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, Color color, {String suffix = ''}) {
    final isNeg = value < 0;
    final displayValue = value.abs().toStringAsFixed(value > 10 ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.shareTechMono(color: color.withOpacity(0.7), fontSize: 10)),
        Text('${isNeg ? '-' : '+'}$displayValue$suffix', style: GoogleFonts.orbitron(color: isNeg ? const Color(0xFFFF3366) : const Color(0xFF00FF88), fontSize: 13)),
      ],
    );
  }

  Widget _buildMiniChart(MomentumItem item, Color phaseColor) {
    final recent = item.history.length > 30 ? item.history.sublist(item.history.length - 30) : item.history;
    final prices = recent.map((p) => p.price).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = maxP - minP;

    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: _MiniChartPainter(prices: prices, minPrice: minP, range: range > 0 ? range : 1, color: phaseColor),
        size: Size.infinite,
      ),
    );
  }

  Color _getPhaseColor(MomentumPhase phase) {
    switch (phase) {
      case MomentumPhase.growth: return const Color(0xFF00FF88);
      case MomentumPhase.peak: return const Color(0xFFFFD700);
      case MomentumPhase.stable: return const Color(0xFF00F0FF);
      case MomentumPhase.drop: return const Color(0xFFFF3366);
      case MomentumPhase.stagnation: return const Color(0xFF6B00FF);
    }
  }

  String _getPhaseLabel(MomentumPhase phase) {
    switch (phase) {
      case MomentumPhase.growth: return 'ROST';
      case MomentumPhase.peak: return 'PYK';
      case MomentumPhase.stable: return 'STABILNIST';
      case MomentumPhase.drop: return 'SPAD';
      case MomentumPhase.stagnation: return 'STAHNATSIYA';
    }
  }

  IconData _getPhaseIcon(MomentumPhase phase) {
    switch (phase) {
      case MomentumPhase.growth: return Icons.trending_up;
      case MomentumPhase.peak: return Icons.show_chart;
      case MomentumPhase.stable: return Icons.trending_flat;
      case MomentumPhase.drop: return Icons.trending_down;
      case MomentumPhase.stagnation: return Icons.pause;
    }
  }

  Widget _buildEmptyState(PriceMomentumNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_down, size: 64, color: const Color(0xFFFF3366).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('PRICE MOMENTUM', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 20)),
            const SizedBox(height: 8),
            Text('Inertsiya tsiny: vyyvay fazu ta chas kupuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _buildSearchBar(notifier),
            const SizedBox(height: 24),
            Text('KATALOH', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(notifier.predefinedCatalog.length, (i) {
                final cat = notifier.predefinedCatalog[i];
                return ActionChip(
                  label: Text(cat['name'] as String, style: GoogleFonts.shareTechMono(color: const Color(0xFFFF3366), fontSize: 11)),
                  backgroundColor: const Color(0xFF1A1F2E),
                  side: const BorderSide(color: Color(0xFFFF3366), width: 0.5),
                  onPressed: () => notifier.addPredefinedProduct(i),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(PriceMomentumNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('MOMENTUM ANALIZ', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.shareTechMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nazva produktu...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFF3366)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFFFF3366).withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B00FF)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.analyzeMomentum(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('ANALIZ', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366))),
          ),
        ],
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  final List<double> prices;
  final double minPrice;
  final double range;
  final Color color;

  _MiniChartPainter({required this.prices, required this.minPrice, required this.range, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < prices.length; i++) {
      final x = (i / (prices.length - 1)) * size.width;
      final y = size.height - ((prices[i] - minPrice) / range) * size.height * 0.8 - size.height * 0.1;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
