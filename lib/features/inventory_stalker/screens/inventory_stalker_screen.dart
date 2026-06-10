import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/inventory_stalker_provider.dart';

class InventoryStalkerScreen extends ConsumerStatefulWidget {
  const InventoryStalkerScreen({super.key});

  @override
  ConsumerState<InventoryStalkerScreen> createState() => _InventoryStalkerScreenState();
}

class _InventoryStalkerScreenState extends ConsumerState<InventoryStalkerScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryStalkerProvider);
    final notifier = ref.read(inventoryStalkerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('INVENTORY STALKER', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 17)),
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF)))
          : state.items.isEmpty
              ? _buildEmptyState(notifier)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSearchBar(notifier),
                    const SizedBox(height: 16),
                    ...state.items.map((item) => _buildStalkerCard(item, notifier)),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.warehouse, color: Color(0xFF00F0FF)),
        onPressed: () => _showSearchDialog(notifier),
      ),
    );
  }

  Widget _buildSearchBar(InventoryStalkerNotifier notifier) {
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
          hintText: 'Stalkeryty inventar produktu...',
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
          prefixIcon: const Icon(Icons.warehouse, color: Color(0xFF00F0FF)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF00F0FF)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                notifier.stalkProduct(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            notifier.stalkProduct(v.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildStalkerCard(InventoryItem item, InventoryStalkerNotifier notifier) {
    final signalColor = _getSignalColor(item.buySignal);
    final signalLabel = _getSignalLabel(item.buySignal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signalColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(item.name, style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 16))),
                Text('${item.currentPrice.toStringAsFixed(0)} грн', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: signalColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: signalColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getSignalIcon(item.buySignal), color: signalColor, size: 16),
                  const SizedBox(width: 8),
                  Text(signalLabel, style: GoogleFonts.orbitron(color: signalColor, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('SEREDN. ZAPAS', '${item.avgStockLevel.toStringAsFixed(0)}%', const Color(0xFF00F0FF)),
                const SizedBox(width: 14),
                _buildStatItem('KOREL YATSIYA', '${(item.priceStockCorrelation * 100).toStringAsFixed(0)}%', const Color(0xFF6B00FF)),
                const SizedBox(width: 14),
                _buildStatItem('DROP SHANS', '${(item.dropProbability * 100).toStringAsFixed(0)}%', const Color(0xFFFF3366)),
                const SizedBox(width: 14),
                _buildStatItem('DO RESTOCK', '${item.daysUntilRestock}d', const Color(0xFFFFD700)),
              ],
            ),
            const SizedBox(height: 12),
            Text('ZAPASY PO MAGAZYNAM', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 11)),
            const SizedBox(height: 6),
            ...item.stockByStore.map((s) {
              final stockColor = s.stockLevel > 60 ? const Color(0xFF00FF88) : s.stockLevel > 30 ? const Color(0xFFFFD700) : const Color(0xFFFF3366);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 80, child: Text(s.store, style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 12))),
                        Text('${s.price.toStringAsFixed(0)} грн', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 12)),
                        const Spacer(),
                        Text('${s.stockLevel}%', style: GoogleFonts.shareTechMono(color: stockColor, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: s.stockLevel / 100,
                        backgroundColor: const Color(0xFF0A0E17),
                        valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.update, color: Color(0xFFFFD700), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RESTITORY PROHNOZ', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('Oriyentovno: ${item.restockPrediction.expectedDate.day}.${item.restockPrediction.expectedDate.month}.${item.restockPrediction.expectedDate.year}', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11)),
                        Text('Prohnozova tsina: ${item.restockPrediction.predictedPrice.toStringAsFixed(0)} грн (${(item.restockPrediction.confidence * 100).toStringAsFixed(0)}%)', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (item.aiAlert.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.4)),
                ),
                child: Text(item.aiAlert, style: GoogleFonts.shareTechMono(color: const Color(0xFF6B00FF), fontSize: 12)),
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.shareTechMono(color: color.withOpacity(0.6), fontSize: 9)),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 13)),
      ],
    );
  }

  Color _getSignalColor(String signal) {
    switch (signal) {
      case 'high_stock_price_dropping': return const Color(0xFF00FF88);
      case 'low_stock_wait_restock': return const Color(0xFFFF3366);
      case 'moderate_correlation': return const Color(0xFFFFD700);
      default: return const Color(0xFF00F0FF);
    }
  }

  String _getSignalLabel(String signal) {
    switch (signal) {
      case 'high_stock_price_dropping': return 'VYSOKYY ZAPAS - TSINA SPADAE';
      case 'low_stock_wait_restock': return 'NYYZKYY ZAPAS - CHEKAY RESTOCK';
      case 'moderate_correlation': return 'POMIRNA KOREL YATSIYA';
      default: return 'NEMA SYHNALU';
    }
  }

  IconData _getSignalIcon(String signal) {
    switch (signal) {
      case 'high_stock_price_dropping': return Icons.trending_down;
      case 'low_stock_wait_restock': return Icons.warning;
      case 'moderate_correlation': return Icons.show_chart;
      default: return Icons.help_outline;
    }
  }

  Widget _buildEmptyState(InventoryStalkerNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warehouse, size: 64, color: const Color(0xFF00F0FF).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('INVENTORY STALKER', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 20)),
            const SizedBox(height: 8),
            Text('Stalkeryty inventar ta tsiny', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
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

  void _showSearchDialog(InventoryStalkerNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('STALKINH', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.shareTechMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nazva produktu dlya stalkinhu...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
            prefixIcon: const Icon(Icons.warehouse, color: Color(0xFF00F0FF)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B00FF)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.stalkProduct(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('STALK', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }
}
