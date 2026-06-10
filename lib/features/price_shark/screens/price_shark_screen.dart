import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/price_shark_provider.dart';

// =============================================================================
// Price Shark Screen — Track prices across 20+ stores with fairness analysis
// =============================================================================

class PriceSharkScreen extends ConsumerStatefulWidget {
  const PriceSharkScreen({super.key});

  @override
  ConsumerState<PriceSharkScreen> createState() => _PriceSharkScreenState();
}

class _PriceSharkScreenState extends ConsumerState<PriceSharkScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceSharkProvider);
    final notifier = ref.read(priceSharkProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(
          'PRICE SHARK',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00F0FF)),
            onPressed: state.isLoading
                ? null
                : () => notifier.refreshAllPrices(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            )
          : RefreshIndicator(
              color: const Color(0xFF00F0FF),
              backgroundColor: const Color(0xFF0A0E17),
              onRefresh: () => notifier.refreshAllPrices(),
              child: CustomScrollView(
                slivers: [
                  // Search bar
                  SliverToBoxAdapter(child: _buildSearchBar(notifier)),

                  // Price alerts
                  if (state.alerts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildAlertsSection(state.alerts),
                    ),

                  // Tracked items
                  if (state.trackedItems.isEmpty)
                    const SliverToBoxAdapter(
                      child: _EmptyState(
                        icon: Icons.search,
                        title: 'Akula shukaye zhertvu...',
                        subtitle:
                            'Dodai tovar z katalohu abo znaydy cherez poshuk',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildTrackedItemCard(
                          state.trackedItems[index],
                          notifier,
                        ),
                        childCount: state.trackedItems.length,
                      ),
                    ),

                  // Predefined catalog
                  SliverToBoxAdapter(child: _buildCatalogSection(notifier, state.trackedItems)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddItemDialog(context, notifier),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search bar
  // ---------------------------------------------------------------------------

  Widget _buildSearchBar(PriceSharkNotifier notifier) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF00F0FF)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Shukai tovar...',
                hintStyle: GoogleFonts.shareTechMono(
                  color: const Color(0xFF4A5568),
                ),
                border: InputBorder.none,
              ),
              onSubmitted: (query) async {
                if (query.trim().isNotEmpty) {
                  final prices = await notifier.searchProduct(query.trim());
                  if (prices.isNotEmpty && mounted) {
                    _showSearchResultsDialog(context, query.trim(), prices, notifier);
                  }
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFF00F0FF)),
            onPressed: () async {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                final prices = await notifier.searchProduct(query);
                if (prices.isNotEmpty && mounted) {
                  _showSearchResultsDialog(context, query, prices, notifier);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alerts section
  // ---------------------------------------------------------------------------

  Widget _buildAlertsSection(List<PriceAlert> alerts) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'SYHNALY AKULY',
              style: GoogleFonts.orbitron(
                color: const Color(0xFF00FF88),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          ...alerts.take(3).map((alert) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_down,
                      color: Color(0xFF00FF88),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${alert.itemName}: tsina vpadala z ${alert.previousPrice.toStringAsFixed(0)} do ${alert.newPrice.toStringAsFixed(0)} hrn (-${alert.dropPercent.toStringAsFixed(1)}%) v ${alert.store}',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tracked item card
  // ---------------------------------------------------------------------------

  Widget _buildTrackedItemCard(
    PriceSharkItem item,
    PriceSharkNotifier notifier,
  ) {
    final isBelowTarget =
        item.targetPrice > 0 && item.currentPrice <= item.targetPrice;
    final borderColor = isBelowTarget
        ? const Color(0xFF00FF88)
        : const Color(0xFF00F0FF).withOpacity(0.3);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + fairness badge
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isFairPrice
                      ? const Color(0xFF00FF88).withOpacity(0.2)
                      : const Color(0xFFFF3366).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.fairnessScore.toStringAsFixed(0)}/100',
                  style: GoogleFonts.shareTechMono(
                    color: item.isFairPrice
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF3366),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current price
          Row(
            children: [
              Text(
                'Zaraz: ',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                  fontSize: 14,
                ),
              ),
              Text(
                '${item.currentPrice.toStringAsFixed(0)} hrn',
                style: GoogleFonts.orbitron(
                  color: isBelowTarget
                      ? const Color(0xFF00FF88)
                      : const Color(0xFF00F0FF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Price range
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Min/Max 90d: ',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                  fontSize: 12,
                ),
              ),
              Text(
                '${item.minPrice90d.toStringAsFixed(0)} / ${item.maxPrice90d.toStringAsFixed(0)} hrn',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF6B00FF),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Fairness score bar
          const SizedBox(height: 8),
          _buildFairnessBar(item.fairnessScore),

          // Best store + target price
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.bestStore.isNotEmpty)
                Text(
                  'Naikrashche: ${item.bestStore}',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8B95A5),
                    fontSize: 12,
                  ),
                ),
              if (item.targetPrice > 0)
                Text(
                  'Tsili: ${item.targetPrice.toStringAsFixed(0)} hrn',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFFFD700),
                    fontSize: 12,
                  ),
                ),
            ],
          ),

          // Actions
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text(
                  'AI Insait',
                  style: GoogleFonts.shareTechMono(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B00FF),
                ),
                onPressed: () async {
                  final insight = await notifier.generateInsight(item);
                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1F2E),
                        title: Text(
                          item.name,
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF00F0FF),
                            fontSize: 16,
                          ),
                        ),
                        content: Text(
                          insight,
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Zrozumilo',
                              style: GoogleFonts.shareTechMono(
                                color: const Color(0xFF00F0FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.track_changes, size: 16),
                label: Text(
                  'Tsili',
                  style: GoogleFonts.shareTechMono(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                ),
                onPressed: () => _showSetTargetDialog(context, item, notifier),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFFFF3366), size: 20),
                onPressed: () => notifier.removeItem(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Fairness score progress bar
  // ---------------------------------------------------------------------------

  Widget _buildFairnessBar(double score) {
    final color = score >= 70
        ? const Color(0xFF00FF88)
        : score >= 40
            ? const Color(0xFFFFD700)
            : const Color(0xFFFF3366);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chesnist tsiny',
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF8B95A5),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: const Color(0xFF0D1117),
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Catalog section
  // ---------------------------------------------------------------------------

  Widget _buildCatalogSection(PriceSharkNotifier notifier, List<PriceSharkItem> trackedItems) {
    final products = notifier.predefinedCatalog;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KATALOH BAZHAN',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF6B00FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: products.map((p) {
              final isTracked =
                  trackedItems.any((i) => i.id == p.id);
              return ActionChip(
                label: Text(
                  p.name,
                  style: GoogleFonts.shareTechMono(
                    color: isTracked
                        ? const Color(0xFF00FF88)
                        : Colors.white,
                    fontSize: 11,
                  ),
                ),
                backgroundColor: isTracked
                    ? const Color(0xFF00FF88).withOpacity(0.1)
                    : const Color(0xFF1A1F2E),
                side: BorderSide(
                  color: isTracked
                      ? const Color(0xFF00FF88)
                      : const Color(0xFF6B00FF),
                  width: 0.5,
                ),
                onPressed: isTracked ? null : () => notifier.addPredefinedProduct(p.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search results dialog
  // ---------------------------------------------------------------------------

  void _showSearchResultsDialog(
    BuildContext context,
    String query,
    List<PricePoint> prices,
    PriceSharkNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          'Rezultaty poshuku',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: prices.length,
            itemBuilder: (_, index) {
              final p = prices[index];
              return ListTile(
                title: Text(
                  p.store.isNotEmpty ? p.store : 'Mahazyn',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                trailing: Text(
                  '${p.price.toStringAsFixed(0)} hrn',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF00F0FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Zakryty',
              style: GoogleFonts.shareTechMono(color: const Color(0xFF8B95A5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B00FF),
            ),
            onPressed: () {
              final bestPrice = prices
                  .reduce((a, b) => a.price < b.price ? a : b);
              notifier.trackItem(PriceSharkItem(
                id: 'search_${DateTime.now().millisecondsSinceEpoch}',
                name: query,
                searchQuery: query,
                currentPrice: bestPrice.price,
                bestStore: bestPrice.store,
                bestStorePrice: bestPrice.price,
              ));
              Navigator.pop(ctx);
            },
            child: Text(
              'Stepezhyty',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Set target price dialog
  // ---------------------------------------------------------------------------

  void _showSetTargetDialog(
    BuildContext context,
    PriceSharkItem item,
    PriceSharkNotifier notifier,
  ) {
    final priceCtrl = TextEditingController(
      text: item.targetPrice > 0 ? item.targetPrice.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          'Vstanovyty tsilovu tsinu',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 16,
          ),
        ),
        content: TextField(
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Skasuvaty',
              style: GoogleFonts.shareTechMono(color: const Color(0xFF8B95A5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B00FF),
            ),
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              if (price > 0) {
                notifier.setTargetPrice(item.id, price);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'Vstanovyty',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add item dialog
  // ---------------------------------------------------------------------------

  void _showAddItemDialog(
    BuildContext context,
    PriceSharkNotifier notifier,
  ) {
    final nameCtrl = TextEditingController();
    final queryCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          'Dodaty tovar',
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
              controller: queryCtrl,
              style: GoogleFonts.shareTechMono(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Poshukovyi zapyt',
                labelStyle: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                ),
                hintText: 'napr. PS5 kupyty Ukraina tsina',
                hintStyle: GoogleFonts.shareTechMono(
                  color: const Color(0xFF4A5568),
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
              style: GoogleFonts.shareTechMono(color: const Color(0xFF8B95A5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B00FF),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final query = queryCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              if (name.isNotEmpty && query.isNotEmpty) {
                notifier.trackItem(PriceSharkItem(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  searchQuery: query,
                  targetPrice: price,
                ));
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
