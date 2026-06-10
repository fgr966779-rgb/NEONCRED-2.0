import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../providers/budget_dna_provider.dart';

// =========================================================================
// BudgetDNAScreen — AI-powered budget tracking + economic indicators
// =========================================================================
//
// Cyberpunk-themed dashboard with 3 tabs:
//   1. БЮДЖЕТ — budget health, savings rate, breach alerts, categories
//   2. ЗВІТ  — monthly report generation & display
//   3. ІНДИКАТОРИ — currency rates, macroeconomics, AI explanation
//
// All text in Ukrainian. Currency: ₴ (UAH).
// =========================================================================

class BudgetDNAScreen extends ConsumerStatefulWidget {
  const BudgetDNAScreen({super.key});

  @override
  ConsumerState<BudgetDNAScreen> createState() => _BudgetDNAScreenState();
}

class _BudgetDNAScreenState extends ConsumerState<BudgetDNAScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _incomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(budgetDNAProvider.notifier).loadBudget();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Color constants
  // ---------------------------------------------------------------------------

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _textPrimary = Color(0xFFE0E0FF);
  static const _textSecondary = Color(0xFF8888AA);
  static const _textMuted = Color(0xFF666688);

  // ---------------------------------------------------------------------------
  // Budget health color
  // ---------------------------------------------------------------------------

  Color _healthColor(double health) {
    if (health > 80) return _green;
    if (health > 60) return _cyan;
    if (health > 40) return Colors.yellow;
    return _pink;
  }

  String _healthLabel(double health) {
    if (health > 80) return 'Відмінно';
    if (health > 60) return 'Добре';
    if (health > 40) return 'Задовільно';
    return 'Критично';
  }

  // ---------------------------------------------------------------------------
  // Format helpers
  // ---------------------------------------------------------------------------

  String _fmtMoney(double v) => '${v.toStringAsFixed(0)}₴';
  String _fmtPercent(double v) => '${(v * 100).toStringAsFixed(1)}%';

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(budgetDNAProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          '🧬 Budget DNA',
          style: TextStyle(color: _cyan, fontSize: 20),
        ),
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _cyan),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _cyan,
          indicatorWeight: 2,
          labelColor: _cyan,
          unselectedLabelColor: _textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'БЮДЖЕТ'),
            Tab(text: 'ЗВІТ'),
            Tab(text: 'ІНДИКАТОРИ'),
          ],
        ),
      ),
      body: state.isRefreshing && state.categories.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: _cyan),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _BudgetTab(
                  state: state,
                  healthColor: _healthColor,
                  healthLabel: _healthLabel,
                  fmtMoney: _fmtMoney,
                  fmtPercent: _fmtPercent,
                  incomeController: _incomeController,
                  onDismissAlert: (i) =>
                      ref.read(budgetDNAProvider.notifier).dismissAlert(i),
                  onUpdateIncome: () {
                    final val = double.tryParse(_incomeController.text);
                    if (val != null && val > 0) {
                      ref
                          .read(budgetDNAProvider.notifier)
                          .updateMonthlyIncome(val);
                      FocusScope.of(context).unfocus();
                    }
                  },
                  onRefresh: () =>
                      ref.read(budgetDNAProvider.notifier).loadBudget(),
                ),
                _ReportTab(
                  state: state,
                  fmtMoney: _fmtMoney,
                  fmtPercent: _fmtPercent,
                  onGenerate: () => ref
                      .read(budgetDNAProvider.notifier)
                      .generateMonthlyReport(),
                ),
                _IndicatorsTab(
                  state: state,
                  onRefresh: () => ref
                      .read(budgetDNAProvider.notifier)
                      .refreshIndicators(),
                ),
              ],
            ),
    );
  }
}

// =========================================================================
// Tab 1 — БЮДЖЕТ
// =========================================================================

class _BudgetTab extends StatelessWidget {
  final BudgetDNAState state;
  final Color Function(double) healthColor;
  final String Function(double) healthLabel;
  final String Function(double) fmtMoney;
  final String Function(double) fmtPercent;
  final TextEditingController incomeController;
  final ValueChanged<int> onDismissAlert;
  final VoidCallback onUpdateIncome;
  final VoidCallback onRefresh;

  const _BudgetTab({
    required this.state,
    required this.healthColor,
    required this.healthLabel,
    required this.fmtMoney,
    required this.fmtPercent,
    required this.incomeController,
    required this.onDismissAlert,
    required this.onUpdateIncome,
    required this.onRefresh,
  });

  static const _bg = Color(0xFF0A0E17);
  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _textPrimary = Color(0xFFE0E0FF);
  static const _textSecondary = Color(0xFF8888AA);
  static const _textMuted = Color(0xFF666688);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _card,
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Error
          if (state.error != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _pink.withOpacity(0.3)),
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(color: _pink, fontSize: 13),
                ),
              ),
            ),

          // Budget health card
          SliverToBoxAdapter(child: _BudgetHealthCard(state: state, healthColor: healthColor, healthLabel: healthLabel)),

          // Savings rate row
          SliverToBoxAdapter(child: _SavingsRateRow(state: state, fmtMoney: fmtMoney, fmtPercent: fmtPercent)),

          // Breach alerts
          if (state.alerts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  '🚨 ПОРУШЕННЯ БЮДЖЕТУ',
                  style: TextStyle(
                    color: _pink,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          if (state.alerts.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _BreachAlertCard(
                  alert: state.alerts[index],
                  onDismiss: () => onDismissAlert(index),
                ),
                childCount: state.alerts.length,
              ),
            ),

          // Category list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                '📊 КАТЕГОРІЇ',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Category entries
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _CategoryCard(
                entry: state.categories[index],
                fmtMoney: fmtMoney,
              ),
              childCount: state.categories.length,
            ),
          ),

          // Income setting card
          SliverToBoxAdapter(
            child: _IncomeSettingCard(
              income: state.monthlyIncome,
              controller: incomeController,
              isUpdating: state.isUpdatingIncome,
              onUpdate: onUpdateIncome,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// =========================================================================
// Budget health card
// =========================================================================

class _BudgetHealthCard extends StatelessWidget {
  final BudgetDNAState state;
  final Color Function(double) healthColor;
  final String Function(double) healthLabel;

  const _BudgetHealthCard({
    required this.state,
    required this.healthColor,
    required this.healthLabel,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _textPrimary = Color(0xFFE0E0FF);
  static const _textSecondary = Color(0xFF8888AA);

  @override
  Widget build(BuildContext context) {
    final health = state.stats.budgetHealth;
    final color = healthColor(health);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular health indicator
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(color: color, width: 3),
                ),
                child: Center(
                  child: Text(
                    '${health.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ЗДОРОВ\'Я БЮДЖЕТУ',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      healthLabel(health),
                      style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _MiniStat(
                          label: 'В нормі',
                          value: '${state.stats.categoriesOnBudget}',
                          color: const Color(0xFF00FF88),
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          label: 'Увага',
                          value: '${state.stats.categoriesWarning}',
                          color: Colors.yellow,
                        ),
                        const SizedBox(width: 16),
                        _MiniStat(
                          label: 'Перевищено',
                          value: '${state.stats.categoriesOverBudget}',
                          color: const Color(0xFFFF3366),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: health / 100,
              backgroundColor: const Color(0xFF1A0A2E),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8888AA),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// Savings rate row
// =========================================================================

class _SavingsRateRow extends StatelessWidget {
  final BudgetDNAState state;
  final String Function(double) fmtMoney;
  final String Function(double) fmtPercent;

  const _SavingsRateRow({
    required this.state,
    required this.fmtMoney,
    required this.fmtPercent,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _textSecondary = Color(0xFF8888AA);

  @override
  Widget build(BuildContext context) {
    final income = state.monthlyIncome;
    final spent = state.stats.monthlySpent;
    final saved = state.stats.monthlySaved;
    final rate = state.stats.savingsRate;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _RateItem(
            emoji: '💰',
            label: 'Дохід',
            value: fmtMoney(income),
            color: _cyan,
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFF1A0A2E),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          _RateItem(
            emoji: '💸',
            label: 'Витрачено',
            value: fmtMoney(spent),
            color: _pink,
          ),
          Container(
            width: 1,
            height: 36,
            color: const Color(0xFF1A0A2E),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          _RateItem(
            emoji: '🏦',
            label: 'Заощаджено',
            value: '${fmtMoney(saved)} (${fmtPercent(rate)})',
            color: _green,
          ),
        ],
      ),
    );
  }
}

class _RateItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _RateItem({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Breach alert card (dismissible)
// =========================================================================

class _BreachAlertCard extends StatelessWidget {
  final BudgetBreachAlert alert;
  final VoidCallback onDismiss;

  const _BreachAlertCard({
    required this.alert,
    required this.onDismiss,
  });

  static const _pink = Color(0xFFFF3366);
  static const _card = Color(0xFF0D1117);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(alert.triggeredAt.microsecondsSinceEpoch),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: _pink),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _pink.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(alert.category.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${alert.category.labelUA} перевищено!',
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _pink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${alert.overspentAmount.toStringAsFixed(0)}₴',
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🤖', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.aiSuggestionUA,
                    style: const TextStyle(
                      color: Color(0xFFE0E0FF),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Category card
// =========================================================================

class _CategoryCard extends StatelessWidget {
  final BudgetCategoryEntry entry;
  final String Function(double) fmtMoney;

  const _CategoryCard({
    required this.entry,
    required this.fmtMoney,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _textPrimary = Color(0xFFE0E0FF);
  static const _textSecondary = Color(0xFF8888AA);

  Color _progressColor() {
    if (entry.isOverBudget) return _pink;
    if (entry.isWarning) return Colors.yellow;
    return _green;
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _progressColor();
    final progressValue = entry.spentPercent.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: progressColor.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji
              Text(entry.category.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  entry.category.labelUA,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Status emoji
              Text(entry.statusEmoji, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          // Spent / limit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fmtMoney(entry.spent),
                style: TextStyle(
                  color: progressColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'з ${fmtMoney(entry.monthlyLimit)}',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: const Color(0xFF1A0A2E),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 5,
            ),
          ),
          // Over budget indicator
          if (entry.isOverBudget) ...[
            const SizedBox(height: 6),
            Text(
              'Перевищено на ${fmtMoney(entry.spent - entry.monthlyLimit)}',
              style: const TextStyle(
                color: _pink,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =========================================================================
// Income setting card
// =========================================================================

class _IncomeSettingCard extends StatelessWidget {
  final double income;
  final TextEditingController controller;
  final bool isUpdating;
  final VoidCallback onUpdate;

  const _IncomeSettingCard({
    required this.income,
    required this.controller,
    required this.isUpdating,
    required this.onUpdate,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _textSecondary = Color(0xFF8888AA);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💰 ВСТАНОВИТИ ДОХІД',
            style: TextStyle(
              color: _purple,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Color(0xFFE0E0FF),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: income > 0 ? '${income.toStringAsFixed(0)}₴' : 'Введіть суму...',
                    hintStyle: const TextStyle(color: Color(0xFF666688)),
                    suffixText: '₴',
                    suffixStyle: const TextStyle(color: _cyan, fontSize: 16),
                    filled: true,
                    fillColor: const Color(0xFF1A0A2E),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _cyan, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => onUpdate(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isUpdating ? null : onUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ЗБЕРЕГТИ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Tab 2 — ЗВІТ
// =========================================================================

class _ReportTab extends StatelessWidget {
  final BudgetDNAState state;
  final String Function(double) fmtMoney;
  final String Function(double) fmtPercent;
  final VoidCallback onGenerate;

  const _ReportTab({
    required this.state,
    required this.fmtMoney,
    required this.fmtPercent,
    required this.onGenerate,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _textPrimary = Color(0xFFE0E0FF);
  static const _textSecondary = Color(0xFF8888AA);

  @override
  Widget build(BuildContext context) {
    final report = state.lastReport;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Generate report button
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: state.isGeneratingReport ? null : onGenerate,
              icon: state.isGeneratingReport
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                state.isGeneratingReport
                    ? 'Генерую звіт...'
                    : '⚡ ЗГЕНЕРУВАТИ ЗВІТ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                disabledBackgroundColor: _purple.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        // Report card
        if (report != null)
          SliverToBoxAdapter(
            child: _MonthlyReportCard(
              report: report,
              fmtMoney: fmtMoney,
              fmtPercent: fmtPercent,
            ),
          )
        else
          const SliverToBoxAdapter(
            child: _EmptyReportState(),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// =========================================================================
// Monthly report card
// =========================================================================

class _MonthlyReportCard extends StatelessWidget {
  final MonthlyBudgetReport report;
  final String Function(double) fmtMoney;
  final String Function(double) fmtPercent;

  const _MonthlyReportCard({
    required this.report,
    required this.fmtMoney,
    required this.fmtPercent,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _textPrimary = Color(0xFFE0E0FF);
  static const _textSecondary = Color(0xFF8888AA);

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      '', 'Січень', 'Лютий', 'Березень', 'Квітень', 'Травень', 'Червень',
      'Липень', 'Серпень', 'Вересень', 'Жовтень', 'Листопад', 'Грудень',
    ];
    final monthLabel =
        '${monthNames[report.month.month]} ${report.month.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ЗВІТ ЗА $monthLabel',
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Income / Spent / Saved
          _ReportRow(
            label: 'Дохід',
            value: fmtMoney(report.totalIncome),
            color: _cyan,
          ),
          const SizedBox(height: 10),
          _ReportRow(
            label: 'Витрачено',
            value: fmtMoney(report.totalSpent),
            color: _pink,
          ),
          const SizedBox(height: 10),
          _ReportRow(
            label: 'Заощаджено',
            value: fmtMoney(report.totalSaved),
            color: _green,
          ),
          const SizedBox(height: 10),
          _ReportRow(
            label: 'Норма заощаджень',
            value: fmtPercent(report.savingsRate),
            color: report.savingsRate >= 0.2
                ? _green
                : report.savingsRate >= 0.1
                    ? _cyan
                    : _pink,
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFF1A0A2E), thickness: 1),
          const SizedBox(height: 16),

          // VAULT-17 AI analysis
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Text(
                'VAULT-17 АНАЛІЗ',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E17),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cyan.withOpacity(0.2)),
            ),
            child: Text(
              report.aiAnalysisUA.isNotEmpty
                  ? report.aiAnalysisUA
                  : 'AI-аналіз недоступний. Підключіть OpenRouter API ключ.',
              style: TextStyle(
                color: report.aiAnalysisUA.isNotEmpty
                    ? _textPrimary
                    : _textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

          // Forecasts
          if (report.forecasts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('🔮', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  'ПРОГНОЗ НА НАСТУПНИЙ МІСЯЦЬ',
                  style: TextStyle(
                    color: _green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...report.forecasts.entries.map(
              (e) {
                final cat = BudgetCategory.values.firstWhere(
                  (c) => c.id == e.key,
                  orElse: () => BudgetCategory.other,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cat.emoji} ${cat.labelUA}',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '~${e.value.toStringAsFixed(0)}₴',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ReportRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8888AA),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// Empty report state
// =========================================================================

class _EmptyReportState extends StatelessWidget {
  const _EmptyReportState();

  static const _card = Color(0xFF0D1117);
  static const _purple = Color(0xFF6B00FF);
  static const _textSecondary = Color(0xFF8888AA);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Text('📊', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            'Звітів ще немає',
            style: TextStyle(
              color: _purple,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Натисни кнопку вище, щоб згенерувати\nперший щомісячний звіт від VAULT-17.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Tab 3 — ІНДИКАТОРИ
// =========================================================================

class _IndicatorsTab extends StatelessWidget {
  final BudgetDNAState state;
  final VoidCallback onRefresh;

  const _IndicatorsTab({
    required this.state,
    required this.onRefresh,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);
  static const _textPrimary = Color(0xFFE0E0FF);
  static const _textSecondary = Color(0xFF8888AA);

  @override
  Widget build(BuildContext context) {
    final ind = state.economicIndicators;

    return RefreshIndicator(
      color: _cyan,
      backgroundColor: _card,
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Currency rates card
          SliverToBoxAdapter(
            child: _CurrencyRatesCard(indicators: ind),
          ),

          // Macroeconomics card
          SliverToBoxAdapter(
            child: _MacroeconomicsCard(indicators: ind),
          ),

          // AI explanation card
          SliverToBoxAdapter(
            child: _AIExplanationCard(
              indicators: ind,
              savingsRate: state.stats.savingsRate,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

// =========================================================================
// Currency rates card
// =========================================================================

class _CurrencyRatesCard extends StatelessWidget {
  final EconomicIndicators indicators;

  const _CurrencyRatesCard({required this.indicators});

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💱', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Text(
                'КУРСИ ВАЛЮТ',
                style: TextStyle(
                  color: _cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                indicators.lastUpdated.year > 2000
                    ? '${indicators.lastUpdated.hour.toString().padLeft(2, '0')}:${indicators.lastUpdated.minute.toString().padLeft(2, '0')}'
                    : '--:--',
                style: const TextStyle(
                  color: Color(0xFF666688),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // USD/UAH
          _RateRow(
            flag: '🇺🇸',
            pair: 'USD/UAH',
            rate: indicators.usdUah.toStringAsFixed(2),
            color: _cyan,
          ),
          const SizedBox(height: 14),
          // EUR/UAH
          _RateRow(
            flag: '🇪🇺',
            pair: 'EUR/UAH',
            rate: indicators.eurUah.toStringAsFixed(2),
            color: _green,
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final String flag;
  final String pair;
  final String rate;
  final Color color;

  const _RateRow({
    required this.flag,
    required this.pair,
    required this.rate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            pair,
            style: const TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            rate,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '₴',
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Macroeconomics card
// =========================================================================

class _MacroeconomicsCard extends StatelessWidget {
  final EconomicIndicators indicators;

  const _MacroeconomicsCard({required this.indicators});

  static const _card = Color(0xFF0D1117);
  static const _pink = Color(0xFFFF3366);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📈', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Text(
                'МАКРОЕКОНОМІКА',
                style: TextStyle(
                  color: _purple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Inflation
          _MacroRow(
            icon: '🔥',
            label: 'Інфляція (річна)',
            value: '${indicators.inflationRateUAH.toStringAsFixed(1)}%',
            description: 'Знецінення гривні',
            color: indicators.inflationRateUAH > 10 ? _pink : const Color(0xFF00F0FF),
          ),
          const SizedBox(height: 16),
          // NBU rate
          _MacroRow(
            icon: '🏛️',
            label: 'Ставка НБУ',
            value: '${indicators.interestRateNBU.toStringAsFixed(1)}%',
            description: 'Облікова ставка Нацбанку',
            color: const Color(0xFF00F0FF),
          ),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String description;
  final Color color;

  const _MacroRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFE0E0FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF666688),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// AI explanation card
// =========================================================================

class _AIExplanationCard extends StatelessWidget {
  final EconomicIndicators indicators;
  final double savingsRate;

  const _AIExplanationCard({
    required this.indicators,
    required this.savingsRate,
  });

  static const _card = Color(0xFF0D1117);
  static const _cyan = Color(0xFF00F0FF);
  static const _green = Color(0xFF00FF88);
  static const _pink = Color(0xFFFF3366);

  @override
  Widget build(BuildContext context) {
    final inflation = indicators.inflationRateUAH;
    final nbuRate = indicators.interestRateNBU;

    // Generate contextual AI explanation
    final buffer = StringBuffer();

    buffer.writeln(
      '💡 Зараз інфляція в Україні складає ${inflation.toStringAsFixed(1)}%. '
      'Це означає, що твої заощадження втрачають покупну спроможність, '
      'якщо вони просто лежать без руху.',
    );

    if (inflation > 10) {
      buffer.writeln(
        '\n⚠️ Інфляція вище 10% — це критично! Гроші на рахунку '
        'знецінюються швидше, ніж ростуть. Розглянь депозити або облігації.',
      );
    }

    buffer.writeln(
      '\n🏦 Ставка НБУ ${nbuRate.toStringAsFixed(1)}% — це орієнтир для '
      'відсотків по депозитах. Якщо твій дохід від заощаджень нижчий за '
      'інфляцію — ти втрачаєш гроші в реальному вираженні.',
    );

    if (savingsRate < 0.1) {
      buffer.writeln(
        '\n🔴 Твоя норма заощаджень дуже низька (${(savingsRate * 100).toStringAsFixed(1)}%). '
        'Спробуй відкладати хоча б 10% доходу — це мінімум для фінансової безпеки.',
      );
    } else if (savingsRate >= 0.2) {
      buffer.writeln(
        '\n🟢 Твоя норма заощаджень ${(savingsRate * 100).toStringAsFixed(1)}% — чудово! '
        'Ти випереджаєш інфляцію. Продовжуй в тому ж дусі, VAULT-17 схвалює.',
      );
    }

    buffer.writeln(
      '\n💱 Курс USD/UAH ${indicators.usdUah.toStringAsFixed(2)} — '
      'зберігання частини заощаджень у валюті може захистити від девальвації.',
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green.withOpacity(0.08), _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              const Text(
                'VAULT-17 ПОЯСНЕННЯ',
                style: TextStyle(
                  color: _green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            buffer.toString().trim(),
            style: const TextStyle(
              color: Color(0xFFE0E0FF),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
