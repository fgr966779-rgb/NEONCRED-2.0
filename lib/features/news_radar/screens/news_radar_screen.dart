import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';

// =========================================================================
// NewsRadarScreen — financial news radar dashboard
// =========================================================================

class NewsRadarScreen extends ConsumerStatefulWidget {
  const NewsRadarScreen({super.key});

  @override
  ConsumerState<NewsRadarScreen> createState() => _NewsRadarScreenState();
}

class _NewsRadarScreenState extends ConsumerState<NewsRadarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(newsRadarProvider);
      if (state.insights.isEmpty) {
        ref.read(newsRadarProvider.notifier).fetchNews();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsRadarProvider);
    final notifier = ref.read(newsRadarProvider.notifier);
    final displayInsights = state.filteredInsights;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          '\u{1F4E1} \u{0424}\u{0456}\u{043D}\u{0430}\u{043D}\u{0441}\u{043E}\u{0432}\u{0438}\u{0439} \u{0420}\u{0430}\u{0434}\u{0430}\u{0440}',
          style: TextStyle(color: Color(0xFF00F0FF), fontSize: 20),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF0D1117),
        onRefresh: () => notifier.fetchNews(),
        child: CustomScrollView(
          slivers: [
            // Pulse radar card
            SliverToBoxAdapter(child: _PulseRadarCard(state: state)),

            // Unread count banner
            if (state.unreadCount > 0)
              SliverToBoxAdapter(child: _UnreadBanner(count: state.unreadCount)),

            // Category filter chips
            SliverToBoxAdapter(
              child: _CategoryFilter(
                selectedCategory: state.filterCategory,
                onSelected: (cat) => notifier.setFilter(cat),
                onClear: () => notifier.setFilter(null),
              ),
            ),

            // News insight cards
            if (displayInsights.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _InsightCard(
                    insight: displayInsights[index],
                    onTap: () {
                      notifier.markAsRead(displayInsights[index].insightId);
                    },
                  ),
                  childCount: displayInsights.length,
                ),
              )
            else if (!state.isLoading)
              const SliverToBoxAdapter(child: _EmptyStateCard()),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Pulse radar card
// =========================================================================

class _PulseRadarCard extends StatelessWidget {
  final NewsRadarState state;

  const _PulseRadarCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final isActive = state.isLoading;
    final insightCount = state.insights.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isActive ? const Color(0xFF00F0FF) : const Color(0xFF6B00FF)).withOpacity(0.15),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isActive ? const Color(0xFF00F0FF) : const Color(0xFF6B00FF)).withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Pulse indicator
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isActive ? const Color(0xFF00F0FF) : const Color(0xFF6B00FF)).withOpacity(0.2),
              border: Border.all(
                color: isActive ? const Color(0xFF00F0FF) : const Color(0xFF6B00FF),
                width: 2,
              ),
            ),
            child: isActive
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00F0FF),
                      ),
                    ),
                  )
                : const Icon(Icons.radar, color: Color(0xFF6B00FF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? '\u{0421}\u{043A}\u{0430}\u{043D}\u{0443}\u{0432}\u{0430}\u{043D}\u{043D}\u{044F}...' : '$insightCount \u{0456}\u{043D}\u{0441}\u{0430}\u{0439}\u{0442}\u{0456}\u{0432}',
                  style: TextStyle(
                    color: isActive ? const Color(0xFF00F0FF) : const Color(0xFFB088FF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.lastFetchedAt != null)
                  Text(
                    '\u{041E}\u{0441}\u{0442}\u{0430}\u{043D}\u{043D}\u{0454} \u{043E}\u{043D}\u{043E}\u{0432}\u{043B}\u{0435}\u{043D}\u{043D}\u{044F}: ${_formatTime(state.lastFetchedAt!)}',
                    style: const TextStyle(color: Color(0xFF8888AA), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// =========================================================================
// Unread banner
// =========================================================================

class _UnreadBanner extends StatelessWidget {
  final int count;

  const _UnreadBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3366).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.3)),
      ),
      child: Text(
        '\u{1F525} $count \u{043D}\u{0435}\u{043F}\u{0440}\u{043E}\u{0447}\u{0438}\u{0442}\u{0430}\u{043D}\u{0438}\u{0445} \u{0456}\u{043D}\u{0441}\u{0430}\u{0439}\u{0442}\u{0456}\u{0432}',
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
// Category filter chips
// =========================================================================

class _CategoryFilter extends StatelessWidget {
  final NewsCategory? selectedCategory;
  final ValueChanged<NewsCategory> onSelected;
  final VoidCallback onClear;

  const _CategoryFilter({
    this.selectedCategory,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('\u{1F4CB} \u{0412}\u{0441}\u{0456}'),
              selected: selectedCategory == null,
              onSelected: (_) => onClear(),
              backgroundColor: const Color(0xFF0D1117),
              selectedColor: const Color(0xFF00F0FF).withOpacity(0.2),
              labelStyle: TextStyle(
                color: selectedCategory == null ? const Color(0xFF00F0FF) : const Color(0xFF8888AA),
                fontSize: 12,
              ),
              side: BorderSide(
                color: selectedCategory == null
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFF333355),
              ),
            ),
          ),
          ...NewsCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('${cat.iconEmoji} ${cat.labelUA}'),
                selected: selectedCategory == cat,
                onSelected: (_) => onSelected(cat),
                backgroundColor: const Color(0xFF0D1117),
                selectedColor: const Color(0xFF00F0FF).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: selectedCategory == cat ? const Color(0xFF00F0FF) : const Color(0xFF8888AA),
                  fontSize: 12,
                ),
                side: BorderSide(
                  color: selectedCategory == cat
                      ? const Color(0xFF00F0FF)
                      : const Color(0xFF333355),
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
// News insight card
// =========================================================================

class _InsightCard extends StatelessWidget {
  final NewsInsight insight;
  final VoidCallback onTap;

  const _InsightCard({required this.insight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final relevanceColor = insight.relevanceScore > 0.7
        ? const Color(0xFF00FF88)
        : insight.relevanceScore > 0.4
            ? const Color(0xFF00F0FF)
            : const Color(0xFF8888AA);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: insight.isRead
              ? const Color(0xFF0D1117)
              : const Color(0xFF1A0A2E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: insight.isActionable
                ? const Color(0xFFFF3366).withOpacity(0.4)
                : const Color(0xFF6B00FF).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: category + relevance
            Row(
              children: [
                Text(insight.category.iconEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  insight.category.labelUA,
                  style: TextStyle(
                    color: relevanceColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Relevance badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: relevanceColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(insight.relevanceScore * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: relevanceColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Headline
            Text(
              insight.headlineUA,
              style: const TextStyle(
                color: Color(0xFFE0E0FF),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Summary
            Text(
              insight.summaryUA,
              style: const TextStyle(
                color: Color(0xFF8888AA),
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Actionable badge
            if (insight.isActionable && insight.actionSuggestionUA != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3366).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFF3366).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('\u{26A1}', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.actionSuggestionUA!,
                        style: const TextStyle(
                          color: Color(0xFFFF3366),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Footer: source + time
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.language, color: Color(0xFF666688), size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    insight.source,
                    style: const TextStyle(color: Color(0xFF666688), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Empty state
// =========================================================================

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Text('\u{1F4E1}', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text(
            '\u{0420}\u{0430}\u{0434}\u{0430}\u{0440} \u{0441}\u{043A}\u{0430}\u{043D}\u{0443}\u{0454} \u{0433}\u{043E}\u{0440}\u{0438}\u{0437}\u{043E}\u{043D}\u{0442}\u{0438}...',
            style: TextStyle(color: Color(0xFF8888AA), fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            '\u{041F}\u{0456}\u{0434}\u{043A}\u{043B}\u{044E}\u{0447}\u{0438} SerpAPI \u{043A}\u{043B}\u{044E}\u{0447} \u{0432} .env \u{0434}\u{043B}\u{044F} \u{0444}\u{0456}\u{043D}\u{0430}\u{043D}\u{0441}\u{043E}\u{0432}\u{0438}\u{0445} \u{043D}\u{043E}\u{0432}\u{0438}\u{043D}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF666688), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
