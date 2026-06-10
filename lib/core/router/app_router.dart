import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/graveyard/screens/savings_graveyard_screen.dart';
import '../../features/reputation_forge/screens/reputation_forge_screen.dart';
import '../../features/flash_mob/screens/flash_mob_screen.dart';
import '../../features/choice_paradox/screens/choice_paradox_screen.dart';
import '../../features/nudge_lab/screens/nudge_lab_screen.dart';
import '../../features/anti_churn/screens/anti_churn_screen.dart';
import '../../features/future_self/screens/future_self_screen.dart';
import '../../features/variable_reward/screens/variable_reward_screen.dart';
import '../../features/bank_sync/screens/bank_sync_screen.dart';
import '../../features/trophy_gallery/screens/trophy_gallery_screen.dart';
import '../../features/news_radar/screens/news_radar_screen.dart';
import '../../features/price_oracle/screens/price_oracle_screen.dart';
import '../../features/receipt_scanner/screens/receipt_scanner_screen.dart';
import '../../features/cyber_pet/screens/cyber_pet_screen.dart';
import '../../features/budget_dna/screens/budget_dna_screen.dart';
import '../../features/voice_vault/screens/voice_vault_screen.dart';
import '../../features/crowd_fund/screens/crowd_fund_screen.dart';
import '../../features/ar_price_tag/screens/ar_price_tag_screen.dart';
import '../../features/soundscapes/screens/soundscapes_screen.dart';
import '../../features/price_shark/screens/price_shark_screen.dart';
import '../../features/price_roulette/screens/price_roulette_screen.dart';
import '../../features/price_match/screens/price_match_screen.dart';
import '../../features/preorder_guard/screens/preorder_guard_screen.dart';
import '../../features/loyalty_cruncher/screens/loyalty_cruncher_screen.dart';
import '../../features/price_freeze/screens/price_freeze_screen.dart';
import '../../features/wishlist_radar/screens/wishlist_radar_screen.dart';
import '../../features/smart_alerts/screens/smart_alerts_screen.dart';
import '../../features/price_arena/screens/price_arena_screen.dart';
import '../../features/price_prophet/screens/price_prophet_screen.dart';
import '../../features/secondhand_analyzer/screens/secondhand_analyzer_screen.dart';
import '../../features/seasonal_calendar/screens/seasonal_calendar_screen.dart';
import '../../features/price_momentum/screens/price_momentum_screen.dart';
import '../../features/price_war/screens/price_war_screen.dart';
import '../../features/haggling_coach/screens/haggling_coach_screen.dart';
import '../../features/price_elasticity/screens/price_elasticity_screen.dart';
import '../../features/inventory_stalker/screens/inventory_stalker_screen.dart';
import '../../features/lending_tracker/screens/lending_tracker_screen.dart';
import '../../features/goal_price_integrator/screens/goal_price_integrator_screen.dart';
import '../../features/habit_loop_forge/screens/habit_loop_forge_screen.dart';
import '../../features/inflation_shield/screens/inflation_shield_screen.dart';
import '../../features/price_detective/screens/price_detective_screen.dart';
import '../../features/wishlist_url_scanner/screens/wishlist_url_scanner_screen.dart';
import '../../features/price_shield/screens/price_shield_screen.dart';
import '../../features/savings_time_machine/screens/savings_time_machine_screen.dart';
import '../../features/quest_chain/screens/quest_chain_screen.dart';
import '../../features/predictive_coach/screens/predictive_coach_screen.dart';
import '../../features/inflation_game/screens/inflation_game_screen.dart';

// =============================================================================
// GoRouter configuration for NEONCRED
// =============================================================================
//
// All feature screens are registered as top-level routes.
// ShellRoute or nested navigation can be added for a main tab bar.
//
// Route naming convention:
//   /feature-name  →  FeatureScreen
// =============================================================================

/// Application router — single source of truth for all routes.
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    // ── Home / placeholder ──────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const _HomeShell(),
    ),

    // ── Feature: Savings Graveyard (#1) ─────────────────────────────────────
    GoRoute(
      path: '/graveyard',
      builder: (context, state) => const SavingsGraveyardScreen(),
    ),

    // ── Feature: Anti-Churn Oracle (#2) ─────────────────────────────────────
    GoRoute(
      path: '/anti-churn',
      builder: (context, state) => const AntiChurnScreen(),
    ),

    // ── Feature: Future Self (#3) ───────────────────────────────────────────
    GoRoute(
      path: '/future-self',
      builder: (context, state) => const FutureSelfScreen(),
    ),

    // ── Feature: Variable Reward Vault (#4) ─────────────────────────────────
    GoRoute(
      path: '/variable-reward',
      builder: (context, state) => const VariableRewardScreen(),
    ),

    // ── Feature: Reputation Forge (#6) ──────────────────────────────────────
    GoRoute(
      path: '/reputation-forge',
      builder: (context, state) => const ReputationForgeScreen(),
    ),

    // ── Feature: Flash Mob (#7) ─────────────────────────────────────────────
    GoRoute(
      path: '/flash-mob',
      builder: (context, state) => const FlashMobScreen(),
    ),

    // ── Feature: Choice Paradox (#8) ────────────────────────────────────────
    GoRoute(
      path: '/choice-paradox',
      builder: (context, state) => const ChoiceParadoxScreen(),
    ),

    // ── Feature: Nudge Lab (#10) ────────────────────────────────────────────
    GoRoute(
      path: '/nudge-lab',
      builder: (context, state) => const NudgeLabScreen(),
    ),

    // ── Feature: Bank Sync Oracle (#5) ──────────────────────────────────────
    GoRoute(
      path: '/bank-sync',
      builder: (context, state) => const BankSyncScreen(),
    ),

    // ── Feature: 3D Trophy Gallery (#7) ─────────────────────────────────────
    GoRoute(
      path: '/trophy-gallery',
      builder: (context, state) => const TrophyGalleryScreen(),
    ),

    // ── Feature: Financial News Radar (#8) ──────────────────────────────────
    GoRoute(
      path: '/news-radar',
      builder: (context, state) => const NewsRadarScreen(),
    ),

    // ── Feature: Price Oracle (#1 Round 2) ──────────────────────────────────
    GoRoute(
      path: '/price-oracle',
      builder: (context, state) => const PriceOracleScreen(),
    ),

    // ── Feature: Receipt Scanner AI (#3 Round 2) ───────────────────────────
    GoRoute(
      path: '/receipt-scanner',
      builder: (context, state) => const ReceiptScannerScreen(),
    ),

    // ── Feature: Cyber-Pet Companion (#4 Round 2) ──────────────────────────
    GoRoute(
      path: '/cyber-pet',
      builder: (context, state) => const CyberPetScreen(),
    ),

    // ── Feature: Budget DNA Scanner (#10 Round 2) ──────────────────────────
    GoRoute(
      path: '/budget-dna',
      builder: (context, state) => const BudgetDNAScreen(),
    ),

    // ── Feature: Voice Vault (#2 Round 2) ──────────────────────────────────
    GoRoute(
      path: '/voice-vault',
      builder: (context, state) => const VoiceVaultScreen(),
    ),

    // ── Feature: Crowd-Fund Wishes (#3 Round 2) ────────────────────────────
    GoRoute(
      path: '/crowd-fund',
      builder: (context, state) => const CrowdFundScreen(),
    ),

    // ── Feature: AR Price Tag (#7 Round 2) ─────────────────────────────────
    GoRoute(
      path: '/ar-price-tag',
      builder: (context, state) => const ARPriceTagScreen(),
    ),

    // ── Feature: Deposit Soundscapes (#8 Round 2) ──────────────────────────
    GoRoute(
      path: '/soundscapes',
      builder: (context, state) => const SoundscapesScreen(),
    ),

    // ── Feature: Price Shark Tracker (#1 Round 3) ─────────────────────────
    GoRoute(
      path: '/price-shark',
      builder: (context, state) => const PriceSharkScreen(),
    ),

    // ── Feature: Price Drop Roulette (#2 Round 3) ────────────────────────
    GoRoute(
      path: '/price-roulette',
      builder: (context, state) => const PriceRouletteScreen(),
    ),

    // ── Feature: Price Match Ninja (#4 Round 3) ──────────────────────────
    GoRoute(
      path: '/price-match',
      builder: (context, state) => const PriceMatchScreen(),
    ),

    // ── Feature: Pre-Order Price Guard (#5 Round 3) ───────────────────────
    GoRoute(
      path: '/preorder-guard',
      builder: (context, state) => const PreOrderGuardScreen(),
    ),

    // ── Feature: Store Loyalty Price Cruncher (#6 Round 3) ────────────────
    GoRoute(
      path: '/loyalty-cruncher',
      builder: (context, state) => const LoyaltyCruncherScreen(),
    ),

    // ── Feature: Price Freeze Challenge (#7 Round 3) ──────────────────────
    GoRoute(
      path: '/price-freeze',
      builder: (context, state) => const PriceFreezeScreen(),
    ),

    // ── Feature: Wish-List Price Radar (#8 Round 3) ──────────────────────
    GoRoute(
      path: '/wishlist-radar',
      builder: (context, state) => const WishlistRadarScreen(),
    ),

    // ── Feature: Smart Price Alerts+ (#9 Round 3) ────────────────────────
    GoRoute(
      path: '/smart-alerts',
      builder: (context, state) => const SmartAlertsScreen(),
    ),

    // ── Feature: Price Arena (#10 Round 3) ───────────────────────────────
    GoRoute(
      path: '/price-arena',
      builder: (context, state) => const PriceArenaScreen(),
    ),

    // ── Feature: Price Prophet AI (#1 Round 4) ──────────────────────────
    GoRoute(
      path: '/price-prophet',
      builder: (context, state) => const PriceProphetScreen(),
    ),

    // ── Feature: Second-Hand Price Analyzer (#2 Round 4) ────────────────
    GoRoute(
      path: '/secondhand-analyzer',
      builder: (context, state) => const SecondhandAnalyzerScreen(),
    ),

    // ── Feature: Seasonal Price Calendar (#4 Round 4) ────────────────────
    GoRoute(
      path: '/seasonal-calendar',
      builder: (context, state) => const SeasonalCalendarScreen(),
    ),

    // ── Feature: Price Momentum Tracker (#10 Round 4) ───────────────────
    GoRoute(
      path: '/price-momentum',
      builder: (context, state) => const PriceMomentumScreen(),
    ),

    // ── Feature: Price War Sentinel (#4 Round 5) ─────────────────────────
    GoRoute(
      path: '/price-war',
      builder: (context, state) => const PriceWarScreen(),
    ),

    // ── Feature: Haggling AI Coach (#8 Round 5) ─────────────────────────
    GoRoute(
      path: '/haggling-coach',
      builder: (context, state) => const HagglingCoachScreen(),
    ),

    // ── Feature: Price Elasticity Explorer (#9 Round 5) ──────────────────
    GoRoute(
      path: '/price-elasticity',
      builder: (context, state) => const PriceElasticityScreen(),
    ),

    // ── Feature: Inventory Price Stalker (#10 Round 5) ──────────────────
    GoRoute(
      path: '/inventory-stalker',
      builder: (context, state) => const InventoryStalkerScreen(),
    ),

    // ── Feature: Lending Tracker (#6 Round 6) ──────────────────────────
    GoRoute(
      path: '/lending-tracker',
      builder: (context, state) => const LendingTrackerScreen(),
    ),

    // ── Feature: Goal Price Integrator (#1 Round 7) ────────────────────
    GoRoute(
      path: '/goal-price-integrator',
      builder: (context, state) => const GoalPriceIntegratorScreen(),
    ),

    // ── Feature: Habit Loop Forge (#5 Round 7) ─────────────────────────
    GoRoute(
      path: '/habit-loop-forge',
      builder: (context, state) => const HabitLoopForgeScreen(),
    ),

    // ── Feature: Inflation Shield Alert (#8 Round 7) ───────────────────
    GoRoute(
      path: '/inflation-shield',
      builder: (context, state) => const InflationShieldScreen(),
    ),

    // ── Feature: Price History Detective (#10 Round 7) ──────────────────
    GoRoute(
      path: '/price-detective',
      builder: (context, state) => const PriceDetectiveScreen(),
    ),

    // ── Feature: Wishlist URL Scanner (#1 LTV Phase 2) ──────────────────
    GoRoute(
      path: '/wishlist-url-scanner',
      builder: (context, state) => const WishlistUrlScannerScreen(),
    ),

    // ── Feature: Showroom Price Shield (#8 LTV Phase 2) ─────────────────
    GoRoute(
      path: '/price-shield',
      builder: (context, state) => const PriceShieldScreen(),
    ),

    // ── Feature: Savings Time Machine (#10 LTV Phase 2) ─────────────────
    GoRoute(
      path: '/savings-time-machine',
      builder: (context, state) => const SavingsTimeMachineScreen(),
    ),

    // ── Feature: Savings Quest Chain (#1 Retention 2026) ──────────────
    GoRoute(
      path: '/quest-chain',
      builder: (context, state) => const QuestChainScreen(),
    ),

    // ── Feature: Predictive Savings Coach (#6 Retention 2026) ──────────
    GoRoute(
      path: '/predictive-coach',
      builder: (context, state) => const PredictiveCoachScreen(),
    ),

    // ── Feature: Anti-Inflation Shield Game (#10 Retention 2026) ───────
    GoRoute(
      path: '/inflation-game',
      builder: (context, state) => const InflationGameScreen(),
    ),
  ],
);

// =============================================================================
// Home shell — feature navigation hub
// =============================================================================

class _HomeShell extends StatelessWidget {
  const _HomeShell();

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);

  /// All feature routes for the home grid.
  static const _features = <_FeatureLink>[
    _FeatureLink('NecroSpend', '/graveyard'),
    _FeatureLink('RetainCore', '/anti-churn'),
    _FeatureLink('FutureMirror', '/future-self'),
    _FeatureLink('LootBox', '/variable-reward'),
    _FeatureLink('RepForge', '/reputation-forge'),
    _FeatureLink('SwarmDrop', '/flash-mob'),
    _FeatureLink('ParadoxCtrl', '/choice-paradox'),
    _FeatureLink('NudgeLab', '/nudge-lab'),
    _FeatureLink('BankLink', '/bank-sync'),
    _FeatureLink('HoloTrophies', '/trophy-gallery'),
    _FeatureLink('InfoScan', '/news-radar'),
    _FeatureLink('PriceOracle', '/price-oracle'),
    _FeatureLink('ReceiptRip', '/receipt-scanner'),
    _FeatureLink('NeonPet', '/cyber-pet'),
    _FeatureLink('BudgetHelix', '/budget-dna'),
    _FeatureLink('VoiceCrypt', '/voice-vault'),
    _FeatureLink('FundSwarm', '/crowd-fund'),
    _FeatureLink('ARTag', '/ar-price-tag'),
    _FeatureLink('SynthWave', '/soundscapes'),
    _FeatureLink('PriceShark', '/price-shark'),
    _FeatureLink('DropRoulette', '/price-roulette'),
    _FeatureLink('MatchBlade', '/price-match'),
    _FeatureLink('PreGuard', '/preorder-guard'),
    _FeatureLink('BonusCrunch', '/loyalty-cruncher'),
    _FeatureLink('FreezeRay', '/price-freeze'),
    _FeatureLink('WishScan', '/wishlist-radar'),
    _FeatureLink('AlertCore', '/smart-alerts'),
    _FeatureLink('PriceColosseum', '/price-arena'),
    _FeatureLink('PriceProphet', '/price-prophet'),
    _FeatureLink('ReGear', '/secondhand-analyzer'),
    _FeatureLink('SeasonPulse', '/seasonal-calendar'),
    _FeatureLink('Momentum', '/price-momentum'),
    _FeatureLink('PriceWar', '/price-war'),
    _FeatureLink('HaggleAI', '/haggling-coach'),
    _FeatureLink('FlexPrice', '/price-elasticity'),
    _FeatureLink('StockGhost', '/inventory-stalker'),
    _FeatureLink('LoanTracker', '/lending-tracker'),
    _FeatureLink('GoalSync', '/goal-price-integrator'),
    _FeatureLink('HabitForge', '/habit-loop-forge'),
    _FeatureLink('InflaShield', '/inflation-shield'),
    _FeatureLink('PriceEye', '/price-detective'),
    _FeatureLink('LinkRip', '/wishlist-url-scanner'),
    _FeatureLink('ShowroomShield', '/price-shield'),
    _FeatureLink('ChronoSaver', '/savings-time-machine'),
    _FeatureLink('QuestChain', '/quest-chain'),
    _FeatureLink('SageAI', '/predictive-coach'),
    _FeatureLink('InflaWall', '/inflation-game'),
  ];

  @override
  Widget build(BuildContext context) {
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
          child: const Text(
            'NEONCRED',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: Colors.white,
            ),
          ),
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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          return _FeatureCard(feature: feature);
        },
      ),
    );
  }
}

class _FeatureLink {
  final String label;
  final String route;

  const _FeatureLink(this.label, this.route);
}

class _FeatureCard extends StatelessWidget {
  final _FeatureLink feature;

  const _FeatureCard({required this.feature});

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _cardBg = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(feature.route),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _cyan.withOpacity(0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _cyan.withOpacity(0.04),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_cyan, _purple],
            ).createShader(bounds),
            child: Text(
              feature.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
