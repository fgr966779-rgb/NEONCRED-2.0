import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voice_vault_provider.dart';

// =============================================================================
// VoiceVaultScreen — cyberpunk voice assistant UI
// =============================================================================
//
// VAULT-17 interactive voice command screen with pulsing mic, neon glow,
// command cards, suggestion chips, and scrollable command history.
// All text is in Ukrainian. Cyberpunk aesthetic throughout.
// =============================================================================

class VoiceVaultScreen extends ConsumerStatefulWidget {
  const VoiceVaultScreen({super.key});

  @override
  ConsumerState<VoiceVaultScreen> createState() => _VoiceVaultScreenState();
}

class _VoiceVaultScreenState extends ConsumerState<VoiceVaultScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Color palette
  // ---------------------------------------------------------------------------
  static const _bgColor = Color(0xFF0A0E17);
  static const _cyanAccent = Color(0xFF00F0FF);
  static const _purpleAccent = Color(0xFF6B00FF);
  static const _pinkAccent = Color(0xFFFF3366);
  static const _greenAccent = Color(0xFF00FF88);
  static const _cardGradientStart = Color(0xFF1A1F2E);
  static const _cardGradientEnd = Color(0xFF0D1117);

  // ---------------------------------------------------------------------------
  // Animation controllers
  // ---------------------------------------------------------------------------
  late final AnimationController _pulseController;
  late final AnimationController _glowController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _glowAnimation;

  // ---------------------------------------------------------------------------
  // Test commands cycle for simulated input
  // ---------------------------------------------------------------------------
  static const _testCommands = [
    'Збережи 500 на PS5',
    'Скільки я зібрав?',
    'Який мій стрік?',
    'Який мій баланс?',
    'Скільки у мене XP?',
  ];
  int _testCommandIndex = 0;

  @override
  void initState() {
    super.initState();

    // Pulse animation — scales the mic button up and down
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation — oscillates the outer glow radius
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 4.0, end: 18.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Mic tap handler — start listening, simulate ASR, then process
  // ---------------------------------------------------------------------------
  Future<void> _onMicTap() async {
    final notifier = ref.read(voiceVaultProvider.notifier);
    final state = ref.read(voiceVaultProvider);

    // If already active, stop
    if (state.isListening || state.isProcessing) {
      notifier.stopListening();
      return;
    }

    // Start listening
    await notifier.startListening();

    // Simulate ASR delay (2 seconds), then feed a test command
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final testInput = _testCommands[_testCommandIndex];
    _testCommandIndex = (_testCommandIndex + 1) % _testCommands.length;

    await notifier.processVoiceInput(testInput);
  }

  // ---------------------------------------------------------------------------
  // Chip tap — immediately process the example command
  // ---------------------------------------------------------------------------
  Future<void> _onChipTap(String command) async {
    final notifier = ref.read(voiceVaultProvider.notifier);
    final state = ref.read(voiceVaultProvider);

    if (state.isListening || state.isProcessing) return;

    await notifier.startListening();

    // Small delay to show "listening" state
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    await notifier.processVoiceInput(command);
  }

  // ---------------------------------------------------------------------------
  // Status text based on current state
  // ---------------------------------------------------------------------------
  String _statusText(VoiceVaultState state) {
    if (state.isSpeaking) return 'Говорю відповідь...';
    if (state.isProcessing) return 'Обробляю...';
    if (state.isListening) return 'Слухаю...';
    return 'Натисни щоб говорити';
  }

  // ---------------------------------------------------------------------------
  // Icon for command type
  // ---------------------------------------------------------------------------
  IconData _commandIcon(VoiceCommandType type) {
    switch (type) {
      case VoiceCommandType.deposit:
        return Icons.savings_rounded;
      case VoiceCommandType.queryGoal:
        return Icons.track_changes_rounded;
      case VoiceCommandType.queryStreak:
        return Icons.local_fire_department_rounded;
      case VoiceCommandType.queryBalance:
        return Icons.account_balance_wallet_rounded;
      case VoiceCommandType.queryXP:
        return Icons.bolt_rounded;
      case VoiceCommandType.unknown:
        return Icons.help_outline_rounded;
    }
  }

  // ---------------------------------------------------------------------------
  // Color for command type
  // ---------------------------------------------------------------------------
  Color _commandColor(VoiceCommandType type) {
    switch (type) {
      case VoiceCommandType.deposit:
        return _greenAccent;
      case VoiceCommandType.queryGoal:
        return _cyanAccent;
      case VoiceCommandType.queryStreak:
        return _pinkAccent;
      case VoiceCommandType.queryBalance:
        return _purpleAccent;
      case VoiceCommandType.queryXP:
        return const Color(0xFFFFD700);
      case VoiceCommandType.unknown:
        return Colors.grey;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final vaultState = ref.watch(voiceVaultProvider);
    final isListening = vaultState.isListening;
    final isProcessing = vaultState.isProcessing;
    final isActive = isListening || isProcessing || vaultState.isSpeaking;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildMicButton(isActive, isListening),
              const SizedBox(height: 20),
              _buildStatusText(vaultState, isActive),
              const SizedBox(height: 8),
              if (vaultState.error != null)
                _buildErrorBanner(vaultState.error!),
              const SizedBox(height: 24),
              if (vaultState.lastCommand != null)
                _buildLastCommandCard(vaultState.lastCommand!),
              const SizedBox(height: 24),
              _buildSuggestionChips(isProcessing),
              const SizedBox(height: 28),
              _buildCommandHistory(vaultState.commandHistory),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      centerTitle: true,
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [_cyanAccent, Color(0xFF00B8D4)],
        ).createShader(bounds),
        child: const Text(
          'VOICE VAULT',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _cyanAccent),
        onPressed: () => Navigator.of(context).pop(),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                _cyanAccent.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Microphone button with pulse & glow
  // ---------------------------------------------------------------------------
  Widget _buildMicButton(bool isActive, bool isListening) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _glowAnimation]),
      builder: (context, child) {
        final scale = isActive ? _pulseAnimation.value : 1.0;
        final glowRadius = isActive ? _glowAnimation.value : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF8B2CF5),
                  _purpleAccent,
                  Color(0xFF4A00B0),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                // Outer glow — cyan when listening, purple when idle
                BoxShadow(
                  color: isListening
                      ? _cyanAccent.withOpacity(0.6)
                      : _purpleAccent.withOpacity(0.5),
                  blurRadius: glowRadius + 12,
                  spreadRadius: glowRadius / 2,
                ),
                // Inner glow
                BoxShadow(
                  color: isListening
                      ? _cyanAccent.withOpacity(0.3)
                      : _purpleAccent.withOpacity(0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: isListening
                    ? _cyanAccent.withOpacity(0.7)
                    : _purpleAccent.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _onMicTap,
                customBorder: const CircleBorder(),
                child: Icon(
                  isListening
                      ? Icons.graphic_eq_rounded
                      : Icons.mic_rounded,
                  size: 48,
                  color: isListening ? _cyanAccent : Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Status text
  // ---------------------------------------------------------------------------
  Widget _buildStatusText(VoiceVaultState state, bool isActive) {
    final text = _statusText(state);
    final color = isActive ? _cyanAccent : Colors.white54;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: color,
          shadows: isActive
              ? [
                  Shadow(color: _cyanAccent.withOpacity(0.5), blurRadius: 12),
                ]
              : null,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Error banner
  // ---------------------------------------------------------------------------
  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A0012), Color(0xFF1A0008)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pinkAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _pinkAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: _pinkAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Last command card
  // ---------------------------------------------------------------------------
  Widget _buildLastCommandCard(VoiceCommand command) {
    final cmdColor = _commandColor(command.commandType);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardGradientStart, _cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cmdColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: cmdColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: type icon + label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cmdColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _commandIcon(command.commandType),
                  color: cmdColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                command.commandType.labelUA,
                style: TextStyle(
                  color: cmdColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Text(
                'VAULT-17',
                style: TextStyle(
                  color: _cyanAccent.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Original command text
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Text(
              '"${command.originalText}"',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Parsed details row
          if (command.amount != null || command.goalName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  if (command.amount != null)
                    _buildDetailChip(
                      icon: Icons.payments_rounded,
                      label: '${command.amount!.toStringAsFixed(0)}₴',
                      color: _greenAccent,
                    ),
                  if (command.amount != null && command.goalName != null)
                    const SizedBox(width: 10),
                  if (command.goalName != null)
                    _buildDetailChip(
                      icon: Icons.flag_rounded,
                      label: command.goalName!,
                      color: _cyanAccent,
                    ),
                ],
              ),
            ),

          // VAULT-17 response
          if (command.responseTextUA.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.smart_toy_rounded, color: cmdColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    command.responseTextUA,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Detail chip (amount / goal name in command card)
  // ---------------------------------------------------------------------------
  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Suggestion chips
  // ---------------------------------------------------------------------------
  Widget _buildSuggestionChips(bool isProcessing) {
    final suggestions = [
      'Збережи 500 на PS5',
      'Скільки я зібрав?',
      'Який мій стрік?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'СПРОБУЙ СКАЗАТИ',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((cmd) {
            return ActionChip(
              onPressed: isProcessing ? null : () => _onChipTap(cmd),
              label: Text(
                cmd,
                style: TextStyle(
                  color: _cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              avatar: Icon(
                Icons.mic_rounded,
                color: _cyanAccent.withOpacity(0.6),
                size: 16,
              ),
              backgroundColor: _cyanAccent.withOpacity(0.06),
              side: BorderSide(color: _cyanAccent.withOpacity(0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Command history list
  // ---------------------------------------------------------------------------
  Widget _buildCommandHistory(List<VoiceCommand> history) {
    if (history.isEmpty) {
      return Column(
        children: [
          Icon(
            Icons.history_rounded,
            color: Colors.white24,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Історія команд порожня',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history_rounded,
              color: Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'ІСТОРІЯ КОМАНД',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Text(
              '${history.length}',
              style: TextStyle(
                color: _cyanAccent.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...history.take(10).map((cmd) => _buildHistoryItem(cmd)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Single history item
  // ---------------------------------------------------------------------------
  Widget _buildHistoryItem(VoiceCommand command) {
    final cmdColor = _commandColor(command.commandType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_cardGradientStart, _cardGradientEnd],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cmdColor.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: cmdColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _commandIcon(command.commandType),
              color: cmdColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command.originalText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (command.responseTextUA.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      command.responseTextUA,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (command.amount != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '${command.amount!.toStringAsFixed(0)}₴',
                style: TextStyle(
                  color: _greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
