import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../providers/receipt_scanner_provider.dart';

// =============================================================================
// Receipt Scanner Screen — Scan receipts, track spending, motivate savings
// =============================================================================

class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() =>
      _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiptScannerProvider.notifier).loadReceipts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receiptScannerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          'RECEipt SCANNER',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: const Color(0xFF0A0E17),
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00F0FF),
          labelColor: const Color(0xFF00F0FF),
          unselectedLabelColor: const Color(0xFF8B95A5),
          tabs: const [
            Tab(text: 'СКАНЕР'),
            Tab(text: 'ВИТРАТИ'),
            Tab(text: 'АНАЛІЗ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(state),
          _buildSpendingTab(state),
          _buildAnalysisTab(state),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
        onPressed: () => _showAddReceiptSheet(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scanner tab
  // ---------------------------------------------------------------------------

  Widget _buildScannerTab(ReceiptScannerState state) {
    if (state.isScanning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00F0FF)),
            SizedBox(height: 16),
            Text(
              'Сканування чеку...',
              style: TextStyle(color: Color(0xFF8B95A5), fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Show last scanned receipt
    if (state.lastScanned != null) {
      return _buildLastReceiptCard(state.lastScanned!);
    }

    // Empty state
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: const Color(0xFF6B00FF).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Скануй чек камерою',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Або додай витрату вручну',
            style: TextStyle(color: Color(0xFF8B95A5), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFF00F0FF),
              side: const BorderSide(color: Color(0xFF00F0FF)),
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Сканувати чек'),
            onPressed: () => _scanReceipt(),
          ),
        ],
      ),
    );
  }

  Widget _buildLastReceiptCard(ScannedReceipt receipt) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00FF88).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                receipt.category.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  receipt.merchantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${receipt.totalAmount.toStringAsFixed(0)}₴',
            style: const TextStyle(
              color: Color(0xFFFF3366),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Motivation message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6B00FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6B00FF).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFF6B00FF), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    receipt.motivationMessageUA,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          if (receipt.isImpulseBuy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3366).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flash_on, color: Color(0xFFFF3366), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Імпульсивна покупка',
                    style: TextStyle(color: Color(0xFFFF3366), fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Потенційні заощадження: ${receipt.savingsPotentialUAH.toStringAsFixed(0)}₴',
            style: const TextStyle(color: Color(0xFF00FF88), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Spending tab
  // ---------------------------------------------------------------------------

  Widget _buildSpendingTab(ReceiptScannerState state) {
    final summary = state.weeklySummary;
    final stats = state.stats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Weekly summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'ТИЖНЕВИЙ ЗВІТ',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    label: 'Витрачено',
                    value: '${summary.totalSpent.toStringAsFixed(0)}₴',
                    color: const Color(0xFFFF3366),
                  ),
                  _StatColumn(
                    label: 'Можна зберегти',
                    value: '${summary.potentialSavings.toStringAsFixed(0)}₴',
                    color: const Color(0xFF00FF88),
                  ),
                  _StatColumn(
                    label: 'Імпульсів',
                    value: '${summary.impulseBuyCount}',
                    color: const Color(0xFF6B00FF),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Category breakdown
        const Text(
          'ЗА КАТЕГОРІЯМИ',
          style: TextStyle(
            color: Color(0xFF6B00FF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),

        ...SpendingCategory.values.map((cat) {
          final amount = summary.byCategory[cat] ?? 0.0;
          if (amount == 0) return const SizedBox.shrink();

          final percent = summary.totalSpent > 0
              ? (amount / summary.totalSpent * 100)
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.labelUA,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: const Color(0xFF0D1117),
                          color: const Color(0xFF00F0FF),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${amount.toStringAsFixed(0)}₴',
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }),

        // Receipts list
        const SizedBox(height: 24),
        const Text(
          'ОСТАННІ ЧЕКИ',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ...state.receipts.reversed.take(10).map((r) => _buildReceiptListTile(r)),
      ],
    );
  }

  Widget _buildReceiptListTile(ScannedReceipt receipt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(receipt.category.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.merchantName,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatDate(receipt.purchaseDate),
                  style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${receipt.totalAmount.toStringAsFixed(0)}₴',
            style: TextStyle(
              color: receipt.isImpulseBuy
                  ? const Color(0xFFFF3366)
                  : const Color(0xFF00F0FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Analysis tab
  // ---------------------------------------------------------------------------

  Widget _buildAnalysisTab(ReceiptScannerState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6B00FF).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text(
                'АНАЛІТИКА',
                style: TextStyle(
                  color: Color(0xFF6B00FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(
                    label: 'Чеків',
                    value: '${state.stats.totalReceiptsScanned}',
                    color: const Color(0xFF00F0FF),
                  ),
                  _StatColumn(
                    label: 'Витрачено',
                    value: '${state.stats.totalSpentUAH.toStringAsFixed(0)}₴',
                    color: const Color(0xFFFF3366),
                  ),
                  _StatColumn(
                    label: 'Можна зберегти',
                    value: '${state.stats.totalPotentialSavings.toStringAsFixed(0)}₴',
                    color: const Color(0xFF00FF88),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // AI Insight
        if (state.aiInsight != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6B00FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6B00FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFF6B00FF), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'VAULT-17 АНАЛІЗ',
                      style: TextStyle(
                        color: Color(0xFF6B00FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.aiInsight!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6B00FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: state.isGeneratingInsight
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(state.isGeneratingInsight
              ? 'Генерую аналіз...'
              : 'Згенерувати AI-аналіз'),
          onPressed: state.isGeneratingInsight
              ? null
              : () => ref.read(receiptScannerProvider.notifier).generateWeeklyInsight(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Add receipt bottom sheet
  // ---------------------------------------------------------------------------

  void _showAddReceiptSheet(BuildContext context) {
    final merchantCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    SpendingCategory selectedCategory = SpendingCategory.other;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Додати витрату',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: merchantCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Магазин / Опис',
                  labelStyle: TextStyle(color: Color(0xFF8B95A5)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Сума (₴)',
                  labelStyle: TextStyle(color: Color(0xFF8B95A5)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF00F0FF)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Категорія:',
                style: TextStyle(color: Color(0xFF8B95A5), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SpendingCategory.values.map((cat) {
                  final isSelected = cat == selectedCategory;
                  return ChoiceChip(
                    label: Text('${cat.emoji} ${cat.labelUA}'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6B00FF).withValues(alpha: 0.4),
                    backgroundColor: const Color(0xFF0D1117),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF8B95A5),
                      fontSize: 12,
                    ),
                    onSelected: (_) => setSheetState(() => selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B00FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final merchant = merchantCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (merchant.isNotEmpty && amount > 0) {
                      ref.read(receiptScannerProvider.notifier).addManualReceipt(
                            merchantName: merchant,
                            totalAmount: amount,
                            category: selectedCategory,
                          );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Додати', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scan receipt (camera trigger)
  // ---------------------------------------------------------------------------

  void _scanReceipt() {
    // In production, use image_picker + camera:
    // final image = await ImagePicker().pickImage(source: ImageSource.camera);
    // final bytes = await image.readAsBytes();
    // final base64 = base64Encode(bytes);
    // ref.read(receiptScannerProvider.notifier).scanReceipt(base64);

    // For now, show manual entry
    _showAddReceiptSheet(context);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

// =============================================================================
// Helper widgets
// =============================================================================

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B95A5), fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
