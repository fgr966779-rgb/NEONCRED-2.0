import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/services/future_self_service.dart';

// =========================================================================
// FutureSelfScreen — cyberpunk future self visualization
// =========================================================================

class FutureSelfScreen extends ConsumerStatefulWidget {
  const FutureSelfScreen({super.key});

  @override
  ConsumerState<FutureSelfScreen> createState() => _FutureSelfScreenState();
}

class _FutureSelfScreenState extends ConsumerState<FutureSelfScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateVisions();
    });
  }

  Future<void> _generateVisions() async {
    final database = ref.read(databaseProvider);
    final goals = await database.getAllGoals();
    final deposits = await database.getAllDeposits();

    for (final goal in goals.take(5)) {
      await ref.read(futureSelfProvider.notifier).generateVision(goal, deposits);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(futureSelfProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{231B} Майбутнє Я',
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
                    'VAULT-17 генерує бачення...',
                    style: TextStyle(color: Color(0xFFB088FF), fontSize: 14),
                  ),
                ],
              ),
            )
          : state.visions.isEmpty
              ? const _EmptyFutureSelfState()
              : RefreshIndicator(
                  color: const Color(0xFF00F0FF),
                  backgroundColor: const Color(0xFF0D1117),
                  onRefresh: _generateVisions,
                  child: CustomScrollView(
                    slivers: [
                      // Active vision card
                      if (state.activeVision != null)
                        SliverToBoxAdapter(
                          child: _ActiveVisionCard(vision: state.activeVision!),
                        ),

                      // Warning message if brightness is low
                      if (state.activeVision != null)
                        SliverToBoxAdapter(
                          child: _BrightnessWarning(
                            vision: state.activeVision!,
                            warningMessage: ref
                                .read(futureSelfProvider.notifier)
                                .getWarningMessage(state.activeVision!.goalId),
                          ),
                        ),

                      // All visions list
                      if (state.visions.length > 1)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              '\u{1F52E} ВСІ БАЧЕННЯ',
                              style: TextStyle(
                                color: Color(0xFF6B00FF),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final visions = state.visions.values.toList();
                            if (state.activeVision != null &&
                                visions[index].goalId ==
                                    state.activeVision!.goalId) {
                              return const SizedBox.shrink();
                            }
                            return _VisionCard(vision: visions[index]);
                          },
                          childCount: state.visions.length,
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
    );
  }
}

// =========================================================================
// Active vision card
// =========================================================================

class _ActiveVisionCard extends StatelessWidget {
  final FutureSelfVision vision;

  const _ActiveVisionCard({required this.vision});

  @override
  Widget build(BuildContext context) {
    final brightness = vision.brightness;
    final glowColor = Color.lerp(
      const Color(0xFFFF3366),
      const Color(0xFF00F0FF),
      brightness,
    )!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            glowColor.withOpacity(brightness * 0.2),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glowColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(brightness * 0.3),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Brightness indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '\u{2600}\u{FE0F}',
                style: TextStyle(fontSize: 16 + brightness * 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Яскравість: ${(brightness * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: glowColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal name
          Text(
            vision.goalName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: glowColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          // Countdown
          if (vision.daysToMeetFutureSelf > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B00FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '\u{23F3} До зустрічі з Future Self: ${vision.daysToMeetFutureSelf} дн.',
                style: const TextStyle(
                  color: Color(0xFFB088FF),
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // AI description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0A2E).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6B00FF).withOpacity(0.2),
              ),
            ),
            child: Text(
              vision.visionDescriptionUA.isNotEmpty
                  ? vision.visionDescriptionUA
                  : vision.visionDescriptionEN,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB088FF),
                fontSize: 15,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Brightness progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: brightness,
              backgroundColor: const Color(0xFF1A0A2E),
              valueColor: AlwaysStoppedAnimation<Color>(glowColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Brightness warning
// =========================================================================

class _BrightnessWarning extends StatelessWidget {
  final FutureSelfVision vision;
  final String warningMessage;

  const _BrightnessWarning({
    required this.vision,
    required this.warningMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (warningMessage.isEmpty) return const SizedBox.shrink();

    final isCritical = vision.brightness < 0.3;
    final color = isCritical ? const Color(0xFFFF3366) : const Color(0xFFFF6B00);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isCritical ? Icons.warning : Icons.info_outline,
              color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              warningMessage,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Vision card (smaller)
// =========================================================================

class _VisionCard extends StatelessWidget {
  final FutureSelfVision vision;

  const _VisionCard({required this.vision});

  @override
  Widget build(BuildContext context) {
    final brightness = vision.brightness;
    final glowColor = Color.lerp(
      const Color(0xFFFF3366),
      const Color(0xFF00F0FF),
      brightness,
    )!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glowColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: glowColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(color: glowColor.withOpacity(0.4), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vision.goalName,
                  style: TextStyle(
                    color: glowColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\u{2600}\u{FE0F} ${(brightness * 100).toStringAsFixed(0)}% | \u{23F3} ${vision.daysToMeetFutureSelf} дн.',
                  style: const TextStyle(
                    color: Color(0xFF8888AA),
                    fontSize: 12,
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

// =========================================================================
// Empty state
// =========================================================================

class _EmptyFutureSelfState extends StatelessWidget {
  const _EmptyFutureSelfState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6B00FF).withOpacity(0.2),
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u{1F52E}', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text(
              'Створи ціль щоб побачити Future Self',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8888AA), fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'AI згенерує кіберпанк-бачення твого майбутнього, '
              'яке стає яскравішим з кожним депозитом!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF666688), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
