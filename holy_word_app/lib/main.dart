import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:holy_word_app/l10n/app_localizations.dart';
import 'core/constants.dart';
import 'core/app_theme.dart';
import 'core/providers/language_provider.dart';
import 'features/onboarding/presentation/splash_screen.dart';

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for Desktop and Web
  if (kIsWeb) {
    // Web initialization
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop initialization
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize Supabase
  // Initialize Supabase in background to avoid blocking startup
  Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  ).then((_) {
    debugPrint('Supabase initialized successfully');
  }).catchError((e) {
    debugPrint('Supabase initialization failed: $e');
  });

  runApp(const ProviderScope(child: HolyWordApp()));
}

class HolyWordApp extends ConsumerWidget {
  const HolyWordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Holy Word App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: Locale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('te'), // Telugu
      ],
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
