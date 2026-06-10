import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/loyalty_cruncher_provider.dart';

// =============================================================================
// Loyalty Price Cruncher Screen -- Cyberpunk themed
// =============================================================================
//
// 2-tab UI: "My Cards" / "Compare Prices"
// Tracks loyalty cards, promo codes, and cashback programs.
// =============================================================================

class LoyaltyCruncherScreen extends ConsumerStatefulWidget {
  const LoyaltyCruncherScreen({super.key});

  @override
  ConsumerState<LoyaltyCruncherScreen> createState() =>
      _LoyaltyCruncherScreenState();
}

class _LoyaltyCruncherScreenState extends ConsumerState<LoyaltyCruncherScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String? _aiSavingsTip;

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final cruncherState = ref.watch(loyaltyCruncherProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'LOYALTY PRICE CRUNCHER',
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _cyan,
          indicatorWeight: 2,
          labelColor: _cyan,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.shareTechMono(fontSize: 12),
          tabs: const [
            Tab(text: 'МОЇ КАРТКИ'),
            Tab(text: 'ПОРІВНЯТИ ЦІНИ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyCardsTab(cruncherState: cruncherState),
          _ComparePricesTab(
            cruncherState: cruncherState,
            searchController: _searchController,
            aiSavingsTip: _aiSavingsTip,
            onSearch: () => _doSearch(),
            onGenerateTip: () => _generateTip(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search handler
  // ---------------------------------------------------------------------------
  void _doSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(loyaltyCruncherProvider.notifier).comparePrices(query);
    }
  }

  // ---------------------------------------------------------------------------
  // Generate AI tip
  // ---------------------------------------------------------------------------
  Future<void> _generateTip() async {
    final tip = await ref
        .read(loyaltyCruncherProvider.notifier)
        .generateSavingsTip();
    if (mounted) {
      setState(() => _aiSavingsTip = tip);
    }
  }

  // ---------------------------------------------------------------------------
  // Add card dialog
  // ---------------------------------------------------------------------------
  void showAddCardDialog() {
    final storeController = TextEditingController();
    final numberController = TextEditingController();
    final cashbackController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.4)),
          ),
          title: Text(
            'ДОДАТИ КАРТКУ',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00F0FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Store name dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: null,
                    isExpanded: true,
                    hint: const Text('Магазин', style: TextStyle(color: Colors.white38)),
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'Rozetka', child: Text('Rozetka')),
                      DropdownMenuItem(value: 'Comfy', child: Text('Comfy')),
                      DropdownMenuItem(value: 'ATB', child: Text('ATB')),
                      DropdownMenuItem(value: 'Silpo', child: Text('Silpo')),
                      DropdownMenuItem(value: 'Allo', child: Text('Allo')),
                      DropdownMenuItem(value: 'MOYO', child: Text('MOYO')),
                      DropdownMenuItem(value: 'Citrus', child: Text('Citrus')),
                      DropdownMenuItem(value: 'custom', child: Text('Iнший...')),
                    ],
                    onChanged: (val) {
                      if (val != null && val != 'custom') {
                        storeController.text = val;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Назва магазину',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Номер картки',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cashbackController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Кешбек %',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: '%',
                  suffixStyle: const TextStyle(color: Color(0xFF00F0FF)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
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
                final store = storeController.text.trim();
                final cashback = double.tryParse(cashbackController.text) ?? 0;
                if (store.isNotEmpty) {
                  ref
                      .read(loyaltyCruncherProvider.notifier)
                      .addCard(store, numberController.text.trim(), cashback);
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: const Color(0xFF0A0E17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Додати'),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Tab 1 -- My Cards
// =============================================================================

class _MyCardsTab extends StatelessWidget {
  final LoyaltyCruncherState cruncherState;

  const _MyCardsTab({required this.cruncherState});

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Total savings counter
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_green.withOpacity(0.12), _card],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.savings, color: _green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ЗАГАЛЬНА ЕКОНОМІЯ',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${cruncherState.totalSavings.toStringAsFixed(0)}₴',
                        style: GoogleFonts.orbitron(
                          color: _green,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Cards list header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'МОЇ КАРТКИ',
                  style: GoogleFonts.orbitron(
                    color: _cyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${cruncherState.cards.length} карток',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Loyalty cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _LoyaltyCardItem(
              card: cruncherState.cards[index],
              onRemove: () {
                ProviderScope.containerOf(context)
                    .read(loyaltyCruncherProvider.notifier)
                    .removeCard(cruncherState.cards[index].id);
              },
            ),
            childCount: cruncherState.cards.length,
          ),
        ),

        // Add card button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _showAddCardDialogFromStateless(context),
                icon: const Icon(Icons.add_circle_outline, color: _cyan),
                label: Text(
                  'ДОДАТИ КАРТКУ',
                  style: GoogleFonts.orbitron(
                    color: _cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _cyan, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Error display
        if (cruncherState.error != null)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _pink.withOpacity(0.3)),
              ),
              child: Text(
                cruncherState.error!,
                style: const TextStyle(color: _pink, fontSize: 13),
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  /// Show add card dialog from StatelessWidget using ProviderScope
  void _showAddCardDialogFromStateless(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    final storeController = TextEditingController();
    final numberController = TextEditingController();
    final cashbackController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.4)),
          ),
          title: Text(
            'ДОДАТИ КАРТКУ',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00F0FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00F0FF).withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: null,
                    isExpanded: true,
                    hint: const Text('Магазин', style: TextStyle(color: Colors.white38)),
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'Rozetka', child: Text('Rozetka')),
                      DropdownMenuItem(value: 'Comfy', child: Text('Comfy')),
                      DropdownMenuItem(value: 'ATB', child: Text('ATB')),
                      DropdownMenuItem(value: 'Silpo', child: Text('Silpo')),
                      DropdownMenuItem(value: 'Allo', child: Text('Allo')),
                      DropdownMenuItem(value: 'MOYO', child: Text('MOYO')),
                      DropdownMenuItem(value: 'Citrus', child: Text('Citrus')),
                      DropdownMenuItem(value: 'custom', child: Text('Iнший...')),
                    ],
                    onChanged: (val) {
                      if (val != null && val != 'custom') {
                        storeController.text = val;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Назва магазину',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Номер картки',
                  hintStyle: const TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cashbackController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Кешбек %',
                  hintStyle: const TextStyle(color: Colors.white38),
                  suffixText: '%',
                  suffixStyle: const TextStyle(color: Color(0xFF00F0FF)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF00F0FF)),
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
                final store = storeController.text.trim();
                final cashback = double.tryParse(cashbackController.text) ?? 0;
                if (store.isNotEmpty) {
                  container.read(loyaltyCruncherProvider.notifier)
                      .addCard(store, numberController.text.trim(), cashback);
                  Navigator.of(dialogContext).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: const Color(0xFF0A0E17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Додати'),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Loyalty card item
// =============================================================================

class _LoyaltyCardItem extends StatelessWidget {
  final LoyaltyCard card;
  final VoidCallback onRemove;

  const _LoyaltyCardItem({
    required this.card,
    required this.onRemove,
  });

  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = _parseColor(card.color);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Store color indicator
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Store info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.storeName,
                  style: GoogleFonts.orbitron(
                    color: brandColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Кешбек: ${card.cashbackPercent.toStringAsFixed(1)}%',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (card.currentPoints > 0)
                      Text(
                        'Бали: ${card.currentPoints.toStringAsFixed(0)}',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            icon: Icon(Icons.close, size: 18, color: brandColor.withOpacity(0.5)),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Tab 2 -- Compare Prices
// =============================================================================

class _ComparePricesTab extends StatelessWidget {
  final LoyaltyCruncherState cruncherState;
  final TextEditingController searchController;
  final String? aiSavingsTip;
  final VoidCallback onSearch;
  final VoidCallback onGenerateTip;

  const _ComparePricesTab({
    required this.cruncherState,
    required this.searchController,
    this.aiSavingsTip,
    required this.onSearch,
    required this.onGenerateTip,
  });

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Пошук товару...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: _cyan),
                      filled: true,
                      fillColor: _card,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cyan, width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => onSearch(),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: cruncherState.isLoading ? null : onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cyan,
                      foregroundColor: _bg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: cruncherState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A0E17),
                            ),
                          )
                        : const Icon(Icons.compare_arrows),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Total savings counter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.savings, color: _green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Економiя: ${cruncherState.totalSavings.toStringAsFixed(0)}₴',
                  style: GoogleFonts.orbitron(
                    color: _green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error display
        if (cruncherState.error != null)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _pink.withOpacity(0.3)),
              ),
              child: Text(
                cruncherState.error!,
                style: const TextStyle(color: _pink, fontSize: 13),
              ),
            ),
          ),

        // Price comparison results
        ...cruncherState.priceComparisons.map(
          (comparison) => SliverToBoxAdapter(
            child: _ComparisonCard(comparison: comparison),
          ),
        ),

        // Available coupons section
        if (cruncherState.priceComparisons.isNotEmpty &&
            cruncherState.priceComparisons.first.availableCoupons.isNotEmpty)
          SliverToBoxAdapter(
            child: _CouponsSection(
              coupons: cruncherState.priceComparisons.first.availableCoupons,
            ),
          ),

        // AI savings tip card
        SliverToBoxAdapter(
          child: _AiSavingsTipCard(
            tip: aiSavingsTip,
            onGenerate: onGenerateTip,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// =============================================================================
// Comparison card showing store prices
// =============================================================================

class _ComparisonCard extends StatelessWidget {
  final EffectivePrice comparison;

  const _ComparisonCard({required this.comparison});

  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Row(
            children: [
              Expanded(
                child: Text(
                  comparison.productName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (comparison.savingsVsHighest > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withOpacity(0.5)),
                  ),
                  child: Text(
                    'ЕКОНОМІЯ ${comparison.savingsVsHighest.toStringAsFixed(0)}₴',
                    style: GoogleFonts.shareTechMono(
                      color: _green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Store price rows
          ...comparison.storePrices.map((sp) {
            final isBest = sp.storeName == comparison.bestStore;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBest ? _green.withOpacity(0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isBest
                    ? Border.all(color: _green.withOpacity(0.4))
                    : Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  // Store name
                  SizedBox(
                    width: 80,
                    child: Row(
                      children: [
                        if (isBest)
                          const Icon(Icons.emoji_events, color: _green, size: 14),
                        if (isBest) const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sp.storeName,
                            style: GoogleFonts.shareTechMono(
                              color: isBest ? _green : Colors.white70,
                              fontSize: 12,
                              fontWeight: isBest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Base price
                  Expanded(
                    child: Text(
                      '${sp.basePrice.toStringAsFixed(0)}₴',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Cashback
                  Expanded(
                    child: Text(
                      sp.cashbackAmount > 0
                          ? '-${sp.cashbackAmount.toStringAsFixed(0)}₴'
                          : '--',
                      style: GoogleFonts.shareTechMono(
                        color: _cyan,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Coupon
                  Expanded(
                    child: Text(
                      sp.couponDiscount > 0
                          ? '-${sp.couponDiscount.toStringAsFixed(0)}₴'
                          : '--',
                      style: GoogleFonts.shareTechMono(
                        color: _pink,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Effective price
                  Expanded(
                    child: Text(
                      '${sp.effectivePrice.toStringAsFixed(0)}₴',
                      style: GoogleFonts.shareTechMono(
                        color: isBest ? _green : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Best deal reason
          if (comparison.bestDealReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Найкраща пропозиція: ${comparison.bestDealReason}',
              style: GoogleFonts.shareTechMono(
                color: _green,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Coupons section
// =============================================================================

class _CouponsSection extends StatelessWidget {
  final List<CouponCode> coupons;

  const _CouponsSection({required this.coupons});

  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _yellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: _yellow, size: 16),
              const SizedBox(width: 8),
              Text(
                'ДОСТУПНІ КУПОНИ',
                style: GoogleFonts.orbitron(
                  color: _yellow,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...coupons.map(
            (coupon) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _yellow.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _yellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _yellow.withOpacity(0.4)),
                    ),
                    child: Text(
                      coupon.code,
                      style: GoogleFonts.shareTechMono(
                        color: _yellow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      coupon.description.isNotEmpty
                          ? coupon.description
                          : '${coupon.store}: -${coupon.discountAmount.toStringAsFixed(0)}₴',
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (coupon.expiryDate.isNotEmpty)
                    Text(
                      coupon.expiryDate,
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// AI Savings Tip card
// =============================================================================

class _AiSavingsTipCard extends StatelessWidget {
  final String? tip;
  final VoidCallback onGenerate;

  const _AiSavingsTipCard({
    this.tip,
    required this.onGenerate,
  });

  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _purple, size: 16),
              const SizedBox(width: 8),
              Text(
                'VAULT-17 ПОРАДА',
                style: GoogleFonts.orbitron(
                  color: _purple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onGenerate,
                child: const Icon(Icons.refresh, color: _purple, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tip != null)
            Text(
              tip!,
              style: GoogleFonts.shareTechMono(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            )
          else
            GestureDetector(
              onTap: onGenerate,
              child: Text(
                'Натиснiть для генерацiї персональної поради з економiї',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
