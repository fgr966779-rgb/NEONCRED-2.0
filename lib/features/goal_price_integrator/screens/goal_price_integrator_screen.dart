import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/goal_price_integrator_provider.dart';

// =============================================================================
// GOAL PRICE INTEGRATOR SCREEN
// =============================================================================

class GoalPriceIntegratorScreen extends ConsumerStatefulWidget {
  const GoalPriceIntegratorScreen({super.key});

  @override
  ConsumerState<GoalPriceIntegratorScreen> createState() =>
      _GoalPriceIntegratorScreenState();
}

class _GoalPriceIntegratorScreenState
    extends ConsumerState<GoalPriceIntegratorScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;

  static const _bg = Color(0xFF0A0E17);
  static const _cardBg = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _pink = Color(0xFFFF3366);
  static const _green = Color(0xFF00FF88);
  static const _gold = Color(0xFFFFD700);
  static const _dimText = Color(0xFF8892A4);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalPriceIntegratorProvider);
    final notifier = ref.read(goalPriceIntegratorProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GOAL PRICE INTEGRATOR',
              style: GoogleFonts.orbitron(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            if (state.stats.hasIntegratorBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.5)),
                ),
                child: Text(
                  'ІНТЕГРАТОР',
                  style: GoogleFonts.shareTechMono(
                    color: _green,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
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
      ),
      body: state.links.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: _cyan,
              backgroundColor: _cardBg,
              onRefresh: () => notifier.checkAllPrices(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsBar(state),
                  const SizedBox(height: 16),
                  ...state.links.map((link) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildLinkCard(link, state),
                      )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: _purple,
        child: const Icon(Icons.link, color: _gold, size: 28),
      ),
    );
  }

  // ---- Stats Bar ----

  Widget _buildStatsBar(GoalPriceIntegratorState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip('Зв\'язки', '${state.stats.totalLinks}', _cyan),
          _statChip('Ціна ОК', '${state.stats.pricesBelowTarget}', _green),
          _statChip('Економія', '${state.stats.totalSavingsPotential.toStringAsFixed(0)} грн', _gold),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 10),
        ),
      ],
    );
  }

  // ---- Link Card ----

  Widget _buildLinkCard(GoalProductLinkItem link, GoalPriceIntegratorState state) {
    final isPriceBelow = link.priceBelowTarget;
    final accentColor = isPriceBelow ? _green : _cyan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text(
                  link.productName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isPriceBelow)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.5 + (_pulseController.value * 0.5),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _green),
                    ),
                    child: Text(
                      'ЦІНА ОК!',
                      style: GoogleFonts.shareTechMono(
                        color: _green,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Goal name
          Text(
            'Ціль: ${link.goalName}',
            style: GoogleFonts.shareTechMono(color: _purple, fontSize: 12),
          ),
          const SizedBox(height: 4),

          // Prices
          _priceRow('Цільова ціна:', '${_fmtPrice(link.targetPriceUah)} грн', _dimText),
          if (link.bestPriceUah > 0) ...[
            _priceRow('Найкраща ціна:', '${_fmtPrice(link.bestPriceUah)} грн', accentColor),
            _priceRow('Магазин:', link.bestStoreName, _dimText),
          ],
          _priceRow('Залишилось:', '${_fmtPrice(link.remainingUah)} грн', _gold),

          const SizedBox(height: 4),
          Text(
            'ID: ${link.linkId}',
            style: GoogleFonts.shareTechMono(color: _dimText.withOpacity(0.5), fontSize: 9),
          ),
          Text(
            'Перевірено: ${_formatDate(link.lastChecked)}',
            style: GoogleFonts.shareTechMono(color: _dimText.withOpacity(0.5), fontSize: 9),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              _actionButton(
                icon: Icons.search,
                label: 'Перевірити',
                color: _cyan,
                onTap: () => ref.read(goalPriceIntegratorProvider.notifier).checkPrices(link.linkId),
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.psychology,
                label: 'AI аналіз',
                color: _purple,
                onTap: () => _handleAnalysis(link.linkId),
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.delete_outline,
                label: 'Видалити',
                color: _pink,
                onTap: () => ref.read(goalPriceIntegratorProvider.notifier).deleteLink(link.linkId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 12)),
          Text(value, style: GoogleFonts.shareTechMono(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.shareTechMono(color: color, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Empty State ----

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, size: 64, color: _cyan),
            const SizedBox(height: 16),
            Text(
              'GOAL PRICE INTEGRATOR',
              style: GoogleFonts.orbitron(color: _cyan, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Прив\'яжи ціль до реального товару -- додаток автоматично перевірить ціни '
              'в 20+ українських магазинах та повідомить, коли ціна впаде нижче цільової.',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text('+25 XP', style: GoogleFonts.orbitron(color: _gold, fontSize: 16)),
                  Text('коли ціна нижче цільової',
                      style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showCreateDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'СТВОРИТИ ЗВ\'ЯЗОК',
                style: GoogleFonts.orbitron(color: _gold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- AI Analysis Dialog ----

  Future<void> _handleAnalysis(String linkId) async {
    final notifier = ref.read(goalPriceIntegratorProvider.notifier);
    await notifier.generateAnalysis(linkId);

    if (!mounted) return;
    final state = ref.read(goalPriceIntegratorProvider);
    if (state.aiAnalysisText != null && state.aiAnalysisForLinkId == linkId) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _purple.withOpacity(0.5)),
          ),
          title: Row(
            children: [
              const Icon(Icons.psychology, color: _purple),
              const SizedBox(width: 8),
              Text(
                'AI АНАЛІЗ',
                style: GoogleFonts.orbitron(color: _purple, fontSize: 14),
              ),
            ],
          ),
          content: Text(
            state.aiAnalysisText!,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                notifier.clearAnalysis();
                Navigator.of(ctx).pop();
              },
              child: Text('ЗАКРИТИ', style: GoogleFonts.shareTechMono(color: _cyan)),
            ),
          ],
        ),
      );
    }
  }

  // ---- Create Dialog ----

  void _showCreateDialog(BuildContext context) {
    final goalIdCtrl = TextEditingController();
    final goalNameCtrl = TextEditingController();
    final productNameCtrl = TextEditingController();
    final searchQueryCtrl = TextEditingController();
    final targetPriceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _cyan.withOpacity(0.5)),
          ),
          title: Text(
            'НОВИЙ ЗВ\'ЯЗОК',
            style: GoogleFonts.orbitron(color: _gold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(goalNameCtrl, 'Назва цілі', Icons.flag),
                const SizedBox(height: 12),
                _dialogField(productNameCtrl, 'Товар (напр. PS5 Slim)', Icons.shopping_cart),
                const SizedBox(height: 12),
                _dialogField(searchQueryCtrl, 'Пошуковий запит (необов\'язково)', Icons.search),
                const SizedBox(height: 12),
                _dialogField(targetPriceCtrl, 'Цільова ціна (грн)', Icons.attach_money, kb: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Скасувати', style: GoogleFonts.shareTechMono(color: _dimText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (goalNameCtrl.text.trim().isEmpty || productNameCtrl.text.trim().isEmpty) return;
                final targetPrice = double.tryParse(targetPriceCtrl.text) ?? 0;
                ref.read(goalPriceIntegratorProvider.notifier).createLink(
                      goalId: DateTime.now().millisecondsSinceEpoch, // temp ID
                      goalName: goalNameCtrl.text.trim(),
                      productName: productNameCtrl.text.trim(),
                      searchQuery: searchQueryCtrl.text.trim(),
                      targetPriceUah: targetPrice,
                    );
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _purple),
              child: Text(
                'СТВОРИТИ +10 XP',
                style: GoogleFonts.shareTechMono(color: _gold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? kb}) {
    return TextField(
      controller: ctrl,
      keyboardType: kb,
      style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _cyan, size: 18),
        hintText: hint,
        hintStyle: GoogleFonts.shareTechMono(color: _dimText, fontSize: 12),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _cyan),
        ),
      ),
    );
  }
}

// =============================================================================
// HELPERS
// =============================================================================

String _fmtPrice(double v) {
  return v.toStringAsFixed(0).replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ' ',
  );
}

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';
}
