import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// =============================================================================
// Voice Vault — AI voice assistant for savings
// =============================================================================
//
// VAULT-17, the cyberpunk AI assistant, listens to voice commands in Ukrainian
// and executes savings operations: deposit to goals, query progress, check
// streaks, balance, and XP. Every voice interaction earns XP.
//
// Flow: ASR (speech-to-text) → AI intent parsing → command execution → TTS
//
// APIs:  OpenRouter (intent parsing + response generation)
//        ASR placeholder (speech-to-text integration point)
//        TTS placeholder (text-to-speech integration point)
// =============================================================================

// -----------------------------------------------------------------------------
// VoiceCommandType — types of voice commands VAULT-17 understands
// -----------------------------------------------------------------------------

enum VoiceCommandType {
  deposit('deposit', 'Поповнення'),
  queryGoal('queryGoal', 'Запит цілі'),
  queryStreak('queryStreak', 'Запит стріку'),
  queryBalance('queryBalance', 'Запит балансу'),
  queryXP('queryXP', 'Запит XP'),
  unknown('unknown', 'Невідома команда');

  final String id;
  final String labelUA;
  const VoiceCommandType(this.id, this.labelUA);
}

// -----------------------------------------------------------------------------
// VoiceCommand — parsed result from AI intent recognition
// -----------------------------------------------------------------------------

class VoiceCommand {
  final VoiceCommandType commandType;
  final String originalText;
  final double? amount;
  final String? goalName;
  final String responseTextUA;

  const VoiceCommand({
    required this.commandType,
    required this.originalText,
    this.amount,
    this.goalName,
    this.responseTextUA = '',
  });

  VoiceCommand copyWith({
    VoiceCommandType? commandType,
    String? originalText,
    double? amount,
    String? goalName,
    String? responseTextUA,
  }) {
    return VoiceCommand(
      commandType: commandType ?? this.commandType,
      originalText: originalText ?? this.originalText,
      amount: amount ?? this.amount,
      goalName: goalName ?? this.goalName,
      responseTextUA: responseTextUA ?? this.responseTextUA,
    );
  }
}

// -----------------------------------------------------------------------------
// VoiceVaultState — reactive state exposed via Riverpod
// -----------------------------------------------------------------------------

class VoiceVaultState {
  final bool isListening;
  final bool isProcessing;
  final bool isSpeaking;
  final VoiceCommand? lastCommand;
  final List<VoiceCommand> commandHistory;
  final String? error;

  const VoiceVaultState({
    this.isListening = false,
    this.isProcessing = false,
    this.isSpeaking = false,
    this.lastCommand,
    this.commandHistory = const [],
    this.error,
  });

  VoiceVaultState copyWith({
    bool? isListening,
    bool? isProcessing,
    bool? isSpeaking,
    VoiceCommand? lastCommand,
    List<VoiceCommand>? commandHistory,
    String? error,
    bool clearError = false,
    bool clearLastCommand = false,
  }) {
    return VoiceVaultState(
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      lastCommand:
          clearLastCommand ? null : (lastCommand ?? this.lastCommand),
      commandHistory: commandHistory ?? this.commandHistory,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// -----------------------------------------------------------------------------
// VoiceVaultNotifier — core voice assistant logic
// -----------------------------------------------------------------------------

class VoiceVaultNotifier extends StateNotifier<VoiceVaultState> {
  final Ref _ref;
  final AppDatabase _db;

  /// XP awarded for each voice command executed.
  static const int _xpPerVoiceCommand = 10;

  /// XP awarded specifically for a voice deposit.
  static const int _xpPerVoiceDeposit = 25;

  /// Maximum command history to keep in state.
  static const int _maxHistoryLength = 50;

  VoiceVaultNotifier(this._ref, this._db) : super(const VoiceVaultState());

  // ===========================================================================
  // Public API
  // ===========================================================================

  /// Start listening for voice input via ASR.
  ///
  /// In production, integrate with a speech-to-text API
  /// (e.g., Google Speech-to-Text, Whisper API, or flutter speech_recognition).
  Future<void> startListening() async {
    if (state.isListening || state.isProcessing) return;

    state = state.copyWith(isListening: true, clearError: true);

    try {
      // ── ASR placeholder ──────────────────────────────────────────────────
      // In production, this would activate the device microphone and stream
      // audio to a speech-to-text service. Example integration:
      //
      //   final speech = SpeechToTextProvider();
      //   await speech.initialize();
      //   speech.listen(onResult: (result) {
      //     if (result.finalResult) {
      //       stopListening();
      //       processVoiceInput(result.recognizedWords);
      //     }
      //   });
      //
      // For now, we simulate ASR completion with a placeholder.
      // The actual text will be provided by calling processVoiceInput() after
      // ASR returns results.

      // Simulate ASR latency — remove this in production
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      state = state.copyWith(
        isListening: false,
        error: 'Помилка розпізнавання голосу: $e',
      );
    }
  }

  /// Stop listening for voice input.
  void stopListening() {
    if (!state.isListening) return;
    state = state.copyWith(isListening: false);
  }

  /// Process voice input text — parse intent with AI and execute command.
  Future<void> processVoiceInput(String text) async {
    if (text.trim().isEmpty) {
      state = state.copyWith(error: 'Порожній голосовий ввід');
      return;
    }

    state = state.copyWith(isProcessing: true, clearError: true);

    try {
      // Parse the voice command using AI
      final command = await _parseIntentWithAI(text);

      // Execute the parsed command
      final executedCommand = await executeCommand(command);

      // Speak the response via TTS
      if (executedCommand.responseTextUA.isNotEmpty) {
        await speakResponse(executedCommand.responseTextUA);
      }

      // Update history
      final updatedHistory = List<VoiceCommand>.from(state.commandHistory)
        ..insert(0, executedCommand);
      if (updatedHistory.length > _maxHistoryLength) {
        updatedHistory.removeRange(_maxHistoryLength, updatedHistory.length);
      }

      state = state.copyWith(
        isProcessing: false,
        lastCommand: executedCommand,
        commandHistory: updatedHistory,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Помилка обробки команди: $e',
      );
    }
  }

  /// Execute a parsed voice command and return the updated command with
  /// response text.
  Future<VoiceCommand> executeCommand(VoiceCommand command) async {
    try {
      final VoiceCommand result;

      switch (command.commandType) {
        case VoiceCommandType.deposit:
          result = await _executeDepositCommand(
            command.goalName ?? '',
            command.amount ?? 0.0,
            command,
          );

        case VoiceCommandType.queryGoal:
          result = await _executeQueryGoalCommand(
            command.goalName ?? '',
            command,
          );

        case VoiceCommandType.queryStreak:
          result = await _executeQueryStreakCommand(command);

        case VoiceCommandType.queryBalance:
          result = await _executeQueryBalanceCommand(command);

        case VoiceCommandType.queryXP:
          result = await _executeQueryXPCommand(command);

        case VoiceCommandType.unknown:
          result = command.copyWith(
            responseTextUA: 'VAULT-17 не розпізнав команду. '
                'Спробуй: "збережи 500 на PS5", '
                '"скільки я зібрав на монітор?", '
                '"який мій стрік?", "який мій баланс?", '
                '"скільки у мене XP?"',
          );
      }

      // Award XP for voice command execution (except unknown)
      if (result.commandType != VoiceCommandType.unknown) {
        final xpAmount = result.commandType == VoiceCommandType.deposit
            ? _xpPerVoiceDeposit
            : _xpPerVoiceCommand;
        await _db.addXP(xpAmount, source: 'voice_vault');
      }

      return result;
    } catch (e) {
      return command.copyWith(
        responseTextUA: 'Системна помилка VAULT-17: $e. '
            'Спробуй ще раз.',
      );
    }
  }

  /// Speak a response via TTS.
  ///
  /// In production, integrate with a text-to-speech API
  /// (e.g., flutter_tts, Google Cloud TTS, or ElevenLabs).
  Future<void> speakResponse(String text) async {
    if (text.isEmpty) return;

    state = state.copyWith(isSpeaking: true);

    try {
      // ── TTS placeholder ──────────────────────────────────────────────────
      // In production, this would send text to a TTS engine and play audio.
      // Example integration:
      //
      //   final tts = FlutterTts();
      //   await tts.setLanguage('uk-UA');
      //   await tts.setPitch(0.9); // slightly lower for cyberpunk feel
      //   await tts.speak(text);
      //   tts.setCompletionHandler(() {
      //     state = state.copyWith(isSpeaking: false);
      //   });
      //
      // For now, we simulate TTS playback duration.
      final estimatedDurationMs = (text.length * 60)
          .clamp(500, 8000); // ~60ms per character
      await Future.delayed(Duration(milliseconds: estimatedDurationMs));
    } catch (e) {
      // TTS failure is non-critical — just log and continue
    } finally {
      state = state.copyWith(isSpeaking: false);
    }
  }

  // ===========================================================================
  // AI Intent Parsing
  // ===========================================================================

  /// Parse user voice input into a structured VoiceCommand using OpenRouter.
  Future<VoiceCommand> _parseIntentWithAI(String text) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);

    // Fallback: rule-based parsing if AI is unavailable
    if (apiKey.isEmpty) {
      return _parseIntentWithRules(text);
    }

    // Fetch user goals to give the AI context for goal name matching
    final goals = await _db.getAllGoals();
    final goalNames = goals.map((g) => g.name).toList();
    final goalsContext = goalNames.isNotEmpty
        ? 'Цілі користувача: ${goalNames.join(', ')}'
        : 'У користувача немає цілей.';

    final systemPrompt = '''Ти VAULT-17 — кіберпанк AI-асистент додатку заощаджень NEONCRED.
Ти розпізнаєш голосові команди українською і перетворюєш їх на структурований JSON.

$goalsContext

Визнач тип команди і видай JSON:
{
  "commandType": "deposit" | "queryGoal" | "queryStreak" | "queryBalance" | "queryXP" | "unknown",
  "amount": <число або null>,
  "goalName": "<назва цілі або null>",
  "responseTextUA": "<відповідь VAULT-17 українською, 1-2 речення, кіберпанк стиль>"
}

Правила:
- "збережи/поклади/додай/перекинь X на Y" → deposit, amount=X, goalName=Y
- "скільки зібрав/залишилось/прогрес на X" → queryGoal, goalName=X
- "який стрік/стрік/серія" → queryStreak
- "який баланс/скільки всього" → queryBalance
- "скільки XP/досвіду/рівень" → queryXP
- Якщо не зрозуміло → unknown

Для deposit: згенеруй мотиваційну відповідь кіберпанк стилем.
Для query команд: згенеруй коротку відповідь-підтвердження що VAULT-17 шукає дані.
Стиль: неймовірний кіберпанк, техно-метафори, звертайся "операторе".''';

    try {
      final result = await openRouter.chatJson(
        systemPrompt: systemPrompt,
        userPrompt: text,
        temperature: 0.3,
        maxTokens: 256,
      );

      if (result == null) {
        return _parseIntentWithRules(text);
      }

      final commandTypeStr = result['commandType'] as String? ?? 'unknown';
      final commandType = VoiceCommandType.values.firstWhere(
        (t) => t.id == commandTypeStr,
        orElse: () => VoiceCommandType.unknown,
      );

      final rawAmount = result['amount'];
      final amount = rawAmount is num ? rawAmount.toDouble() : null;

      final goalName = result['goalName'] as String?;
      final responseTextUA = result['responseTextUA'] as String? ?? '';

      return VoiceCommand(
        commandType: commandType,
        originalText: text,
        amount: amount,
        goalName: goalName,
        responseTextUA: responseTextUA,
      );
    } catch (e) {
      return _parseIntentWithRules(text);
    }
  }

  /// Fallback rule-based intent parser when AI is unavailable.
  VoiceCommand _parseIntentWithRules(String text) {
    final lower = text.toLowerCase();

    // ── Deposit: "збережи 500 на PS5" ────────────────────────────────────
    final depositPatterns = [
      RegExp(r'(?:збережи|поклади|додай|перекинь|відклади)\s+(\d+)\s+(?:на|до|в)\s+(.+)'),
      RegExp(r'(\d+)\s+(?:грн|₴|uah)?\s+(?:на|до|в)\s+(.+)'),
    ];

    for (final pattern in depositPatterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final amount = double.tryParse(match.group(1) ?? '') ?? 0.0;
        final goalName = match.group(2)?.trim() ?? '';
        return VoiceCommand(
          commandType: VoiceCommandType.deposit,
          originalText: text,
          amount: amount,
          goalName: goalName.isNotEmpty ? _capitalize(goalName) : null,
          responseTextUA: 'Операторе, ініціюю переказ $amount₴ на ціль. '
              'Нейронна мережа підтверджує операцію.',
        );
      }
    }

    // ── Query goal: "скільки я зібрав на монітор?" ───────────────────────
    final queryGoalPattern = RegExp(
      r'(?:скільки|як\s*же|який\s*прогрес).*(?:зібрав|залишилось|прогрес|накопичив).*(?:на|до)\s+(.+)',
    );
    final queryGoalMatch = queryGoalPattern.firstMatch(lower);
    if (queryGoalMatch != null) {
      final goalName = queryGoalMatch.group(1)?.trim() ?? '';
      return VoiceCommand(
        commandType: VoiceCommandType.queryGoal,
        originalText: text,
        goalName: goalName.isNotEmpty ? _capitalize(goalName) : null,
        responseTextUA: 'Сканую базу даних за ціллю...',
      );
    }

    // ── Query streak: "який мій стрік?" ──────────────────────────────────
    if (lower.contains('стрік') || lower.contains('сері')) {
      return VoiceCommand(
        commandType: VoiceCommandType.queryStreak,
        originalText: text,
        responseTextUA: 'Аналізую ланцюг операцій оператора...',
      );
    }

    // ── Query balance: "який мій баланс?" ────────────────────────────────
    if (lower.contains('баланс') || lower.contains('скільки всього')) {
      return VoiceCommand(
        commandType: VoiceCommandType.queryBalance,
        originalText: text,
        responseTextUA: 'Підключаюсь до ядра скарбниці...',
      );
    }

    // ── Query XP: "скільки у мене XP?" ───────────────────────────────────
    if (lower.contains('xp') ||
        lower.contains('досвід') ||
        lower.contains('рівень')) {
      return VoiceCommand(
        commandType: VoiceCommandType.queryXP,
        originalText: text,
        responseTextUA: 'Завантажую матрицю досвіду...',
      );
    }

    return VoiceCommand(
      commandType: VoiceCommandType.unknown,
      originalText: text,
      responseTextUA: 'VAULT-17 не розпізнав команду. '
          'Спробуй: "збережи 500 на PS5", '
          '"скільки я зібрав на монітор?", '
          '"який мій стрік?", "який мій баланс?", '
          '"скільки у мене XP?"',
    );
  }

  // ===========================================================================
  // Command Execution — Deposit
  // ===========================================================================

  Future<VoiceCommand> _executeDepositCommand(
    String goalName,
    double amount,
    VoiceCommand original,
  ) async {
    if (amount <= 0) {
      return original.copyWith(
        responseTextUA: 'VAULT-17: Сума поповнення має бути більше нуля. '
            'Назви суму, операторе.',
      );
    }

    // Find the goal by name (fuzzy match)
    final goals = await _db.getAllGoals();
    final goal = _findGoalByName(goals, goalName);

    if (goal == null) {
      final availableGoals = goals
          .where((g) => !g.isCompleted)
          .map((g) => '"${g.name}"')
          .join(', ');
      return original.copyWith(
        responseTextUA: goals.isEmpty
            ? 'VAULT-17: Ціль не знайдено. Спочатку створи ціль у скарбниці!'
            : 'VAULT-17: Ціль "$goalName" не знайдено. '
                'Доступні цілі: $availableGoals',
      );
    }

    if (goal.isCompleted) {
      return original.copyWith(
        responseTextUA: 'VAULT-17: Ціль "${goal.name}" вже завершена! '
            '${amount.toStringAsFixed(0)}₴ залишились у твоєму розпорядженні, '
            'операторе.',
      );
    }

    // Update goal saved amount
    final newSavedAmount = goal.savedAmount + amount;
    final newCurrentAmount = goal.currentAmount + amount;
    final isNowCompleted = newSavedAmount >= goal.targetAmount;

    await (_db.update(_db.goals)).replace(
      goal.copyWith(
        savedAmount: newSavedAmount,
        currentAmount: newCurrentAmount,
        isCompleted: isNowCompleted,
        lastDepositAt: Value(DateTime.now()),
      ),
    );

    // Record the deposit
    await _db.into(_db.deposits).insert(
          DepositsCompanion(
            goalId: Value(goal.id),
            amount: Value(amount),
            createdAt: Value(DateTime.now()),
          ),
        );

    // Update user's lastDepositAt and streak
    final user = await _db.getUserProfile();
    if (user != null) {
      final now = DateTime.now();
      final lastDeposit = user.lastDepositAt;
      final streakUpdated = _calculateNewStreak(user.currentStreak, lastDeposit, now);

      await (_db.update(_db.users)).replace(
        user.copyWith(
          currentStreak: streakUpdated,
          lastDepositAt: Value(now),
        ),
      );
    }

    // Award voice deposit XP (in addition to the base _xpPerVoiceDeposit
    // awarded in executeCommand)
    await _db.addXP(_xpPerVoiceDeposit, source: 'voice_deposit');

    // Build cyberpunk response
    final percent = goal.targetAmount > 0
        ? (newSavedAmount / goal.targetAmount * 100).toStringAsFixed(1)
        : '0.0';
    final remaining = goal.targetAmount - newSavedAmount;

    String response;
    if (isNowCompleted) {
      response = 'VAULT-17: ЦІЛЬ ЗАВЕРШЕНА! "${goal.name}" досягнута! '
          '${amount.toStringAsFixed(0)}₴ зачислено. '
          'Неонова мережа вітає тебе, операторе! 🎉⚡';
    } else if (remaining > 0) {
      response = 'VAULT-17: ${amount.toStringAsFixed(0)}₴ зачислено на '
          '"${goal.name}". Прогрес: $percent%. '
          'Залишилось: ${remaining.toStringAsFixed(0)}₴. '
          'Квантова мережа задоволена, операторе! ⚡';
    } else {
      response = 'VAULT-17: ${amount.toStringAsFixed(0)}₴ зачислено на '
          '"${goal.name}". Прогрес: $percent%. '
          'Нейронний потік прискорюється!';
    }

    return original.copyWith(responseTextUA: response);
  }

  // ===========================================================================
  // Command Execution — Query Goal
  // ===========================================================================

  Future<VoiceCommand> _executeQueryGoalCommand(
    String goalName,
    VoiceCommand original,
  ) async {
    final goals = await _db.getAllGoals();

    // If a specific goal name was mentioned
    if (goalName.isNotEmpty) {
      final goal = _findGoalByName(goals, goalName);

      if (goal == null) {
        return original.copyWith(
          responseTextUA: 'VAULT-17: Ціль "$goalName" не знайдено в базі. '
              'Можливо, вона в архіві чи ще не створена.',
        );
      }

      final percent = goal.targetAmount > 0
          ? (goal.savedAmount / goal.targetAmount * 100).toStringAsFixed(1)
          : '0.0';
      final remaining = goal.targetAmount - goal.savedAmount;
      final statusEmoji = goal.isCompleted ? ' ✅' : '';

      return original.copyWith(
        responseTextUA: 'VAULT-17: Ціль "${goal.name}"$statusEmoji — '
            'зібрано ${goal.savedAmount.toStringAsFixed(0)}₴ '
            'з ${goal.targetAmount.toStringAsFixed(0)}₴ ($percent%). '
            '${goal.isCompleted ? "ЦІЛЬ ЗАВЕРШЕНА! 🎉" : "Залишилось: ${remaining.toStringAsFixed(0)}₴"}',
      );
    }

    // No specific goal — show all active goals summary
    final activeGoals = goals.where((g) => !g.isCompleted).toList();

    if (activeGoals.isEmpty) {
      if (goals.isEmpty) {
        return original.copyWith(
          responseTextUA: 'VAULT-17: Скарбниця порожня, операторе. '
              'Створи свою першу ціль і почни накопичення!',
        );
      }
      return original.copyWith(
        responseTextUA: 'VAULT-17: Всі цілі завершено! Ти — майстер '
            'заощаджень. Час нових викликів, операторе! 🏆',
      );
    }

    final goalsSummary = activeGoals.map((g) {
      final pct = g.targetAmount > 0
          ? (g.savedAmount / g.targetAmount * 100).toStringAsFixed(0)
          : '0';
      return '"${g.name}" ${g.savedAmount.toStringAsFixed(0)}/${g.targetAmount.toStringAsFixed(0)}₴ ($pct%)';
    }).join('; ');

    return original.copyWith(
      responseTextUA: 'VAULT-17: Активні цілі: $goalsSummary. '
          'Нейронна мережа фіксує прогрес, операторе!',
    );
  }

  // ===========================================================================
  // Command Execution — Query Streak
  // ===========================================================================

  Future<VoiceCommand> _executeQueryStreakCommand(
    VoiceCommand original,
  ) async {
    final user = await _db.getUserProfile();

    if (user == null) {
      return original.copyWith(
        responseTextUA: 'VAULT-17: Профіль оператора не знайдено в базі. '
            'Зареєструйся для доступу до нейронної мережі.',
      );
    }

    final streak = user.currentStreak;
    final lastDeposit = user.lastDepositAt;
    final daysSinceLast = lastDeposit != null
        ? DateTime.now().difference(lastDeposit).inDays
        : 999;

    String streakStatus;
    if (streak == 0 || daysSinceLast > 1) {
      streakStatus = 'Стрік розірвано. Час відновити ланцюг!';
    } else if (streak < 7) {
      streakStatus = 'Непоганий старт! Продовжуй ланцюг!';
    } else if (streak < 30) {
      streakStatus = 'Сильний ланцюг! Нейронна мережа горить!';
    } else if (streak < 100) {
      streakStatus = 'ЛЕГЕНДАРНИЙ стрік! Ти — віртуоз заощаджень!';
    } else {
      streakStatus = 'БЕЗСМЕРТНИЙ стрік! Ти — жива легенда системи!';
    }

    return original.copyWith(
      responseTextUA: 'VAULT-17: Твій стрік: $streak днів. '
          '$streakStatus '
          '${daysSinceLast == 0 ? "Сьогоднішнє поповнення зараховано! ⚡" : daysSinceLast == 1 ? "Зроби поповнення сьогодні, щоб зберегти стрік!" : ""}',
    );
  }

  // ===========================================================================
  // Command Execution — Query Balance
  // ===========================================================================

  Future<VoiceCommand> _executeQueryBalanceCommand(
    VoiceCommand original,
  ) async {
    final goals = await _db.getAllGoals();

    if (goals.isEmpty) {
      return original.copyWith(
        responseTextUA: 'VAULT-17: Скарбниця порожня, операторе. '
            'Створи ціль і почни накопичувати нейронну енергію!',
      );
    }

    final totalSaved = goals.fold<double>(0.0, (sum, g) => sum + g.savedAmount);
    final totalTarget = goals.fold<double>(0.0, (sum, g) => sum + g.targetAmount);
    final completedCount = goals.where((g) => g.isCompleted).length;
    final activeCount = goals.length - completedCount;

    final overallPercent = totalTarget > 0
        ? (totalSaved / totalTarget * 100).toStringAsFixed(1)
        : '0.0';

    return original.copyWith(
      responseTextUA: 'VAULT-17: Загальний баланс: '
          '${totalSaved.toStringAsFixed(0)}₴ з ${totalTarget.toStringAsFixed(0)}₴ '
          '($overallPercent%). '
          'Активних цілей: $activeCount, завершено: $completedCount. '
          'Квантова скарбниця стабільна, операторе! 💎',
    );
  }

  // ===========================================================================
  // Command Execution — Query XP (not in task spec but in enum)
  // ===========================================================================

  Future<VoiceCommand> _executeQueryXPCommand(
    VoiceCommand original,
  ) async {
    final user = await _db.getUserProfile();

    if (user == null) {
      return original.copyWith(
        responseTextUA: 'VAULT-17: Профіль оператора не знайдено. '
            'Зареєструйся для доступу до матриці досвіду.',
      );
    }

    final xp = user.xp;
    final level = user.level;
    final xpForNextLevel = level * 500; // 500 XP per level
    final xpInCurrentLevel = xp - ((level - 1) * 500);
    final progressPercent =
        (xpInCurrentLevel / 500 * 100).toStringAsFixed(0);

    return original.copyWith(
      responseTextUA: 'VAULT-17: Рівень $level | XP: $xp. '
          'Прогрес до рівня ${level + 1}: $progressPercent% '
          '($xpInCurrentLevel/500 XP). '
          'Нейронна мережа фіксує зростання, операторе! ⚡',
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  /// Find a goal by name with fuzzy matching (case-insensitive, partial match).
  Goal? _findGoalByName(List<Goal> goals, String name) {
    if (name.isEmpty) return null;

    final lower = name.toLowerCase();

    // Exact match (case-insensitive)
    for (final goal in goals) {
      if (goal.name.toLowerCase() == lower) return goal;
    }

    // Partial match: goal name contains the query or vice versa
    for (final goal in goals) {
      final goalLower = goal.name.toLowerCase();
      if (goalLower.contains(lower) || lower.contains(goalLower)) {
        return goal;
      }
    }

    // Word-level match
    final queryWords = lower.split(RegExp(r'\s+'));
    for (final goal in goals) {
      final goalWords = goal.name.toLowerCase().split(RegExp(r'\s+'));
      final overlap = queryWords.any(
        (qw) => goalWords.any((gw) => gw.contains(qw) || qw.contains(gw)),
      );
      if (overlap) return goal;
    }

    return null;
  }

  /// Calculate new streak based on last deposit date.
  int _calculateNewStreak(
    int currentStreak,
    DateTime? lastDepositAt,
    DateTime now,
  ) {
    if (lastDepositAt == null) return 1;

    final lastDate = DateTime(
      lastDepositAt.year,
      lastDepositAt.month,
      lastDepositAt.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(lastDate).inDays;

    if (diff == 0) {
      // Same day deposit — streak unchanged
      return currentStreak;
    } else if (diff == 1) {
      // Next day deposit — streak continues
      return currentStreak + 1;
    } else {
      // Streak broken — restart from 1
      return 1;
    }
  }

  /// Capitalize the first letter of a string.
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

// -----------------------------------------------------------------------------
// Riverpod provider
// -----------------------------------------------------------------------------

final voiceVaultProvider =
    StateNotifierProvider<VoiceVaultNotifier, VoiceVaultState>((ref) {
  final db = ref.watch(databaseProvider);
  return VoiceVaultNotifier(ref, db);
});
