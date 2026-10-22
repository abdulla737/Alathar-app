import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'prayer_store.dart';
import 'sample_data.dart' show LText;

/// Places across the Emirates checked for rain (UAE users only).
class UaeRainPlace {
  final LText name;
  final double lat;
  final double lng;
  const UaeRainPlace(this.name, this.lat, this.lng);
}

const uaeRainPlaces = <UaeRainPlace>[
  UaeRainPlace(LText(ar: 'أبوظبي', en: 'Abu Dhabi', ur: 'ابوظہبی'), 24.454, 54.377),
  UaeRainPlace(LText(ar: 'العين', en: 'Al Ain', ur: 'العین'), 24.208, 55.745),
  UaeRainPlace(LText(ar: 'الرويس', en: 'Ruwais', ur: 'رویس'), 24.110, 52.730),
  UaeRainPlace(LText(ar: 'مدينة زايد', en: 'Madinat Zayed', ur: 'مدینہ زاید'), 23.685, 53.705),
  UaeRainPlace(LText(ar: 'ليوا', en: 'Liwa', ur: 'لیوا'), 23.133, 53.772),
  UaeRainPlace(LText(ar: 'دبي', en: 'Dubai', ur: 'دبئی'), 25.205, 55.271),
  UaeRainPlace(LText(ar: 'حتا', en: 'Hatta', ur: 'حتّا'), 24.796, 56.117),
  UaeRainPlace(LText(ar: 'الشارقة', en: 'Sharjah', ur: 'شارجہ'), 25.346, 55.421),
  UaeRainPlace(LText(ar: 'الذيد', en: 'Al Dhaid', ur: 'الذید'), 25.288, 55.881),
  UaeRainPlace(LText(ar: 'عجمان', en: 'Ajman', ur: 'عجمان'), 25.405, 55.514),
  UaeRainPlace(LText(ar: 'أم القيوين', en: 'Umm Al Quwain', ur: 'ام القوین'), 25.565, 55.555),
  UaeRainPlace(LText(ar: 'رأس الخيمة', en: 'Ras Al Khaimah', ur: 'راس الخیمہ'), 25.801, 55.976),
  UaeRainPlace(LText(ar: 'جبل جيس', en: 'Jebel Jais', ur: 'جبل جیس'), 25.950, 56.130),
  UaeRainPlace(LText(ar: 'مسافي', en: 'Masafi', ur: 'مسافی'), 25.301, 56.166),
  UaeRainPlace(LText(ar: 'دبا', en: 'Dibba', ur: 'دبا'), 25.620, 56.270),
  UaeRainPlace(LText(ar: 'خورفكان', en: 'Khor Fakkan', ur: 'خورفکان'), 25.339, 56.356),
  UaeRainPlace(LText(ar: 'الفجيرة', en: 'Fujairah', ur: 'فجیرہ'), 25.129, 56.327),
  UaeRainPlace(LText(ar: 'كلباء', en: 'Kalba', ur: 'کلباء'), 25.074, 56.355),
];

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
/// changes, and at most every 60 minutes after that. Without internet the
/// prayer card simply shows no weather.
class WeatherStore extends ChangeNotifier {
  WeatherStore._();
  static final WeatherStore instance = WeatherStore._();

  WeatherNow? now;

  /// Places in [uaeRainPlaces] where rain is likely right now (model data,
  /// not radar). Empty outside the UAE or when it is dry everywhere.
  List<UaeRainPlace> uaeRain = const [];
  DateTime? _uaeFetched;
  bool _uaeLoading = false;
  static const uaeRefreshEvery = Duration(minutes: 30);

  /// The prayer place is in the UAE (by country, or inside its borders' box).
  bool get inUae {
    final p = PrayerStore.instance;
    if (!p.hasLocation) return false;
    if (p.country == 'AE') return true;
    return p.lat! > 22.5 && p.lat! < 26.3 && p.lng! > 51.5 && p.lng! < 56.5;
  }
  String _place = '';
  bool _loading = false;
  Timer? _timer;

  static const refreshEvery = Duration(minutes: 60);

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
    uaeRain = const [];
    _uaeFetched = null;
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
    _refreshUae(force: force);
    await _refreshHere(force: force);
  }

  /// Rain across the Emirates: one request for all the places.
  Future<void> _refreshUae({bool force = false}) async {
    if (!inUae) {
      if (uaeRain.isNotEmpty) {
        uaeRain = const [];
        notifyListeners();
      }
      return;
    }
    final last = _uaeFetched;
    if (_uaeLoading ||
        (!force && last != null && DateTime.now().difference(last) < uaeRefreshEvery)) {
      return;
    }
    _uaeLoading = true;
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': uaeRainPlaces.map((e) => e.lat.toStringAsFixed(3)).join(','),
        'longitude': uaeRainPlaces.map((e) => e.lng.toStringAsFixed(3)).join(','),
        'current': 'weather_code,precipitation',
      });
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      final list = body is List ? body : [body];
      final raining = <UaeRainPlace>[];
      for (var i = 0; i < list.length && i < uaeRainPlaces.length; i++) {
        final cur = (list[i] as Map<String, dynamic>)['current'] as Map<String, dynamic>?;
        if (cur == null) continue;
        final code = (cur['weather_code'] as num?)?.toInt() ?? 0;
        final mm = (cur['precipitation'] as num?)?.toDouble() ?? 0;
        if (kindFor(code) == WeatherKind.rain || mm > 0) raining.add(uaeRainPlaces[i]);
      }
      uaeRain = raining;
      _uaeFetched = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('UAE rain unavailable: $e');
    } finally {
      _uaeLoading = false;
    }
  }

  Future<void> _refreshHere({bool force = false}) async {
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
