import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/secondhand_analyzer_provider.dart';

class SecondhandAnalyzerScreen extends ConsumerStatefulWidget {
  const SecondhandAnalyzerScreen({super.key});

  @override
  ConsumerState<SecondhandAnalyzerScreen> createState() => _SecondhandAnalyzerScreenState();
}

class _SecondhandAnalyzerScreenState extends ConsumerState<SecondhandAnalyzerScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(secondhandAnalyzerProvider);
    final notifier = ref.read(secondhandAnalyzerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('SECOND-HAND ANALYZER', style: GoogleFonts.orbitron(color: const Color(0xFF00FF88), fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF00FF88)),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF88)))
          : state.items.isEmpty
              ? _buildEmptyState(notifier)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSearchBar(notifier),
                    const SizedBox(height: 16),
                    ...state.items.map((item) => _buildItemCard(item, notifier)),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.add, color: Color(0xFF00FF88)),
        onPressed: () => _showSearchDialog(notifier),
      ),
    );
  }

  Widget _buildSearchBar(SecondHandAnalyzerNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.shareTechMono(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Shukay b/u produkt...',
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF88)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF00FF88)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                notifier.analyzeProduct(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            notifier.analyzeProduct(v.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildItemCard(SecondHandItem item, SecondHandAnalyzerNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.name, style: GoogleFonts.orbitron(color: const Color(0xFF00FF88), fontSize: 16))),
                IconButton(icon: const Icon(Icons.delete, color: Color(0xFFFF3366), size: 20), onPressed: () => notifier.removeItem(item.id)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriceBadge('NOVE', '${item.newPrice.toStringAsFixed(0)} грн', const Color(0xFFFF3366)),
                const SizedBox(width: 12),
                _buildPriceBadge('B/U SEREDNYE', '${item.avgUsedPrice.toStringAsFixed(0)} грн', const Color(0xFF00F0FF)),
                const SizedBox(width: 12),
                _buildPriceBadge('B/U NAJKRASHCHE', '${item.bestUsedPrice.toStringAsFixed(0)} грн', const Color(0xFF00FF88)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('EKONOMIYA: ', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13)),
                  Text('${item.savingsPercent.toStringAsFixed(1)}%', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('PLATFORMY', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 12)),
            const SizedBox(height: 6),
            ...item.listings.take(5).map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 90, child: Text(l.platform, style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 12))),
                  SizedBox(width: 80, child: Text(l.condition, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11))),
                  Text('${l.price.toStringAsFixed(0)} грн', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 12)),
                ],
              ),
            )),
            if (item.depreciationCurve.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('DEPRETSIATSIYA', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 12)),
              const SizedBox(height: 6),
              ...item.depreciationCurve.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    SizedBox(width: 60, child: Text('+${d.monthOffset}m', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11))),
                    Text('-${(d.newPrice - d.usedPrice).toStringAsFixed(0)} грн (${d.depreciationPercent.toStringAsFixed(0)}%)', style: GoogleFonts.shareTechMono(color: const Color(0xFFFF3366), fontSize: 11)),
                  ],
                ),
              )),
            ],
            if (item.aiVerdict.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.4)),
                ),
                child: Text(item.aiVerdict, style: GoogleFonts.shareTechMono(color: const Color(0xFF6B00FF), fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBadge(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.shareTechMono(color: color.withOpacity(0.7), fontSize: 10)),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState(SecondHandAnalyzerNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cached, size: 64, color: const Color(0xFF00FF88).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('SECOND-HAND ANALYZER', style: GoogleFonts.orbitron(color: const Color(0xFF00FF88), fontSize: 20)),
            const SizedBox(height: 8),
            Text('Analiz tsin na b/u rynku vs novi', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
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
                  label: Text(cat['name'] as String, style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 11)),
                  backgroundColor: const Color(0xFF1A1F2E),
                  side: const BorderSide(color: Color(0xFF00FF88), width: 0.5),
                  onPressed: () => notifier.addPredefinedProduct(i),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(SecondHandAnalyzerNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('ANALIZ B/U', style: GoogleFonts.orbitron(color: const Color(0xFF00FF88), fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.shareTechMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nazva produktu...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF00FF88)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00FF88).withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B00FF)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.analyzeProduct(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('ANALIZ', style: GoogleFonts.orbitron(color: const Color(0xFF00FF88))),
          ),
        ],
      ),
    );
  }
}
