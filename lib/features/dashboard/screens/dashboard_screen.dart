import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database.dart';

// =============================================================================
// DashboardScreen — main home screen after onboarding
// =============================================================================
//
// Shows: user profile bar, streak banner, two goal cards with progress,
// prominent "Deposit" button, and quick actions row.
// =============================================================================

/// Provider that streams the user profile from the database.
final _userProfileProvider = FutureProvider<User?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getUserProfile();
});

/// Provider that fetches active goals from the database.
final _activeGoalsProvider = FutureProvider<List<Goal>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getActiveGoals();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _cardBg = Color(0xFF111827);
  static const _green = Color(0xFF00FF88);
  static const _orange = Color(0xFFFF6B00);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(_userProfileProvider);
    final goalsAsync = ref.watch(_activeGoalsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [_cyan, _purple],
          ).createShader(bounds),
          child: Text(
            'NEONCRED',
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: _cyan, size: 22),
            onPressed: () => context.go('/settings'),
          ),
        ],
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
      body: RefreshIndicator(
        color: _cyan,
        backgroundColor: _cardBg,
        onRefresh: () async {
          ref.invalidate(_userProfileProvider);
          ref.invalidate(_activeGoalsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User profile bar
              userAsync.when(
                data: (user) => _ProfileBar(user: user),
                loading: () => const _ProfileBar(user: null),
                error: (_, __) => const _ProfileBar(user: null),
              ),

              const SizedBox(height: 16),

              // Streak banner
              userAsync.when(
                data: (user) => _StreakBanner(streak: user?.currentStreak ?? 0),
                loading: () => const _StreakBanner(streak: 0),
                error: (_, __) => const _StreakBanner(streak: 0),
              ),

              const SizedBox(height: 20),

              // Goals section header
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_cyan, _purple],
                    ).createShader(bounds),
                    child: Text(
                      'ЦІЛІ',
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Goal cards
              goalsAsync.when(
                data: (goals) {
                  if (goals.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _cyan.withOpacity(0.12)),
                      ),
                      child: Text(
                        'Цілі ще не створено',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: goals
                        .map((goal) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _GoalCard(goal: goal),
                            ))
                        .toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _cyan),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cyan.withOpacity(0.12)),
                  ),
                  child: Text(
                    'Помилка завантаження цілей',
                    style: GoogleFonts.shareTechMono(color: Colors.white38),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Big Deposit button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/deposit'),
                  icon: const Icon(Icons.add_circle_outline, size: 24),
                  label: Text(
                    'ВНЕСТИ КОШТИ',
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions row
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.grid_view,
                      label: 'Функції',
                      onTap: () => context.go('/features'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.local_fire_department,
                      label: 'Серія',
                      onTap: () {
                        // Could navigate to streak details
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.settings,
                      label: 'Налаштування',
                      onTap: () => context.go('/settings'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Profile bar widget
// =============================================================================

class _ProfileBar extends StatelessWidget {
  final User? user;

  const _ProfileBar({this.user});

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _cardBg = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'NetRunner';
    final characterClass = user?.characterClass ?? 'NetRunner';
    final level = user?.level ?? 1;
    final xp = user?.xp ?? 0;
    final xpForNextLevel = level * 500;
    final xpProgress = xpForNextLevel > 0 ? xp / xpForNextLevel : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: _cyan.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [_cyan, _purple]),
              border: Border.all(color: _cyan.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'N',
                style: GoogleFonts.orbitron(
                  color: _bg,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$characterClass // Рівень $level',
                  style: GoogleFonts.shareTechMono(
                    color: _cyan.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                // XP progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: xpProgress.clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_cyan, _purple],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$xp / $xpForNextLevel XP',
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Streak banner widget
// =============================================================================

class _StreakBanner extends StatelessWidget {
  final int streak;

  const _StreakBanner({required this.streak});

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _orange = Color(0xFFFF6B00);
  static const _cardBg = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: _orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              streak > 0
                  ? 'Серія: $streak дн. підряд!'
                  : 'Почни серію сьогодні!',
              style: GoogleFonts.shareTechMono(
                color: streak > 0 ? _orange : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (streak > 0)
            Text(
              'x$streak',
              style: GoogleFonts.orbitron(
                color: _orange,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Goal card with progress bar
// =============================================================================

class _GoalCard extends StatelessWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _green = Color(0xFF00FF88);
  static const _cardBg = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).toInt();
    final remaining = goal.targetAmount - goal.currentAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: _cyan.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _green.withOpacity(0.4)),
                  ),
                  child: Text(
                    'ВИКОНАНО',
                    style: GoogleFonts.orbitron(
                      color: _green,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: progress >= 1.0
                            ? [_green, _cyan]
                            : [_cyan, _purple],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.currentAmount.toInt()} / ${goal.targetAmount.toInt()} UAH',
                style: GoogleFonts.shareTechMono(
                  color: _cyan,
                  fontSize: 12,
                ),
              ),
              Text(
                '$percent%',
                style: GoogleFonts.orbitron(
                  color: percent >= 100 ? _green : _cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (remaining > 0 && !goal.isCompleted) ...[
            const SizedBox(height: 4),
            Text(
              'Залишилось: ${remaining.toInt()} UAH',
              style: GoogleFonts.shareTechMono(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Quick action button
// =============================================================================

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const _cardBg = Color(0xFF111827);
  static const _cyan = Color(0xFF00F0FF);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cyan.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _cyan, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
