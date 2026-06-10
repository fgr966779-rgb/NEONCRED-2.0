import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/inflation_shield_provider.dart';

// =============================================================================
// INFLATION SHIELD ALERT SCREEN
// =============================================================================

class InflationShieldScreen extends ConsumerStatefulWidget {
  const InflationShieldScreen({super.key});

  @override
  ConsumerState<InflationShieldScreen> createState() =>
      _InflationShieldScreenState();
}

class _InflationShieldScreenState
    extends ConsumerState<InflationShieldScreen>
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
    final state = ref.watch(inflationShieldProvider);
    final notifier = ref.read(inflationShieldProvider.notifier);
    final shield = state.shield;

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
              'INFLATION SHIELD',
              style: GoogleFonts.orbitron(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            if (state.hasShieldBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.5)),
                ),
                child: Text(
                  'ЩИТ',
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
      body: shield == null
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Alert banner
                if (shield.isAlertActive) _buildAlertBanner(shield),
                const SizedBox(height: 12),

                // Exchange rates card
                _buildRatesCard(shield),
                const SizedBox(height: 12),

                // Inflation impact card
                _buildImpactCard(shield),
                const SizedBox(height: 12),

                // Savings in foreign currency
                _buildCurrencyCard(shield),
                const SizedBox(height: 12),

                // Suggested top-up
                _buildTopUpCard(shield),
                const SizedBox(height: 12),

                // AI Advice
                if (shield.aiAdvice.isNotEmpty) _buildAdviceCard(shield),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _actionButton(
                        icon: Icons.refresh,
                        label: 'Оновити курси',
                        color: _cyan,
                        onTap: () => notifier.fetchRates(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _actionButton(
                        icon: Icons.psychology,
                        label: 'AI порада',
                        color: _purple,
                        onTap: () => _handleAdvice(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Anti-inflation deposit
                _buildDepositButton(shield),
              ],
            ),
    );
  }

  // ---- Alert Banner ----

  Widget _buildAlertBanner(InflationShieldItem shield) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.6 + (_pulseController.value * 0.4),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _pink.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield, color: _pink, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                shield.impactMessage,
                style: GoogleFonts.shareTechMono(color: _pink, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Exchange Rates Card ----

  Widget _buildRatesCard(InflationShieldItem shield) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, color: _cyan, size: 20),
              const SizedBox(width: 8),
              Text(
                'КУРСИ ВАЛЮТ',
                style: GoogleFonts.orbitron(color: _cyan, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _rateRow('USD/UAH', shield.usdUahRate.toStringAsFixed(2), '\$', _green),
          const SizedBox(height: 8),
          _rateRow('EUR/UAH', shield.eurUahRate.toStringAsFixed(2), '\u20AC', _purple),
          const SizedBox(height: 8),
          _rateRow('Інфляція', '${shield.inflationRate.toStringAsFixed(1)}%', '', _pink),
          const SizedBox(height: 4),
          Text(
            'Оновлено: ${_formatDate(shield.lastUpdated)}',
            style: GoogleFonts.shareTechMono(color: _dimText.withOpacity(0.5), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _rateRow(String label, String value, String symbol, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 13)),
        Row(
          children: [
            if (symbol.isNotEmpty) ...[
              Text(symbol, style: GoogleFonts.shareTechMono(color: color, fontSize: 13)),
              const SizedBox(width: 4),
            ],
            Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  // ---- Inflation Impact Card ----

  Widget _buildImpactCard(InflationShieldItem shield) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pink.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down, color: _pink, size: 20),
              const SizedBox(width: 8),
              Text(
                'ВПЛИВ ІНФЛЯЦІЇ',
                style: GoogleFonts.orbitron(color: _pink, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _impactRow('Заощадження:', '${_fmtPrice(shield.totalSavingsUah)} грн', _gold),
          _impactRow('Втрати за рік:', '${_fmtPrice(shield.projectedLossIn1Year)} грн', _pink),
          _impactRow(
            'Реальна вартість через рік:',
            '${_fmtPrice(shield.totalSavingsUah - shield.projectedLossIn1Year)} грн',
            _dimText,
          ),
        ],
      ),
    );
  }

  Widget _impactRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 12))),
          Text(value, style: GoogleFonts.shareTechMono(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ---- Currency Equivalent Card ----

  Widget _buildCurrencyCard(InflationShieldItem shield) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance, color: _green, size: 20),
              const SizedBox(width: 8),
              Text(
                'ВАЛЮТНИЙ ЕКВІВАЛЕНТ',
                style: GoogleFonts.orbitron(color: _green, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _currencyChip('USD', '\$${shield.savingsInUsd.toStringAsFixed(2)}', _green),
              _currencyChip('EUR', '\u20AC${shield.savingsInEur.toStringAsFixed(2)}', _purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _currencyChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 11)),
      ],
    );
  }

  // ---- Suggested Top-Up Card ----

  Widget _buildTopUpCard(InflationShieldItem shield) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings, color: _gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'РЕКОМЕНДАЦІЯ',
                style: GoogleFonts.orbitron(color: _gold, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Щомісячне поповнення ${_fmtPrice(shield.suggestedTopUpUah)} грн компенсує знецінення від інфляції.',
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---- AI Advice Card ----

  Widget _buildAdviceCard(InflationShieldItem shield) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: _purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI ПОРАДА',
                style: GoogleFonts.orbitron(color: _purple, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            shield.aiAdvice,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ---- Action Button ----

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.shareTechMono(color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Anti-Inflation Deposit Button ----

  Widget _buildDepositButton(InflationShieldItem shield) {
    return GestureDetector(
      onTap: () => _showDepositDialog(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_purple, _cyan.withOpacity(0.5)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield, color: _gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'АНОТИНФЛЯЦІЙНИЙ ДЕПОЗИТ +20 XP',
              style: GoogleFonts.orbitron(color: _gold, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
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
            const Icon(Icons.shield_moon, size: 64, color: _cyan),
            const SizedBox(height: 16),
            Text(
              'INFLATION SHIELD',
              style: GoogleFonts.orbitron(color: _cyan, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Моніторинг курсів USD/UAH та EUR/UAH, аналіз впливу інфляції на заощадження. '
              'Додаток покаже скільки втрачаєш та скільки потрібно поповнювати щомісяця.',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _xpChip('TwelveData API', _cyan),
                const SizedBox(width: 12),
                _xpChip('+20 XP за депозит', _gold),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ref.read(inflationShieldProvider.notifier).initShield();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'АКТИВУВАТИ ЩИТ',
                style: GoogleFonts.orbitron(color: _gold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _xpChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: GoogleFonts.shareTechMono(color: color, fontSize: 11)),
    );
  }

  // ---- AI Advice Handler ----

  Future<void> _handleAdvice() async {
    await ref.read(inflationShieldProvider.notifier).generateAdvice();
  }

  // ---- Deposit Dialog ----

  void _showDepositDialog() {
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _gold.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            const Icon(Icons.shield, color: _gold),
            const SizedBox(width: 8),
            Text(
              'АНТИІНФЛЯЦІЙНИЙ ДЕПОЗИТ',
              style: GoogleFonts.orbitron(color: _gold, fontSize: 14),
            ),
          ],
        ),
        content: TextField(
          controller: amountCtrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.attach_money, color: _gold, size: 18),
            hintText: 'Сума поповнення (грн)',
            hintStyle: GoogleFonts.shareTechMono(color: _dimText, fontSize: 12),
            filled: true,
            fillColor: _bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _gold.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _gold),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Скасувати', style: GoogleFonts.shareTechMono(color: _dimText)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0) return;
              ref.read(inflationShieldProvider.notifier).recordAntiInflationDeposit(amount);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            child: Text(
              'ПОПОВНИТИ +20 XP',
              style: GoogleFonts.shareTechMono(color: _gold, fontSize: 12),
            ),
          ),
        ],
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
      '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
