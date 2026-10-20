import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prayer_places.dart';
import 'prayer_times.dart';
import 'sample_data.dart' show LText;

/// Why locating the phone didn't work, so the screen can say what to do.
enum LocateResult { ok, serviceOff, denied, deniedForever, failed }

/// Prayer-time settings and today's times. Saved on the phone; the times
/// are calculated on the phone, so they work offline once a place is set.
class PrayerStore extends ChangeNotifier {
  PrayerStore._();
  static final PrayerStore instance = PrayerStore._();

  SharedPreferences? _prefs;

  double? lat;
  double? lng;

  /// 'gps' (the phone's location) or 'city' (picked from the list).
  String source = '';
  String? cityId;

  /// Country code used for the automatic method / Asr choice.
  String country = '';

  /// 'auto' or a [PrayerMethod] name.
  String methodKey = 'auto';

  /// 'auto', 'standard' (Shafi'i, Maliki, Hanbali) or 'hanafi'.
  String asrKey = 'auto';

  bool locating = false;

  bool get hasLocation => lat != null && lng != null;

  PrayerMethod get autoMethod => methodForCountry(country);
  PrayerMethod get method => methodKey == 'auto'
      ? autoMethod
      : PrayerMethod.values.firstWhere((m) => m.name == methodKey,
          orElse: () => autoMethod);

  bool get hanafi => asrKey == 'auto' ? hanafiForCountry(country) : asrKey == 'hanafi';

  /// Name to show for the place: the city, "near <city>", or "my location".
  LText? get placeName {
    if (!hasLocation) return null;
    if (source == 'city') return prayerCityById(cityId)?.name;
    return nearestCity(lat!, lng!)?.name;
  }

  // Storage keys
  static const _kLat = 'prayer_lat';
  static const _kLng = 'prayer_lng';
  static const _kSource = 'prayer_source';
  static const _kCity = 'prayer_city';
  static const _kCountry = 'prayer_country';
  static const _kMethod = 'prayer_method';
  static const _kAsr = 'prayer_asr';

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    lat = p.getDouble(_kLat);
    lng = p.getDouble(_kLng);
    source = p.getString(_kSource) ?? '';
    cityId = p.getString(_kCity);
    country = p.getString(_kCountry) ?? '';
    methodKey = p.getString(_kMethod) ?? 'auto';
    asrKey = p.getString(_kAsr) ?? 'auto';
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    if (lat != null) p.setDouble(_kLat, lat!);
    if (lng != null) p.setDouble(_kLng, lng!);
    p.setString(_kSource, source);
    if (cityId != null) {
      p.setString(_kCity, cityId!);
    } else {
      p.remove(_kCity);
    }
    p.setString(_kCountry, country);
    p.setString(_kMethod, methodKey);
    p.setString(_kAsr, asrKey);
  }

  void _changed() {
    _cache.clear();
    _save();
    notifyListeners();
  }

  void setCity(PrayerCity c) {
    lat = c.lat;
    lng = c.lng;
    source = 'city';
    cityId = c.id;
    country = c.country;
    _changed();
  }

  void setMethod(String key) {
    methodKey = key;
    _changed();
  }

  void setAsr(String key) {
    asrKey = key;
    _changed();
  }

  /// Asks for the phone's location (once, low accuracy is enough).
  Future<LocateResult> useMyLocation() async {
    locating = true;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return LocateResult.serviceOff;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return LocateResult.deniedForever;
      if (perm == LocationPermission.denied) return LocateResult.denied;

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
      } catch (_) {
        if (!kIsWeb) pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return LocateResult.failed;

      lat = pos.latitude;
      lng = pos.longitude;
      source = 'gps';
      final near = nearestCity(pos.latitude, pos.longitude, maxKm: 150);
      cityId = null;
      country = near?.country ?? regionOf(pos.latitude, pos.longitude);
      _changed();
      return LocateResult.ok;
    } catch (e) {
      debugPrint('Location failed: $e');
      return LocateResult.failed;
    } finally {
      locating = false;
      notifyListeners();
    }
  }

  static Future<void> openAppSettings() => Geolocator.openAppSettings();
  static Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  // ------------------------------------------------------------ times

  final Map<String, PrayerDay?> _cache = {};

  /// Times for the day of [day] (null without a place, or near the poles).
  PrayerDay? dayOf(DateTime day) {
    if (!hasLocation) return null;
    final key = '${day.year}-${day.month}-${day.day}';
    return _cache.putIfAbsent(
      key,
      () => PrayerCalculator.compute(
        date: day,
        lat: lat!,
        lng: lng!,
        method: method,
        hanafi: hanafi,
      ),
    );
  }

  /// The next prayer after [now] (sunrise is skipped), looking into
  /// tomorrow after Isha.
  (Prayer, DateTime)? next(DateTime now) {
    for (final offset in [0, 1]) {
      final d = dayOf(DateTime(now.year, now.month, now.day + offset));
      if (d == null) continue;
      for (final p in Prayer.values) {
        if (p == Prayer.sunrise) continue;
        if (d[p].isAfter(now)) return (p, d[p]);
      }
    }
    return null;
  }

  /// The prayer whose time it is now (the last one that has started today).
  Prayer? current(DateTime now) {
    final d = dayOf(now);
    if (d == null) return null;
    Prayer? cur;
    for (final p in Prayer.values) {
      if (p == Prayer.sunrise) continue;
      if (!d[p].isAfter(now)) cur = p;
    }
    return cur;
  }
}
