import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/seasonal_calendar_provider.dart';

class SeasonalCalendarScreen extends ConsumerStatefulWidget {
  const SeasonalCalendarScreen({super.key});

  @override
  ConsumerState<SeasonalCalendarScreen> createState() => _SeasonalCalendarScreenState();
}

class _SeasonalCalendarScreenState extends ConsumerState<SeasonalCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = DateTime.now();
      ref.read(seasonalCalendarProvider.notifier).loadMonth(now.month, now.year);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(seasonalCalendarProvider);
    final notifier = ref.read(seasonalCalendarProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('SEASONAL CALENDAR', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMonthSelector(state, notifier),
                const SizedBox(height: 16),
                if (state.aiWeeklyGuide.isNotEmpty) _buildWeeklyGuide(state),
                const SizedBox(height: 16),
                _buildUpcomingEvents(state),
                const SizedBox(height: 16),
                _buildCalendarGrid(state, notifier),
                if (state.selectedDay != null) ...[
                  const SizedBox(height: 16),
                  _buildSelectedDayDetail(state),
                ],
                const SizedBox(height: 16),
                _buildSubscriptions(state, notifier),
              ],
            ),
    );
  }

  Widget _buildMonthSelector(SeasonalCalendarState state, SeasonalCalendarNotifier notifier) {
    final monthNames = ['', 'Sichen', 'Lyutyy', 'Berezen', 'Kviten', 'Traven', 'Cherven', 'Lypen', 'Serpen', 'Veresen', 'Zhovten', 'Lystopad', 'Hruden'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFFFFD700)),
            onPressed: () {
              int m = state.selectedMonth - 1;
              int y = state.selectedYear;
              if (m < 1) { m = 12; y--; }
              notifier.loadMonth(m, y);
            },
          ),
          Text('${monthNames[state.selectedMonth]} ${state.selectedYear}', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 18)),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Color(0xFFFFD700)),
            onPressed: () {
              int m = state.selectedMonth + 1;
              int y = state.selectedYear;
              if (m > 12) { m = 1; y++; }
              notifier.loadMonth(m, y);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyGuide(SeasonalCalendarState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POSHYR PORADA', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 13)),
          const SizedBox(height: 6),
          Text(state.aiWeeklyGuide, style: GoogleFonts.shareTechMono(color: const Color(0xFF6B00FF), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(SeasonalCalendarState state) {
    if (state.upcomingEvents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NAYBLYZHCHI PODIYI', style: GoogleFonts.orbitron(color: const Color(0xFFFF3366), fontSize: 13)),
        const SizedBox(height: 8),
        ...state.upcomingEvents.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getEventColor(e.type).withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: GoogleFonts.orbitron(color: _getEventColor(e.type), fontSize: 12)),
                    Text('${e.startDate.day}.${e.startDate.month} - ${e.endDate.day}.${e.endDate.month}', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF00FF88).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('-${e.expectedDiscount.toStringAsFixed(0)}%', style: GoogleFonts.orbitron(color: const Color(0xFF00FF88), fontSize: 13)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCalendarGrid(SeasonalCalendarState state, SeasonalCalendarNotifier notifier) {
    if (state.calendarDays.isEmpty) return const SizedBox.shrink();
    final firstDay = state.calendarDays.first.date;
    final startWeekday = firstDay.weekday % 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KALENDAR', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Nd', 'Pn', 'Vt', 'Sr', 'Cht', 'Pt', 'Sb'].map((d) =>
            SizedBox(width: 42, child: Center(child: Text(d, style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)))),
          ).toList(),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ...List.generate(startWeekday, (_) => const SizedBox(width: 42, height: 42)),
            ...state.calendarDays.map((day) {
              final isSelected = state.selectedDay?.date == day.date;
              final bpi = day.buyingPowerIndex;
              final bgColor = bpi > 80 ? const Color(0xFF00FF88) : bpi > 60 ? const Color(0xFF00F0FF) : bpi > 40 ? const Color(0xFFFFD700) : const Color(0xFFFF3366);

              return GestureDetector(
                onTap: () => notifier.selectDay(day),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSelected ? bgColor.withOpacity(0.4) : const Color(0xFF1A1F2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? bgColor : bgColor.withOpacity(0.3), width: isSelected ? 2 : 1),
                  ),
                  child: Center(
                    child: Text('${day.date.day}', style: GoogleFonts.shareTechMono(color: bgColor, fontSize: 13)),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedDayDetail(SeasonalCalendarState state) {
    final day = state.selectedDay!;
    final bpi = day.buyingPowerIndex;
    final bpiColor = bpi > 80 ? const Color(0xFF00FF88) : bpi > 60 ? const Color(0xFF00F0FF) : bpi > 40 ? const Color(0xFFFFD700) : const Color(0xFFFF3366);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bpiColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${day.date.day}.${day.date.month}.${day.date.year}', style: GoogleFonts.orbitron(color: bpiColor, fontSize: 15)),
              const SizedBox(width: 12),
              Text('BPI: $bpi', style: GoogleFonts.orbitron(color: bpiColor, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Text(day.label, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 13)),
          const SizedBox(height: 4),
          Text(day.description, style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 12)),
          if (day.avgDiscount != null) ...[
            const SizedBox(height: 6),
            Text('Serednya znyzhka: ${day.avgDiscount!.toStringAsFixed(0)}%', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 12)),
          ],
          if (day.hotCategories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: day.hotCategories.map((c) => Chip(
                label: Text(c, style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 10)),
                backgroundColor: const Color(0xFF0A0E17),
                side: const BorderSide(color: Color(0xFF00F0FF), width: 0.5),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptions(SeasonalCalendarState state, SeasonalCalendarNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('PIDPYSKY', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.add, color: Color(0xFF00F0FF), size: 16),
              label: Text('DODATY', style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 11)),
              onPressed: () => _showAddSubscriptionDialog(notifier),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.subscriptions.isEmpty)
          Text('Nemaye pidpysok. Doday kategoryi dlya nahaduvan.', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 12))
        else
          ...state.subscriptions.map((sub) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00F0FF).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(sub.isActive ? Icons.notifications_active : Icons.notifications_off, color: sub.isActive ? const Color(0xFF00FF88) : Colors.white38, size: 18),
                const SizedBox(width: 8),
                Text('${sub.category} - ${sub.threshold}', style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFFF3366), size: 16),
                  onPressed: () => notifier.removeSubscription(sub.id),
                ),
              ],
            ),
          )),
      ],
    );
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'mega_sale': return const Color(0xFFFF3366);
      case 'sale': return const Color(0xFF00FF88);
      case 'clearance': return const Color(0xFFFFD700);
      case 'launch': return const Color(0xFF6B00FF);
      default: return const Color(0xFF00F0FF);
    }
  }

  void _showAddSubscriptionDialog(SeasonalCalendarNotifier notifier) {
    final catCtrl = TextEditingController();
    final threshCtrl = TextEditingController(text: '20%');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('NOVA PIDPYSKA', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: catCtrl,
              style: GoogleFonts.shareTechMono(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Kategoryiya (napr. Gaming)',
                hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
                border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.5))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: threshCtrl,
              style: GoogleFonts.shareTechMono(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Porih znyzhky (napr. 20%)',
                hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
                border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF00F0FF).withOpacity(0.5))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B00FF)),
            onPressed: () {
              if (catCtrl.text.trim().isNotEmpty) {
                notifier.addSubscription(catCtrl.text.trim(), threshCtrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('PIDPYSATYSYA', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }
}
