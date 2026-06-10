import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/providers.dart';
import '../providers/price_match_provider.dart';

// =============================================================================
// Price Match Ninja Screen — AI-generated price-match requests to stores
// =============================================================================

class PriceMatchScreen extends ConsumerStatefulWidget {
  const PriceMatchScreen({super.key});

  @override
  ConsumerState<PriceMatchScreen> createState() => _PriceMatchScreenState();
}

class _PriceMatchScreenState extends ConsumerState<PriceMatchScreen> {
  final _productNameCtrl = TextEditingController();
  final _currentPriceCtrl = TextEditingController();
  final _currentStoreCtrl = TextEditingController();

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _currentPriceCtrl.dispose();
    _currentStoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceMatchProvider);
    final notifier = ref.read(priceMatchProvider.notifier);
    final stats = notifier.getStats();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(
          'PRICE MATCH NINJA',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
            )
          : CustomScrollView(
              slivers: [
                // Stats card
                SliverToBoxAdapter(child: _buildStatsCard(stats)),

                // New request form
                SliverToBoxAdapter(child: _buildRequestForm(notifier)),

                // Request tracking list
                if (state.requests.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildRequestList(state.requests, notifier),
                  ),

                // Success gallery
                if (state.requests.any((r) => r.isSuccess))
                  SliverToBoxAdapter(
                    child:
                        _buildSuccessGallery(state.requests.where((r) => r.isSuccess).toList()),
                  ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stats card
  // ---------------------------------------------------------------------------

  Widget _buildStatsCard((int totalSaved, int successfulMatches, double successRate) stats) {
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
        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'NINJA STATS',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00FF88),
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
                label: 'Zekonomleno',
                value: '${stats.$1} hrn',
                color: const Color(0xFF00FF88),
              ),
              _StatChip(
                label: 'Usplashno',
                value: '${stats.$2}',
                color: const Color(0xFF00F0FF),
              ),
              _StatChip(
                label: 'Usplashnist',
                value: '${stats.$3.toStringAsFixed(0)}%',
                color: const Color(0xFF6B00FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Request form
  // ---------------------------------------------------------------------------

  Widget _buildRequestForm(PriceMatchNotifier notifier) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NOVYI ZAPYT',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00F0FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _productNameCtrl,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _currentPriceCtrl,
                  style: GoogleFonts.shareTechMono(
                      color: Colors.white, fontSize: 14),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tsina (hrn)',
                    labelStyle: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8B95A5),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00F0FF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _currentStoreCtrl,
                  style: GoogleFonts.shareTechMono(
                      color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Mahazyn',
                    labelStyle: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8B95A5),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF00F0FF)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search, size: 18),
              label: Text(
                'Znaity deshevshe',
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: const Color(0xFF0A0E17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _findCheaperPrice(notifier),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Find cheaper price action
  // ---------------------------------------------------------------------------

  Future<void> _findCheaperPrice(PriceMatchNotifier notifier) async {
    final productName = _productNameCtrl.text.trim();
    final currentPrice = double.tryParse(_currentPriceCtrl.text) ?? 0.0;
    final currentStore = _currentStoreCtrl.text.trim();

    if (productName.isEmpty || currentPrice <= 0 || currentStore.isEmpty) {
      return;
    }

    final request =
        await notifier.findCheaperPrice(productName, currentPrice, currentStore);

    if (request != null && mounted) {
      _showCheaperResultDialog(context, request, notifier);
    }
  }

  // ---------------------------------------------------------------------------
  // Cheaper result dialog
  // ---------------------------------------------------------------------------

  void _showCheaperResultDialog(
    BuildContext context,
    PriceMatchRequest request,
    PriceMatchNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          'Znaideno deshevshe!',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00FF88),
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('Tovar', request.productName),
            _buildResultRow(
                'Vash mahazyn', '${request.currentPrice.toStringAsFixed(0)} hrn'),
            _buildResultRow('Deshevshe v',
                '${request.cheaperStore}: ${request.cheaperPrice.toStringAsFixed(0)} hrn'),
            _buildResultRow('Ekonomiia',
                '${request.savingsAmount.toStringAsFixed(0)} hrn (${request.savingsPercent.toStringAsFixed(1)}%)'),
            if (request.storePolicy.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6B00FF).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Polityka: ${request.storePolicy}',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8B95A5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Zakryty',
              style:
                  GoogleFonts.shareTechMono(color: const Color(0xFF8B95A5)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B00FF),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _generateLetter(request, notifier);
            },
            child: Text(
              'Zeneruvaty list',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result row helper
  // ---------------------------------------------------------------------------

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF8B95A5),
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.shareTechMono(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Generate letter action
  // ---------------------------------------------------------------------------

  Future<void> _generateLetter(
    PriceMatchRequest request,
    PriceMatchNotifier notifier,
  ) async {
    final letter = await notifier.generateMatchLetter(request);
    if (mounted && letter.isNotEmpty) {
      _showLetterPreviewDialog(context, letter, request, notifier);
    }
  }

  // ---------------------------------------------------------------------------
  // Letter preview dialog
  // ---------------------------------------------------------------------------

  void _showLetterPreviewDialog(
    BuildContext context,
    String letter,
    PriceMatchRequest request,
    PriceMatchNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text(
          'Zenerovanyi list',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF6B00FF),
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00F0FF).withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                letter,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Zakryty',
              style:
                  GoogleFonts.shareTechMono(color: const Color(0xFF8B95A5)),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 16),
            label: Text(
              'Nadislaty',
              style: GoogleFonts.shareTechMono(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
            ),
            onPressed: () async {
              final success =
                  await notifier.sendMatchRequest(request);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF00FF88),
                      content: Text(
                        'Lyst uspishno nadislano!',
                        style: GoogleFonts.shareTechMono(
                            color: const Color(0xFF0A0E17)),
                      ),
                    ),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFFFF3366),
                      content: Text(
                        'Ne vdalosia nadislaty list. Sprobuvi shche raz.',
                        style: GoogleFonts.shareTechMono(
                            color: Colors.white),
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Request tracking list
  // ---------------------------------------------------------------------------

  Widget _buildRequestList(
    List<PriceMatchRequest> requests,
    PriceMatchNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VIDSTEZHENNIA ZAPYTIV',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF6B00FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...requests.map((request) => _buildRequestCard(request, notifier)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Request card
  // ---------------------------------------------------------------------------

  Widget _buildRequestCard(
    PriceMatchRequest request,
    PriceMatchNotifier notifier,
  ) {
    final statusColor = _getStatusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  request.productName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status.labelUA,
                  style: GoogleFonts.shareTechMono(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Price comparison
          Row(
            children: [
              Text(
                '${request.currentPrice.toStringAsFixed(0)} hrn',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8B95A5),
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, color: Color(0xFF00F0FF), size: 14),
              const SizedBox(width: 8),
              Text(
                '${request.cheaperPrice.toStringAsFixed(0)} hrn',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF00FF88),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '-${request.savingsPercent.toStringAsFixed(0)}%',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFFF3366),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.currentStore} -> ${request.cheaperStore}',
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF8B95A5),
              fontSize: 12,
            ),
          ),

          // XP badge
          if (request.xpAwarded > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 4),
                Text(
                  '+${request.xpAwarded} XP',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFFFD700),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // Action buttons for pending/sent items
          if (request.status == PriceMatchStatus.pending ||
              request.status == PriceMatchStatus.sent) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.matchLetterHtml.isEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(
                      'Zener. list',
                      style: GoogleFonts.shareTechMono(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B00FF),
                    ),
                    onPressed: () => _generateLetter(request, notifier),
                  ),
                if (request.matchLetterHtml.isNotEmpty &&
                    request.status == PriceMatchStatus.pending)
                  TextButton.icon(
                    icon: const Icon(Icons.send, size: 14),
                    label: Text(
                      'Nadislaty',
                      style: GoogleFonts.shareTechMono(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00FF88),
                    ),
                    onPressed: () async {
                      await notifier.sendMatchRequest(request);
                    },
                  ),
                if (request.status == PriceMatchStatus.sent) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle, size: 14),
                    label: Text(
                      'Pryiniato',
                      style: GoogleFonts.shareTechMono(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00FF88),
                    ),
                    onPressed: () => notifier.updateStatus(
                        request.id, PriceMatchStatus.accepted),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, size: 14),
                    label: Text(
                      'Vidkhylemo',
                      style: GoogleFonts.shareTechMono(fontSize: 11),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFFF3366),
                    ),
                    onPressed: () => notifier.updateStatus(
                        request.id, PriceMatchStatus.rejected),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Success gallery
  // ---------------------------------------------------------------------------

  Widget _buildSuccessGallery(List<PriceMatchRequest> successes) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HALERIEIA USPIKHU',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...successes.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Color(0xFFFFD700), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.productName,
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Zekonomleno ${r.savingsAmount.toStringAsFixed(0)} hrn v ${r.currentStore}',
                            style: GoogleFonts.shareTechMono(
                              color: const Color(0xFF00FF88),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${r.cheaperPrice.toStringAsFixed(0)} hrn',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFF00FF88),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '+${r.xpAwarded} XP',
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFFFFD700),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Status color helper
  // ---------------------------------------------------------------------------

  Color _getStatusColor(PriceMatchStatus status) {
    switch (status) {
      case PriceMatchStatus.pending:
        return const Color(0xFFFFD700);
      case PriceMatchStatus.sent:
        return const Color(0xFF00F0FF);
      case PriceMatchStatus.accepted:
        return const Color(0xFF00FF88);
      case PriceMatchStatus.rejected:
        return const Color(0xFFFF3366);
    }
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF8B95A5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
