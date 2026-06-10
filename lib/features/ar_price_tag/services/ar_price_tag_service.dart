import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// AR Price Tag — Augmented reality price overlays for NEONCRED
// =============================================================================
//
// Scans products via camera (Google Vision label detection), fetches prices
// from SerpAPI Shopping, and renders a cyberpunk hologram overlay showing
// the in-store vs. online price, savings potential, and linked goal progress.
//
// APIs:  Google Vision API (label / object detection)
//        SerpAPI Shopping (price comparison)
//        OpenRouter (AI savings tips)
//
// XP:    +20 XP per scan
//        +10 XP if cheaper online found
//        +5  XP if goal linked
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// Result of scanning a product with the AR camera.
class ARScanResult {
  final String scanId;
  final String productName;
  final List<String> detectedLabels;
  final double confidence;
  final double currentPriceUAH;
  final double cheaperOnlinePriceUAH;
  final String cheaperStoreName;
  final double savingsPercent;
  final double goalProgress; // 0.0 – 1.0
  final String linkedGoalId;
  final String linkedGoalName;
  final bool priceDropExpected;
  final int priceDropDays;
  final String hologramColor; // hex color for AR overlay
  final String arOverlayText; // formatted text shown in hologram

  const ARScanResult({
    required this.scanId,
    required this.productName,
    this.detectedLabels = const [],
    this.confidence = 0.0,
    this.currentPriceUAH = 0.0,
    this.cheaperOnlinePriceUAH = 0.0,
    this.cheaperStoreName = '',
    this.savingsPercent = 0.0,
    this.goalProgress = 0.0,
    this.linkedGoalId = '',
    this.linkedGoalName = '',
    this.priceDropExpected = false,
    this.priceDropDays = 0,
    this.hologramColor = '#00FFD1',
    this.arOverlayText = '',
  });

  /// Whether a cheaper online price was found.
  bool get hasCheaperOnline =>
      cheaperOnlinePriceUAH > 0 && cheaperOnlinePriceUAH < currentPriceUAH;

  /// Absolute savings in UAH.
  double get savingsUAH =>
      hasCheaperOnline ? currentPriceUAH - cheaperOnlinePriceUAH : 0.0;

  /// Whether a savings goal is linked.
  bool get hasLinkedGoal => linkedGoalId.isNotEmpty;

  ARScanResult copyWith({
    String? scanId,
    String? productName,
    List<String>? detectedLabels,
    double? confidence,
    double? currentPriceUAH,
    double? cheaperOnlinePriceUAH,
    String? cheaperStoreName,
    double? savingsPercent,
    double? goalProgress,
    String? linkedGoalId,
    String? linkedGoalName,
    bool? priceDropExpected,
    int? priceDropDays,
    String? hologramColor,
    String? arOverlayText,
  }) {
    return ARScanResult(
      scanId: scanId ?? this.scanId,
      productName: productName ?? this.productName,
      detectedLabels: detectedLabels ?? this.detectedLabels,
      confidence: confidence ?? this.confidence,
      currentPriceUAH: currentPriceUAH ?? this.currentPriceUAH,
      cheaperOnlinePriceUAH:
          cheaperOnlinePriceUAH ?? this.cheaperOnlinePriceUAH,
      cheaperStoreName: cheaperStoreName ?? this.cheaperStoreName,
      savingsPercent: savingsPercent ?? this.savingsPercent,
      goalProgress: goalProgress ?? this.goalProgress,
      linkedGoalId: linkedGoalId ?? this.linkedGoalId,
      linkedGoalName: linkedGoalName ?? this.linkedGoalName,
      priceDropExpected: priceDropExpected ?? this.priceDropExpected,
      priceDropDays: priceDropDays ?? this.priceDropDays,
      hologramColor: hologramColor ?? this.hologramColor,
      arOverlayText: arOverlayText ?? this.arOverlayText,
    );
  }
}

/// A saved scan in the user's history.
class ARScanHistory {
  final String scanId;
  final String productName;
  final double priceUAH;
  final double savingsUAH;
  final DateTime scannedAt;
  final bool isActionable;

  ARScanHistory({
    required this.scanId,
    required this.productName,
    this.priceUAH = 0.0,
    this.savingsUAH = 0.0,
    DateTime? scannedAt,
    this.isActionable = false,
  }) : scannedAt = scannedAt ?? DateTime(2000);
}

// -----------------------------------------------------------------------------
// Google Vision API — label detection
// -----------------------------------------------------------------------------

Future<Map<String, dynamic>> _detectWithGoogleVision(
  String base64Image,
  String apiKey,
) async {
  if (apiKey.isEmpty) {
    return {'error': 'Google Vision API key not configured'};
  }

  final uri = Uri.parse(
    'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
  );

  final body = jsonEncode({
    'requests': [
      {
        'image': {'content': base64Image},
        'features': [
          {'type': 'LABEL_DETECTION', 'maxResults': 10},
          {'type': 'OBJECT_LOCALIZATION', 'maxResults': 5},
        ],
      },
    ],
  });

  try {
    final response = await http.post(uri, body: body, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'error': 'Vision API returned ${response.statusCode}'};
  } catch (e) {
    return {'error': 'Vision API error: $e'};
  }
}



// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class ARPriceTagState {
  final bool isScanning;
  final bool isDetecting;
  final ARScanResult? lastScan;
  final List<ARScanHistory> scanHistory;
  final String? savingsTip;
  final String? error;

  const ARPriceTagState({
    this.isScanning = false,
    this.isDetecting = false,
    this.lastScan,
    this.scanHistory = const [],
    this.savingsTip,
    this.error,
  });

  ARPriceTagState copyWith({
    bool? isScanning,
    bool? isDetecting,
    ARScanResult? lastScan,
    List<ARScanHistory>? scanHistory,
    String? savingsTip,
    String? error,
  }) {
    return ARPriceTagState(
      isScanning: isScanning ?? this.isScanning,
      isDetecting: isDetecting ?? this.isDetecting,
      lastScan: lastScan ?? this.lastScan,
      scanHistory: scanHistory ?? this.scanHistory,
      savingsTip: savingsTip,
      error: error,
    );
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class ARPriceTagNotifier extends StateNotifier<ARPriceTagState> {
  final Ref _ref;
  final AppDatabase _db;

  ARPriceTagNotifier(this._ref, this._db)
      : super(const ARPriceTagState());

  // ---------------------------------------------------------------------------
  // Start camera scan — initiate camera + Google Vision pipeline
  // ---------------------------------------------------------------------------

  Future<void> startCameraScan() async {
    state = state.copyWith(
      isScanning: true,
      isDetecting: false,
      error: null,
      savingsTip: null,
    );

    try {
      // Camera initiation happens in the UI layer (camera plugin).
      // Here we prepare the scanning state and validate API keys.
      final visionKey = _ref.read(googleVisionApiKeyProvider);

      if (visionKey.isEmpty) {
        state = state.copyWith(
          isScanning: false,
          error: 'Google Vision API ключ не налаштований',
        );
        return;
      }

      // Scanning is active — UI should now show camera feed
      // and call detectProduct() when user captures a frame.
      state = state.copyWith(isScanning: true);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Помилка запуску камери: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Detect product — use Google Vision for labels
  // ---------------------------------------------------------------------------

  Future<ARScanResult?> detectProduct(String base64Image) async {
    state = state.copyWith(isDetecting: true, error: null);

    try {
      final visionKey = _ref.read(googleVisionApiKeyProvider);
      final visionResult = await _detectWithGoogleVision(
        base64Image,
        visionKey,
      );

      // Parse label annotations
      final responses = visionResult['responses'] as List<dynamic>? ?? [];
      if (responses.isEmpty) {
        state = state.copyWith(
          isDetecting: false,
          isScanning: false,
          error: 'Не вдалося розпізнати зображення',
        );
        return null;
      }

      final response = responses[0] as Map<String, dynamic>;
      final labelAnnotations =
          response['labelAnnotations'] as List<dynamic>? ?? [];

      final detectedLabels = <String>[];
      double topConfidence = 0.0;

      for (final label in labelAnnotations) {
        final desc = (label['description'] ?? '').toString();
        final score = (label['score'] ?? 0.0) as num;
        if (desc.isNotEmpty) {
          detectedLabels.add(desc);
          if (score > topConfidence) topConfidence = score.toDouble();
        }
      }

      if (detectedLabels.isEmpty) {
        state = state.copyWith(
          isDetecting: false,
          isScanning: false,
          error: 'Мітки не знайдено — спробуй ще раз',
        );
        return null;
      }

      // Use top label as product name
      final productName = detectedLabels.first;

      final scanId = 'arscan_${DateTime.now().millisecondsSinceEpoch}';

      var scanResult = ARScanResult(
        scanId: scanId,
        productName: productName,
        detectedLabels: detectedLabels,
        confidence: topConfidence,
      );

      // Fetch price data
      final pricedResult = await fetchPriceData(productName);
      scanResult = scanResult.copyWith(
        currentPriceUAH: pricedResult.currentPriceUAH,
        cheaperOnlinePriceUAH: pricedResult.cheaperOnlinePriceUAH,
        cheaperStoreName: pricedResult.cheaperStoreName,
        savingsPercent: pricedResult.savingsPercent,
      );

      // Match with savings goal
      final matchedResult = await matchWithGoal(productName);
      scanResult = scanResult.copyWith(
        goalProgress: matchedResult.goalProgress,
        linkedGoalId: matchedResult.linkedGoalId,
        linkedGoalName: matchedResult.linkedGoalName,
      );

      // Generate hologram overlay data
      final overlayResult = generateHologramOverlay(scanResult);
      scanResult = scanResult.copyWith(
        hologramColor: overlayResult.hologramColor,
        arOverlayText: overlayResult.arOverlayText,
      );

      // Save to history
      await saveScanToHistory(scanResult);

      // Award XP
      int xp = 20; // base scan XP
      if (scanResult.hasCheaperOnline) xp += 10;
      if (scanResult.hasLinkedGoal) xp += 5;
      await _db.addXP(xp, source: 'ar_price_tag_scan');

      state = state.copyWith(
        isDetecting: false,
        isScanning: false,
        lastScan: scanResult,
      );

      return scanResult;
    } catch (e) {
      state = state.copyWith(
        isDetecting: false,
        isScanning: false,
        error: 'Помилка розпізнавання: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch price data — use SerpAPI Shopping
  // ---------------------------------------------------------------------------

  Future<ARScanResult> fetchPriceData(String productName) async {
    final query = '$productName купити Україна ціна';
    final result = await _ref.read(serpApiServiceProvider).searchShoppingRaw(query);

    double currentPrice = 0.0;
    double cheaperOnlinePrice = 0.0;
    String cheaperStore = '';
    double savingsPercent = 0.0;

    final shoppingResults =
        result['shopping_results'] as List<dynamic>? ?? [];

    if (shoppingResults.isNotEmpty) {
      // First result is treated as current/retail price
      final firstResult = shoppingResults[0] as Map<String, dynamic>;
      final firstPriceStr =
          (firstResult['extracted_price'] ?? firstResult['price'] ?? '0')
              .toString();
      currentPrice = double.tryParse(
            firstPriceStr.replaceAll(RegExp(r'[^\d.]'), ''),
          ) ??
          0.0;

      // Find the cheapest online price
      double lowestPrice = double.maxFinite;
      for (final r in shoppingResults) {
        final priceStr =
            (r['extracted_price'] ?? r['price'] ?? '0').toString();
        final price = double.tryParse(
              priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
            ) ??
            0.0;
        if (price > 0 && price < lowestPrice) {
          lowestPrice = price;
          cheaperStore =
              (r['store'] ?? r['source'] ?? '').toString();
        }
      }

      if (lowestPrice < double.maxFinite && lowestPrice < currentPrice) {
        cheaperOnlinePrice = lowestPrice;
        savingsPercent =
            ((currentPrice - cheaperOnlinePrice) / currentPrice) * 100;
      }
    }

    return ARScanResult(
      scanId: '',
      productName: productName,
      currentPriceUAH: currentPrice,
      cheaperOnlinePriceUAH: cheaperOnlinePrice,
      cheaperStoreName: cheaperStore,
      savingsPercent: savingsPercent,
    );
  }

  // ---------------------------------------------------------------------------
  // Match with goal — link to existing savings goal
  // ---------------------------------------------------------------------------

  Future<ARScanResult> matchWithGoal(String productName) async {
    try {
      final goals = await _db.getAllGoals();
      if (goals.isEmpty) {
        return const ARScanResult(
          scanId: '',
          productName: '',
        );
      }

      // Simple keyword matching — find a goal whose name overlaps with
      // the detected product labels.
      final productLower = productName.toLowerCase();

      Goal? bestMatch;
      double bestScore = 0.0;

      for (final goal in goals) {
        final goalLower = goal.name.toLowerCase();
        double score = 0.0;

        // Check word overlap
        final productWords = productLower.split(RegExp(r'\s+'));
        final goalWords = goalLower.split(RegExp(r'\s+'));

        for (final pw in productWords) {
          if (pw.length < 3) continue; // skip short words
          for (final gw in goalWords) {
            if (gw.length < 3) continue;
            if (gw.contains(pw) || pw.contains(gw)) {
              score += 1.0;
            }
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestMatch = goal;
        }
      }

      if (bestMatch != null && bestScore > 0) {
        final progress = bestMatch.targetAmount > 0
            ? (bestMatch.currentAmount / bestMatch.targetAmount)
                .clamp(0.0, 1.0)
            : 0.0;

        return ARScanResult(
          scanId: '',
          productName: '',
          goalProgress: progress,
          linkedGoalId: bestMatch.id.toString(),
          linkedGoalName: bestMatch.name,
        );
      }
    } catch (_) {
      // If goal matching fails, return empty — non-critical feature
    }

    return const ARScanResult(
      scanId: '',
      productName: '',
    );
  }

  // ---------------------------------------------------------------------------
  // Generate hologram overlay — compute AR overlay data
  // ---------------------------------------------------------------------------

  ARScanResult generateHologramOverlay(ARScanResult scan) {
    // Pick hologram color based on savings potential
    String hologramColor;
    if (scan.hasCheaperOnline && scan.savingsPercent > 20) {
      // Green — big savings
      hologramColor = '#00FF88';
    } else if (scan.hasCheaperOnline) {
      // Cyan — moderate savings
      hologramColor = '#00FFD1';
    } else if (scan.hasLinkedGoal && scan.goalProgress > 0.5) {
      // Blue — goal is progressing well
      hologramColor = '#00AAFF';
    } else if (scan.hasLinkedGoal) {
      // Purple — goal linked but slow progress
      hologramColor = '#AA44FF';
    } else {
      // Default neon teal
      hologramColor = '#00FFD1';
    }

    // Build overlay text
    final buffer = StringBuffer();
    buffer.writeln('॥ ${scan.productName} ॥');
    buffer.writeln('${scan.currentPriceUAH.toStringAsFixed(0)}₴');

    if (scan.hasCheaperOnline) {
      buffer.writeln(
        '→ ${scan.cheaperOnlinePriceUAH.toStringAsFixed(0)}₴ '
        '@ ${scan.cheaperStoreName}',
      );
      buffer.writeln(
        'Δ ${scan.savingsUAH.toStringAsFixed(0)}₴ '
        '(${scan.savingsPercent.toStringAsFixed(0)}%)',
      );
    }

    if (scan.hasLinkedGoal) {
      final pct = (scan.goalProgress * 100).toStringAsFixed(0);
      buffer.writeln('◉ ${scan.linkedGoalName}: $pct%');
    }

    if (scan.priceDropExpected) {
      buffer.writeln(
        '↓ Очікується знижка через ${scan.priceDropDays} дн.',
      );
    }

    return scan.copyWith(
      hologramColor: hologramColor,
      arOverlayText: buffer.toString().trim(),
    );
  }

  // ---------------------------------------------------------------------------
  // Save scan to history
  // ---------------------------------------------------------------------------

  Future<void> saveScanToHistory(ARScanResult scan) async {
    final entry = ARScanHistory(
      scanId: scan.scanId,
      productName: scan.productName,
      priceUAH: scan.currentPriceUAH,
      savingsUAH: scan.savingsUAH,
      scannedAt: DateTime.now(),
      isActionable: scan.hasCheaperOnline,
    );

    final updated = [...state.scanHistory, entry];

    // Keep last 100 scans in memory
    final trimmed = updated.length > 100
        ? updated.sublist(updated.length - 100)
        : updated;

    state = state.copyWith(scanHistory: trimmed);
  }

  // ---------------------------------------------------------------------------
  // Load scan history
  // ---------------------------------------------------------------------------

  Future<void> loadScanHistory() async {
    // Scan history is currently kept in-memory only.
    // Future: persist via a dedicated Drift table.
    // For now, we simply ensure state is clean.
    state = state.copyWith(scanHistory: state.scanHistory);
  }

  // ---------------------------------------------------------------------------
  // Generate savings tip — AI tip via OpenRouter
  // ---------------------------------------------------------------------------

  Future<void> generateSavingsTip(ARScanResult scan) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    if (apiKey.isEmpty) {
      state = state.copyWith(
        savingsTip: 'AI недоступний — API ключ не налаштований',
      );
      return;
    }

    final goalContext = scan.hasLinkedGoal
        ? 'Ціль "${scan.linkedGoalName}" прогрес ${(scan.goalProgress * 100).toStringAsFixed(0)}%.'
        : 'Ціль не прив\'язана.';

    final savingsContext = scan.hasCheaperOnline
        ? 'Дешевше онлайн: ${scan.cheaperOnlinePriceUAH.toStringAsFixed(0)}₴ у ${scan.cheaperStoreName} (економія ${scan.savingsUAH.toStringAsFixed(0)}₴, ${scan.savingsPercent.toStringAsFixed(0)}%).'
        : 'Дешевшої ціни онлайн не знайдено.';

    final userPrompt = '''Товар: ${scan.productName}
Ціна в магазині: ${scan.currentPriceUAH.toStringAsFixed(0)}₴
$savingsContext
$goalContext

Дай коротку (2-3 речення) пораду українською, як заощадити на цій покупці.
Стиль: кіберпанк, використовуй техно-метафори, звертайся до користувача як "оператор".''';

    try {
      final tip = await openRouter.chat(
        systemPrompt: _systemPrompt,
        userPrompt: userPrompt,
        temperature: 0.9,
        maxTokens: 256,
      );

      state = state.copyWith(savingsTip: tip);
    } catch (e) {
      state = state.copyWith(
        savingsTip: 'Не вдалося згенерувати пораду: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Clear last scan
  // ---------------------------------------------------------------------------

  void clearLastScan() {
    state = state.copyWith(
      lastScan: null,
      savingsTip: null,
      error: null,
    );
  }

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const _systemPrompt =
      'Ти VAULT-17 — кіберпанк AI-асистент додатку NEONCRED. '
      'Твоя мета — допомагати користувачам заощаджувати гроші, '
      'знаходити вигідніші ціни та мотивувати досягати фінансових цілей. '
      'Говори українською. Стиль: кіберпанк, техно-метафори, '
      'звертайся до користувача як "оператор".';
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final arPriceTagProvider =
    StateNotifierProvider<ARPriceTagNotifier, ARPriceTagState>((ref) {
  final db = ref.read(databaseProvider);
  return ARPriceTagNotifier(ref, db);
});
