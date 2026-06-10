import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/price_prophet_provider.dart';

class PriceProphetScreen extends ConsumerStatefulWidget {
  const PriceProphetScreen({super.key});

  @override
  ConsumerState<PriceProphetScreen> createState() => _PriceProphetScreenState();
}

class _PriceProphetScreenState extends ConsumerState<PriceProphetScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceProphetProvider);
    final notifier = ref.read(priceProphetProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('PRICE PROPHET', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 20)),
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
          : state.items.isEmpty
              ? _buildEmptyState(notifier)
              : RefreshIndicator(
                  color: const Color(0xFF00F0FF),
                  backgroundColor: const Color(0xFF1A1F2E),
                  onRefresh: () async {},
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSearchBar(notifier),
                      const SizedBox(height: 16),
                      ...state.items.map((item) => _buildForecastCard(item, notifier)),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.add, color: Color(0xFF00F0FF)),
        onPressed: () => _showSearchDialog(notifier),
      ),
    );
  }

  Widget _buildSearchBar(PriceProphetNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.shareTechMono(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Shukay produkt dlya prohnozu...',
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF00F0FF)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                notifier.searchAndForecast(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            notifier.searchAndForecast(value.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildForecastCard(PriceProphetItem item, PriceProphetNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.name, style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 16)),
                ),
                Text('${item.currentPrice.toStringAsFixed(0)} грн', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 18)),
              ],
            ),
            if (item.targetGoalPrice != null) ...[
              const SizedBox(height: 4),
              Text('Tsileva tsina: ${item.targetGoalPrice!.toStringAsFixed(0)} грн', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 13)),
            ],
            const SizedBox(height: 4),
            Text(item.category, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12)),
            const Divider(color: Color(0x3300F0FF)),
            Text('PROGNOZY', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 13)),
            const SizedBox(height: 8),
            ...item.scenarios.map((s) => _buildScenarioRow(s)),
            if (item.aiInsight.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00F0FF), size: 20),
                  onPressed: () => notifier.refreshForecast(item.id),
                ),
                IconButton(
                  icon: const Icon(Icons.flag, color: Color(0xFFFFD700), size: 20),
                  onPressed: () => _showTargetDialog(item, notifier),
                ),
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

  Widget _buildScenarioRow(ForecastScenario scenario) {
    Color color;
    String label;
    switch (scenario.name) {
      case 'optimistic':
        color = const Color(0xFF00FF88);
        label = 'OPTIMIST';
        break;
      case 'realistic':
        color = const Color(0xFF00F0FF);
        label = 'REALIST';
        break;
      case 'pessimistic':
        color = const Color(0xFFFF3366);
        label = 'PESSIMIST';
        break;
      default:
        color = Colors.white;
        label = scenario.name.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.5))),
            child: Text(label, style: GoogleFonts.orbitron(color: color, fontSize: 10)),
          ),
          const SizedBox(width: 10),
          Text('${scenario.targetPrice.toStringAsFixed(0)} грн', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14)),
          const SizedBox(width: 10),
          Text('${(scenario.confidence * 100).toStringAsFixed(0)}%', style: GoogleFonts.shareTechMono(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(PriceProphetNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph, size: 64, color: const Color(0xFF6B00FF).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('PRICE PROPHET', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 22)),
            const SizedBox(height: 8),
            Text('ML-prohnoz tsin z dovirchymy intervalamy', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
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
                  label: Text(cat['name'] as String, style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 11)),
                  backgroundColor: const Color(0xFF1A1F2E),
                  side: const BorderSide(color: Color(0xFF00F0FF), width: 0.5),
                  onPressed: () => notifier.addPredefinedProduct(i),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(PriceProphetNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('NOVYY PROHNOZ', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.shareTechMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nazva produktu...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF00F0FF)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B00FF)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.searchAndForecast(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('PROHNOZ', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }

  void _showTargetDialog(PriceProphetItem item, PriceProphetNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('TSILEVA TSINA', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 16)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.shareTechMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Vvedit tsilevu tsinu...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
            prefixIcon: const Icon(Icons.flag, color: Color(0xFFFFD700)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () {
              final val = double.tryParse(ctrl.text);
              if (val != null) {
                notifier.setTargetPrice(item.id, val);
                Navigator.pop(ctx);
              }
            },
            child: Text('ZBEREHITY', style: GoogleFonts.orbitron(color: const Color(0xFF0A0E17))),
          ),
        ],
      ),
    );
  }
}
