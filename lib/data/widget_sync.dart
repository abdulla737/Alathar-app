import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import 'app_settings.dart';
import 'content_store.dart';
import 'prayer_store.dart';
import 'prayer_times.dart';
import 'quran.dart';
import 'user_store.dart';

/// Sends what the iPhone widgets show (Lock Screen and Home Screen) to the
/// widget extension: the next prayers, today's hadith and Qur'an wird.
///
/// The data goes into the shared App Group, read by ios/AlatharWidget.
/// Updates are sent when the app opens or resumes and whenever prayer
/// times, the hadith progress, Qur'an pages or the language change.
class WidgetSync with WidgetsBindingObserver {
  WidgetSync._();
  static final WidgetSync instance = WidgetSync._();

  static const _channel = MethodChannel('alathar/widget');
  Timer? _debounce;
  bool _started = false;

  static bool get _supported => !kIsWeb && Platform.isIOS;

  void start() {
    if (!_supported || _started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    for (final l in <Listenable>[
      PrayerStore.instance,
      UserStore.instance,
      QuranStore.instance,
      AppSettings.instance,
      ContentStore.instance,
    ]) {
      l.addListener(schedule);
    }
    schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed || state == AppLifecycleState.paused) {
      schedule();
    }
  }

  /// Sends an update shortly (several changes in a row send one update).
  void schedule() {
    if (!_supported) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), push);
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  Map<String, Object?> _data() {
    final now = DateTime.now();
    final prayers = <Map<String, Object>>[];
    final store = PrayerStore.instance;
    for (var offset = 0; offset < 3; offset++) {
      final day = DateTime(now.year, now.month, now.day + offset);
      final d = store.dayOf(day);
      if (d == null) continue;
      for (final p in Prayer.values) {
        if (p == Prayer.sunrise) continue;
        final name = p == Prayer.dhuhr && day.weekday == DateTime.friday
            ? S.t('prayer_jumuah')
            : S.t('prayer_${p.name}');
        prayers.add({'n': name, 't': d[p].millisecondsSinceEpoch / 1000});
      }
    }

    String hadith = '';
    bool hadithDone = false;
    try {
      final h = ContentStore.instance.hadithOfToday();
      hadith = S.isArabic || h.translation.isEmpty ? h.arabic : h.translation;
      hadith = hadith.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (hadith.length > 160) hadith = '${hadith.substring(0, 160)}…';
      hadithDone = UserStore.instance.readToday(h.id);
    } catch (_) {}

    return {
      'lang': S.lang,
      'day': '${now.year}-${_two(now.month)}-${_two(now.day)}',
      'city': store.placeName?.v,
      'prayers': prayers,
      'hadith': hadith,
      'hadithDone': hadithDone,
      'quranRead': QuranStore.instance.pagesReadToday,
      'quranGoal': AppSettings.instance.quranPagesPerDay,
      'labels': {
        'next': S.t('prayer_next'),
        'in': S.t('prayer_in'),
        'open': S.t('widget_open_app'),
        'wird': S.t('widget_wird'),
        'quran': S.t('widget_quran'),
        'hadith': S.t('widget_hadith'),
        'pages': S.t('widget_pages'),
      },
    };
  }

  Future<void> push() async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod('update', jsonEncode(_data()));
    } catch (e) {
      debugPrint('Widget update skipped: $e');
    }
  }
}
