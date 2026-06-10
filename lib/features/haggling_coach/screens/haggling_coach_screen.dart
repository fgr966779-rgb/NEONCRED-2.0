import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/haggling_coach_provider.dart';

class HagglingCoachScreen extends ConsumerStatefulWidget {
  const HagglingCoachScreen({super.key});

  @override
  ConsumerState<HagglingCoachScreen> createState() => _HagglingCoachScreenState();
}

class _HagglingCoachScreenState extends ConsumerState<HagglingCoachScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hagglingCoachProvider);
    final notifier = ref.read(hagglingCoachProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: Text('HAGGLING AI COACH', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 17)),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        elevation: 0,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : state.sessions.isEmpty
              ? _buildEmptyState(notifier)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSearchBar(notifier),
                    const SizedBox(height: 16),
                    ...state.sessions.map((session) => _buildSessionCard(session, notifier)),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B00FF),
        child: const Icon(Icons.record_voice_over, color: Color(0xFFFFD700)),
        onPressed: () => _showSearchDialog(notifier),
      ),
    );
  }

  Widget _buildSearchBar(HagglingCoachNotifier notifier) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.shareTechMono(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Pidhotuvatys do torhu...',
          hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
          prefixIcon: const Icon(Icons.record_voice_over, color: Color(0xFFFFD700)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: Color(0xFFFFD700)),
            onPressed: () {
              if (_searchController.text.trim().isNotEmpty) {
                notifier.prepareHaggling(_searchController.text.trim());
                _searchController.clear();
              }
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) {
            notifier.prepareHaggling(v.trim());
            _searchController.clear();
          }
        },
      ),
    );
  }

  Widget _buildSessionCard(HagglingSession session, HagglingCoachNotifier notifier) {
    final statusColor = session.status == 'won' ? const Color(0xFF00FF88) : session.status == 'lost' ? const Color(0xFFFF3366) : const Color(0xFFFFD700);
    final statusLabel = session.status == 'won' ? 'PEREMOHA' : session.status == 'lost' ? 'PROHRASH' : 'HOTOVYY';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(session.productName, style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: statusColor.withOpacity(0.5))),
                  child: Text(statusLabel, style: GoogleFonts.orbitron(color: statusColor, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPriceCol('MAGAZYN', '${session.storePrice.toStringAsFixed(0)} грн', const Color(0xFFFF3366)),
                const SizedBox(width: 16),
                _buildPriceCol('TSIL', '${session.targetPrice.toStringAsFixed(0)} грн', const Color(0xFF00FF88)),
                const SizedBox(width: 16),
                _buildPriceCol('KONKURENT', '${session.bestCompetitorPrice.toStringAsFixed(0)} грн', const Color(0xFF00F0FF)),
                const SizedBox(width: 16),
                _buildPriceCol('EKONOMIYA', '${session.savingsPotential.toStringAsFixed(1)}%', const Color(0xFFFFD700)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('SHANS USPIKU: ', style: GoogleFonts.shareTechMono(color: Colors.white38, fontSize: 11)),
                Text(session.successRate, style: GoogleFonts.orbitron(color: const Color(0xFF00FF88), fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            if (session.competitorPrices.isNotEmpty) ...[
              Text('TSINY KONKURENTIV', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 12)),
              const SizedBox(height: 6),
              ...session.competitorPrices.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(width: 80, child: Text(c.store, style: GoogleFonts.shareTechMono(color: const Color(0xFF00F0FF), fontSize: 12))),
                    Text('${c.price.toStringAsFixed(0)} грн', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 12)),
                  ],
                ),
              )),
              const SizedBox(height: 12),
            ],
            if (session.script.isNotEmpty) ...[
              Text('SKRYPT PEREHOVORIV', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 12)),
              const SizedBox(height: 6),
              ...session.script.asMap().entries.map((entry) {
                final idx = entry.key;
                final step = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E17),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6B00FF).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: const Color(0xFF6B00FF).withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text('${idx + 1}', style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 11))),
                          ),
                          const SizedBox(width: 8),
                          Text(step.step, style: GoogleFonts.orbitron(color: const Color(0xFF6B00FF), fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(step.dialogue, style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 12)),
                      if (step.tips.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Porada: ${step.tips}', style: GoogleFonts.shareTechMono(color: const Color(0xFFFFD700).withOpacity(0.7), fontSize: 11)),
                      ],
                    ],
                  ),
                );
              }),
            ],
            if (session.aiCoachTip.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
                ),
                child: Text(session.aiCoachTip, style: GoogleFonts.shareTechMono(color: const Color(0xFFFFD700), fontSize: 12)),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (session.status == 'ready') ...[
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle, color: Color(0xFF00FF88), size: 16),
                    label: Text('VYHRYV', style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF88), fontSize: 11)),
                    onPressed: () => notifier.markSessionWon(session.id),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, color: Color(0xFFFF3366), size: 16),
                    label: Text('PROHRYV', style: GoogleFonts.shareTechMono(color: const Color(0xFFFF3366), fontSize: 11)),
                    onPressed: () => notifier.markSessionLost(session.id),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFFF3366), size: 20),
                  onPressed: () => notifier.removeSession(session.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.shareTechMono(color: color.withOpacity(0.6), fontSize: 9)),
        Text(value, style: GoogleFonts.orbitron(color: color, fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState(HagglingCoachNotifier notifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.record_voice_over, size: 64, color: const Color(0xFFFFD700).withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('HAGGLING AI COACH', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 20)),
            const SizedBox(height: 8),
            Text('AI-trener torhu: heneruye skrypty perehovoriv', style: GoogleFonts.shareTechMono(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            _buildSearchBar(notifier),
            const SizedBox(height: 24),
            Text('KATALOH', style: GoogleFonts.orbitron(color: const Color(0xFF00F0FF), fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(notifier.predefinedCatalog.length, (i) {
                final cat = notifier.predefinedCatalog[i];
                return ActionChip(
                  label: Text(cat['name'] as String, style: GoogleFonts.shareTechMono(color: const Color(0xFFFFD700), fontSize: 11)),
                  backgroundColor: const Color(0xFF1A1F2E),
                  side: const BorderSide(color: Color(0xFFFFD700), width: 0.5),
                  onPressed: () => notifier.addPredefinedProduct(i),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(HagglingCoachNotifier notifier) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2E),
        title: Text('NOVYY TORH', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700), fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: GoogleFonts.shareTechMono(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Nazva produktu dlya torhu...',
            hintStyle: GoogleFonts.shareTechMono(color: Colors.white54),
            prefixIcon: const Icon(Icons.record_voice_over, color: Color(0xFFFFD700)),
            border: UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.5))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skasuvaty', style: GoogleFonts.shareTechMono(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B00FF)),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                notifier.prepareHaggling(ctrl.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text('PIDHOTUVATY', style: GoogleFonts.orbitron(color: const Color(0xFFFFD700))),
          ),
        ],
      ),
    );
  }
}
