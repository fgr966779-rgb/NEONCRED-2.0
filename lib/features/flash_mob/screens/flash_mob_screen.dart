import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../services/flash_mob_service.dart';

// =========================================================================
// FlashMobScreen — real-time flash mob savings events
// =========================================================================

class FlashMobScreen extends ConsumerStatefulWidget {
  const FlashMobScreen({super.key});

  @override
  ConsumerState<FlashMobScreen> createState() => _FlashMobScreenState();
}

class _FlashMobScreenState extends ConsumerState<FlashMobScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flashMobProvider.notifier).checkForActiveEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(flashMobProvider);
    final notifier = ref.read(flashMobProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{26A1} Флеш-Моб Заощаджень',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF0D1117),
        onRefresh: () => notifier.checkForActiveEvents(),
        child: CustomScrollView(
          slivers: [
            // Active event card
            if (state.activeEvent != null)
              SliverToBoxAdapter(
                child: _ActiveEventCard(
                  event: state.activeEvent!,
                  notifier: notifier,
                  isJoining: state.isJoining,
                ),
              )
            else
              const SliverToBoxAdapter(
                child: _NoActiveEventCard(),
              ),

            // FOMO message
            if (state.activeEvent != null)
              SliverToBoxAdapter(
                child: _FomoBanner(message: notifier.fomoMessage()),
              ),

            // Joined events history
            if (state.joinedEvents.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    '\u{2705} ПРИЄДНАНІ ПОДІЇ',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _EventHistoryCard(event: state.joinedEvents[index]),
                  childCount: state.joinedEvents.length,
                ),
              ),
            ],

            // Event types info
            const SliverToBoxAdapter(
              child: _EventTypesInfo(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Active event card
// =========================================================================

class _ActiveEventCard extends StatelessWidget {
  final FlashMobEvent event;
  final FlashMobNotifier notifier;
  final bool isJoining;

  const _ActiveEventCard({
    required this.event,
    required this.notifier,
    required this.isJoining,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = notifier.timeRemaining();
    final minutes = remaining.inMinutes;

    // Pulsing border color based on urgency
    final urgencyColor = minutes <= 5
        ? const Color(0xFFFF3366)
        : minutes <= 15
            ? const Color(0xFFFF6B00)
            : const Color(0xFF00F0FF);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            urgencyColor.withOpacity(0.15),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: urgencyColor.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Event title with multiplier
          Text(
            event.titleUA,
            style: TextStyle(
              color: urgencyColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'x${event.multiplier.toStringAsFixed(1)} МНОЖНИК',
              style: TextStyle(
                color: urgencyColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            event.descriptionUA,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB088FF),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),

          // Countdown timer
          _CountdownTimer(remaining: remaining, color: urgencyColor),

          const SizedBox(height: 12),

          // Participant count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people, color: Color(0xFF00F0FF), size: 20),
              const SizedBox(width: 8),
              Text(
                '${event.participantCount} операторів приєднались',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Join button
          if (!event.isJoined)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isJoining
                    ? null
                    : () => notifier.joinEvent(event.eventId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: urgencyColor,
                  foregroundColor: const Color(0xFF0A0E17),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isJoining
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0A0E17),
                        ),
                      )
                    : const Text(
                        '\u{26A1} ПРИЄДНАТИСЬ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF88).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00FF88).withOpacity(0.3),
                ),
              ),
              child: const Text(
                '\u{2705} Ти в грі! Роби депозити щоб максимізувати XP!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =========================================================================
// Countdown timer widget
// =========================================================================

class _CountdownTimer extends StatefulWidget {
  final Duration remaining;
  final Color color;

  const _CountdownTimer({required this.remaining, required this.color});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remaining;
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant _CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remaining != widget.remaining) {
      _remaining = widget.remaining;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0) {
        setState(() {
          _remaining = _remaining - const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TimeUnit(value: hours.toString().padLeft(2, '0'), label: 'год'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':',
              style: TextStyle(color: Color(0xFFFF3366), fontSize: 24)),
        ),
        _TimeUnit(value: minutes.toString().padLeft(2, '0'), label: 'хв'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(':',
              style: TextStyle(color: Color(0xFFFF3366), fontSize: 24)),
        ),
        _TimeUnit(value: seconds.toString().padLeft(2, '0'), label: 'сек'),
      ],
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String label;

  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0A2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFF3366),
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8888AA),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// FOMO banner
// =========================================================================

class _FomoBanner extends StatelessWidget {
  final String message;

  const _FomoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF3366).withOpacity(0.3),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFF3366),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =========================================================================
// No active event card
// =========================================================================

class _NoActiveEventCard extends StatelessWidget {
  const _NoActiveEventCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.2),
        ),
      ),
      child: const Column(
        children: [
          Text(
            '\u{1F3AC}',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 16),
          Text(
            'Немає активних подій',
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Флеш-моб з\'являється випадково! Слідкуй за сповіщеннями.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF666688),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Event history card
// =========================================================================

class _EventHistoryCard extends StatelessWidget {
  final FlashMobEvent event;

  const _EventHistoryCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00FF88).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              event.titleUA,
              style: const TextStyle(
                color: Color(0xFFB088FF),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            'x${event.multiplier.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Event types info section
// =========================================================================

class _EventTypesInfo extends StatelessWidget {
  const _EventTypesInfo();

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
            'ТИПИ ПОДІЙ',
            style: TextStyle(
              color: Color(0xFF6B00FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          ...FlashMobEventType.values.map(
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
                          'x${type.baseMultiplier} | ${type.typicalDuration.inMinutes}хв',
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
