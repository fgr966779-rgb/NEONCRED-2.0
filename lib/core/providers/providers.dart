/// Barrel file for NEONCRED providers.
///
/// Re-exports all providers AND commonly-used types so that consuming
/// code only needs a single import.

// Environment config — centralized .env reader + API key providers
export '../config/env_provider.dart'
    show
        envProvider,
        EnvConfig,
        openRouterApiKeyProvider,
        sketchfabApiKeyProvider,
        serpApiKeyProvider,
        twelveDataApiKeyProvider,
        privatbankMerchantIdProvider,
        privatbankPasswordProvider,
        plaidClientIdProvider,
        plaidSecretProvider,
        mindeeApiKeyProvider,
        googleVisionApiKeyProvider,
        okxApiKeyProvider,
        okxSecretKeyProvider,
        couponApiKeyProvider,
        sendgridApiKeyProvider,
        amazonAccessKeyProvider,
        amazonSecretKeyProvider,
        amazonPartnerTagProvider,
        asrApiKeyProvider,
        ttsApiKeyProvider,
        firebaseApiKeyProvider,
        firebaseProjectIdProvider,
        priceApiApiKeyProvider,
        predicthqApiKeyProvider,
        olxApiKeyProvider;

// Database provider
// NOTE: Some types (PriceSharkItem, PriceWatchItem, NewsInsight, ScannedReceipt,
// PriceMatchRequest, RouletteItem, PreOrderGuard, LoyaltyCard, FreezeChallenge,
// CrowdFundContribution, SecondHandItem, MomentumItem, HagglingSession,
// ElasticityItem, PriceAlert) are intentionally excluded here because they are
// also defined as richer domain models in feature service files. Screens get
// the service versions through their feature provider imports. The database
// versions are still accessible via direct `database.dart` import in services.
export '../../data/database.dart'
    show
        Value,
        databaseProvider,
        AppDatabase,
        User,
        Goal,
        Deposit,
        GraveyardEntry,
        GraveyardEntriesCompanion,
        ReputationProfile,
        ReputationProfilesCompanion,
        PublicCommitment,
        PublicCommitmentsCompanion,
        FlashMobEvent,
        FlashMobEventsCompanion,
        SavingsContract,
        SavingsContractsCompanion,
        NudgeExperiment,
        NudgeExperimentsCompanion,
        PersuasionProfile,
        PersuasionProfilesCompanion,
        BankSyncConfig,
        BankSyncConfigsCompanion,
        AutoDeposit,
        AutoDepositsCompanion,
        TrophyEntry,
        TrophyEntriesCompanion,
        // NewsInsight — duplicate in news_radar_service.dart
        // NewsInsightsCompanion — use database.dart directly
        // PriceWatchItem — duplicate in price_oracle_service.dart
        // PriceWatchItemsCompanion — use database.dart directly
        CyberPet,
        CyberPetsCompanion,
        BudgetEntry,
        BudgetEntriesCompanion,
        BudgetReport,
        BudgetReportsCompanion,
        VoiceCommand,
        VoiceCommandsCompanion,
        CrowdFundWishlist,
        CrowdFundWishlistsCompanion,
        // CrowdFundContribution — duplicate in crowd_fund_service.dart
        // CrowdFundContributionsCompanion — use database.dart directly
        ARScanEntry,
        ARScanEntriesCompanion,
        SoundUnlock,
        SoundUnlocksCompanion,
        // PriceSharkItem — duplicate in price_shark_service.dart
        // PriceSharkItemsCompanion — use database.dart directly
        // RouletteItem — duplicate in price_roulette_service.dart
        // RouletteItemsCompanion — use database.dart directly
        // PriceMatchRequest — duplicate in price_match_service.dart
        // PriceMatchRequestsCompanion — use database.dart directly
        // PreOrderGuard — duplicate in preorder_guard_service.dart
        // PreOrderGuardsCompanion — use database.dart directly
        // LoyaltyCard — duplicate in loyalty_cruncher_service.dart
        // LoyaltyCardsCompanion — use database.dart directly
        // FreezeChallenge — duplicate in price_freeze_service.dart
        // FreezeChallengesCompanion — use database.dart directly
        RadarWishItem,
        RadarWishItemsCompanion,
        SmartAlertEntry,
        SmartAlertEntriesCompanion,
        AlertSubscription,
        AlertSubscriptionsCompanion,
        ArenaTournament,
        ArenaTournamentsCompanion,
        ArenaSubmission,
        ArenaSubmissionsCompanion,
        PriceForecast,
        PriceForecastsCompanion,
        // SecondHandItem — duplicate in secondhand_analyzer_service.dart
        // SecondHandItemsCompanion — use database.dart directly
        CalendarSubscription,
        CalendarSubscriptionsCompanion,
        PriceEvent,
        PriceEventsCompanion,
        // MomentumItem — duplicate in price_momentum_service.dart
        // MomentumItemsCompanion — use database.dart directly
        PriceWarEntry,
        PriceWarEntriesCompanion,
        // HagglingSession — duplicate in haggling_coach_service.dart
        // HagglingSessionsCompanion — use database.dart directly
        // ElasticityItem — duplicate in price_elasticity_service.dart
        // ElasticityItemsCompanion — use database.dart directly
        InventoryStalkerItem,
        InventoryStalkerItemsCompanion,
        LendingRecord,
        LendingRecordsCompanion,
        GoalProductLink,
        GoalProductLinksCompanion,
        HabitLoop,
        HabitLoopsCompanion,
        InflationShield,
        InflationShieldsCompanion,
        PriceHistoryEntry,
        PriceHistoryEntriesCompanion,
        PriceDetectiveItem,
        PriceDetectiveItemsCompanion,
        // PriceAlert — duplicate in price_oracle_service.dart & price_shark_service.dart
        // PriceAlertsCompanion — use database.dart directly
        WishlistUrl,
        WishlistUrlsCompanion,
        PriceShieldScan,
        PriceShieldScansCompanion,
        TimeMachineProjection,
        TimeMachineProjectionsCompanion,
        QuestChain,
        QuestChainsCompanion,
        CoachPrediction,
        CoachPredictionsCompanion,
        InflationWave,
        InflationWavesCompanion;

// Core service providers & types
export '../services/anti_churn_oracle_service.dart'
    show
        antiChurnOracleProvider,
        ChurnSignal,
        ChurnAnalysis,
        RescueMission,
        AntiChurnState;
export '../services/variable_reward_vault_service.dart'
    show
        variableRewardProvider,
        JackpotTier,
        JackpotResult,
        JackpotStats,
        VariableRewardState;
export '../services/future_self_service.dart'
    show
        futureSelfProvider,
        FutureSelfVision,
        FutureSelfState;

// Feature providers & types
// (show clauses exclude data-model classes that are already exported from database.dart)
export '../../features/graveyard/providers/savings_graveyard_provider.dart'
    show
        savingsGraveyardProvider,
        SavingsGraveyardState,
        SavingsGraveyardNotifier,
        GraveyardStats,
        GraveyardStatus,
        GraveyardStatusX;
export '../../features/reputation_forge/providers/reputation_forge_provider.dart'
    show
        reputationForgeProvider,
        ReputationForgeState,
        ReputationForgeNotifier,
        ReputationTier,
        ReputationTierX;
export '../../features/flash_mob/providers/flash_mob_provider.dart'
    show
        flashMobProvider,
        FlashMobState,
        FlashMobNotifier,
        FlashMobEventType,
        FlashMobEventTypeX;
export '../../features/choice_paradox/providers/choice_paradox_provider.dart'
    show
        choiceParadoxProvider,
        ChoiceParadoxState,
        ChoiceParadoxNotifier,
        ContractType,
        ContractTypeX;
export '../../features/nudge_lab/providers/nudge_lab_provider.dart'
    show
        nudgeLabProvider,
        NudgeLabState,
        NudgeLabNotifier,
        NudgeType,
        NudgeTypeX;
export '../../features/bank_sync/providers/bank_sync_provider.dart'
    show
        bankSyncProvider,
        BankSyncNotifier,
        BankSyncState,
        BankSyncStats,
        BankProvider,
        BankProviderX,
        SyncStatus,
        SyncStatusX,
        BankTransaction,
        AutoSaveRule,
        AutoSaveRuleType,
        AutoSaveRuleTypeX;
export '../../features/trophy_gallery/providers/trophy_gallery_provider.dart'
    show
        trophyGalleryProvider,
        TrophyGalleryNotifier,
        TrophyGalleryState,
        TrophyGalleryStats,
        Trophy3D,
        TrophyTier,
        TrophyTierX,
        TrophyUnlockResult;
export '../../features/news_radar/providers/news_radar_provider.dart'
    show
        newsRadarProvider,
        NewsRadarNotifier,
        NewsRadarState,
        NewsCategory,
        NewsCategoryX,
        NewsInsight;
export '../../features/price_oracle/providers/price_oracle_provider.dart'
    show
        priceOracleProvider,
        PriceOracleNotifier,
        PriceOracleState,
        PriceAlertType,
        PriceOracleStats,
        PriceWatchItem;
// PricePoint, PriceAlert NOT exported here — defined in multiple services; get from specific provider
export '../../features/receipt_scanner/providers/receipt_scanner_provider.dart'
    show
        receiptScannerProvider,
        ReceiptScannerNotifier,
        ReceiptScannerState,
        ReceiptLineItem,
        SpendingCategory,
        WeeklySpendingSummary,
        ReceiptScannerStats,
        ScannedReceipt;
export '../../features/cyber_pet/providers/cyber_pet_provider.dart'
    show
        cyberPetProvider,
        CyberPetNotifier,
        CyberPetState,
        CyberPetData,
        CyberPetStats,
        PetSpecies,
        PetEvolution,
        PetMood,
        PetDialogue,
        PetAccessory;
export '../../features/budget_dna/providers/budget_dna_provider.dart'
    show
        budgetDNAProvider,
        BudgetDNANotifier,
        BudgetDNAState,
        BudgetCategory,
        BudgetCategoryEntry,
        BudgetBreachAlert,
        MonthlyBudgetReport,
        EconomicIndicators,
        BudgetDNAStats;
export '../../features/voice_vault/providers/voice_vault_provider.dart'
    show
        voiceVaultProvider,
        VoiceVaultNotifier,
        VoiceVaultState,
        VoiceCommandType;
// VoiceCommand excluded — exported from database.dart
export '../../features/crowd_fund/providers/crowd_fund_provider.dart'
    show
        crowdFundProvider,
        CrowdFundNotifier,
        CrowdFundState,
        WishlistEntry,
        CrowdFundStats,
        WishlistStatus,
        WishlistOccasion,
        CrowdFundContribution;
export '../../features/ar_price_tag/providers/ar_price_tag_provider.dart'
    show
        arPriceTagProvider,
        ARPriceTagNotifier,
        ARPriceTagState,
        ARScanResult,
        ARScanHistory;
export '../../features/soundscapes/providers/soundscapes_provider.dart'
    show
        soundscapesProvider,
        SoundscapesNotifier,
        SoundscapesState,
        SoundEffect,
        SoundCollection,
        DepositSoundEvent,
        SoundTier;
// Price-focused features (Round 3)
export '../../features/price_shark/providers/price_shark_provider.dart'
    show
        priceSharkProvider,
        PriceSharkNotifier,
        PriceSharkState,
        PriceSharkItem;
// PricePoint, PriceAlert NOT exported here — defined in multiple services; get from specific provider
export '../../features/price_roulette/providers/price_roulette_provider.dart'
    show
        priceRouletteProvider,
        PriceRouletteNotifier,
        PriceRouletteState,
        SpinResult,
        RouletteItem;
export '../../features/price_match/providers/price_match_provider.dart'
    show
        priceMatchProvider,
        PriceMatchNotifier,
        PriceMatchState,
        PriceMatchStatus,
        PriceMatchRequest;
export '../../features/preorder_guard/providers/preorder_guard_provider.dart'
    show
        preOrderGuardProvider,
        PreOrderGuardNotifier,
        PreOrderGuardState,
        GuardRecommendation,
        PreOrderGuard,
        DepreciationPoint;
export '../../features/loyalty_cruncher/providers/loyalty_cruncher_provider.dart'
    show
        loyaltyCruncherProvider,
        LoyaltyCruncherNotifier,
        LoyaltyCruncherState,
        StorePrice,
        EffectivePrice,
        CouponCode,
        LoyaltyCard;
export '../../features/price_freeze/providers/price_freeze_provider.dart'
    show
        priceFreezeProvider,
        PriceFreezeNotifier,
        PriceFreezeState,
        DailySnapshot,
        FreezeChallenge;
export '../../features/wishlist_radar/providers/wishlist_radar_provider.dart'
    show
        wishlistRadarProvider,
        WishlistRadarNotifier,
        WishlistRadarState,
        BuyRecommendation,
        WeeklyBuyGuide,
        UrgencyLevel;
// RadarWishItem excluded — exported from database.dart
export '../../features/smart_alerts/providers/smart_alerts_provider.dart'
    show
        smartAlertsProvider,
        SmartAlertsNotifier,
        SmartAlertsState,
        PriceAlertModel,
        AlertStatus,
        AlertUrgency;
export '../../features/price_arena/providers/price_arena_provider.dart'
    show
        priceArenaProvider,
        PriceArenaNotifier,
        PriceArenaState,
        ArenaLeaderboardEntry;
// ArenaTournament, ArenaSubmission excluded — exported from database.dart
// Seasonal & Momentum features (Round 4)
export '../../features/seasonal_calendar/providers/seasonal_calendar_provider.dart'
    show
        seasonalCalendarProvider,
        SeasonalCalendarNotifier,
        SeasonalCalendarState,
        CalendarDay,
        SeasonalEvent;
// CalendarSubscription excluded — exported from database.dart
export '../../features/price_momentum/providers/price_momentum_provider.dart'
    show
        priceMomentumProvider,
        PriceMomentumNotifier,
        PriceMomentumState,
        MomentumDataPoint,
        MomentumPhase,
        MomentumItem;
// AI Forecasting & Second-Hand features (Round 4)
export '../../features/price_prophet/providers/price_prophet_provider.dart'
    show
        priceProphetProvider,
        PriceProphetNotifier,
        PriceProphetState,
        PriceProphetItem,
        ForecastScenario,
        AccuracyRecord;
export '../../features/secondhand_analyzer/providers/secondhand_analyzer_provider.dart'
    show
        secondhandAnalyzerProvider,
        SecondHandAnalyzerNotifier,
        SecondHandState,
        SecondHandListing,
        SecondHandItem;
// DepreciationPoint NOT exported here — defined in multiple services; get from specific provider
// Price War, Haggling, Elasticity & Inventory features (Round 5)
export '../../features/price_war/providers/price_war_provider.dart'
    show
        priceWarProvider,
        PriceWarNotifier,
        PriceWarState,
        PriceWarItem,
        PriceBattle;
export '../../features/haggling_coach/providers/haggling_coach_provider.dart'
    show
        hagglingCoachProvider,
        HagglingCoachNotifier,
        HagglingState,
        HagglingScript,
        CompetitorPrice,
        HagglingSession;
export '../../features/price_elasticity/providers/price_elasticity_provider.dart'
    show
        priceElasticityProvider,
        PriceElasticityNotifier,
        PriceElasticityState,
        ElasticityAnalysis,
        DemandPoint,
        ElasticityType,
        ElasticityItem;
export '../../features/inventory_stalker/providers/inventory_stalker_provider.dart'
    show
        inventoryStalkerProvider,
        InventoryStalkerNotifier,
        InventoryStalkerState,
        InventoryItem,
        StockEntry,
        RestockPrediction;
// Lending Tracker (Round 6)
export '../../features/lending_tracker/providers/lending_tracker_provider.dart'
    show
        lendingTrackerProvider,
        LendingTrackerNotifier,
        LendingState,
        LendingStats;
// LendingRecord excluded — exported from database.dart
// Goal Price Integrator (Round 7)
export '../../features/goal_price_integrator/providers/goal_price_integrator_provider.dart'
    show
        goalPriceIntegratorProvider,
        GoalPriceIntegratorNotifier,
        GoalPriceIntegratorState,
        GoalProductLinkItem,
        GoalPriceIntegratorStats;
// Habit Loop Forge (Round 7)
export '../../features/habit_loop_forge/providers/habit_loop_forge_provider.dart'
    show
        habitLoopForgeProvider,
        HabitLoopForgeNotifier,
        HabitLoopForgeState,
        HabitLoopItem,
        HabitLoopStats;
// Inflation Shield Alert (Round 7)
export '../../features/inflation_shield/providers/inflation_shield_provider.dart'
    show
        inflationShieldProvider,
        InflationShieldNotifier,
        InflationShieldState,
        InflationShieldItem;
// Price History Detective (Round 7)
export '../../features/price_detective/providers/price_detective_provider.dart'
    show
        priceDetectiveProvider,
        PriceDetectiveNotifier,
        PriceDetectiveState,
        DetectiveItem,
        PriceHistoryPoint,
        PriceDetectiveStats;
// Wishlist URL Scanner (LTV Phase 2)
export '../../features/wishlist_url_scanner/providers/wishlist_url_scanner_provider.dart'
    show
        wishlistUrlScannerProvider,
        WishlistUrlScannerNotifier,
        WishlistUrlScannerState,
        WishlistUrlModel,
        UkrainianStore;
// Showroom Price Shield (LTV Phase 2)
export '../../features/price_shield/providers/price_shield_provider.dart'
    show
        priceShieldProvider,
        PriceShieldNotifier,
        PriceShieldState,
        PriceShieldScanModel;
// Savings Time Machine (LTV Phase 2)
export '../../features/savings_time_machine/providers/savings_time_machine_provider.dart'
    show
        savingsTimeMachineProvider,
        SavingsTimeMachineNotifier,
        SavingsTimeMachineState,
        TimeMachineModel;
// Savings Quest Chain (Retention 2026)
export '../../features/quest_chain/providers/quest_chain_provider.dart'
    show
        questChainProvider,
        QuestChainNotifier,
        QuestChainState,
        QuestModel,
        QuestType;
// Predictive Savings Coach (Retention 2026)
export '../../features/predictive_coach/providers/predictive_coach_provider.dart'
    show
        predictiveCoachProvider,
        PredictiveCoachNotifier,
        PredictiveCoachState,
        CoachPredictionModel,
        PredictionType;
// Anti-Inflation Shield Game (Retention 2026)
export '../../features/inflation_game/providers/inflation_game_provider.dart'
    show
        inflationGameProvider,
        InflationGameNotifier,
        InflationGameState,
        InflationWaveModel;

// Shared utilities
export '../utils/open_router_service.dart'
    show OpenRouterService, openRouterServiceProvider;
export '../utils/serp_api_service.dart'
    show SerpApiService, serpApiServiceProvider, SerpShoppingResult, SerpOrganicResult;

// =============================================================================
// Onboarding state providers
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Title for Goal A during onboarding.
final onboardingGoalATitleProvider = StateProvider<String>((ref) => 'PlayStation 5');

/// Target amount for Goal A during onboarding (UAH).
final onboardingGoalATargetProvider = StateProvider<double>((ref) => 25000.0);

/// Title for Goal B during onboarding.
final onboardingGoalBTitleProvider = StateProvider<String>((ref) => 'Gaming Monitor');

/// Target amount for Goal B during onboarding (UAH).
final onboardingGoalBTargetProvider = StateProvider<double>((ref) => 15000.0);

/// Async check for whether onboarding has been completed.
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('has_completed_onboarding') ?? false;
});

// Re-export SharedPreferences for convenience
export 'package:shared_preferences/shared_preferences.dart';
