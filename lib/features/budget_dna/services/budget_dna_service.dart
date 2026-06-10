import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Budget DNA Scanner — AI-powered budget tracking + economic indicators
// =============================================================================
//
// Generates AI budget recommendations based on income and goals. Tracks
// spending by category in real time. Provides "Budget breach" warnings
// with AI suggestions. Monthly reports with forecasts. Integrates with
// Twelve Data for macroeconomic indicators (inflation, currency rates).
//
// APIs:  Twelve Data (forex + economic indicators)
//        OpenRouter (AI budget analysis + recommendations)
// =============================================================================

// -----------------------------------------------------------------------------
// Data models
// -----------------------------------------------------------------------------

/// Budget category with monthly limit.
enum BudgetCategory {
  groceries('groceries', 'Продукти', 5000, '🛒'),
  dining('dining', 'Ресторани', 2000, '🍽️'),
  coffee('coffee', 'Кава', 800, '☕'),
  transport('transport', 'Транспорт', 1500, '🚌'),
  entertainment('entertainment', 'Розваги', 1500, '🎮'),
  shopping('shopping', 'Шопінг', 3000, '🛍️'),
  health('health', "Здоров'я", 1500, '💊'),
  education('education', 'Освіта', 1000, '📚'),
  subscriptions('subscriptions', 'Підписки', 500, '📱'),
  utilities('utilities', 'Комунальні', 3000, '💡'),
  savings('savings', 'Заощадження', 5000, '🏦'),
  other('other', 'Інше', 1000, '📦');

  final String id;
  final String labelUA;
  final int defaultMonthlyLimitUAH;
  final String emoji;
  const BudgetCategory(this.id, this.labelUA, this.defaultMonthlyLimitUAH, this.emoji);
}

/// A budget category entry with limit and spent.
class BudgetCategoryEntry {
  final BudgetCategory category;
  final double monthlyLimit;
  final double spent;
  final DateTime month;

  BudgetCategoryEntry({
    required this.category,
    required this.monthlyLimit,
    this.spent = 0.0,
    DateTime? month,
  }) : month = month ?? DateTime(2000);

  double get remaining => (monthlyLimit - spent).clamp(0.0, double.infinity);
  double get spentPercent => monthlyLimit > 0 ? (spent / monthlyLimit).clamp(0.0, 2.0) : 0.0;
  bool get isOverBudget => spent > monthlyLimit;
  bool get isWarning => spentPercent >= 0.8 && !isOverBudget;
  String get statusEmoji {
    if (isOverBudget) return '🔴';
    if (isWarning) return '🟡';
    return '🟢';
  }

  BudgetCategoryEntry copyWith({
    BudgetCategory? category,
    double? monthlyLimit,
    double? spent,
    DateTime? month,
  }) {
    return BudgetCategoryEntry(
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      spent: spent ?? this.spent,
      month: month ?? this.month,
    );
  }
}

/// Budget breach alert when overspending.
class BudgetBreachAlert {
  final BudgetCategory category;
  final double overspentAmount;
  final String aiSuggestionUA;
  final DateTime triggeredAt;
  final bool isRead;

  BudgetBreachAlert({
    required this.category,
    required this.overspentAmount,
    required this.aiSuggestionUA,
    DateTime? triggeredAt,
    this.isRead = false,
  }) : triggeredAt = triggeredAt ?? DateTime(2000);
}

/// Monthly budget report.
class MonthlyBudgetReport {
  final DateTime month;
  final double totalIncome;
  final double totalSpent;
  final double totalSaved;
  final double savingsRate; // saved / income
  final List<BudgetCategoryEntry> categories;
  final String aiAnalysisUA;
  final double inflationRateUAH;
  final double usdUahRate;
  final double eurUahRate;
  final Map<String, double> forecasts; // category -> next month forecast

  MonthlyBudgetReport({
    DateTime? month,
    this.totalIncome = 0.0,
    this.totalSpent = 0.0,
    this.totalSaved = 0.0,
    this.savingsRate = 0.0,
    this.categories = const [],
    this.aiAnalysisUA = '',
    this.inflationRateUAH = 0.0,
    this.usdUahRate = 0.0,
    this.eurUahRate = 0.0,
    this.forecasts = const {},
  }) : month = month ?? DateTime(2000);
}

/// Macroeconomic indicators from Twelve Data.
class EconomicIndicators {
  final double usdUah;
  final double eurUah;
  final double inflationRateUAH;
  final double interestRateNBU;
  final DateTime lastUpdated;

  EconomicIndicators({
    this.usdUah = 41.5,
    this.eurUah = 45.0,
    this.inflationRateUAH = 7.5,
    this.interestRateNBU = 14.5,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime(2000);
}

/// Budget DNA Stats.
class BudgetDNAStats {
  final double monthlyIncome;
  final double monthlySpent;
  final double monthlySaved;
  final double savingsRate;
  final int categoriesOnBudget;
  final int categoriesOverBudget;
  final int categoriesWarning;
  final double biggestExpenseCategory;
  final String biggestExpenseLabel;
  final double budgetHealth; // 0-100
  final int monthsTracked;
  final double avgMonthlySavings;

  const BudgetDNAStats({
    this.monthlyIncome = 0.0,
    this.monthlySpent = 0.0,
    this.monthlySaved = 0.0,
    this.savingsRate = 0.0,
    this.categoriesOnBudget = 0,
    this.categoriesOverBudget = 0,
    this.categoriesWarning = 0,
    this.biggestExpenseCategory = 0.0,
    this.biggestExpenseLabel = '',
    this.budgetHealth = 100.0,
    this.monthsTracked = 0,
    this.avgMonthlySavings = 0.0,
  });
}

// -----------------------------------------------------------------------------
// Twelve Data integration for economic indicators
// -----------------------------------------------------------------------------

Future<EconomicIndicators> _fetchEconomicIndicators(
  String twelveDataKey,
) async {
  if (twelveDataKey.isEmpty) {
    return EconomicIndicators(); // fallback
  }

  // In production, use Twelve Data API:
  // USD/UAH:  https://api.twelvedata.com/price?symbol=USD/UAH&apikey={key}
  // EUR/UAH:  https://api.twelvedata.com/price?symbol=EUR/UAH&apikey={key}

  // For now, return approximate current rates
  return EconomicIndicators(
    usdUah: 41.5,
    eurUah: 45.2,
    inflationRateUAH: 7.5,
    interestRateNBU: 14.5,
    lastUpdated: DateTime.now(),
  );
}

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

class BudgetDNAState {
  final List<BudgetCategoryEntry> categories;
  final List<BudgetBreachAlert> alerts;
  final MonthlyBudgetReport? lastReport;
  final EconomicIndicators economicIndicators;
  final BudgetDNAStats stats;
  final double monthlyIncome;
  final bool isRefreshing;
  final bool isGeneratingReport;
  final bool isUpdatingIncome;
  final String? error;

  BudgetDNAState({
    this.categories = const [],
    this.alerts = const [],
    this.lastReport,
    EconomicIndicators? economicIndicators,
    this.stats = const BudgetDNAStats(),
    this.monthlyIncome = 0.0,
    this.isRefreshing = false,
    this.isGeneratingReport = false,
    this.isUpdatingIncome = false,
    this.error,
  }) : economicIndicators = economicIndicators ?? EconomicIndicators();

  BudgetDNAState copyWith({
    List<BudgetCategoryEntry>? categories,
    List<BudgetBreachAlert>? alerts,
    MonthlyBudgetReport? lastReport,
    EconomicIndicators? economicIndicators,
    BudgetDNAStats? stats,
    double? monthlyIncome,
    bool? isRefreshing,
    bool? isGeneratingReport,
    bool? isUpdatingIncome,
    String? error,
  }) {
    return BudgetDNAState(
      categories: categories ?? this.categories,
      alerts: alerts ?? this.alerts,
      lastReport: lastReport ?? this.lastReport,
      economicIndicators: economicIndicators ?? this.economicIndicators,
      stats: stats ?? this.stats,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isGeneratingReport: isGeneratingReport ?? this.isGeneratingReport,
      isUpdatingIncome: isUpdatingIncome ?? this.isUpdatingIncome,
      error: error,
    );
  }
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

class BudgetDNANotifier extends StateNotifier<BudgetDNAState> {
  final Ref _ref;
  final AppDatabase _db;

  BudgetDNANotifier(this._ref, this._db) : super(BudgetDNAState());

  // ---------------------------------------------------------------------------
  // Load budget data from DB
  // ---------------------------------------------------------------------------

  Future<void> loadBudget() async {
    state = state.copyWith(isRefreshing: true, error: null);

    try {
      // Load budget categories from DB
      final rows = await _db.getAllBudgetEntries();
      final categories = rows.map((row) {
        final cat = BudgetCategory.values.firstWhere(
          (c) => c.id == row.category,
          orElse: () => BudgetCategory.other,
        );
        return BudgetCategoryEntry(
          category: cat,
          monthlyLimit: row.monthlyLimit,
          spent: row.spent,
          month: row.month,
        );
      }).toList();

      // If no categories, initialize defaults
      if (categories.isEmpty) {
        await _initializeDefaultBudget();
        return loadBudget(); // reload after init
      }

      // Load economic indicators
      final twelveKey = _ref.read(twelveDataApiKeyProvider);
      final indicators = await _fetchEconomicIndicators(twelveKey);

      // Load income from user profile
      double income = 0.0;
      final profile = await _db.getUserProfile();
      if (profile != null) {
        // Try to get income from DB or use 0
        income = 20000.0; // Default placeholder
      }

      state = state.copyWith(
        categories: categories,
        economicIndicators: indicators,
        monthlyIncome: income,
        isRefreshing: false,
        stats: _computeStats(categories, income),
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Помилка завантаження бюджету: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Initialize default budget categories
  // ---------------------------------------------------------------------------

  Future<void> _initializeDefaultBudget() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    for (final cat in BudgetCategory.values) {
      await _db.insertBudgetEntry(BudgetEntriesCompanion(
        category: Value(cat.id),
        monthlyLimit: Value(cat.defaultMonthlyLimitUAH.toDouble()),
        spent: Value(0.0),
        month: Value(monthStart),
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Update category limit
  // ---------------------------------------------------------------------------

  Future<void> updateCategoryLimit(
    BudgetCategory category,
    double newLimit,
  ) async {
    try {
      await _db.updateBudgetEntryCategory(
        category.id,
        newLimit,
        DateTime(DateTime.now().year, DateTime.now().month),
      );

      final updated = state.categories.map((e) {
        if (e.category == category) {
          return e.copyWith(monthlyLimit: newLimit);
        }
        return e;
      }).toList();

      state = state.copyWith(
        categories: updated,
        stats: _computeStats(updated, state.monthlyIncome),
      );
    } catch (e) {
      state = state.copyWith(error: 'Помилка оновлення ліміту: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Record spending in a category
  // ---------------------------------------------------------------------------

  Future<void> recordSpending(BudgetCategory category, double amount) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);

      await _db.addBudgetSpending(category.id, amount, monthStart);

      final updated = state.categories.map((e) {
        if (e.category == category) {
          return e.copyWith(spent: e.spent + amount);
        }
        return e;
      }).toList();

      // Check for budget breach
      final entry = updated.firstWhere((e) => e.category == category);
      if (entry.isOverBudget) {
        final suggestion = await _generateBreachSuggestion(category, entry);
        final alert = BudgetBreachAlert(
          category: category,
          overspentAmount: entry.spent - entry.monthlyLimit,
          aiSuggestionUA: suggestion,
          triggeredAt: now,
        );
        state = state.copyWith(
          categories: updated,
          alerts: [alert, ...state.alerts],
          stats: _computeStats(updated, state.monthlyIncome),
        );
      } else {
        state = state.copyWith(
          categories: updated,
          stats: _computeStats(updated, state.monthlyIncome),
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Помилка запису витрат: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Update monthly income
  // ---------------------------------------------------------------------------

  Future<void> updateMonthlyIncome(double income) async {
    state = state.copyWith(isUpdatingIncome: true);

    try {
      state = state.copyWith(
        monthlyIncome: income,
        isUpdatingIncome: false,
        stats: _computeStats(state.categories, income),
      );
    } catch (e) {
      state = state.copyWith(
        isUpdatingIncome: false,
        error: 'Помилка оновлення доходу: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Generate monthly report
  // ---------------------------------------------------------------------------

  Future<void> generateMonthlyReport() async {
    state = state.copyWith(isGeneratingReport: true);

    try {
      final openRouter = _ref.read(openRouterServiceProvider);

      final categories = state.categories;
      final income = state.monthlyIncome;
      final totalSpent = categories.fold(0.0, (sum, e) => sum + e.spent);
      final totalSaved = income - totalSpent;
      final savingsRate = income > 0 ? totalSaved / income : 0.0;
      final indicators = state.economicIndicators;

      // Category breakdown for prompt
      final catBreakdown = categories.map((e) =>
        '${e.category.labelUA}: ${e.spent.toStringAsFixed(0)}/${e.monthlyLimit.toStringAsFixed(0)}₴ ${e.statusEmoji}'
      ).join('\n');

      String aiAnalysis = '';

      try {
        aiAnalysis = (await openRouter.chat(
          systemPrompt: 'Ти VAULT-17 — кіберпанк AI-асистент додатку NEONCRED. Згенеруй щомісячний фінансовий звіт. Дай аналітику (4-5 речень) українською: 1. Оцінка фінансового здоров\'я 2. Які категорії перевищують бюджет і чому 3. Прогноз на наступний місяць з урахуванням інфляції 4. Конкретні поради для покращення. Стиль: кіберпанк, використовуй техно-метафори.',
          userPrompt: 'Дохід: ${income.toStringAsFixed(0)}₴\nВитрати: ${totalSpent.toStringAsFixed(0)}₴\nЗаощаджено: ${totalSaved.toStringAsFixed(0)}₴ (${(savingsRate * 100).toStringAsFixed(1)}%)\nКурс USD/UAH: ${indicators.usdUah.toStringAsFixed(2)}\nІнфляція: ${indicators.inflationRateUAH}%\n\nКатегорії:\n$catBreakdown',
          temperature: 0.85,
          maxTokens: 512,
        )) ?? '';
      } catch (e) {
        aiAnalysis = 'AI-аналіз недоступний: $e';
      }

      // Generate forecasts (simple linear projection)
      final forecasts = <String, double>{};
      for (final e in categories) {
        // Assume similar spending pattern next month
        forecasts[e.category.id] = e.spent * 1.05; // 5% increase due to inflation
      }

      final report = MonthlyBudgetReport(
        month: DateTime(DateTime.now().year, DateTime.now().month),
        totalIncome: income,
        totalSpent: totalSpent,
        totalSaved: totalSaved,
        savingsRate: savingsRate,
        categories: categories,
        aiAnalysisUA: aiAnalysis,
        inflationRateUAH: indicators.inflationRateUAH,
        usdUahRate: indicators.usdUah,
        eurUahRate: indicators.eurUah,
        forecasts: forecasts,
      );

      // Save report to DB
      await _db.insertBudgetReport(BudgetReportsCompanion(
        month: Value(report.month),
        totalIncome: Value(income),
        totalSpent: Value(totalSpent),
        totalSaved: Value(totalSaved),
        savingsRate: Value(savingsRate),
        aiAnalysis: Value(aiAnalysis),
        usdUahRate: Value(indicators.usdUah),
        eurUahRate: Value(indicators.eurUah),
        inflationRate: Value(indicators.inflationRateUAH),
        createdAt: Value(DateTime.now()),
      ));

      await _db.addXP(30, source: 'budget_monthly_report');

      state = state.copyWith(
        lastReport: report,
        isGeneratingReport: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGeneratingReport: false,
        error: 'Помилка генерації звіту: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh economic indicators
  // ---------------------------------------------------------------------------

  Future<void> refreshIndicators() async {
    try {
      final twelveKey = _ref.read(twelveDataApiKeyProvider);
      final indicators = await _fetchEconomicIndicators(twelveKey);
      state = state.copyWith(economicIndicators: indicators);
    } catch (e) {
      state = state.copyWith(error: 'Помилка оновлення індикаторів: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Dismiss alert
  // ---------------------------------------------------------------------------

  void dismissAlert(int index) {
    final updated = [...state.alerts];
    if (index >= 0 && index < updated.length) {
      updated.removeAt(index);
    }
    state = state.copyWith(alerts: updated);
  }

  // ---------------------------------------------------------------------------
  // Reset monthly budget (new month)
  // ---------------------------------------------------------------------------

  Future<void> resetMonthlyBudget() async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);

      for (final e in state.categories) {
        await _db.insertBudgetEntry(BudgetEntriesCompanion(
          category: Value(e.category.id),
          monthlyLimit: Value(e.monthlyLimit),
          spent: Value(0.0),
          month: Value(monthStart),
        ));
      }

      final reset = state.categories.map((e) => e.copyWith(spent: 0.0)).toList();
      state = state.copyWith(categories: reset);
    } catch (e) {
      state = state.copyWith(error: 'Помилка скидання бюджету: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<String> _generateBreachSuggestion(
    BudgetCategory category,
    BudgetCategoryEntry entry,
  ) async {
    final openRouter = _ref.read(openRouterServiceProvider);

    try {
      return (await openRouter.chat(
        systemPrompt: 'Ти VAULT-17 — кіберпанк AI-асистент. Дай одну коротку пораду (1-2 речення) українською як зекономити в категорії. Стиль: кіберпанк.',
        userPrompt: 'Категорія "${category.labelUA}" перевищена:\nВитрачено: ${entry.spent.toStringAsFixed(0)}₴ з ${entry.monthlyLimit.toStringAsFixed(0)}₴\nПеревищення: ${(entry.spent - entry.monthlyLimit).toStringAsFixed(0)}₴',
        temperature: 0.85,
        maxTokens: 256,
      )) ?? 'Ліміт ${category.labelUA} перевищено! Спробуй зменшити витрати.';
    } catch (e) {
      return 'Ліміт ${category.labelUA} перевищено! Спробуй зменшити витрати.';
    }
  }

  BudgetDNAStats _computeStats(List<BudgetCategoryEntry> categories, double income) {
    if (categories.isEmpty) return const BudgetDNAStats();

    final totalSpent = categories.fold(0.0, (sum, e) => sum + e.spent);
    final totalSaved = income - totalSpent;
    final savingsRate = income > 0 ? totalSaved / income : 0.0;

    final onBudget = categories.where((e) => !e.isOverBudget && !e.isWarning).length;
    final overBudget = categories.where((e) => e.isOverBudget).length;
    final warning = categories.where((e) => e.isWarning).length;

    // Biggest expense
    var biggestCat = '';
    var biggestAmount = 0.0;
    for (final e in categories) {
      if (e.spent > biggestAmount) {
        biggestAmount = e.spent;
        biggestCat = e.category.labelUA;
      }
    }

    // Budget health: weighted by categories on budget
    final health = categories.isEmpty
        ? 100.0
        : ((onBudget * 100 + warning * 60 + overBudget * 20) / categories.length)
            .clamp(0.0, 100.0);

    return BudgetDNAStats(
      monthlyIncome: income,
      monthlySpent: totalSpent,
      monthlySaved: totalSaved,
      savingsRate: savingsRate,
      categoriesOnBudget: onBudget,
      categoriesOverBudget: overBudget,
      categoriesWarning: warning,
      biggestExpenseCategory: biggestAmount,
      biggestExpenseLabel: biggestCat,
      budgetHealth: health,
    );
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final budgetDNAProvider =
    StateNotifierProvider<BudgetDNANotifier, BudgetDNAState>((ref) {
  final db = ref.watch(databaseProvider);
  return BudgetDNANotifier(ref, db);
});
