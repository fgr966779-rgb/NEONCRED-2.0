# NEONCRED -- UNIVERSAL AI AGENT PROMPT
## Cyberpunk Gamified Savings & Price Intelligence App | Full Build Specification
### Version 2.0 | Universal (Claude Code / Gemini / GPT-4o / Cursor / Cline)

---

> **AGENT INSTRUCTIONS -- READ BEFORE ACTING**
>
> You are a world-class senior mobile engineer and UI/UX architect tasked with building a **complete, production-ready mobile application**. This document is your single source of truth for NEONCRED. It is intentionally exhaustive -- every section carries weight. Do not skim, do not interpolate silently, do not invent features not described here.
>
> **Execution protocol:**
> 1. Read this entire document before writing a single line of code.
> 2. Think through the full architecture before scaffolding.
> 3. Build iteratively: foundation -> data layer -> navigation -> screens -> animations -> polish.
> 4. After each major milestone, verify it against the relevant section of this spec.
> 5. Where this spec leaves room for creative freedom (marked with ART), use it generously. Where it is prescriptive, follow it precisely.
> 6. All UI text MUST be in Ukrainian (UA). No emojis anywhere in the app.
> 7. Use `withOpacity()` not `withValues()` for Flutter 3.44 compatibility.

---

## PART 1 -- PROJECT OVERVIEW

### 1.1 Application Identity

| Field | Value |
|---|---|
| App Name | **NEONCRED** |
| Tagline | *"Zberihay z cilyu. Vyhravay zo stylyem."* (Save with purpose. Win with style.) |
| Package | `com.neoncred.neoncred` |
| Category | Personal Finance / Gamification / Price Intelligence / Lifestyle |
| Primary Purpose | Cyberpunk-themed gamified savings tracker with 47+ AI-powered features for price tracking, budget analysis, and behavioral economics |
| Target Audience | Young adults (18-35) passionate about gaming, tech, and cyberpunk aesthetics |
| Platforms | Android (arm64-v8a primary), iOS (future) |
| Minimum OS | Android 8.0 (API 26) |
| Feature Count | 47+ features across 7 rounds |
| Localization | Ukrainian (primary), English (secondary) |
| Offline Support | Full offline capability via Drift SQLite; sync when online |

### 1.2 Core Mission Statement

NEONCRED transforms the mundane act of saving money into an engaging, visually stunning cyberpunk gaming experience. Users create savings goals, deposit money toward them, track prices, analyze budgets, maintain streaks, earn achievements, and celebrate milestones -- all within a dark, cyberpunk-infused neon aesthetic that feels like a premium gaming product, not a bank app.

The app must feel **alive at all times**. Idle states should pulse gently. Actions should feel consequential and satisfying. Progress should be immediately visible and emotionally rewarding.

### 1.3 The Two Default Goals

| Goal | Label | Primary Accent Color |
|---|---|---|
| **Goal A** | PlayStation 5 | Electric Cyan `#00F0FF` |
| **Goal B** | Gaming Monitor | Neon Magenta `#FF00FF` |

Both goals exist simultaneously on first launch. The user sets a target price for each, a deadline (optional), and allocates deposits to either or both. Users can create additional custom goals.

---

## PART 2 -- FRAMEWORK & TECHNICAL STACK

### 2.1 Framework

**Flutter (Dart).** Version 3.44+ with Impeller renderer.

### 2.2 Architecture

**Clean Architecture** with feature-driven organization:

```
lib/
  core/
    constants/          # AppColors, AppSizes, AppStrings, AppDurations
    theme/              # AppTheme, TextStyles, ComponentThemes
    router/             # GoRouter configuration, route guards
    di/                 # Dependency injection (Riverpod providers)
    providers/          # Global providers barrel file
    utils/              # CurrencyFormatter, DateUtils, AnimationUtils
    services/           # OpenRouterService, SerpApiService, etc.
    config/             # EnvProvider for .env API keys
    data/               # UkrainianStores catalog
  data/
    database.dart       # Drift database with all tables
    database.g.dart     # Generated Drift code
  features/
    onboarding/         # Welcome, Goal setup, Class selection, Finish
    dashboard/          # Main home screen with goals, streak, deposit
    deposit/            # Deposit flow, allocation, confirmation
    goals/              # Goal detail, history, projection
    achievements/       # Badges, milestones, trophy room
    streaks/            # Streak tracking, calendar heatmap
    analytics/          # Charts, statistics, projections
    settings/           # Profile, notifications, themes, reset
    celebrations/       # Confetti, milestone modals, completion screen
    graveyard/          # NecroSpend -- failed goals resurrection
    reputation_forge/   # RepForge -- public commitments & karma
    flash_mob/          # SwarmDrop -- group savings events
    choice_paradox/     # ParadoxCtrl -- savings contracts
    nudge_lab/          # NudgeLab -- behavioral experiments
    anti_churn/         # RetainCore -- churn prediction & rescue
    future_self/        # FutureMirror -- future self visualization
    variable_reward/    # LootBox -- variable reward vault
    bank_sync/          # BankLink -- bank connection & round-up
    trophy_gallery/     # HoloTrophies -- 3D trophy collection
    news_radar/         # InfoScan -- financial news AI scanner
    price_oracle/       # PriceOracle -- price tracking & alerts
    receipt_scanner/    # ReceiptRip -- receipt OCR & analysis
    cyber_pet/          # NeonPet -- cyberpunk tamagotchi
    budget_dna/         # BudgetHelix -- budget DNA scanner
    voice_vault/        # VoiceCrypt -- voice command deposits
    crowd_fund/         # FundSwarm -- crowdfunding wishes
    ar_price_tag/       # ARTag -- AR price scanner
    soundscapes/        # SynthWave -- deposit sound effects
    price_shark/        # PriceShark -- price history tracker
    price_roulette/     # DropRoulette -- price drop gambling
    price_match/        # MatchBlade -- price match guarantees
    preorder_guard/     # PreGuard -- pre-order price protection
    loyalty_cruncher/   # BonusCrunch -- loyalty card optimizer
    price_freeze/       # FreezeRay -- price freeze challenge
    wishlist_radar/     # WishScan -- wishlist price radar
    smart_alerts/       # AlertCore -- smart price notifications
    price_arena/        # PriceColosseum -- price competition arena
    price_prophet/      # PriceProphet -- AI price forecasting
    secondhand_analyzer/ # ReGear -- used price analysis
    seasonal_calendar/  # SeasonPulse -- seasonal price calendar
    price_momentum/     # Momentum -- price momentum tracker
    price_war/          # PriceWar -- store price war sentinel
    haggling_coach/     # HaggleAI -- haggling AI coach
    price_elasticity/   # FlexPrice -- price elasticity explorer
    inventory_stalker/  # StockGhost -- inventory price stalker
    lending_tracker/    # LoanTracker -- lending & debt tracker
    goal_price_integrator/ # GoalSync -- goal-price linker
    habit_loop_forge/   # HabitForge -- habit loop builder
    inflation_shield/   # InflaShield -- inflation alert system
    price_detective/    # PriceEye -- price history detective
    wishlist_url_scanner/ # LinkRip -- URL wishlist scanner
    price_shield/       # ShowroomShield -- showroom price shield
    savings_time_machine/ # ChronoSaver -- savings time machine
    quest_chain/        # QuestChain -- savings quest chain
    predictive_coach/   # SageAI -- predictive savings coach
    inflation_game/     # InflaWall -- anti-inflation game
  main.dart             # App entry point
```

### 2.3 State Management

**Riverpod 2.x** (manual providers, no code generation for simplicity).

- `databaseProvider` -- Singleton AppDatabase
- Feature-specific `NotifierProvider` / `FutureProvider` for each feature
- `envProvider` -- Loads .env file for API keys
- No `setState` anywhere in the feature layer

### 2.4 Local Database

**Drift (formerly Moor)** for structured relational data. All tables defined in `lib/data/database.dart`.

Core tables:
- `Users` -- id, firebaseUid, displayName, characterClass, xp, level, karma, currentStreak, lastDepositAt, etc.
- `Goals` -- id, userId, name, currentAmount, savedAmount, targetAmount, targetDate, isCompleted, category
- `Deposits` -- id, goalId, amount, createdAt

Feature tables (47+ features, each with dedicated tables):
- `GraveyardEntries`, `ReputationProfiles`, `PublicCommitments`, `FlashMobEvents`, `SavingsContracts`, `NudgeExperiments`, `PersuasionProfiles`, `BankSyncConfigs`, `AutoDeposits`, `TrophyEntries`, `NewsInsights`, `PriceWatchItems`, `ScannedReceipts`, `CyberPets`, `BudgetEntries`, `BudgetReports`, `VoiceCommands`, `CrowdFundWishlists`, `CrowdFundContributions`, `ARScanEntries`, `SoundUnlocks`, `PriceSharkItems`, `RouletteItems`, `PriceMatchRequests`, `PreOrderGuards`, `LoyaltyCards`, `FreezeChallenges`, `RadarWishItems`, `SmartAlertEntries`, `AlertSubscriptions`, `ArenaTournaments`, `ArenaSubmissions`, `PriceForecasts`, `SecondHandItems`, `CalendarSubscriptions`, `PriceEvents`, `MomentumItems`, `PriceWarEntries`, `HagglingSessions`, `ElasticityItems`, `InventoryStalkerItems`, `LendingRecords`, `GoalProductLinks`, `HabitLoops`, `InflationShields`, `PriceHistoryEntries`, `PriceDetectiveItems`, `WishlistUrls`, `PriceShieldScans`, `TimeMachineProjections`, `QuestChains`, `CoachPredictions`, `InflationWaves`

### 2.5 Navigation

**GoRouter 14.x** with named routes.

Route structure:
```
/                        -> DashboardScreen (home with goals, streak, deposit)
/graveyard               -> SavingsGraveyardScreen (NecroSpend)
/anti-churn              -> AntiChurnScreen (RetainCore)
/future-self             -> FutureSelfScreen (FutureMirror)
/variable-reward         -> VariableRewardScreen (LootBox)
/reputation-forge        -> ReputationForgeScreen (RepForge)
/flash-mob               -> FlashMobScreen (SwarmDrop)
/choice-paradox          -> ChoiceParadoxScreen (ParadoxCtrl)
/nudge-lab               -> NudgeLabScreen (NudgeLab)
/bank-sync               -> BankSyncScreen (BankLink)
/trophy-gallery          -> TrophyGalleryScreen (HoloTrophies)
/news-radar              -> NewsRadarScreen (InfoScan)
/price-oracle            -> PriceOracleScreen (PriceOracle)
/receipt-scanner         -> ReceiptScannerScreen (ReceiptRip)
/cyber-pet               -> CyberPetScreen (NeonPet)
/budget-dna              -> BudgetDNAScreen (BudgetHelix)
/voice-vault             -> VoiceVaultScreen (VoiceCrypt)
/crowd-fund              -> CrowdFundScreen (FundSwarm)
/ar-price-tag            -> ARPriceTagScreen (ARTag)
/soundscapes             -> SoundscapesScreen (SynthWave)
/price-shark             -> PriceSharkScreen (PriceShark)
/price-roulette          -> PriceRouletteScreen (DropRoulette)
/price-match             -> PriceMatchScreen (MatchBlade)
/preorder-guard          -> PreOrderGuardScreen (PreGuard)
/loyalty-cruncher        -> LoyaltyCruncherScreen (BonusCrunch)
/price-freeze            -> PriceFreezeScreen (FreezeRay)
/wishlist-radar          -> WishlistRadarScreen (WishScan)
/smart-alerts            -> SmartAlertsScreen (AlertCore)
/price-arena             -> PriceArenaScreen (PriceColosseum)
/price-prophet           -> PriceProphetScreen (PriceProphet)
/secondhand-analyzer     -> SecondhandAnalyzerScreen (ReGear)
/seasonal-calendar       -> SeasonalCalendarScreen (SeasonPulse)
/price-momentum          -> PriceMomentumScreen (Momentum)
/price-war               -> PriceWarScreen (PriceWar)
/haggling-coach          -> HagglingCoachScreen (HaggleAI)
/price-elasticity        -> PriceElasticityScreen (FlexPrice)
/inventory-stalker       -> InventoryStalkerScreen (StockGhost)
/lending-tracker         -> LendingTrackerScreen (LoanTracker)
/goal-price-integrator   -> GoalPriceIntegratorScreen (GoalSync)
/habit-loop-forge        -> HabitLoopForgeScreen (HabitForge)
/inflation-shield        -> InflationShieldScreen (InflaShield)
/price-detective         -> PriceDetectiveScreen (PriceEye)
/wishlist-url-scanner    -> WishlistUrlScannerScreen (LinkRip)
/price-shield            -> PriceShieldScreen (ShowroomShield)
/savings-time-machine    -> SavingsTimeMachineScreen (ChronoSaver)
/quest-chain             -> QuestChainScreen (QuestChain)
/predictive-coach        -> PredictiveCoachScreen (SageAI)
/inflation-game          -> InflationGameScreen (InflaWall)
```

### 2.6 Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^14.2.0
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.0
  path: ^1.9.0
  path_provider: ^2.1.0
  google_fonts: ^6.2.0
  http: ^1.2.0
  flutter_dotenv: ^5.1.0
  json_annotation: ^4.9.0
  shared_preferences: ^2.2.0
  flutter_local_notifications: ^18.0.0

dev_dependencies:
  drift_dev: ^2.18.0
  build_runner: ^2.4.0
  flutter_lints: ^4.0.0
```

### 2.7 API Keys (loaded from .env)

- `OPENROUTER_API_KEY` -- AI chat completions (DeepSeek, GPT-4o)
- `SKETCHFAB_API_KEY` -- 3D model viewer
- `SERP_API_KEY` -- Web search & shopping
- `TWELVEDATA_API_KEY` -- Currency exchange rates
- `PRIVATBANK_MERCHANT_ID` / `PRIVATBANK_PASSWORD` -- Bank sync
- `PLAID_CLIENT_ID` / `PLAID_SECRET` -- International bank sync
- `MINDEE_API_KEY` -- Receipt OCR
- `GOOGLE_VISION_API_KEY` -- Image analysis
- `OKX_API_KEY` / `OKX_SECRET_KEY` -- Crypto prices
- `COUPON_API_KEY` -- Discount codes
- `SENDGRID_API_KEY` -- Email notifications
- `AMAZON_ACCESS_KEY` / `AMAZON_SECRET_KEY` / `AMAZON_PARTNER_TAG` -- Amazon prices
- `ASR_API_KEY` -- Speech recognition
- `TTS_API_KEY` -- Text-to-speech
- `FIREBASE_API_KEY` / `FIREBASE_PROJECT_ID` -- Cloud sync
- `PRICEAPI_API_KEY` -- Price comparison
- `PREDICTHQ_API_KEY` -- Event data
- `OLX_API_KEY` -- OLX marketplace prices

---

## PART 3 -- VISUAL DESIGN SYSTEM

### 3.1 Aesthetic Manifesto

NEONCRED inhabits a **dark cyberpunk / neon gaming** visual universe. Every screen breathes this aesthetic. There is no room for "clean white corporate" energy.

Key visual principles:
- **Dark-first**: All screens use deep dark backgrounds. Light mode does not exist in v2.0.
- **Neon accents**: Cyan and Purple are the twin souls of the app. They glow, they pulse, they bleed.
- **Glassmorphism**: Cards and modals use frosted-glass panels with subtle blur and luminous borders.
- **Depth**: Multiple z-layers. Background ambient effects, mid-layer cards, foreground interactive elements.
- **Typography**: Futuristic but legible. Numbers feel like HUD displays.
- **NO EMOJIS**: Absolutely no emoji characters in any UI text.

### 3.2 Color Palette

```dart
class AppColors {
  // === BACKGROUNDS ===
  static const Color background         = Color(0xFF0A0E17); // Near-black deep navy
  static const Color backgroundElevated = Color(0xFF111827); // Cards, panels
  static const Color backgroundSurface  = Color(0xFF1A1F2E); // Input fields, chips
  static const Color backgroundOverlay  = Color(0x990A0E17); // Modal overlays

  // === PRIMARY ACCENTS ===
  static const Color cyan               = Color(0xFF00F0FF); // Electric Cyan
  static const Color purple             = Color(0xFF6B00FF); // Neon Purple
  static const Color green              = Color(0xFF00FF88); // Success states
  static const Color red                = Color(0xFFFF3366); // Error states
  static const Color orange             = Color(0xFFFF6B00); // Warnings, streaks

  // === TEXT ===
  static const Color textPrimary        = Color(0xFFFFFFFF); // Main body text
  static const Color textSecondary      = Color(0xB3FFFFFF); // Subtitles (70% white)
  static const Color textTertiary       = Color(0x61FFFFFF); // Placeholders (38% white)
  static const Color textOnDark         = Color(0xFF0A0E17); // Text on bright neon buttons

  // === GRADIENTS ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF6B00FF)],
  );
  static const LinearGradient cyanToBlue = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF0080CC)],
  );
  static const LinearGradient purpleToPink = LinearGradient(
    colors: [Color(0xFF6B00FF), Color(0xFFFF00FF)],
  );
}
```

### 3.3 Typography

Font stack:
1. **Orbitron** -- Headlines, large numeric displays, goal titles, buttons. Futuristic geometric feel.
2. **ShareTechMono** -- Body text, descriptions, settings, metadata. Monospace techy feel.

```dart
// Headings -- GoogleFonts.orbitron()
// Body -- GoogleFonts.shareTechMono()
// Usage: GoogleFonts.orbitron(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 4)
// Usage: GoogleFonts.shareTechMono(fontSize: 13, color: Colors.white70)
```

### 3.4 ShaderMask Gradient Text

All major headings and the NEONCRED logo use `ShaderMask` with the primary gradient:

```dart
ShaderMask(
  shaderCallback: (bounds) => const LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF6B00FF)],
  ).createShader(bounds),
  child: Text(
    'NEONCRED',
    style: GoogleFonts.orbitron(
      color: Colors.white, // Required for ShaderMask
      fontSize: 24,
      fontWeight: FontWeight.w900,
      letterSpacing: 4,
    ),
  ),
)
```

### 3.5 Card Design

```dart
Container(
  decoration: BoxDecoration(
    color: Color(0xFF111827),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Color(0xFF00F0FF).withOpacity(0.15)),
    boxShadow: [
      BoxShadow(
        color: Color(0xFF00F0FF).withOpacity(0.04),
        blurRadius: 8,
      ),
    ],
  ),
)
```

---

## PART 4 -- CORE MECHANICS & BUSINESS LOGIC

### 4.1 Goal System

Users can create N goals (not limited to 2). Each goal has:
- **Name** (text)
- **Target Amount** (double, in selected currency)
- **Current Amount** (double, sum of deposits)
- **Saved Amount** (double, alternative tracking)
- **Target Date** (optional DateTime)
- **Is Completed** (boolean)
- **Category** (optional text)

### 4.2 Deposit Flow

A deposit consists of:
1. **Amount input** -- custom numeric keyboard
2. **Goal allocation** -- assign to specific goal
3. **Confirmation** -- summary before commit
4. **Success celebration** -- visual + haptic feedback
5. **Post-deposit state update** -- check for milestone unlocks, streak increment

### 4.3 Streak System

A **deposit streak** counts consecutive days with at least one deposit.
- Streak counter displayed on Dashboard
- Streak resets to 0 if a full calendar day passes with no deposit
- **Streak Milestones**: 3 days, 7 days, 14 days, 30 days, 60 days, 100 days

### 4.4 Achievement System

Achievements unlocked through actions. Categories:
- First Steps (first deposit, set goals, add note)
- Milestone (progress thresholds for each goal)
- Streak (streak milestone badges)
- Amount (deposit single amounts of 100/500/1000/5000 UAH)
- Dedication (10/25/50/100 total deposits)
- Special (birthday deposit, New Year deposit)

### 4.5 XP & Level System

- Users earn XP for deposits, streaks, and achievements
- Level = XP / (level * 500)
- Character classes: NetRunner, Hacker, CyberSamurai, etc.
- Each level unlocks new visual elements

### 4.6 Currency Support

Support UAH (primary), USD ($), EUR (EUR). Currency is an app-level setting.

---

## PART 5 -- FEATURE SPECIFICATIONS (47+ Features)

Each feature follows the pattern:
- **Cyberpunk Name** (displayed in feature grid)
- **Route** (GoRouter path)
- **Provider** (Riverpod state management)
- **Service** (business logic + AI integration)
- **Screen** (UI with cyberpunk theme)
- **Database Table** (Drift persistence)

---

### FEATURE 1: NecroSpend (Savings Graveyard)

**Route:** `/graveyard`
**Purpose:** Memorial for failed/abandoned goals with resurrection mechanics.

**UI Description:**
- Dark mausoleum-themed screen showing "dead" goals as gravestones
- Each gravestone shows: goal name, target amount, saved amount, death date, epitaph
- "Resurrect" button allows reviving a goal by making a deposit
- Necromancer mechanic: spend XP to bring back a goal
- Stats card: total goals died, total resurrected, resurrection success rate
- AI generates dramatic epitaphs for each dead goal

**Data:** `GraveyardEntries` table -- id, goalId, goalName, targetAmount, savedAmount, epitaph, deathDate, isResurrected, resurrectionDate, deathReason, necromancerUsed

---

### FEATURE 2: RetainCore (Anti-Churn Oracle)

**Route:** `/anti-churn`
**Purpose:** AI-powered churn prediction and rescue missions.

**UI Description:**
- Dashboard showing churn risk level (Low/Medium/High/Critical) with color-coded indicator
- Churn signals list: days since last deposit, streak broken, decreasing amounts
- AI-generated "Rescue Missions" -- personalized challenges to re-engage
- "Emergency Deposit" quick-action button with reduced minimum
- Motivation messages from AI based on behavioral patterns

**Data:** Churn analysis computed from `Users` and `Deposits` tables. No dedicated table -- uses real-time calculation.

---

### FEATURE 3: FutureMirror (Future Self)

**Route:** `/future-self`
**Purpose:** Visualization of future financial self based on current savings trajectory.

**UI Description:**
- Split-screen comparison: current state vs projected future state
- "If you continue at this pace" projections with timeline
- Visual avatar transformation showing improvement
- Savings milestone predictions with dates
- AI-generated motivational messages about future self
- "Fast-forward" slider to see different time horizons

**Data:** `FutureSelfVision` model computed from goal progress and deposit history.

---

### FEATURE 4: LootBox (Variable Reward Vault)

**Route:** `/variable-reward`
**Purpose:** Variable reward mechanics for deposits -- dopamine-driven engagement.

**UI Description:**
- Animated loot box that opens after deposits
- Jackpot tiers: Common (grey), Rare (cyan), Epic (purple), Legendary (gold), Mythic (red)
- Spin animation with neon particles
- Statistics: total boxes opened, best loot, jackpot streak
- Each deposit has a chance to trigger a jackpot (5% common, 2% rare, 0.5% epic, 0.1% legendary)
- Rewards: XP multipliers, streak freeze tokens, cosmetic items

**Data:** `VariableRewardState` managed by `VariableRewardVaultService`. Jackpot results stored in memory.

---

### FEATURE 5: BankLink (Bank Sync Oracle)

**Route:** `/bank-sync`
**Purpose:** Connect real bank accounts for automatic transaction import and round-up deposits.

**UI Description:**
- Bank provider selection: PrivatBank, Plaid (international)
- Connection status indicator with animated sync icon
- Transaction list categorized by type
- Round-up calculator: shows pending "change" from purchases
- Auto-save rules: round-up, income percentage, fixed weekly
- AI categorization of transactions
- "Sync Now" manual trigger button

**Data:** `BankSyncConfigs`, `AutoDeposits` tables. Mock banking provider for demo.

---

### FEATURE 6: RepForge (Reputation Forge)

**Route:** `/reputation-forge`
**Purpose:** Public commitment system with karma tracking.

**UI Description:**
- Reputation score display (0-100) with tier badges: Novice, Apprentice, Adept, Expert, Master, Legend
- Public commitments list with deadline countdowns
- "Make a Commitment" dialog with stake (XP/karma)
- Fulfillment rate percentage
- Circle reliability metric
- Karma contribution history
- AI-generated commitment suggestions

**Data:** `ReputationProfiles`, `PublicCommitments` tables.

---

### FEATURE 7: SwarmDrop (Flash Mob)

**Route:** `/flash-mob`
**Purpose:** Time-limited group savings events with multipliers.

**UI Description:**
- Active flash mob events with countdown timers
- Multiplier badge (1.5x, 2x, 3x)
- Participant count with animated counter
- "Join" button for active events
- Past events with results
- AI-generated event descriptions
- XP bonus for participation

**Data:** `FlashMobEvents` table.

---

### FEATURE 8: ParadoxCtrl (Choice Paradox)

**Route:** `/choice-paradox`
**Purpose:** Savings contracts with stakes to combat decision fatigue.

**UI Description:**
- Active contracts list with stakes and progress
- Contract types: "Weekly Deposit Target", "No-Spend Challenge", "Minimum Daily"
- Stake display: XP and karma at risk
- Progress bar toward contract fulfillment
- "Create Contract" dialog with customizable terms
- AI contract recommendations based on spending patterns

**Data:** `SavingsContracts` table.

---

### FEATURE 9: NudgeLab (Nudge Lab)

**Route:** `/nudge-lab`
**Purpose:** Behavioral economics experiments -- A/B testing persuasion techniques.

**UI Description:**
- Active experiments with variant labels (A/B)
- Impression and conversion counters
- Dominant nudge type identification
- Effectiveness scores radar chart
- "Start Experiment" dialog
- Persuasion profile summary
- Nudge types: loss_aversion, social_proof, anchoring, scarcity, gamification

**Data:** `NudgeExperiments`, `PersuasionProfiles` tables.

---

### FEATURE 10: HoloTrophies (3D Trophy Gallery)

**Route:** `/trophy-gallery`
**Purpose:** 3D achievement trophies with milestone tracking.

**UI Description:**
- Trophy grid with 3D model previews (Sketchfab integration)
- Trophy tiers: Common, Rare, Epic, Legendary, Mythic
- Each trophy shows: name, milestone amount, unlock date
- Unlocked vs locked states (locked = grayscale + padlock)
- "View in 3D" button for unlocked trophies
- Trophy stats: total, by tier, latest unlock
- AI-generated trophy descriptions

**Data:** `TrophyEntries` table. Sketchfab model IDs for 3D viewing.

---

### FEATURE 11: InfoScan (Financial News Radar)

**Route:** `/news-radar`
**Purpose:** AI-curated financial news with relevance scoring.

**UI Description:**
- News feed with relevance-scored articles
- Category badges: currency, crypto, economy, tech, retail
- Relevance score bar (0-100%)
- "Actionable" badge for news with concrete suggestions
- AI summary for each article
- Link to related goals
- Unread indicator

**Data:** `NewsInsights` table. AI-generated via OpenRouter.

---

### FEATURE 12: PriceOracle (Price Oracle)

**Route:** `/price-oracle`
**Purpose:** Price tracking and alert system for wishlist items.

**UI Description:**
- Watch list with current/previous/target prices
- Price change indicators (up/down arrows with color)
- "Add Item" dialog with search query
- Alert configuration: target price, notification type
- Price history chart
- Store name and last updated timestamp
- AI price prediction summary

**Data:** `PriceWatchItems` table. Price data via SERP API.

---

### FEATURE 13: ReceiptRip (Receipt Scanner)

**Route:** `/receipt-scanner`
**Purpose:** OCR receipt scanning with savings potential analysis.

**UI Description:**
- Camera/gallery import for receipt images
- OCR processing with merchant, amount, category extraction
- Savings potential badge
- AI motivation message per receipt
- Impulse buy detection indicator
- Weekly spending summary chart
- Category breakdown pie chart

**Data:** `ScannedReceipts` table. OCR via Mindee API.

---

### FEATURE 14: NeonPet (Cyber-Pet Companion)

**Route:** `/cyber-pet`
**Purpose:** Virtual cyberpunk pet that grows with savings.

**UI Description:**
- Pet selection screen: NeonCat, CircuitDog, DataDragon
- Pet display: 200x200 circle with pulse glow animation
- Dialogue bubble with AI-generated pet messages
- Stats bars: Health (0-100%), Happiness (0-100%)
- Evolution progress: Egg -> Baby -> Teen -> Adult -> Mega -> Ultra
- Action buttons: Pet (free), Talk (AI dialogue), Feed (100 UAH deposit)
- Accessories shop: buy with XP, unlock by evolution stage
- Pet stats card: days together, total feedings, streak days

**Data:** `CyberPets` table. AI dialogue via OpenRouter.

---

### FEATURE 15: BudgetHelix (Budget DNA Scanner)

**Route:** `/budget-dna`
**Purpose:** Budget category analysis with AI insights and economic indicators.

**UI Description:**
- Budget category list with monthly limits and spent amounts
- Category breach alerts with red indicators
- Monthly budget report card
- Economic indicators: USD/UAH rate, EUR/UAH rate, inflation rate
- AI analysis paragraph per month
- Savings rate percentage
- "Add Category" dialog
- DNA helix visualization of spending patterns

**Data:** `BudgetEntries`, `BudgetReports` tables.

---

### FEATURE 16: VoiceCrypt (Voice Vault)

**Route:** `/voice-vault`
**Purpose:** Voice command deposits -- hands-free savings.

**UI Description:**
- Microphone button with voice waveform animation
- Voice command recognition: "Zberihy 100 hryven" -> deposit 100 UAH
- Command history list
- Supported commands: deposit, check balance, check goal progress
- AI voice response text
- Error handling for unrecognized commands

**Data:** `VoiceCommands` table. ASR via z-ai-web-dev-sdk.

---

### FEATURE 17: FundSwarm (Crowd-Fund Wishes)

**Route:** `/crowd-fund`
**Purpose:** Crowdfunding wishlist for group gifts and shared goals.

**UI Description:**
- Active wishlists with progress bars
- Occasion badges: birthday, wedding, just_because
- Share code for inviting contributors
- Contribution list with messages
- "Create Wishlist" dialog
- Public/private toggle
- Thank-you sending mechanic

**Data:** `CrowdFundWishlists`, `CrowdFundContributions` tables.

---

### FEATURE 18: ARTag (AR Price Tag)

**Route:** `/ar-price-tag`
**Purpose:** AR-style price scanning with savings comparison.

**UI Description:**
- Scan history with product names and prices
- Savings potential per scan
- "Actionable" badge for items where saving makes sense
- Scan results with product image and price comparison
- Total savings across all scans

**Data:** `ARScanEntries` table.

---

### FEATURE 19: SynthWave (Deposit Soundscapes)

**Route:** `/soundscapes`
**Purpose:** Deposit sound effects collection -- unlock new sounds through achievements.

**UI Description:**
- Sound collection grid with unlock status
- Sound tiers: Common, Rare, Epic, Legendary
- Active sound indicator
- "Preview" button for each sound
- Unlock conditions tied to deposit milestones
- Custom sound assignment per goal

**Data:** `SoundUnlocks` table.

---

### FEATURE 20: PriceShark (Price Shark Tracker)

**Route:** `/price-shark`
**Purpose:** Deep price history tracking with fairness scoring.

**UI Description:**
- Tracked items with current/min/max prices over 90 days
- Fairness score gauge (0-100)
- "Is Fair Price" indicator
- Best store and best price display
- Price history line chart
- "Add Item" with search query
- AI price analysis

**Data:** `PriceSharkItems` table. Price data via SERP API.

---

### FEATURE 21: DropRoulette (Price Drop Roulette)

**Route:** `/price-roulette`
**Purpose:** Gamified price drop tracking with spin mechanics.

**UI Description:**
- Roulette items with current/initial/target prices
- Daily spins counter
- Drop chance percentage
- Jackpot won indicator
- "Spin" button with animation
- Deposit amount linked to price drop
- Progress toward target price

**Data:** `RouletteItems` table.

---

### FEATURE 22: MatchBlade (Price Match Ninja)

**Route:** `/price-match`
**Purpose:** Price match guarantee request generator.

**UI Description:**
- Price match requests with status badges: pending/sent/accepted/rejected
- Current store vs cheaper store comparison
- Match letter HTML preview
- Store policy information
- XP awarded for successful matches
- "Create Request" dialog with product and price details

**Data:** `PriceMatchRequests` table.

---

### FEATURE 23: PreGuard (Pre-Order Price Guard)

**Route:** `/preorder-guard`
**Purpose:** Pre-order price protection with depreciation forecasting.

**UI Description:**
- Guarded products with launch vs current vs predicted prices
- 6-month price prediction chart
- Recommendation badge: buy_now / wait_1m / wait_3m / wait_6m
- Predicted drop percentage
- AI analysis paragraph
- Active/inactive toggle
- Category selection

**Data:** `PreOrderGuards` table. AI predictions via OpenRouter.

---

### FEATURE 24: BonusCrunch (Store Loyalty Price Cruncher)

**Route:** `/loyalty-cruncher`
**Purpose:** Loyalty card optimizer with effective price calculation.

**UI Description:**
- Loyalty card list with store names and brand colors
- Cashback percentage display
- Current points and point values
- Effective price comparison (after cashback/points)
- Coupon code list with expiry dates
- "Add Card" dialog
- Store-specific price comparison

**Data:** `LoyaltyCards` table.

---

### FEATURE 25: FreezeRay (Price Freeze Challenge)

**Route:** `/price-freeze`
**Purpose:** Price freeze savings challenges -- save the difference.

**UI Description:**
- Active challenges with frozen vs current price
- Daily deposit amount tracker
- Days active counter
- Savings vs frozen price comparison
- Challenge progress bar
- "Start Challenge" dialog with product and frozen price
- Completion celebration

**Data:** `FreezeChallenges` table.

---

### FEATURE 26: WishScan (Wishlist Price Radar)

**Route:** `/wishlist-radar`
**Purpose:** AI-powered wishlist price monitoring with buy recommendations.

**UI Description:**
- Wishlist items with current/lowest/highest prices
- 7-day and 30-day price change indicators
- AI forecast badge: up / down / stable
- Forecast confidence percentage
- Urgency level: buy_now / soon / can_wait
- Best store recommendation
- Weekly buy guide

**Data:** `RadarWishItems` table. AI forecasts via OpenRouter.

---

### FEATURE 27: AlertCore (Smart Price Alerts+)

**Route:** `/smart-alerts`
**Purpose:** Advanced price alert system with AI context.

**UI Description:**
- Alert feed with urgency badges: urgent / soon / can_wait
- Alert types: price_drop, price_surge, best_time_buy, sale_ending, restock, black_friday
- Before/after price comparison
- Change percentage with color indicator
- AI context message per alert
- Sale end date countdown
- Alert subscription management
- "Create Alert" dialog

**Data:** `SmartAlertEntries`, `AlertSubscriptions` tables.

---

### FEATURE 28: PriceColosseum (Price Arena)

**Route:** `/price-arena`
**Purpose:** Price competition arena -- find the best price and earn XP.

**UI Description:**
- Active tournaments with reference prices
- Leaderboard showing best price submissions
- Submission form: product, price, store, URL
- Validation status indicator
- AI commentary on tournament
- Participant count
- XP rewards for valid submissions

**Data:** `ArenaTournaments`, `ArenaSubmissions` tables.

---

### FEATURE 29: PriceProphet (Price Prophet AI)

**Route:** `/price-prophet`
**Purpose:** AI-powered price forecasting with confidence intervals.

**UI Description:**
- Product forecasts with current price and 7d/30d predictions
- Three scenarios: Optimistic, Realistic, Pessimistic
- Confidence percentage gauge
- Trend indicator: up / down / stable
- Forecast accuracy tracker
- AI reasoning text
- Historical accuracy chart

**Data:** `PriceForecasts` table. AI via OpenRouter.

---

### FEATURE 30: ReGear (Second-Hand Price Analyzer)

**Route:** `/secondhand-analyzer`
**Purpose:** Used market price analysis with depreciation curves.

**UI Description:**
- Product cards with new vs used prices at 9/7/5 condition
- Depreciation percentage over 2 years
- Savings vs new price
- AI recommendation: buy_new / buy_used / wait
- Available listings count
- Market source attribution
- Price comparison chart

**Data:** `SecondHandItems` table.

---

### FEATURE 31: SeasonPulse (Seasonal Price Calendar)

**Route:** `/seasonal-calendar`
**Purpose:** Seasonal price event calendar with buying recommendations.

**UI Description:**
- Calendar view with price event markers
- Event cards: name, date range, average discount, categories
- AI tips per event
- Subscription management for reminders
- "Best time to buy" categories
- Upcoming events countdown

**Data:** `CalendarSubscriptions`, `PriceEvents` tables.

---

### FEATURE 32: Momentum (Price Momentum Tracker)

**Route:** `/price-momentum`
**Purpose:** Price momentum analysis with buy/sell signals.

**UI Description:**
- Tracked items with phase indicators: rising / peak / stable / falling
- Days stable counter
- Fall probability percentage
- Expected fall percentage
- Days until expected move
- Momentum signal text
- AI analysis paragraph
- Phase transition chart

**Data:** `MomentumItems` table.

---

### FEATURE 33: PriceWar (Price War Sentinel)

**Route:** `/price-war`
**Purpose:** Store price war detection and monitoring.

**UI Description:**
- Active price wars with intensity gauge
- Original vs best price comparison
- Savings percentage
- War day counter
- Recommendation: buy_now / watch_closely / wait / no_war
- AI commentary on war dynamics
- Price history during war

**Data:** `PriceWarEntries` table.

---

### FEATURE 34: HaggleAI (Haggling AI Coach)

**Route:** `/haggling-coach`
**Purpose:** AI-powered haggling coach with script generation.

**UI Description:**
- Active haggling sessions with store/target prices
- Best competitor price comparison
- Savings potential display
- Success rate indicator
- Session status: ready / won / lost
- AI coach tip per session
- Haggling script generator
- "Start Session" dialog

**Data:** `HagglingSessions` table. AI via OpenRouter.

---

### FEATURE 35: FlexPrice (Price Elasticity Explorer)

**Route:** `/price-elasticity`
**Purpose:** Price elasticity analysis with demand curve visualization.

**UI Description:**
- Product elasticity cards with coefficient display
- Elasticity type: elastic / inelastic / unit_elastic
- Optimal price calculation
- Price volatility gauge
- Best time to buy recommendation
- AI insight text
- Demand curve chart

**Data:** `ElasticityItems` table.

---

### FEATURE 36: StockGhost (Inventory Price Stalker)

**Route:** `/inventory-stalker`
**Purpose:** Inventory level monitoring with restock predictions.

**UI Description:**
- Tracked products with stock level indicators
- Price-stock correlation display
- Buy signal: high_stock_price_dropping / low_stock_wait_restock / moderate / no_clear_signal
- Drop probability percentage
- Days until restock estimate
- Predicted restock price
- AI alert text

**Data:** `InventoryStalkerItems` table.

---

### FEATURE 37: LoanTracker (Lending Tracker)

**Route:** `/lending-tracker`
**Purpose:** Track money lent to friends with overdue alerts.

**UI Description:**
- Lending records with debtor names and amounts
- Status badges: active / overdue / returned / archived
- Overdue records highlighted in red
- Days until due / days overdue counter
- "Add Loan" dialog with debtor, amount, due date
- Mark as returned action
- XP awarded for returned loans
- Record ID in LN-XXXXX format
- Total lent vs total returned stats

**Data:** `LendingRecords` table.

---

### FEATURE 38: GoalSync (Goal Price Integrator)

**Route:** `/goal-price-integrator`
**Purpose:** Link goals to real product prices with automatic target updates.

**UI Description:**
- Goal-product link cards
- Current product price vs goal target
- Price change impact on goal progress
- Auto-adjust target when price changes
- Link ID in GPI-XXXXX format
- "Create Link" dialog
- Stats: total links, auto-adjustments made, price alerts triggered

**Data:** `GoalProductLinks` table.

---

### FEATURE 39: HabitForge (Habit Loop Forge)

**Route:** `/habit-loop-forge`
**Purpose:** Build savings habits using the habit loop model (Cue-Routine-Reward).

**UI Description:**
- Habit list with cue, routine, and reward descriptions
- Habit streak tracker
- Completion rate percentage
- "Add Habit" dialog with customizable loop
- Daily check-in mechanic
- AI habit suggestions based on spending patterns
- Habit stats card

**Data:** `HabitLoops` table.

---

### FEATURE 40: InflaShield (Inflation Shield Alert)

**Route:** `/inflation-shield`
**Purpose:** Inflation impact tracking on savings goals.

**UI Description:**
- Shield cards with current inflation rate
- Impact on each goal's real value
- Recommended additional savings to counter inflation
- Historical inflation chart
- AI recommendations for inflation-proofing
- Active/inactive shield toggle
- Alert when inflation exceeds threshold

**Data:** `InflationShields` table.

---

### FEATURE 41: PriceEye (Price History Detective)

**Route:** `/price-detective`
**Purpose:** Deep price history analysis with pattern detection.

**UI Description:**
- Product cards with current and historical prices
- Price history line chart with multiple data points
- Pattern detection: seasonal, cyclical, trending
- Best historical price display
- Price volatility score
- AI analysis of price patterns
- "Investigate" dialog to add new product
- Stats: total investigations, patterns found, best savings

**Data:** `PriceHistoryEntries`, `PriceDetectiveItems` tables.

---

### FEATURE 42: LinkRip (Wishlist URL Scanner)

**Route:** `/wishlist-url-scanner`
**Purpose:** Scan product URLs from Ukrainian stores for price tracking.

**UI Description:**
- URL input field with paste button
- Supported stores list: Rozetka, Comfy, Citrus, Allo, Foxtrot, etc.
- Scanned products with current prices
- Price history per URL
- "Scan Now" button
- Auto-refresh schedule
- AI price comparison across stores

**Data:** `WishlistUrls` table. SERP API for price extraction.

---

### FEATURE 43: ShowroomShield (Showroom Price Shield)

**Route:** `/price-shield`
**Purpose:** In-store price comparison -- check if showroom price is fair.

**UI Description:**
- Scan results with product name and price
- Online vs in-store price comparison
- Savings potential if bought online
- "Is Fair Price" indicator
- Alternative store suggestions
- "Scan Price" manual input dialog
- Total savings from all scans

**Data:** `PriceShieldScans` table.

---

### FEATURE 44: ChronoSaver (Savings Time Machine)

**Route:** `/savings-time-machine`
**Purpose:** Project future savings with different scenarios.

**UI Description:**
- Current savings trajectory chart
- "What if" scenario sliders: increase deposit by X%, add lump sum, change frequency
- Projected goal completion dates
- Timeline visualization
- Comparison: current pace vs accelerated pace
- AI recommendations for reaching goals faster
- "Save projection" feature

**Data:** `TimeMachineProjections` table.

---

### FEATURE 45: QuestChain (Savings Quest Chain)

**Route:** `/quest-chain`
**Purpose:** Sequential savings quests with increasing difficulty and rewards.

**UI Description:**
- Quest chain progress with connected nodes
- Current quest highlighted
- Quest types: daily_deposit, reach_percentage, maintain_streak, no_spend_day, specific_amount
- Completion reward display (XP, badges)
- "Start Quest" button
- Chain completion celebration
- AI quest generation based on user behavior

**Data:** `QuestChains` table.

---

### FEATURE 46: SageAI (Predictive Savings Coach)

**Route:** `/predictive-coach`
**Purpose:** AI coach that predicts savings behavior and offers proactive advice.

**UI Description:**
- Prediction dashboard with confidence levels
- Prediction types: will_miss_deposit, will_break_streak, goal_at_risk, optimal_deposit_day
- Behavioral pattern analysis
- Proactive notifications
- AI coaching messages
- Prediction accuracy tracking
- "Ask Coach" chat interface

**Data:** `CoachPredictions` table. AI via OpenRouter.

---

### FEATURE 47: InflaWall (Anti-Inflation Shield Game)

**Route:** `/inflation-game`
**Purpose:** Gamified defense against inflation -- protect your savings.

**UI Description:**
- Wave-based game: inflation "attacks" your savings
- Defense mechanics: deposits build walls
- Wave difficulty increases over time
- Score based on savings preserved
- Leaderboard (local)
- Power-ups: streak shields, bonus deposits
- AI wave generation with real inflation data
- Visual: neon walls being attacked by red "inflation" particles

**Data:** `InflationWaves` table.

---

## PART 6 -- SCREEN SPECIFICATIONS

### 6.1 Dashboard (Home Screen)

**Layout (top to bottom):**

1. **Header:** NEONCRED logo (ShaderMask gradient), settings icon
2. **Profile Bar:** Avatar circle with initials, displayName, characterClass, Level, XP progress bar
3. **Streak Banner:** Fire icon + streak count, orange accent
4. **Goals Section:** "CILI" heading (ShaderMask), goal cards with progress bars
5. **Deposit Button:** Full-width cyan "VNESTY KOSHTY" button
6. **Quick Actions:** 3-column grid -- Features, Streak, Settings

**Goal Card:**
- Goal name (Orbitron)
- Gradient progress bar (cyan to purple)
- Current/Target amount (ShareTechMono)
- Percentage badge
- Completion badge (green)

### 6.2 Feature Grid (Home Shell)

**Layout:** 3-column GridView with 47 feature cards.

**Feature Card:**
- Dark background (0xFF111827)
- Cyan border (0.15 opacity)
- Feature name in ShaderMask gradient
- Tap navigates to feature route

### 6.3 Onboarding Flow

1. **Welcome Screen** -- NEONCRED logo, "START THE MISSION" button
2. **Goal Setup A** -- Set target for PS5 (cyan theme)
3. **Goal Setup B** -- Set target for Monitor (purple theme)
4. **Class Selection** -- NetRunner, Hacker, CyberSamurai
5. **Setup Finish** -- Celebration, "ENTER THE VAULT" button

---

## PART 7 -- TECHNICAL CONSTRAINTS

### 7.1 Flutter Compatibility
- Use `withOpacity()` NOT `withValues()` (Flutter 3.44 compatibility)
- Use `Color(0xFF...)` for all color constants
- All text in Ukrainian (UA)

### 7.2 No Emojis
- Zero emoji characters in any UI text
- Use Icons (Material) or custom painted symbols instead

### 7.3 Font Rules
- Headings: `GoogleFonts.orbitron()`
- Body: `GoogleFonts.shareTechMono()`
- All ShaderMask gradient text uses `color: Colors.white` as base

### 7.4 Build Configuration
- Android only (arm64-v8a)
- Package: `com.neoncred.neoncred`
- Signing: debug config for release builds
- No minification, no resource shrinking

### 7.5 API Integration Pattern
- All API calls through feature-specific Service classes
- AI features use `OpenRouterService` (z-ai-web-dev-sdk compatible)
- Price data via `SerpApiService`
- Bank data via mock provider (real API ready)
- Error handling: graceful fallback to cached/mock data

### 7.6 Data Persistence
- All data stored locally in Drift SQLite
- No cloud sync in v2.0 (Firebase ready for v3.0)
- `build_runner` required to generate `database.g.dart`
- SharedPreferences for onboarding flag

---

## PART 8 -- IMPLEMENTATION PRIORITY

| Priority | Features | Description |
|----------|----------|-------------|
| P0 (Critical) | Dashboard, Deposit, Goals, Streaks, Onboarding | Core app must work |
| P1 (High) | CyberPet, BudgetDNA, PriceOracle, ReceiptScanner, BankSync | Most-used AI features |
| P2 (Medium) | PriceShark, WishlistRadar, SmartAlerts, PriceProphet, NewsRadar | Price intelligence |
| P3 (Lower) | All remaining features | Extended functionality |

---

## PART 9 -- DASHBOARD SCREEN DETAIL

```
+-------------------------------------+
|  [Avatar] NEONCRED           [gear]  |  <- Header with ShaderMask logo
+-------------------------------------+
|  [ProfileBar: Name / Class / Lvl]   |  <- Glass card with XP bar
+-------------------------------------+
|  [Fire] Cepia: 12 dh. pidryad!      |  <- Streak Banner (orange)
+-------------------------------------+
|  CILI                                |  <- ShaderMask heading
|  +---------------------------------+ |
|  | PlayStation 5                   | |
|  | 12450 / 24999 UAH               | |
|  | [=========----] 49.8%           | |  <- Goal Card A (cyan gradient)
|  +---------------------------------+ |
|  +---------------------------------+ |
|  | Gaming Monitor                  | |
|  | 4200 / 14999 UAH               | |
|  | [===----------] 28.0%           | |  <- Goal Card B (purple gradient)
|  +---------------------------------+ |
+-------------------------------------+
|  [   VNESTY KOSHTY   ]              |  <- Big deposit button (cyan)
+-------------------------------------+
|  [Features] [Cepia] [Settings]      |  <- Quick actions row
+-------------------------------------+
```

---

*NEONCRED | Master Prompt Document | Version 2.0 | June 2026*
