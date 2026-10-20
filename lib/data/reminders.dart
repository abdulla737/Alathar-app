import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/strings.dart';
import '../screens/friday_screen.dart';
import 'app_settings.dart';
import 'prayer_store.dart';
import 'prayer_times.dart';

/// Lets a tapped notification open a page (see [Reminders]).
final appNavigatorKey = GlobalKey<NavigatorState>();

/// The Settings «التذكيرات» switches as phone notifications, which arrive
/// even when the app is closed. Scheduled on the phone (no server) for the
/// next 7 days, timed by today's prayer times when a place is set:
///
/// - hadith   حديث اليوم        Fajr + 15 min
/// - morning  أذكار الصباح      Fajr + 5 min
/// - evening  أذكار المساء      Asr + 5 min
/// - friday   سنن يوم الجمعة   Friday 9:00, and an hour before Maghrib
///                              (the last hour of Friday, for du'a)
/// - nudges   تذكير بالذكر      10:00, 13:30 and 21:00
///
/// Everything is rescheduled when a switch, the language or the prayer
/// place changes, and each time the app opens (so the 7 days roll forward).
class Reminders {
  Reminders._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static Timer? _debounce;

  static const _channelId = 'alathar_reminders';
  static const _days = 7;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Call once at startup, after settings and prayer data are loaded.
  static Future<void> init() async {
    if (!_supported) return;
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) => _open(r.payload),
      );
      _ready = true;

      // App opened by tapping a notification while it was closed.
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch!.notificationResponse?.payload;
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(payload));
      }

      AppSettings.instance.addListener(_changed);
      PrayerStore.instance.addListener(_changed);
      await sync(askPermission: AppSettings.instance.onboardingDone);
    } catch (e) {
      debugPrint('Reminders init failed: $e');
    }
  }

  static String _last = '';

  /// What the reminders depend on; other setting changes (text size…) don't
  /// reschedule anything.
  static String _signature() {
    final s = AppSettings.instance;
    final p = PrayerStore.instance;
    return [
      for (final e in s.reminders.entries) '${e.key}=${e.value}',
      s.language,
      p.lat,
      p.lng,
      p.methodKey,
      p.asrKey,
    ].join('|');
  }

  static void _changed() {
    if (_signature() == _last) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () => sync(askPermission: true));
  }

  static void _open(String? payload) {
    final nav = appNavigatorKey.currentState;
    if (nav == null) return;
    if (payload == 'friday') {
      nav.push(MaterialPageRoute(builder: (_) => const FridayScreen()));
    }
    // Other reminders just open the app on the Today page.
  }

  static bool _on(String key) => AppSettings.instance.reminders[key] ?? false;

  static Future<bool> _askPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  /// Cancels and re-creates every reminder from the current settings.
  static Future<void> sync({bool askPermission = false}) async {
    if (!_supported || !_ready) return;
    _last = _signature();
    try {
      await _plugin.cancelAll();
      final keys = ['hadith', 'morning', 'evening', 'friday', 'nudges'];
      if (!keys.any(_on)) return;
      if (askPermission) await _askPermission();

      final now = DateTime.now();
      var count = 0;
      for (var d = 0; d < _days; d++) {
        final day = DateTime(now.year, now.month, now.day + d);
        final times = PrayerStore.instance.dayOf(day);
        DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
        final fajr = times?[Prayer.fajr] ?? at(5, 0);
        final asr = times?[Prayer.asr] ?? at(15, 30);
        final maghrib = times?[Prayer.maghrib] ?? at(18, 0);

        // id = day × 10 + slot, so every reminder has its own id.
        Future<void> add(int slot, DateTime when, String key, String title, String body) async {
          if (!when.isAfter(now)) return;
          await _schedule(d * 10 + slot, when, title, body, key);
          count++;
        }

        if (_on('morning')) {
          await add(1, fajr.add(const Duration(minutes: 5)), 'morning',
              S.t('n_morning_title'), S.t('n_morning_body'));
        }
        if (_on('hadith')) {
          await add(2, fajr.add(const Duration(minutes: 15)), 'hadith',
              S.t('n_hadith_title'), S.t('n_hadith_body'));
        }
        if (_on('evening')) {
          await add(3, asr.add(const Duration(minutes: 5)), 'evening',
              S.t('n_evening_title'), S.t('n_evening_body'));
        }
        if (_on('friday') && day.weekday == DateTime.friday) {
          await add(4, at(9, 0), 'friday', S.t('friday_title'), S.t('n_friday_body'));
          await add(5, maghrib.subtract(const Duration(hours: 1)), 'friday',
              S.t('n_friday_hour_title'), S.t('n_friday_hour_body'));
        }
        if (_on('nudges')) {
          final slots = [at(10, 0), at(13, 30), at(21, 0)];
          for (var i = 0; i < slots.length; i++) {
            // A different dhikr each time.
            final n = (d * slots.length + i) % 5 + 1;
            await add(6 + i, slots[i], 'nudges', S.t('n_nudge_title'), S.t('n_nudge_$n'));
          }
        }
      }
      debugPrint('Reminders: $count scheduled for the next $_days days');
    } catch (e) {
      debugPrint('Reminders sync failed: $e');
    }
  }

  static Future<void> _schedule(
      int id, DateTime when, String title, String body, String payload) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      // An exact moment in time (UTC), so the phone's time zone is respected.
      tz.TZDateTime.from(when.toUtc(), tz.UTC),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          S.t('reminders_channel'),
          channelDescription: S.t('reminders_channel_desc'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Inexact is fine for reminders and needs no "alarms" permission.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }
}
