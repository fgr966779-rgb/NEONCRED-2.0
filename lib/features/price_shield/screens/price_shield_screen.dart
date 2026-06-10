import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/price_shield_provider.dart';

// =============================================================================
// Showroom Price Shield Screen — LTV Phase 2 Feature #8
// =============================================================================
// Cyberpunk-themed UI for scanning in-store prices and finding cheaper online.
// =============================================================================

class PriceShieldScreen extends ConsumerStatefulWidget {
  const PriceShieldScreen({super.key});

  @override
  ConsumerState<PriceShieldScreen> createState() => _PriceShieldScreenState();
}

class _PriceShieldScreenState extends ConsumerState<PriceShieldScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(priceShieldProvider.notifier).loadScans();
    });
  }

  static const _bg = Color(0xFF0A0E17);
  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceShieldProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ЦІНОВИЙ ЩИТ',
          style: GoogleFonts.orbitron(
            color: _cyan,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _green, _cyan, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Total Savings Banner ──────────────────────────────────
          SliverToBoxAdapter(child: _SavingsBanner(state: state)),

          // ── Error Banner ──────────────────────────────────────────
          if (state.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(error: state.error!)),

          // ── Loading ───────────────────────────────────────────────
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: _cyan)),
              ),
            ),

          // ── Scan List ─────────────────────────────────────────────
          if (state.scans.isEmpty && !state.isLoading)
            SliverToBoxAdapter(
              child: _EmptyStateCard(onScan: _showScanDialog),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ScanCard(model: state.scans[index]),
                childCount: state.scans.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScanDialog,
        backgroundColor: _green,
        child: const Icon(Icons.shield_outlined, color: _bg),
      ),
    );
  }

  void _showScanDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final storeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _green, width: 1),
          ),
          title: Text(
            'СКАНУВАТИ ЦІНУ',
            style: GoogleFonts.orbitron(color: _green, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Назва товару',
                  hintStyle: GoogleFonts.shareTechMono(color: Colors.white38),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _green),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ціна в магазині (грн)',
                  hintStyle: GoogleFonts.shareTechMono(color: Colors.white38),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _green),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: storeController,
                style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Назва магазину',
                  hintStyle: GoogleFonts.shareTechMono(color: Colors.white38),
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _green),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _green, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _purple),
                    ),
                    child: Text(
                      '+5 XP',
                      style: GoogleFonts.orbitron(
                        color: _yellow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Скасувати',
                style: GoogleFonts.shareTechMono(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(priceController.text) ?? 0;
                if (nameController.text.trim().isNotEmpty && price > 0) {
                  ref.read(priceShieldProvider.notifier).scanProduct(
                        productName: nameController.text.trim(),
                        inStorePrice: price,
                        inStoreName: storeController.text.trim(),
                      );
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _green),
              child: Text(
                'ПОРУВНЯТИ',
                style: GoogleFonts.orbitron(
                  color: _bg,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _SavingsBanner extends StatelessWidget {
  final PriceShieldState state;
  const _SavingsBanner({required this.state});

  static const _bg = Color(0xFF0A0E17);
  static const _green = Color(0xFF00FF88);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2818), Color(0xFF0A0E17)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'ЗАГАЛЬНА ЕКОНОМІЯ',
            style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.totalSavingsUah} грн',
            style: GoogleFonts.orbitron(
              color: _green,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.totalScans} сканувань',
                style: GoogleFonts.shareTechMono(color: _cyan, fontSize: 11),
              ),
              const SizedBox(width: 16),
              Text(
                '${state.priceMatchOpportunities} можливостей',
                style: GoogleFonts.shareTechMono(color: _green, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3366).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF3366)),
      ),
      child: Text(
        error,
        style: GoogleFonts.shareTechMono(color: const Color(0xFFFF3366), fontSize: 12),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyStateCard({required this.onScan});

  static const _green = Color(0xFF00FF88);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'ЦІНОВИЙ ЩИТ',
            style: GoogleFonts.orbitron(color: _green, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Скануйте ціну в магазині — ми знайдемо найдешевшу онлайн-ціну і допоможемо отримати знижку через price match',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text('СКАНУВАТИ', style: GoogleFonts.orbitron(fontSize: 12)),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
          ),
        ],
      ),
    );
  }
}

class _ScanCard extends ConsumerWidget {
  final PriceShieldScanModel model;
  const _ScanCard({required this.model});

  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSavings = model.hasSavings;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSavings ? _green.withOpacity(0.3) : _pink.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product Name ────────────────────────────────────────
          Text(
            model.data.productName,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // ── Price Comparison ────────────────────────────────────
          Row(
            children: [
              // In-store price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'В МАГАЗИНІ',
                    style: GoogleFonts.shareTechMono(color: _pink, fontSize: 9),
                  ),
                  Text(
                    '${model.data.inStorePrice.toStringAsFixed(0)} грн',
                    style: GoogleFonts.orbitron(
                      color: _pink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),

              // Online best price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ОНЛАЙН НАЙДЕШЕВШЕ',
                    style: GoogleFonts.shareTechMono(color: _green, fontSize: 9),
                  ),
                  Text(
                    model.data.bestOnlinePrice > 0
                        ? '${model.data.bestOnlinePrice.toStringAsFixed(0)} грн'
                        : '-- грн',
                    style: GoogleFonts.orbitron(
                      color: model.data.bestOnlinePrice > 0 ? _green : Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Savings Badge ──────────────────────────────────────
          if (hasSavings) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings, color: _green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ЕКОНОМІЯ: ${model.savingsAmount.toStringAsFixed(0)} грн (${model.savingsPercentStr})',
                    style: GoogleFonts.orbitron(
                      color: _green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (model.data.bestOnlineStore.isNotEmpty)
                    Flexible(
                      child: Text(
                        model.data.bestOnlineStore,
                        style: GoogleFonts.shareTechMono(color: _cyan, fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // Price Match button
            if (!model.data.priceMatchUsed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(priceShieldProvider.notifier)
                        .markPriceMatchUsed(model.data.id),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      'ВИКОРИСТАНО PRICE MATCH (+10 XP)',
                      style: GoogleFonts.orbitron(fontSize: 9, color: _yellow),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _yellow),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
          ],

          // ── Actions ────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (model.data.priceMatchUsed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PRICE MATCH',
                    style: GoogleFonts.shareTechMono(color: _green, fontSize: 9),
                  ),
                ),
              const Spacer(),
              IconButton(
                onPressed: () => ref
                    .read(priceShieldProvider.notifier)
                    .deleteScan(model.data.id),
                icon: const Icon(Icons.delete_outline, color: _pink, size: 20),
                tooltip: 'Видалити',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
