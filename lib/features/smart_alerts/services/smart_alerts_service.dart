import 'dart:io';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../core/utils/serp_api_service.dart';
import '../../../data/database.dart';

// =============================================================================
// Smart Price Alert v2 — LTV 2026-2030 Phase 1
// =============================================================================
//
// Persistent price alerts linked to goals with:
//   - 24h aggressive caching (SerpAPI Free Tier: 100 req/month)
//   - Batch-oriented price checking (deduplicate product queries)
//   - Local push notifications via flutter_local_notifications
//   - XP reward for creating alerts (+5 XP)
//   - CASCADE deletion when parent goal is removed
//
// APIs:  SerpAPI Shopping (price data) + OpenRouter (AI context)
// =============================================================================

// -----------------------------------------------------------------------------
// Alert status enum
// -----------------------------------------------------------------------------

enum AlertStatus {
  active('active', 'Активний'),
  triggered('triggered', 'Сприйнятий'),
  disabled('disabled', 'Вимкнений');

  final String id;
  final String labelUA;
  const AlertStatus(this.id, this.labelUA);

  static AlertStatus fromBool({required bool isTriggered, required bool isNotifying}) {
    if (isTriggered) return AlertStatus.triggered;
    if (!isNotifying) return AlertStatus.disabled;
    return AlertStatus.active;
  }
}

// -----------------------------------------------------------------------------
// Alert urgency enum
// -----------------------------------------------------------------------------

enum AlertUrgency {
  urgent('urgent', 'Терміново'),
  soon('soon', 'Скоро'),
  can_wait('can_wait', 'Може зачекати');

  final String id;
  final String labelUA;
  const AlertUrgency(this.id, this.labelUA);
}

// -----------------------------------------------------------------------------
// Data model — wraps a PriceAlert DB row with computed fields
// -----------------------------------------------------------------------------

class PriceAlertModel {
  final int id;
  final int goalId;
  final String productQuery;
  final double targetPrice;
  final double currentPrice;
  final bool isTriggered;
  final bool isNotifying;
  final DateTime? lastCheckedAt;
  final DateTime createdAt;
  final AlertStatus status;
  final String? aiContext;

  const PriceAlertModel({
    required this.id,
    required this.goalId,
    required this.productQuery,
    required this.targetPrice,
    this.currentPrice = 0.0,
    this.isTriggered = false,
    this.isNotifying = true,
    this.lastCheckedAt,
    required this.createdAt,
    this.status = AlertStatus.active,
    this.aiContext,
  });

  factory PriceAlertModel.fromDb(PriceAlert row, {String? aiContext}) {
    return PriceAlertModel(
      id: row.id,
      goalId: row.goalId,
      productQuery: row.productQuery,
      targetPrice: row.targetPrice,
      currentPrice: row.currentPrice,
      isTriggered: row.isTriggered,
      isNotifying: row.isNotifying,
      lastCheckedAt: row.lastCheckedAt,
      createdAt: row.createdAt,
      status: AlertStatus.fromBool(
        isTriggered: row.isTriggered,
        isNotifying: row.isNotifying,
      ),
      aiContext: aiContext,
    );
  }

  /// Returns true if this alert was checked within the last 24 hours.
  bool get wasCheckedRecently {
    if (lastCheckedAt == null) return false;
    return DateTime.now().difference(lastCheckedAt!).inHours < 24;
  }

  /// Returns true if the current price is at or below the target.
  bool get isPriceAtTarget => currentPrice > 0 && currentPrice <= targetPrice;

  PriceAlertModel copyWith({
    double? currentPrice,
    bool? isTriggered,
    bool? isNotifying,
    DateTime? lastCheckedAt,
    String? aiContext,
  }) {
    return PriceAlertModel(
      id: id,
      goalId: goalId,
      productQuery: productQuery,
      targetPrice: targetPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      isTriggered: isTriggered ?? this.isTriggered,
      isNotifying: isNotifying ?? this.isNotifying,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      createdAt: createdAt,
      status: AlertStatus.fromBool(
        isTriggered: isTriggered ?? this.isTriggered,
        isNotifying: isNotifying ?? this.isNotifying,
      ),
      aiContext: aiContext ?? this.aiContext,
    );
  }
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class SmartAlertsState {
  final List<PriceAlertModel> alerts;
  final int serpApiCallsThisMonth;
  final int serpApiCallsToday;
  final bool isLoading;
  final String? error;

  const SmartAlertsState({
    this.alerts = const [],
    this.serpApiCallsThisMonth = 0,
    this.serpApiCallsToday = 0,
    this.isLoading = false,
    this.error,
  });

  SmartAlertsState copyWith({
    List<PriceAlertModel>? alerts,
    int? serpApiCallsThisMonth,
    int? serpApiCallsToday,
    bool? isLoading,
    String? error,
  }) {
    return SmartAlertsState(
      alerts: alerts ?? this.alerts,
      serpApiCallsThisMonth:
          serpApiCallsThisMonth ?? this.serpApiCallsThisMonth,
      serpApiCallsToday: serpApiCallsToday ?? this.serpApiCallsToday,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<PriceAlertModel> get activeAlerts =>
      alerts.where((a) => a.status == AlertStatus.active).toList();

  List<PriceAlertModel> get triggeredAlerts =>
      alerts.where((a) => a.status == AlertStatus.triggered).toList();

  /// Whether we've hit the SerpAPI free tier limit (100/month).
  bool get isSerpApiLimitReached => serpApiCallsThisMonth >= 95;

  /// Remaining SerpAPI calls this month.
  int get serpApiCallsRemaining => (95 - serpApiCallsThisMonth).clamp(0, 95);
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class SmartAlertsNotifier extends StateNotifier<SmartAlertsState> {
  final Ref _ref;

  /// SerpAPI Free Tier limit.
  static const int _serpApiMonthlyLimit = 100;

  /// Safety margin — stop at 95 to avoid hitting the hard limit.
  static const int _serpApiSafetyLimit = 95;

  /// Minimum interval between checks for the same alert (24 hours).
  static const Duration _checkInterval = Duration(hours: 24);

  SmartAlertsNotifier(this._ref) : super(const SmartAlertsState());

  // ===========================================================================
  // Public API — CRUD
  // ===========================================================================

  /// Load all price alerts from the database.
  Future<void> loadAlerts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final database = _ref.read(databaseProvider);
      final rows = await database.getAllPriceAlerts();
      final models = rows.map((r) => PriceAlertModel.fromDb(r)).toList();

      state = state.copyWith(alerts: models, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Create a new price alert linked to a goal.
  Future<void> createAlert({
    required int goalId,
    required String productQuery,
    required double targetPrice,
  }) async {
    if (targetPrice <= 0) return;

    try {
      final database = _ref.read(databaseProvider);

      await database.insertPriceAlert(
        PriceAlertsCompanion.insert(
          goalId: goalId,
          productQuery: productQuery,
          targetPrice: targetPrice,
        ),
      );

      // Award +5 XP for setting up an alert
      await database.addXP(5, source: 'smart_price_alert_created');

      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a price alert.
  Future<void> deleteAlert(int alertId) async {
    try {
      final database = _ref.read(databaseProvider);
      await database.deletePriceAlert(alertId);
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Toggle the notification status of an alert.
  Future<void> toggleAlertNotifications(int alertId, bool isNotifying) async {
    try {
      final database = _ref.read(databaseProvider);
      await database.updatePriceAlert(
        alertId,
        PriceAlertsCompanion(isNotifying: Value(isNotifying)),
      );
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Dismiss a triggered alert (mark as read / disable it).
  Future<void> dismissTriggeredAlert(int alertId) async {
    try {
      final database = _ref.read(databaseProvider);
      await database.updatePriceAlert(
        alertId,
        PriceAlertsCompanion(
          isNotifying: const Value(false),
        ),
      );
      await loadAlerts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ===========================================================================
  // Public API — Price checking
  // ===========================================================================

  /// Check all active alerts for price changes (batch-oriented).
  ///
  /// - Skips alerts checked within the last 24 hours (aggressive caching).
  /// - Deduplicates product queries to minimize SerpAPI calls.
  /// - Respects SerpAPI free tier limit (100/month).
  /// - Triggers local notification when price drops to target.
  Future<void> checkActiveAlerts() async {
    if (state.isSerpApiLimitReached) {
      debugPrint('[SmartAlert] SerpAPI monthly limit reached — skipping check');
      state = state.copyWith(
        error: 'SerpAPI ліміт вичерпано (${_serpApiMonthlyLimit} запитів/місяць)',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final serpApi = _ref.read(serpApiServiceProvider);
      if (!serpApi.isConfigured) {
        state = state.copyWith(
          isLoading: false,
          error: 'SerpAPI не налаштований — перевірте API ключ',
        );
        return;
      }

      final database = _ref.read(databaseProvider);

      // 1. Filter: only active, non-triggered alerts that need checking
      final needsCheck = state.alerts.where((a) {
        if (a.isTriggered || !a.isNotifying) return false;
        return !a.wasCheckedRecently;
      }).toList();

      if (needsCheck.isEmpty) {
        state = state.copyWith(isLoading: false);
        return;
      }

      // 2. Deduplicate product queries (batch optimization)
      final uniqueQueries = <String, List<PriceAlertModel>>{};
      for (final alert in needsCheck) {
        final key = alert.productQuery.toLowerCase().trim();
        uniqueQueries.putIfAbsent(key, () => []).add(alert);
      }

      // 3. Check each unique query (respecting rate limit)
      int callsUsed = 0;
      final updatedAlerts = <PriceAlertModel>[];
      final triggeredAlerts = <PriceAlertModel>[];

      for (final entry in uniqueQueries.entries) {
        if (callsUsed + state.serpApiCallsThisMonth >= _serpApiSafetyLimit) {
          debugPrint('[SmartAlert] Approaching SerpAPI limit — stopping batch');
          break;
        }

        final query = entry.key;
        final alertsForQuery = entry.value;

        // Search SerpAPI
        final results = await serpApi.searchShopping(
          query,
          numResults: 5,
        );
        callsUsed++;

        // Find the lowest price
        double lowestPrice = -1.0;
        String bestStore = '';

        for (final r in results) {
          if (r.price > 0 && (lowestPrice < 0 || r.price < lowestPrice)) {
            lowestPrice = r.price;
            bestStore = r.store;
          }
        }

        // Update all alerts sharing this query
        for (final alert in alertsForQuery) {
          final wasTriggered =
              lowestPrice > 0 && lowestPrice <= alert.targetPrice;

          final updated = alert.copyWith(
            currentPrice: lowestPrice >= 0 ? lowestPrice : alert.currentPrice,
            isTriggered: wasTriggered,
            lastCheckedAt: DateTime.now(),
          );

          // Persist to database
          await database.updatePriceAlert(
            alert.id,
            PriceAlertsCompanion(
              currentPrice: Value(updated.currentPrice),
              isTriggered: Value(updated.isTriggered),
              lastCheckedAt: Value(updated.lastCheckedAt),
            ),
          );

          updatedAlerts.add(updated);

          if (wasTriggered) {
            triggeredAlerts.add(updated);
          }
        }
      }

      // 4. Send local notifications for triggered alerts
      for (final triggered in triggeredAlerts) {
        await _sendLocalNotification(
          title: 'SMART PRICE ALERT',
          body:
              'Ціна на ${triggered.productQuery} впала до ${triggered.currentPrice.toStringAsFixed(0)} грн! '
              'Твоя мішень: ${triggered.targetPrice.toStringAsFixed(0)} грн. Пора купувати!',
        );
      }

      // 5. Reload from database and update state
      await loadAlerts();

      state = state.copyWith(
        serpApiCallsToday: state.serpApiCallsToday + callsUsed,
        serpApiCallsThisMonth: state.serpApiCallsThisMonth + callsUsed,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Force-check a single alert regardless of 24h cache (for testing).
  Future<PriceAlertModel?> forceCheckAlert(int alertId) async {
    try {
      final alert = state.alerts.where((a) => a.id == alertId).firstOrNull;
      if (alert == null) return null;

      final serpApi = _ref.read(serpApiServiceProvider);
      final database = _ref.read(databaseProvider);

      final results = await serpApi.searchShopping(
        alert.productQuery,
        numResults: 5,
      );

      double lowestPrice = -1.0;
      for (final r in results) {
        if (r.price > 0 && (lowestPrice < 0 || r.price < lowestPrice)) {
          lowestPrice = r.price;
        }
      }

      final wasTriggered =
          lowestPrice > 0 && lowestPrice <= alert.targetPrice;

      await database.updatePriceAlert(
        alertId,
        PriceAlertsCompanion(
          currentPrice: Value(lowestPrice >= 0 ? lowestPrice : alert.currentPrice),
          isTriggered: Value(wasTriggered),
          lastCheckedAt: Value(DateTime.now()),
        ),
      );

      if (wasTriggered) {
        await _sendLocalNotification(
          title: 'SMART PRICE ALERT',
          body:
              'Ціна на ${alert.productQuery} впала до ${lowestPrice.toStringAsFixed(0)} грн! '
              'Твоя мішень: ${alert.targetPrice.toStringAsFixed(0)} грн. Пора купувати!',
        );
      }

      await loadAlerts();
      return state.alerts.where((a) => a.id == alertId).firstOrNull;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ===========================================================================
  // Public API — AI context
  // ===========================================================================

  /// Generate AI context for a triggered alert using OpenRouter.
  Future<void> generateAlertContext(int alertId) async {
    final alert = state.alerts.where((a) => a.id == alertId).firstOrNull;
    if (alert == null) return;

    final openRouter = _ref.read(openRouterServiceProvider);

    try {
      final result = await openRouter.chat(
        systemPrompt:
            'Ти VAULT-17 — кіберпанк AI-асистент NEONCRED. Генеруєш короткі рекомендації '
            'щодо покупки українською мовою. Без маркдауну, лише текст.',
        userPrompt:
            'Товар "${alert.productQuery}" впав у ціні до ${alert.currentPrice.toStringAsFixed(0)} грн '
            '(ціль: ${alert.targetPrice.toStringAsFixed(0)} грн). '
            'Чи варто купувати зараз? Дай коротку відповідь 1-2 речення.',
        temperature: 0.7,
        maxTokens: 150,
      );

      if (result != null && result.trim().isNotEmpty) {
        final updatedAlerts = state.alerts.map((a) {
          if (a.id == alertId) return a.copyWith(aiContext: result.trim());
          return a;
        }).toList();
        state = state.copyWith(alerts: updatedAlerts);
      }
    } catch (_) {
      // Silent fail for AI context
    }
  }

  // ===========================================================================
  // Test alert — for Debug Tools
  // ===========================================================================

  /// Send a test notification without waiting for a real price change.
  Future<void> sendTestNotification() async {
    await _sendLocalNotification(
      title: 'TEST ALERT',
      body: 'Це тестове сповіщення Smart Price Alert. Якщо бачиш — все працює!',
    );
  }

  // ===========================================================================
  // Private — Local notifications
  // ===========================================================================

  static FlutterLocalNotificationsPlugin? _notificationPlugin;

  Future<void> _initNotifications() async {
    if (_notificationPlugin != null) return;

    _notificationPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationPlugin!.initialize(settings);
  }

  Future<void> _sendLocalNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _initNotifications();

      const androidDetails = AndroidNotificationDetails(
        'smart_price_alerts',
        'Smart Price Alerts',
        channelDescription: 'Сповіщення про падіння цін',
        importance: Importance.high,
        priority: Priority.high,
        enableLights: true,
        ledColor: const Color(0xFF00F0FF),
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationPlugin!.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('[SmartAlert] Notification failed: $e');
    }
  }
}

// =============================================================================
// Provider
// =============================================================================

final smartAlertsProvider =
    StateNotifierProvider<SmartAlertsNotifier, SmartAlertsState>(
  (ref) => SmartAlertsNotifier(ref),
);
