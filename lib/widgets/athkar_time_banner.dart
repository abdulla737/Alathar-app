import 'dart:async';

import 'package:flutter/material.dart';

import '../data/content_store.dart';
import '../data/prayer_store.dart';
import '../data/prayer_times.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../screens/athkar_counter_screen.dart';
import '../screens/prayer_screen.dart';
import '../theme/app_theme.dart';
import 'prayer_widgets.dart';

/// Which athkar it is time for now, if any.
class AthkarWindow {
  final String slug; // 'prayer', or an athkar category: after_prayer, morning, evening, sleep
  final String titleKey; // «حان وقت …»
  final int seenId; // remembered for today once tapped (hides the strip)
  final Color background;
  final Color foreground;
  final Prayer? prayer; // for 'prayer': which one
  final DateTime? at; // for 'prayer': its time (Friday Dhuhr → Jumuah)
  const AthkarWindow(this.slug, this.titleKey, this.seenId, this.background, this.foreground,
      {this.prayer, this.at});
}

/// Today's windows, timed by the prayer times:
/// - from each adhan, 30 minutes (20 for Maghrib) → «حان وقت صلاة …»
///   (opens the prayer-times page)
/// - then, for 30 minutes → «بعد الصلاة»
/// - 30 min after Fajr until Dhuhr → «أذكار الصباح»
/// - 30 min after Asr until 10 pm → «أذكار المساء»
/// - 10 pm until midnight → «قبل النوم»
/// Prayer time, then "after prayer", win where windows overlap. Without a prayer place set,
/// typical times are used (Fajr 5:00, Dhuhr 12:15, Asr 15:30, Maghrib 18:00,
/// Isha 19:30).
AthkarWindow? athkarWindowAt(DateTime now) {
  DateTime at(int h, int m) => DateTime(now.year, now.month, now.day, h, m);
  final day = PrayerStore.instance.dayOf(now);
  final times = <Prayer, DateTime>{
    Prayer.fajr: day?[Prayer.fajr] ?? at(5, 0),
    Prayer.dhuhr: day?[Prayer.dhuhr] ?? at(12, 15),
    Prayer.asr: day?[Prayer.asr] ?? at(15, 30),
    Prayer.maghrib: day?[Prayer.maghrib] ?? at(18, 0),
    Prayer.isha: day?[Prayer.isha] ?? at(19, 30),
  };
  bool within(DateTime a, DateTime b) => !now.isBefore(a) && now.isBefore(b);
  const after = Duration(minutes: 30);

  for (final e in times.entries) {
    // How long «حان وقت الصلاة» shows before the after-prayer athkar.
    final prayerTime = Duration(minutes: e.key == Prayer.maghrib ? 20 : 30);
    if (within(e.value, e.value.add(prayerTime))) {
      return AthkarWindow('prayer', 'banner_prayer', 400 + e.key.index,
          AppColors.night, AppColors.nightGold,
          prayer: e.key, at: e.value);
    }
    if (within(e.value.add(prayerTime), e.value.add(prayerTime + after))) {
      return AthkarWindow('after_prayer', 'banner_after_prayer', 300 + e.key.index,
          AppColors.sandSoft, AppColors.goldDark);
    }
  }
  if (within(times[Prayer.fajr]!.add(after), times[Prayer.dhuhr]!)) {
    return const AthkarWindow('morning', 'banner_morning', 1, Color(0xFFFFF4D6), Color(0xFF7A5200));
  }
  if (within(times[Prayer.asr]!.add(after), at(22, 0))) {
    return const AthkarWindow('evening', 'banner_evening', 2, Color(0xFFE4E9F4), AppColors.night);
  }
  if (!now.isBefore(at(22, 0))) {
    return const AthkarWindow('sleep', 'banner_sleep', 4, Color(0xFF1F2A44), AppColors.nightGold);
  }
  return null;
}

/// Today page, under the prayer card: «حان وقت الأذكار بعد الصلاة» and the
/// like, title only. Tap → that athkar. Hidden once tapped for that window,
/// when that athkar is already finished today, and outside the windows.
class AthkarTimeBanner extends StatefulWidget {
  const AthkarTimeBanner({super.key});

  @override
  State<AthkarTimeBanner> createState() => _AthkarTimeBannerState();
}

class _AthkarTimeBannerState extends State<AthkarTimeBanner>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    // Re-checks the time every 30 minutes (also on every rebuild).
    _timer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _open(AthkarWindow w) {
    if (w.slug == 'prayer') {
      UserStore.instance.setAthkarSeenToday(w.seenId);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerScreen()));
      return;
    }
    final store = ContentStore.instance;
    final c = store.athkarCategoryBySlug(w.slug);
    UserStore.instance.setAthkarSeenToday(w.seenId);
    if (c == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AthkarCounterScreen(
        title: c.name.v,
        athkar: store.athkarIn(c.id),
        onFinished: () => UserStore.instance.setAthkarDoneToday(c.id),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([UserStore.instance, PrayerStore.instance, ContentStore.instance]),
      builder: (context, _) {
        final w = athkarWindowAt(DateTime.now());
        if (w == null) return const SizedBox.shrink();
        final user = UserStore.instance;
        if (user.athkarSeenToday(w.seenId)) return const SizedBox.shrink();
        String title;
        if (w.slug == 'prayer') {
          title = context.tr(w.titleKey, {'p': prayerName(context, w.prayer!, w.at)});
        } else {
          final c = ContentStore.instance.athkarCategoryBySlug(w.slug);
          if (c == null || ContentStore.instance.athkarIn(c.id).isEmpty) {
            return const SizedBox.shrink();
          }
          // Morning / evening / sleep: hide once finished today.
          if (w.slug != 'after_prayer' && user.athkarDoneToday(c.id)) {
            return const SizedBox.shrink();
          }
          title = context.tr(w.titleKey);
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Material(
            color: w.background,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(w),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    FadeTransition(
                      opacity: Tween(begin: 1.0, end: 0.35).animate(_pulse),
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(color: w.foreground, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (w.slug == 'prayer') ...[
                      Icon(Icons.mosque, color: w.foreground, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(title,
                          style: AppText.ui(
                              size: 15, weight: FontWeight.w700, color: w.foreground)),
                    ),
                    Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                        color: w.foreground, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
