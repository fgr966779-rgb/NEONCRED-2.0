import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/price_war_provider.dart';

class PriceWarScreen extends ConsumerStatefulWidget {
  const PriceWarScreen({super.key});

  @override
  ConsumerState<PriceWarScreen> createState() => _PriceWarScreenState();
}

class _PriceWarScreenState extends ConsumerState<PriceWarScreen> {
  final _searchController = TextEditingController();
  bool _showPast = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceWarProvider);
    final notifier = ref.read(priceWarProvider.notifier);
    final wars = _showPast ? state.pastWars : state.activeWars;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('PRICE WAR SENTINEL', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 17)),
        iconTheme: const IconThemeData(color: Color(0xFFFF3366)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _showPast = !_showPast),
            child: Text(_showPast ? 'AKTYVNI' : 'ARKHIV', style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 12)),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3366)))
          : wars.isEmpty
              ? _buildEmptyState(notifier)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSearchBar(notifier),
                    const SizedBox(height: 16),
                    ...wars.map((war) => _buildWarCard(war, notifier)),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.radar, color: Color(0xFFFF3366)),
        onPressed: () => _showSearchDialog(notifier),
      ),
    );
  }

  Widget _buildSearchBar(PriceWarNotifier notifier) {
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
          hintText: 'Skanyuvaty tsinovi viyny...',
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
          prefixIcon: const Icon(Icons.radar, color: Color(0xFFFF3366)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFFF3366)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                notifier.scanForWars(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            notifier.scanForWars(v.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildWarCard(PriceWarItem war, PriceWarNotifier notifier) {
    final recColor = _getRecColor(war.buyRecommendation);
    final recLabel = _getRecLabel(war.buyRecommendation);
    final intensityColor = war.warIntensity > 0.25 ? const Color(0xFFFF3366) : war.warIntensity > 0.15 ? const Color(0xFFFFD700) : const Color(0xFF00F0FF);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: intensityColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(war.productName, style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: recColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: recColor.withOpacity(0.5))),
                  child: Text(recLabel, style: GoogleFonts.orbitron(color: recColor, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ORIHINAL', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
                  Text('${war.originalPrice.toStringAsFixed(0)} грн', style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 14)),
                ]),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NAIKRASHCHE', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 10)),
                  Text('${war.currentBestPrice.toStringAsFixed(0)} грн', style: GoogleFonts.orbitron(color: const Color(0xFF00FF88), fontSize: 16)),
                ]),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('EKONOMIYA', style: GoogleFonts.shareTechMono(color: const Color(0xFFFFD700), fontSize: 10)),
                  Text('${war.totalSavings.toStringAsFixed(1)}%', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 16)),
                ]),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('DEN VIYNY: ', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
                Text('${war.warDay}', style: GoogleFonts.shareTechMono(color: intensityColor, fontSize: 13)),
                const SizedBox(width: 16),
                Text('INTENSIVNIST: ', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
                Text('${(war.warIntensity * 100).toStringAsFixed(0)}%', style: GoogleFonts.shareTechMono(color: intensityColor, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Text('FRONTY', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 12)),
            const SizedBox(height: 6),
            ...war.battles.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(b.retailerA, style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${b.priceA.toStringAsFixed(0)} грн', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 12)),
                  ),
                  Text('vs', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10)),
                  Expanded(
                    flex: 2,
                    child: Text('${b.priceB.toStringAsFixed(0)} грн', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 12), textAlign: TextAlign.end),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(b.retailerB, style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 12), textAlign: TextAlign.end),
                  ),
                ],
              ),
            )),
            if (war.aiCommentary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.4)),
                ),
                child: Text(war.aiCommentary, style: GoogleFonts.shareTechMono(color: const Color(0xFF6B00FF), fontSize: 12)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (war.isWarActive)
                  TextButton.icon(
                    icon: const Icon(Icons.archive, color: Color(0xFFFFD700), size: 16),
                    label: Text('ARKHIV', style: GoogleFonts.shareTechMono(color: const Color(0xFFFFD700), fontSize: 11)),
                    onPressed: () => notifier.archiveWar(war.id),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFFF3366), size: 20),
                  onPressed: () => notifier.removeWar(war.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRecColor(String rec) {
    switch (rec) {
      case 'buy_now': return const Color(0xFF00FF88);
      case 'watch_closely': return const Color(0xFFFFD700);
      case 'wait_for_escalation': return const Color(0xFF00F0FF);
      default: return Colors.white38;
    }
  }

  String _getRecLabel(String rec) {
    switch (rec) {
      case 'buy_now': return 'KUPUVATY';
      case 'watch_closely': return 'SLIDKUVATY';
      case 'wait_for_escalation': return 'CHEKATY';
      default: return 'NEMA VIYNY';
    }
  }

  Widget _buildEmptyState(PriceWarNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, size: 64, color: const Color(0xFFFF3366).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('PRICE WAR SENTINEL', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 20)),
            const SizedBox(height: 8),
            Text('Vartov tsinovykh viyn: skanyuy rynok', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
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

  void _showSearchDialog(PriceWarNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('SKAN VIYN', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 16)),
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
                notifier.scanForWars(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('SKAN', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366))),
          ),
        ],
      ),
    );
  }
}
