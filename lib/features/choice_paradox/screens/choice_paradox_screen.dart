import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../services/choice_paradox_service.dart';

// =========================================================================
// ChoiceParadoxScreen — weekly savings contract selection
// =========================================================================

class ChoiceParadoxScreen extends ConsumerStatefulWidget {
  const ChoiceParadoxScreen({super.key});

  @override
  ConsumerState<ChoiceParadoxScreen> createState() =>
      _ChoiceParadoxScreenState();
}

class _ChoiceParadoxScreenState extends ConsumerState<ChoiceParadoxScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(choiceParadoxProvider);
      if (state.availableContracts.isEmpty && state.activeContract == null) {
        ref.read(choiceParadoxProvider.notifier).generateWeeklyContracts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(choiceParadoxProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1F3AD} Контракти Заощаджень',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: state.isGenerating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00F0FF)),
                  SizedBox(height: 16),
                  Text(
                    'VAULT-17 генерує контракти...',
                    style: TextStyle(color: Color(0xFFB088FF), fontSize: 14),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Active contract
                if (state.activeContract != null)
                  SliverToBoxAdapter(
                    child: _ActiveContractCard(
                      contract: state.activeContract!,
                    ),
                  ),

                // Available contract selection
                if (state.availableContracts.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Text(
                        '\u{1F3AF} ОБЕРИ СВІЙ КОНТРАКТ',
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
                      (context, index) => _ContractOptionCard(
                        contract: state.availableContracts[index],
                      ),
                      childCount: state.availableContracts.length,
                    ),
                  ),
                ],

                // No contracts available
                if (state.availableContracts.isEmpty &&
                    state.activeContract == null)
                  const SliverToBoxAdapter(
                    child: _NoContractsState(),
                  ),

                // Contract types info
                const SliverToBoxAdapter(
                  child: _ContractTypesInfo(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
    );
  }
}

// =========================================================================
// Active contract card
// =========================================================================

class _ActiveContractCard extends StatelessWidget {
  final SavingsContract contract;

  const _ActiveContractCard({required this.contract});

  @override
  Widget build(BuildContext context) {
    final type = ContractTypeX.fromKey(contract.contractType);
    final progress = contract.weeklyDepositTarget > 0
        ? (contract.actualDeposits / contract.weeklyDepositTarget).clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = contract.expiresAt.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A0A2E),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.iconEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  type.titleUA,
                  style: const TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Condition text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6B00FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF6B00FF).withOpacity(0.2),
              ),
            ),
            child: Text(
              contract.conditionText,
              style: const TextStyle(
                color: Color(0xFFB088FF),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${contract.actualDeposits.toStringAsFixed(0)}\u{20B4}',
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${contract.weeklyDepositTarget.toStringAsFixed(0)}\u{20B4}',
                style: const TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF1A0A2E),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF88)),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 12),

          // Stakes info
          Row(
            children: [
              _StakeChip(
                label: '\u{1F525} ${contract.stakeKarma} карма',
                color: const Color(0xFFFF6B00),
              ),
              const SizedBox(width: 8),
              _StakeChip(
                label: '\u{2B50} ${contract.stakeXP} XP',
                color: const Color(0xFF00F0FF),
              ),
              const Spacer(),
              Text(
                '$daysLeft дн.',
                style: TextStyle(
                  color: daysLeft <= 2
                      ? const Color(0xFFFF3366)
                      : const Color(0xFF8888AA),
                  fontSize: 12,
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
// Contract option card (for selection)
// =========================================================================

class _ContractOptionCard extends ConsumerWidget {
  final SavingsContract contract;

  const _ContractOptionCard({required this.contract});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ContractTypeX.fromKey(contract.contractType);

    // Border color by risk level
    final borderColor = type.karmaMultiplier >= 3.0
        ? const Color(0xFFFF3366)
        : type.karmaMultiplier >= 2.0
            ? const Color(0xFFFF6B00)
            : const Color(0xFF00F0FF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(type.iconEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.titleUA,
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      type.descriptionUA,
                      style: const TextStyle(
                        color: Color(0xFF8888AA),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Condition text
          Text(
            contract.conditionText,
            style: const TextStyle(
              color: Color(0xFFB088FF),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 12),

          // Stakes & target
          Row(
            children: [
              Text(
                'Ціль: ${contract.weeklyDepositTarget.toStringAsFixed(0)}\u{20B4}/тиж',
                style: const TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              _StakeChip(
                label: '${contract.stakeKarma} карма',
                color: const Color(0xFFFF6B00),
              ),
              const SizedBox(width: 6),
              _StakeChip(
                label: 'x${type.xpMultiplier} XP',
                color: const Color(0xFF00F0FF),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Select button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  ref.read(choiceParadoxProvider.notifier).selectContract(contract.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: borderColor,
                foregroundColor: const Color(0xFF0A0E17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'ОБРАТИ ЦЕЙ КОНТРАКТ',
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
// Stake chip widget
// =========================================================================

class _StakeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StakeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =========================================================================
// No contracts state
// =========================================================================

class _NoContractsState extends StatelessWidget {
  const _NoContractsState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: const Column(
        children: [
          Text(
            '\u{1F3AD}',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 16),
          Text(
            'Контракти з\'являться незабаром',
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Кожен тиждень VAULT-17 пропонує 3 контракти на вибір. '
            'Обери один — і виконай клятву!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF666688), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Contract types info
// =========================================================================

class _ContractTypesInfo extends StatelessWidget {
  const _ContractTypesInfo();

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
          const Text(
            'ТИПИ КОНТРАКТІВ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...ContractType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(type.iconEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.titleUA,
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Карма x${type.karmaMultiplier} | XP x${type.xpMultiplier}',
                          style: const TextStyle(
                            color: Color(0xFF8888AA),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
