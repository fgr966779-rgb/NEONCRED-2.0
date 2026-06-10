import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/price_detective_provider.dart';

// =============================================================================
// PRICE HISTORY DETECTIVE SCREEN
// =============================================================================

class PriceDetectiveScreen extends ConsumerStatefulWidget {
  const PriceDetectiveScreen({super.key});

  @override
  ConsumerState<PriceDetectiveScreen> createState() =>
      _PriceDetectiveScreenState();
}

class _PriceDetectiveScreenState extends ConsumerState<PriceDetectiveScreen>
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
    final state = ref.watch(priceDetectiveProvider);
    final notifier = ref.read(priceDetectiveProvider.notifier);

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
              'PRICE DETECTIVE',
              style: GoogleFonts.orbitron(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            if (state.stats.hasDetectiveBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.5)),
                ),
                child: Text(
                  'ДЕТЕКТИВ',
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
      body: state.items.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              color: _cyan,
              backgroundColor: _cardBg,
              onRefresh: () => notifier.pollAllPrices(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsBar(state),
                  const SizedBox(height: 16),
                  ...state.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildDetectiveCard(item),
                      )),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: _purple,
        child: const Icon(Icons.search, color: _gold, size: 28),
      ),
    );
  }

  // ---- Stats Bar ----

  Widget _buildStatsBar(PriceDetectiveState state) {
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
          _statChip('Відстежується', '${state.stats.totalTracked}', _cyan),
          _statChip('КУПУЙ', '${state.stats.buyNowCount}', _green),
          _statChip('Ціна падає', '${state.stats.priceDroppingCount}', _gold),
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
          style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 9),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---- Detective Card ----

  Widget _buildDetectiveCard(DetectiveItem item) {
    final signalColor = Color(item.signalColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signalColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with product name and signal badge
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _buildSignalBadge(item),
            ],
          ),
          const SizedBox(height: 8),

          // Current price
          if (item.currentPriceUah > 0) ...[
            _priceRow('Поточна ціна:', '${_fmtPrice(item.currentPriceUah)} грн', signalColor),
          ],

          // Min prices
          if (item.minPrice30d > 0) ...[
            _priceRow('Мін 30д:', '${_fmtPrice(item.minPrice30d)} грн', _cyan),
            _priceRow('Мін 90д:', '${_fmtPrice(item.minPrice90d)} грн', _purple),
            _priceRow('Мін 180д:', '${_fmtPrice(item.minPrice180d)} грн', _dimText),
          ],

          // Price vs minimum
          if (item.currentPriceUah > 0 && item.minPrice30d > 0) ...[
            const SizedBox(height: 4),
            Text(
              item.priceVsMin,
              style: GoogleFonts.shareTechMono(color: signalColor, fontSize: 11),
            ),
          ],

          const SizedBox(height: 4),
          Text(
            'Мінімум був ${item.daysSinceMin} дн. тому',
            style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 10),
          ),

          // Price History Chart
          if (item.priceHistory.length >= 2) ...[
            const SizedBox(height: 12),
            _buildPriceChart(item),
          ],

          // AI Analysis
          if (item.aiAnalysis.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _purple.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology, color: _purple, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.aiAnalysis,
                      style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),
          Text(
            'ID: ${item.itemId} | Оновлено: ${_formatDate(item.lastUpdated)}',
            style: GoogleFonts.shareTechMono(color: _dimText.withOpacity(0.5), fontSize: 9),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              _actionButton(
                icon: Icons.refresh,
                label: 'Опитати',
                color: _cyan,
                onTap: () => ref.read(priceDetectiveProvider.notifier).pollPrices(item.itemId),
              ),
              const SizedBox(width: 6),
              _actionButton(
                icon: Icons.psychology,
                label: 'AI',
                color: _purple,
                onTap: () => _handleAnalysis(item.itemId),
              ),
              const SizedBox(width: 6),
              if (item.signal == 'buy_now')
                _actionButton(
                  icon: Icons.shopping_cart,
                  label: 'Купив! +40XP',
                  color: _green,
                  onTap: () => ref.read(priceDetectiveProvider.notifier).markAsBought(item.itemId),
                ),
              const Spacer(),
              _actionButton(
                icon: Icons.delete_outline,
                label: '',
                color: _pink,
                onTap: () => ref.read(priceDetectiveProvider.notifier).deleteItem(item.itemId),
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Signal Badge ----

  Widget _buildSignalBadge(DetectiveItem item) {
    final color = Color(item.signalColor);
    final isBuy = item.signal == 'buy_now';

    if (isBuy) {
      return AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: 0.5 + (_pulseController.value * 0.5),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Text(
            item.signalLabel,
            style: GoogleFonts.shareTechMono(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        item.signalLabel,
        style: GoogleFonts.shareTechMono(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ---- Price Chart (Simple CustomPainter) ----

  Widget _buildPriceChart(DetectiveItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.show_chart, color: _cyan, size: 14),
            const SizedBox(width: 4),
            Text(
              'ІСТОРІЯ ЦІН',
              style: GoogleFonts.orbitron(color: _cyan, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _PriceChartPainter(
              history: item.priceHistory,
              lineColor: _cyan,
              minLineColor: _green,
              fillGradient: [_cyan.withOpacity(0.15), Colors.transparent],
            ),
          ),
        ),
      ],
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
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: compact ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.shareTechMono(color: color, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
            const Icon(Icons.search, size: 64, color: _cyan),
            const SizedBox(height: 16),
            Text(
              'PRICE DETECTIVE',
              style: GoogleFonts.orbitron(color: _cyan, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Щоденне опитування цін з українських магазинів через SerpAPI. '
              '30/90/180-денні графіки цін, AI аналіз трендів та сигнали КУПУЙ/ЧИКАЙ. '
              'Отримай +40 XP за покупку на мінімумі!',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _xpChip('SerpAPI', _cyan),
                const SizedBox(width: 12),
                _xpChip('+40 XP мін. ціна', _gold),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Text(
                'Бейдж "ДЕТЕКТИВ" за 3 покупки на мінімумі',
                style: GoogleFonts.shareTechMono(color: _gold, fontSize: 11),
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
                'ПОЧАТИ ВІДСТЕЖЕННЯ',
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

  // ---- AI Analysis ----

  Future<void> _handleAnalysis(String itemId) async {
    await ref.read(priceDetectiveProvider.notifier).generateAnalysis(itemId);
  }

  // ---- Create Dialog ----

  void _showCreateDialog(BuildContext context) {
    final productCtrl = TextEditingController();
    final searchCtrl = TextEditingController();

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
            'НОВЕ ВІДСТЕЖЕННЯ',
            style: GoogleFonts.orbitron(color: _gold, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(productCtrl, 'Товар (напр. PS5 Slim 1TB)', Icons.shopping_cart),
                const SizedBox(height: 12),
                _dialogField(searchCtrl, 'Пошуковий запит (необов\'язково)', Icons.search),
                const SizedBox(height: 8),
                Text(
                  'Додаток буде щоденно перевіряти ціни через SerpAPI та українські магазини.',
                  style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 10),
                ),
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
                if (productCtrl.text.trim().isEmpty) return;
                ref.read(priceDetectiveProvider.notifier).trackProduct(
                      productName: productCtrl.text.trim(),
                      searchQuery: searchCtrl.text.trim(),
                    );
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _purple),
              child: Text(
                'ВІДСТЕЖИТИ',
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

  // ---- Price formatter ----

  String _fmtPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    }
    return price.toStringAsFixed(2);
  }

  // ---- Date formatter ----

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}

// =============================================================================
// CUSTOM PAINTER — Price Chart
// =============================================================================

class _PriceChartPainter extends CustomPainter {
  final List<PriceHistoryPoint> history;
  final Color lineColor;
  final Color minLineColor;
  final List<Color> fillGradient;

  _PriceChartPainter({
    required this.history,
    required this.lineColor,
    required this.minLineColor,
    required this.fillGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final padding = 16.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // Find min/max prices
    double minPrice = history.map((p) => p.priceUah).reduce(min);
    double maxPrice = history.map((p) => p.priceUah).reduce(max);
    final priceRange = maxPrice - minPrice;
    if (priceRange == 0) return;

    // Convert points to coordinates
    final points = <Offset>[];
    for (int i = 0; i < history.length; i++) {
      final x = padding + (i / (history.length - 1)) * chartWidth;
      final y = padding + chartHeight - ((history[i].priceUah - minPrice) / priceRange) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw fill gradient
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height - padding)
      ..lineTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, size.height - padding);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fillGradient,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw minimum price line
    final minY = padding + chartHeight;
    final minPaint = Paint()
      ..color = minLineColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Dashed effect for minimum line
    final dashWidth = 4.0;
    final dashSpace = 4.0;
    double startX = padding;
    while (startX < size.width - padding) {
      canvas.drawLine(
        Offset(startX, minY),
        Offset(startX + dashWidth, minY),
        minPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Draw dots at each data point
    final dotPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }

    // Draw minimum label
    final minLabelPainter = TextPainter(
      text: TextSpan(
        text: 'мін ${minPrice.toStringAsFixed(0)} грн',
        style: TextStyle(
          color: minLineColor,
          fontSize: 9,
          fontFamily: 'ShareTechMono',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    minLabelPainter.paint(canvas, Offset(padding, minY - 14));
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}
