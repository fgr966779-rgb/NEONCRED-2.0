import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database.dart';

// =========================================================================
// OnboardingScreen — first-time user setup
// =========================================================================

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _cardBg = Color(0xFF111827);
  static const _green = Color(0xFF00FF88);

  final _nameController = TextEditingController();
  String? _selectedClass;
  bool _isSaving = false;

  static const _characterClasses = [
    _CharacterClassOption('NetRunner', 'Швидкий хакер мережевих цін', Icons.electrical_services),
    _CharacterClassOption('CryptoSamurai', 'Майстер цифрових активів', Icons.shield),
    _CharacterClassOption('DataMage', 'Чарівник аналітики даних', Icons.auto_fix_high),
    _CharacterClassOption('CircuitKnight', 'Захисник фінансових фортець', Icons.security),
    _CharacterClassOption('VoidHacker', 'Руйнівник імпульсивних покупок', Icons.code),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedClass == null) return;

    setState(() => _isSaving = true);

    try {
      final database = ref.read(databaseProvider);
      await database.insertUser(
        UsersCompanion.insert(
          displayName: name,
          characterClass: Value(_selectedClass),
          xp: const Value(0),
          level: const Value(1),
          karma: const Value(10),
          currentStreak: const Value(0),
          notificationsEnabled: const Value(true),
        ),
      );

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Помилка: $e'),
            backgroundColor: const Color(0xFFFF3366),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Logo
              Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_cyan, _purple],
                  ).createShader(bounds),
                  child: Text(
                    'NEONCRED',
                    style: GoogleFonts.orbitron(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'IНIЦIАЛIЗАЦIЯ ПРОФIЛЮ',
                  style: GoogleFonts.shareTechMono(
                    color: _cyan.withOpacity(0.6),
                    fontSize: 12,
                    letterSpacing: 3,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Name field
              Text(
                'ТВОЇМ ІМ\'ЯМ БУДЕ...',
                style: GoogleFonts.orbitron(
                  color: _cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: GoogleFonts.shareTechMono(
                  color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Введи нікнейм...',
                  hintStyle: GoogleFonts.shareTechMono(
                    color: Colors.white24,
                  ),
                  filled: true,
                  fillColor: _cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _cyan, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                textInputAction: TextInputAction.done,
              ),

              const SizedBox(height: 36),

              // Class selection
              Text(
                'ОБЕРИ КЛАС ПЕРСОНАЖА',
                style: GoogleFonts.orbitron(
                  color: _cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),

              ..._characterClasses.map((cls) => _ClassCard(
                    cls: cls,
                    isSelected: _selectedClass == cls.name,
                    onTap: () => setState(() => _selectedClass = cls.name),
                  )),

              const SizedBox(height: 36),

              // Save button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: (_nameController.text.isNotEmpty &&
                          _selectedClass != null &&
                          !_isSaving)
                      ? _saveProfile
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _bg,
                    disabledBackgroundColor: _cyan.withOpacity(0.2),
                    disabledForegroundColor: _bg.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: _bg,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'АКТИВУВАТИ ПРОФІЛЬ',
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterClassOption {
  final String name;
  final String description;
  final IconData icon;
  const _CharacterClassOption(this.name, this.description, this.icon);
}

class _ClassCard extends StatelessWidget {
  final _CharacterClassOption cls;
  final bool isSelected;
  final VoidCallback onTap;

  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);
  static const _cardBg = Color(0xFF111827);

  const _ClassCard({
    required this.cls,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _cyan : _cyan.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _cyan.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? _cyan.withOpacity(0.2)
                    : _purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                cls.icon,
                color: isSelected ? _cyan : _purple.withOpacity(0.7),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cls.name,
                    style: GoogleFonts.orbitron(
                      color: isSelected ? _cyan : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cls.description,
                    style: GoogleFonts.shareTechMono(
                      color: isSelected
                          ? _cyan.withOpacity(0.7)
                          : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: _cyan, size: 22),
          ],
        ),
      ),
    );
  }
}
