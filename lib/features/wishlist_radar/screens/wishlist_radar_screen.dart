import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/wishlist_radar_service.dart';

// =========================================================================
// WishlistRadarScreen -- WISH-LIST PRICE RADAR dashboard
// =========================================================================

class WishlistRadarScreen extends ConsumerStatefulWidget {
  const WishlistRadarScreen({super.key});

  @override
  ConsumerState<WishlistRadarScreen> createState() =>
      _WishlistRadarScreenState();
}

class _WishlistRadarScreenState extends ConsumerState<WishlistRadarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(wishlistRadarProvider);
      if (state.wishItems.isEmpty) {
        ref.read(wishlistRadarProvider.notifier).scanAllPrices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistRadarProvider);
    final notifier = ref.read(wishlistRadarProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(
          'WISH-LIST PRICE RADAR',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () => _showAddWishDialog(context, notifier),
            tooltip: 'Додати товар',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF0D1117),
        onRefresh: () => notifier.scanAllPrices(),
        child: CustomScrollView(
          slivers: [
            // Total potential savings banner
            SliverToBoxAdapter(
              child: _SavingsBanner(totalSavings: state.totalPotentialSavings),
            ),

            // Loading indicator
            if (state.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00F0FF),
                    ),
                  ),
                ),
              ),

            // Error banner
            if (state.error != null)
              SliverToBoxAdapter(
                child: _ErrorBanner(error: state.error!),
              ),

            // Scan All Prices button
            SliverToBoxAdapter(
              child: _ScanAllButton(
                isLoading: state.isLoading,
                onScan: () => notifier.scanAllPrices(),
              ),
            ),

            // Wish item cards
            if (state.wishItems.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _WishItemCard(
                    item: state.wishItems[index],
                    onForecast: (item) => notifier.generateForecast(item),
                    onRemove: (id) => notifier.removeWishItem(id),
                    onUrgencyChange: (id, urgency) =>
                        notifier.setUrgency(id, urgency),
                  ),
                  childCount: state.wishItems.length,
                ),
              )
            else if (!state.isLoading)
              const SliverToBoxAdapter(child: _EmptyStateCard()),

            // Weekly Buy Guide section
            if (state.weeklyGuide != null)
              SliverToBoxAdapter(
                child: _WeeklyBuyGuideCard(guide: state.weeklyGuide!),
              ),

            // Generate Weekly Guide button
            SliverToBoxAdapter(
              child: _GenerateGuideButton(
                onGenerate: () => notifier.generateWeeklyGuide(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add wish item dialog
  // ---------------------------------------------------------------------------

  void _showAddWishDialog(
    BuildContext context,
    WishlistRadarNotifier notifier,
  ) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFF00F0FF),
              width: 1,
            ),
          ),
          title: Text(
            'НОВИЙ ТОВАР У РАДАР',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00F0FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFE0E0FF),
                ),
                decoration: InputDecoration(
                  labelText: 'Назва товару',
                  labelStyle: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8888AA),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF333355)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFE0E0FF),
                ),
                decoration: InputDecoration(
                  labelText: 'Очікувана ціна (грн)',
                  labelStyle: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8888AA),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF333355)),
                  ),
                  focusedBorder: const OutlineInputBorder(
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
                'Скасувати',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8888AA),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price =
                    double.tryParse(priceController.text.trim()) ?? 0.0;
                if (name.isNotEmpty && price > 0) {
                  notifier.addWishItem(name, price);
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF).withOpacity(0.2),
                foregroundColor: const Color(0xFF00F0FF),
                side: const BorderSide(color: Color(0xFF00F0FF)),
              ),
              child: Text(
                'Додати',
                style: GoogleFonts.shareTechMono(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =========================================================================
// Savings banner
// =========================================================================

class _SavingsBanner extends StatelessWidget {
  final double totalSavings;

  const _SavingsBanner({required this.totalSavings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF88).withOpacity(0.15),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings, color: Color(0xFF00FF88), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ПОТЕНЦІЙНА ЕКОНОМІЯ',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF00FF88),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalSavings.toStringAsFixed(0)} грн',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFE0E0FF),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Error banner
// =========================================================================

class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF3366).withOpacity(0.3),
        ),
      ),
      child: Text(
        error,
        style: GoogleFonts.shareTechMono(
          color: const Color(0xFFFF3366),
          fontSize: 13,
        ),
      ),
    );
  }
}

// =========================================================================
// Scan All button
// =========================================================================

class _ScanAllButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onScan;

  const _ScanAllButton({
    required this.isLoading,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onScan,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00F0FF),
                  ),
                )
              : const Icon(Icons.radar, color: Color(0xFF00F0FF)),
          label: Text(
            'СКАНУВАТИ ВСІ ЦІНИ',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00F0FF),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF).withOpacity(0.1),
            side: const BorderSide(color: Color(0xFF00F0FF)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Wish item card
// =========================================================================

class _WishItemCard extends StatefulWidget {
  final RadarWishItem item;
  final Future<void> Function(RadarWishItem) onForecast;
  final void Function(String) onRemove;
  final void Function(String, UrgencyLevel) onUrgencyChange;

  const _WishItemCard({
    required this.item,
    required this.onForecast,
    required this.onRemove,
    required this.onUrgencyChange,
  });

  @override
  State<_WishItemCard> createState() => _WishItemCardState();
}

class _WishItemCardState extends State<_WishItemCard> {
  bool _expanded = false;
  bool _forecastLoading = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final urgencyColor = _urgencyColor(item.urgency);
    final change7dColor = item.priceChange7d < 0
        ? const Color(0xFF00FF88)
        : item.priceChange7d > 0
            ? const Color(0xFFFF3366)
            : const Color(0xFF8888AA);
    final change30dColor = item.priceChange30d < 0
        ? const Color(0xFF00FF88)
        : item.priceChange30d > 0
            ? const Color(0xFFFF3366)
            : const Color(0xFF8888AA);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgencyColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + Urgency badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFFE0E0FF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _UrgencyBadge(urgency: item.urgency),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Current price
                  Row(
                    children: [
                      Text(
                        '${item.currentPrice.toStringAsFixed(0)} грн',
                        style: GoogleFonts.orbitron(
                          color: const Color(0xFF00F0FF),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // 7d change
                      _ChangeIndicator(
                        label: '7д',
                        change: item.priceChange7d,
                        color: change7dColor,
                      ),
                      const SizedBox(width: 12),
                      // 30d change
                      _ChangeIndicator(
                        label: '30д',
                        change: item.priceChange30d,
                        color: change30dColor,
                      ),
                    ],
                  ),

                  // AI forecast summary
                  if (item.forecastReasoning.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B00FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6B00FF).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.aiForecast == 'down'
                                ? Icons.trending_down
                                : item.aiForecast == 'up'
                                    ? Icons.trending_up
                                    : Icons.trending_flat,
                            color: item.aiForecast == 'down'
                                ? const Color(0xFF00FF88)
                                : item.aiForecast == 'up'
                                    ? const Color(0xFFFF3366)
                                    : const Color(0xFFFFD700),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.forecastReasoning,
                              style: GoogleFonts.shareTechMono(
                                color: const Color(0xFFB088FF),
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Expand indicator
                  Align(
                    alignment: Alignment.center,
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF8888AA),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          if (_expanded) ...[
            const Divider(
              color: Color(0xFF333355),
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Best store
                  _DetailRow(
                    label: 'Кращий магазин',
                    value: item.bestStore.isNotEmpty
                        ? item.bestStore
                        : 'Не знайдено',
                    valueColor: item.bestStore.isNotEmpty
                        ? const Color(0xFF00FF88)
                        : const Color(0xFF8888AA),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Ціна в магазині',
                    value:
                        '${item.bestStorePrice.toStringAsFixed(0)} грн',
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Найнижча ціна',
                    value:
                        '${item.lowestPrice.toStringAsFixed(0)} грн',
                    valueColor: const Color(0xFF00FF88),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Найвища ціна',
                    value:
                        '${item.highestPrice.toStringAsFixed(0)} грн',
                    valueColor: const Color(0xFFFF3366),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Зекономлено',
                    value: '${item.totalSaved.toStringAsFixed(0)} грн',
                    valueColor: const Color(0xFF00FF88),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Останнє сканування',
                    value: _formatScannedDate(item.lastScanned),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'AI прогноз',
                    value: _forecastLabel(item.aiForecast),
                    valueColor: item.aiForecast == 'down'
                        ? const Color(0xFF00FF88)
                        : item.aiForecast == 'up'
                            ? const Color(0xFFFF3366)
                            : const Color(0xFFFFD700),
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    label: 'Впевненість AI',
                    value:
                        '${item.forecastConfidence.toStringAsFixed(0)}%',
                  ),

                  const SizedBox(height: 16),

                  // Urgency selector
                  Text(
                    'ТЕРМІНОВІСТЬ',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF8888AA),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: UrgencyLevel.values.map((u) {
                      final selected = item.urgency == u;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            u.labelUA,
                            style: GoogleFonts.shareTechMono(
                              color: selected
                                  ? _urgencyColor(u)
                                  : const Color(0xFF8888AA),
                              fontSize: 11,
                            ),
                          ),
                          selected: selected,
                          onSelected: (_) =>
                              widget.onUrgencyChange(item.id, u),
                          backgroundColor: const Color(0xFF0D1117),
                          selectedColor:
                              _urgencyColor(u).withOpacity(0.2),
                          side: BorderSide(
                            color: selected
                                ? _urgencyColor(u)
                                : const Color(0xFF333355),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _forecastLoading
                              ? null
                              : () async {
                                  setState(
                                      () => _forecastLoading = true);
                                  await widget.onForecast(item);
                                  if (mounted) {
                                    setState(() =>
                                        _forecastLoading = false);
                                  }
                                },
                          icon: _forecastLoading
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child:
                                      CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF6B00FF),
                                      ),
                                )
                              : const Icon(Icons.auto_fix_high,
                                  color: Color(0xFF6B00FF),
                                  size: 16),
                          label: Text(
                            'ПРОГНОЗ AI',
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFF6B00FF),
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFF6B00FF)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              widget.onRemove(item.id),
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFFF3366), size: 16),
                          label: Text(
                            'ВИДАЛИТИ',
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFFFF3366),
                              fontSize: 11,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFFF3366)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _urgencyColor(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.buy_now:
        return const Color(0xFF00FF88);
      case UrgencyLevel.soon:
        return const Color(0xFFFFD700);
      case UrgencyLevel.can_wait:
        return const Color(0xFF8888AA);
    }
  }

  String _formatScannedDate(String isoDate) {
    if (isoDate.isEmpty) return 'Ніколи';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  String _forecastLabel(String forecast) {
    switch (forecast) {
      case 'up':
        return 'Зростання';
      case 'down':
        return 'Падіння';
      case 'stable':
        return 'Стабільно';
      default:
        return forecast;
    }
  }
}

// =========================================================================
// Urgency badge
// =========================================================================

class _UrgencyBadge extends StatelessWidget {
  final UrgencyLevel urgency;

  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final color = urgency == UrgencyLevel.buy_now
        ? const Color(0xFF00FF88)
        : urgency == UrgencyLevel.soon
            ? const Color(0xFFFFD700)
            : const Color(0xFF8888AA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        urgency.labelUA.toUpperCase(),
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =========================================================================
// Price change indicator
// =========================================================================

class _ChangeIndicator extends StatelessWidget {
  final String label;
  final double change;
  final Color color;

  const _ChangeIndicator({
    required this.label,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final arrow = change < 0
        ? Icons.arrow_downward
        : change > 0
            ? Icons.arrow_upward
            : Icons.remove;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF8888AA),
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 2),
        Icon(arrow, color: color, size: 12),
        const SizedBox(width: 2),
        Text(
          '${change.abs().toStringAsFixed(1)}%',
          style: GoogleFonts.shareTechMono(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// Detail row
// =========================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFFE0E0FF),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF8888AA),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.shareTechMono(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// Weekly Buy Guide card
// =========================================================================

class _WeeklyBuyGuideCard extends StatelessWidget {
  final WeeklyBuyGuide guide;

  const _WeeklyBuyGuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  color: Color(0xFFFFD700), size: 18),
              const SizedBox(width: 8),
              Text(
                'ТИЖНЕВИЙ ГАЙД ПОКУПОК',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFFD700),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            guide.weekLabel,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF8888AA),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // AI Summary
          if (guide.aiSummary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF6B00FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6B00FF).withOpacity(0.3),
                ),
              ),
              child: Text(
                guide.aiSummary,
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFB088FF),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recommendations
          ...guide.recommendations.map((rec) {
            final urgencyColor = rec.urgency == UrgencyLevel.buy_now
                ? const Color(0xFF00FF88)
                : rec.urgency == UrgencyLevel.soon
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF8888AA);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: urgencyColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.itemName,
                            style: GoogleFonts.orbitron(
                              color: const Color(0xFFE0E0FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec.reason,
                            style: GoogleFonts.shareTechMono(
                              color: const Color(0xFF8888AA),
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${rec.currentPrice.toStringAsFixed(0)} грн',
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFF00F0FF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (rec.savingsVsAvg > 0)
                          Text(
                            '-${rec.savingsVsAvg.toStringAsFixed(0)} грн',
                            style: GoogleFonts.shareTechMono(
                              color: const Color(0xFF00FF88),
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =========================================================================
// Generate Guide button
// =========================================================================

class _GenerateGuideButton extends StatelessWidget {
  final VoidCallback onGenerate;

  const _GenerateGuideButton({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.auto_awesome,
              color: Color(0xFFFFD700), size: 18),
          label: Text(
            'ЗГЕНЕРУВАТИ ТИЖНЕВИЙ ГАЙД',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFFFD700),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFFD700)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Empty state
// =========================================================================

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.radar, color: Color(0xFF6B00FF), size: 48),
          const SizedBox(height: 16),
          Text(
            'Радар сканує горизонти...',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF8888AA),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Додай товари у вішлист, щоб VAULT-17 почав відстежувати ціни. '
            'Натисни кнопку + у верхньому правому куті.',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF666688),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
