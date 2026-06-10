import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/providers.dart';
import '../../../data/database.dart';

// =============================================================================
// SetupFinishScreen — third (final) onboarding screen
// =============================================================================
//
// Confirms goal setup, creates user profile and goals in database,
// marks onboarding as completed via SharedPreferences,
// then navigates to the dashboard.
// =============================================================================

class SetupFinishScreen extends ConsumerStatefulWidget {
  const SetupFinishScreen({super.key});

  @override
  ConsumerState<SetupFinishScreen> createState() => _SetupFinishScreenState();
}

class _SetupFinishScreenState extends ConsumerState<SetupFinishScreen> {
  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _cardBg = Color(0xFF111827);
  static const _green = Color(0xFF00FF88);

  bool _isSaving = false;

  Future<void> _completeSetup() async {
    setState(() => _isSaving = true);

    try {
      final database = ref.read(databaseProvider);
      final goalATitle = ref.read(onboardingGoalATitleProvider);
      final goalBTitle = ref.read(onboardingGoalBTitleProvider);
      final goalATarget = ref.read(onboardingGoalATargetProvider);
      final goalBTarget = ref.read(onboardingGoalBTargetProvider);

      // Create user profile
      await database.insertUser(
        UsersCompanion(
          displayName: const Value('NetRunner'),
          characterClass: const Value('NetRunner'),
          xp: const Value(0),
          level: const Value(1),
          karma: const Value(10),
          currentStreak: const Value(0),
          notificationsEnabled: const Value(true),
        ),
      );

      // Get the created user
      final user = await database.getUserProfile();

      // Create Goal A
      await database.insertGoal(
        GoalsCompanion.insert(
          name: goalATitle,
          targetAmount: goalATarget,
          userId: Value(user?.id ?? 0),
          category: const Value('electronics'),
        ),
      );

      // Create Goal B
      await database.insertGoal(
        GoalsCompanion.insert(
          name: goalBTitle,
          targetAmount: goalBTarget,
          userId: Value(user?.id ?? 0),
          category: const Value('electronics'),
        ),
      );

      // Mark onboarding as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: const Color(0xFFFF3366),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalATitle = ref.watch(onboardingGoalATitleProvider);
    final goalBTitle = ref.watch(onboardingGoalBTitleProvider);
    final goalATarget = ref.watch(onboardingGoalATargetProvider);
    final goalBTarget = ref.watch(onboardingGoalBTargetProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _cyan, size: 20),
          onPressed: () => context.go('/onboarding-goals'),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_cyan, _purple],
          ).createShader(bounds),
          child: Text(
            'ПІДСУМОК',
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
            const SizedBox(height: 16),

            // Success icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green.withOpacity(0.4), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.1),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: _green,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'Все готово!',
                style: GoogleFonts.orbitron(
                  color: _green,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                'Перевір свої цілі перед стартом',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Goal A summary
            _SummaryCard(
              label: 'ЦІЛЬ А',
              name: goalATitle,
              target: goalATarget,
              cyan: _cyan,
              purple: _purple,
              cardBg: _cardBg,
            ),

            const SizedBox(height: 16),

            // Goal B summary
            _SummaryCard(
              label: 'ЦІЛЬ Б',
              name: goalBTitle,
              target: goalBTarget,
              cyan: _cyan,
              purple: _purple,
              cardBg: _cardBg,
            ),

            const SizedBox(height: 32),

            // Profile info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cyan.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: _purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NetRunner',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Рівень 1 // XP: 0',
                          style: GoogleFonts.shareTechMono(
                            color: _cyan.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Confirm button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: _bg,
                  disabledBackgroundColor: _green.withOpacity(0.2),
                  disabledForegroundColor: _bg.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: _bg,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'АКТИВУВАТИ',
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

class _SummaryCard extends StatelessWidget {
  final String label;
  final String name;
  final double target;
  final Color cyan;
  final Color purple;
  final Color cardBg;

  const _SummaryCard({
    required this.label,
    required this.name,
    required this.target,
    required this.cyan,
    required this.purple,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cyan.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [cyan, purple],
                  ).createShader(bounds),
                  child: Text(
                    label,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${target.toInt()} UAH',
            style: GoogleFonts.shareTechMono(
              color: cyan,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
