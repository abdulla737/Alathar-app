import 'dart:math' as math;

import 'prayer_times.dart';
import 'sample_data.dart' show LText;

/// A city users can pick when they don't share their location.
class PrayerCity {
  final String id;
  final LText name;
  final String country; // ISO code, used to choose the calculation method
  final double lat;
  final double lng;
  const PrayerCity(this.id, this.name, this.country, this.lat, this.lng);
}

const prayerCities = <PrayerCity>[
  // UAE
  PrayerCity('dubai', LText(ar: 'دبي', en: 'Dubai', ur: 'دبئی'), 'AE', 25.2048, 55.2708),
  PrayerCity('abudhabi', LText(ar: 'أبوظبي', en: 'Abu Dhabi', ur: 'ابوظہبی'), 'AE', 24.4539, 54.3773),
  PrayerCity('sharjah', LText(ar: 'الشارقة', en: 'Sharjah', ur: 'شارجہ'), 'AE', 25.3463, 55.4209),
  PrayerCity('ajman', LText(ar: 'عجمان', en: 'Ajman', ur: 'عجمان'), 'AE', 25.4052, 55.5136),
  PrayerCity('rak', LText(ar: 'رأس الخيمة', en: 'Ras Al Khaimah', ur: 'راس الخیمہ'), 'AE', 25.8007, 55.9762),
  PrayerCity('fujairah', LText(ar: 'الفجيرة', en: 'Fujairah', ur: 'فجیرہ'), 'AE', 25.1288, 56.3265),
  PrayerCity('alain', LText(ar: 'العين', en: 'Al Ain', ur: 'العین'), 'AE', 24.2075, 55.7447),
  // Saudi Arabia
  PrayerCity('makkah', LText(ar: 'مكة المكرمة', en: 'Makkah', ur: 'مکہ مکرمہ'), 'SA', 21.4225, 39.8262),
  PrayerCity('madinah', LText(ar: 'المدينة المنورة', en: 'Madinah', ur: 'مدینہ منورہ'), 'SA', 24.4672, 39.6111),
  PrayerCity('riyadh', LText(ar: 'الرياض', en: 'Riyadh', ur: 'ریاض'), 'SA', 24.7136, 46.6753),
  PrayerCity('jeddah', LText(ar: 'جدة', en: 'Jeddah', ur: 'جدہ'), 'SA', 21.4858, 39.1925),
  PrayerCity('dammam', LText(ar: 'الدمام', en: 'Dammam', ur: 'دمام'), 'SA', 26.4207, 50.0888),
  // Gulf
  PrayerCity('doha', LText(ar: 'الدوحة', en: 'Doha', ur: 'دوحہ'), 'QA', 25.2854, 51.5310),
  PrayerCity('kuwait', LText(ar: 'الكويت', en: 'Kuwait City', ur: 'کویت'), 'KW', 29.3759, 47.9774),
  PrayerCity('manama', LText(ar: 'المنامة', en: 'Manama', ur: 'منامہ'), 'BH', 26.2285, 50.5860),
  PrayerCity('muscat', LText(ar: 'مسقط', en: 'Muscat', ur: 'مسقط'), 'OM', 23.5880, 58.3829),
  // Levant, Egypt, North Africa
  PrayerCity('cairo', LText(ar: 'القاهرة', en: 'Cairo', ur: 'قاہرہ'), 'EG', 30.0444, 31.2357),
  PrayerCity('amman', LText(ar: 'عمّان', en: 'Amman', ur: 'عمان'), 'JO', 31.9539, 35.9106),
  PrayerCity('alquds', LText(ar: 'القدس', en: 'Jerusalem (Al-Quds)', ur: 'القدس'), 'PS', 31.7767, 35.2345),
  PrayerCity('damascus', LText(ar: 'دمشق', en: 'Damascus', ur: 'دمشق'), 'SY', 33.5138, 36.2765),
  PrayerCity('baghdad', LText(ar: 'بغداد', en: 'Baghdad', ur: 'بغداد'), 'IQ', 33.3152, 44.3661),
  PrayerCity('casablanca', LText(ar: 'الدار البيضاء', en: 'Casablanca', ur: 'کاسابلانکا'), 'MA', 33.5731, -7.5898),
  // South Asia
  PrayerCity('karachi', LText(ar: 'كراتشي', en: 'Karachi', ur: 'کراچی'), 'PK', 24.8607, 67.0011),
  PrayerCity('lahore', LText(ar: 'لاهور', en: 'Lahore', ur: 'لاہور'), 'PK', 31.5204, 74.3587),
  PrayerCity('islamabad', LText(ar: 'إسلام آباد', en: 'Islamabad', ur: 'اسلام آباد'), 'PK', 33.6844, 73.0479),
  PrayerCity('delhi', LText(ar: 'دلهي', en: 'Delhi', ur: 'دہلی'), 'IN', 28.6139, 77.2090),
  PrayerCity('hyderabad', LText(ar: 'حيدر آباد', en: 'Hyderabad (India)', ur: 'حیدرآباد دکن'), 'IN', 17.3850, 78.4867),
  PrayerCity('dhaka', LText(ar: 'دكا', en: 'Dhaka', ur: 'ڈھاکہ'), 'BD', 23.8103, 90.4125),
  // Elsewhere
  PrayerCity('istanbul', LText(ar: 'إسطنبول', en: 'Istanbul', ur: 'استنبول'), 'TR', 41.0082, 28.9784),
  PrayerCity('kualalumpur', LText(ar: 'كوالالمبور', en: 'Kuala Lumpur', ur: 'کوالالمپور'), 'MY', 3.1390, 101.6869),
  PrayerCity('jakarta', LText(ar: 'جاكرتا', en: 'Jakarta', ur: 'جکارتہ'), 'ID', -6.2088, 106.8456),
  PrayerCity('london', LText(ar: 'لندن', en: 'London', ur: 'لندن'), 'GB', 51.5074, -0.1278),
  PrayerCity('newyork', LText(ar: 'نيويورك', en: 'New York', ur: 'نیو یارک'), 'US', 40.7128, -74.0060),
  PrayerCity('toronto', LText(ar: 'تورونتو', en: 'Toronto', ur: 'ٹورنٹو'), 'CA', 43.6532, -79.3832),
];

PrayerCity? prayerCityById(String? id) {
  for (final c in prayerCities) {
    if (c.id == id) return c;
  }
  return null;
}

/// Distance in km between two points (haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 6371 * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// The listed city nearest to a GPS position, if within [maxKm].
PrayerCity? nearestCity(double lat, double lng, {double maxKm = 60}) {
  PrayerCity? best;
  var bestKm = maxKm;
  for (final c in prayerCities) {
    final km = distanceKm(lat, lng, c.lat, c.lng);
    if (km <= bestKm) {
      best = c;
      bestKm = km;
    }
  }
  return best;
}

/// Rough country from GPS (offline, no address lookup) — only to choose a
/// sensible default method. Users can always pick the method themselves.
String regionOf(double lat, double lng) {
  bool box(double s, double n, double w, double e) =>
      lat >= s && lat <= n && lng >= w && lng <= e;
  if (box(24.4, 26.3, 50.7, 51.65)) return 'QA';
  if (box(25.5, 26.4, 50.3, 50.85)) return 'BH';
  if (box(22.5, 26.2, 51.5, 56.45)) return 'AE';
  if (box(28.5, 30.1, 46.5, 48.5)) return 'KW';
  if (box(16.6, 26.4, 52.0, 60.0)) return 'OM';
  if (box(16.0, 32.2, 34.5, 55.7)) return 'SA';
  if (box(22.0, 31.7, 25.0, 35.0)) return 'EG';
  if (box(36.0, 42.2, 26.0, 45.0)) return 'TR';
  if (box(5.0, 37.0, 60.0, 92.7)) return 'PK'; // South Asia (PK/IN/BD/AF)
  if (box(-11.0, 7.5, 95.0, 141.0)) return 'MY'; // MY/SG/ID/BN
  if (box(14.0, 72.0, -170.0, -50.0)) return 'US'; // North America
  return '';
}

/// Default calculation method for a country code.
PrayerMethod methodForCountry(String country) {
  switch (country) {
    case 'AE':
      return PrayerMethod.dubai;
    case 'SA':
    case 'BH':
    case 'YE':
      return PrayerMethod.ummAlQura;
    case 'QA':
      return PrayerMethod.qatar;
    case 'KW':
      return PrayerMethod.kuwait;
    case 'PK':
    case 'IN':
    case 'BD':
    case 'AF':
      return PrayerMethod.karachi;
    case 'EG':
      return PrayerMethod.egyptian;
    case 'TR':
      return PrayerMethod.turkey;
    case 'MY':
    case 'SG':
    case 'ID':
    case 'BN':
      return PrayerMethod.singapore;
    case 'US':
    case 'CA':
      return PrayerMethod.isna;
    default:
      return PrayerMethod.mwl;
  }
}

/// Hanafi Asr is the common default in South Asia.
bool hanafiForCountry(String country) =>
    const {'PK', 'IN', 'BD', 'AF'}.contains(country);
