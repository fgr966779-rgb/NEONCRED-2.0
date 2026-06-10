import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';

// =============================================================================
// Savings Quest Chain — Retention 2026 Feature #1
// =============================================================================
//
// Геймифікована система щоденних/тижневих мікро-квестів:
// "Відклади 50 грн сьогодні", "Скануй ціну", "Знайди дешевше на 10%".
// Квести з'єднуються в ланцюги — 5 підряд = множник XP x2.
// Серія переривається = ланцюг згорає (FOMO-ефект).
//
// API: OpenRouter для персоналізованих квестів
// XP: +5 за квест, x1.5 за 3 підряд, x2 за 5 підряд
// =============================================================================

/// Quest type definitions.
enum QuestType {
  dailyDeposit('daily_deposit', 'Відкласти сьогодні'),
  priceScan('price_scan', 'Сканувати ціну'),
  receiptScan('receipt_scan', 'Сканувати чек'),
  weeklySavings('weekly_savings', 'Тижневе заощадження'),
  noSpendDay('no_spend_day', 'День без витрат'),
  goalProgress('goal_progress', 'Прогрес цілі'),
  priceCompare('price_compare', 'Порівняти ціни');

  const QuestType(this.id, this.labelUA);
  final String id;
  final String labelUA;
}

/// Rich model for a quest with chain context.
class QuestModel {
  final QuestChain data;
  final int chainProgress; // completedInChain for the whole chain
  final double chainCompletionPercent;
  final bool isChainComplete;
  final double effectiveXpMultiplier;

  const QuestModel({
    required this.data,
    this.chainProgress = 0,
    this.chainCompletionPercent = 0.0,
    this.isChainComplete = false,
    this.effectiveXpMultiplier = 1.0,
  });

  /// Progress of this individual quest.
  double get questProgress =>
      data.targetValue > 0 ? (data.currentValue / data.targetValue).clamp(0.0, 1.0) : 0.0;

  /// Quest is done.
  bool get isQuestComplete => data.isCompleted;

  /// Quest expired without completion.
  bool get isQuestFailed => data.isFailed;

  /// Quest is still active.
  bool get isActive => !isQuestComplete && !isQuestFailed;

  /// Remaining value to complete.
  double get remaining => (data.targetValue - data.currentValue).clamp(0.0, double.infinity);

  /// XP that will be awarded (with multiplier).
  int get actualXpReward => (data.xpReward * effectiveXpMultiplier).round();
}

/// State for the Quest Chain feature.
class QuestChainState {
  final List<QuestModel> quests;
  final bool isLoading;
  final String? error;
  final int activeChains;
  final int completedChains;
  final int totalXpEarned;

  const QuestChainState({
    this.quests = const [],
    this.isLoading = false,
    this.error,
    this.activeChains = 0,
    this.completedChains = 0,
    this.totalXpEarned = 0,
  });

  int get activeQuestCount => quests.where((q) => q.isActive).length;
  int get completedToday => quests
      .where((q) =>
          q.isQuestComplete &&
          q.data.completedAt != null &&
          DateTime.now().difference(q.data.completedAt!).inDays == 0)
      .length;

  QuestChainState copyWith({
    List<QuestModel>? quests,
    bool? isLoading,
    String? error,
    int? activeChains,
    int? completedChains,
    int? totalXpEarned,
  }) {
    return QuestChainState(
      quests: quests ?? this.quests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeChains: activeChains ?? this.activeChains,
      completedChains: completedChains ?? this.completedChains,
      totalXpEarned: totalXpEarned ?? this.totalXpEarned,
    );
  }
}

/// StateNotifier for Savings Quest Chain.
class QuestChainNotifier extends StateNotifier<QuestChainState> {
  final AppDatabase _db;
  final OpenRouterService _ai;

  QuestChainNotifier(this._db, this._ai)
      : super(const QuestChainState());

  /// Loads all quests from the database.
  Future<void> loadQuests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Clean up expired quests first
      await _db.deleteExpiredQuestChains();

      final allQuests = await _db.getAllQuestChains();
      final activeQuests = await _db.getActiveQuestChains();

      // Group by chainId for chain progress
      final chainGroups = <String, List<QuestChain>>{};
      for (final q in allQuests) {
        chainGroups.putIfAbsent(q.chainId, () => []).add(q);
      }

      int activeChains = 0;
      int completedChains = 0;
      int totalXp = 0;

      final models = activeQuests.map((q) {
        final chain = chainGroups[q.chainId] ?? [];
        final completedInChain = chain.where((c) => c.isCompleted).length;
        final chainPercent = chain.isNotEmpty ? completedInChain / chain.length : 0.0;
        final isComplete = completedInChain == chain.length && chain.isNotEmpty;

        if (isComplete) {
          completedChains++;
        } else {
          activeChains++;
        }

        // XP multiplier based on chain progress
        double multiplier = 1.0;
        if (completedInChain >= 5) {
          multiplier = 2.0;
        } else if (completedInChain >= 3) {
          multiplier = 1.5;
        }

        totalXp += q.isCompleted ? (q.xpReward * multiplier).round() : 0;

        return QuestModel(
          data: q,
          chainProgress: completedInChain,
          chainCompletionPercent: chainPercent,
          isChainComplete: isComplete,
          effectiveXpMultiplier: multiplier,
        );
      }).toList();

      // Also add completed quests for history
      final completedQuests = allQuests
          .where((q) => q.isCompleted || q.isFailed)
          .map((q) => QuestModel(
                data: q,
                effectiveXpMultiplier: 1.0,
              ))
          .toList();

      final allModels = [...models, ...completedQuests];

      state = state.copyWith(
        quests: allModels,
        isLoading: false,
        activeChains: activeChains,
        completedChains: completedChains,
        totalXpEarned: totalXp,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Generates a new quest chain (5 quests) via AI.
  Future<void> generateNewChain() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final goals = await _db.getActiveGoals();
      final deposits = await _db.getAllDeposits();
      final user = await _db.getUserProfile();

      // Calculate average deposit amount for personalization
      double avgDeposit = 0;
      if (deposits.isNotEmpty) {
        avgDeposit = deposits.map((d) => d.amount).reduce((a, b) => a + b) /
            deposits.length;
      }

      final goalNames = goals.map((g) => g.name).join(', ');
      final chainId = 'QC-${_randomId()}';

      // Ask AI to generate personalized quests
      final result = await _ai.chatJson(
        systemPrompt:
            'Ти VAULT-17, кібернетичний майстер квестів в NEONCRED. '
            'Генеруй персоналізовані квести для заощадження українською. '
            'Відповідай ТІЛЬКИ JSON масив з 5 квестів. '
            'Кожен квест має бути реалістичним і мотивуючим. '
            'Типи: daily_deposit, price_scan, receipt_scan, weekly_savings, no_spend_day, goal_progress, price_compare',
        userPrompt:
            'Цілі юзера: $goalNames\n'
            'Середній депозит: ${avgDeposit.toStringAsFixed(0)} грн\n'
            'Рівень: ${user?.level ?? 1}\n'
            'Поточний стрік: ${user?.currentStreak ?? 0} днів\n\n'
            'Верни JSON масив:\n'
            '[\n'
            '  {\n'
            '    "name": "<назва квесту українською>",\n'
            '    "type": "<тип з списку>",\n'
            '    "target_value": <число>,\n'
            '    "xp_reward": <5-15>\n'
            '  }\n'
            ']',
        temperature: 0.9,
        maxTokens: 600,
      );

      final now = DateTime.now();

      if (result != null) {
        final List<dynamic> questList;
        if (result is List) {
          questList = result as List<dynamic>;
        } else if (result['quests'] is List) {
          questList = result['quests'] as List<dynamic>;
        } else {
          questList = [];
        }
        int position = 1;
        for (final questJson in questList) {
          if (questJson is Map<String, dynamic>) {
            final questType = questJson['type'] as String? ?? 'daily_deposit';
            final questName = questJson['name'] as String? ?? 'Квест заощадження';
            final targetValue =
                (questJson['target_value'] as num?)?.toDouble() ?? 100.0;
            final xpReward = (questJson['xp_reward'] as num?)?.toInt() ?? 5;

            // Each quest expires 2 days from now, giving buffer
            final expiresAt = now.add(Duration(days: 2 + position));

            await _db.insertQuestChain(QuestChainsCompanion.insert(
              chainId: chainId,
              questName: questName,
              questType: questType,
              targetValue: Value(targetValue),
              chainPosition: Value(position),
              chainLength: const Value(5),
              xpReward: Value(xpReward),
              expiresAt: expiresAt,
            ));
            position++;
          }
        }
        if (position == 1) {
          // No valid quests parsed, fallback
          await _generateDefaultChain(chainId, avgDeposit);
        }
      } else {
        // Fallback: generate default quests if AI fails
        await _generateDefaultChain(chainId, avgDeposit);
      }

      await loadQuests();
    } catch (e) {
      // Fallback on error
      final chainId = 'QC-${_randomId()}';
      await _generateDefaultChain(chainId, 100);
      await loadQuests();
    }
  }

  /// Updates quest progress (e.g., when a deposit is made).
  Future<void> updateQuestProgress(String questType, double value) async {
    try {
      final activeQuests = await _db.getActiveQuestChains();
      for (final quest in activeQuests) {
        if (quest.questType == questType && !quest.isCompleted) {
          final newCurrent = quest.currentValue + value;
          final isComplete = newCurrent >= quest.targetValue;

          await _db.updateQuestChain(
            quest.id,
            QuestChainsCompanion(
              currentValue: Value(newCurrent),
              isCompleted: Value(isComplete),
              completedAt: Value(isComplete ? DateTime.now() : null),
            ),
          );

          if (isComplete) {
            // Calculate multiplier based on chain progress
            final chainQuests = await _db.getQuestChainsByChainId(quest.chainId);
            final completedInChain =
                chainQuests.where((q) => q.isCompleted).length;
            double multiplier = 1.0;
            if (completedInChain >= 5) {
              multiplier = 2.0;
            } else if (completedInChain >= 3) {
              multiplier = 1.5;
            }

            final xpAwarded = (quest.xpReward * multiplier).round();
            await _db.addXP(xpAwarded, source: 'quest_chain_complete');

            // Check if entire chain is complete
            if (completedInChain == quest.chainLength) {
              // Chain complete bonus!
              await _db.addXP(25, source: 'quest_chain_full');
            }
          }
        }
      }
      await loadQuests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Marks a quest as failed (chain breaks).
  Future<void> failQuest(int id) async {
    await _db.updateQuestChain(
      id,
      const QuestChainsCompanion(isFailed: Value(true)),
    );
    await loadQuests();
  }

  /// Deletes a quest.
  Future<void> deleteQuest(int id) async {
    await _db.deleteQuestChain(id);
    await loadQuests();
  }

  /// Generates a default chain if AI is unavailable.
  Future<void> _generateDefaultChain(String chainId, double avgDeposit) async {
    final now = DateTime.now();
    final depositTarget = (avgDeposit * 0.5).clamp(50.0, 500.0);

    final defaultQuests = [
      ('Відкласти ${depositTarget.toStringAsFixed(0)} грн', 'daily_deposit', depositTarget, 5),
      ('Скануй ціну на товар', 'price_scan', 1.0, 5),
      ('Знайди дешевше на 10%', 'price_compare', 1.0, 8),
      ('Відкласти ${(depositTarget * 2).toStringAsFixed(0)} грн цього тижня', 'weekly_savings', depositTarget * 2, 10),
      ('День без зайвих витрат', 'no_spend_day', 1.0, 15),
    ];

    int position = 1;
    for (final (name, type, target, xp) in defaultQuests) {
      await _db.insertQuestChain(QuestChainsCompanion.insert(
        chainId: chainId,
        questName: name,
        questType: type,
        targetValue: Value(target),
        chainPosition: Value(position),
        chainLength: const Value(5),
        xpReward: Value(xp),
        expiresAt: now.add(Duration(days: 1 + position)),
      ));
      position++;
    }
  }

  String _randomId() {
    final rng = Random();
    return '${rng.nextInt(90000) + 10000}';
  }
}

/// Provider for the Savings Quest Chain.
final questChainProvider =
    StateNotifierProvider<QuestChainNotifier, QuestChainState>(
  (ref) {
    final db = ref.read(databaseProvider);
    final ai = ref.read(openRouterServiceProvider);
    return QuestChainNotifier(db, ai);
  },
);
