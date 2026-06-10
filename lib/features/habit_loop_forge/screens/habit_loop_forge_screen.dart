import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/habit_loop_forge_provider.dart';

// =============================================================================
// HABIT LOOP FORGE SCREEN
// =============================================================================

class HabitLoopForgeScreen extends ConsumerStatefulWidget {
  const HabitLoopForgeScreen({super.key});

  @override
  ConsumerState<HabitLoopForgeScreen> createState() =>
      _HabitLoopForgeScreenState();
}

class _HabitLoopForgeScreenState extends ConsumerState<HabitLoopForgeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _pulseController;

  static const _bg = Color(0xFF0A0E17);
  static const _cardBg = Color(0xFF1A1F2E);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _pink = Color(0xFFFF3366);
  static const _green = Color(0xFF00FF88);
  static const _gold = Color(0xFFFFD700);
  static const _dimText = Color(0xFF8892A4);

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitLoopForgeProvider);
    final notifier = ref.read(habitLoopForgeProvider.notifier);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HABIT LOOP FORGE',
              style: GoogleFonts.orbitron(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            if (state.stats.hasKovalBadge) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold.withOpacity(0.5)),
                ),
                child: Text(
                  'КОВАЛЬ',
                  style: GoogleFonts.shareTechMono(
                    color: _gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
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
      body: state.habits.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatsBar(state),
                const SizedBox(height: 16),
                ...state.habits.map((habit) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildHabitCard(habit),
                    )),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        backgroundColor: _purple,
        child: const Icon(Icons.add_circle, color: _gold, size: 28),
      ),
    );
  }

  // ---- Stats Bar ----

  Widget _buildStatsBar(HabitLoopForgeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cyan.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statChip('Активні', '${state.stats.activeHabits}', _cyan),
          _statChip('Завершені 21д', '${state.stats.completed21}', _green),
          _statChip('Макс стрік', '${state.stats.longestActiveStreak}', _gold),
          _statChip('Заощаджено', '${state.stats.totalSavedAllHabits.toStringAsFixed(0)}', _gold),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 9),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---- Habit Card with Apple Fitness Ring ----

  Widget _buildHabitCard(HabitLoopItem habit) {
    final accentColor = habit.isCompleted21
        ? _green
        : habit.isActive
            ? _cyan
            : _dimText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with ring and info
          Row(
            children: [
              // Apple Fitness-style ring
              _buildHabitRing(habit),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${habit.dailyAmountUah.toStringAsFixed(0)} грн/день',
                      style: GoogleFonts.shareTechMono(color: _gold, fontSize: 12),
                    ),
                    if (habit.trigger.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        habit.trigger,
                        style: GoogleFonts.shareTechMono(color: _purple, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Streak & progress info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _streakChip('День', '${habit.currentDay}/${habit.targetDays}', _cyan),
              _streakChip('Стрік', '${habit.streakDays} дн.', _gold),
              _streakChip('Заощаджено', '${habit.totalSavedUah.toStringAsFixed(0)} грн', _green),
            ],
          ),

          // Broken streak indicator
          if (habit.isActive && habit.isStreakBroken && habit.currentDay > 0) ...[
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + (_pulseController.value * 0.5),
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _pink.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, color: _pink, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Ланцюг розірвано! Почни знову.',
                      style: GoogleFonts.shareTechMono(color: _pink, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Completed 21-day badge
          if (habit.isCompleted21) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: _green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '21-ДЕННЕ КОЛО ЗАВЕРШЕНО! +105 XP',
                    style: GoogleFonts.shareTechMono(color: _green, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              if (habit.canCheckInToday && habit.isActive)
                Expanded(
                  child: _actionButton(
                    icon: Icons.check_circle,
                    label: 'Чек-ін +5 XP',
                    color: _green,
                    onTap: () => ref.read(habitLoopForgeProvider.notifier).checkIn(habit.habitId),
                  ),
                ),
              if (!habit.canCheckInToday && habit.isActive) ...[
                Expanded(
                  child: _actionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Вже чек-ін сьогодні',
                    color: _dimText,
                    onTap: null,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              _actionButton(
                icon: habit.isActive ? Icons.pause : Icons.play_arrow,
                label: habit.isActive ? 'Пауза' : 'Продовжити',
                color: _purple,
                onTap: () => ref.read(habitLoopForgeProvider.notifier).toggleHabit(habit.habitId),
                compact: true,
              ),
              const SizedBox(width: 8),
              _actionButton(
                icon: Icons.delete_outline,
                label: '',
                color: _pink,
                onTap: () => ref.read(habitLoopForgeProvider.notifier).deleteHabit(habit.habitId),
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Apple Fitness-Style Ring ----

  Widget _buildHabitRing(HabitLoopItem habit) {
    final progress = habit.progress;
    final ringColor = habit.isCompleted21
        ? _green
        : progress >= 0.8
            ? _gold
            : _cyan;

    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _HabitRingPainter(
          progress: progress,
          color: ringColor,
          strokeWidth: 6,
        ),
        child: Center(
          child: Text(
            habit.ringLabel,
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _streakChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.shareTechMono(color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 9),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 8,
          horizontal: compact ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(icon, color: color, size: 14),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.shareTechMono(color: color, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---- Empty State ----

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.loop, size: 64, color: _cyan),
            const SizedBox(height: 16),
            Text(
              'HABIT LOOP FORGE',
              style: GoogleFonts.orbitron(color: _cyan, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Куй звички заощаджування 21-денними циклами. Не розірвати ланцюг! '
              'AI запропонує мікро-звички, а кільця прогресу як Apple Fitness '
              'покажуть твій шлях до фінансової дисципліни.',
              textAlign: TextAlign.center,
              style: GoogleFonts.shareTechMono(color: _dimText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _xpChip('+5 XP/день', _cyan),
                const SizedBox(width: 12),
                _xpChip('x2 за 21 день', _gold),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withOpacity(0.3)),
              ),
              child: Text(
                'Бейдж "КОВАЛЬ" за 3 завершені цикли',
                style: GoogleFonts.shareTechMono(color: _gold, fontSize: 11),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showCreateDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'СТВОРИТИ ЗВИЧКУ',
                style: GoogleFonts.orbitron(color: _gold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _xpChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: GoogleFonts.shareTechMono(color: color, fontSize: 11)),
    );
  }

  // ---- AI Suggestion Dialog ----

  Future<void> _showSuggestionDialog() async {
    final notifier = ref.read(habitLoopForgeProvider.notifier);
    await notifier.generateSuggestion();

    if (!mounted) return;
    final state = ref.read(habitLoopForgeProvider);
    if (state.aiSuggestionText != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _purple.withOpacity(0.5)),
          ),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: _purple),
              const SizedBox(width: 8),
              Text(
                'МІКРО-ЗВИЧКИ',
                style: GoogleFonts.orbitron(color: _purple, fontSize: 14),
              ),
            ],
          ),
          content: Text(
            state.aiSuggestionText!,
            style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () {
                notifier.clearSuggestion();
                Navigator.of(ctx).pop();
              },
              child: Text('ЗАКРИТИ', style: GoogleFonts.shareTechMono(color: _cyan)),
            ),
          ],
        ),
      );
    }
  }

  // ---- Create Dialog ----

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final triggerCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _cyan.withOpacity(0.5)),
          ),
          title: Row(
            children: [
              Text(
                'НОВА ЗВИЧКА',
                style: GoogleFonts.orbitron(color: _gold, fontSize: 16),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showSuggestionDialog();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _purple.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: _purple, size: 14),
                      const SizedBox(width: 4),
                                      Text('AI', style: GoogleFonts.shareTechMono(color: _purple, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField(nameCtrl, 'Назва звички', Icons.loop),
                const SizedBox(height: 12),
                _dialogField(amountCtrl, 'Сума/день (грн)', Icons.attach_money, kb: TextInputType.number),
                const SizedBox(height: 12),
                _dialogField(triggerCtrl, 'Тригер (напр. "перед кавою")', Icons.bolt),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Скасувати', style: GoogleFonts.shareTechMono(color: _dimText)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final amount = double.tryParse(amountCtrl.text) ?? 50;
                ref.read(habitLoopForgeProvider.notifier).createHabit(
                      name: nameCtrl.text.trim(),
                      dailyAmountUah: amount,
                      trigger: triggerCtrl.text.trim(),
                    );
                Navigator.of(ctx).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: _purple),
              child: Text(
                'КУТИ +5 XP/ДЕНЬ',
                style: GoogleFonts.shareTechMono(color: _gold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? kb}) {
    return TextField(
      controller: ctrl,
      keyboardType: kb,
      style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _cyan, size: 18),
        hintText: hint,
        hintStyle: GoogleFonts.shareTechMono(color: _dimText, fontSize: 12),
        filled: true,
        fillColor: _bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _cyan),
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER — Apple Fitness-Style Ring
// =============================================================================

class _HabitRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double strokeWidth;

  _HabitRingPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HabitRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
