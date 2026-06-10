import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/providers.dart';

// =============================================================================
// GoalSetupScreen — second onboarding screen
// =============================================================================
//
// User enters names and target amounts for two initial goals.
// Uses onboarding state providers to persist data between screens.
// =============================================================================

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _cardBg = Color(0xFF111827);

  late final TextEditingController _goalANameController;
  late final TextEditingController _goalBNameController;
  late final TextEditingController _goalATargetController;
  late final TextEditingController _goalBTargetController;

  @override
  void initState() {
    super.initState();
    _goalANameController = TextEditingController(
      text: ref.read(onboardingGoalATitleProvider),
    );
    _goalBNameController = TextEditingController(
      text: ref.read(onboardingGoalBTitleProvider),
    );
    _goalATargetController = TextEditingController(
      text: ref.read(onboardingGoalATargetProvider).toInt().toString(),
    );
    _goalBTargetController = TextEditingController(
      text: ref.read(onboardingGoalBTargetProvider).toInt().toString(),
    );
  }

  @override
  void dispose() {
    _goalANameController.dispose();
    _goalBNameController.dispose();
    _goalATargetController.dispose();
    _goalBTargetController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final nameA = _goalANameController.text.trim();
    final nameB = _goalBNameController.text.trim();
    final targetA = double.tryParse(_goalATargetController.text) ?? 0;
    final targetB = double.tryParse(_goalBTargetController.text) ?? 0;
    return nameA.isNotEmpty && nameB.isNotEmpty && targetA > 0 && targetB > 0;
  }

  void _proceed() {
    if (!_isValid) return;

    ref.read(onboardingGoalATitleProvider.notifier).state =
        _goalANameController.text.trim();
    ref.read(onboardingGoalATargetProvider.notifier).state =
        double.tryParse(_goalATargetController.text) ?? 25000.0;
    ref.read(onboardingGoalBTitleProvider.notifier).state =
        _goalBNameController.text.trim();
    ref.read(onboardingGoalBTargetProvider.notifier).state =
        double.tryParse(_goalBTargetController.text) ?? 15000.0;

    context.go('/onboarding-finish');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _cyan, size: 20),
          onPressed: () => context.go('/welcome'),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_cyan, _purple],
          ).createShader(bounds),
          child: Text(
            'ЦІЛІ',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _cyan, _purple, Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            Text(
              'Встанови свої фінансові цілі',
              style: GoogleFonts.shareTechMono(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 32),

            // Goal A Card
            _GoalCard(
              label: 'ЦІЛЬ А',
              icon: Icons.flag,
              nameController: _goalANameController,
              targetController: _goalATargetController,
              nameHint: 'Назва цілі...',
              cyan: _cyan,
              purple: _purple,
              cardBg: _cardBg,
              bg: _bg,
            ),

            const SizedBox(height: 24),

            // Goal B Card
            _GoalCard(
              label: 'ЦІЛЬ Б',
              icon: Icons.track_changes,
              nameController: _goalBNameController,
              targetController: _goalBTargetController,
              nameHint: 'Назва цілі...',
              cyan: _cyan,
              purple: _purple,
              cardBg: _cardBg,
              bg: _bg,
            ),

            const SizedBox(height: 48),

            // Next button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isValid ? _proceed : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cyan,
                  foregroundColor: _bg,
                  disabledBackgroundColor: _cyan.withOpacity(0.2),
                  disabledForegroundColor: _bg.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'ДАЛІ',
                  style: GoogleFonts.orbitron(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    fontSize: 15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController nameController;
  final TextEditingController targetController;
  final String nameHint;
  final Color cyan;
  final Color purple;
  final Color cardBg;
  final Color bg;

  const _GoalCard({
    required this.label,
    required this.icon,
    required this.nameController,
    required this.targetController,
    required this.nameHint,
    required this.cyan,
    required this.purple,
    required this.cardBg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cyan.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: cyan.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cyan, size: 20),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [cyan, purple],
                ).createShader(bounds),
                child: Text(
                  label,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Name input
          Text(
            'НАЗВА',
            style: GoogleFonts.orbitron(
              color: cyan,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: nameHint,
              hintStyle: GoogleFonts.shareTechMono(color: Colors.white24),
              filled: true,
              fillColor: bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cyan.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: cyan, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Target amount input
          Text(
            'СУМА (ГРН)',
            style: GoogleFonts.orbitron(
              color: cyan,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: targetController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.shareTechMono(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: '25000',
              hintStyle: GoogleFonts.shareTechMono(color: Colors.white24),
              filled: true,
              fillColor: bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: cyan.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: cyan, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              suffixText: 'UAH',
              suffixStyle: GoogleFonts.shareTechMono(
                color: cyan.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
