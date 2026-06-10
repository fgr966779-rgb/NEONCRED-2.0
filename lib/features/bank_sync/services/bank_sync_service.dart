import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// BankProvider — which banking API is connected
// ---------------------------------------------------------------------------

enum BankProvider {
  privatbank,
  plaid,
  mono, // monobank — future support
}

extension BankProviderX on BankProvider {
  String get labelUA => switch (this) {
        BankProvider.privatbank => 'ПриватБанк',
        BankProvider.plaid => 'Plaid',
        BankProvider.mono => 'Monobank',
      };

  String get iconEmoji => switch (this) {
        BankProvider.privatbank => '\u{1F3E6}',
        BankProvider.plaid => '\u{1F517}',
        BankProvider.mono => '\u{1F4F1}',
      };
}

// ---------------------------------------------------------------------------
// SyncStatus — current synchronization state
// ---------------------------------------------------------------------------

enum SyncStatus {
  disconnected,
  connecting,
  connected,
  syncing,
  synced,
  error,
}

extension SyncStatusX on SyncStatus {
  String get labelUA => switch (this) {
        SyncStatus.disconnected => 'Не підключено',
        SyncStatus.connecting => 'Підключення...',
        SyncStatus.connected => 'Підключено',
        SyncStatus.syncing => 'Синхронізація...',
        SyncStatus.synced => 'Синхронізовано',
        SyncStatus.error => 'Помилка',
      };

  String get iconEmoji => switch (this) {
        SyncStatus.disconnected => '\u{1F534}',
        SyncStatus.connecting => '\u{1F7E1}',
        SyncStatus.connected => '\u{1F7E2}',
        SyncStatus.syncing => '\u{1F504}',
        SyncStatus.synced => '\u{2705}',
        SyncStatus.error => '\u{274C}',
      };
}

// ---------------------------------------------------------------------------
// BankTransaction — a single synced transaction
// ---------------------------------------------------------------------------

class BankTransaction {
  final String transactionId;
  final double amount;
  final String currency;
  final String description;
  final String category;
  final DateTime date;
  final bool isIncome;
  final double? roundUpAmount;

  const BankTransaction({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.category,
    required this.date,
    required this.isIncome,
    this.roundUpAmount,
  });
}

// ---------------------------------------------------------------------------
// AutoSaveRule — a rule for automatic savings
// ---------------------------------------------------------------------------

class AutoSaveRule {
  final String id;
  final AutoSaveRuleType ruleType;
  final double value; // percentage for income, amount for round-up
  final int? goalId; // which goal to auto-deposit to (null = split across all)
  final bool isActive;

  const AutoSaveRule({
    required this.id,
    required this.ruleType,
    required this.value,
    this.goalId,
    this.isActive = true,
  });
}

enum AutoSaveRuleType {
  incomePercentage, // save X% of every income
  roundUp, // round up purchases to nearest 10/50/100 UAH
  fixedWeekly, // fixed weekly auto-deposit
  triggerThreshold, // save when balance exceeds X
}

extension AutoSaveRuleTypeX on AutoSaveRuleType {
  String get labelUA => switch (this) {
        AutoSaveRuleType.incomePercentage => '% від надходжень',
        AutoSaveRuleType.roundUp => 'Round-Up округлення',
        AutoSaveRuleType.fixedWeekly => 'Фіксований тиждень',
        AutoSaveRuleType.triggerThreshold => 'Поріг балансу',
      };

  String get descriptionUA => switch (this) {
        AutoSaveRuleType.incomePercentage =>
          'Автоматично відкладати % від кожного надходження',
        AutoSaveRuleType.roundUp =>
          'Округлювати покупки до найближчої суми і різницю на ціль',
        AutoSaveRuleType.fixedWeekly =>
          'Фіксована сума щотижня автоматично',
        AutoSaveRuleType.triggerThreshold =>
          'Відкладати коли баланс перевищує поріг',
      };
}

// ---------------------------------------------------------------------------
// BankSyncStats — aggregated statistics
// ---------------------------------------------------------------------------

class BankSyncStats {
  final double totalAutoSaved;
  final double totalRoundUp;
  final int totalTransactions;
  final int totalAutoDeposits;
  final double averageRoundUp;
  final DateTime? lastSyncAt;

  const BankSyncStats({
    this.totalAutoSaved = 0.0,
    this.totalRoundUp = 0.0,
    this.totalTransactions = 0,
    this.totalAutoDeposits = 0,
    this.averageRoundUp = 0.0,
    this.lastSyncAt,
  });

  BankSyncStats copyWith({
    double? totalAutoSaved,
    double? totalRoundUp,
    int? totalTransactions,
    int? totalAutoDeposits,
    double? averageRoundUp,
    DateTime? lastSyncAt,
  }) {
    return BankSyncStats(
      totalAutoSaved: totalAutoSaved ?? this.totalAutoSaved,
      totalRoundUp: totalRoundUp ?? this.totalRoundUp,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      totalAutoDeposits: totalAutoDeposits ?? this.totalAutoDeposits,
      averageRoundUp: averageRoundUp ?? this.averageRoundUp,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}

// ---------------------------------------------------------------------------
// BankSyncState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class BankSyncState {
  final SyncStatus syncStatus;
  final BankProvider? connectedBank;
  final List<BankTransaction> recentTransactions;
  final List<AutoSaveRule> autoSaveRules;
  final BankSyncStats stats;
  final bool isLoading;
  final String? error;

  const BankSyncState({
    this.syncStatus = SyncStatus.disconnected,
    this.connectedBank,
    this.recentTransactions = const [],
    this.autoSaveRules = const [],
    this.stats = const BankSyncStats(),
    this.isLoading = false,
    this.error,
  });

  BankSyncState copyWith({
    SyncStatus? syncStatus,
    BankProvider? connectedBank,
    List<BankTransaction>? recentTransactions,
    List<AutoSaveRule>? autoSaveRules,
    BankSyncStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return BankSyncState(
      syncStatus: syncStatus ?? this.syncStatus,
      connectedBank: connectedBank ?? this.connectedBank,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      autoSaveRules: autoSaveRules ?? this.autoSaveRules,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// BankSyncNotifier — core logic & API integration
// ---------------------------------------------------------------------------

class BankSyncNotifier extends StateNotifier<BankSyncState> {
  final Ref _ref;

  static const String _privatBankBaseUrl =
      'https://acp.privatbank.ua/api-proxy';

  BankSyncNotifier(this._ref) : super(const BankSyncState());

  // =========================================================================
  // Public API
  // =========================================================================

  /// Connect to PrivatBank using merchant ID and password (HMAC-SHA256).
  Future<bool> connectPrivatBank({
    required String merchantId,
    required String password,
    required String cardNumber,
  }) async {
    state = state.copyWith(
      syncStatus: SyncStatus.connecting,
      isLoading: true,
      error: null,
    );

    try {
      // PrivatBank API: Get card balance
      final balance = await _fetchPrivatBankBalance(
        merchantId: merchantId,
        password: password,
        cardNumber: cardNumber,
      );

      if (balance != null) {
        state = state.copyWith(
          syncStatus: SyncStatus.connected,
          connectedBank: BankProvider.privatbank,
          isLoading: false,
        );

        // Save connection to database
        final database = _ref.read(databaseProvider);
        await database.insertBankSyncConfig(
          BankSyncConfigsCompanion.insert(
            provider: 'privatbank',
            accessToken: merchantId,
            refreshToken: Value(password),
            accountMask: Value(cardNumber.substring(cardNumber.length - 4)),
          ),
        );

        return true;
      } else {
        state = state.copyWith(
          syncStatus: SyncStatus.error,
          isLoading: false,
          error: 'Не вдалося підключитися до ПриватБанк. Перевірте дані.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Connect to Plaid (international banks).
  Future<bool> connectPlaid({
    required String publicToken,
    required String accountId,
  }) async {
    state = state.copyWith(
      syncStatus: SyncStatus.connecting,
      isLoading: true,
      error: null,
    );

    try {
      // Plaid API: Exchange public token for access token
      final success = await _exchangePlaidToken(
        publicToken: publicToken,
      );

      if (success) {
        state = state.copyWith(
          syncStatus: SyncStatus.connected,
          connectedBank: BankProvider.plaid,
          isLoading: false,
        );

        final database = _ref.read(databaseProvider);
        await database.insertBankSyncConfig(
          BankSyncConfigsCompanion.insert(
            provider: 'plaid',
            accessToken: publicToken,
            accountId: Value(accountId),
          ),
        );

        return true;
      } else {
        state = state.copyWith(
          syncStatus: SyncStatus.error,
          isLoading: false,
          error: 'Plaid підключення не вдалося.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Synchronize recent transactions from the connected bank.
  Future<void> syncTransactions() async {
    if (state.syncStatus != SyncStatus.connected &&
        state.syncStatus != SyncStatus.synced) {
      return;
    }

    state = state.copyWith(syncStatus: SyncStatus.syncing, isLoading: true);

    try {
      final database = _ref.read(databaseProvider);
      final configs = await database.getAllBankSyncConfigs();

      if (configs.isEmpty) {
        state = state.copyWith(
          syncStatus: SyncStatus.disconnected,
          isLoading: false,
        );
        return;
      }

      final config = configs.first;
      List<BankTransaction> transactions;

      switch (config.provider) {
        case 'privatbank':
          transactions = await _fetchPrivatBankTransactions(config);
          break;
        case 'plaid':
          transactions = await _fetchPlaidTransactions(config);
          break;
        default:
          transactions = [];
      }

      // Process auto-save rules
      final autoSavedTransactions =
          await _processAutoSaveRules(transactions);

      final updatedStats = _computeStats(
        transactions,
        autoSavedTransactions,
      );

      state = state.copyWith(
        syncStatus: SyncStatus.synced,
        recentTransactions: transactions,
        stats: updatedStats,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        syncStatus: SyncStatus.error,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add an auto-save rule.
  void addAutoSaveRule(AutoSaveRule rule) {
    final rules = [...state.autoSaveRules, rule];
    state = state.copyWith(autoSaveRules: rules);
  }

  /// Remove an auto-save rule by id.
  void removeAutoSaveRule(String ruleId) {
    final rules =
        state.autoSaveRules.where((r) => r.id != ruleId).toList();
    state = state.copyWith(autoSaveRules: rules);
  }

  /// Toggle auto-save rule active state.
  void toggleAutoSaveRule(String ruleId) {
    final rules = state.autoSaveRules.map((r) {
      if (r.id == ruleId) {
        return AutoSaveRule(
          id: r.id,
          ruleType: r.ruleType,
          value: r.value,
          goalId: r.goalId,
          isActive: !r.isActive,
        );
      }
      return r;
    }).toList();
    state = state.copyWith(autoSaveRules: rules);
  }

  /// Calculate round-up amount for a purchase.
  double calculateRoundUp(double purchaseAmount, {double roundTo = 50.0}) {
    if (purchaseAmount <= 0 || roundTo <= 0) return 0.0;
    final roundedUp = (purchaseAmount / roundTo).ceil() * roundTo;
    return roundedUp - purchaseAmount;
  }

  /// Disconnect the bank.
  Future<void> disconnect() async {
    final database = _ref.read(databaseProvider);
    final configs = await database.getAllBankSyncConfigs();
    for (final config in configs) {
      await database.deleteBankSyncConfig(config);
    }

    state = const BankSyncState();
  }

  /// Load existing bank connection from database.
  Future<void> loadExistingConnection() async {
    try {
      final database = _ref.read(databaseProvider);
      final configs = await database.getAllBankSyncConfigs();

      if (configs.isNotEmpty) {
        final config = configs.first;
        final provider = config.provider == 'privatbank'
            ? BankProvider.privatbank
            : BankProvider.plaid;

        state = state.copyWith(
          syncStatus: SyncStatus.connected,
          connectedBank: provider,
        );

        // Auto-sync on load
        await syncTransactions();
      }
    } catch (_) {
      // Silent fail — just stay disconnected
    }
  }

  // =========================================================================
  // PrivatBank API (HMAC-SHA256)
  // =========================================================================

  Future<double?> _fetchPrivatBankBalance({
    required String merchantId,
    required String password,
    required String cardNumber,
  }) async {
    try {
      final uri = Uri.parse('$_privatBankBaseUrl/balance');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json;charset=utf-8',
          'Accept': 'application/json',
          'Authorization': 'Bearer $merchantId|$password',
        },
        body: jsonEncode({
          'card_number': cardNumber,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final balance = body['balance'] as num?;
        return balance?.toDouble();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<BankTransaction>> _fetchPrivatBankTransactions(
    BankSyncConfig config,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));

      final uri = Uri.parse('$_privatBankBaseUrl/statement');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json;charset=utf-8',
          'Accept': 'application/json',
          'Authorization':
              'Bearer ${config.accessToken}|${config.refreshToken}',
        },
        body: jsonEncode({
          'card_number': config.accountMask,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(now),
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final statements =
            body['statements'] as List<dynamic>? ?? [];
        return statements.map((dynamic e) => _parsePrivatBankTransaction(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  BankTransaction _parsePrivatBankTransaction(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final isIncome = amount > 0;

    // Calculate round-up for purchases
    double? roundUp;
    if (!isIncome) {
      roundUp = calculateRoundUp(amount.abs());
    }

    return BankTransaction(
      transactionId: json['id']?.toString() ?? '',
      amount: amount,
      currency: json['currency']?.toString() ?? 'UAH',
      description: json['description']?.toString() ?? 'Транзакція',
      category: _categorizePrivatBank(
        json['description']?.toString() ?? '',
      ),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.now(),
      isIncome: isIncome,
      roundUpAmount: roundUp,
    );
  }

  String _categorizePrivatBank(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('atm') || lower.contains('банкомат')) {
      return 'cash';
    } else if (lower.contains('market') ||
        lower.contains('сильпо') ||
        lower.contains('атб') ||
        lower.contains('новус')) {
      return 'groceries';
    } else if (lower.contains('cafe') ||
        lower.contains('кафе') ||
        lower.contains('ресторан')) {
      return 'dining';
    } else if (lower.contains('fuel') || lower.contains('заправка')) {
      return 'transport';
    } else if (lower.contains('salary') || lower.contains('зарплата')) {
      return 'income';
    }
    return 'other';
  }

  // =========================================================================
  // Plaid API
  // =========================================================================

  Future<bool> _exchangePlaidToken({
    required String publicToken,
  }) async {
    // In production: call your backend to exchange the public token
    // For now, simulate successful connection
    return true;
  }

  Future<List<BankTransaction>> _fetchPlaidTransactions(
    BankSyncConfig config,
  ) async {
    // In production: call your backend which uses the Plaid access token
    // to fetch transactions from the Plaid API
    // Endpoint: GET /api/transactions/get
    return [];
  }

  // =========================================================================
  // Auto-save rule processing
  // =========================================================================

  Future<List<BankTransaction>> _processAutoSaveRules(
    List<BankTransaction> transactions,
  ) async {
    final autoSaved = <BankTransaction>[];
    final database = _ref.read(databaseProvider);

    for (final rule in state.autoSaveRules) {
      if (!rule.isActive) continue;

      for (final tx in transactions) {
        double? autoSaveAmount;

        switch (rule.ruleType) {
          case AutoSaveRuleType.incomePercentage:
            if (tx.isIncome) {
              autoSaveAmount = tx.amount * (rule.value / 100);
            }
            break;
          case AutoSaveRuleType.roundUp:
            if (!tx.isIncome && tx.roundUpAmount != null) {
              autoSaveAmount = tx.roundUpAmount;
            }
            break;
          case AutoSaveRuleType.fixedWeekly:
            // Handled by scheduled tasks, not per-transaction
            break;
          case AutoSaveRuleType.triggerThreshold:
            // Handled by balance check, not per-transaction
            break;
        }

        if (autoSaveAmount != null && autoSaveAmount > 0) {
          // Create auto-deposit in the database
          if (rule.goalId != null) {
            await database.insertAutoDeposit(
              AutoDepositsCompanion.insert(
                goalId: rule.goalId!,
                amount: autoSaveAmount,
                source: Value('bank_sync_${rule.ruleType.name}'),
              ),
            );
          }

          autoSaved.add(BankTransaction(
            transactionId: 'auto_${tx.transactionId}',
            amount: autoSaveAmount,
            currency: tx.currency,
            description:
                'Auto-save: ${rule.ruleType.labelUA}',
            category: 'auto_save',
            date: tx.date,
            isIncome: true,
          ));

          // Award XP for auto-savings
          await database.addXP(
            (autoSaveAmount / 10).floor().clamp(10, 200),
            source: 'bank_sync_auto',
          );
        }
      }
    }

    return autoSaved;
  }

  // =========================================================================
  // Stats computation
  // =========================================================================

  BankSyncStats _computeStats(
    List<BankTransaction> transactions,
    List<BankTransaction> autoSaved,
  ) {
    double totalAutoSaved = 0.0;
    double totalRoundUp = 0.0;
    int autoDeposits = 0;
    double roundUpSum = 0.0;
    int roundUpCount = 0;

    for (final tx in autoSaved) {
      totalAutoSaved += tx.amount;
      autoDeposits++;
    }

    for (final tx in transactions) {
      if (tx.roundUpAmount != null && tx.roundUpAmount! > 0) {
        totalRoundUp += tx.roundUpAmount!;
        roundUpSum += tx.roundUpAmount!;
        roundUpCount++;
      }
    }

    return BankSyncStats(
      totalAutoSaved: totalAutoSaved + state.stats.totalAutoSaved,
      totalRoundUp: totalRoundUp + state.stats.totalRoundUp,
      totalTransactions:
          transactions.length + state.stats.totalTransactions,
      totalAutoDeposits: autoDeposits + state.stats.totalAutoDeposits,
      averageRoundUp: roundUpCount > 0
          ? roundUpSum / roundUpCount
          : state.stats.averageRoundUp,
      lastSyncAt: DateTime.now(),
    );
  }

  // =========================================================================
  // Utility
  // =========================================================================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bankSyncProvider =
    StateNotifierProvider<BankSyncNotifier, BankSyncState>(
  (ref) => BankSyncNotifier(ref),
);
