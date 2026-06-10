import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/price_arena_service.dart';

// =========================================================================
// PriceArenaScreen -- PRICE ARENA competitive price finding dashboard
// =========================================================================

class PriceArenaScreen extends ConsumerStatefulWidget {
  const PriceArenaScreen({super.key});

  @override
  ConsumerState<PriceArenaScreen> createState() =>
      _PriceArenaScreenState();
}

class _PriceArenaScreenState extends ConsumerState<PriceArenaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(priceArenaProvider);
      if (state.activeTournament == null) {
        ref.read(priceArenaProvider.notifier).fetchActiveTournament();
      }
      if (state.leaderboard.isEmpty) {
        ref.read(priceArenaProvider.notifier).fetchLeaderboard();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(priceArenaProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: Text(
          'PRICE ARENA',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00F0FF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00F0FF),
          labelColor: const Color(0xFF00F0FF),
          unselectedLabelColor: const Color(0xFF8888AA),
          labelStyle: GoogleFonts.orbitron(fontSize: 11),
          tabs: const [
            Tab(text: 'ТУРНІР'),
            Tab(text: 'РЕЙТИНГ'),
            Tab(text: 'ІСТОРІЯ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TournamentTab(state: state),
          _LeaderboardTab(state: state),
          _HistoryTab(state: state),
        ],
      ),
    );
  }
}

// =========================================================================
// Tournament tab
// =========================================================================

class _TournamentTab extends ConsumerStatefulWidget {
  final PriceArenaState state;

  const _TournamentTab({required this.state});

  @override
  ConsumerState<_TournamentTab> createState() => _TournamentTabState();
}

class _TournamentTabState extends ConsumerState<_TournamentTab> {
  final _priceController = TextEditingController();
  final _storeController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _storeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final notifier = ref.read(priceArenaProvider.notifier);
    final tournament = state.activeTournament;

    return CustomScrollView(
      slivers: [
        // Error banner
        if (state.error != null)
          SliverToBoxAdapter(
            child: _ErrorBanner(error: state.error!),
          ),

        // Loading indicator
        if (state.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00F0FF),
                ),
              ),
            ),
          ),

        if (tournament != null) ...[
          // Active tournament card
          SliverToBoxAdapter(
            child: _ActiveTournamentCard(tournament: tournament),
          ),

          // Submit price section
          SliverToBoxAdapter(
            child: _SubmitPriceSection(
              priceController: _priceController,
              storeController: _storeController,
              urlController: _urlController,
              onSubmit: () {
                final price =
                    double.tryParse(_priceController.text.trim()) ?? 0.0;
                final store = _storeController.text.trim();
                final url = _urlController.text.trim();

                if (price > 0 && store.isNotEmpty) {
                  notifier.submitPrice(
                    tournament.tournamentId,
                    price,
                    store,
                    url,
                  );
                  _priceController.clear();
                  _storeController.clear();
                  _urlController.clear();
                }
              },
            ),
          ),

          // AI Commentary section
          if (tournament.aiCommentary.isNotEmpty)
            SliverToBoxAdapter(
              child: _AiCommentaryCard(
                commentary: tournament.aiCommentary,
                onGenerate: () =>
                    notifier.generateCommentary(tournament),
              ),
            )
          else if (tournament.submissions.isNotEmpty)
            SliverToBoxAdapter(
              child: _GenerateCommentaryButton(
                onGenerate: () =>
                    notifier.generateCommentary(tournament),
              ),
            ),

          // Submissions list
          if (tournament.submissions.isNotEmpty)
            SliverToBoxAdapter(
              child: _SubmissionsHeader(
                count: tournament.submissions.length,
              ),
            ),

          if (tournament.submissions.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SubmissionCard(
                  submission: tournament.submissions[index],
                  isWinner: tournament.winner?.id ==
                      tournament.submissions[index].id,
                  referencePrice: tournament.referencePrice,
                ),
                childCount: tournament.submissions.length,
              ),
            ),
        ] else ...[
          // No active tournament
          const SliverToBoxAdapter(
            child: _NoTournamentCard(),
          ),
        ],

        // User stats card
        SliverToBoxAdapter(
          child: _UserStatsCard(
            xp: state.userXp,
            rank: state.userRank,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// =========================================================================
// Leaderboard tab
// =========================================================================

class _LeaderboardTab extends ConsumerWidget {
  final PriceArenaState state;

  const _LeaderboardTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(priceArenaProvider.notifier);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 8),
                Text(
                  'РЕЙТИНГ АРЕНИ',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => notifier.fetchLeaderboard(),
                  icon: const Icon(Icons.refresh,
                      color: Color(0xFF8888AA), size: 18),
                ),
              ],
            ),
          ),
        ),

        // Leaderboard entries
        if (state.leaderboard.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _LeaderboardEntryCard(
                entry: state.leaderboard[index],
                position: index + 1,
                isCurrentUser:
                    state.leaderboard[index].userId == 'user_local',
              ),
              childCount: state.leaderboard.length,
            ),
          )
        else
          const SliverToBoxAdapter(
            child: _EmptyLeaderboardCard(),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// =========================================================================
// History tab
// =========================================================================

class _HistoryTab extends ConsumerWidget {
  final PriceArenaState state;

  const _HistoryTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pastTournaments =
        state.tournaments.where((t) => !t.isActive).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'МИНУЛІ ТУРНІРИ',
              style: GoogleFonts.orbitron(
                color: const Color(0xFF8888AA),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        if (pastTournaments.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _PastTournamentCard(
                tournament: pastTournaments[index],
              ),
              childCount: pastTournaments.length,
            ),
          )
        else
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF6B00FF).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.history,
                      color: Color(0xFF6B00FF), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Минулі турніри з\'являться тут',
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFF8888AA),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Бери участь у турнірах, щоб залишити слід в історії Арени.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.shareTechMono(
                      color: const Color(0xFF666688),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// =========================================================================
// Active tournament card
// =========================================================================

class _ActiveTournamentCard extends StatelessWidget {
  final ArenaTournament tournament;

  const _ActiveTournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final timeRemaining = _computeTimeRemaining(tournament.endDate);
    final savingsPercent = tournament.winner != null &&
            tournament.referencePrice > 0
        ? ((tournament.referencePrice -
                    tournament.winner!.submittedPrice) /
                tournament.referencePrice) *
            100
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00F0FF).withOpacity(0.12),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_martial_arts,
                  color: Color(0xFF00F0FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'АКТИВНИЙ ТУРНІР',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00F0FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF00FF88),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tournament.productName,
            style: GoogleFonts.orbitron(
              color: const Color(0xFFE0E0FF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (tournament.productCategory.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tournament.productCategory,
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF8888AA),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Reference price
          Row(
            children: [
              Text(
                'Референтна ціна: ',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8888AA),
                  fontSize: 12,
                ),
              ),
              Text(
                '${tournament.referencePrice.toStringAsFixed(0)} грн',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFFFF3366),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Time remaining + participants
          Row(
            children: [
              const Icon(Icons.timer,
                  color: Color(0xFFFFD700), size: 14),
              const SizedBox(width: 4),
              Text(
                timeRemaining,
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFFFD700),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.people,
                  color: Color(0xFF00F0FF), size: 14),
              const SizedBox(width: 4),
              Text(
                '${tournament.participantCount} учасників',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF00F0FF),
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Winner highlight
          if (tournament.winner != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events,
                      color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Лідер: ${tournament.winner!.userName}',
                          style: GoogleFonts.orbitron(
                            color: const Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${tournament.winner!.submittedPrice.toStringAsFixed(0)} грн -- ${savingsPercent.toStringAsFixed(1)}% економії',
                          style: GoogleFonts.shareTechMono(
                            color: const Color(0xFFE0E0FF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _computeTimeRemaining(String endDate) {
    try {
      final end = DateTime.parse(endDate);
      final diff = end.difference(DateTime.now());
      if (diff.isNegative) return 'Завершено';
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      return '$daysд ${hours}г';
    } catch (_) {
      return 'Невідомо';
    }
  }
}

// =========================================================================
// Submit price section
// =========================================================================

class _SubmitPriceSection extends StatelessWidget {
  final TextEditingController priceController;
  final TextEditingController storeController;
  final TextEditingController urlController;
  final VoidCallback onSubmit;

  const _SubmitPriceSection({
    required this.priceController,
    required this.storeController,
    required this.urlController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ЗНАЙШОВ КРАЩУ ЦІНУ?',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00F0FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFFE0E0FF),
            ),
            decoration: InputDecoration(
              labelText: 'Ціна (грн)',
              labelStyle: GoogleFonts.shareTechMono(
                color: const Color(0xFF8888AA),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF333355)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00F0FF)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: storeController,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFFE0E0FF),
            ),
            decoration: InputDecoration(
              labelText: 'Магазин',
              labelStyle: GoogleFonts.shareTechMono(
                color: const Color(0xFF8888AA),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF333355)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00F0FF)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: urlController,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFFE0E0FF),
            ),
            decoration: InputDecoration(
              labelText: 'URL магазину (необов\'язково)',
              labelStyle: GoogleFonts.shareTechMono(
                color: const Color(0xFF8888AA),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF333355)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00F0FF)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.send, color: Color(0xFF00F0FF)),
              label: Text(
                'ВІДПРАВИТИ ЦІНУ',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00F0FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF00F0FF).withOpacity(0.15),
                side: const BorderSide(color: Color(0xFF00F0FF)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// AI commentary card
// =========================================================================

class _AiCommentaryCard extends StatelessWidget {
  final String commentary;
  final VoidCallback onGenerate;

  const _AiCommentaryCard({
    required this.commentary,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFF6B00FF), size: 16),
              const SizedBox(width: 8),
              Text(
                'КОМЕНТАР AI',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF6B00FF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            commentary,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFFB088FF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Generate commentary button
// =========================================================================

class _GenerateCommentaryButton extends StatelessWidget {
  final VoidCallback onGenerate;

  const _GenerateCommentaryButton({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: OutlinedButton.icon(
        onPressed: onGenerate,
        icon: const Icon(Icons.auto_awesome,
            color: Color(0xFF6B00FF), size: 16),
        label: Text(
          'ЗГЕНЕРУВАТИ КОМЕНТАР',
          style: GoogleFonts.orbitron(
            color: const Color(0xFF6B00FF),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF6B00FF)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Submissions header
// =========================================================================

class _SubmissionsHeader extends StatelessWidget {
  final int count;

  const _SubmissionsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        'ПІДПРАЦЮВАННЯ ($count)',
        style: GoogleFonts.orbitron(
          color: const Color(0xFF8888AA),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// =========================================================================
// Submission card
// =========================================================================

class _SubmissionCard extends StatelessWidget {
  final ArenaSubmission submission;
  final bool isWinner;
  final double referencePrice;

  const _SubmissionCard({
    required this.submission,
    required this.isWinner,
    required this.referencePrice,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isWinner
        ? const Color(0xFFFFD700)
        : submission.isValid
            ? const Color(0xFF00FF88)
            : const Color(0xFFFFD700).withOpacity(0.5);

    final savingsPercent = referencePrice > 0
        ? ((referencePrice - submission.submittedPrice) /
                referencePrice) *
            100
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Validity indicator
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: submission.isValid
                  ? const Color(0xFF00FF88).withOpacity(0.2)
                  : const Color(0xFFFFD700).withOpacity(0.2),
              border: Border.all(
                color: submission.isValid
                    ? const Color(0xFF00FF88)
                    : const Color(0xFFFFD700),
                width: 2,
              ),
            ),
            child: Icon(
              submission.isValid ? Icons.check : Icons.hourglass_top,
              color: submission.isValid
                  ? const Color(0xFF00FF88)
                  : const Color(0xFFFFD700),
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      submission.userName,
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFE0E0FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.emoji_events,
                          color: Color(0xFFFFD700), size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  submission.storeName,
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8888AA),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${submission.submittedPrice.toStringAsFixed(0)} грн',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00F0FF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '-${savingsPercent.toStringAsFixed(1)}%',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF00FF88),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// User stats card
// =========================================================================

class _UserStatsCard extends StatelessWidget {
  final int xp;
  final String rank;

  const _UserStatsCard({
    required this.xp,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6B00FF).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6B00FF).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF6B00FF),
                width: 2,
              ),
            ),
            child: const Icon(Icons.person,
                color: Color(0xFF6B00FF), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Кібер-мисливець',
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFFE0E0FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rank,
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFFFD700),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$xp XP',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00F0FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Досвід',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF8888AA),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Leaderboard entry card
// =========================================================================

class _LeaderboardEntryCard extends StatelessWidget {
  final ArenaLeaderboardEntry entry;
  final int position;
  final bool isCurrentUser;

  const _LeaderboardEntryCard({
    required this.entry,
    required this.position,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final positionColor = position == 1
        ? const Color(0xFFFFD700)
        : position == 2
            ? const Color(0xFFC0C0C0)
            : position == 3
                ? const Color(0xFFCD7F32)
                : const Color(0xFF8888AA);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF1A1F2E)
            : const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser
              ? const Color(0xFF00F0FF).withOpacity(0.4)
              : positionColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 32,
            child: Text(
              '#$position',
              style: GoogleFonts.orbitron(
                color: positionColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar placeholder
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: positionColor.withOpacity(0.15),
              border: Border.all(color: positionColor.withOpacity(0.5)),
            ),
            child: Center(
              child: Text(
                entry.userName.isNotEmpty
                    ? entry.userName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.orbitron(
                  color: positionColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  style: GoogleFonts.orbitron(
                    color: isCurrentUser
                        ? const Color(0xFF00F0FF)
                        : const Color(0xFFE0E0FF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  entry.rank,
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFF8888AA),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xp} XP',
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF00F0FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${entry.tournamentsWon} перемог',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFFFD700),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Past tournament card
// =========================================================================

class _PastTournamentCard extends StatelessWidget {
  final ArenaTournament tournament;

  const _PastTournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF333355),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tournament.productName,
                style: GoogleFonts.orbitron(
                  color: const Color(0xFF8888AA),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${tournament.referencePrice.toStringAsFixed(0)} грн',
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFF666688),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (tournament.winner != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${tournament.winner!.userName} -- ${tournament.winner!.submittedPrice.toStringAsFixed(0)} грн',
                  style: GoogleFonts.shareTechMono(
                    color: const Color(0xFFE0E0FF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${tournament.participantCount} учасників',
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF666688),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Error banner
// =========================================================================

class _ErrorBanner extends StatelessWidget {
  final String error;

  const _ErrorBanner({required this.error});

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
        error,
        style: GoogleFonts.shareTechMono(
          color: const Color(0xFFFF3366),
          fontSize: 13,
        ),
      ),
    );
  }
}

// =========================================================================
// Empty states
// =========================================================================

class _NoTournamentCard extends StatelessWidget {
  const _NoTournamentCard();

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
      child: Column(
        children: [
          const Icon(Icons.sports_martial_arts,
              color: Color(0xFF6B00FF), size: 48),
          const SizedBox(height: 16),
          Text(
            'Арена очікує бійців...',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF8888AA),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Новий турнір розпочнеться найближчим часом. '
            'Готуйся знайти найнижчу ціну!',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF666688),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLeaderboardCard extends StatelessWidget {
  const _EmptyLeaderboardCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events,
              color: Color(0xFFFFD700), size: 48),
          const SizedBox(height: 16),
          Text(
            'Рейтинг формується...',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF8888AA),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Стань першим чемпіоном Арени Цін!',
            textAlign: TextAlign.center,
            style: GoogleFonts.shareTechMono(
              color: const Color(0xFF666688),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
