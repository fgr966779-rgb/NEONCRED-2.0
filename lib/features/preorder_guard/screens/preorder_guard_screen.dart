import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/preorder_guard_provider.dart';

// =============================================================================
// Pre-Order Price Guard Screen -- Cyberpunk themed
// =============================================================================
//
// Tracks upcoming product pre-orders, displays depreciation curves,
// and provides buy/wait recommendations powered by AI.
// =============================================================================

class PreOrderGuardScreen extends ConsumerStatefulWidget {
  const PreOrderGuardScreen({super.key});

  @override
  ConsumerState<PreOrderGuardScreen> createState() =>
      _PreOrderGuardScreenState();
}

class _PreOrderGuardScreenState extends ConsumerState<PreOrderGuardScreen> {
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
  static const _orange = Color(0xFFFF8800);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Could load persisted guards here
    });
  }

  // ---------------------------------------------------------------------------
  // Recommendation badge color
  // ---------------------------------------------------------------------------
  Color _recommendationColor(GuardRecommendation rec) {
    switch (rec) {
      case GuardRecommendation.buy_now:
        return _green;
      case GuardRecommendation.wait_1m:
        return _yellow;
      case GuardRecommendation.wait_3m:
        return _orange;
      case GuardRecommendation.wait_6m:
        return _pink;
    }
  }

  String _recommendationText(GuardRecommendation rec) {
    switch (rec) {
      case GuardRecommendation.buy_now:
        return 'КУПУЙ ЗАРАЗ';
      case GuardRecommendation.wait_1m:
        return 'ПОЧЕКАЙ 1 МІС';
      case GuardRecommendation.wait_3m:
        return 'ПОЧЕКАЙ 3 МІС';
      case GuardRecommendation.wait_6m:
        return 'ПОЧЕКАЙ 6 МІС';
    }
  }

  String _fmtMoney(double v) => '${v.toStringAsFixed(0)}₴';

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final guardState = ref.watch(preOrderGuardProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          'PRE-ORDER PRICE GUARD',
          style: GoogleFonts.orbitron(
            color: _cyan,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _cyan),
            onPressed: () => _showAddGuardDialog(),
          ),
        ],
      ),
      body: guardState.isLoading && guardState.guards.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: _cyan),
            )
          : RefreshIndicator(
              color: _cyan,
              backgroundColor: _card,
              onRefresh: () async {
                // Refresh all guards
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Error display
                  if (guardState.error != null)
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
                          guardState.error!,
                          style: const TextStyle(color: _pink, fontSize: 13),
                        ),
                      ),
                    ),

                  // Potential savings banner
                  SliverToBoxAdapter(
                    child: _PotentialSavingsBanner(
                      totalSavings: guardState.totalPotentialSavings,
                    ),
                  ),

                  // Predefined catalog section
                  SliverToBoxAdapter(
                    child: _UpcomingCatalogSection(
                      onAdd: (name, price, category) {
                        ref
                            .read(preOrderGuardProvider.notifier)
                            .addGuard(name, price, category);
                      },
                    ),
                  ),

                  // Guard list header
                  if (guardState.guards.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'ВASH СТИЖЕННЯ',
                          style: GoogleFonts.orbitron(
                            color: _purple,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),

                  // Guard cards
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _GuardCard(
                        guard: guardState.guards[index],
                        recommendationColor: _recommendationColor,
                        recommendationText: _recommendationText,
                        onRefresh: () => ref
                            .read(preOrderGuardProvider.notifier)
                            .refreshGuard(guardState.guards[index].id),
                        onRemove: () => ref
                            .read(preOrderGuardProvider.notifier)
                            .removeGuard(guardState.guards[index].id),
                      ),
                      childCount: guardState.guards.length,
                    ),
                  ),

                  // Empty state
                  if (guardState.guards.isEmpty)
                    SliverToBoxAdapter(
                      child: _EmptyGuardState(
                        onAdd: () => _showAddGuardDialog(),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add guard dialog
  // ---------------------------------------------------------------------------
  void _showAddGuardDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedCategory = 'phone';

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: _cyan.withOpacity(0.4)),
              ),
              title: Text(
                'ДОДАТИ GUARD',
                style: GoogleFonts.orbitron(
                  color: _cyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Назва продукту',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Цiна передзамовлення (грн)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      suffixText: '₴',
                      suffixStyle: const TextStyle(color: _cyan),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _cyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cyan.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF111827),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 'phone', child: Text('Смартфон')),
                          DropdownMenuItem(value: 'console', child: Text('Консоль')),
                          DropdownMenuItem(value: 'laptop', child: Text('Ноутбук')),
                          DropdownMenuItem(value: 'gpu', child: Text('Вiдеокарта')),
                          DropdownMenuItem(value: 'gadget', child: Text('Гаджет')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCategory = val);
                          }
                        },
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
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text) ?? 0;
                    if (name.isNotEmpty && price > 0) {
                      Navigator.of(dialogContext).pop();
                      ref
                          .read(preOrderGuardProvider.notifier)
                          .addGuard(name, price, selectedCategory);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _bg,
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
      },
    );
  }
}

// =============================================================================
// HELPER WIDGETS
// =============================================================================

/// Potential savings banner at the top.
class _PotentialSavingsBanner extends StatelessWidget {
  final double totalSavings;

  const _PotentialSavingsBanner({required this.totalSavings});

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green.withOpacity(0.15), _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'ПОТЕНЦІЙНА ЕКОНОМІЯ',
            style: GoogleFonts.orbitron(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${totalSavings.toStringAsFixed(0)}₴',
            style: GoogleFonts.orbitron(
              color: _green,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(color: _green.withOpacity(0.4), blurRadius: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Якщо зачекаєте замість передзамовлення',
            style: GoogleFonts.shareTechMono(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Upcoming launches catalog section.
class _UpcomingCatalogSection extends StatelessWidget {
  final void Function(String name, double price, String category) onAdd;

  const _UpcomingCatalogSection({required this.onAdd});

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);

  static const _catalog = [
    {'name': 'iPhone 17', 'category': 'phone', 'launchPrice': 44999.0},
    {'name': 'PS5 Pro', 'category': 'console', 'launchPrice': 24999.0},
    {'name': 'Galaxy S25', 'category': 'phone', 'launchPrice': 39999.0},
    {'name': 'MacBook Pro M4', 'category': 'laptop', 'launchPrice': 74999.0},
    {'name': 'Nintendo Switch 2', 'category': 'console', 'launchPrice': 16999.0},
  ];

  String _categoryIcon(String cat) {
    switch (cat) {
      case 'phone':
        return '[PH]';
      case 'console':
        return '[CS]';
      case 'laptop':
        return '[LT]';
      case 'gpu':
        return '[GPU]';
      default:
        return '[GD]';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'ОЧІКУВАНІ РЕЛІЗИ',
            style: GoogleFonts.orbitron(
              color: _purple,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _catalog.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = _catalog[index];
              return GestureDetector(
                onTap: () => onAdd(
                  item['name'] as String,
                  item['launchPrice'] as double,
                  item['category'] as String,
                ),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _cyan.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _categoryIcon(item['category'] as String),
                        style: GoogleFonts.shareTechMono(
                          color: _cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['name'] as String,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        '${(item['launchPrice'] as double).toStringAsFixed(0)}₴',
                        style: GoogleFonts.orbitron(
                          color: _cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual guard card with depreciation curve and AI analysis.
class _GuardCard extends StatelessWidget {
  final PreOrderGuard guard;
  final Color Function(GuardRecommendation) recommendationColor;
  final String Function(GuardRecommendation) recommendationText;
  final VoidCallback onRefresh;
  final VoidCallback onRemove;

  const _GuardCard({
    required this.guard,
    required this.recommendationColor,
    required this.recommendationText,
    required this.onRefresh,
    required this.onRemove,
  });

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);

  @override
  Widget build(BuildContext context) {
    final recColor = recommendationColor(guard.recommendation);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: name + recommendation badge
          Row(
            children: [
              Expanded(
                child: Text(
                  guard.productName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: recColor.withOpacity(0.5)),
                ),
                child: Text(
                  recommendationText(guard.recommendation),
                  style: GoogleFonts.shareTechMono(
                    color: recColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Price row
          Row(
            children: [
              _PriceColumn(
                label: 'ПРЕДЗАМ.',
                value: '${guard.launchPrice.toStringAsFixed(0)}₴',
                color: _cyan,
              ),
              const SizedBox(width: 16),
              _PriceColumn(
                label: 'ЗАРАЗ',
                value: guard.currentPrice > 0
                    ? '${guard.currentPrice.toStringAsFixed(0)}₴'
                    : '--₴',
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              _PriceColumn(
                label: 'ЧЕРЕЗ 6М',
                value: '${guard.predictedPrice6m.toStringAsFixed(0)}₴',
                color: _green,
              ),
              const SizedBox(width: 16),
              _PriceColumn(
                label: 'ЗНЕЦ.',
                value:
                    '-${guard.predictedDropPercent.toStringAsFixed(1)}%',
                color: _pink,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Depreciation curve visualization (bar chart style)
          if (guard.depreciationCurve.isNotEmpty) ...[
            Text(
              'КРИВА ЗНЕЦІНЕННЯ',
              style: GoogleFonts.shareTechMono(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            _DepreciationChart(curve: guard.depreciationCurve),
            const SizedBox(height: 12),
          ],

          // AI Analysis section
          if (guard.aiAnalysis.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _cyan.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: _cyan, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'VAULT-17 АНАЛІЗ',
                        style: GoogleFonts.shareTechMono(
                          color: _cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    guard.aiAnalysis,
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 16, color: _cyan),
                label: Text(
                  'Оновити',
                  style: GoogleFonts.shareTechMono(
                    color: _cyan,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, size: 16, color: _pink.withOpacity(0.7)),
                label: Text(
                  'Видалити',
                  style: GoogleFonts.shareTechMono(
                    color: _pink.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small price column widget.
class _PriceColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.shareTechMono(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple bar chart for depreciation curve.
class _DepreciationChart extends StatelessWidget {
  final List<DepreciationPoint> curve;

  const _DepreciationChart({required this.curve});

  static const _cyan = Color(0xFF00F0FF);
  static const _pink = Color(0xFFFF3366);

  @override
  Widget build(BuildContext context) {
    if (curve.isEmpty) return const SizedBox.shrink();

    final maxPrice = curve
        .map((p) => p.expectedPrice)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: curve.map((point) {
          final height = maxPrice > 0
              ? (point.expectedPrice / maxPrice * 50).clamp(5.0, 50.0)
              : 5.0;
          final dropIntensity = point.dropPercent / 50;
          final color = Color.lerp(_cyan, _pink, dropIntensity) ?? _cyan;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${point.monthsAfterLaunch}м',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white38,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Empty state when no guards are added.
class _EmptyGuardState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGuardState({required this.onAdd});

  static const _card = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cyan.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined, color: _cyan, size: 48),
            const SizedBox(height: 16),
            Text(
              'НІЯКИХ GUARDS НЕ ДОДАНО',
              style: GoogleFonts.orbitron(
                color: _cyan,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Додайте продукти з передзамовлень, щоб відстежувати знецінення',
              style: GoogleFonts.shareTechMono(
                color: Colors.white54,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: const Color(0xFF0A0E17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ДОДАТИ GUARD',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
