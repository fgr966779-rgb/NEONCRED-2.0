import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../services/bank_sync_service.dart';

// =========================================================================
// BankSyncScreen — bank synchronization dashboard
// =========================================================================

class BankSyncScreen extends ConsumerStatefulWidget {
  const BankSyncScreen({super.key});

  @override
  ConsumerState<BankSyncScreen> createState() => _BankSyncScreenState();
}

class _BankSyncScreenState extends ConsumerState<BankSyncScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bankSyncProvider.notifier).loadExistingConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bankSyncProvider);
    final notifier = ref.read(bankSyncProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1F3E6} Bank Sync Oracle',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF0D1117),
        onRefresh: () => notifier.syncTransactions(),
        child: CustomScrollView(
          slivers: [
            // Connection status card
            SliverToBoxAdapter(
              child: _ConnectionStatusCard(state: state, notifier: notifier),
            ),

            // Auto-saved stats card
            if (state.syncStatus == SyncStatus.connected ||
                state.syncStatus == SyncStatus.synced)
              SliverToBoxAdapter(
                child: _AutoSaveStatsCard(stats: state.stats),
              ),

            // Auto-save rules
            if (state.syncStatus == SyncStatus.connected ||
                state.syncStatus == SyncStatus.synced)
              SliverToBoxAdapter(
                child: _AutoSaveRulesCard(
                  rules: state.autoSaveRules,
                  notifier: notifier,
                ),
              ),

            // Recent transactions
            if (state.recentTransactions.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    '\u{1F4B3} ОСТАННІ ТРАНЗАКЦІЇ',
                    style: TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TransactionCard(
                    transaction: state.recentTransactions[index],
                  ),
                  childCount: state.recentTransactions.length,
                ),
              ),
            ],

            // Connect bank button (when disconnected)
            if (state.syncStatus == SyncStatus.disconnected)
              const SliverToBoxAdapter(
                child: _ConnectBankCard(),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Connection status card
// =========================================================================

class _ConnectionStatusCard extends StatelessWidget {
  final BankSyncState state;
  final BankSyncNotifier notifier;

  const _ConnectionStatusCard({
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(state.syncStatus);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Status icon
          Text(
            state.syncStatus.iconEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),

          // Status label
          Text(
            state.syncStatus.labelUA,
            style: TextStyle(
              color: statusColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Connected bank info
          if (state.connectedBank != null) ...[
            Text(
              '${state.connectedBank!.iconEmoji} ${state.connectedBank!.labelUA}',
              style: const TextStyle(
                color: Color(0xFFB088FF),
                fontSize: 16,
              ),
            ),
          ],

          // Last sync time
          if (state.stats.lastSyncAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Остання синхронізація: ${_formatTime(state.stats.lastSyncAt!)}',
              style: const TextStyle(
                color: Color(0xFF8888AA),
                fontSize: 12,
              ),
            ),
          ],

          // Disconnect button
          if (state.syncStatus == SyncStatus.connected ||
              state.syncStatus == SyncStatus.synced) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => notifier.disconnect(),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF3366),
              ),
              child: const Text('\u{1F534} Відключити банк'),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(SyncStatus status) => switch (status) {
        SyncStatus.disconnected => const Color(0xFF8888AA),
        SyncStatus.connecting => const Color(0xFFFFAA00),
        SyncStatus.connected => const Color(0xFF00FF88),
        SyncStatus.syncing => const Color(0xFF00F0FF),
        SyncStatus.synced => const Color(0xFF00FF88),
        SyncStatus.error => const Color(0xFFFF3366),
      };

  String _formatTime(DateTime time) {
    return '${time.day.toString().padLeft(2, '0')}.'
        '${time.month.toString().padLeft(2, '0')}.'
        '${time.year} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }
}

// =========================================================================
// Auto-save stats card
// =========================================================================

class _AutoSaveStatsCard extends StatelessWidget {
  final BankSyncStats stats;

  const _AutoSaveStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '\u{1F4B0} АВТОМАТИЧНІ ЗАОЩАДЖЕННЯ',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Всього авто-збережено',
                  value: '${stats.totalAutoSaved.toStringAsFixed(0)} грн',
                  color: const Color(0xFF00FF88),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Round-Up збережено',
                  value: '${stats.totalRoundUp.toStringAsFixed(0)} грн',
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Авто-депозитів',
                  value: '${stats.totalAutoDeposits}',
                  color: const Color(0xFFB088FF),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Середній Round-Up',
                  value: '${stats.averageRoundUp.toStringAsFixed(1)} грн',
                  color: const Color(0xFFFFAA00),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8888AA),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// Auto-save rules card
// =========================================================================

class _AutoSaveRulesCard extends StatelessWidget {
  final List<AutoSaveRule> rules;
  final BankSyncNotifier notifier;

  const _AutoSaveRulesCard({
    required this.rules,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '\u{2699}\u{FE0F} ПРАВИЛА АВТО-ЗБЕРЕЖЕННЯ',
                style: TextStyle(
                  color: Color(0xFF6B00FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                onPressed: () => _showAddRuleDialog(context),
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF00F0FF),
                ),
              ),
            ],
          ),
          if (rules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Немає правил. Додайте правило для автоматичного збереження!',
                style: TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 13,
                ),
              ),
            )
          else
            ...rules.map(
              (rule) => _RuleItem(
                rule: rule,
                onToggle: () => notifier.toggleAutoSaveRule(rule.id),
                onRemove: () => notifier.removeAutoSaveRule(rule.id),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddRuleSheet(notifier: notifier),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final AutoSaveRule rule;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  const _RuleItem({
    required this.rule,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rule.isActive
            ? const Color(0xFF00FF88).withOpacity(0.08)
            : const Color(0xFF1A0A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rule.isActive
              ? const Color(0xFF00FF88).withOpacity(0.3)
              : const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Switch(
            value: rule.isActive,
            onChanged: (_) => onToggle(),
            activeColor: const Color(0xFF00FF88),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.ruleType.labelUA,
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  rule.ruleType == AutoSaveRuleType.incomePercentage
                      ? '${rule.value}% від надходжень'
                      : rule.ruleType == AutoSaveRuleType.roundUp
                          ? 'Округлення до ${rule.value} грн'
                          : '${rule.value} грн',
                  style: const TextStyle(
                    color: Color(0xFF8888AA),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete, color: Color(0xFFFF3366), size: 20),
          ),
        ],
      ),
    );
  }
}

class _AddRuleSheet extends StatefulWidget {
  final BankSyncNotifier notifier;

  const _AddRuleSheet({required this.notifier});

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  AutoSaveRuleType _selectedType = AutoSaveRuleType.incomePercentage;
  final _valueController = TextEditingController(text: '10');

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'НОВЕ ПРАВИЛО АВТО-ЗБЕРЕЖЕННЯ',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...AutoSaveRuleType.values.map(
            (type) => ListTile(
              title: Text(
                type.labelUA,
                style: const TextStyle(color: Color(0xFFB088FF)),
              ),
              subtitle: Text(
                type.descriptionUA,
                style: const TextStyle(color: Color(0xFF8888AA), fontSize: 11),
              ),
              leading: Radio<AutoSaveRuleType>(
                value: type,
                groupValue: _selectedType,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
                activeColor: const Color(0xFF00F0FF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFF00F0FF)),
            decoration: InputDecoration(
              labelText: _selectedType == AutoSaveRuleType.incomePercentage
                  ? 'Відсоток (%)'
                  : 'Сума (грн)',
              labelStyle: const TextStyle(color: Color(0xFF8888AA)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6B00FF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF00F0FF)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final value =
                    double.tryParse(_valueController.text) ?? 10.0;
                widget.notifier.addAutoSaveRule(
                  AutoSaveRule(
                    id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
                    ruleType: _selectedType,
                    value: value,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F0FF),
                foregroundColor: const Color(0xFF0A0E17),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '\u{26A1} ДОДАТИ ПРАВИЛО',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Transaction card
// =========================================================================

class _TransactionCard extends StatelessWidget {
  final BankTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final categoryIcon = _categoryIcon(transaction.category);
    final amountColor =
        transaction.isIncome ? const Color(0xFF00FF88) : const Color(0xFFFF3366);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(categoryIcon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    color: Color(0xFFB088FF),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(transaction.date),
                  style: const TextStyle(
                    color: Color(0xFF8888AA),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.isIncome ? '+' : '-'}'
                '${transaction.amount.toStringAsFixed(0)} '
                '${transaction.currency}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (transaction.roundUpAmount != null &&
                  transaction.roundUpAmount! > 0)
                Text(
                  'Round-Up: +${transaction.roundUpAmount!.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryIcon(String category) => switch (category) {
        'groceries' => '\u{1F6D2}',
        'dining' => '\u{1F37D}\u{FE0F}',
        'transport' => '\u{26FD}',
        'cash' => '\u{1F4B5}',
        'income' => '\u{1F4B8}',
        'auto_save' => '\u{1F916}',
        _ => '\u{1F4CB}',
      };

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

// =========================================================================
// Connect bank card (disconnected state)
// =========================================================================

class _ConnectBankCard extends StatelessWidget {
  const _ConnectBankCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Text(
            '\u{1F512} ПІДКЛЮЧИТИ БАНК',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Підключи свій банк для автоматичних заощаджень. '
            'Chunt падає на 60-80% з Bank Sync!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // PrivatBank connect
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Show PrivatBank connection dialog
              },
              icon: const Text('\u{1F3E6}', style: TextStyle(fontSize: 20)),
              label: const Text(
                'ПриватБанк',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AA44),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Plaid connect
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Show Plaid Link flow
              },
              icon: const Text('\u{1F517}', style: TextStyle(fontSize: 20)),
              label: const Text(
                'Plaid (міжнародно)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00F0FF),
                side: const BorderSide(color: Color(0xFF00F0FF)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
