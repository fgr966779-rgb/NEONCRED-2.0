import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/env_provider.dart';
import '../../../core/utils/open_router_service.dart';

// === MODELS ===

class CalendarDay {
  final DateTime date;
  final int buyingPowerIndex;
  final String label;
  final String description;
  final List<String> hotCategories;
  final double? avgDiscount;

  const CalendarDay({
    required this.date,
    required this.buyingPowerIndex,
    required this.label,
    required this.description,
    this.hotCategories = const [],
    this.avgDiscount,
  });
}

class SeasonalEvent {
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double expectedDiscount;
  final List<String> categories;
  final String type;

  const SeasonalEvent({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.expectedDiscount,
    this.categories = const [],
    this.type = 'sale',
  });
}

class CalendarSubscription {
  final String id;
  final String category;
  final String threshold;
  final bool isActive;

  const CalendarSubscription({
    required this.id,
    required this.category,
    required this.threshold,
    this.isActive = true,
  });
}

class SeasonalCalendarState {
  final List<CalendarDay> calendarDays;
  final List<SeasonalEvent> upcomingEvents;
  final List<CalendarSubscription> subscriptions;
  final CalendarDay? selectedDay;
  final String aiWeeklyGuide;
  final bool isLoading;
  final String? error;
  final int selectedMonth;
  final int selectedYear;

  const SeasonalCalendarState({
    this.calendarDays = const [],
    this.upcomingEvents = const [],
    this.subscriptions = const [],
    this.selectedDay,
    this.aiWeeklyGuide = '',
    this.isLoading = false,
    this.error,
    this.selectedMonth = 1,
    this.selectedYear = 2026,
  });

  SeasonalCalendarState copyWith({
    List<CalendarDay>? calendarDays,
    List<SeasonalEvent>? upcomingEvents,
    List<CalendarSubscription>? subscriptions,
    CalendarDay? selectedDay,
    String? aiWeeklyGuide,
    bool? isLoading,
    String? error,
    int? selectedMonth,
    int? selectedYear,
  }) {
    return SeasonalCalendarState(
      calendarDays: calendarDays ?? this.calendarDays,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      subscriptions: subscriptions ?? this.subscriptions,
      selectedDay: selectedDay ?? this.selectedDay,
      aiWeeklyGuide: aiWeeklyGuide ?? this.aiWeeklyGuide,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedYear: selectedYear ?? this.selectedYear,
    );
  }
}

// === SEASONAL EVENTS DATABASE ===

final _globalEvents = <SeasonalEvent>[
  SeasonalEvent(name: 'New Year Sale', startDate: DateTime(2026, 1, 1), endDate: DateTime(2026, 1, 7), expectedDiscount: 30, categories: ['Electronics', 'Smartphones', 'Laptops'], type: 'sale'),
  SeasonalEvent(name: 'Valentine Tech Deals', startDate: DateTime(2026, 2, 10), endDate: DateTime(2026, 2, 14), expectedDiscount: 20, categories: ['Audio', 'Smartphones'], type: 'sale'),
  SeasonalEvent(name: 'Spring Clearance', startDate: DateTime(2026, 3, 20), endDate: DateTime(2026, 3, 31), expectedDiscount: 25, categories: ['TV', 'Monitors', 'Components'], type: 'clearance'),
  SeasonalEvent(name: 'Amazon Prime Day', startDate: DateTime(2026, 7, 12), endDate: DateTime(2026, 7, 13), expectedDiscount: 40, categories: ['Electronics', 'Gaming', 'Audio', 'Smartphones', 'Laptops'], type: 'mega_sale'),
  SeasonalEvent(name: 'Back to School', startDate: DateTime(2026, 8, 15), endDate: DateTime(2026, 9, 5), expectedDiscount: 25, categories: ['Laptops', 'Tablets', 'Monitors'], type: 'sale'),
  SeasonalEvent(name: 'Black Friday', startDate: DateTime(2026, 11, 27), endDate: DateTime(2026, 11, 28), expectedDiscount: 50, categories: ['Electronics', 'Gaming', 'TV', 'Smartphones', 'Audio', 'Components'], type: 'mega_sale'),
  SeasonalEvent(name: 'Cyber Monday', startDate: DateTime(2026, 11, 30), endDate: DateTime(2026, 11, 30), expectedDiscount: 45, categories: ['Laptops', 'Components', 'Monitors', 'Tablets'], type: 'mega_sale'),
  SeasonalEvent(name: 'Holiday Season', startDate: DateTime(2026, 12, 15), endDate: DateTime(2026, 12, 31), expectedDiscount: 35, categories: ['Gaming', 'Audio', 'Smartphones'], type: 'sale'),
  SeasonalEvent(name: 'PS6 Launch Window', startDate: DateTime(2027, 11, 1), endDate: DateTime(2027, 12, 15), expectedDiscount: 35, categories: ['Gaming'], type: 'launch'),
  SeasonalEvent(name: 'iPhone 19 Release', startDate: DateTime(2027, 9, 10), endDate: DateTime(2027, 9, 20), expectedDiscount: 30, categories: ['Smartphones'], type: 'launch'),
];

// === NOTIFIER ===

class SeasonalCalendarNotifier extends StateNotifier<SeasonalCalendarState> {
  final Ref _ref;

  SeasonalCalendarNotifier(this._ref) : super(const SeasonalCalendarState());

  Future<void> loadMonth(int month, int year) async {
    state = state.copyWith(isLoading: true, selectedMonth: month, selectedYear: year, error: null);
    try {
      final env = _ref.read(envProvider);
      final days = <CalendarDay>[];
      final daysInMonth = DateTime(year, month + 1, 0).day;
      final rand = Random();

      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(year, month, d);
        final events = _getEventsForDate(date);
        int bpi = 50 + rand.nextInt(30);
        String label = 'Normal day';
        String description = 'Standard market prices. No special events detected.';
        List<String> hotCats = [];
        double? avgDiscount;

        if (events.isNotEmpty) {
          final best = events.reduce((a, b) => a.expectedDiscount > b.expectedDiscount ? a : b);
          bpi = (80 + best.expectedDiscount / 2).round().clamp(0, 100);
          label = best.name;
          description = 'Expected discount: ${best.expectedDiscount.toStringAsFixed(0)}%. ${best.categories.join(", ")} categories.';
          hotCats = best.categories;
          avgDiscount = best.expectedDiscount;
        }

        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          bpi = (bpi + 5).clamp(0, 100);
        }

        days.add(CalendarDay(
          date: date,
          buyingPowerIndex: bpi,
          label: label,
          description: description,
          hotCategories: hotCats,
          avgDiscount: avgDiscount,
        ));
      }

      final upcoming = _globalEvents.where((e) =>
        e.startDate.isAfter(DateTime.now()) && e.startDate.isBefore(DateTime.now().add(const Duration(days: 90)))
      ).toList();

      final guide = await _generateWeeklyGuide(month, year, upcoming);

      state = state.copyWith(
        calendarDays: days,
        upcomingEvents: upcoming,
        aiWeeklyGuide: guide,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<SeasonalEvent> _getEventsForDate(DateTime date) {
    return _globalEvents.where((e) =>
      !date.isBefore(e.startDate) && !date.isAfter(e.endDate)
    ).toList();
  }

  Future<String> _generateWeeklyGuide(int month, int year, List<SeasonalEvent> events) async {
    try {
      final ai = _ref.read(openRouterServiceProvider);
      final eventsText = events.map((e) =>
        '${e.name}: ${e.startDate.day}.${e.startDate.month} - ${e.endDate.day}.${e.endDate.month}, discount up to ${e.expectedDiscount.toStringAsFixed(0)}% on ${e.categories.join(", ")}'
      ).join('\n');

      final response = await ai.chat(
        systemPrompt: 'You are a cyberpunk seasonal calendar AI called CHRONO BUYER. Respond in Ukrainian with cyberpunk flavor. Be concise (2-3 sentences). Give weekly buying advice.',
        userPrompt: 'Month: $month/$year. Upcoming events:\n$eventsText\nGive a brief buying guide for this period.',
        temperature: 0.85,
        maxTokens: 512,
      );
      return (response ?? '').trim();
    } catch (_) {
      return 'Chrono Buyer: calendar data processed. Seasonal patterns analyzed.';
    }
  }

  void selectDay(CalendarDay day) {
    state = state.copyWith(selectedDay: day);
  }

  void addSubscription(String category, String threshold) {
    final sub = CalendarSubscription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      category: category,
      threshold: threshold,
    );
    state = state.copyWith(subscriptions: [...state.subscriptions, sub]);
  }

  void removeSubscription(String id) {
    state = state.copyWith(subscriptions: state.subscriptions.where((s) => s.id != id).toList());
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// === PROVIDER ===

final seasonalCalendarProvider = StateNotifierProvider<SeasonalCalendarNotifier, SeasonalCalendarState>(
  (ref) => SeasonalCalendarNotifier(ref),
);
