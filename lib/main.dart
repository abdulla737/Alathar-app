import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_settings.dart';
import 'data/content_store.dart';
import 'data/content_sync.dart';
import 'data/prayer_store.dart';
import 'data/quran.dart';
import 'data/reminders.dart';
import 'data/weather.dart';
import 'data/widget_sync.dart';
import 'data/user_store.dart';
import 'l10n/strings.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved settings and favorites from the phone before showing the app.
  // Each step is time-limited and may fail on its own: the app must always
  // get past the logo screen, with defaults if something goes wrong.
  await _step('settings', AppSettings.instance.load);
  await _step('user', UserStore.instance.load);
  await _step('content', ContentStore.instance.load);
  await _step('prayer', PrayerStore.instance.load);
  await _step('quran', QuranStore.instance.load);

  runApp(AlatharApp(showOnboarding: !AppSettings.instance.onboardingDone));

  // Everything below runs after the first screen is showing.
  try {
    WeatherStore.instance.start(); // live weather for the prayer card
  } catch (e) {
    debugPrint('Weather start failed: $e');
  }
  // The Qur'an text (bundled), ready before the Qur'an tab is opened.
  unawaited(_step('quran text', QuranData.instance.ensureLoaded, seconds: 20));
  // Connect to Supabase, then check for new content in the background.
  unawaited(_step('supabase', ContentSync.init, seconds: 10)
      .then((_) => ContentSync.run()));
  // iPhone Lock Screen / Home Screen widgets.
  try {
    WidgetSync.instance.start();
  } catch (e) {
    debugPrint('Widget sync failed: $e');
  }
  // Phone notifications for the Settings reminders (work with the app closed).
  unawaited(_step('reminders', Reminders.init, seconds: 20));
}

/// Runs one start-up step; logs and moves on if it fails or takes too long.
Future<void> _step(String name, Future<void> Function() run, {int seconds = 5}) async {
  try {
    await run().timeout(Duration(seconds: seconds));
  } catch (e) {
    debugPrint('Start-up step "$name" skipped: $e');
  }
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
