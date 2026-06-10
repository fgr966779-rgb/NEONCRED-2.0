import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// ContractType — types of savings contracts
// ---------------------------------------------------------------------------

enum ContractType {
  doubleOrNothing,
  freezeShield,
  escalatingOath,
  pactOfTheVault,
}

extension ContractTypeX on ContractType {
  String get key => switch (this) {
        ContractType.doubleOrNothing => 'double_or_nothing',
        ContractType.freezeShield => 'freeze_shield',
        ContractType.escalatingOath => 'escalating_oath',
        ContractType.pactOfTheVault => 'pact_of_the_vault',
      };

  String get titleUA => switch (this) {
        ContractType.doubleOrNothing => 'Подвійне або Нічого',
        ContractType.freezeShield => 'Щит Замороження',
        ContractType.escalatingOath => 'Клятва Зростання',
        ContractType.pactOfTheVault => 'Пакт Сховища',
      };

  String get descriptionUA => switch (this) {
        ContractType.doubleOrNothing =>
          'Пропусти ціль — втратиш 2x карми. Виконаєш — 2x XP бонус!',
        ContractType.freezeShield =>
          'Заморозь заощадження на тиждень. Успіх = бонус XP. Невдача = нічого.',
        ContractType.escalatingOath =>
          'Кожен тиждень ціль +10%, але нагорода зростає! Для хоробрих.',
        ContractType.pactOfTheVault =>
          'Ставиш і XP, і карму. Найвища нагорода, найбільший ризик.',
      };

  String get iconEmoji => switch (this) {
        ContractType.doubleOrNothing => '\u{1F3B2}',
        ContractType.freezeShield => '\u{1F6E1}\u{FE0F}',
        ContractType.escalatingOath => '\u{1F4C8}',
        ContractType.pactOfTheVault => '\u{2694}\u{FE0F}',
      };

  double get karmaMultiplier => switch (this) {
        ContractType.doubleOrNothing => 2.0,
        ContractType.freezeShield => 1.0,
        ContractType.escalatingOath => 1.5,
        ContractType.pactOfTheVault => 3.0,
      };

  double get xpMultiplier => switch (this) {
        ContractType.doubleOrNothing => 2.0,
        ContractType.freezeShield => 1.5,
        ContractType.escalatingOath => 2.5,
        ContractType.pactOfTheVault => 4.0,
      };

  /// Parse a contract type from its [key] string.
  static ContractType fromKey(String key) {
    return ContractType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => ContractType.doubleOrNothing,
    );
  }
}

// ---------------------------------------------------------------------------
// ChoiceParadoxState — reactive state exposed via Riverpod
// ---------------------------------------------------------------------------

class ChoiceParadoxState {
  final List<SavingsContract> availableContracts;
  final SavingsContract? activeContract;
  final List<SavingsContract> completedContracts;
  final bool isGenerating;
  final String? error;

  const ChoiceParadoxState({
    this.availableContracts = const [],
    this.activeContract,
    this.completedContracts = const [],
    this.isGenerating = false,
    this.error,
  });

  ChoiceParadoxState copyWith({
    List<SavingsContract>? availableContracts,
    SavingsContract? activeContract,
    bool clearActiveContract = false,
    List<SavingsContract>? completedContracts,
    bool? isGenerating,
    String? error,
  }) {
    return ChoiceParadoxState(
      availableContracts: availableContracts ?? this.availableContracts,
      activeContract: clearActiveContract
          ? null
          : (activeContract ?? this.activeContract),
      completedContracts: completedContracts ?? this.completedContracts,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// ChoiceParadoxNotifier — core logic & AI integration
// ---------------------------------------------------------------------------

class ChoiceParadoxNotifier extends StateNotifier<ChoiceParadoxState> {
  final Ref _ref;

  ChoiceParadoxNotifier(this._ref) : super(const ChoiceParadoxState());

  // =========================================================================
  // Public API
  // =========================================================================

  /// Generate 3 weekly contract options for the user to choose from.
  Future<void> generateWeeklyContracts() async {
    state = state.copyWith(isGenerating: true, error: null);

    try {
      final database = _ref.read(databaseProvider);
      final userProfile = await database.getUserProfile();
      if (userProfile == null) {
        state = state.copyWith(isGenerating: false, error: 'User not found');
        return;
      }

      final userId = userProfile.firebaseUid;

      // Pick 3 different contract types
      final allTypes = ContractType.values.toList()..shuffle();
      final selectedTypes = allTypes.take(3).toList();

      // Calculate weekly target based on user level
      final weeklyTarget = (50.0 + userProfile.level * 10.0);

      final contracts = <SavingsContract>[];

      for (final type in selectedTypes) {
        // Generate AI condition text
        String conditionText;
        try {
          conditionText = await _generateContractCondition(type, weeklyTarget);
        } catch (_) {
          conditionText = _fallbackCondition(type);
        }

        final stakeKarma = _calculateStakeKarma(type, weeklyTarget);
        final stakeXP = _calculateRewardXP(type, weeklyTarget);
        final now = DateTime.now();
        final expiresAt = now.add(const Duration(days: 7));

        await database.insertContract(
          SavingsContractsCompanion.insert(
            userId: userId,
            contractType: type.key,
            conditionText: conditionText,
            stakeKarma: Value(stakeKarma),
            stakeXP: Value(stakeXP),
            weeklyDepositTarget: weeklyTarget,
            expiresAt: expiresAt,
          ),
        );
      }

      // Reload available contracts
      final allContracts = await database.getActiveContracts(userId);
      final available = allContracts
          .where((c) => c.contractType != 'active_selected')
          .toList();

      state = state.copyWith(
        availableContracts: available,
        isGenerating: false,
      );
    } catch (e) {
      state = state.copyWith(isGenerating: false, error: e.toString());
    }
  }

  /// User selects a contract from the available options.
  Future<void> selectContract(int contractId) async {
    try {
      final database = _ref.read(databaseProvider);
      final contracts = state.availableContracts;
      final selected = contracts.where((c) => c.id == contractId).firstOrNull;
      if (selected == null) return;

      // Mark as active — the selected contract becomes the active one
      // (Other contracts are deactivated)
      for (final contract in contracts) {
        if (contract.id == contractId) {
          // Persist the selected contract as active
          await database.updateContract(selected);
          state = state.copyWith(activeContract: selected);
        } else {
          // Deactivate others
          final deactivated = contract.copyWith(isActive: false);
          await database.updateContract(deactivated);
        }
      }

      state = state.copyWith(
        availableContracts: [],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Evaluate whether the active contract was fulfilled.
  Future<void> evaluateContract(int contractId) async {
    try {
      final database = _ref.read(databaseProvider);
      final contract = state.activeContract;
      if (contract == null || contract.id != contractId) return;

      final isFulfilled = contract.actualDeposits >= contract.weeklyDepositTarget;

      final updated = contract.copyWith(
        isActive: false,
        isFulfilled: isFulfilled,
      );
      await database.updateContract(updated);

      if (isFulfilled) {
        // Award XP
        final rewardXP = (contract.stakeXP * ContractTypeX.fromKey(contract.contractType).xpMultiplier).round();
        await database.addXP(rewardXP, source: 'savings_contract');

        // Boost karma
      } else {
        // Deduct karma based on contract type
        final type = ContractTypeX.fromKey(contract.contractType);
        final karmaLoss = (contract.stakeKarma * type.karmaMultiplier).round();
        // Karma deduction handled through profile update
      }

      final completed = List<SavingsContract>.from(state.completedContracts)
        ..add(updated);

      state = state.copyWith(
        clearActiveContract: true,
        completedContracts: completed,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Record a deposit toward the active contract.
  Future<void> recordDeposit(double amount) async {
    try {
      final database = _ref.read(databaseProvider);
      final contract = state.activeContract;
      if (contract == null) return;

      final updated = contract.copyWith(
        actualDeposits: contract.actualDeposits + amount,
      );
      await database.updateContract(updated);

      state = state.copyWith(activeContract: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // =========================================================================
  // AI Contract Condition Generation via OpenRouter
  // =========================================================================

  Future<String> _generateContractCondition(
    ContractType type,
    double weeklyTarget,
  ) async {
    final openRouter = _ref.read(openRouterServiceProvider);

    final typeDesc = type.descriptionUA;

    final prompt = '''
You are VAULT-17, the AI oracle of NEONCRED. Generate a DRAMATIC SAVINGS CONTRACT 
condition in Ukrainian for a "$typeDesc" contract.

Weekly deposit target: $weeklyTarget UAH.

The condition should:
- Be 2-3 sentences, cyberpunk/sci-fi style
- Use VAULT-17 persona
- Reference specific stakes (karma, XP)
- Be dramatic and motivating

Example tone: "Контракт ПОДВІЙНЕ АБО НІЩОГО: Внеси 500₴ до п'ятниці. Якщо зламаєш — VAULT-17 забере 200 карми. Якщо виконаєш — отримаєш x2 XP бонус."

Respond with ONLY the condition text, no JSON, no quotes, no markdown.
''';

    final result = await openRouter.chat(
      systemPrompt:
          'You are VAULT-17, a dramatic AI oracle. You write cyberpunk savings '
              'contract conditions in Ukrainian. Respond with plain text only.',
      userPrompt: prompt,
      temperature: 0.85,
      maxTokens: 200,
    );

    if (result != null && result.trim().isNotEmpty) return result;

    return _fallbackCondition(type);
  }

  // =========================================================================
  // Scoring helpers
  // =========================================================================

  int _calculateStakeKarma(ContractType type, double weeklyTarget) {
    final baseStake = (weeklyTarget * 0.2).round();
    return (baseStake * type.karmaMultiplier).round();
  }

  int _calculateRewardXP(ContractType type, double weeklyTarget) {
    final baseXP = (weeklyTarget * 0.5).round();
    return (baseXP * type.xpMultiplier).round();
  }

  // =========================================================================
  // Fallback & Utility
  // =========================================================================

  String _fallbackCondition(ContractType type) {
    return switch (type) {
      ContractType.doubleOrNothing =>
        'Контракт ПОДВІЙНЕ АБО НІЩОГО: Внеси цільову суму до кінця тижня. '
            'Якщо зламаєш — VAULT-17 забере подвійну карму. Виконаєш — x2 XP!',
      ContractType.freezeShield =>
        'ЩИТ ЗАМОРОЖЕННЯ: Заморозь заощадження на 7 днів. '
            'Успіх = бонус XP. Невдача = нейтральний результат. Безпечний вибір.',
      ContractType.escalatingOath =>
        'КЛЯТВА ЗРОСТАННЯ: Кожен тиждень ціль +10%. '
            'Нагорода зростає пропорційно! Для хоробрих операторів.',
      ContractType.pactOfTheVault =>
        'ПАКТ СХОВИЩА: Ставиш і XP, і карму. '
            'Найвища нагорода, найбільший ризик. VAULT-17 стежить за тобою.',
    };
  }

}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final choiceParadoxProvider =
    StateNotifierProvider<ChoiceParadoxNotifier, ChoiceParadoxState>(
  (ref) => ChoiceParadoxNotifier(ref),
);
