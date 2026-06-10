import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/price_elasticity_provider.dart';

class PriceElasticityScreen extends ConsumerStatefulWidget {
  const PriceElasticityScreen({super.key});

  @override
  ConsumerState<PriceElasticityScreen> createState() => _PriceElasticityScreenState();
}

class _PriceElasticityScreenState extends ConsumerState<PriceElasticityScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceElasticityProvider);
    final notifier = ref.read(priceElasticityProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('PRICE ELASTICITY', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF6B00FF)),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6B00FF)))
          : state.items.isEmpty
              ? _buildEmptyState(notifier)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (state.dailyStreak > 0) _buildStreakBadge(state.dailyStreak),
                    const SizedBox(height: 12),
                    _buildSearchBar(notifier),
                    const SizedBox(height: 16),
                    ...state.items.map((item) => _buildElasticityCard(item, notifier)),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.insights, color: Color(0xFF00F0FF)),
        onPressed: () => _showSearchDialog(notifier),
      ),
    );
  }

  Widget _buildStreakBadge(int streak) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department, color: Color(0xFFFFD700), size: 20),
          const SizedBox(width: 8),
          Text('STRIK: $streak dniv', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(PriceElasticityNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.shareTechMono(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Analizuvaty elastychnist tsiny...',
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
          prefixIcon: const Icon(Icons.insights, color: Color(0xFF6B00FF)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF6B00FF)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                notifier.analyzeElasticity(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            notifier.analyzeElasticity(v.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildElasticityCard(ElasticityItem item, PriceElasticityNotifier notifier) {
    final typeColor = _getElasticityColor(item.analysis.type);
    final typeLabel = _getElasticityLabel(item.analysis.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.name, style: GoogleFonts.orbitron(color: typeColor, fontSize: 16))),
                Text('${item.currentPrice.toStringAsFixed(0)} грн', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getElasticityIcon(item.analysis.type), color: typeColor, size: 18),
                  const SizedBox(width: 8),
                  Text(typeLabel, style: GoogleFonts.orbitron(color: typeColor, fontSize: 13)),
                  const SizedBox(width: 12),
                  Text('E=${item.analysis.coefficient.toStringAsFixed(2)}', style: GoogleFonts.shareTechMono(color: typeColor.withOpacity(0.7), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(item.analysis.interpretation, style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatBox('OPTYMALNA', '${item.analysis.optimalPrice.toStringAsFixed(0)} грн', const Color(0xFF00FF88)),
                const SizedBox(width: 12),
                _buildStatBox('VOLATYLNIST', '${(item.priceVolatility * 100).toStringAsFixed(1)}%', const Color(0xFFFF3366)),
                const SizedBox(width: 12),
                _buildStatBox('CHAS KUPUVATY', item.bestTimeToBuy, const Color(0xFFFFD700)),
              ],
            ),
            if (item.demandCurve.length > 10) ...[
              const SizedBox(height: 12),
              Text('KRYYA POPUTU', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 11)),
              const SizedBox(height: 6),
              _buildDemandChart(item),
            ],
            if (item.aiInsight.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.4)),
                ),
                child: Text(item.aiInsight, style: GoogleFonts.shareTechMono(color: const Color(0xFF6B00FF), fontSize: 12)),
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

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E17),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.shareTechMono(color: color.withOpacity(0.6), fontSize: 9)),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandChart(ElasticityItem item) {
    final recent = item.demandCurve.length > 20 ? item.demandCurve.sublist(item.demandCurve.length - 20) : item.demandCurve;
    return SizedBox(
      height: 50,
      child: CustomPaint(
        painter: _DemandCurvePainter(points: recent, color: _getElasticityColor(item.analysis.type)),
        size: Size.infinite,
      ),
    );
  }

  Color _getElasticityColor(ElasticityType type) {
    switch (type) {
      case ElasticityType.elastic: return const Color(0xFF00FF88);
      case ElasticityType.inelastic: return const Color(0xFFFF3366);
      case ElasticityType.unitElastic: return const Color(0xFF00F0FF);
    }
  }

  String _getElasticityLabel(ElasticityType type) {
    switch (type) {
      case ElasticityType.elastic: return 'ELASTYCHNYY';
      case ElasticityType.inelastic: return 'NEELASTYCHNYY';
      case ElasticityType.unitElastic: return 'ODYNYCHNA';
    }
  }

  IconData _getElasticityIcon(ElasticityType type) {
    switch (type) {
      case ElasticityType.elastic: return Icons.trending_down;
      case ElasticityType.inelastic: return Icons.lock;
      case ElasticityType.unitElastic: return Icons.balance;
    }
  }

  Widget _buildEmptyState(PriceElasticityNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights, size: 64, color: const Color(0xFF6B00FF).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('PRICE ELASTICITY', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 20)),
            const SizedBox(height: 8),
            Text('Elastychnist tsiny: koly kupuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
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
                  label: Text(cat['name'] as String, style: GoogleFonts.shareTechMono(color: const Color(0xFF6B00FF), fontSize: 11)),
                  backgroundColor: const Color(0xFF1A1F2E),
                  side: const BorderSide(color: Color(0xFF6B00FF), width: 0.5),
                  onPressed: () => notifier.addPredefinedProduct(i),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(PriceElasticityNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('ELASTYCHNIST', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.shareTechMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nazva produktu...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
            prefixIcon: const Icon(Icons.insights, color: Color(0xFF6B00FF)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF6B00FF).withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B00FF)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.analyzeElasticity(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('ANALIZ', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }
}

class _DemandCurvePainter extends CustomPainter {
  final List<DemandPoint> points;
  final Color color;

  _DemandCurvePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - (points[i].demandLevel.clamp(0.0, 2.0) / 2.0) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
