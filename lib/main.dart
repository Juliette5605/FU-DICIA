// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/locale_manager.dart';
import 'screens/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← ajoute cet import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null); // ← ajoute cette ligne
  // ... le reste reste pareil

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final localeManager = LocaleManager();
  await localeManager.init();

  runApp(FuDiciaApp(localeManager: localeManager));
}

class FuDiciaApp extends StatelessWidget {
  final LocaleManager localeManager;
  const FuDiciaApp({super.key, required this.localeManager});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeManager,
      builder: (_, __) => MaterialApp(
        title: 'FU-DICIA',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: SplashScreen(localeManager: localeManager),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(AppColors.bgDark),
      colorScheme: const ColorScheme.dark(
        primary: Color(AppColors.primaryCyan),
        secondary: Color(AppColors.primaryGreen),
        error: Color(AppColors.primaryRed),
        surface: Color(AppColors.bgCard),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1BD6FF), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: const Color(0xFF1BD6FF).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1BD6FF), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF8B9BB4)),
        hintStyle: const TextStyle(color: Color(0xFF3D4F6A)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppColors.primaryCyan),
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}
