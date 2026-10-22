import 'dart:async';

import 'package:flutter/material.dart';

import '../data/content_store.dart';
import '../data/prayer_store.dart';
import '../data/prayer_times.dart';
import '../data/sample_data.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../screens/athkar_counter_screen.dart';
import '../screens/prayer_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'prayer_widgets.dart';

/// One moment of the day in «حان الوقت»: a prayer, the athkar after it,
/// or the morning / evening / sleep athkar.
class Occasion {
  /// 'prayer', 'after_prayer', 'morning', 'evening' or 'sleep'.
  final String kind;
  final Prayer? prayer; // for 'prayer' and 'after_prayer'
  final DateTime start;
  final DateTime day; // the date it belongs to (sleep after midnight → yesterday)
  const Occasion(this.kind, this.start, this.day, {this.prayer});

  /// Remembered as done under this key, e.g. "2026-10-22 after_dhuhr".
  String get key {
    final d = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final what = switch (kind) {
      'prayer' => prayer!.name,
      'after_prayer' => 'after_${prayer!.name}',
      _ => kind,
    };
    return '$d $what';
  }

  /// The athkar category opened for it (none for a prayer).
  String? get athkarSlug => kind == 'prayer' ? null : kind;
}

/// A day's occasions, in time order (prayer times from the chosen place;
/// typical times when none is set):
///   each adhan → «صلاة …» for 30 min (20 for Maghrib) → «أذكار بعد الصلاة»;
///   30 min after Fajr's after-prayer athkar → «أذكار الصباح»;
///   30 min after Asr's → «أذكار المساء»; 10 pm → «أذكار النوم».
List<Occasion> occasionsOf(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  DateTime at(int h, int m) => DateTime(day.year, day.month, day.day, h, m);
  final t = PrayerStore.instance.dayOf(day);
  final times = <Prayer, DateTime>{
    Prayer.fajr: t?[Prayer.fajr] ?? at(5, 0),
    Prayer.dhuhr: t?[Prayer.dhuhr] ?? at(12, 15),
    Prayer.asr: t?[Prayer.asr] ?? at(15, 30),
    Prayer.maghrib: t?[Prayer.maghrib] ?? at(18, 0),
    Prayer.isha: t?[Prayer.isha] ?? at(19, 30),
  };
  final list = <Occasion>[];
  for (final e in times.entries) {
    final prayerTime = Duration(minutes: e.key == Prayer.maghrib ? 20 : 30);
    list.add(Occasion('prayer', e.value, day, prayer: e.key));
    list.add(Occasion('after_prayer', e.value.add(prayerTime), day, prayer: e.key));
  }
  const after = Duration(minutes: 60);
  list.add(Occasion('morning', times[Prayer.fajr]!.add(after), day));
  list.add(Occasion('evening', times[Prayer.asr]!.add(after), day));
  list.add(Occasion('sleep', at(22, 0), day));
  list.sort((a, b) => a.start.compareTo(b.start));
  return list;
}

/// The occasion now (it stays until the next one starts) and the next one.
(Occasion, Occasion) occasionNow(DateTime now) {
  final all = [
    for (var d = -1; d <= 1; d++) ...occasionsOf(DateTime(now.year, now.month, now.day + d)),
  ]..sort((a, b) => a.start.compareTo(b.start));
  var i = all.lastIndexWhere((o) => !o.start.isAfter(now));
  if (i < 0) i = 0;
  return (all[i], all[(i + 1).clamp(0, all.length - 1)]);
}

/// Today page: «حان الوقت» — the current prayer or athkar, one card.
/// Tap → the prayer times, or that athkar. Done (✓) when the athkar are
/// finished, or «صليت» is tapped for a prayer; the ✓ stays until the next
/// occasion begins. Glows gently while not done.
class TimeNowCard extends StatefulWidget {
  const TimeNowCard({super.key});

  @override
  State<TimeNowCard> createState() => _TimeNowCardState();
}

class _TimeNowCardState extends State<TimeNowCard> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    // The next occasion starts by the clock: check every minute.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isDone(Occasion o, DateTime now) {
    final user = UserStore.instance;
    if (user.occasionDone(o.key)) return true;
    // Morning / evening / sleep athkar finished from the Athkar tab today.
    if (o.kind == 'morning' || o.kind == 'evening' || o.kind == 'sleep') {
      final c = ContentStore.instance.athkarCategoryBySlug(o.kind);
      return c != null && _sameDay(o.day, now) && user.athkarDoneToday(c.id);
    }
    return false;
  }

  String _title(BuildContext context, Occasion o) => switch (o.kind) {
        'prayer' => context.tr('occ_prayer', {'p': prayerName(context, o.prayer!, o.day)}),
        'after_prayer' =>
          context.tr('occ_after_prayer', {'p': prayerName(context, o.prayer!, o.day)}),
        'morning' => context.tr('morning_athkar'),
        'evening' => context.tr('evening_athkar'),
        _ => context.tr('occ_sleep'),
      };

  void _open(Occasion o) {
    if (o.kind == 'prayer') {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerScreen()));
      return;
    }
    final store = ContentStore.instance;
    final c = store.athkarCategoryBySlug(o.athkarSlug!);
    if (c == null) return;
    UserStore.instance.setAthkarSeenToday(c.id);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AthkarCounterScreen(
        title: _title(context, o),
        athkar: store.athkarIn(c.id),
        progressKey: o.key,
        onFinished: () {
          UserStore.instance.setOccasionDone(o.key);
          if (_sameDay(o.day, DateTime.now())) UserStore.instance.setAthkarDoneToday(c.id);
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([UserStore.instance, PrayerStore.instance, ContentStore.instance]),
      builder: (context, _) {
        final now = DateTime.now();
        final (o, next) = occasionNow(now);
        final done = _isDone(o, now);

        // Glow while waiting to be done (steady for reduced motion).
        final still = MediaQuery.disableAnimationsOf(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (!done && !still && !_pulse.isAnimating) {
            _pulse.repeat(reverse: true);
          } else if ((done || still) && _pulse.isAnimating) {
            _pulse.stop();
            _pulse.value = 0;
          }
        });

        final (IconData icon, Color fg, Color bg) = switch (o.kind) {
          'prayer' => (Icons.mosque, AppColors.green, AppColors.greenSoft),
          'after_prayer' => (Icons.self_improvement, AppColors.goldDark, AppColors.sandSoft),
          'morning' => (Icons.wb_sunny_outlined, AppColors.goldDark, AppColors.sandSoft),
          'evening' => (Icons.nights_stay_outlined, AppColors.green, AppColors.greenSoft),
          _ => (Icons.bedtime_outlined, AppColors.nightGold, AppColors.night),
        };

        final c = o.athkarSlug == null
            ? null
            : ContentStore.instance.athkarCategoryBySlug(o.athkarSlug!);
        final list = c == null ? const <Dhikr>[] : ContentStore.instance.athkarIn(c.id);
        final count = list.length;
        // Athkar started but not finished: how many are done so far.
        final saved = UserStore.instance.athkarProgress(o.key);
        final finishedN = saved == null || saved.length != count
            ? 0
            : [for (var i = 0; i < count; i++) if (saved[i] >= list[i].count) i].length;
        final started = !done && saved != null && saved.any((n) => n > 0);
        final first = o.kind == 'prayer'
            ? context.tr('occ_adhan', {'t': formatPrayerTime(context, o.start)})
            : done
                ? context.tr('completed_n', {'a': count, 'b': count})
                : started
                    ? context.tr('athkar_progress_n', {'a': finishedN, 'b': count})
                    : context.tr('athkar_count', {'n': count});
        final progress = done ? 1.0 : (count == 0 ? 0.0 : finishedN / count);
        final status = [
          first,
          context.tr('occ_next',
              {'x': _title(context, next), 't': formatPrayerTime(context, next.start)}),
        ].join(' · ');

        final Widget trailing = done
            ? Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                child: Icon(Icons.check,
                    size: 17, color: Colors.white, semanticLabel: context.tr('completed')),
              )
            : o.kind == 'prayer'
                ? TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => UserStore.instance.setOccasionDone(o.key),
                    child: Text(context.tr('occ_prayed'),
                        style: AppText.ui(
                            size: 15, weight: FontWeight.w700, color: AppColors.green)),
                  )
                : Text(context.tr(started ? 'athkar_continue' : 'athkar_start'),
                    style: AppText.ui(size: 15, weight: FontWeight.w700, color: AppColors.green));

        final body = Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration:
                  BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: fg, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr(done ? 'occ_done' : 'occ_now'),
                      style: AppText.ui(
                          size: 12,
                          weight: FontWeight.w700,
                          color: done ? AppColors.green : AppColors.goldDark)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_title(context, o),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.ui(size: 17, weight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      trailing,
                    ],
                  ),
                  const SizedBox(height: 10),
                  ProgressLine(value: progress, height: 8),
                  const SizedBox(height: 8),
                  Text(status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.ui(size: 13, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        );

        if (done) return AppCard(onTap: () => _open(o), child: body);
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = still ? 1.0 : Curves.easeInOut.transform(_pulse.value);
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.15 + 0.25 * t),
                    blurRadius: 6 + 12 * t,
                    spreadRadius: 1 * t,
                  ),
                ],
              ),
              child: AppCard(
                onTap: () => _open(o),
                color: Color.lerp(AppColors.surface, AppColors.sandSoft, 0.5 * t)!,
                borderColor: Color.lerp(AppColors.line, AppColors.gold, 0.5 + 0.5 * t)!,
                borderWidth: 1.5,
                child: child!,
              ),
            );
          },
          child: body,
        );
      },
    );
  }
}
