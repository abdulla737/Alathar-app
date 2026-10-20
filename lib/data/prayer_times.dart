import 'dart:math' as math;

/// The five prayers plus sunrise (shown in the table, not a prayer).
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Calculation methods (twilight angles and minute adjustments), the same
/// values the widely used `adhan` libraries use.
enum PrayerMethod {
  dubai,
  ummAlQura,
  qatar,
  kuwait,
  karachi,
  egyptian,
  mwl,
  isna,
  singapore,
  turkey,
}

class _Params {
  final double fajrAngle;
  final double? ishaAngle; // null → [ishaMinutes] after Maghrib
  final int ishaMinutes;
  final Map<Prayer, int> adjust; // minutes added after calculating
  const _Params(this.fajrAngle, this.ishaAngle,
      {this.ishaMinutes = 0, this.adjust = const {}});
}

const Map<PrayerMethod, _Params> _params = {
  PrayerMethod.dubai: _Params(18.2, 18.2, adjust: {
    Prayer.sunrise: -3,
    Prayer.dhuhr: 3,
    Prayer.asr: 3,
    Prayer.maghrib: 3,
  }),
  PrayerMethod.ummAlQura: _Params(18.5, null, ishaMinutes: 90),
  PrayerMethod.qatar: _Params(18, null, ishaMinutes: 90),
  PrayerMethod.kuwait: _Params(18, 17.5),
  PrayerMethod.karachi: _Params(18, 18, adjust: {Prayer.dhuhr: 1}),
  PrayerMethod.egyptian: _Params(19.5, 17.5, adjust: {Prayer.dhuhr: 1}),
  PrayerMethod.mwl: _Params(18, 17, adjust: {Prayer.dhuhr: 1}),
  PrayerMethod.isna: _Params(15, 15, adjust: {Prayer.dhuhr: 1}),
  PrayerMethod.singapore: _Params(20, 18, adjust: {Prayer.dhuhr: 1}),
  PrayerMethod.turkey: _Params(18, 17, adjust: {
    Prayer.sunrise: -7,
    Prayer.dhuhr: 5,
    Prayer.asr: 4,
    Prayer.maghrib: 7,
  }),
};

/// One day's times, in the phone's local time, rounded to the minute.
class PrayerDay {
  final DateTime date; // the day they are for (local, midnight)
  final Map<Prayer, DateTime> times;
  const PrayerDay(this.date, this.times);

  DateTime operator [](Prayer p) => times[p]!;
}

/// Works out prayer times on the phone (no internet), from the sun's
/// position: Fajr/Isha by twilight angle, sunrise/Maghrib at −0.833°, Dhuhr
/// at solar noon, Asr when an object's shadow is 1× (or 2× for Hanafi) its
/// length plus its noon shadow. Where twilight never ends (far north in
/// summer) Fajr and Isha use the middle of the night.
class PrayerCalculator {
  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;
  static double _fix(double a, double b) => a - b * (a / b).floorToDouble();

  /// Sun declination (degrees) and equation of time (hours) for a Julian day.
  static (double, double) _sun(double jd) {
    final d = jd - 2451545.0;
    final g = _fix(357.529 + 0.98560028 * d, 360);
    final q = _fix(280.459 + 0.98564736 * d, 360);
    final l = _fix(q + 1.915 * math.sin(_rad(g)) + 0.020 * math.sin(_rad(2 * g)), 360);
    final e = 23.439 - 0.00000036 * d;
    final ra = _deg(math.atan2(math.cos(_rad(e)) * math.sin(_rad(l)), math.cos(_rad(l)))) / 15;
    var eqt = q / 15 - _fix(ra, 24);
    if (eqt > 12) eqt -= 24;
    if (eqt < -12) eqt += 24;
    final decl = _deg(math.asin(math.sin(_rad(e)) * math.sin(_rad(l))));
    return (decl, eqt);
  }

  static double _julian(int y, int m, int day) {
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + a ~/ 4;
    return (365.25 * (y + 4716)).floorToDouble() +
        (30.6001 * (m + 1)).floorToDouble() +
        day +
        b -
        1524.5;
  }

  /// Times for [date] (its year/month/day) at [lat], [lng]. Returns null when
  /// the sun doesn't rise or set that day (polar day / night).
  static PrayerDay? compute({
    required DateTime date,
    required double lat,
    required double lng,
    required PrayerMethod method,
    bool hanafi = false,
  }) {
    final p = _params[method]!;
    final jd = _julian(date.year, date.month, date.day) - lng / 360;

    double noon(double t) => _fix(12 - _sun(jd + t / 24).$2, 24);

    // Time (local solar hours) when the sun is [angle]° below the horizon,
    // before noon if [morning]. NaN when it never gets there.
    double atAngle(double angle, double t, bool morning) {
      final decl = _sun(jd + t / 24).$1;
      final c = (-math.sin(_rad(angle)) - math.sin(_rad(decl)) * math.sin(_rad(lat))) /
          (math.cos(_rad(decl)) * math.cos(_rad(lat)));
      if (c.abs() > 1) return double.nan;
      final h = _deg(math.acos(c)) / 15;
      final n = noon(t);
      return morning ? n - h : n + h;
    }

    double asr(double t) {
      final decl = _sun(jd + t / 24).$1;
      final factor = hanafi ? 2.0 : 1.0;
      final a = -_deg(math.atan(1 / (factor + math.tan(_rad((lat - decl).abs())))));
      return atAngle(a, t, false);
    }

    final ishaAngle = p.ishaAngle;
    var t = <Prayer, double>{
      Prayer.fajr: 5,
      Prayer.sunrise: 6,
      Prayer.dhuhr: 12,
      Prayer.asr: 13,
      Prayer.maghrib: 18,
      Prayer.isha: 18,
    };
    var last = t;
    // A few rounds: each uses the sun's position at the previous estimate.
    for (var i = 0; i < 3; i++) {
      final n = <Prayer, double>{
        Prayer.fajr: atAngle(p.fajrAngle, t[Prayer.fajr]!, true),
        Prayer.sunrise: atAngle(0.833, t[Prayer.sunrise]!, true),
        Prayer.dhuhr: noon(t[Prayer.dhuhr]!),
        Prayer.asr: asr(t[Prayer.asr]!),
        Prayer.maghrib: atAngle(0.833, t[Prayer.maghrib]!, false),
        Prayer.isha: ishaAngle == null ? 0 : atAngle(ishaAngle, t[Prayer.isha]!, false),
      };
      t = {for (final e in n.entries) e.key: e.value.isNaN ? t[e.key]! : e.value};
      last = n;
    }
    if (last[Prayer.sunrise]!.isNaN || last[Prayer.maghrib]!.isNaN || last[Prayer.asr]!.isNaN) {
      return null;
    }

    // Far north in summer: never later than the middle of the night.
    final sunrise = last[Prayer.sunrise]!;
    final maghrib = last[Prayer.maghrib]!;
    final night = 24 - (maghrib - sunrise);
    var fajr = last[Prayer.fajr]!;
    final safeFajr = sunrise - night / 2;
    if (fajr.isNaN || fajr < safeFajr) fajr = safeFajr;
    double isha;
    if (ishaAngle == null) {
      isha = maghrib + p.ishaMinutes / 60;
    } else {
      isha = last[Prayer.isha]!;
      final safeIsha = maghrib + night / 2;
      if (isha.isNaN || isha > safeIsha) isha = safeIsha;
    }

    final solar = <Prayer, double>{
      Prayer.fajr: fajr,
      Prayer.sunrise: sunrise,
      Prayer.dhuhr: last[Prayer.dhuhr]!,
      Prayer.asr: last[Prayer.asr]!,
      Prayer.maghrib: maghrib,
      Prayer.isha: isha,
    };

    final dayUtc = DateTime.utc(date.year, date.month, date.day);
    final times = <Prayer, DateTime>{};
    for (final e in solar.entries) {
      // Local solar time → UTC, plus the method's minute adjustment.
      final hours = e.value - lng / 15 + (p.adjust[e.key] ?? 0) / 60;
      final seconds = (hours * 3600).round();
      final minutes = ((seconds + 30) / 60).floor(); // nearest minute
      times[e.key] = dayUtc.add(Duration(minutes: minutes)).toLocal();
    }
    return PrayerDay(DateTime(date.year, date.month, date.day), times);
  }
}
