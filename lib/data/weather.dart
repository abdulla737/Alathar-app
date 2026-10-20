import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'prayer_store.dart';

/// What the prayer card's sky shows.
enum WeatherKind { clear, cloudy, rain }

class WeatherNow {
  final WeatherKind kind;
  final bool isDay;
  final double temperature; // °C
  final DateTime fetched;
  const WeatherNow(this.kind, this.isDay, this.temperature, this.fetched);
}

/// Current weather at the prayer place, from Open-Meteo (free, no account
/// or key: https://open-meteo.com). Fetched when the place is set or
/// changes, and at most every 30 minutes after that. Without internet the
/// prayer card simply shows no weather.
class WeatherStore extends ChangeNotifier {
  WeatherStore._();
  static final WeatherStore instance = WeatherStore._();

  WeatherNow? now;
  String _place = '';
  bool _loading = false;
  Timer? _timer;

  static const refreshEvery = Duration(minutes: 30);

  /// Starts following the prayer place. Call once at startup.
  void start() {
    PrayerStore.instance.addListener(_placeChanged);
    _placeChanged();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => refresh());
  }

  void _placeChanged() {
    final p = PrayerStore.instance;
    final key = '${p.lat}|${p.lng}';
    if (key == _place) return;
    _place = key;
    now = null;
    notifyListeners();
    refresh(force: true);
  }

  /// WMO weather codes → our three skies.
  /// 0–1 clear; 2–3 cloud, 45/48 fog, snow → cloudy; drizzle, rain,
  /// showers and thunderstorms → rain.
  static WeatherKind kindFor(int code) {
    if (code <= 1) return WeatherKind.clear;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95) {
      return WeatherKind.rain;
    }
    return WeatherKind.cloudy;
  }

  Future<void> refresh({bool force = false}) async {
    final p = PrayerStore.instance;
    if (!p.hasLocation || _loading) return;
    final last = now?.fetched;
    if (!force && last != null && DateTime.now().difference(last) < refreshEvery) return;
    _loading = true;
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': p.lat!.toStringAsFixed(3),
        'longitude': p.lng!.toStringAsFixed(3),
        'current': 'temperature_2m,weather_code,is_day',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return;
      final cur = (jsonDecode(res.body) as Map<String, dynamic>)['current'] as Map<String, dynamic>?;
      if (cur == null) return;
      now = WeatherNow(
        kindFor((cur['weather_code'] as num).toInt()),
        (cur['is_day'] as num?)?.toInt() != 0,
        (cur['temperature_2m'] as num).toDouble(),
        DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Weather unavailable: $e');
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
