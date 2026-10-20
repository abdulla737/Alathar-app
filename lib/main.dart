import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_settings.dart';
import 'data/content_store.dart';
import 'data/content_sync.dart';
import 'data/prayer_store.dart';
import 'data/reminders.dart';
import 'data/weather.dart';
import 'data/user_store.dart';
import 'l10n/strings.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved settings and favorites from the phone before showing the app.
  await AppSettings.instance.load();
  await UserStore.instance.load();
  await ContentStore.instance.load();
  await PrayerStore.instance.load();
  WeatherStore.instance.start(); // live weather for the prayer card

  // Connect to Supabase, then check for new content in the background.
  // The app opens right away with what is already on the phone.
  await ContentSync.init();
  unawaited(ContentSync.run());

  runApp(AlatharApp(showOnboarding: !AppSettings.instance.onboardingDone));

  // Phone notifications for the Settings reminders (work with the app closed).
  unawaited(Reminders.init());
}

class AlatharApp extends StatefulWidget {
  /// Onboarding shows only on the very first launch.
  final bool showOnboarding;

  const AlatharApp({super.key, required this.showOnboarding});

  @override
  State<AlatharApp> createState() => _AlatharAppState();
}

class _AlatharAppState extends State<AlatharApp> {
  bool? _builtDark;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    // Rebuilds the app with the new locale (and text direction) whenever
    // the language changes (Arabic is the default), and in the new colors
    // when dark mode is switched.
    return ListenableBuilder(
      listenable: Listenable.merge([settings.languageNotifier, settings.darkNotifier]),
      builder: (context, _) {
        final lang = settings.language;
        final dark = settings.darkMode;
        AppColors.isDark = dark;
        if (_builtDark != null && _builtDark != dark) {
          // A fresh navigator so every page is built again in the new colors.
          appNavigatorKey = GlobalKey<NavigatorState>();
        }
        _builtDark = dark;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        ));
        return MaterialApp(
        key: ValueKey(dark),
        title: 'Alathar',
        navigatorKey: appNavigatorKey, // lets a tapped notification open a page
        debugShowCheckedModeBanner: false,
        locale: Locale(lang),
        supportedLocales: [for (final code in S.supported) Locale(code)],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: AppTheme.light(),
        home: widget.showOnboarding && !settings.onboardingDone
            ? const OnboardingScreen()
            : const HomeShell(),
        );
      },
    );
  }
}
