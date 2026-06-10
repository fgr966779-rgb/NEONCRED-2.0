import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// =============================================================================
// MODELS
// =============================================================================

class LendingRecord {
  final String recordId;
  final String debtorName;
  final double amountUah;
  final DateTime lentAt;
  final DateTime dueDate;
  final String status; // active/overdue/returned/archived
  final String? note;
  final DateTime? returnedAt;
  final int xpAwarded;
  final DateTime createdAt;

  const LendingRecord({
    required this.recordId,
    required this.debtorName,
    required this.amountUah,
    required this.lentAt,
    required this.dueDate,
    this.status = 'active',
    this.note,
    this.returnedAt,
    this.xpAwarded = 0,
    required this.createdAt,
  });

  LendingRecord copyWith({
    String? recordId,
    String? debtorName,
    double? amountUah,
    DateTime? lentAt,
    DateTime? dueDate,
    String? status,
    String? note,
    DateTime? returnedAt,
    int? xpAwarded,
    DateTime? createdAt,
  }) {
    return LendingRecord(
      recordId: recordId ?? this.recordId,
      debtorName: debtorName ?? this.debtorName,
      amountUah: amountUah ?? this.amountUah,
      lentAt: lentAt ?? this.lentAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      note: note ?? this.note,
      returnedAt: returnedAt ?? this.returnedAt,
      xpAwarded: xpAwarded ?? this.xpAwarded,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Days remaining until due date (negative if overdue).
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Days past the due date (0 if not overdue).
  int get daysOverdue => max(0, DateTime.now().difference(dueDate).inDays);

  /// Whether this active record should be considered overdue.
  bool get shouldBeOverdue =>
      (status == 'active' || status == 'overdue') &&
      DateTime.now().isAfter(dueDate);
}

class LendingStats {
  final double totalLentActive;
  final double totalOverdue;
  final double totalReturned;
  final int activeCount;
  final int overdueCount;
  final int returnedCount;
  final bool hasCollectorBadge;

  const LendingStats({
    this.totalLentActive = 0,
    this.totalOverdue = 0,
    this.totalReturned = 0,
    this.activeCount = 0,
    this.overdueCount = 0,
    this.returnedCount = 0,
    this.hasCollectorBadge = false,
  });
}

class LendingState {
  final List<LendingRecord> records;
  final bool isLoading;
  final String? error;
  final List<String> debtorNames;
  final String? aiReminderText;
  final String? aiReminderForRecordId;
  final LendingStats stats;

  const LendingState({
    this.records = const [],
    this.isLoading = false,
    this.error,
    this.debtorNames = const [],
    this.aiReminderText,
    this.aiReminderForRecordId,
    this.stats = const LendingStats(),
  });

  LendingState copyWith({
    List<LendingRecord>? records,
    bool? isLoading,
    String? error,
    List<String>? debtorNames,
    String? aiReminderText,
    String? aiReminderForRecordId,
    LendingStats? stats,
  }) {
    return LendingState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      debtorNames: debtorNames ?? this.debtorNames,
      aiReminderText: aiReminderText,
      aiReminderForRecordId: aiReminderForRecordId,
      stats: stats ?? this.stats,
    );
  }
}

// =============================================================================
// NOTIFIER — Lending Tracker Business Logic
// =============================================================================

class LendingTrackerNotifier extends StateNotifier<LendingState> {
  final Ref _ref;

  LendingTrackerNotifier(this._ref) : super(const LendingState()) {
    _init();
  }

  // ---- Initialization ----

  void _init() {
    checkOverdue();
  }

  // ---- Create New Lending Record ----

  void createRecord({
    required String debtorName,
    required double amountUah,
    required DateTime dueDate,
    String? note,
  }) {
    final now = DateTime.now();
    final recordId = 'LN-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase().padLeft(5, '0')}';

    final record = LendingRecord(
      recordId: recordId,
      debtorName: debtorName.trim(),
      amountUah: amountUah,
      lentAt: now,
      dueDate: dueDate,
      note: note,
      createdAt: now,
    );

    final newRecords = [record, ...state.records];
    final newDebtorNames = _extractDebtorNames(newRecords);

    state = state.copyWith(
      records: newRecords,
      debtorNames: newDebtorNames,
      stats: _computeStats(newRecords),
      error: null,
    );

    // Award +10 XP for creating a contract
    _awardXP(10, source: 'lending_contract_created');
  }

  // ---- Mark as Returned ----

  void markAsReturned(String recordId) {
    final idx = state.records.indexWhere((r) => r.recordId == recordId);
    if (idx == -1) return;

    final record = state.records[idx];
    if (record.status == 'returned' || record.status == 'archived') return;

    final updated = record.copyWith(
      status: 'returned',
      returnedAt: DateTime.now(),
      xpAwarded: 50,
    );

    final newRecords = [...state.records];
    newRecords[idx] = updated;

    state = state.copyWith(
      records: newRecords,
      stats: _computeStats(newRecords),
    );

    // Award +50 XP for successful return
    _awardXP(50, source: 'lending_returned');
  }

  // ---- Archive (Soft Delete) ----

  void archiveRecord(String recordId) {
    final idx = state.records.indexWhere((r) => r.recordId == recordId);
    if (idx == -1) return;

    final record = state.records[idx];
    final updated = record.copyWith(status: 'archived');

    final newRecords = [...state.records];
    newRecords[idx] = updated;

    state = state.copyWith(
      records: newRecords,
      stats: _computeStats(newRecords),
    );
  }

  // ---- Check Overdue Status ----

  void checkOverdue() {
    final now = DateTime.now();
    bool changed = false;
    final newRecords = [...state.records];

    for (int i = 0; i < newRecords.length; i++) {
      if (newRecords[i].status == 'active' && now.isAfter(newRecords[i].dueDate)) {
        newRecords[i] = newRecords[i].copyWith(status: 'overdue');
        changed = true;
      }
    }

    if (changed) {
      state = state.copyWith(
        records: newRecords,
        stats: _computeStats(newRecords),
      );
    }
  }

  // ---- Simulate Overdue (Debug) ----

  void simulateOverdue(String recordId) {
    final idx = state.records.indexWhere((r) => r.recordId == recordId);
    if (idx == -1) return;

    final record = state.records[idx];
    if (record.status != 'active') return;

    // Set dueDate to 3 days ago for visual testing
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    final updated = record.copyWith(
      dueDate: threeDaysAgo,
      status: 'overdue',
    );

    final newRecords = [...state.records];
    newRecords[idx] = updated;

    state = state.copyWith(
      records: newRecords,
      stats: _computeStats(newRecords),
    );
  }

  // ---- AI Reminder via OpenRouter ----

  Future<void> generateReminder(String recordId) async {
    final record = state.records.where((r) => r.recordId == recordId).firstOrNull;
    if (record == null) return;

    state = state.copyWith(isLoading: true, aiReminderForRecordId: recordId);

    try {
      final ai = _ref.read(openRouterServiceProvider);
      final response = await ai.chat(
        systemPrompt:
            'Ти -- Кібер-Колектор. Напиши коротке (1-2 речення) ввічливе, але тверде нагадування про борг. '
            'Стиль: кіберпанк-діловий. Використовуй українську мову. '
            'Не додавай зайвих пояснень -- лише текст нагадування.',
        userPrompt:
            'Боржник: ${record.debtorName}, сума: ${record.amountUah.toStringAsFixed(0)} грн, '
            'прострочено: ${record.daysOverdue} днів. '
            'Дата видачі: ${_formatDate(record.lentAt)}. Термін: ${_formatDate(record.dueDate)}.',
        temperature: 0.9,
        maxTokens: 200,
      );

      state = state.copyWith(
        isLoading: false,
        aiReminderText: response ?? _fallbackReminder(record),
        aiReminderForRecordId: recordId,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        aiReminderText: _fallbackReminder(record),
        aiReminderForRecordId: recordId,
      );
    }
  }

  void clearReminder() {
    state = state.copyWith(aiReminderText: null, aiReminderForRecordId: null);
  }

  String _fallbackReminder(LendingRecord record) {
    final overdueDays = record.daysOverdue;
    if (overdueDays > 0) {
      return '${record.debtorName}, термін повернення ${record.amountUah.toStringAsFixed(0)} грн '
          'минув $overdueDays дн. тому. Прошу повернути борг найближчим часом.';
    }
    return '${record.debtorName}, нагадую про борг ${record.amountUah.toStringAsFixed(0)} грн. '
        'Термін повернення: ${_formatDate(record.dueDate)}.';
  }

  // ---- XP Awarding ----

  void _awardXP(int amount, {String source = 'lending'}) {
    try {
      final db = _ref.read(databaseProvider);
      db.addXP(amount, source: source);
    } catch (_) {
      // XP system may not be initialized; ignore gracefully
    }
  }

  // ---- Stats Computation ----

  LendingStats _computeStats(List<LendingRecord> records) {
    double totalLentActive = 0;
    double totalOverdue = 0;
    double totalReturned = 0;
    int activeCount = 0;
    int overdueCount = 0;
    int returnedCount = 0;

    for (final r in records) {
      if (r.status == 'archived') continue;
      switch (r.status) {
        case 'active':
          totalLentActive += r.amountUah;
          activeCount++;
          break;
        case 'overdue':
          totalOverdue += r.amountUah;
          overdueCount++;
          break;
        case 'returned':
          totalReturned += r.amountUah;
          returnedCount++;
          break;
      }
    }

    // Badge "Колектор" after 5+ returned debts
    final hasCollectorBadge = returnedCount >= 5;

    return LendingStats(
      totalLentActive: totalLentActive,
      totalOverdue: totalOverdue,
      totalReturned: totalReturned,
      activeCount: activeCount,
      overdueCount: overdueCount,
      returnedCount: returnedCount,
      hasCollectorBadge: hasCollectorBadge,
    );
  }

  // ---- Debtor Names Extraction ----

  List<String> _extractDebtorNames(List<LendingRecord> records) {
    final names = records
        .where((r) => r.status != 'archived')
        .map((r) => r.debtorName)
        .toSet()
        .toList();
    names.sort();
    return names;
  }

  // ---- Filtering ----

  List<LendingRecord> get activeRecords =>
      state.records.where((r) => r.status == 'active').toList();

  List<LendingRecord> get overdueRecords =>
      state.records.where((r) => r.status == 'overdue').toList();

  List<LendingRecord> get returnedRecords =>
      state.records.where((r) => r.status == 'returned').toList();

  List<LendingRecord> get visibleRecords =>
      state.records.where((r) => r.status != 'archived').toList();

  // ---- Clear Error ----

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// =============================================================================
// HELPERS
// =============================================================================

String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';
}

// =============================================================================
// PROVIDER
// =============================================================================

final lendingTrackerProvider =
    StateNotifierProvider<LendingTrackerNotifier, LendingState>(
  (ref) => LendingTrackerNotifier(ref),
);
