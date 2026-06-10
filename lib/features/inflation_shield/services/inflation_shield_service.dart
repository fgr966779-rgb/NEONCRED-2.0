import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// MODELS
// =============================================================================

class InflationShieldItem {
  final String shieldId;
  final double usdUahRate;
  final double eurUahRate;
  final double inflationRate;
  final double totalSavingsUah;
  final double realValueLossUah;
  final double suggestedTopUpUah;
  final String aiAdvice;
  final bool isAlertActive;
  final int xpAwarded;
  final DateTime lastUpdated;
  final DateTime createdAt;

  const InflationShieldItem({
    required this.shieldId,
    this.usdUahRate = 41.5,
    this.eurUahRate = 45.0,
    this.inflationRate = 8.0,
    this.totalSavingsUah = 0,
    this.realValueLossUah = 0,
    this.suggestedTopUpUah = 0,
    this.aiAdvice = '',
    this.isAlertActive = false,
    this.xpAwarded = 0,
    required this.lastUpdated,
    required this.createdAt,
  });

  InflationShieldItem copyWith({
    String? shieldId,
    double? usdUahRate,
    double? eurUahRate,
    double? inflationRate,
    double? totalSavingsUah,
    double? realValueLossUah,
    double? suggestedTopUpUah,
    String? aiAdvice,
    bool? isAlertActive,
    int? xpAwarded,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return InflationShieldItem(
      shieldId: shieldId ?? this.shieldId,
      usdUahRate: usdUahRate ?? this.usdUahRate,
      eurUahRate: eurUahRate ?? this.eurUahRate,
      inflationRate: inflationRate ?? this.inflationRate,
      totalSavingsUah: totalSavingsUah ?? this.totalSavingsUah,
      realValueLossUah: realValueLossUah ?? this.realValueLossUah,
      suggestedTopUpUah: suggestedTopUpUah ?? this.suggestedTopUpUah,
      aiAdvice: aiAdvice ?? this.aiAdvice,
      isAlertActive: isAlertActive ?? this.isAlertActive,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// How much savings will be worth in 1 year due to inflation
  double get projectedLossIn1Year => totalSavingsUah * (inflationRate / 100);

  /// Savings in USD equivalent
  double get savingsInUsd => usdUahRate > 0 ? totalSavingsUah / usdUahRate : 0;

  /// Savings in EUR equivalent
  double get savingsInEur => eurUahRate > 0 ? totalSavingsUah / eurUahRate : 0;

  /// Impact message
  String get impactMessage {
    if (totalSavingsUah <= 0) return 'Введи суму заощаджень для аналізу інфляційного впливу';
    return 'Твої заощадження ${_fmtPrice(totalSavingsUah)} грн -- через рік при ${inflationRate.toStringAsFixed(0)}% інфляції це еквівалентно ${_fmtPrice(totalSavingsUah - projectedLossIn1Year)} грн';
  }
}

class InflationShieldState {
  final InflationShieldItem? shield;
  final bool isLoading;
  final String? error;
  final bool hasShieldBadge;

  const InflationShieldState({
    this.shield,
    this.isLoading = false,
    this.error,
    this.hasShieldBadge = false,
  });

  InflationShieldState copyWith({
    InflationShieldItem? shield,
    bool? isLoading,
    String? error,
    bool? hasShieldBadge,
  }) {
    return InflationShieldState(
      shield: shield ?? this.shield,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasShieldBadge: hasShieldBadge ?? this.hasShieldBadge,
    );
  }
}

// =============================================================================
// NOTIFIER — Inflation Shield Alert Business Logic
// =============================================================================

class InflationShieldNotifier extends StateNotifier<InflationShieldState> {
  final Ref _ref;

  InflationShieldNotifier(this._ref) : super(const InflationShieldState());

  // ---- Initialize Shield ----

  void initShield({double totalSavingsUah = 0}) {
    final now = DateTime.now();
    final shieldId = 'IS-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(5, '0')}';

    final shield = InflationShieldItem(
      shieldId: shieldId,
      totalSavingsUah: totalSavingsUah,
      lastUpdated: now,
      createdAt: now,
    );

    state = state.copyWith(shield: shield);
  }

  // ---- Update Savings Amount ----

  void updateSavings(double totalSavingsUah) {
    final shield = state.shield;
    if (shield == null) {
      initShield(totalSavingsUah: totalSavingsUah);
      return;
    }

    final realValueLoss = totalSavingsUah * (shield.inflationRate / 100);
    final suggestedTopUp = realValueLoss / 12; // Monthly top-up to counter inflation

    final updated = shield.copyWith(
      totalSavingsUah: totalSavingsUah,
      realValueLossUah: realValueLoss,
      suggestedTopUpUah: suggestedTopUp,
      lastUpdated: DateTime.now(),
    );

    state = state.copyWith(shield: updated);
  }

  // ---- Fetch Exchange Rates from TwelveData ----

  Future<void> fetchRates() async {
    state = state.copyWith(isLoading: true);

    try {
      final twelveDataApiKey = _ref.read(twelveDataApiKeyProvider);
      double usdUah = 41.5; // Fallback defaults
      double eurUah = 45.0;

      if (twelveDataApiKey.isNotEmpty) {
        // Fetch USD/UAH
        final usdResponse = await http.get(
          Uri.parse(
            'https://api.twelvedata.com/price?symbol=USD/UAH&apikey=$twelveDataApiKey',
          ),
        );
        if (usdResponse.statusCode == 200) {
          final data = json.decode(usdResponse.body);
          if (data['price'] != null) {
            usdUah = double.tryParse(data['price'].toString()) ?? usdUah;
          }
        }

        // Fetch EUR/UAH
        final eurResponse = await http.get(
          Uri.parse(
            'https://api.twelvedata.com/price?symbol=EUR/UAH&apikey=$twelveDataApiKey',
          ),
        );
        if (eurResponse.statusCode == 200) {
          final data = json.decode(eurResponse.body);
          if (data['price'] != null) {
            eurUah = double.tryParse(data['price'].toString()) ?? eurUah;
          }
        }
      }

      final shield = state.shield;
      final savings = shield?.totalSavingsUah ?? 0;
      final inflation = shield?.inflationRate ?? 8.0;
      final realValueLoss = savings * (inflation / 100);
      final suggestedTopUp = realValueLoss / 12;
      final isActive = savings > 0 && (inflation >= 5);

      final now = DateTime.now();
      final shieldId = shield?.shieldId ??
          'IS-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(5, '0')}';

      final updated = InflationShieldItem(
        shieldId: shieldId,
        usdUahRate: usdUah,
        eurUahRate: eurUah,
        inflationRate: inflation,
        totalSavingsUah: savings,
        realValueLossUah: realValueLoss,
        suggestedTopUpUah: suggestedTopUp,
        isAlertActive: isActive,
        lastUpdated: now,
        createdAt: shield?.createdAt ?? now,
      );

      state = state.copyWith(
        shield: updated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Помилка отримання курсів: $e',
      );
    }
  }

  // ---- Update Inflation Rate ----

  void updateInflationRate(double rate) {
    final shield = state.shield;
    if (shield == null) return;

    final realValueLoss = shield.totalSavingsUah * (rate / 100);
    final suggestedTopUp = realValueLoss / 12;

    final updated = shield.copyWith(
      inflationRate: rate,
      realValueLossUah: realValueLoss,
      suggestedTopUpUah: suggestedTopUp,
      isAlertActive: shield.totalSavingsUah > 0 && rate >= 5,
      lastUpdated: DateTime.now(),
    );

    state = state.copyWith(shield: updated);
  }

  // ---- Record Anti-Inflation Deposit (+20 XP) ----

  void recordAntiInflationDeposit(double amountUah) {
    final shield = state.shield;
    if (shield == null) return;

    final updated = shield.copyWith(
      totalSavingsUah: shield.totalSavingsUah + amountUah,
      xpAwarded: shield.xpAwarded + 20,
      lastUpdated: DateTime.now(),
    );

    state = state.copyWith(
      shield: updated,
      hasShieldBadge: updated.xpAwarded >= 100,
    );

    _awardXP(20, source: 'inflation_shield_deposit');
  }

  // ---- AI Advice via OpenRouter ----

  Future<void> generateAdvice() async {
    final shield = state.shield;
    if (shield == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt:
            'Ти -- Інфляційний Щит. Аналізуй вплив інфляції на заощадження та пропонуй стратегії захисту. '
            'Стиль: кіберпанк-фінансист. Використовуй українську мову. '
            'Дай коротку пораду (2-3 речення): як захистити заощадження від інфляції, чи варто конвертувати в валюту. '
            'Не додавай зайвих пояснень.',
        userPrompt:
            'Заощадження: ${_fmtPrice(shield.totalSavingsUah)} грн, '
            'USD/UAH: ${shield.usdUahRate.toStringAsFixed(2)}, '
            'EUR/UAH: ${shield.eurUahRate.toStringAsFixed(2)}, '
            'Інфляція: ${shield.inflationRate.toStringAsFixed(1)}%, '
            'Втрати за рік: ${_fmtPrice(shield.projectedLossIn1Year)} грн, '
            'Рекомендація місячного поповнення: ${_fmtPrice(shield.suggestedTopUpUah)} грн.',
        temperature: 0.8,
        maxTokens: 300,
      );

      final updated = shield.copyWith(aiAdvice: response ?? _fallbackAdvice(shield));
      state = state.copyWith(
        shield: updated,
        isLoading: false,
      );
    } catch (_) {
      final updated = shield.copyWith(aiAdvice: _fallbackAdvice(shield));
      state = state.copyWith(
        shield: updated,
        isLoading: false,
      );
    }
  }

  // ---- XP Awarding ----

  void _awardXP(int amount, {String source = 'inflation_shield'}) {
    try {
      final db = _ref.read(databaseProvider);
      db.addXP(amount, source: source);
    } catch (_) {}
  }

  // ---- Clear Error ----

  void clearError() {
    state = state.copyWith(error: null);
  }

  // ---- Fallback Advice ----

  String _fallbackAdvice(InflationShieldItem shield) {
    if (shield.totalSavingsUah <= 0) {
      return 'Почни заощаджувати, щоб активувати Інфляційний Щит. Навіть малі суми кращі за нічого.';
    }
    if (shield.inflationRate > 10) {
      return 'Висока інфляція! Рекомендуємо конвертувати частину заощаджень у валюту. '
          'Щомісячне поповнення ${_fmtPrice(shield.suggestedTopUpUah)} грн компенсує знецінення.';
    }
    return 'Щомісячне поповнення ${_fmtPrice(shield.suggestedTopUpUah)} грн допоможе зберегти купівельну спроможність. '
        'Розглянь часткову конвертацію у USD/EUR для диверсифікації.';
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

// =============================================================================
// PROVIDER
// =============================================================================

final inflationShieldProvider =
    StateNotifierProvider<InflationShieldNotifier, InflationShieldState>(
  (ref) => InflationShieldNotifier(ref),
);
