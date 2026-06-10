import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

// =============================================================================
// WelcomeScreen — first onboarding screen
// =============================================================================
//
// Cyberpunk welcome with ShaderMask gradient logo, Ukrainian text,
// and "Start" button to proceed to goal setup.
// =============================================================================

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Animated logo
              FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  children: [
                    // Glowing ring
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _cyan.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _cyan.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [_cyan, _purple],
                          ).createShader(bounds),
                          child: Text(
                            'NC',
                            style: GoogleFonts.orbitron(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // NEONCRED title
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [_cyan, _purple],
                      ).createShader(bounds),
                      child: Text(
                        'NEONCRED',
                        style: GoogleFonts.orbitron(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'КІБЕРПАНК НАКОПИЧЕННЯ',
                      style: GoogleFonts.shareTechMono(
                        color: _cyan.withOpacity(0.6),
                        fontSize: 13,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // Description text
              FadeTransition(
                opacity: _fadeIn,
                child: Text(
                  'Твій цифровий скарбничок у світі неону.\n'
                  'Ставай цілеспрямованим. Копи розумно.\n'
                  'Розвивайся разом з системою.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.shareTechMono(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Start button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding-goals'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _cyan,
                    foregroundColor: _bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: _cyan.withOpacity(0.3),
                  ),
                  child: Text(
                    'ПОЧАТИ',
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Version hint
              Text(
                'v2.0 // NEONCRED SYSTEMS',
                style: GoogleFonts.shareTechMono(
                  color: Colors.white24,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
