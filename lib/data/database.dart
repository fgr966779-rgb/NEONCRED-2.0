import 'dart:io';

import 'package:drift/drift.dart';
export 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/config/env_provider.dart';

part 'database.g.dart';

// =============================================================================
// Core Tables
// =============================================================================

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firebaseUid => text().withDefault(const Constant(''))();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get characterClass => text().nullable()();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get karma => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastDepositAt => dateTime().nullable()();
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastPushInteractionAt => dateTime().nullable()();
  DateTimeColumn get lastAppOpenAt => dateTime().nullable()();
  DateTimeColumn get lastLendingXPDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(0))();
  TextColumn get name => text()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  RealColumn get targetAmount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get targetDate => dateTime().nullable()();
  DateTimeColumn get lastDepositAt => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get category => text().nullable()();
}

class Deposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  RealColumn get amount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Graveyard (#1)
// =============================================================================

class GraveyardEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  TextColumn get goalName => text()();
  RealColumn get targetAmount => real()();
  RealColumn get savedAmount => real().withDefault(const Constant(0.0))();
  TextColumn get epitaph => text().nullable()();
  DateTimeColumn get deathDate => dateTime()();
  BoolColumn get isResurrected => boolean().withDefault(const Constant(false))();
  DateTimeColumn get resurrectionDate => dateTime().nullable()();
  TextColumn get sketchfabModelId => text().nullable()();
  TextColumn get deathReason => text().nullable()();
  BoolColumn get necromancerUsed => boolean().withDefault(const Constant(false))();
}

// =============================================================================
// Feature Tables — Reputation Forge (#6)
// =============================================================================

class ReputationProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  RealColumn get reputationScore => real().withDefault(const Constant(50.0))();
  IntColumn get publicCommitmentsCount => integer().withDefault(const Constant(0))();
  IntColumn get fulfilledCommitmentsCount => integer().withDefault(const Constant(0))();
  RealColumn get circleReliability => real().withDefault(const Constant(0.0))();
  RealColumn get karmaContribution => real().withDefault(const Constant(0.0))();
  TextColumn get title => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class PublicCommitments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  IntColumn get goalId => integer()();
  TextColumn get commitmentText => text()();
  DateTimeColumn get deadlineDate => dateTime()();
  BoolColumn get isFulfilled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get stakeKarma => integer().withDefault(const Constant(0))();
}

// =============================================================================
// Feature Tables — Flash Mob (#7)
// =============================================================================

class FlashMobEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text()();
  TextColumn get titleUA => text()();
  TextColumn get descriptionUA => text()();
  RealColumn get multiplier => real().withDefault(const Constant(1.5))();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  IntColumn get participantCount => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  BoolColumn get isJoined => boolean().withDefault(const Constant(false))();
}

// =============================================================================
// Feature Tables — Choice Paradox (#8)
// =============================================================================

class SavingsContracts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get contractType => text()();
  TextColumn get conditionText => text()();
  IntColumn get stakeKarma => integer().withDefault(const Constant(0))();
  IntColumn get stakeXP => integer().withDefault(const Constant(0))();
  RealColumn get weeklyDepositTarget => real()();
  RealColumn get actualDeposits => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isFulfilled => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()();
}

// =============================================================================
// Feature Tables — Nudge Lab (#10)
// =============================================================================

class NudgeExperiments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get nudgeType => text()();
  TextColumn get variant => text().withDefault(const Constant('A'))();
  IntColumn get impressions => integer().withDefault(const Constant(0))();
  IntColumn get conversions => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class PersuasionProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get dominantNudgeType => text().withDefault(const Constant('loss_aversion'))();
  TextColumn get effectivenessScores => text().withDefault(const Constant('{}'))();
  IntColumn get totalExperiments => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Bank Sync Oracle (#5)
// =============================================================================

class BankSyncConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get provider => text()(); // 'privatbank' | 'plaid'
  TextColumn get accessToken => text()();
  TextColumn get refreshToken => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get accountMask => text().nullable()(); // last 4 digits
  DateTimeColumn get connectedAt => dateTime().withDefault(currentDateAndTime)();
}

class AutoDeposits extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  RealColumn get amount => real()();
  TextColumn get source => text().withDefault(const Constant('manual'))(); // 'bank_sync_round_up', 'bank_sync_income_pct', 'manual'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — 3D Trophy Gallery (#7)
// =============================================================================

class TrophyEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get trophyId => text()(); // e.g. 'neon_seed'
  TextColumn get name => text()(); // e.g. 'Neon Seed'
  TextColumn get tier => text()(); // 'common' | 'rare' | 'epic' | 'legendary' | 'mythic'
  TextColumn get sketchfabModelId => text().nullable()();
  RealColumn get milestoneAmount => real().withDefault(const Constant(0.0))();
  TextColumn get achievementTag => text().nullable()();
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Financial News Radar (#8)
// =============================================================================

class NewsInsights extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get insightId => text()();
  TextColumn get headline => text()();
  TextColumn get summary => text()();
  RealColumn get relevanceScore => real().withDefault(const Constant(0.5))();
  TextColumn get source => text().withDefault(const Constant('web'))();
  TextColumn get category => text()(); // 'currency' | 'crypto' | etc.
  IntColumn get relatedGoalId => integer().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  BoolColumn get isActionable => boolean().withDefault(const Constant(false))();
  TextColumn get actionSuggestion => text().nullable()();
  DateTimeColumn get publishedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price Oracle (#1)
// =============================================================================

class PriceWatchItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get name => text()();
  TextColumn get searchQuery => text()();
  RealColumn get currentPriceUah => real().withDefault(const Constant(0.0))();
  RealColumn get previousPriceUah => real().withDefault(const Constant(0.0))();
  RealColumn get targetPriceUah => real().withDefault(const Constant(0.0))();
  IntColumn get goalId => integer().nullable()();
  TextColumn get currency => text().withDefault(const Constant('UAH'))();
  TextColumn get imageUrl => text().withDefault(const Constant(''))();
  TextColumn get storeName => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Receipt Scanner (#3)
// =============================================================================

class ScannedReceipts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get receiptId => text()();
  TextColumn get merchantName => text()();
  RealColumn get totalAmount => real()();
  TextColumn get currency => text().withDefault(const Constant('UAH'))();
  TextColumn get category => text().withDefault(const Constant('other'))();
  DateTimeColumn get purchaseDate => dateTime().withDefault(currentDateAndTime)();
  RealColumn get savingsPotential => real().withDefault(const Constant(0.0))();
  TextColumn get motivationMessage => text().nullable()();
  IntColumn get goalId => integer().nullable()();
  BoolColumn get isImpulseBuy => boolean().withDefault(const Constant(false))();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get ocrSource => text().withDefault(const Constant('manual'))();
}

// =============================================================================
// Feature Tables — Cyber-Pet Companion (#4)
// =============================================================================

class CyberPets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get petId => text()();
  TextColumn get species => text()(); // 'neon_cat' | 'circuit_dog' | 'data_dragon'
  TextColumn get name => text()();
  RealColumn get health => real().withDefault(const Constant(100.0))();
  RealColumn get happiness => real().withDefault(const Constant(80.0))();
  IntColumn get petXp => integer().withDefault(const Constant(0))();
  TextColumn get evolution => text().withDefault(const Constant('egg'))();
  DateTimeColumn get lastFedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastPetAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get totalFeedings => integer().withDefault(const Constant(0))();
  IntColumn get totalPettings => integer().withDefault(const Constant(0))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  TextColumn get equippedAccessories => text().withDefault(const Constant(''))();
}

// =============================================================================
// Feature Tables — Budget DNA Scanner (#10)
// =============================================================================

class BudgetEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get monthlyLimit => real()();
  RealColumn get spent => real().withDefault(const Constant(0.0))();
  DateTimeColumn get month => dateTime()();
}

class BudgetReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get month => dateTime()();
  RealColumn get totalIncome => real().withDefault(const Constant(0.0))();
  RealColumn get totalSpent => real().withDefault(const Constant(0.0))();
  RealColumn get totalSaved => real().withDefault(const Constant(0.0))();
  RealColumn get savingsRate => real().withDefault(const Constant(0.0))();
  TextColumn get aiAnalysis => text().withDefault(const Constant(''))();
  RealColumn get usdUahRate => real().withDefault(const Constant(41.5))();
  RealColumn get eurUahRate => real().withDefault(const Constant(45.0))();
  RealColumn get inflationRate => real().withDefault(const Constant(7.5))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Voice Vault (#2)
// =============================================================================

class VoiceCommands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get commandType => text()();
  TextColumn get originalText => text()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get goalName => text().withDefault(const Constant(''))();
  TextColumn get responseText => text().withDefault(const Constant(''))();
  DateTimeColumn get executedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Crowd-Fund Wishes (#3)
// =============================================================================

class CrowdFundWishlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get wishListId => text()();
  IntColumn get goalId => integer()();
  TextColumn get goalName => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  TextColumn get occasion => text().withDefault(const Constant('just_because'))();
  TextColumn get shareCode => text().withDefault(const Constant(''))();
  BoolColumn get isPublic => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime().nullable()();
}

class CrowdFundContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get contributionId => text()();
  IntColumn get wishListDbId => integer()();
  TextColumn get contributorName => text()();
  TextColumn get contributorAvatar => text().withDefault(const Constant(''))();
  RealColumn get amount => real()();
  TextColumn get message => text().withDefault(const Constant(''))();
  BoolColumn get thankYouSent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — AR Price Tag (#7)
// =============================================================================

class ARScanEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get scanId => text()();
  TextColumn get productName => text()();
  RealColumn get priceUah => real().withDefault(const Constant(0.0))();
  RealColumn get savingsUah => real().withDefault(const Constant(0.0))();
  BoolColumn get isActionable => boolean().withDefault(const Constant(false))();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Deposit Soundscapes (#8)
// =============================================================================

class SoundUnlocks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get soundId => text()();
  TextColumn get soundName => text()();
  TextColumn get tier => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price Shark Tracker (#1 Round 3)
// =============================================================================

class PriceSharkItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get name => text()();
  TextColumn get searchQuery => text()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get minPrice90d => real().withDefault(const Constant(0.0))();
  RealColumn get maxPrice90d => real().withDefault(const Constant(0.0))();
  RealColumn get targetPrice => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('UAH'))();
  TextColumn get bestStore => text().withDefault(const Constant(''))();
  RealColumn get bestStorePrice => real().withDefault(const Constant(0.0))();
  RealColumn get fairnessScore => real().withDefault(const Constant(50.0))();
  BoolColumn get isFairPrice => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price Drop Roulette (#2 Round 3)
// =============================================================================

class RouletteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get productName => text()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get initialPrice => real().withDefault(const Constant(0.0))();
  RealColumn get targetPrice => real().withDefault(const Constant(0.0))();
  RealColumn get depositAmount => real().withDefault(const Constant(0.0))();
  IntColumn get totalDeposits => integer().withDefault(const Constant(0))();
  IntColumn get dailySpins => integer().withDefault(const Constant(0))();
  RealColumn get dropChance => real().withDefault(const Constant(5.0))();
  BoolColumn get jackpotWon => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSpunAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price Match Ninja (#4 Round 3)
// =============================================================================

class PriceMatchRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get requestId => text()();
  TextColumn get productName => text()();
  RealColumn get currentPrice => real()();
  TextColumn get currentStore => text()();
  RealColumn get cheaperPrice => real().withDefault(const Constant(0.0))();
  TextColumn get cheaperStore => text().withDefault(const Constant(''))();
  TextColumn get matchLetterHtml => text().withDefault(const Constant(''))();
  TextColumn get storePolicy => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending/sent/accepted/rejected
  DateTimeColumn get responseDate => dateTime().nullable()();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Pre-Order Price Guard (#5 Round 3)
// =============================================================================

class PreOrderGuards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get guardId => text()();
  TextColumn get productName => text()();
  TextColumn get category => text().withDefault(const Constant('phone'))();
  RealColumn get launchPrice => real()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get predictedPrice6m => real().withDefault(const Constant(0.0))();
  RealColumn get predictedDropPercent => real().withDefault(const Constant(0.0))();
  TextColumn get recommendation => text().withDefault(const Constant('wait_3m'))(); // buy_now/wait_1m/wait_3m/wait_6m
  TextColumn get aiAnalysis => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Store Loyalty Price Cruncher (#6 Round 3)
// =============================================================================

class LoyaltyCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get cardId => text()();
  TextColumn get storeName => text()();
  TextColumn get cardNumber => text().withDefault(const Constant(''))();
  RealColumn get cashbackPercent => real().withDefault(const Constant(0.0))();
  RealColumn get currentPoints => real().withDefault(const Constant(0.0))();
  RealColumn get pointsValue => real().withDefault(const Constant(0.01))();
  TextColumn get brandColor => text().withDefault(const Constant('#00F0FF'))();
}

// =============================================================================
// Feature Tables — Price Freeze Challenge (#7 Round 3)
// =============================================================================

class FreezeChallenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get challengeId => text()();
  TextColumn get productName => text()();
  RealColumn get frozenPrice => real()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get dailyDepositAmount => real().withDefault(const Constant(0.0))();
  RealColumn get totalSaved => real().withDefault(const Constant(0.0))();
  IntColumn get daysActive => integer().withDefault(const Constant(0))();
  RealColumn get savingsVsFrozen => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Wish-List Price Radar (#8 Round 3)
// =============================================================================

class RadarWishItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get name => text()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get lowestPrice => real().withDefault(const Constant(0.0))();
  RealColumn get highestPrice => real().withDefault(const Constant(0.0))();
  RealColumn get priceChange7d => real().withDefault(const Constant(0.0))();
  RealColumn get priceChange30d => real().withDefault(const Constant(0.0))();
  TextColumn get aiForecast => text().withDefault(const Constant('stable'))(); // up/down/stable
  RealColumn get forecastConfidence => real().withDefault(const Constant(50.0))();
  TextColumn get urgency => text().withDefault(const Constant('can_wait'))(); // buy_now/soon/can_wait
  TextColumn get bestStore => text().withDefault(const Constant(''))();
  RealColumn get bestStorePrice => real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastScanned => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Smart Price Alerts+ (#9 Round 3)
// =============================================================================

class SmartAlertEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get alertId => text()();
  TextColumn get productName => text()();
  TextColumn get alertType => text()(); // price_drop/price_surge/best_time_buy/sale_ending/restock/black_friday
  RealColumn get priceBefore => real().withDefault(const Constant(0.0))();
  RealColumn get priceAfter => real().withDefault(const Constant(0.0))();
  RealColumn get changePercent => real().withDefault(const Constant(0.0))();
  TextColumn get aiContext => text().withDefault(const Constant(''))();
  TextColumn get urgency => text().withDefault(const Constant('can_wait'))(); // urgent/soon/can_wait
  TextColumn get store => text().withDefault(const Constant(''))();
  TextColumn get saleEndDate => text().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AlertSubscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subscriptionId => text()();
  TextColumn get productName => text()();
  RealColumn get targetPrice => real()();
  TextColumn get alertTypes => text().withDefault(const Constant('price_drop'))(); // comma-separated
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// =============================================================================
// Feature Tables — Price Arena (#10 Round 3)
// =============================================================================

class ArenaTournaments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tournamentId => text()();
  TextColumn get productName => text()();
  TextColumn get productCategory => text().withDefault(const Constant('electronics'))();
  RealColumn get referencePrice => real()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get participantCount => integer().withDefault(const Constant(0))();
  TextColumn get aiCommentary => text().withDefault(const Constant(''))();
}

class ArenaSubmissions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get submissionId => text()();
  IntColumn get tournamentDbId => integer()();
  TextColumn get userId => text().withDefault(const Constant(''))();
  TextColumn get userName => text().withDefault(const Constant(''))();
  RealColumn get submittedPrice => real()();
  TextColumn get storeName => text()();
  TextColumn get storeUrl => text().withDefault(const Constant(''))();
  BoolColumn get isValid => boolean().withDefault(const Constant(false))();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get submittedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price Prophet AI (#1 Round 4)
// =============================================================================

class PriceForecasts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get forecastId => text()();
  TextColumn get productName => text()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get optimisticPrice30d => real().withDefault(const Constant(0.0))();
  RealColumn get realisticPrice30d => real().withDefault(const Constant(0.0))();
  RealColumn get pessimisticPrice30d => real().withDefault(const Constant(0.0))();
  RealColumn get optimisticPrice7d => real().withDefault(const Constant(0.0))();
  RealColumn get realisticPrice7d => real().withDefault(const Constant(0.0))();
  RealColumn get pessimisticPrice7d => real().withDefault(const Constant(0.0))();
  RealColumn get confidencePercent => real().withDefault(const Constant(50.0))();
  TextColumn get trend => text().withDefault(const Constant('stable'))(); // up/down/stable
  RealColumn get forecastAccuracy => real().withDefault(const Constant(0.0))();
  IntColumn get totalForecastsMade => integer().withDefault(const Constant(0))();
  TextColumn get forecastReasoning => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Second-Hand Price Analyzer (#2 Round 4)
// =============================================================================

class SecondHandItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get productName => text()();
  RealColumn get newPrice => real().withDefault(const Constant(0.0))();
  RealColumn get usedPrice9 => real().withDefault(const Constant(0.0))();
  RealColumn get usedPrice7 => real().withDefault(const Constant(0.0))();
  RealColumn get usedPrice5 => real().withDefault(const Constant(0.0))();
  RealColumn get depreciationPercent2y => real().withDefault(const Constant(0.0))();
  RealColumn get savingsVsNew => real().withDefault(const Constant(0.0))();
  TextColumn get aiRecommendation => text().withDefault(const Constant(''))();
  TextColumn get marketSource => text().withDefault(const Constant(''))();
  IntColumn get availableListings => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastScanned => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Seasonal Price Calendar (#4 Round 4)
// =============================================================================

class CalendarSubscriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subscriptionId => text()();
  TextColumn get productName => text()();
  RealColumn get targetPrice => real()();
  IntColumn get reminderDaysBefore => integer().withDefault(const Constant(3))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

class PriceEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text()();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  RealColumn get averageDiscount => real().withDefault(const Constant(0.0))();
  TextColumn get categories => text().withDefault(const Constant(''))();
  TextColumn get aiTip => text().withDefault(const Constant(''))();
}

// =============================================================================
// Feature Tables — Price Momentum Tracker (#10 Round 4)
// =============================================================================

class MomentumItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get productName => text()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get previousPrice => real().withDefault(const Constant(0.0))();
  IntColumn get daysStable => integer().withDefault(const Constant(0))();
  TextColumn get phase => text().withDefault(const Constant('stable'))(); // rising/peak/stable/falling
  RealColumn get fallProbability => real().withDefault(const Constant(0.0))();
  RealColumn get expectedFallPercent => real().withDefault(const Constant(0.0))();
  IntColumn get daysUntilExpectedMove => integer().withDefault(const Constant(0))();
  TextColumn get momentumSignal => text().withDefault(const Constant(''))();
  TextColumn get aiAnalysis => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price War Sentinel (#4 Round 5)
// =============================================================================

class PriceWarEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get warId => text()();
  TextColumn get productName => text()();
  RealColumn get originalPrice => real().withDefault(const Constant(0.0))();
  RealColumn get bestPrice => real().withDefault(const Constant(0.0))();
  RealColumn get savingsPercent => real().withDefault(const Constant(0.0))();
  TextColumn get recommendation => text().withDefault(const Constant('no_war'))(); // buy_now/watch_closely/wait/no_war
  RealColumn get warIntensity => real().withDefault(const Constant(0.0))();
  IntColumn get warDay => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get aiCommentary => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Haggling AI Coach (#8 Round 5)
// =============================================================================

class HagglingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text()();
  TextColumn get productName => text()();
  RealColumn get storePrice => real().withDefault(const Constant(0.0))();
  RealColumn get targetPrice => real().withDefault(const Constant(0.0))();
  RealColumn get bestCompetitorPrice => real().withDefault(const Constant(0.0))();
  RealColumn get savingsPotential => real().withDefault(const Constant(0.0))();
  TextColumn get successRate => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('ready'))(); // ready/won/lost
  TextColumn get aiCoachTip => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price Elasticity Explorer (#9 Round 5)
// =============================================================================

class ElasticityItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get productName => text()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get elasticityCoefficient => real().withDefault(const Constant(1.0))();
  TextColumn get elasticityType => text().withDefault(const Constant('unit_elastic'))(); // elastic/inelastic/unit_elastic
  RealColumn get optimalPrice => real().withDefault(const Constant(0.0))();
  RealColumn get priceVolatility => real().withDefault(const Constant(0.0))();
  TextColumn get bestTimeToBuy => text().withDefault(const Constant(''))();
  TextColumn get aiInsight => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Inventory Price Stalker (#10 Round 5)
// =============================================================================

class InventoryStalkerItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()();
  TextColumn get productName => text()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  RealColumn get avgStockLevel => real().withDefault(const Constant(0.0))();
  RealColumn get priceStockCorrelation => real().withDefault(const Constant(0.0))();
  TextColumn get buySignal => text().withDefault(const Constant('no_clear_signal'))(); // high_stock_price_dropping/low_stock_wait_restock/moderate/no_clear
  RealColumn get dropProbability => real().withDefault(const Constant(0.0))();
  IntColumn get daysUntilRestock => integer().withDefault(const Constant(0))();
  RealColumn get predictedRestockPrice => real().withDefault(const Constant(0.0))();
  TextColumn get aiAlert => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Lending Tracker (#6 Round 6)
// =============================================================================

class LendingRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recordId => text()(); // LN-XXXXX format
  TextColumn get debtorName => text()();
  RealColumn get amountUah => real()();
  DateTimeColumn get lentAt => dateTime()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active/overdue/returned/archived
  TextColumn get note => text().nullable()();
  DateTimeColumn get returnedAt => dateTime().nullable()();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Goal Price Integrator (#1 Round 7)
// =============================================================================

class GoalProductLinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get linkId => text()(); // GPI-XXXXX
  IntColumn get goalId => integer()();
  TextColumn get productName => text()();
  TextColumn get searchQuery => text()();
  RealColumn get targetPriceUah => real().withDefault(const Constant(0.0))();
  RealColumn get bestPriceUah => real().withDefault(const Constant(0.0))();
  TextColumn get bestStoreName => text().withDefault(const Constant(''))();
  TextColumn get bestStoreUrl => text().withDefault(const Constant(''))();
  RealColumn get remainingUah => real().withDefault(const Constant(0.0))();
  BoolColumn get priceBelowTarget => boolean().withDefault(const Constant(false))();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastChecked => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Habit Loop Forge (#5 Round 7)
// =============================================================================

class HabitLoops extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get habitId => text()(); // HL-XXXXX
  TextColumn get name => text()();
  RealColumn get dailyAmountUah => real()();
  TextColumn get trigger => text().withDefault(const Constant(''))(); // e.g. 'before_coffee'
  IntColumn get currentDay => integer().withDefault(const Constant(0))();
  IntColumn get targetDays => integer().withDefault(const Constant(21))();
  IntColumn get streakDays => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  RealColumn get totalSavedUah => real().withDefault(const Constant(0.0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isCompleted21 => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastCheckIn => dateTime().nullable()();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Inflation Shield Alert (#8 Round 7)
// =============================================================================

class InflationShields extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get shieldId => text()(); // IS-XXXXX
  RealColumn get usdUahRate => real().withDefault(const Constant(41.5))();
  RealColumn get eurUahRate => real().withDefault(const Constant(45.0))();
  RealColumn get inflationRate => real().withDefault(const Constant(8.0))();
  RealColumn get totalSavingsUah => real().withDefault(const Constant(0.0))();
  RealColumn get realValueLossUah => real().withDefault(const Constant(0.0))();
  RealColumn get suggestedTopUpUah => real().withDefault(const Constant(0.0))();
  TextColumn get aiAdvice => text().withDefault(const Constant(''))();
  BoolColumn get isAlertActive => boolean().withDefault(const Constant(false))();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Price History Detective (#10 Round 7)
// =============================================================================

class PriceHistoryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entryId => text()(); // PHD-XXXXX
  TextColumn get productName => text()();
  TextColumn get storeName => text()();
  RealColumn get priceUah => real()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
}

class PriceDetectiveItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get itemId => text()(); // DET-XXXXX
  TextColumn get productName => text()();
  TextColumn get searchQuery => text()();
  RealColumn get currentPriceUah => real().withDefault(const Constant(0.0))();
  RealColumn get minPrice30d => real().withDefault(const Constant(0.0))();
  RealColumn get minPrice90d => real().withDefault(const Constant(0.0))();
  RealColumn get minPrice180d => real().withDefault(const Constant(0.0))();
  IntColumn get daysSinceMin => integer().withDefault(const Constant(0))();
  TextColumn get signal => text().withDefault(const Constant('wait'))(); // buy_now/wait/price_dropping
  TextColumn get aiAnalysis => text().withDefault(const Constant(''))();
  IntColumn get goalId => integer().nullable()();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Smart Price Alert v2 (LTV 2026-2030 Phase 1)
// =============================================================================

class PriceAlerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  TextColumn get productQuery => text()();
  RealColumn get targetPrice => real()();
  RealColumn get currentPrice => real().withDefault(const Constant(0.0))();
  BoolColumn get isTriggered => boolean().withDefault(const Constant(false))();
  BoolColumn get isNotifying => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Wishlist URL Scanner (#1 LTV Phase 2)
// =============================================================================

class WishlistUrls extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  TextColumn get url => text()();
  TextColumn get storeName => text().withDefault(const Constant(''))();
  TextColumn get productName => text().withDefault(const Constant(''))();
  RealColumn get extractedPrice => real().withDefault(const Constant(0.0))();
  DateTimeColumn get lastScannedAt => dateTime().nullable()();
}

// =============================================================================
// Feature Tables — Showroom Price Shield (#8 LTV Phase 2)
// =============================================================================

class PriceShieldScans extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId => integer().withDefault(const Constant(0))();
  TextColumn get productName => text()();
  RealColumn get inStorePrice => real()();
  RealColumn get bestOnlinePrice => real().withDefault(const Constant(0.0))();
  TextColumn get bestOnlineStore => text().withDefault(const Constant(''))();
  RealColumn get savingsUah => real().withDefault(const Constant(0.0))();
  BoolColumn get priceMatchUsed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get scannedAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Savings Time Machine (#10 LTV Phase 2)
// =============================================================================

class TimeMachineProjections extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer()();
  RealColumn get monthlyDeposit => real()();
  DateTimeColumn get projectedDate => dateTime().nullable()();
  RealColumn get projectedSavings => real().withDefault(const Constant(0.0))();
  RealColumn get projectedPrice => real().withDefault(const Constant(0.0))();
  RealColumn get priceDropPercent => real().withDefault(const Constant(0.0))();
  RealColumn get confidenceScore => real().withDefault(const Constant(50.0))();
  TextColumn get aiAnalysis => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUpdatedAt => dateTime().nullable()();
}

// =============================================================================
// Feature Tables — Savings Quest Chain (#1 Retention 2026)
// =============================================================================

class QuestChains extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get chainId => text()(); // QC-XXXXX
  TextColumn get questName => text()();
  TextColumn get questType => text()(); // daily_deposit/price_scan/receipt_scan/weekly_savings/no_spend_day
  RealColumn get targetValue => real().withDefault(const Constant(0.0))();
  RealColumn get currentValue => real().withDefault(const Constant(0.0))();
  IntColumn get chainPosition => integer().withDefault(const Constant(1))(); // 1-5 in chain
  IntColumn get chainLength => integer().withDefault(const Constant(5))();
  IntColumn get completedInChain => integer().withDefault(const Constant(0))();
  RealColumn get xpMultiplier => real().withDefault(const Constant(1.0))(); // x1, x1.5, x2 for streaks
  IntColumn get xpReward => integer().withDefault(const Constant(5))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isFailed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get expiresAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Predictive Savings Coach (#6 Retention 2026)
// =============================================================================

class CoachPredictions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get predictionId => text()(); // CP-XXXXX
  TextColumn get predictionType => text()(); // danger_window/no_spend_risk/streak_threat/overspend_alert
  DateTimeColumn get dangerDate => dateTime()(); // predicted dangerous day
  RealColumn get confidenceScore => real().withDefault(const Constant(50.0))();
  TextColumn get aiRecommendation => text().withDefault(const Constant(''))();
  RealColumn get suggestedDepositAmount => real().withDefault(const Constant(0.0))();
  BoolColumn get isNudgeSent => boolean().withDefault(const Constant(false))();
  BoolColumn get isUserActed => boolean().withDefault(const Constant(false))();
  IntColumn get xpAwarded => integer().withDefault(const Constant(0))();
  DateTimeColumn get predictedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Feature Tables — Anti-Inflation Shield Game (#10 Retention 2026)
// =============================================================================

class InflationWaves extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get waveId => text()(); // IW-XXXXX
  RealColumn get inflationRate => real().withDefault(const Constant(7.5))(); // NBU actual %
  RealColumn get wallStrength => real().withDefault(const Constant(0.0))(); // total deposits this month
  RealColumn get wallDamage => real().withDefault(const Constant(0.0))(); // inflation erosion amount
  BoolColumn get wallHeld => boolean().withDefault(const Constant(false))();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  IntColumn get consecutiveWallsHeld => integer().withDefault(const Constant(0))(); // streak
  TextColumn get monthLabel => text().withDefault(const Constant(''))(); // e.g. 'Червень 2026'
  DateTimeColumn get waveStartAt => dateTime()();
  DateTimeColumn get waveEndAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// =============================================================================
// Drift Database
// =============================================================================

@DriftDatabase(
  tables: [
    Users,
    Goals,
    Deposits,
    GraveyardEntries,
    ReputationProfiles,
    PublicCommitments,
    FlashMobEvents,
    SavingsContracts,
    NudgeExperiments,
    PersuasionProfiles,
    BankSyncConfigs,
    AutoDeposits,
    TrophyEntries,
    NewsInsights,
    PriceWatchItems,
    ScannedReceipts,
    CyberPets,
    BudgetEntries,
    BudgetReports,
    VoiceCommands,
    CrowdFundWishlists,
    CrowdFundContributions,
    ARScanEntries,
    SoundUnlocks,
    PriceSharkItems,
    RouletteItems,
    PriceMatchRequests,
    PreOrderGuards,
    LoyaltyCards,
    FreezeChallenges,
    RadarWishItems,
    SmartAlertEntries,
    AlertSubscriptions,
    ArenaTournaments,
    ArenaSubmissions,
    PriceForecasts,
    SecondHandItems,
    CalendarSubscriptions,
    PriceEvents,
    MomentumItems,
    PriceWarEntries,
    HagglingSessions,
    ElasticityItems,
    InventoryStalkerItems,
    LendingRecords,
    GoalProductLinks,
    HabitLoops,
    InflationShields,
    PriceHistoryEntries,
    PriceDetectiveItems,
    PriceAlerts,
    WishlistUrls,
    PriceShieldScans,
    TimeMachineProjections,
    QuestChains,
    CoachPredictions,
    InflationWaves,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 30;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Safe incremental migration: create tables that don't exist yet.
          // Drift's createAll() is safe on upgrade — it only creates missing
          // tables and does NOT drop existing ones with data.
          if (from < 20) {
            await m.createAll();
          }
          if (from < 21) {
            // v21: BankSyncConfigs, AutoDeposits, TrophyEntries, NewsInsights
            await m.createAll();
          }
          if (from < 22) {
            // v22: PriceWatchItems, ScannedReceipts, CyberPets,
            //      BudgetEntries, BudgetReports, VoiceCommands,
            //      CrowdFundWishlists, CrowdFundContributions,
            //      ARScanEntries, SoundUnlocks
            await m.createAll();
          }
          if (from < 23) {
            // v23: PriceSharkItems, RouletteItems, PriceMatchRequests,
            //      PreOrderGuards, LoyaltyCards, FreezeChallenges,
            //      RadarWishItems, SmartAlertEntries, AlertSubscriptions,
            //      ArenaTournaments, ArenaSubmissions
            await m.createAll();
          }
          if (from < 24) {
            // v24: PriceForecasts, SecondHandItems,
            //      CalendarSubscriptions, PriceEvents, MomentumItems
            await m.createAll();
          }
          if (from < 25) {
            // v25: PriceWarEntries, HagglingSessions,
            //      ElasticityItems, InventoryStalkerItems
            await m.createAll();
          }
          if (from < 26) {
            // v26: LendingRecords table + lastLendingXPDate column on Users
            await m.addColumn(users, users.lastLendingXPDate);
            await m.createAll();
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_lending_records_status ON lending_records (status)',
            );
          }
          if (from < 27) {
            // v27: GoalProductLinks, HabitLoops, InflationShields,
            //      PriceHistoryEntries, PriceDetectiveItems
            await m.createAll();
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_price_history_product ON price_history_entries (productName)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_price_detective_product ON price_detective_items (productName)',
            );
          }
          if (from < 28) {
            // v28: PriceAlerts table (Smart Price Alert v2 — LTV Phase 1)
            await m.createAll();
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_price_alerts_triggered ON price_alerts (isTriggered)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_price_alerts_last_checked ON price_alerts (lastCheckedAt)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_price_alerts_goal_id ON price_alerts (goalId)',
            );
            // CASCADE: delete orphaned alerts when parent goal is deleted
            await customStatement(
              'CREATE TRIGGER IF NOT EXISTS fk_price_alerts_goal_cascade '
              'AFTER DELETE ON goals BEGIN '
              'DELETE FROM price_alerts WHERE goalId = OLD.id; '
              'END',
            );
          }
          if (from < 29) {
            // v29: WishlistUrls, PriceShieldScans, TimeMachineProjections
            //      (LTV Phase 2 — URL Scanner, Price Shield, Time Machine)
            await m.createAll();
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_wishlist_urls_goal_id ON wishlist_urls (goalId)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_price_shield_scans_user_id ON price_shield_scans (userId)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_time_machine_projections_goal_id ON time_machine_projections (goalId)',
            );
            // CASCADE: delete orphaned wishlist URLs when parent goal is deleted
            await customStatement(
              'CREATE TRIGGER IF NOT EXISTS fk_wishlist_urls_goal_cascade '
              'AFTER DELETE ON goals BEGIN '
              'DELETE FROM wishlist_urls WHERE goalId = OLD.id; '
              'END',
            );
            // CASCADE: delete orphaned time machine projections when parent goal is deleted
            await customStatement(
              'CREATE TRIGGER IF NOT EXISTS fk_time_machine_projections_goal_cascade '
              'AFTER DELETE ON goals BEGIN '
              'DELETE FROM time_machine_projections WHERE goalId = OLD.id; '
              'END',
            );
          }
          if (from < 30) {
            // v30: QuestChains, CoachPredictions, InflationWaves
            //      (Retention 2026 — Quest Chain, Predictive Coach, Inflation Game)
            await m.createAll();
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_quest_chains_chain_id ON quest_chains (chainId)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_quest_chains_type ON quest_chains (questType)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_coach_predictions_type ON coach_predictions (predictionType)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_coach_predictions_danger_date ON coach_predictions (dangerDate)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_inflation_waves_wave_id ON inflation_waves (waveId)',
            );
          }
        },
      );

  // ===========================================================================
  // Accessors — shorthand for tables
  // ===========================================================================

  // (Generated accessors are available as `users`, `goals`, `deposits`, etc.)

  // ===========================================================================
  // Core queries — User (profile), Goals, Deposits
  // ===========================================================================

  /// Returns the first user profile or null if no users exist.
  Future<User?> getUserProfile() async {
    final list = await (select(users)..limit(1)).get();
    return list.isNotEmpty ? list.first : null;
  }

  /// Returns all goals.
  Future<List<Goal>> getAllGoals() {
    return select(goals).get();
  }

  /// Returns all deposits.
  Future<List<Deposit>> getAllDeposits() {
    return select(deposits).get();
  }

  // ===========================================================================
  // User CRUD
  // ===========================================================================

  Future<void> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  Future<void> updateUser(int id, UsersCompanion user) {
    return (update(users)..where((t) => t.id.equals(id))).write(user);
  }

  Future<void> deleteUser(int id) {
    return (delete(users)..where((t) => t.id.equals(id))).go();
  }

  // ===========================================================================
  // Goal CRUD
  // ===========================================================================

  Future<void> insertGoal(GoalsCompanion goal) {
    return into(goals).insert(goal);
  }

  Future<void> updateGoal(int id, GoalsCompanion goal) {
    return (update(goals)..where((t) => t.id.equals(id))).write(goal);
  }

  Future<void> deleteGoal(int id) {
    return (delete(goals)..where((t) => t.id.equals(id))).go();
  }

  Future<Goal?> getGoalById(int id) async {
    final query = select(goals)..where((t) => t.id.equals(id))..limit(1);
    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Goal>> getGoalsByUserId(int userId) {
    return (select(goals)..where((t) => t.userId.equals(userId))).get();
  }

  Future<List<Goal>> getActiveGoals() {
    return (select(goals)..where((t) => t.isCompleted.equals(false))).get();
  }

  // ===========================================================================
  // Deposit CRUD
  // ===========================================================================

  Future<void> insertDeposit(DepositsCompanion deposit) {
    return into(deposits).insert(deposit);
  }

  Future<void> deleteDeposit(int id) {
    return (delete(deposits)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Deposit>> getDepositsByGoalId(int goalId) {
    return (select(deposits)..where((t) => t.goalId.equals(goalId))).get();
  }

  // ===========================================================================
  // Price Alert queries (Smart Price Alert v2 — LTV Phase 1)
  // ===========================================================================

  Future<List<PriceAlert>> getAllPriceAlerts() {
    return select(priceAlerts).get();
  }

  Future<List<PriceAlert>> getActivePriceAlerts() {
    return (select(priceAlerts)..where((t) => t.isTriggered.equals(false))).get();
  }

  Future<PriceAlert?> getPriceAlertById(int id) async {
    final query = select(priceAlerts)..where((t) => t.id.equals(id))..limit(1);
    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<PriceAlert>> getPriceAlertsByGoalId(int goalId) {
    return (select(priceAlerts)..where((t) => t.goalId.equals(goalId))).get();
  }

  Future<void> insertPriceAlert(PriceAlertsCompanion alert) {
    return into(priceAlerts).insert(alert);
  }

  Future<void> updatePriceAlert(int id, PriceAlertsCompanion alert) {
    return (update(priceAlerts)..where((t) => t.id.equals(id))).write(alert);
  }

  Future<void> deletePriceAlert(int id) {
    return (delete(priceAlerts)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deletePriceAlertsByGoalId(int goalId) {
    return (delete(priceAlerts)..where((t) => t.goalId.equals(goalId))).go();
  }

  // ===========================================================================
  // Wishlist URL queries (Wishlist URL Scanner — LTV Phase 2)
  // ===========================================================================

  Future<List<WishlistUrl>> getAllWishlistUrls() {
    return select(wishlistUrls).get();
  }

  Future<List<WishlistUrl>> getWishlistUrlsByGoalId(int goalId) {
    return (select(wishlistUrls)..where((t) => t.goalId.equals(goalId))).get();
  }

  Future<void> insertWishlistUrl(WishlistUrlsCompanion entry) {
    return into(wishlistUrls).insert(entry);
  }

  Future<void> updateWishlistUrl(int id, WishlistUrlsCompanion entry) {
    return (update(wishlistUrls)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteWishlistUrl(int id) {
    return (delete(wishlistUrls)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteWishlistUrlsByGoalId(int goalId) {
    return (delete(wishlistUrls)..where((t) => t.goalId.equals(goalId))).go();
  }

  // ===========================================================================
  // Price Shield Scan queries (Showroom Price Shield — LTV Phase 2)
  // ===========================================================================

  Future<List<PriceShieldScan>> getAllPriceShieldScans() {
    return select(priceShieldScans).get();
  }

  Future<List<PriceShieldScan>> getPriceShieldScansByUserId(int userId) {
    return (select(priceShieldScans)..where((t) => t.userId.equals(userId))).get();
  }

  Future<void> insertPriceShieldScan(PriceShieldScansCompanion entry) {
    return into(priceShieldScans).insert(entry);
  }

  Future<void> updatePriceShieldScan(int id, PriceShieldScansCompanion entry) {
    return (update(priceShieldScans)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deletePriceShieldScan(int id) {
    return (delete(priceShieldScans)..where((t) => t.id.equals(id))).go();
  }

  // ===========================================================================
  // Time Machine Projection queries (Savings Time Machine — LTV Phase 2)
  // ===========================================================================

  Future<List<TimeMachineProjection>> getAllTimeMachineProjections() {
    return select(timeMachineProjections).get();
  }

  Future<TimeMachineProjection?> getTimeMachineProjectionByGoalId(int goalId) async {
    final query = select(timeMachineProjections)
      ..where((t) => t.goalId.equals(goalId))
      ..limit(1);
    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insertTimeMachineProjection(TimeMachineProjectionsCompanion entry) {
    return into(timeMachineProjections).insert(entry);
  }

  Future<void> updateTimeMachineProjection(int id, TimeMachineProjectionsCompanion entry) {
    return (update(timeMachineProjections)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteTimeMachineProjection(int id) {
    return (delete(timeMachineProjections)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteTimeMachineProjectionsByGoalId(int goalId) {
    return (delete(timeMachineProjections)..where((t) => t.goalId.equals(goalId))).go();
  }

  // ===========================================================================
  // Quest Chain queries (Savings Quest Chain — Retention 2026)
  // ===========================================================================

  Future<List<QuestChain>> getAllQuestChains() {
    return select(questChains).get();
  }

  Future<List<QuestChain>> getActiveQuestChains() {
    return (select(questChains)
          ..where((t) => t.isCompleted.equals(false) & t.isFailed.equals(false)))
        .get();
  }

  Future<List<QuestChain>> getQuestChainsByChainId(String chainId) {
    return (select(questChains)..where((t) => t.chainId.equals(chainId))).get();
  }

  Future<void> insertQuestChain(QuestChainsCompanion entry) {
    return into(questChains).insert(entry);
  }

  Future<void> updateQuestChain(int id, QuestChainsCompanion entry) {
    return (update(questChains)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteQuestChain(int id) {
    return (delete(questChains)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteExpiredQuestChains() {
    return (delete(questChains)..where((t) => t.expiresAt.isSmallerThanValue(DateTime.now()))).go();
  }

  // ===========================================================================
  // Coach Prediction queries (Predictive Savings Coach — Retention 2026)
  // ===========================================================================

  Future<List<CoachPrediction>> getAllCoachPredictions() {
    return select(coachPredictions).get();
  }

  Future<List<CoachPrediction>> getActiveCoachPredictions() {
    return (select(coachPredictions)..where((t) => t.isUserActed.equals(false))).get();
  }

  Future<List<CoachPrediction>> getUpcomingDangerWindows() {
    final now = DateTime.now();
    return (select(coachPredictions)
          ..where((t) => t.dangerDate.isBiggerOrEqualValue(now) & t.isUserActed.equals(false)))
        .get();
  }

  Future<void> insertCoachPrediction(CoachPredictionsCompanion entry) {
    return into(coachPredictions).insert(entry);
  }

  Future<void> updateCoachPrediction(int id, CoachPredictionsCompanion entry) {
    return (update(coachPredictions)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteCoachPrediction(int id) {
    return (delete(coachPredictions)..where((t) => t.id.equals(id))).go();
  }

  // ===========================================================================
  // Inflation Wave queries (Anti-Inflation Shield Game — Retention 2026)
  // ===========================================================================

  Future<List<InflationWave>> getAllInflationWaves() {
    return select(inflationWaves).get();
  }

  Future<InflationWave?> getActiveInflationWave() async {
    final now = DateTime.now();
    final query = select(inflationWaves)
      ..where((t) => t.waveEndAt.isNull() | t.waveEndAt.isBiggerOrEqualValue(now))
      ..limit(1);
    final results = await query.get();
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> insertInflationWave(InflationWavesCompanion entry) {
    return into(inflationWaves).insert(entry);
  }

  Future<void> updateInflationWave(int id, InflationWavesCompanion entry) {
    return (update(inflationWaves)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteInflationWave(int id) {
    return (delete(inflationWaves)..where((t) => t.id.equals(id))).go();
  }

  /// Adds XP to the current user profile wrapped in a transaction.
  /// [source] is logged for analytics (e.g., 'habit_check_in', 'price_detective').
  /// Reads the latest profile inside the transaction to prevent lost-update
  /// when multiple addXP() calls happen concurrently.
  Future<void> addXP(int amount, {String source = 'unknown'}) async {
    if (amount <= 0) return;

    await transaction(() async {
      final list = await (select(users)..limit(1)).get();
      if (list.isEmpty) return;
      final profile = list.first;

      final newXp = profile.xp + amount;
      final newLevel = (newXp / 500).floor() + 1; // 500 XP per level

      await (update(users)..where((t) => t.id.equals(profile.id))).write(
        UsersCompanion(
          xp: Value(newXp),
          level: Value(newLevel),
        ),
      );
    });
  }

  // ===========================================================================
  // Graveyard queries
  // ===========================================================================

  Future<List<GraveyardEntry>> getAllGraveyardEntries() {
    return select(graveyardEntries).get();
  }

  Future<void> insertGraveyardEntry(GraveyardEntriesCompanion entry) {
    return into(graveyardEntries).insert(entry);
  }

  Future<void> updateGraveyardEntry(GraveyardEntry entry) {
    return update(graveyardEntries).replace(entry);
  }

  // ===========================================================================
  // Reputation queries
  // ===========================================================================

  Future<ReputationProfile?> getReputationProfile(String userId) async {
    final query = select(reputationProfiles)
      ..where((t) => t.userId.equals(userId));
    final list = await (query..limit(1)).get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> insertReputationProfile(ReputationProfilesCompanion profile) {
    return into(reputationProfiles).insert(profile);
  }

  Future<void> updateReputationProfile(ReputationProfile profile) {
    return update(reputationProfiles).replace(profile);
  }

  Future<List<PublicCommitment>> getActiveCommitments(String userId) {
    final query = select(publicCommitments)
      ..where((t) => t.userId.equals(userId) & t.isFulfilled.equals(false));
    return query.get();
  }

  Future<void> insertCommitment(PublicCommitmentsCompanion commitment) {
    return into(publicCommitments).insert(commitment);
  }

  Future<void> updateCommitment(PublicCommitment commitment) {
    return update(publicCommitments).replace(commitment);
  }

  // ===========================================================================
  // Flash Mob queries
  // ===========================================================================

  Future<List<FlashMobEvent>> getActiveFlashMobEvents() {
    final query = select(flashMobEvents)
      ..where((t) => t.isActive.equals(true));
    return query.get();
  }

  Future<List<FlashMobEvent>> getAllFlashMobEvents() {
    return select(flashMobEvents).get();
  }

  Future<void> insertFlashMobEvent(FlashMobEventsCompanion event) {
    return into(flashMobEvents).insert(event);
  }

  Future<void> updateFlashMobEvent(FlashMobEvent event) {
    return update(flashMobEvents).replace(event);
  }

  // ===========================================================================
  // Savings Contracts queries
  // ===========================================================================

  Future<List<SavingsContract>> getActiveContracts(String userId) {
    final query = select(savingsContracts)
      ..where((t) => t.userId.equals(userId) & t.isActive.equals(true));
    return query.get();
  }

  Future<void> insertContract(SavingsContractsCompanion contract) {
    return into(savingsContracts).insert(contract);
  }

  Future<void> updateContract(SavingsContract contract) {
    return update(savingsContracts).replace(contract);
  }

  // ===========================================================================
  // Nudge Lab queries
  // ===========================================================================

  Future<List<NudgeExperiment>> getExperiments(String userId) {
    final query = select(nudgeExperiments)
      ..where((t) => t.userId.equals(userId));
    return query.get();
  }

  Future<void> insertExperiment(NudgeExperimentsCompanion experiment) {
    return into(nudgeExperiments).insert(experiment);
  }

  Future<void> updateExperiment(NudgeExperiment experiment) {
    return update(nudgeExperiments).replace(experiment);
  }

  Future<PersuasionProfile?> getPersuasionProfile(String userId) async {
    final query = select(persuasionProfiles)
      ..where((t) => t.userId.equals(userId));
    final list = await (query..limit(1)).get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> insertPersuasionProfile(PersuasionProfilesCompanion profile) {
    return into(persuasionProfiles).insert(profile);
  }

  Future<void> updatePersuasionProfile(PersuasionProfile profile) {
    return update(persuasionProfiles).replace(profile);
  }

  // ===========================================================================
  // Bank Sync queries
  // ===========================================================================

  Future<List<BankSyncConfig>> getAllBankSyncConfigs() {
    return select(bankSyncConfigs).get();
  }

  Future<void> insertBankSyncConfig(BankSyncConfigsCompanion config) {
    return into(bankSyncConfigs).insert(config);
  }

  Future<void> deleteBankSyncConfig(BankSyncConfig config) {
    return delete(bankSyncConfigs).delete(config);
  }

  Future<void> insertAutoDeposit(AutoDepositsCompanion deposit) {
    return into(autoDeposits).insert(deposit);
  }

  Future<List<AutoDeposit>> getAutoDepositsForGoal(int goalId) {
    final query = select(autoDeposits)
      ..where((t) => t.goalId.equals(goalId));
    return query.get();
  }

  // ===========================================================================
  // Trophy Gallery queries
  // ===========================================================================

  Future<List<TrophyEntry>> getAllTrophyEntries() {
    return select(trophyEntries).get();
  }

  Future<void> insertTrophyEntry(TrophyEntriesCompanion entry) {
    return into(trophyEntries).insert(entry);
  }

  Future<bool> isTrophyUnlocked(String trophyId) async {
    final query = select(trophyEntries)
      ..where((t) => t.trophyId.equals(trophyId))
      ..limit(1);
    final results = await query.get();
    return results.isNotEmpty;
  }

  // ===========================================================================
  // News Radar queries
  // ===========================================================================

  Future<List<NewsInsight>> getAllNewsInsights() {
    return select(newsInsights).get();
  }

  Future<void> insertNewsInsight(NewsInsightsCompanion insight) {
    return into(newsInsights).insert(insight);
  }

  Future<void> markNewsInsightRead(int id) async {
    await (update(newsInsights)..where((t) => t.id.equals(id))).write(
      const NewsInsightsCompanion(isRead: Value(true)),
    );
  }

  // ===========================================================================
  // Price Oracle queries
  // ===========================================================================

  Future<List<PriceWatchItem>> getAllPriceWatchItems() {
    return select(priceWatchItems).get();
  }

  Future<void> insertPriceWatchItem(PriceWatchItemsCompanion item) {
    return into(priceWatchItems).insert(item);
  }

  Future<void> updatePriceWatchItem(int id, PriceWatchItemsCompanion item) {
    return (update(priceWatchItems)..where((t) => t.id.equals(id))).write(item);
  }

  Future<int> getPriceWatchItemId(String itemId) async {
    final query = select(priceWatchItems)
      ..where((t) => t.itemId.equals(itemId))
      ..limit(1);
    final results = await query.get();
    return results.isNotEmpty ? results.first.id : -1;
  }

  Future<void> deletePriceWatchItemByItemId(String itemId) {
    return (delete(priceWatchItems)
          ..where((t) => t.itemId.equals(itemId)))
        .go();
  }

  // ===========================================================================
  // Receipt Scanner queries
  // ===========================================================================

  Future<List<ScannedReceipt>> getAllScannedReceipts() {
    return select(scannedReceipts).get();
  }

  Future<void> insertScannedReceipt(ScannedReceiptsCompanion receipt) {
    return into(scannedReceipts).insert(receipt);
  }

  Future<void> deleteScannedReceipt(String receiptId) {
    return (delete(scannedReceipts)
          ..where((t) => t.receiptId.equals(receiptId)))
        .go();
  }

  // ===========================================================================
  // Cyber-Pet queries
  // ===========================================================================

  Future<List<CyberPet>> getAllCyberPets() {
    return select(cyberPets).get();
  }

  Future<void> insertCyberPet(CyberPetsCompanion pet) {
    return into(cyberPets).insert(pet);
  }

  Future<void> updateCyberPet(int id, CyberPetsCompanion pet) {
    return (update(cyberPets)..where((t) => t.id.equals(id))).write(pet);
  }

  Future<int> getCyberPetDbId(String petId) async {
    final query = select(cyberPets)
      ..where((t) => t.petId.equals(petId))
      ..limit(1);
    final results = await query.get();
    return results.isNotEmpty ? results.first.id : -1;
  }

  // ===========================================================================
  // Budget DNA queries
  // ===========================================================================

  Future<List<BudgetEntry>> getAllBudgetEntries() {
    return select(budgetEntries).get();
  }

  Future<void> insertBudgetEntry(BudgetEntriesCompanion entry) {
    return into(budgetEntries).insert(entry);
  }

  Future<void> updateBudgetEntryCategory(
    String category,
    double monthlyLimit,
    DateTime month,
  ) async {
    final query = select(budgetEntries)
      ..where((t) => t.category.equals(category) & t.month.equals(month));
    final results = await query.get();
    for (final row in results) {
      await update(budgetEntries).replace(
        row.copyWith(monthlyLimit: monthlyLimit),
      );
    }
  }

  Future<void> addBudgetSpending(
    String category,
    double amount,
    DateTime month,
  ) async {
    final query = select(budgetEntries)
      ..where((t) => t.category.equals(category) & t.month.equals(month));
    final results = await query.get();
    for (final row in results) {
      await update(budgetEntries).replace(
        row.copyWith(spent: row.spent + amount),
      );
    }
  }

  Future<void> insertBudgetReport(BudgetReportsCompanion report) {
    return into(budgetReports).insert(report);
  }

  // ===========================================================================
  // Voice Vault queries
  // ===========================================================================

  Future<void> insertVoiceCommand(VoiceCommandsCompanion command) {
    return into(voiceCommands).insert(command);
  }

  // ===========================================================================
  // Crowd-Fund queries
  // ===========================================================================

  Future<List<CrowdFundWishlist>> getAllCrowdFundWishlists() {
    return select(crowdFundWishlists).get();
  }

  Future<void> insertCrowdFundWishlist(CrowdFundWishlistsCompanion wishlist) {
    return into(crowdFundWishlists).insert(wishlist);
  }

  Future<void> updateCrowdFundWishlist(CrowdFundWishlist wishlist) {
    return update(crowdFundWishlists).replace(wishlist);
  }

  Future<List<CrowdFundContribution>> getCrowdFundContributions(
    int wishListDbId,
  ) {
    final query = select(crowdFundContributions)
      ..where((t) => t.wishListDbId.equals(wishListDbId));
    return query.get();
  }

  Future<void> insertCrowdFundContribution(
    CrowdFundContributionsCompanion contribution,
  ) {
    return into(crowdFundContributions).insert(contribution);
  }

  // ===========================================================================
  // AR Price Tag queries
  // ===========================================================================

  Future<void> insertARScanEntry(ARScanEntriesCompanion scan) {
    return into(aRScanEntries).insert(scan);
  }

  Future<List<ARScanEntry>> getAllARScanEntries() {
    return select(aRScanEntries).get();
  }

  // ===========================================================================
  // Soundscapes queries
  // ===========================================================================

  Future<List<SoundUnlock>> getAllSoundUnlocks() {
    return select(soundUnlocks).get();
  }

  Future<void> insertSoundUnlock(SoundUnlocksCompanion sound) {
    return into(soundUnlocks).insert(sound);
  }

  // ===========================================================================
  // Price Shark queries
  // ===========================================================================

  Future<List<PriceSharkItem>> getAllPriceSharkItems() {
    return select(priceSharkItems).get();
  }

  Future<void> insertPriceSharkItem(PriceSharkItemsCompanion item) {
    return into(priceSharkItems).insert(item);
  }

  Future<void> deletePriceSharkItem(String itemId) {
    return (delete(priceSharkItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  // ===========================================================================
  // Price Roulette queries
  // ===========================================================================

  Future<List<RouletteItem>> getAllRouletteItems() {
    return select(rouletteItems).get();
  }

  Future<void> insertRouletteItem(RouletteItemsCompanion item) {
    return into(rouletteItems).insert(item);
  }

  Future<void> updateRouletteItem(RouletteItem item) {
    return update(rouletteItems).replace(item);
  }

  // ===========================================================================
  // Price Match queries
  // ===========================================================================

  Future<List<PriceMatchRequest>> getAllPriceMatchRequests() {
    return select(priceMatchRequests).get();
  }

  Future<void> insertPriceMatchRequest(PriceMatchRequestsCompanion request) {
    return into(priceMatchRequests).insert(request);
  }

  Future<void> updatePriceMatchRequest(PriceMatchRequest request) {
    return update(priceMatchRequests).replace(request);
  }

  // ===========================================================================
  // Pre-Order Guard queries
  // ===========================================================================

  Future<List<PreOrderGuard>> getAllPreOrderGuards() {
    return select(preOrderGuards).get();
  }

  Future<void> insertPreOrderGuard(PreOrderGuardsCompanion guard) {
    return into(preOrderGuards).insert(guard);
  }

  Future<void> updatePreOrderGuard(PreOrderGuard guard) {
    return update(preOrderGuards).replace(guard);
  }

  Future<void> deletePreOrderGuard(String guardId) {
    return (delete(preOrderGuards)..where((t) => t.guardId.equals(guardId))).go();
  }

  // ===========================================================================
  // Loyalty Card queries
  // ===========================================================================

  Future<List<LoyaltyCard>> getAllLoyaltyCards() {
    return select(loyaltyCards).get();
  }

  Future<void> insertLoyaltyCard(LoyaltyCardsCompanion card) {
    return into(loyaltyCards).insert(card);
  }

  Future<void> deleteLoyaltyCard(String cardId) {
    return (delete(loyaltyCards)..where((t) => t.cardId.equals(cardId))).go();
  }

  // ===========================================================================
  // Price Freeze queries
  // ===========================================================================

  Future<List<FreezeChallenge>> getAllFreezeChallenges() {
    return select(freezeChallenges).get();
  }

  Future<void> insertFreezeChallenge(FreezeChallengesCompanion challenge) {
    return into(freezeChallenges).insert(challenge);
  }

  Future<void> updateFreezeChallenge(FreezeChallenge challenge) {
    return update(freezeChallenges).replace(challenge);
  }

  // ===========================================================================
  // Wish-List Radar queries
  // ===========================================================================

  Future<List<RadarWishItem>> getAllRadarWishItems() {
    return select(radarWishItems).get();
  }

  Future<void> insertRadarWishItem(RadarWishItemsCompanion item) {
    return into(radarWishItems).insert(item);
  }

  Future<void> deleteRadarWishItem(String itemId) {
    return (delete(radarWishItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  // ===========================================================================
  // Smart Alerts queries
  // ===========================================================================

  Future<List<SmartAlertEntry>> getAllSmartAlerts() {
    return select(smartAlertEntries).get();
  }

  Future<void> insertSmartAlert(SmartAlertEntriesCompanion alert) {
    return into(smartAlertEntries).insert(alert);
  }

  Future<void> markSmartAlertRead(int id) async {
    final query = select(smartAlertEntries)..where((t) => t.id.equals(id));
    final results = await query.get();
    for (final row in results) {
      await update(smartAlertEntries).replace(row.copyWith(isRead: true));
    }
  }

  Future<List<AlertSubscription>> getAllAlertSubscriptions() {
    return select(alertSubscriptions).get();
  }

  Future<void> insertAlertSubscription(AlertSubscriptionsCompanion sub) {
    return into(alertSubscriptions).insert(sub);
  }

  Future<void> deleteAlertSubscription(String subscriptionId) {
    return (delete(alertSubscriptions)
          ..where((t) => t.subscriptionId.equals(subscriptionId)))
        .go();
  }

  // ===========================================================================
  // Price Arena queries
  // ===========================================================================

  Future<List<ArenaTournament>> getAllArenaTournaments() {
    return select(arenaTournaments).get();
  }

  Future<void> insertArenaTournament(ArenaTournamentsCompanion tournament) {
    return into(arenaTournaments).insert(tournament);
  }

  Future<void> updateArenaTournament(ArenaTournament tournament) {
    return update(arenaTournaments).replace(tournament);
  }

  Future<List<ArenaSubmission>> getArenaSubmissions(int tournamentDbId) {
    final query = select(arenaSubmissions)
      ..where((t) => t.tournamentDbId.equals(tournamentDbId));
    return query.get();
  }

  Future<void> insertArenaSubmission(ArenaSubmissionsCompanion submission) {
    return into(arenaSubmissions).insert(submission);
  }

  // ===========================================================================
  // Price Prophet queries
  // ===========================================================================

  Future<List<PriceForecast>> getAllPriceForecasts() {
    return select(priceForecasts).get();
  }

  Future<void> insertPriceForecast(PriceForecastsCompanion forecast) {
    return into(priceForecasts).insert(forecast);
  }

  Future<void> deletePriceForecast(String forecastId) {
    return (delete(priceForecasts)..where((t) => t.forecastId.equals(forecastId))).go();
  }

  // ===========================================================================
  // Second-Hand Analyzer queries
  // ===========================================================================

  Future<List<SecondHandItem>> getAllSecondHandItems() {
    return select(secondHandItems).get();
  }

  Future<void> insertSecondHandItem(SecondHandItemsCompanion item) {
    return into(secondHandItems).insert(item);
  }

  Future<void> deleteSecondHandItem(String itemId) {
    return (delete(secondHandItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  // ===========================================================================
  // Seasonal Calendar queries
  // ===========================================================================

  Future<List<CalendarSubscription>> getAllCalendarSubscriptions() {
    return select(calendarSubscriptions).get();
  }

  Future<void> insertCalendarSubscription(CalendarSubscriptionsCompanion sub) {
    return into(calendarSubscriptions).insert(sub);
  }

  Future<void> deleteCalendarSubscription(String subscriptionId) {
    return (delete(calendarSubscriptions)
          ..where((t) => t.subscriptionId.equals(subscriptionId)))
        .go();
  }

  Future<List<PriceEvent>> getAllPriceEvents() {
    return select(priceEvents).get();
  }

  Future<void> insertPriceEvent(PriceEventsCompanion event) {
    return into(priceEvents).insert(event);
  }

  // ===========================================================================
  // Price Momentum queries
  // ===========================================================================

  Future<List<MomentumItem>> getAllMomentumItems() {
    return select(momentumItems).get();
  }

  Future<void> insertMomentumItem(MomentumItemsCompanion item) {
    return into(momentumItems).insert(item);
  }

  Future<void> updateMomentumItem(MomentumItem item) {
    return update(momentumItems).replace(item);
  }

  Future<void> deleteMomentumItem(String itemId) {
    return (delete(momentumItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  // ===========================================================================
  // Price War Sentinel queries (Round 5)
  // ===========================================================================

  Future<List<PriceWarEntry>> getAllPriceWarEntries() {
    return select(priceWarEntries).get();
  }

  Future<void> insertPriceWarEntry(PriceWarEntriesCompanion entry) {
    return into(priceWarEntries).insert(entry);
  }

  Future<void> updatePriceWarEntry(PriceWarEntry entry) {
    return update(priceWarEntries).replace(entry);
  }

  Future<void> deletePriceWarEntry(String warId) {
    return (delete(priceWarEntries)..where((t) => t.warId.equals(warId))).go();
  }

  // ===========================================================================
  // Haggling AI Coach queries (Round 5)
  // ===========================================================================

  Future<List<HagglingSession>> getAllHagglingSessions() {
    return select(hagglingSessions).get();
  }

  Future<void> insertHagglingSession(HagglingSessionsCompanion session) {
    return into(hagglingSessions).insert(session);
  }

  Future<void> updateHagglingSession(HagglingSession session) {
    return update(hagglingSessions).replace(session);
  }

  Future<void> deleteHagglingSession(String sessionId) {
    return (delete(hagglingSessions)..where((t) => t.sessionId.equals(sessionId))).go();
  }

  // ===========================================================================
  // Price Elasticity Explorer queries (Round 5)
  // ===========================================================================

  Future<List<ElasticityItem>> getAllElasticityItems() {
    return select(elasticityItems).get();
  }

  Future<void> insertElasticityItem(ElasticityItemsCompanion item) {
    return into(elasticityItems).insert(item);
  }

  Future<void> updateElasticityItem(ElasticityItem item) {
    return update(elasticityItems).replace(item);
  }

  Future<void> deleteElasticityItem(String itemId) {
    return (delete(elasticityItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  // ===========================================================================
  // Inventory Price Stalker queries (Round 5)
  // ===========================================================================

  Future<List<InventoryStalkerItem>> getAllInventoryStalkerItems() {
    return select(inventoryStalkerItems).get();
  }

  Future<void> insertInventoryStalkerItem(InventoryStalkerItemsCompanion item) {
    return into(inventoryStalkerItems).insert(item);
  }

  Future<void> updateInventoryStalkerItem(InventoryStalkerItem item) {
    return update(inventoryStalkerItems).replace(item);
  }

  Future<void> deleteInventoryStalkerItem(String itemId) {
    return (delete(inventoryStalkerItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  // ===========================================================================
  // Lending Records queries
  // ===========================================================================

  Future<List<LendingRecord>> getAllLendingRecords() {
    return select(lendingRecords).get();
  }

  Future<List<LendingRecord>> getLendingRecordsByStatus(String status) {
    return (select(lendingRecords)..where((t) => t.status.equals(status))).get();
  }

  Future<void> insertLendingRecord(LendingRecordsCompanion record) {
    return into(lendingRecords).insert(record);
  }

  Future<void> updateLendingRecord(LendingRecord record) {
    return update(lendingRecords).replace(record);
  }

  Future<LendingRecord?> getLendingRecordByRecordId(String recordId) async {
    final query = select(lendingRecords)..where((t) => t.recordId.equals(recordId));
    final list = await (query..limit(1)).get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<List<String>> getUniqueDebtorNames() async {
    final records = await select(lendingRecords).get();
    return records.map((r) => r.debtorName).toSet().toList()..sort();
  }

  // ===========================================================================
  // Goal Product Links queries (Round 7)
  // ===========================================================================

  Future<List<GoalProductLink>> getAllGoalProductLinks() {
    return select(goalProductLinks).get();
  }

  Future<List<GoalProductLink>> getGoalProductLinksByGoalId(int goalId) {
    return (select(goalProductLinks)..where((t) => t.goalId.equals(goalId))).get();
  }

  Future<void> insertGoalProductLink(GoalProductLinksCompanion link) {
    return into(goalProductLinks).insert(link);
  }

  Future<void> updateGoalProductLink(GoalProductLink link) {
    return update(goalProductLinks).replace(link);
  }

  Future<void> deleteGoalProductLink(String linkId) {
    return (delete(goalProductLinks)..where((t) => t.linkId.equals(linkId))).go();
  }

  // ===========================================================================
  // Habit Loops queries (Round 7)
  // ===========================================================================

  Future<List<HabitLoop>> getAllHabitLoops() {
    return select(habitLoops).get();
  }

  Future<List<HabitLoop>> getActiveHabitLoops() {
    return (select(habitLoops)..where((t) => t.isActive.equals(true))).get();
  }

  Future<void> insertHabitLoop(HabitLoopsCompanion habit) {
    return into(habitLoops).insert(habit);
  }

  Future<void> updateHabitLoop(HabitLoop habit) {
    return update(habitLoops).replace(habit);
  }

  Future<void> deleteHabitLoop(String habitId) {
    return (delete(habitLoops)..where((t) => t.habitId.equals(habitId))).go();
  }

  // ===========================================================================
  // Inflation Shield queries (Round 7)
  // ===========================================================================

  Future<List<InflationShield>> getAllInflationShields() {
    return select(inflationShields).get();
  }

  Future<void> insertInflationShield(InflationShieldsCompanion shield) {
    return into(inflationShields).insert(shield);
  }

  Future<void> updateInflationShield(InflationShield shield) {
    return update(inflationShields).replace(shield);
  }

  // ===========================================================================
  // Price History Entries queries (Round 7)
  // ===========================================================================

  Future<List<PriceHistoryEntry>> getAllPriceHistoryEntries() {
    return select(priceHistoryEntries).get();
  }

  Future<List<PriceHistoryEntry>> getPriceHistoryForProduct(String productName) {
    return (select(priceHistoryEntries)..where((t) => t.productName.equals(productName))).get();
  }

  Future<List<PriceHistoryEntry>> getPriceHistoryForProductLastDays(String productName, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (select(priceHistoryEntries)
      ..where((t) => t.productName.equals(productName) & t.recordedAt.isBiggerOrEqualValue(cutoff)))
      .get();
  }

  Future<void> insertPriceHistoryEntry(PriceHistoryEntriesCompanion entry) {
    return into(priceHistoryEntries).insert(entry);
  }

  // ===========================================================================
  // Price Detective Items queries (Round 7)
  // ===========================================================================

  Future<List<PriceDetectiveItem>> getAllPriceDetectiveItems() {
    return select(priceDetectiveItems).get();
  }

  Future<PriceDetectiveItem?> getPriceDetectiveItemByItemId(String itemId) async {
    final query = select(priceDetectiveItems)..where((t) => t.itemId.equals(itemId));
    final list = await (query..limit(1)).get();
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> insertPriceDetectiveItem(PriceDetectiveItemsCompanion item) {
    return into(priceDetectiveItems).insert(item);
  }

  Future<void> updatePriceDetectiveItem(PriceDetectiveItem item) {
    return update(priceDetectiveItems).replace(item);
  }

  Future<void> deletePriceDetectiveItem(String itemId) {
    return (delete(priceDetectiveItems)..where((t) => t.itemId.equals(itemId))).go();
  }

  Future<void> setActiveSound(String soundId) async {
    // Deactivate all, then activate the selected one
    await (soundUnlocks.update())
        .write(const SoundUnlocksCompanion(isActive: Value(false)));
    final query = select(soundUnlocks)
      ..where((t) => t.soundId.equals(soundId));
    final results = await query.get();
    for (final row in results) {
      await update(soundUnlocks).replace(
        row.copyWith(isActive: true),
      );
    }
  }
}

// =============================================================================
// Database connection helper
// =============================================================================

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'neoncred.db'));
    return NativeDatabase.createInBackground(file);
  });
}

// =============================================================================
// Riverpod providers
// =============================================================================

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// NOTE: openRouterApiKeyProvider is now defined in core/config/env_provider.dart
// and reads from .env file. Import env_provider.dart instead of database.dart
// to access API keys.
// This alias is kept for backward compatibility with existing services.
// Deprecated: use env_provider.openRouterApiKeyProvider instead.
