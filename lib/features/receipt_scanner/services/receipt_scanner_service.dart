import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// =============================================================================
// Receipt Scanner AI — Scan receipts, extract spending, motivate savings
// =============================================================================
//
// Scans receipts via camera (Mindee API + Google Vision fallback), extracts
// merchant, total, items, and category. Then converts every receipt into
// savings motivation: "That coffee cost 12% of your PS5 goal".
//
// APIs:  Mindee API (structured receipt parsing)
//        Google Vision API (OCR fallback)
//        OpenRouter (AI spending insights)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// Spending categories for receipts.
enum SpendingCategory {
  groceries('groceries', 'Продукти', '🛒'),
  dining('dining', 'Ресторани/Кафе', '🍽️'),
  coffee('coffee', 'Кава', '☕'),
  transport('transport', 'Транспорт', '🚌'),
  entertainment('entertainment', 'Розваги', '🎮'),
  shopping('shopping', 'Шопінг', '🛍️'),
  health('health', "Здоров'я", '💊'),
  education('education', 'Освіта', '📚'),
  subscriptions('subscriptions', 'Підписки', '📱'),
  utilities('utilities', 'Комунальні', '💡'),
  impulse('impulse', 'Імпульсивні', '⚡'),
  other('other', 'Інше', '📦');

  final String id;
  final String labelUA;
  final String emoji;
  const SpendingCategory(this.id, this.labelUA, this.emoji);
}

/// A scanned receipt with extracted data.
class ScannedReceipt {
  final String receiptId;
  final String merchantName;
  final double totalAmount;
  final String currency;
  final SpendingCategory category;
  final DateTime purchaseDate;
  final List<ReceiptLineItem> lineItems;
  final double savingsPotentialUAH; // what could have been saved
  final String motivationMessageUA; // "Це 12% від ціни PS5"
  final int? goalId; // linked goal for motivation
  final bool isImpulseBuy;
  final DateTime scannedAt;
  final String ocrSource; // 'mindee' | 'google_vision' | 'manual'

  ScannedReceipt({
    required this.receiptId,
    required this.merchantName,
    required this.totalAmount,
    this.currency = 'UAH',
    this.category = SpendingCategory.other,
    DateTime? purchaseDate,
    this.lineItems = const [],
    this.savingsPotentialUAH = 0.0,
    this.motivationMessageUA = '',
    this.goalId,
    this.isImpulseBuy = false,
    DateTime? scannedAt,
    this.ocrSource = 'manual',
  })  : purchaseDate = purchaseDate ?? DateTime(2000),
        scannedAt = scannedAt ?? DateTime(2000);

  ScannedReceipt copyWith({
    String? receiptId,
    String? merchantName,
    double? totalAmount,
    String? currency,
    SpendingCategory? category,
    DateTime? purchaseDate,
    List<ReceiptLineItem>? lineItems,
    double? savingsPotentialUAH,
    String? motivationMessageUA,
    int? goalId,
    bool? isImpulseBuy,
    DateTime? scannedAt,
    String? ocrSource,
  }) {
    return ScannedReceipt(
      receiptId: receiptId ?? this.receiptId,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lineItems: lineItems ?? this.lineItems,
      savingsPotentialUAH: savingsPotentialUAH ?? this.savingsPotentialUAH,
      motivationMessageUA: motivationMessageUA ?? this.motivationMessageUA,
      goalId: goalId ?? this.goalId,
      isImpulseBuy: isImpulseBuy ?? this.isImpulseBuy,
      scannedAt: scannedAt ?? this.scannedAt,
      ocrSource: ocrSource ?? this.ocrSource,
    );
  }
}

class ReceiptLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  const ReceiptLineItem({
    required this.description,
    this.quantity = 1.0,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
  });
}

/// Weekly spending summary.
class WeeklySpendingSummary {
  final double totalSpent;
  final double potentialSavings;
  final Map<SpendingCategory, double> byCategory;
  final int impulseBuyCount;
  final double impulseBuyTotal;
  final double coffeeTotal;
  final double diningTotal;
  final String topCategoryLabel;
  final double topCategoryAmount;

  const WeeklySpendingSummary({
    this.totalSpent = 0.0,
    this.potentialSavings = 0.0,
    this.byCategory = const {},
    this.impulseBuyCount = 0,
    this.impulseBuyTotal = 0.0,
    this.coffeeTotal = 0.0,
    this.diningTotal = 0.0,
    this.topCategoryLabel = '',
    this.topCategoryAmount = 0.0,
  });
}

/// Overall stats for the Receipt Scanner feature.
class ReceiptScannerStats {
  final int totalReceiptsScanned;
  final double totalSpentUAH;
  final double totalPotentialSavings;
  final int impulseBuyCount;
  final double impulseBuyTotal;
  final double avgReceiptAmount;
  final SpendingCategory topCategory;
  final double topCategoryAmount;
  final int streakDays; // consecutive days with a scan

  const ReceiptScannerStats({
    this.totalReceiptsScanned = 0,
    this.totalSpentUAH = 0.0,
    this.totalPotentialSavings = 0.0,
    this.impulseBuyCount = 0,
    this.impulseBuyTotal = 0.0,
    this.avgReceiptAmount = 0.0,
    this.topCategory = SpendingCategory.other,
    this.topCategoryAmount = 0.0,
    this.streakDays = 0,
  });
}

// -----------------------------------------------------------------------------
// Mindee API integration
// -----------------------------------------------------------------------------

Future<Map<String, dynamic>> _scanWithMindee(
  String base64Image,
  String mindeeApiKey,
) async {
  if (mindeeApiKey.isEmpty) {
    return {'error': 'Mindee API key not configured'};
  }

  // In production, use package:http to POST to:
  // https://api.mindee.net/v1/products/mindee/expense_receipts/v5/predict
  // Headers: Authorization: ApiKey {mindeeApiKey}
  // Body: multipart/form-data with document image

  // Placeholder response structure
  return {
    'prediction': {
      'merchant_name': 'Unknown',
      'total_amount': 0.0,
      'date': DateTime.now().toIso8601String(),
      'line_items': [],
    }
  };
}

// -----------------------------------------------------------------------------
// Google Vision API fallback
// -----------------------------------------------------------------------------

Future<String> _scanWithGoogleVision(
  String base64Image,
  String googleVisionKey,
) async {
  if (googleVisionKey.isEmpty) {
    return 'Google Vision API key not configured';
  }

  // In production, POST to:
  // https://vision.googleapis.com/v1/images:annotate?key={key}
  // Body: { "requests": [{ "image": { "content": base64Image }, "features": [{"type": "TEXT_DETECTION"}] }]}

  return ''; // placeholder
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class ReceiptScannerState {
  final List<ScannedReceipt> receipts;
  final ReceiptScannerStats stats;
  final WeeklySpendingSummary weeklySummary;
  final bool isScanning;
  final bool isGeneratingInsight;
  final String? aiInsight;
  final String? error;
  final ScannedReceipt? lastScanned;

  const ReceiptScannerState({
    this.receipts = const [],
    this.stats = const ReceiptScannerStats(),
    this.weeklySummary = const WeeklySpendingSummary(),
    this.isScanning = false,
    this.isGeneratingInsight = false,
    this.aiInsight,
    this.error,
    this.lastScanned,
  });

  ReceiptScannerState copyWith({
    List<ScannedReceipt>? receipts,
    ReceiptScannerStats? stats,
    WeeklySpendingSummary? weeklySummary,
    bool? isScanning,
    bool? isGeneratingInsight,
    String? aiInsight,
    String? error,
    ScannedReceipt? lastScanned,
  }) {
    return ReceiptScannerState(
      receipts: receipts ?? this.receipts,
      stats: stats ?? this.stats,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      isScanning: isScanning ?? this.isScanning,
      isGeneratingInsight: isGeneratingInsight ?? this.isGeneratingInsight,
      aiInsight: aiInsight,
      error: error,
      lastScanned: lastScanned ?? this.lastScanned,
    );
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class ReceiptScannerNotifier extends StateNotifier<ReceiptScannerState> {
  final Ref _ref;
  final AppDatabase _db;

  ReceiptScannerNotifier(this._ref, this._db)
      : super(const ReceiptScannerState());

  // ---------------------------------------------------------------------------
  // Load scanned receipts from DB
  // ---------------------------------------------------------------------------

  Future<void> loadReceipts() async {
    try {
      final rows = await _db.getAllScannedReceipts();
      final receipts = rows.map((row) => ScannedReceipt(
        receiptId: row.receiptId,
        merchantName: row.merchantName,
        totalAmount: row.totalAmount,
        currency: row.currency,
        category: SpendingCategory.values.firstWhere(
          (c) => c.id == row.category,
          orElse: () => SpendingCategory.other,
        ),
        purchaseDate: row.purchaseDate,
        savingsPotentialUAH: row.savingsPotential,
        motivationMessageUA: row.motivationMessage ?? '',
        goalId: row.goalId,
        isImpulseBuy: row.isImpulseBuy,
        scannedAt: row.scannedAt,
        ocrSource: row.ocrSource,
      )).toList();

      state = state.copyWith(
        receipts: receipts,
        stats: _computeStats(receipts),
        weeklySummary: _computeWeeklySummary(receipts),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка завантаження: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Scan a receipt image
  // ---------------------------------------------------------------------------

  Future<void> scanReceipt(String base64Image, {int? goalId}) async {
    state = state.copyWith(isScanning: true, error: null);

    try {
      final mindeeKey = _ref.read(mindeeApiKeyProvider);
      final visionKey = _ref.read(googleVisionApiKeyProvider);

      Map<String, dynamic> parsed;
      String ocrSource;

      // Try Mindee first, fall back to Google Vision
      if (mindeeKey.isNotEmpty) {
        parsed = await _scanWithMindee(base64Image, mindeeKey);
        ocrSource = 'mindee';
      } else if (visionKey.isNotEmpty) {
        final ocrText = await _scanWithGoogleVision(base64Image, visionKey);
        parsed = {'raw_text': ocrText};
        ocrSource = 'google_vision';
      } else {
        // Manual entry fallback
        parsed = {'error': 'No OCR API configured'};
        ocrSource = 'manual';
      }

      // Extract data from parsed result
      final prediction = parsed['prediction'] as Map<String, dynamic>? ?? {};
      final merchantName = (prediction['merchant_name'] ?? 'Невідомий магазин')
          .toString();
      final totalAmount =
          (prediction['total_amount'] ?? 0.0) as double;
      final purchaseDateStr = (prediction['date'] ?? '').toString();

      // Determine category via AI
      final category = await _categorizeWithAI(merchantName, totalAmount);

      // Calculate savings potential
      final savingsPotential = totalAmount * 0.3; // 30% could have been saved
      final motivation = await _generateMotivation(totalAmount, category, goalId);

      final receipt = ScannedReceipt(
        receiptId: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        merchantName: merchantName,
        totalAmount: totalAmount,
        category: category,
        purchaseDate: DateTime.tryParse(purchaseDateStr) ?? DateTime.now(),
        savingsPotentialUAH: savingsPotential,
        motivationMessageUA: motivation,
        goalId: goalId,
        isImpulseBuy: _isImpulseBuy(category, totalAmount),
        scannedAt: DateTime.now(),
        ocrSource: ocrSource,
      );

      // Save to DB
      await _db.insertScannedReceipt(ScannedReceiptsCompanion(
        receiptId: Value(receipt.receiptId),
        merchantName: Value(receipt.merchantName),
        totalAmount: Value(receipt.totalAmount),
        currency: Value(receipt.currency),
        category: Value(receipt.category.id),
        purchaseDate: Value(receipt.purchaseDate),
        savingsPotential: Value(receipt.savingsPotentialUAH),
        motivationMessage: Value(receipt.motivationMessageUA),
        goalId: Value(receipt.goalId),
        isImpulseBuy: Value(receipt.isImpulseBuy),
        scannedAt: Value(receipt.scannedAt),
        ocrSource: Value(receipt.ocrSource),
      ));

      // Award XP for scanning
      await _db.addXP(20, source: 'receipt_scan');

      final updated = [...state.receipts, receipt];
      state = state.copyWith(
        receipts: updated,
        lastScanned: receipt,
        isScanning: false,
        stats: _computeStats(updated),
        weeklySummary: _computeWeeklySummary(updated),
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        error: 'Помилка сканування: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Add manual receipt entry
  // ---------------------------------------------------------------------------

  Future<void> addManualReceipt({
    required String merchantName,
    required double totalAmount,
    required SpendingCategory category,
    int? goalId,
  }) async {
    final savingsPotential = totalAmount * 0.3;
    final motivation =
        await _generateMotivation(totalAmount, category, goalId);

    final receipt = ScannedReceipt(
      receiptId: 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
      merchantName: merchantName,
      totalAmount: totalAmount,
      category: category,
      purchaseDate: DateTime.now(),
      savingsPotentialUAH: savingsPotential,
      motivationMessageUA: motivation,
      goalId: goalId,
      isImpulseBuy: _isImpulseBuy(category, totalAmount),
      scannedAt: DateTime.now(),
      ocrSource: 'manual',
    );

    await _db.insertScannedReceipt(ScannedReceiptsCompanion(
      receiptId: Value(receipt.receiptId),
      merchantName: Value(receipt.merchantName),
      totalAmount: Value(receipt.totalAmount),
      currency: Value(receipt.currency),
      category: Value(receipt.category.id),
      purchaseDate: Value(receipt.purchaseDate),
      savingsPotential: Value(receipt.savingsPotentialUAH),
      motivationMessage: Value(receipt.motivationMessageUA),
      goalId: Value(receipt.goalId),
      isImpulseBuy: Value(receipt.isImpulseBuy),
      scannedAt: Value(receipt.scannedAt),
      ocrSource: Value(receipt.ocrSource),
    ));

    await _db.addXP(10, source: 'receipt_manual');

    final updated = [...state.receipts, receipt];
    state = state.copyWith(
      receipts: updated,
      lastScanned: receipt,
      stats: _computeStats(updated),
      weeklySummary: _computeWeeklySummary(updated),
    );
  }

  // ---------------------------------------------------------------------------
  // Generate AI spending insight
  // ---------------------------------------------------------------------------

  Future<void> generateWeeklyInsight() async {
    state = state.copyWith(isGeneratingInsight: true);

    final openRouter = _ref.read(openRouterServiceProvider);

    final summary = state.weeklySummary;

    try {
      final insight = await openRouter.chat(
        systemPrompt: 'Ти VAULT-17 — кіберпанк AI-асистент додатку NEONCRED. Проаналізуй тижневі витрати користувача і дай пораду. Дай коротку (3-4 речення) аналітику українською: 1. Що найбільше витягує бюджет 2. Як можна заощадити 3. Мотиваційний заклик до заощаджень. Стиль: кіберпанк, використовуй техно-метафори.',
        userPrompt: 'Загалом витрачено: ${summary.totalSpent.toStringAsFixed(0)}₴\nПотенційні заощадження: ${summary.potentialSavings.toStringAsFixed(0)}₴\nІмпульсивних покупок: ${summary.impulseBuyCount} на ${summary.impulseBuyTotal.toStringAsFixed(0)}₴\nКава: ${summary.coffeeTotal.toStringAsFixed(0)}₴\nРесторани: ${summary.diningTotal.toStringAsFixed(0)}₴\nТоп категорія: ${summary.topCategoryLabel} (${summary.topCategoryAmount.toStringAsFixed(0)}₴)',
        temperature: 0.85,
        maxTokens: 512,
      );
      state = state.copyWith(
        isGeneratingInsight: false,
        aiInsight: insight ?? 'Не вдалося згенерувати інсайт',
      );
    } catch (e) {
      state = state.copyWith(
        isGeneratingInsight: false,
        aiInsight: 'Не вдалося згенерувати інсайт: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Delete receipt
  // ---------------------------------------------------------------------------

  Future<void> deleteReceipt(String receiptId) async {
    try {
      await _db.deleteScannedReceipt(receiptId);
      final updated =
          state.receipts.where((r) => r.receiptId != receiptId).toList();
      state = state.copyWith(
        receipts: updated,
        stats: _computeStats(updated),
        weeklySummary: _computeWeeklySummary(updated),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка видалення: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isImpulseBuy(SpendingCategory category, double amount) {
    return category == SpendingCategory.impulse ||
        category == SpendingCategory.coffee ||
        (category == SpendingCategory.dining && amount > 500) ||
        (category == SpendingCategory.shopping && amount > 3000);
  }

  Future<SpendingCategory> _categorizeWithAI(
    String merchantName,
    double amount,
  ) async {
    // Simple rule-based categorization first
    final name = merchantName.toLowerCase();

    if (name.contains('сільпо') || name.contains('атб') ||
        name.contains('новус') || name.contains('billa') ||
        name.contains('караван') || name.contains('varus')) {
      return SpendingCategory.groceries;
    }
    if (name.contains('кав') || name.contains('coffee') ||
        name.contains('starbucks') || name.contains('кофе')) {
      return SpendingCategory.coffee;
    }
    if (name.contains('ресторан') || name.contains('піца') ||
        name.contains('sushi') || name.contains('бургер') ||
        name.contains('mcdonald') || name.contains('kfc')) {
      return SpendingCategory.dining;
    }
    if (name.contains('аптек') || name.contains('фарм') ||
        name.contains('pharmacy')) {
      return SpendingCategory.health;
    }
    if (name.contains('залізн') || name.contains('метро') ||
        name.contains('bus') || name.contains('таксі') ||
        name.contains('bolt') || name.contains('uber')) {
      return SpendingCategory.transport;
    }

    // Could use OpenRouter for smarter categorization
    return SpendingCategory.other;
  }

  Future<String> _generateMotivation(
    double amount,
    SpendingCategory category,
    int? goalId,
  ) async {
    // Try to get linked goal for personalized motivation
    if (goalId != null) {
      try {
        final goals = await _db.getAllGoals();
        final goal = goals.where((g) => g.id == goalId).firstOrNull;
        if (goal != null && goal.targetAmount > 0) {
          final percent = (amount / goal.targetAmount * 100).toStringAsFixed(1);
          return 'Ця покупка ${amount.toStringAsFixed(0)}₴ — це $percent% від ціни "${goal.name}". Ці гроші могли бути у скарбничці!';
        }
      } catch (_) {}
    }

    // Generic motivation based on category
    return switch (category) {
      SpendingCategory.coffee =>
        '${amount.toStringAsFixed(0)}₴ на каву — альтернативно це могла бути частина твоєї мрії!',
      SpendingCategory.dining =>
        '${amount.toStringAsFixed(0)}₴ у ресторані — приготування вдома зекономило б ${amount > 300 ? (amount * 0.6).toStringAsFixed(0) : 'більше'}₴',
      SpendingCategory.impulse =>
        '${amount.toStringAsFixed(0)}₴ імпульсивної покупки — зупинись і подумай, чи це справді треба!',
      SpendingCategory.shopping =>
        '${amount.toStringAsFixed(0)}₴ шопінгу — кожна гривня ближче до цілі, якщо зберегти!',
      _ =>
        '${amount.toStringAsFixed(0)}₴ витрачено — ${amount > 500 ? 'значна сума, яка могла поповнити скарбничку' : 'маленький крок до заощаджень'}',
    };
  }

  ReceiptScannerStats _computeStats(List<ScannedReceipt> receipts) {
    if (receipts.isEmpty) return const ReceiptScannerStats();

    final totalSpent = receipts.fold(0.0, (sum, r) => sum + r.totalAmount);
    final totalSavings =
        receipts.fold(0.0, (sum, r) => sum + r.savingsPotentialUAH);
    final impulseCount = receipts.where((r) => r.isImpulseBuy).length;
    final impulseTotal =
        receipts.where((r) => r.isImpulseBuy).fold(0.0, (sum, r) => sum + r.totalAmount);

    // Top category
    final catTotals = <SpendingCategory, double>{};
    for (final r in receipts) {
      catTotals[r.category] = (catTotals[r.category] ?? 0.0) + r.totalAmount;
    }
    final topEntry =
        catTotals.entries.fold<MapEntry<SpendingCategory, double>?>(
      null,
      (best, e) => best == null || e.value > best.value ? e : best,
    );

    return ReceiptScannerStats(
      totalReceiptsScanned: receipts.length,
      totalSpentUAH: totalSpent,
      totalPotentialSavings: totalSavings,
      impulseBuyCount: impulseCount,
      impulseBuyTotal: impulseTotal,
      avgReceiptAmount: totalSpent / receipts.length,
      topCategory: topEntry?.key ?? SpendingCategory.other,
      topCategoryAmount: topEntry?.value ?? 0.0,
    );
  }

  WeeklySpendingSummary _computeWeeklySummary(List<ScannedReceipt> receipts) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekly = receipts
        .where((r) => r.purchaseDate.isAfter(weekAgo))
        .toList();

    if (weekly.isEmpty) return const WeeklySpendingSummary();

    final totalSpent = weekly.fold(0.0, (sum, r) => sum + r.totalAmount);
    final potentialSavings =
        weekly.fold(0.0, (sum, r) => sum + r.savingsPotentialUAH);
    final impulseCount = weekly.where((r) => r.isImpulseBuy).length;
    final impulseTotal =
        weekly.where((r) => r.isImpulseBuy).fold(0.0, (sum, r) => sum + r.totalAmount);
    final coffeeTotal = weekly
        .where((r) => r.category == SpendingCategory.coffee)
        .fold(0.0, (sum, r) => sum + r.totalAmount);
    final diningTotal = weekly
        .where((r) => r.category == SpendingCategory.dining)
        .fold(0.0, (sum, r) => sum + r.totalAmount);

    // Category breakdown
    final byCategory = <SpendingCategory, double>{};
    for (final r in weekly) {
      byCategory[r.category] = (byCategory[r.category] ?? 0.0) + r.totalAmount;
    }

    final topEntry =
        byCategory.entries.fold<MapEntry<SpendingCategory, double>?>(
      null,
      (best, e) => best == null || e.value > best.value ? e : best,
    );

    return WeeklySpendingSummary(
      totalSpent: totalSpent,
      potentialSavings: potentialSavings,
      byCategory: byCategory,
      impulseBuyCount: impulseCount,
      impulseBuyTotal: impulseTotal,
      coffeeTotal: coffeeTotal,
      diningTotal: diningTotal,
      topCategoryLabel: topEntry?.key.labelUA ?? '',
      topCategoryAmount: topEntry?.value ?? 0.0,
    );
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final receiptScannerProvider =
    StateNotifierProvider<ReceiptScannerNotifier, ReceiptScannerState>((ref) {
  final db = ref.watch(databaseProvider);
  return ReceiptScannerNotifier(ref, db);
});
