import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/database.dart';
import '../services/smart_alerts_service.dart';

// =========================================================================
// SmartAlertsScreen — SMART PRICE ALERT v2 dashboard (LTV Phase 1)
// =========================================================================

class SmartAlertsScreen extends ConsumerStatefulWidget {
  const SmartAlertsScreen({super.key});

  @override
  ConsumerState<SmartAlertsScreen> createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends ConsumerState<SmartAlertsScreen> {
  @override
  void initState() {
    super.initState();
    // Load alerts on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(smartAlertsProvider.notifier).loadAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smartAlertsProvider);
    final notifier = ref.read(smartAlertsProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(
          'SMART PRICE ALERT',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        actions: [
          // Debug test notification button
          IconButton(
            onPressed: () => notifier.sendTestNotification(),
            icon: const Icon(Icons.science, color: Color(0xFF6B00FF), size: 20),
            tooltip: 'Тестове сповіщення',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // SerpAPI rate limit indicator
          SliverToBoxAdapter(
            child: _RateLimitBar(
              callsUsed: state.serpApiCallsThisMonth,
              callsRemaining: state.serpApiCallsRemaining,
              isLimitReached: state.isSerpApiLimitReached,
            ),
          ),

          // Error banner
          if (state.error != null)
            SliverToBoxAdapter(
              child: _ErrorBanner(error: state.error!),
            ),

          // Check prices button
          SliverToBoxAdapter(
            child: _CheckPricesButton(
              isLoading: state.isLoading,
              activeCount: state.activeAlerts.length,
              onCheck: () => notifier.checkActiveAlerts(),
            ),
          ),

          // Loading indicator
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                ),
              ),
            ),

          // Section: Triggered alerts
          if (state.triggeredAlerts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'СПРИЙНУТІ АЛЕРТИ',
                count: state.triggeredAlerts.length,
                color: const Color(0xFF00FF88),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _AlertCard(
                  alert: state.triggeredAlerts[index],
                  onDismiss: (id) => notifier.dismissTriggeredAlert(id),
                  onContext: (id) => notifier.generateAlertContext(id),
                  onDelete: (id) => notifier.deleteAlert(id),
                ),
                childCount: state.triggeredAlerts.length,
              ),
            ),
          ],

          // Section: Active alerts
          if (state.activeAlerts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'АКТИВНІ АЛЕРТИ',
                count: state.activeAlerts.length,
                color: const Color(0xFF00F0FF),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _AlertCard(
                  alert: state.activeAlerts[index],
                  onDismiss: (id) => notifier.dismissTriggeredAlert(id),
                  onContext: (id) => notifier.generateAlertContext(id),
                  onDelete: (id) => notifier.deleteAlert(id),
                ),
                childCount: state.activeAlerts.length,
              ),
            ),
          ],

          // Empty state
          if (state.alerts.isEmpty && !state.isLoading)
            const SliverToBoxAdapter(child: _EmptyStateCard()),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlertDialog(context),
        backgroundColor: const Color(0xFF00F0FF).withOpacity(0.2),
        foregroundColor: const Color(0xFF00F0FF),
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Create alert dialog
  // ---------------------------------------------------------------------------

  void _showCreateAlertDialog(BuildContext context) {
    final queryController = TextEditingController();
    final priceController = TextEditingController();
    int? selectedGoalId;
    String? selectedGoalName;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1F2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF00F0FF), width: 1),
              ),
              title: Text(
                'НОВИЙ АЛЕРТ',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00F0FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Goal selector
                    FutureBuilder<List<Goal>>(
                      future: ref.read(databaseProvider).getActiveGoals(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text(
                            'Немає активних цілей',
                            style: GoogleFonts.shareTechMono(
                              color: const Color(0xFF8888AA),
                              fontSize: 12,
                            ),
                          );
                        }
                        final goals = snapshot.data!;
                        return DropdownButtonFormField<int>(
                          value: selectedGoalId,
                          decoration: InputDecoration(
                            labelText: 'Прив\'язати до цілі',
                            labelStyle: GoogleFonts.shareTechMono(
                              color: const Color(0xFF8888AA),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF333355)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF00F0FF)),
                            ),
                          ),
                          dropdownColor: const Color(0xFF1A1F2E),
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFFE0E0FF),
                          ),
                          items: goals.map((goal) {
                            return DropdownMenuItem<int>(
                              value: goal.id,
                              child: Text(
                                goal.name,
                                style: GoogleFonts.shareTechMono(
                                  color: const Color(0xFFE0E0FF),
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            setDialogState(() {
                              selectedGoalId = id;
                              final goal = goals.where((g) => g.id == id).firstOrNull;
                              if (goal != null) {
                                selectedGoalName = goal.name;
                                // Auto-fill product query from goal name
                                if (queryController.text.isEmpty) {
                                  queryController.text = goal.name;
                                }
                                // Auto-fill target price from goal target
                                if (priceController.text.isEmpty) {
                                  priceController.text =
                                      goal.targetAmount.toStringAsFixed(0);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: queryController,
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFFE0E0FF),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Товар для відстеження',
                        labelStyle: GoogleFonts.shareTechMono(
                          color: const Color(0xFF8888AA),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF333355)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00F0FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFFE0E0FF),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Цільова ціна (грн)',
                        labelStyle: GoogleFonts.shareTechMono(
                          color: const Color(0xFF8888AA),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF333355)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00F0FF)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '+5 XP за створення алерту',
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFF00FF88),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Скасувати',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8888AA),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final query = queryController.text.trim();
                    final price =
                        double.tryParse(priceController.text.trim()) ?? 0.0;
                    if (query.isNotEmpty &&
                        price > 0 &&
                        selectedGoalId != null) {
                      ref.read(smartAlertsProvider.notifier).createAlert(
                            goalId: selectedGoalId!,
                            productQuery: query,
                            targetPrice: price,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF00F0FF).withOpacity(0.2),
                    foregroundColor: const Color(0xFF00F0FF),
                    side: const BorderSide(color: Color(0xFF00F0FF)),
                  ),
                  child: Text(
                    'Створити',
                    style: GoogleFonts.shareTechMono(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// =========================================================================
// Rate limit bar
// =========================================================================

class _RateLimitBar extends StatelessWidget {
  final int callsUsed;
  final int callsRemaining;
  final bool isLimitReached;

  const _RateLimitBar({
    required this.callsUsed,
    required this.callsRemaining,
    required this.isLimitReached,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = callsRemaining;
    final barColor = isLimitReached || remaining < 20
        ? const Color(0xFFFF3366)     // Red: <20 remaining
        : remaining <= 50
            ? const Color(0xFFFFD700) // Yellow: 20-50 remaining
            : const Color(0xFF00FF88); // Green: >50 remaining
    final percent = (callsUsed / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: barColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SERPAPI',
                style: GoogleFonts.orbitron(
                  color: barColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$callsRemaining / 100 запитів',
                style: GoogleFonts.shareTechMono(
                  color: barColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0xFF1A1F2E),
              color: barColor,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Error banner
// =========================================================================

class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.3)),
      ),
      child: Text(
        error,
        style: GoogleFonts.shareTechMono(
          color: const Color(0xFFFF3366),
          fontSize: 12,
        ),
      ),
    );
  }
}

// =========================================================================
// Check prices button
// =========================================================================

class _CheckPricesButton extends StatelessWidget {
  final bool isLoading;
  final int activeCount;
  final VoidCallback onCheck;

  const _CheckPricesButton({
    required this.isLoading,
    required this.activeCount,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onCheck,
        icon: isLoading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00F0FF),
                ),
              )
            : const Icon(Icons.refresh, color: Color(0xFF00F0FF), size: 18),
        label: Text(
          'ПЕРЕВІРИТИ ЦІНИ ($activeCount)',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00F0FF).withOpacity(0.1),
          side: const BorderSide(color: Color(0xFF00F0FF)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Section header
// =========================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.orbitron(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.orbitron(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Alert card
// =========================================================================

class _AlertCard extends StatefulWidget {
  final PriceAlertModel alert;
  final void Function(int) onDismiss;
  final void Function(int) onContext;
  final void Function(int) onDelete;

  const _AlertCard({
    required this.alert,
    required this.onDismiss,
    required this.onContext,
    required this.onDelete,
  });

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _contextLoading = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final isTriggered = alert.status == AlertStatus.triggered;
    final isActive = alert.status == AlertStatus.active;

    final statusColor = isTriggered
        ? const Color(0xFF00FF88)
        : isActive
            ? const Color(0xFF00F0FF)
            : const Color(0xFF8888AA);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTriggered
            ? const Color(0xFF00FF88).withOpacity(0.05)
            : const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: product + status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.productQuery,
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFE0E0FF),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: alert.status),
            ],
          ),
          const SizedBox(height: 8),

          // Price info
          Row(
            children: [
              Text(
                'Ціль: ',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8888AA),
                  fontSize: 12,
                ),
              ),
              Text(
                '${alert.targetPrice.toStringAsFixed(0)} грн',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00F0FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (alert.currentPrice > 0) ...[
                const SizedBox(width: 12),
                Text(
                  'Зараз: ',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8888AA),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${alert.currentPrice.toStringAsFixed(0)} грн',
                  style: GoogleFonts.orbitron(
                    color: alert.isPriceAtTarget
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF3366),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),

          // Last checked
          if (alert.lastCheckedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Перевірено: ${_formatDateTime(alert.lastCheckedAt!)}',
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF666688),
                fontSize: 10,
              ),
            ),
          ],

          // AI context
          if (alert.aiContext != null && alert.aiContext!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B00FF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFF6B00FF).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.psychology,
                      color: Color(0xFF6B00FF), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      alert.aiContext!,
                      style: GoogleFonts.shareTechMono(
                        color: const Color(0xFFB088FF),
                        fontSize: 11,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isTriggered)
                TextButton(
                  onPressed: () => widget.onDismiss(alert.id),
                  child: Text(
                    'Прибрати',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF8888AA),
                      fontSize: 11,
                    ),
                  ),
                ),
              if (alert.aiContext == null || alert.aiContext!.isEmpty)
                TextButton.icon(
                  onPressed: _contextLoading
                      ? null
                      : () async {
                          setState(() => _contextLoading = true);
                          widget.onContext(alert.id);
                          if (mounted) {
                            setState(() => _contextLoading = false);
                          }
                        },
                  icon: _contextLoading
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6B00FF),
                          ),
                        )
                      : const Icon(Icons.auto_fix_high,
                          color: Color(0xFF6B00FF), size: 14),
                  label: Text(
                    'AI',
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF6B00FF),
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => widget.onDelete(alert.id),
                icon: const Icon(Icons.delete_outline,
                    color: Color(0xFFFF3366), size: 18),
                tooltip: 'Видалити',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// =========================================================================
// Status badge
// =========================================================================

class _StatusBadge extends StatelessWidget {
  final AlertStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == AlertStatus.triggered
        ? const Color(0xFF00FF88)
        : status == AlertStatus.active
            ? const Color(0xFF00F0FF)
            : const Color(0xFF8888AA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.labelUA.toUpperCase(),
        style: GoogleFonts.orbitron(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =========================================================================
// Empty state
// =========================================================================

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333355)),
      ),
      child: Column(
        children: [
          const Icon(Icons.notifications_off,
              color: Color(0xFF333355), size: 48),
          const SizedBox(height: 16),
          Text(
            'НЕМАЄ АЛЕРТІВ',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF8888AA),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Створи алерт, щоб відстежувати падіння цін на товари з твого вішлісту. '
            'SerpAPI перевірятиме ціни 1 раз на добу і надішле сповіщення.',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF666688),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
