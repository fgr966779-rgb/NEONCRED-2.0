import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../providers/price_oracle_provider.dart';

// =============================================================================
// Price Oracle Screen — Track real prices for wish-list items
// =============================================================================

class PriceOracleScreen extends ConsumerStatefulWidget {
  const PriceOracleScreen({super.key});

  @override
  ConsumerState<PriceOracleScreen> createState() => _PriceOracleScreenState();
}

class _PriceOracleScreenState extends ConsumerState<PriceOracleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(priceOracleProvider.notifier).loadWatchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceOracleProvider);
    final notifier = ref.read(priceOracleProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          'PRICE ORACLE',
          style: TextStyle(
            color: Color(0xFF00F0FF),
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
            onPressed: state.isRefreshing
                ? null
                : () => notifier.refreshPrices(),
          ),
        ],
      ),
      body: state.isRefreshing
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            )
          : RefreshIndicator(
              color: const Color(0xFF00F0FF),
              backgroundColor: const Color(0xFF0A0E17),
              onRefresh: () => notifier.refreshPrices(),
              child: CustomScrollView(
                slivers: [
                  // Stats header
                  SliverToBoxAdapter(child: _buildStatsCard(state.stats)),

                  // Alerts
                  if (state.alerts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildAlertsSection(state.alerts, notifier),
                    ),

                  // Watch items
                  if (state.watchItems.isEmpty)
                    const SliverToBoxAdapter(
                      child: _EmptyState(
                        icon: Icons.price_check,
                        title: 'Немає відстежуваних товарів',
                        subtitle: 'Додай товар з каталогу або власний запит',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildWatchItemCard(state.watchItems[index], notifier),
                        childCount: state.watchItems.length,
                      ),
                    ),

                  // Predefined catalog
                  SliverToBoxAdapter(child: _buildCatalogSection(notifier)),
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
  // Stats card
  // ---------------------------------------------------------------------------

  Widget _buildStatsCard(PriceOracleStats stats) {
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
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'ORACLE STATS',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                label: 'Товарів',
                value: '${stats.totalItems}',
                color: const Color(0xFF00F0FF),
              ),
              _StatChip(
                label: 'Алергів',
                value: '${stats.activeAlerts}',
                color: const Color(0xFFFF3366),
              ),
              _StatChip(
                label: 'Знижки',
                value: '${stats.priceDropAlertsTriggered}',
                color: const Color(0xFF00FF88),
              ),
              _StatChip(
                label: 'Економія',
                value: '${stats.potentialSavingsUAH.toStringAsFixed(0)}₴',
                color: const Color(0xFF6B00FF),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.totalSavingsProgress,
              backgroundColor: const Color(0xFF1A1F2E),
              color: const Color(0xFF00F0FF),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Загальний прогрес: ${(stats.totalSavingsProgress * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Alerts section
  // ---------------------------------------------------------------------------

  Widget _buildAlertsSection(List<PriceAlert> alerts, PriceOracleNotifier notifier) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'ALERTS',
              style: TextStyle(
                color: Color(0xFFFF3366),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          ...alerts.take(3).map((alert) => Dismissible(
                key: Key(alert.alertId),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => notifier.dismissAlert(alert.alertId),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: const Color(0xFFFF3366),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3366).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF3366).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        alert.type == PriceAlertType.priceDrop
                            ? Icons.trending_down
                            : alert.type == PriceAlertType.targetReached
                                ? Icons.check_circle
                                : Icons.notifications_active,
                        color: alert.type == PriceAlertType.priceDrop
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF3366),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.messageUA,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Watch item card
  // ---------------------------------------------------------------------------

  Widget _buildWatchItemCard(
    PriceWatchItem item,
    PriceOracleNotifier notifier,
  ) {
    final isPriceDrop = item.isPriceDrop;
    final cardBorderColor = isPriceDrop
        ? const Color(0xFF00FF88)
        : const Color(0xFF6B00FF).withValues(alpha: 0.5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + price
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isPriceDrop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.priceChangePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF00FF88),
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
              const Text(
                'Зараз: ',
                style: TextStyle(color: Color(0xFF8B95A5), fontSize: 14),
              ),
              Text(
                '${item.currentPriceUAH.toStringAsFixed(0)}₴',
                style: TextStyle(
                  color: isPriceDrop
                      ? const Color(0xFF00FF88)
                      : const Color(0xFF00F0FF),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (item.previousPriceUAH > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${item.previousPriceUAH.toStringAsFixed(0)}₴',
                  style: const TextStyle(
                    color: Color(0xFF8B95A5),
                    fontSize: 14,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),

          // Target price
          if (item.targetPriceUAH > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Ціль: ',
                  style: TextStyle(color: Color(0xFF8B95A5), fontSize: 13),
                ),
                Text(
                  '${item.targetPriceUAH.toStringAsFixed(0)}₴',
                  style: const TextStyle(
                    color: Color(0xFF6B00FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // Store + last updated
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.storeName.isNotEmpty)
                Text(
                  item.storeName,
                  style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 12),
                ),
              Text(
                'Оновлено: ${_timeAgo(item.lastUpdated)}',
                style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 11),
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
                label: const Text('AI Інсайт'),
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
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 16,
                          ),
                        ),
                        content: Text(
                          insight,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Зрозуміло'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3366), size: 20),
                onPressed: () => notifier.removeWatchItem(item.itemId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Catalog section
  // ---------------------------------------------------------------------------

  Widget _buildCatalogSection(PriceOracleNotifier notifier) {
    final products = notifier.predefinedProducts;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'КАТАЛОГ БАЖАНЬ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
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
              return ActionChip(
                label: Text(
                  p.name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: const Color(0xFF1A1F2E),
                side: const BorderSide(color: Color(0xFF6B00FF), width: 0.5),
                onPressed: () => notifier.addPredefinedItem(p.itemId),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add item dialog
  // ---------------------------------------------------------------------------

  void _showAddItemDialog(BuildContext context, PriceOracleNotifier notifier) {
    final nameCtrl = TextEditingController();
    final queryCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: const Text(
          'Додати товар',
          style: TextStyle(color: Color(0xFF00F0FF)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Назва товару',
                labelStyle: TextStyle(color: Color(0xFF8B95A5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00F0FF)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: queryCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Пошуковий запит',
                labelStyle: TextStyle(color: Color(0xFF8B95A5)),
                hintText: 'напр. PS5 купити Україна ціна',
                hintStyle: TextStyle(color: Color(0xFF4A5568)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00F0FF)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цільова ціна (₴)',
                labelStyle: TextStyle(color: Color(0xFF8B95A5)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00F0FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Скасувати'),
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
                notifier.addWatchItem(PriceWatchItem(
                  itemId: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  query: query,
                  targetPriceUAH: price,
                ));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Додати'),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}хв тому';
    if (diff.inHours < 24) return '${diff.inHours}год тому';
    return '${diff.inDays}д тому';
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 11),
        ),
      ],
    );
  }
}

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
          Icon(icon, size: 64, color: const Color(0xFF6B00FF).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
