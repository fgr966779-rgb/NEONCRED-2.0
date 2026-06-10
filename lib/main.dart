import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';

// =============================================================================
// NEONCRED Entry Point
// =============================================================================
//
// Cyberpunk-themed gamified savings app.
// Architecture: Flutter + Riverpod + Drift (SQLite) + GoRouter
//
// Initialization chain:
//   main() -> ProviderScope -> envProvider (loads .env)
//           -> databaseProvider (AppDatabase with Drift/SQLite)
//           -> appRouter (GoRouter with 40 feature routes)
//           -> screens (StateNotifier + OpenRouterService)
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for consistent cyberpunk UI
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay to match dark cyberpunk theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF0A0E17),
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E17),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: NeonCredApp(),
    ),
  );
}

// =============================================================================
// Root Application Widget
// =============================================================================

class NeonCredApp extends StatelessWidget {
  const NeonCredApp({super.key});

  // Cyberpunk color constants
  static const _bg = Color(0xFF0A0E17);
  static const _cyan = Color(0xFF00F0FF);
  static const _purple = Color(0xFF6B00FF);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NEONCRED',
      debugShowCheckedModeBanner: false,

      // Cyberpunk dark theme
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: _cyan,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _cyan,
          secondary: _purple,
          surface: Color(0xFF1A1F2E),
          onPrimary: Color(0xFF0A0E17),
          onSecondary: Colors.white,
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.shareTechMonoTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: _bg,
          elevation: 0,
          titleTextStyle: GoogleFonts.orbitron(
            color: _cyan,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
          iconTheme: const IconThemeData(color: _cyan),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1F2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _cyan.withOpacity(0.3)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1A1F2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _cyan.withOpacity(0.3)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0A0E17),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _cyan.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _cyan),
          ),
          labelStyle: const TextStyle(color: Color(0xFF00F0FF)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _cyan,
            foregroundColor: _bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.orbitron(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        useMaterial3: true,
      ),

      // GoRouter configuration
      routerConfig: appRouter,
    );
  }
}
