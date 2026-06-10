import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/lending_tracker_provider.dart';
import '../services/lending_tracker_service.dart';

class LendingTrackerScreen extends ConsumerStatefulWidget {
  const LendingTrackerScreen({super.key});

  @override
  ConsumerState<LendingTrackerScreen> createState() =>
      _LendingTrackerScreenState();
}

class _LendingTrackerScreenState extends ConsumerState<LendingTrackerScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Color Constants ────────────────────────────────────────────────────
  static const _bg = Color(0xFF0A0E17);
  static const _cardBg = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _red = Color(0xFFFF3366);
  static const _green = Color(0xFF00FF88);
  static const _gold = Color(0xFFFFD700);
  static const _dimText = Color(0xFF8899AA);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lendingTrackerProvider);
    final notifier = ref.read(lendingTrackerProvider.notifier);

    // Auto-check overdue on each build
    notifier.checkOverdue();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text(
          'LENDING TRACKER',
          style: GoogleFonts.orbitron(color: _gold, fontSize: 17),
        ),
        iconTheme: const IconThemeData(color: _gold),
        elevation: 0,
        actions: [
          if (state.stats.hasCollectorBadge)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  'КОЛЕКТОР',
                  style: GoogleFonts.orbitron(color: _gold, fontSize: 9),
                ),
                backgroundColor: _purple.withOpacity(0.4),
                side: BorderSide(color: _gold.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : state.records.isEmpty
              ? _buildEmptyState(notifier)
              : RefreshIndicator(
                  color: _gold,
                  backgroundColor: _cardBg,
                  onRefresh: () async => notifier.checkOverdue(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildStatsBar(state.stats),
                      const SizedBox(height: 16),
                      ..._buildSection(
                        label: 'ПРОСТРОЧЕНІ КОНТРАКТИ',
                        records: state.records
                            .where((r) => r.status == 'overdue')
                            .toList(),
                        notifier: notifier,
                      ),
                      ..._buildSection(
                        label: 'АКТИВНІ КОНТРАКТИ',
                        records: state.records
                            .where((r) => r.status == 'active')
                            .toList(),
                        notifier: notifier,
                      ),
                      ..._buildSection(
                        label: 'ПОВЕРНЕНІ',
                        records: state.records
                            .where((r) => r.status == 'returned')
                            .toList(),
                        notifier: notifier,
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _purple,
        child: const Icon(Icons.add_card, color: _gold),
        onPressed: () => _showCreateDialog(notifier),
      ),
    );
  }

  // ── Stats Bar ──────────────────────────────────────────────────────────

  Widget _buildStatsBar(LendingStats stats) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _statChip('Активно', '${stats.activeCount}', _cyan),
          const SizedBox(width: 12),
          _statChip('Прострочено', '${stats.overdueCount}', _red),
          const SizedBox(width: 12),
          _statChip('Повернено', '${stats.returnedCount}', _green),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ЗАБОРГОВАНІСТЬ',
                  style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 8)),
              Text(
                '${(stats.totalLentActive + stats.totalOverdue).toStringAsFixed(0)} грн',
                style: GoogleFonts.orbitron(
                  color: stats.totalOverdue > 0 ? _red : _cyan,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 8)),
        Text(value,
            style: GoogleFonts.orbitron(color: color, fontSize: 16)),
      ],
    );
  }

  // ── Section Builder ────────────────────────────────────────────────────

  List<Widget> _buildSection({
    required String label,
    required List<LendingRecord> records,
    required LendingTrackerNotifier notifier,
  }) {
    if (records.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          label,
          style: GoogleFonts.orbitron(
            color: _dimText,
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
      ),
      ...records.map((r) => _buildRecordCard(r, notifier)),
    ];
  }

  // ── Record Card ────────────────────────────────────────────────────────

  Widget _buildRecordCard(
      LendingRecord record, LendingTrackerNotifier notifier) {
    final isOverdue = record.status == 'overdue';
    final isActive = record.status == 'active';
    final isReturned = record.status == 'returned';

    final Color accentColor;
    if (isOverdue) {
      accentColor = _red;
    } else if (isActive) {
      accentColor = _cyan;
    } else {
      accentColor = _green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.4)),
        boxShadow: isOverdue
            ? [
                BoxShadow(
                  color: _red.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    record.debtorName,
                    style: GoogleFonts.orbitron(
                      color: accentColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                _buildStatusBadge(record, accentColor),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Row(
                  children: [
                    Text('СУМА: ',
                        style: GoogleFonts.shareTechMono(
                            color: _dimText, fontSize: 11)),
                    Text(
                      '${record.amountUah.toStringAsFixed(0)} грн',
                      style: GoogleFonts.orbitron(
                          color: _gold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Dates row
                Row(
                  children: [
                    _dateChip('ВИДАНО', _formatDate(record.lentAt), _cyan),
                    const SizedBox(width: 16),
                    _dateChip('ТЕРМІН', _formatDate(record.dueDate), _red),
                  ],
                ),
                const SizedBox(height: 6),

                // Overdue / countdown
                if (isOverdue)
                  _buildOverdueIndicator(record)
                else if (isActive)
                  _buildCountdownIndicator(record),

                // Returned badge
                if (isReturned) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: _green, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Повернено ${_formatDate(record.returnedAt!)}',
                        style: GoogleFonts.shareTechMono(
                            color: _green, fontSize: 12),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _green.withOpacity(0.5)),
                        ),
                        child: Text(
                          '+${record.xpAwarded} XP',
                          style: GoogleFonts.orbitron(
                              color: _green, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],

                // Note
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    record.note!,
                    style: GoogleFonts.shareTechMono(
                        color: _dimText, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActive || isOverdue) ...[
                  _actionButton(
                    icon: Icons.notifications_active,
                    label: 'Нагадати',
                    color: _gold,
                    onTap: () => _handleReminder(record, notifier),
                  ),
                  const SizedBox(width: 6),
                  _actionButton(
                    icon: Icons.check_circle,
                    label: 'Повернуто',
                    color: _green,
                    onTap: () => notifier.markAsReturned(record.recordId),
                  ),
                ],
                const SizedBox(width: 6),
                _actionButton(
                  icon: Icons.archive,
                  label: 'Архів',
                  color: _dimText,
                  onTap: () => notifier.archiveRecord(record.recordId),
                ),
                if (isActive) ...[
                  const SizedBox(width: 6),
                  _actionButton(
                    icon: Icons.bug_report,
                    label: 'Сим. прострочення',
                    color: _purple,
                    onTap: () =>
                        notifier.simulateOverdue(record.recordId),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Badge ───────────────────────────────────────────────────────

  Widget _buildStatusBadge(LendingRecord record, Color accentColor) {
    String label;
    if (record.status == 'overdue') {
      label = 'ПРОСТРОЧЕНО';
    } else if (record.status == 'returned') {
      label = 'ПОВЕРНЕНО';
    } else {
      label = 'АКТИВНИЙ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.orbitron(color: accentColor, fontSize: 9),
      ),
    );
  }

  // ── Overdue Pulsing Indicator ──────────────────────────────────────────

  Widget _buildOverdueIndicator(LendingRecord record) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final opacity = 0.5 + 0.5 * _pulseController.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _red.withOpacity(0.1 * opacity),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _red.withOpacity(0.3 * opacity)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: _red.withOpacity(opacity), size: 18),
              const SizedBox(width: 8),
              Text(
                'ПРОСТРОЧЕНО ${record.daysOverdue} дн.',
                style: GoogleFonts.orbitron(
                  color: _red.withOpacity(opacity),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Countdown Indicator ────────────────────────────────────────────────

  Widget _buildCountdownIndicator(LendingRecord record) {
    final days = record.daysUntilDue;
    final urgent = days <= 3;
    final color = urgent ? _gold : _cyan;

    return Row(
      children: [
        Icon(
          urgent ? Icons.timer : Icons.schedule,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          days > 0 ? 'Залишилось $days дн.' : 'Термін сьогодні!',
          style: GoogleFonts.shareTechMono(color: color, fontSize: 12),
        ),
      ],
    );
  }

  // ── Date Chip ──────────────────────────────────────────────────────────

  Widget _dateChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 8)),
        Text(value,
            style: GoogleFonts.shareTechMono(color: color, fontSize: 12)),
      ],
    );
  }

  // ── Action Button ──────────────────────────────────────────────────────

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.shareTechMono(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reminder Handler ──────────────────────────────────────────────────

  Future<void> _handleReminder(
      LendingRecord record, LendingTrackerNotifier notifier) async {
    await notifier.generateReminder(record.recordId);

    final state = ref.read(lendingTrackerProvider);
    if (state.aiReminderText != null && mounted) {
      _showReminderDialog(record, state.aiReminderText!, notifier);
    }
  }

  void _showReminderDialog(
      LendingRecord record, String text, LendingTrackerNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _gold.withOpacity(0.4)),
        ),
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: _gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'КІБЕР-КОЛЕКТОР',
              style: GoogleFonts.orbitron(color: _gold, fontSize: 14),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Нагадування для ${record.debtorName}:',
              style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: SelectableText(
                text,
                style: GoogleFonts.shareTechMono(
                    color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              notifier.clearReminder();
              Navigator.pop(ctx);
            },
            child: Text('Закрити',
                style: GoogleFonts.shareTechMono(color: _dimText)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            style: ElevatedButton.styleFrom(backgroundColor: _purple),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _cardBg,
                  content: Text(
                    'Скопійовано в буфер обміну',
                    style: GoogleFonts.shareTechMono(color: _green),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
              notifier.clearReminder();
              Navigator.pop(ctx);
            },
            label: Text('КОПІЮВАТИ',
                style: GoogleFonts.orbitron(color: _gold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyState(LendingTrackerNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet,
                size: 64, color: _gold.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('LENDING TRACKER',
                style: GoogleFonts.orbitron(color: _gold, fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              'Відстежуй борги та отримуй XP за дисципліну\n+10 XP за контракт  |  +50 XP за повернення',
              style: GoogleFonts.shareTechMono(
                  color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _purple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _purple.withOpacity(0.4)),
              ),
              child: Text(
                'Badge "КОЛЕКТОР" за 5+ повернених боргів',
                style: GoogleFonts.shareTechMono(
                    color: _purple.withOpacity(0.8), fontSize: 11),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_card, color: _gold),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: () => _showCreateDialog(notifier),
              label: Text('СТВОРИТИ КОНТРАКТ',
                  style: GoogleFonts.orbitron(color: _gold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Create Record Dialog ──────────────────────────────────────────────

  void _showCreateDialog(LendingTrackerNotifier notifier) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    final state = ref.read(lendingTrackerProvider);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: _gold.withOpacity(0.4)),
              ),
              title: Text('НОВИЙ КОНТРАКТ',
                  style: GoogleFonts.orbitron(color: _gold, fontSize: 16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Debtor name with autocomplete
                    Text('ІМ\'Я БОРЖНИКА',
                        style: GoogleFonts.orbitron(
                            color: _cyan, fontSize: 10)),
                    const SizedBox(height: 4),
                    Autocomplete<String>(
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        return state.debtorNames.where(
                          (name) => name.toLowerCase().contains(
                              textEditingValue.text.toLowerCase()),
                        );
                      },
                      onSelected: (selection) {
                        nameCtrl.text = selection;
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onFieldSubmitted) {
                        // Sync the autocomplete controller with our controller
                        controller.addListener(() {
                          nameCtrl.text = controller.text;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          style: GoogleFonts.shareTechMono(
                              color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Введіть ім\'я...',
                            hintStyle: GoogleFonts.shareTechMono(
                                color: Colors.white38),
                            prefixIcon: const Icon(Icons.person,
                                color: _cyan, size: 20),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: _cyan.withOpacity(0.5)),
                            ),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            color: _cardBg,
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxHeight: 150, maxWidth: 250),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (context, index) {
                                  final option =
                                      options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      option,
                                      style:
                                          GoogleFonts.shareTechMono(
                                              color: _cyan,
                                              fontSize: 13),
                                    ),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    Text('СУМА (ГРН)',
                        style: GoogleFonts.orbitron(
                            color: _gold, fontSize: 10)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.orbitron(
                          color: _gold, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.orbitron(
                            color: Colors.white24, fontSize: 16),
                        prefixIcon: const Icon(Icons.payments,
                            color: _gold, size: 20),
                        suffixText: 'грн',
                        suffixStyle: GoogleFonts.shareTechMono(
                            color: _dimText, fontSize: 12),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: _gold.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Due Date
                    Text('ТЕРМІН ПОВЕРНЕННЯ',
                        style: GoogleFonts.orbitron(
                            color: _red, fontSize: 10)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                              const Duration(days: 365 * 3)),
                          builder: (ctx, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: _gold,
                                  surface: _cardBg,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => dueDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _red.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: _red, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(dueDate),
                              style: GoogleFonts.shareTechMono(
                                  color: _red, fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down,
                                color: _red),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Note
                    Text('ПРИМІТКА',
                        style: GoogleFonts.orbitron(
                            color: _dimText, fontSize: 10)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: noteCtrl,
                      style: GoogleFonts.shareTechMono(
                          color: Colors.white70),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Необов\'язково...',
                        hintStyle: GoogleFonts.shareTechMono(
                            color: Colors.white24),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: _dimText.withOpacity(0.3)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Скасувати',
                      style:
                          GoogleFonts.shareTechMono(color: _dimText)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _purple),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final amount =
                        double.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (name.isEmpty || amount <= 0) return;

                    notifier.createRecord(
                      debtorName: name,
                      amountUah: amount,
                      dueDate: dueDate,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                  },
                  child: Text('СТВОРИТИ +10 XP',
                      style: GoogleFonts.orbitron(
                          color: _gold, fontSize: 12)),
                ),
              ],
            );
          },
        );
      },
    );
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
