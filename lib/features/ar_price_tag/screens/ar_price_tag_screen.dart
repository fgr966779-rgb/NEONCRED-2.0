import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ar_price_tag_provider.dart';

// =============================================================================
// AR Price Tag Screen — Cyberpunk-styled AR price scanning interface
// =============================================================================
//
// Camera view with scan-frame overlay, holographic result card,
// and scrollable scan history. All text in Ukrainian. Currency: ₴ (UAH).
// =============================================================================

class ARPriceTagScreen extends ConsumerStatefulWidget {
  const ARPriceTagScreen({super.key});

  @override
  ConsumerState<ARPriceTagScreen> createState() => _ARPriceTagScreenState();
}

class _ARPriceTagScreenState extends ConsumerState<ARPriceTagScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Cyberpunk palette
  // ---------------------------------------------------------------------------
  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);

  // ---------------------------------------------------------------------------
  // Animation controllers
  // ---------------------------------------------------------------------------
  late final AnimationController _scanPulseCtrl;
  late final AnimationController _scanLineCtrl;
  late final AnimationController _glitchCtrl;
  late final AnimationController _holoGlowCtrl;

  @override
  void initState() {
    super.initState();
    _scanPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _holoGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Load history on init
    Future.microtask(
      () => ref.read(arPriceTagProvider.notifier).loadScanHistory(),
    );
  }

  @override
  void dispose() {
    _scanPulseCtrl.dispose();
    _scanLineCtrl.dispose();
    _glitchCtrl.dispose();
    _holoGlowCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _onScanTap() async {
    final notifier = ref.read(arPriceTagProvider.notifier);
    await notifier.startCameraScan();

    // Simulate a scan result after a short delay (in production this would
    // come from the camera plugin feeding a base64 frame into detectProduct).
    // For demo purposes we trigger a mock detection.
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Use a deterministic mock base64 so the provider pipeline runs.
    // In a real app the camera plugin would supply the actual image.
    await notifier.detectProduct('');

    // Generate AI savings tip if scan succeeded
    final state = ref.read(arPriceTagProvider);
    if (state.lastScan != null) {
      await notifier.generateSavingsTip(state.lastScan!);
    }
  }

  void _onDismissResult() {
    ref.read(arPriceTagProvider.notifier).clearLastScan();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arPriceTagProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Camera view ──────────────────────────────────────────────
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCameraView(),
                _buildScanFrameOverlay(),
                if (state.isScanning || state.isDetecting)
                  _buildScanLineAnimation(),
                if (state.lastScan != null)
                  _buildHolographicResult(state.lastScan!, state.savingsTip),
                if (state.error != null) _buildErrorBanner(state.error!),
              ],
            ),
          ),

          // ── Scan history ─────────────────────────────────────────────
          _buildScanHistory(state.scanHistory),
        ],
      ),
    );
  }

  // ===========================================================================
  // AppBar
  // ===========================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bg,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.view_in_ar, color: _cyan, size: 22),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_cyan, _purple],
            ).createShader(bounds),
            child: const Text(
              'AR PRICE TAG',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: Colors.white,
              ),
            ),
          ),
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
    );
  }

  // ===========================================================================
  // Camera view (simulated)
  // ===========================================================================

  Widget _buildCameraView() {
    return Container(
      color: const Color(0xFF060A12),
      child: CustomPaint(
        painter: _GridPainter(),
        size: Size.infinite,
      ),
    );
  }

  // ===========================================================================
  // Scan frame overlay — corner brackets + hint + button
  // ===========================================================================

  Widget _buildScanFrameOverlay() {
    final state = ref.watch(arPriceTagProvider);
    final isScanning = state.isScanning || state.isDetecting;

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.maxWidth * 0.75;
        final frameTop = (constraints.maxHeight - frameSize) / 2 - 30;
        final frameLeft = (constraints.maxWidth - frameSize) / 2;

        return Stack(
          children: [
            // Corner brackets
            Positioned(
              top: frameTop,
              left: frameLeft,
              child: CustomPaint(
                size: Size(frameSize, frameSize),
                painter: _ScanFramePainter(
                  color: isScanning ? _cyan : _cyan.withOpacity(0.4),
                  strokeWidth: 2.5,
                  cornerLength: frameSize * 0.12,
                  pulse: _scanPulseCtrl,
                ),
              ),
            ),

            // Hint text
            Positioned(
              top: frameTop + frameSize + 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    isScanning
                        ? 'Сканування...'
                        : 'Наведи камеру на товар',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isScanning ? _cyan : _cyan.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: _cyan.withOpacity(0.5), blurRadius: 12),
                      ],
                    ),
                  ),
                  if (!isScanning) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Натисни кнопку сканування нижче',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Scan button
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: _CyberScanButton(
                  isScanning: isScanning,
                  onPressed: isScanning ? null : _onScanTap,
                  pulseController: _scanPulseCtrl,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // Scan line animation
  // ===========================================================================

  Widget _buildScanLineAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final frameSize = constraints.maxWidth * 0.75;
        final frameTop = (constraints.maxHeight - frameSize) / 2 - 30;
        final frameLeft = (constraints.maxWidth - frameSize) / 2;

        return Positioned(
          top: frameTop,
          left: frameLeft,
          width: frameSize,
          height: frameSize,
          child: AnimatedBuilder(
            animation: _scanLineCtrl,
            builder: (context, _) {
              final lineY = frameSize * _scanLineCtrl.value;
              return CustomPaint(
                size: Size(frameSize, frameSize),
                painter: _ScanLinePainter(
                  lineY: lineY,
                  color: _cyan,
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Holographic result card
  // ===========================================================================

  Widget _buildHolographicResult(ARScanResult scan, String? tip) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: AnimatedBuilder(
            animation: _holoGlowCtrl,
            builder: (context, _) {
              final glowValue = _holoGlowCtrl.value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _cyan.withOpacity(0.4 + glowValue * 0.3),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0D1520).withOpacity(0.95),
                      const Color(0xFF0A0E17).withOpacity(0.98),
                      const Color(0xFF10081F).withOpacity(0.95),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cyan.withOpacity(0.15 + glowValue * 0.1),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _purple.withOpacity(0.1 + glowValue * 0.08),
                      blurRadius: 20,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Holographic shimmer line
                      _buildHoloShimmer(),

                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      color: _cyan,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'РЕЗУЛЬТАТ СКАНУВАННЯ',
                                      style: TextStyle(
                                        color: _cyan.withOpacity(0.8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                // Close button
                                GestureDetector(
                                  onTap: _onDismissResult,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _pink.withOpacity(0.5),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: _pink,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Product name
                            Text(
                              scan.productName.toUpperCase(),
                              style: const TextStyle(
                                color: _cyan,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(color: _cyan, blurRadius: 8),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Price display
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${scan.currentPriceUAH.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '₴',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            // Cheaper online badge
                            if (scan.hasCheaperOnline) ...[
                              const SizedBox(height: 12),
                              _buildCheaperOnlineBadge(scan),
                            ],

                            // Goal progress bar
                            if (scan.hasLinkedGoal) ...[
                              const SizedBox(height: 14),
                              _buildGoalProgress(scan),
                            ],

                            // AI savings tip
                            if (tip != null && tip.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _buildAITip(tip),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Holographic shimmer effect
  // ---------------------------------------------------------------------------

  Widget _buildHoloShimmer() {
    return AnimatedBuilder(
      animation: _glitchCtrl,
      builder: (context, _) {
        final value = _glitchCtrl.value;
        return Positioned.fill(
          child: CustomPaint(
            painter: _HoloShimmerPainter(
              progress: value,
              color1: _cyan,
              color2: _purple,
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // "Дешевше онлайн" badge
  // ---------------------------------------------------------------------------

  Widget _buildCheaperOnlineBadge(ARScanResult scan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _green.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ДЕШЕВШЕ ОНЛАЙН',
              style: TextStyle(
                color: Color(0xFF0A0E17),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${scan.cheaperOnlinePriceUAH.toStringAsFixed(0)}₴',
                style: const TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (scan.cheaperStoreName.isNotEmpty)
                Text(
                  scan.cheaperStoreName,
                  style: TextStyle(
                    color: _green.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Економія',
                style: TextStyle(
                  color: _green.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
              Text(
                '-${scan.savingsUAH.toStringAsFixed(0)}₴',
                style: const TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '-${scan.savingsPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _green.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Goal progress bar
  // ---------------------------------------------------------------------------

  Widget _buildGoalProgress(ARScanResult scan) {
    final progress = scan.goalProgress.clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag, color: _purple, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                scan.linkedGoalName,
                style: TextStyle(
                  color: _purple.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                color: _purple,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                // Track
                Container(
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_purple, _cyan],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: _purple.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AI savings tip
  // ---------------------------------------------------------------------------

  Widget _buildAITip(String tip) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _purple.withOpacity(0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.auto_awesome, color: _purple, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Error banner
  // ===========================================================================

  Widget _buildErrorBanner(String error) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _pink.withOpacity(0.5), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: _pink, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: _pink,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(arPriceTagProvider.notifier).clearLastScan(),
              child: const Icon(Icons.close, color: _pink, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Scan history
  // ===========================================================================

  Widget _buildScanHistory(List<ARScanHistory> history) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1117),
        border: Border(
          top: BorderSide(color: Color(0xFF1A2035), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Icon(Icons.history, color: _cyan.withOpacity(0.6), size: 14),
                const SizedBox(width: 6),
                Text(
                  'ІСТОРІЯ СКАНУВАНЬ',
                  style: TextStyle(
                    color: _cyan.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                if (history.isNotEmpty)
                  Text(
                    '${history.length}',
                    style: TextStyle(
                      color: _cyan.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // List
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Сканувань ще немає',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                itemCount: history.length > 10 ? 10 : history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = history[history.length - 1 - index];
                  return _buildHistoryItem(item);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(ARScanHistory item) {
    final timeStr =
        '${item.scannedAt.hour.toString().padLeft(2, '0')}:${item.scannedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: item.isActionable
              ? _green.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Time
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 10),

          // Product name
          Expanded(
            child: Text(
              item.productName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Price
          Text(
            '${item.priceUAH.toStringAsFixed(0)}₴',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Savings badge
          if (item.savingsUAH > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '-${item.savingsUAH.toStringAsFixed(0)}₴',
                style: const TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Custom painters
// =============================================================================

/// Background grid for the simulated camera view.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.04)
      ..strokeWidth = 0.5;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Crosshair at center
    final cx = size.width / 2;
    final cy = size.height / 2 - 30;
    final crossPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.08)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx - 20, cy), Offset(cx + 20, cy), crossPaint);
    canvas.drawLine(Offset(cx, cy - 20), Offset(cx, cy + 20), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Scan frame with animated corner brackets.
class _ScanFramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final Animation<double> pulse;

  _ScanFramePainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.pulse,
  }) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = 0.5 + pulse.value * 0.5;
    final paint = Paint()
      ..color = color.withOpacity(alpha)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final cl = cornerLength;
    final w = size.width;
    final h = size.height;

    // Top-left
    canvas.drawLine(Offset(0, cl), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cl, 0), paint);

    // Top-right
    canvas.drawLine(Offset(w - cl, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cl), paint);

    // Bottom-right
    canvas.drawLine(Offset(w, h - cl), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w - cl, h), paint);

    // Bottom-left
    canvas.drawLine(Offset(cl, h), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cl), paint);

    // Subtle inner glow on corners
    final glowPaint = Paint()
      ..color = color.withOpacity(alpha * 0.15)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(Offset(0, cl), Offset(0, 0), glowPaint);
    canvas.drawLine(Offset(0, 0), Offset(cl, 0), glowPaint);
    canvas.drawLine(Offset(w - cl, 0), Offset(w, 0), glowPaint);
    canvas.drawLine(Offset(w, 0), Offset(w, cl), glowPaint);
    canvas.drawLine(Offset(w, h - cl), Offset(w, h), glowPaint);
    canvas.drawLine(Offset(w, h), Offset(w - cl, h), glowPaint);
    canvas.drawLine(Offset(cl, h), Offset(0, h), glowPaint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cl), glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter oldDelegate) => false;
}

/// Horizontal scan line that sweeps top to bottom.
class _ScanLinePainter extends CustomPainter {
  final double lineY;
  final Color color;

  _ScanLinePainter({required this.lineY, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), linePaint);

    // Gradient fade below line
    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.15),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, lineY, size.width, 40));

    canvas.drawRect(
      Rect.fromLTWH(0, lineY, size.width, 40),
      gradient,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) =>
      lineY != oldDelegate.lineY;
}

/// Holographic shimmer effect across the card.
class _HoloShimmerPainter extends CustomPainter {
  final double progress;
  final Color color1;
  final Color color2;

  _HoloShimmerPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * (progress * 2 - 0.5);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color1.withOpacity(0.0),
          color1.withOpacity(0.04),
          color2.withOpacity(0.03),
          color2.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(
        Rect.fromLTWH(x - 60, 0, 120, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(x - 60, 0, 120, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HoloShimmerPainter oldDelegate) =>
      progress != oldDelegate.progress;
}

// =============================================================================
// Cyber scan button
// =============================================================================

class _CyberScanButton extends StatelessWidget {
  final bool isScanning;
  final VoidCallback? onPressed;
  final Animation<double> pulseController;

  const _CyberScanButton({
    required this.isScanning,
    required this.onPressed,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, _) {
          final pulseVal = pulseController.value;
          final outerSize = 72.0 + (isScanning ? pulseVal * 8 : 0);
          final outerOpacity = isScanning ? 0.3 + pulseVal * 0.2 : 0.15;

          return SizedBox(
            width: outerSize + 20,
            height: outerSize + 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: outerSize,
                  height: outerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withOpacity(outerOpacity),
                      width: 2,
                    ),
                  ),
                ),
                // Inner circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isScanning
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6B00FF),
                              Color(0xFF00F0FF),
                            ],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF00F0FF),
                              Color(0xFF6B00FF),
                            ],
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: isScanning
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
