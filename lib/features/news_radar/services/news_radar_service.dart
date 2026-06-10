import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/providers.dart';
import '../../../core/utils/open_router_service.dart';
import '../../../data/database.dart';

// ---------------------------------------------------------------------------
// NewsCategory
// ---------------------------------------------------------------------------

enum NewsCategory {
  currency,
  crypto,
  interestRates,
  inflation,
  electronics,
  realEstate,
  employment,
  general,
}

extension NewsCategoryX on NewsCategory {
  String get labelUA => switch (this) {
        NewsCategory.currency => 'Валюта',
        NewsCategory.crypto => 'Крипто',
        NewsCategory.interestRates => 'Ставки',
        NewsCategory.inflation => 'Інфляція',
        NewsCategory.electronics => 'Електроніка',
        NewsCategory.realEstate => 'Нерухомість',
        NewsCategory.employment => 'Ринок праці',
        NewsCategory.general => 'Загальне',
      };

  String get iconEmoji => switch (this) {
        NewsCategory.currency => '\u{1F4B1}',
        NewsCategory.crypto => '\u{1F4B3}',
        NewsCategory.interestRates => '\u{1F4C8}',
        NewsCategory.inflation => '\u{1F525}',
        NewsCategory.electronics => '\u{1F4BB}',
        NewsCategory.realEstate => '\u{1F3E0}',
        NewsCategory.employment => '\u{1F4BC}',
        NewsCategory.general => '\u{1F4F0}',
      };

  String get serpApiQuery => switch (this) {
        NewsCategory.currency => 'USD UAH exchange rate Ukraine 2025',
        NewsCategory.crypto => 'bitcoin ethereum crypto news',
        NewsCategory.interestRates => 'NBU interest rate Ukraine',
        NewsCategory.inflation => 'inflation Ukraine 2025',
        NewsCategory.electronics => 'electronics prices Ukraine',
        NewsCategory.realEstate => 'real estate prices Ukraine',
        NewsCategory.employment => 'employment salary Ukraine',
        NewsCategory.general => 'finance economy Ukraine',
      };
}

// ---------------------------------------------------------------------------
// NewsInsight
// ---------------------------------------------------------------------------

class NewsInsight {
  final String insightId;
  final String headlineUA;
  final String summaryUA;
  final double relevanceScore;
  final String source;
  final NewsCategory category;
  final int? relatedGoalId;
  final DateTime publishedAt;
  final bool isRead;
  final bool isActionable;
  final String? actionSuggestionUA;

  const NewsInsight({
    required this.insightId,
    required this.headlineUA,
    required this.summaryUA,
    required this.relevanceScore,
    required this.source,
    required this.category,
    this.relatedGoalId,
    required this.publishedAt,
    this.isRead = false,
    this.isActionable = false,
    this.actionSuggestionUA,
  });

  NewsInsight copyWith({bool? isRead}) {
    return NewsInsight(
      insightId: insightId,
      headlineUA: headlineUA,
      summaryUA: summaryUA,
      relevanceScore: relevanceScore,
      source: source,
      category: category,
      relatedGoalId: relatedGoalId,
      publishedAt: publishedAt,
      isRead: isRead ?? this.isRead,
      isActionable: isActionable,
      actionSuggestionUA: actionSuggestionUA,
    );
  }
}

// ---------------------------------------------------------------------------
// NewsRadarState
// ---------------------------------------------------------------------------

class NewsRadarState {
  final List<NewsInsight> insights;
  final int unreadCount;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetchedAt;
  final NewsCategory? filterCategory;

  const NewsRadarState({
    this.insights = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
    this.lastFetchedAt,
    this.filterCategory,
  });

  NewsRadarState copyWith({
    List<NewsInsight>? insights,
    int? unreadCount,
    bool? isLoading,
    String? error,
    DateTime? lastFetchedAt,
    NewsCategory? filterCategory,
    bool clearFilter = false,
  }) {
    return NewsRadarState(
      insights: insights ?? this.insights,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetchedAt: lastFetchedAt ?? this.lastFetchedAt,
      filterCategory: clearFilter ? null : (filterCategory ?? this.filterCategory),
    );
  }

  List<NewsInsight> get filteredInsights => filterCategory != null
      ? insights.where((i) => i.category == filterCategory).toList()
      : insights;
}

// ---------------------------------------------------------------------------
// NewsRadarNotifier
// ---------------------------------------------------------------------------

class NewsRadarNotifier extends StateNotifier<NewsRadarState> {
  final Ref _ref;

  NewsRadarNotifier(this._ref) : super(const NewsRadarState());

  // =========================================================================
  // Public API
  // =========================================================================

  Future<void> fetchNews() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final allInsights = <NewsInsight>[];

      // Fetch news for each category via SerpAPI
      for (final category in NewsCategory.values) {
        final rawResults = await _fetchSerpApiNews(category);
        if (rawResults.isEmpty) continue;

        // Analyze with AI and convert to insights
        final insights = await _analyzeWithAI(rawResults, category);
        allInsights.addAll(insights);
      }

      // Sort by relevance
      allInsights.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // Save to database
      final database = _ref.read(databaseProvider);
      for (final insight in allInsights) {
        await database.insertNewsInsight(
          NewsInsightsCompanion.insert(
            insightId: insight.insightId,
            headline: insight.headlineUA,
            summary: insight.summaryUA,
            relevanceScore: Value(insight.relevanceScore),
            source: Value(insight.source),
            category: insight.category.name,
            relatedGoalId: Value(insight.relatedGoalId),
            isActionable: Value(insight.isActionable),
            actionSuggestion: Value(insight.actionSuggestionUA),
          ),
        );
      }

      final unread = allInsights.where((i) => !i.isRead).length;

      state = state.copyWith(
        insights: allInsights,
        unreadCount: unread,
        isLoading: false,
        lastFetchedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void markAsRead(String insightId) {
    final updated = state.insights.map((i) {
      if (i.insightId == insightId) return i.copyWith(isRead: true);
      return i;
    }).toList();

    final unread = updated.where((i) => !i.isRead).length;
    state = state.copyWith(insights: updated, unreadCount: unread);
  }

  void setFilter(NewsCategory? category) {
    if (category == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterCategory: category);
    }
  }

  // =========================================================================
  // SerpAPI — Google search for financial news (via centralized service)
  // =========================================================================

  Future<List<Map<String, dynamic>>> _fetchSerpApiNews(
    NewsCategory category,
  ) async {
    try {
      final results = await _ref
          .read(serpApiServiceProvider)
          .searchNews(category.serpApiQuery, numResults: 5);

      return results.map((r) => <String, dynamic>{
        'title': r.title,
        'snippet': r.snippet,
        'link': r.link,
        'date': r.date,
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // =========================================================================
  // OpenRouter AI — analyze news & generate Ukrainian insights (via service)
  // =========================================================================

  Future<List<NewsInsight>> _analyzeWithAI(
    List<Map<String, dynamic>> newsItems,
    NewsCategory category,
  ) async {
    final openRouter = _ref.read(openRouterServiceProvider);
    final apiKey = _ref.read(openRouterApiKeyProvider);
    if (apiKey.isEmpty) return _fallbackInsights(newsItems, category);

    try {
      final newsText = newsItems
          .asMap()
          .entries
          .map((e) => '[${e.key + 1}] ${e.value['title']}\n${e.value['snippet']}')
          .join('\n\n');

      final userPrompt =
          'You are VAULT-17, the AI oracle of NEONCRED — a gamified savings app.\n'
          'Analyze these financial news items and create actionable insights for a Ukrainian user.\n\n'
          'Category: ${category.labelUA}\n'
          'News:\n$newsText\n\n'
          'For EACH news item, generate a JSON object with:\n'
          '- "headline": Ukrainian headline (max 80 chars)\n'
          '- "summary": Ukrainian summary (1-2 sentences, how this affects savings)\n'
          '- "isActionable": true if user should act NOW (deposit, convert currency, etc.)\n'
          '- "actionSuggestion": Ukrainian action suggestion if actionable, else null\n'
          '- "relevance": 0.0-1.0 how relevant to personal savings goals\n\n'
          'Return a JSON array. No markdown, no code fences, just the array.';

      final result = await openRouter.chatJson(
        systemPrompt:
            'You are VAULT-17. You analyze financial news and generate '
            'Ukrainian-language savings insights. Return ONLY a JSON array, no markdown.',
        userPrompt: userPrompt,
        temperature: 0.7,
        maxTokens: 1024,
      );

      if (result == null) return _fallbackInsights(newsItems, category);

      // Result may be a List directly or wrapped in an object
      final List<dynamic> parsed;
      if (result is List) {
        parsed = result as List<dynamic>;
      } else if (result['insights'] is List) {
        parsed = result['insights'] as List<dynamic>;
      } else {
        return _fallbackInsights(newsItems, category);
      }

      return parsed.asMap().entries.map((entry) {
        final i = entry.value as Map<String, dynamic>;
        final originalIndex = entry.key;
        return NewsInsight(
          insightId: 'insight_${category.name}_${DateTime.now().millisecondsSinceEpoch}_$originalIndex',
          headlineUA: i['headline']?.toString() ?? newsItems[originalIndex]['title'] ?? '',
          summaryUA: i['summary']?.toString() ?? '',
          relevanceScore: (i['relevance'] as num?)?.toDouble() ?? 0.5,
          source: newsItems[originalIndex]['link']?.toString() ?? 'web',
          category: category,
          publishedAt: DateTime.now(),
          isActionable: i['isActionable'] == true,
          actionSuggestionUA: i['actionSuggestion']?.toString(),
        );
      }).toList();
    } catch (_) {
      return _fallbackInsights(newsItems, category);
    }
  }

  // =========================================================================
  // Fallback insights (when AI is unavailable)
  // =========================================================================

  List<NewsInsight> _fallbackInsights(
    List<Map<String, dynamic>> newsItems,
    NewsCategory category,
  ) {
    return newsItems.asMap().entries.map((entry) {
      final i = entry.value;
      return NewsInsight(
        insightId: 'insight_${category.name}_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
        headlineUA: i['title']?.toString() ?? 'Фінансові новини',
        summaryUA: i['snippet']?.toString() ?? '',
        relevanceScore: 0.5,
        source: i['link']?.toString() ?? 'web',
        category: category,
        publishedAt: DateTime.now(),
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final newsRadarProvider =
    StateNotifierProvider<NewsRadarNotifier, NewsRadarState>(
  (ref) => NewsRadarNotifier(ref),
);
