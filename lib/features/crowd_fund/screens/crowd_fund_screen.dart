import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../providers/crowd_fund_provider.dart';

// =========================================================================
// CrowdFundScreen — collective funding for savings goals
// =========================================================================

class CrowdFundScreen extends ConsumerStatefulWidget {
  const CrowdFundScreen({super.key});

  @override
  ConsumerState<CrowdFundScreen> createState() => _CrowdFundScreenState();
}

class _CrowdFundScreenState extends ConsumerState<CrowdFundScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(crowdFundProvider.notifier).loadWishlists();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =======================================================================
  // Create-wishlist dialog
  // =======================================================================

  Future<void> _showCreateWishlistDialog() async {
    final database = ref.read(databaseProvider);
    final goals = await database.getAllGoals();

    if (!mounted) return;

    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Спершу створіть ціль заощаджень!'),
          backgroundColor: Color(0xFFFF3366),
        ),
      );
      return;
    }

    Goal? selectedGoal;
    WishlistOccasion selectedOccasion = WishlistOccasion.justBecause;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF0D1117),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFF00F0FF).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              title: const Text(
                'НОВИЙ ВІШЛІСТ',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal selector
                    const Text(
                      'Оберіть ціль:',
                      style: TextStyle(
                        color: Color(0xFFB088FF),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF6B00FF).withOpacity(0.3),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Goal>(
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1F2E),
                          hint: const Text(
                            'Оберіть ціль...',
                            style: TextStyle(color: Color(0xFF8888AA)),
                          ),
                          value: selectedGoal,
                          items: goals.map((g) {
                            return DropdownMenuItem<Goal>(
                              value: g,
                              child: Text(
                                '${g.name} — ${g.targetAmount.toStringAsFixed(0)} ₴',
                                style: const TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            setDialogState(() => selectedGoal = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Occasion selector
                    const Text(
                      'Привід:',
                      style: TextStyle(
                        color: Color(0xFFB088FF),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...WishlistOccasion.values.map(
                      (occasion) => GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedOccasion = occasion);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: selectedOccasion == occasion
                                ? const Color(0xFF6B00FF).withOpacity(0.25)
                                : const Color(0xFF1A1F2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedOccasion == occasion
                                  ? const Color(0xFF6B00FF)
                                  : const Color(0xFF6B00FF).withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                occasion.iconEmoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                occasion.labelUA,
                                style: TextStyle(
                                  color: selectedOccasion == occasion
                                      ? const Color(0xFF00F0FF)
                                      : const Color(0xFF8888AA),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Скасувати',
                    style: TextStyle(color: Color(0xFF8888AA)),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedGoal == null
                      ? null
                      : () async {
                          final notifier =
                              ref.read(crowdFundProvider.notifier);
                          await notifier.createWishlist(
                            selectedGoal!.id,
                            selectedOccasion.name,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F0FF),
                    foregroundColor: const Color(0xFF0A0E17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Створити',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =======================================================================
  // Build
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crowdFundProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text(
          'CROWD-FUND',
          style: TextStyle(
            color: Color(0xFF00F0FF),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F0FF)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00F0FF),
          indicatorWeight: 2,
          labelColor: const Color(0xFF00F0FF),
          unselectedLabelColor: const Color(0xFF8888AA),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            letterSpacing: 1,
          ),
          tabs: const [
            Tab(text: 'ВІШЛІСТИ'),
            Tab(text: 'ВНЕСКИ'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00F0FF),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _WishlistsTab(state: state, onShare: _shareWishlist),
                _ContributionsTab(state: state),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateWishlistDialog,
        backgroundColor: const Color(0xFF00F0FF),
        foregroundColor: const Color(0xFF0A0E17),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  Future<void> _shareWishlist(WishlistEntry wishlist) async {
    final notifier = ref.read(crowdFundProvider.notifier);
    final shareCode = await notifier.shareWishlist(wishlist.wishListId);
    if (!mounted) return;

    if (shareCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не вдалося згенерувати посилання'),
          backgroundColor: Color(0xFFFF3366),
        ),
      );
      return;
    }

    final link = notifier.generateShareLink(wishlist.wishListId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Посилання скопійовано: $link'),
        backgroundColor: const Color(0xFF00FF88),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// =========================================================================
// Tab 1: Wishlists
// =========================================================================

class _WishlistsTab extends StatelessWidget {
  final CrowdFundState state;
  final Future<void> Function(WishlistEntry) onShare;

  const _WishlistsTab({required this.state, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF00F0FF),
      backgroundColor: const Color(0xFF0D1117),
      onRefresh: () async {
        // Trigger reload by reading notifier
      },
      child: CustomScrollView(
        slivers: [
          // Stats card
          SliverToBoxAdapter(child: _StatsCard(stats: state.stats)),

          // Wishlist cards
          if (state.wishlists.isEmpty)
            const SliverToBoxAdapter(child: _EmptyWishlistsCard())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _WishlistCard(
                  wishlist: state.wishlists[index],
                  onShare: onShare,
                ),
                childCount: state.wishlists.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}

// =========================================================================
// Tab 2: Contributions
// =========================================================================

class _ContributionsTab extends StatelessWidget {
  final CrowdFundState state;

  const _ContributionsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final allContributions = state.wishlists
        .expand((w) => w.contributions.map((c) => (c, w)))
        .toList();

    return CustomScrollView(
      slivers: [
        if (allContributions.isEmpty)
          const SliverToBoxAdapter(child: _EmptyContributionsCard())
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'УСІ ВНЕСКИ (${allContributions.length})',
                style: const TextStyle(
                  color: Color(0xFF6B00FF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final (contribution, wishlist) = allContributions[index];
                return _ContributionCard(
                  contribution: contribution,
                  wishlistName: wishlist.goalName,
                );
              },
              childCount: allContributions.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }
}

// =========================================================================
// Stats card
// =========================================================================

class _StatsCard extends StatelessWidget {
  final CrowdFundStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'СТАТИСТИКА CROWD-FUND',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                label: 'Зібрано',
                value: stats.totalRaisedUAH,
                color: const Color(0xFF00FF88),
                icon: Icons.account_balance_wallet_rounded,
              ),
              _StatItem(
                label: 'Вішлісти',
                value: '${stats.totalWishlists}',
                color: const Color(0xFF00F0FF),
                icon: Icons.receipt_long_rounded,
              ),
              _StatItem(
                label: 'Друзі',
                value: '${stats.friendsContributed}',
                color: const Color(0xFF6B00FF),
                icon: Icons.people_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Wishlist card
// =========================================================================

class _WishlistCard extends StatelessWidget {
  final WishlistEntry wishlist;
  final Future<void> Function(WishlistEntry) onShare;

  const _WishlistCard({
    required this.wishlist,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = wishlist.isFullyFunded
        ? const Color(0xFF00FF88)
        : wishlist.progress >= 0.5
            ? const Color(0xFF00F0FF)
            : const Color(0xFFFF3366);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            progressColor.withOpacity(0.08),
            const Color(0xFF0D1117),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: progressColor.withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withOpacity(0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: name + share button
          Row(
            children: [
              Expanded(
                child: Text(
                  wishlist.goalName,
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Occasion badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B00FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6B00FF).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  '${wishlist.occasion.iconEmoji} ${wishlist.occasion.labelUA}',
                  style: const TextStyle(
                    color: Color(0xFFB088FF),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Share button
              GestureDetector(
                onTap: () => onShare(wishlist),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00F0FF).withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: Color(0xFF00F0FF),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Amounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wishlist.currentAmountUAH,
                style: TextStyle(
                  color: progressColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'з ${wishlist.targetAmountUAH}',
                style: const TextStyle(
                  color: Color(0xFF8888AA),
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Background track
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Filled track
                FractionallySizedBox(
                  widthFactor: wishlist.progress,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor,
                          progressColor.withOpacity(0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: progressColor.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Progress info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                wishlist.progressPercent,
                style: TextStyle(
                  color: progressColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (wishlist.status == WishlistStatus.active)
                Text(
                  '${wishlist.daysRemaining} дн. залишилось',
                  style: const TextStyle(
                    color: Color(0xFF8888AA),
                    fontSize: 11,
                  ),
                )
              else
                Text(
                  wishlist.status.labelUA,
                  style: TextStyle(
                    color: wishlist.status == WishlistStatus.completed
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF3366),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),

          // Contributions list
          if (wishlist.contributions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(
              color: Color(0xFF1A1F2E),
              height: 1,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Color(0xFF6B00FF),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'ВНЕСКИ (${wishlist.contributions.length})',
                  style: const TextStyle(
                    color: Color(0xFF6B00FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...wishlist.contributions.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1F2E),
                        border: Border.all(
                          color: const Color(0xFF6B00FF).withOpacity(0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          c.contributorName.isNotEmpty
                              ? c.contributorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFFB088FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.contributorName,
                        style: const TextStyle(
                          color: Color(0xFFB088FF),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      c.amountUAH,
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =========================================================================
// Contribution card (Tab 2)
// =========================================================================

class _ContributionCard extends StatelessWidget {
  final CrowdFundContribution contribution;
  final String wishlistName;

  const _ContributionCard({
    required this.contribution,
    required this.wishlistName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1F2E), Color(0xFF0D1117)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contribution.thankYouSent
              ? const Color(0xFF00FF88).withOpacity(0.3)
              : const Color(0xFF6B00FF).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (contribution.thankYouSent
                    ? const Color(0xFF00FF88)
                    : const Color(0xFF6B00FF))
                .withOpacity(0.06),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B00FF).withOpacity(0.4),
                  const Color(0xFF00F0FF).withOpacity(0.2),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00F0FF).withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                contribution.contributorName.isNotEmpty
                    ? contribution.contributorName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + amount row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        contribution.contributorName,
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      contribution.amountUAH,
                      style: const TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Wishlist name
                Text(
                  '→ $wishlistName',
                  style: const TextStyle(
                    color: Color(0xFF8888AA),
                    fontSize: 12,
                  ),
                ),

                // Message
                if (contribution.message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6B00FF).withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFFB088FF),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contribution.message,
                            style: const TextStyle(
                              color: Color(0xFFB088FF),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Thank you status
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (contribution.thankYouSent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF88).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00FF88).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFF00FF88),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Подяку надіслано',
                              style: TextStyle(
                                color: Color(0xFF00FF88),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3366).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFF3366).withOpacity(0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              color: Color(0xFFFF3366),
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Подякувати',
                              style: TextStyle(
                                color: Color(0xFFFF3366),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
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
// Empty states
// =========================================================================

class _EmptyWishlistsCard extends StatelessWidget {
  const _EmptyWishlistsCard();

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
            '\u{1F31F}',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 16),
          Text(
            'Вішлістів ще немає',
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Створіть вішліст з вашої цілі заощаджень\nі друзі зможуть допомогти!',
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

class _EmptyContributionsCard extends StatelessWidget {
  const _EmptyContributionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00F0FF).withOpacity(0.15),
        ),
      ),
      child: const Column(
        children: [
          Text(
            '\u{1F4B0}',
            style: TextStyle(fontSize: 48),
          ),
          SizedBox(height: 16),
          Text(
            'Внесків ще немає',
            style: TextStyle(
              color: Color(0xFF8888AA),
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Поділіться своїм вішлістом з друзями,\nщоб отримати внески!',
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
