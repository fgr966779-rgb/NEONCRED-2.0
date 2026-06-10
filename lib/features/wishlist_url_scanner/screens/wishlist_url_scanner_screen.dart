import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/wishlist_url_scanner_provider.dart';

// =============================================================================
// Wishlist URL Scanner Screen — LTV Phase 2 Feature #1
// =============================================================================
// Cyberpunk-themed UI for scanning product URLs from Ukrainian stores.
// =============================================================================

class WishlistUrlScannerScreen extends ConsumerStatefulWidget {
  const WishlistUrlScannerScreen({super.key});

  @override
  ConsumerState<WishlistUrlScannerScreen> createState() =>
      _WishlistUrlScannerScreenState();
}

class _WishlistUrlScannerScreenState
    extends ConsumerState<WishlistUrlScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistUrlScannerProvider.notifier).loadUrls();
    });
  }

  // Cyberpunk color palette
  static const _bg = Color(0xFF0A0E17);
  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wishlistUrlScannerProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'СКАНЕР ПОСИЛАНЬ',
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
                colors: [Colors.transparent, _cyan, _purple, Colors.transparent],
              ),
            ),
          ),
        ),
        actions: [
          if (state.urlsNeedingRescan > 0)
            IconButton(
              onPressed: state.isLoading
                  ? null
                  : () => ref
                      .read(wishlistUrlScannerProvider.notifier)
                      .rescanOutdated(),
              icon: const Icon(Icons.sync, color: _yellow),
              tooltip: 'Пересканувати застарілі (${state.urlsNeedingRescan})',
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── SerpAPI Rate Limit Bar ────────────────────────────────────
          SliverToBoxAdapter(child: _RateLimitBar(state: state)),

          // ── Error Banner ──────────────────────────────────────────────
          if (state.error != null)
            SliverToBoxAdapter(child: _ErrorBanner(error: state.error!)),

          // ── Loading Indicator ─────────────────────────────────────────
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: _cyan),
                ),
              ),
            ),

          // ── Stats Summary ─────────────────────────────────────────────
          SliverToBoxAdapter(child: _StatsBar(state: state)),

          // ── URL List ──────────────────────────────────────────────────
          if (state.urls.isEmpty && !state.isLoading)
            SliverToBoxAdapter(
              child: _EmptyStateCard(onScan: _showScanDialog),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _UrlCard(model: state.urls[index]),
                childCount: state.urls.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScanDialog,
        backgroundColor: _purple,
        child: const Icon(Icons.link, color: Colors.white),
      ),
    );
  }

  void _showScanDialog() {
    final urlController = TextEditingController();
    int? selectedGoalId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _cyan, width: 1),
              ),
              title: Text(
                'ДОДАТИ ПОСИЛАННЯ',
                style: GoogleFonts.orbitron(color: _cyan, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'https://rozetka.com.ua/...',
                      hintStyle: GoogleFonts.shareTechMono(color: Colors.white38),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _cyan),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _cyan, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Goal>>(
                    future: ref.read(databaseProvider).getAllGoals(),
                    builder: (ctx, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text(
                          'Немає цілей — створіть спочатку ціль',
                          style: GoogleFonts.shareTechMono(
                            color: _pink,
                            fontSize: 12,
                          ),
                        );
                      }
                      final goals = snapshot.data!;
                      return DropdownButtonFormField<int>(
                        value: selectedGoalId,
                        dropdownColor: _cardBg,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Ціль',
                          labelStyle: GoogleFonts.shareTechMono(color: _cyan),
                          filled: true,
                          fillColor: _bg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _cyan),
                          ),
                        ),
                        items: goals
                            .map((g) => DropdownMenuItem(
                                  value: g.id,
                                  child: Text(g.name),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedGoalId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _purple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _purple),
                        ),
                        child: Text(
                          '+3 XP',
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
                    if (urlController.text.trim().isNotEmpty &&
                        selectedGoalId != null) {
                      ref
                          .read(wishlistUrlScannerProvider.notifier)
                          .scanUrl(urlController.text.trim(), selectedGoalId!);
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _cyan),
                  child: Text(
                    'СКАНУВАТИ',
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
      },
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _RateLimitBar extends StatelessWidget {
  final WishlistUrlScannerState state;
  const _RateLimitBar({required this.state});

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    final used = state.serpApiCallsThisMonth;
    final total = 100;
    final remaining = 95 - used;
    final percent = used / total;

    final barColor = remaining > 50
        ? const Color(0xFF00FF88)
        : remaining > 20
            ? const Color(0xFFFFD700)
            : const Color(0xFFFF3366);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SERPAPI ЗАПИТИ',
                style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 10),
              ),
              Text(
                '$used/100',
                style: GoogleFonts.shareTechMono(color: barColor, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: _bg,
              color: barColor,
              minHeight: 4,
            ),
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

class _StatsBar extends StatelessWidget {
  final WishlistUrlScannerState state;
  const _StatsBar({required this.state});

  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _yellow = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatChip(label: 'ПОСИЛАННЯ', value: '${state.totalUrls}', color: _cyan),
          const SizedBox(width: 12),
          _StatChip(
            label: 'ПОТРІБНО ПЕРЕВІРКА',
            value: '${state.urlsNeedingRescan}',
            color: state.urlsNeedingRescan > 0 ? _yellow : _green,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.orbitron(color: color, fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyStateCard({required this.onScan});

  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.link_off, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'НЕМАЕ ПОСИЛАНЬ',
            style: GoogleFonts.orbitron(color: _cyan, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Вставте посилання на товар з Rozetka, Comfy, Allo або Click — система автоматично витягне назву, ціну та магазин',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.add_link),
            label: Text(
              'ДОДАТИ ПОСИЛАННЯ',
              style: GoogleFonts.orbitron(fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: _cyan),
          ),
        ],
      ),
    );
  }
}

class _UrlCard extends ConsumerWidget {
  final WishlistUrlModel model;
  const _UrlCard({required this.model});

  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _yellow = Color(0xFFFFD700);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = model.store;
    final storeColor = store != null ? _parseColor(store.color) : _cyan;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: storeColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: storeColor.withOpacity(0.05),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Store badge + Goal name ───────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: storeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: storeColor.withOpacity(0.4)),
                ),
                child: Text(
                  store?.name ?? 'НЕВІДОМИЙ',
                  style: GoogleFonts.orbitron(
                    color: storeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (model.needsRescan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _yellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'ЗАСТАРІЛО',
                    style: GoogleFonts.shareTechMono(color: _yellow, fontSize: 9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Product Name ──────────────────────────────────────────
          Text(
            model.data.productName.isNotEmpty
                ? model.data.productName
                : 'Назва не розпізнана',
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // ── Price + Goal ──────────────────────────────────────────
          Row(
            children: [
              Text(
                model.data.extractedPrice > 0
                    ? '${model.data.extractedPrice.toStringAsFixed(0)} грн'
                    : '-- грн',
                style: GoogleFonts.orbitron(
                  color: model.data.extractedPrice > 0 ? _green : Colors.white38,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (model.goalName.isNotEmpty)
                Text(
                  model.goalName,
                  style: GoogleFonts.shareTechMono(
                    color: _purple,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── URL (truncated) ──────────────────────────────────────
          Text(
            model.data.url.length > 60
                ? '${model.data.url.substring(0, 60)}...'
                : model.data.url,
            style: GoogleFonts.shareTechMono(color: Colors.white24, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // ── Actions ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => ref
                    .read(wishlistUrlScannerProvider.notifier)
                    .deleteUrl(model.data.id),
                icon: const Icon(Icons.delete_outline, color: _pink, size: 20),
                tooltip: 'Видалити',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _cyan;
    }
  }
}
