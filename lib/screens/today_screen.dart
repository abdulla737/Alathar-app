import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/content_store.dart';
import '../data/friday_data.dart';
import '../data/prayer_store.dart';
import '../data/prayer_times.dart';
import '../data/user_store.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_button.dart';
import '../widgets/common.dart';
import '../widgets/athkar_time_banner.dart';
import '../widgets/prayer_card.dart';
import '../widgets/quran_wird_card.dart';
import '../widgets/share_card.dart';
import 'athkar_counter_screen.dart';
import 'friday_screen.dart';
import 'hadith_detail_screen.dart';
import 'home_shell.dart';

class TodayScreen extends StatelessWidget {
  /// Switches the bottom tab (see [AppTab]).
  final ValueChanged<int> onOpenTab;

  const TodayScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    // Refreshes when new content arrives from Supabase.
    return ListenableBuilder(
      listenable: Listenable.merge([ContentStore.instance, AppSettings.instance]),
      builder: (context, _) => _build(context, ContentStore.instance.hadithOfToday()),
    );
  }

  Widget _build(BuildContext context, Hadith hadith) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's date in the app language. TODO: add the Hijri date.
                    Text(MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
                        style: AppText.ui(
                            size: 13, weight: FontWeight.w500, color: AppColors.muted)),
                    const SizedBox(height: 2),
                    Text(context.tr('greeting'), style: AppText.title()),
                  ],
                ),
              ),
              // Dark / light mode, next to the bell.
              IconButton.outlined(
                tooltip: context.tr(AppSettings.instance.darkMode ? 'light_mode' : 'dark_mode'),
                onPressed: () =>
                    AppSettings.instance.setDarkMode(!AppSettings.instance.darkMode),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.line),
                  fixedSize: const Size(44, 44),
                ),
                icon: Icon(
                    AppSettings.instance.darkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: AppSettings.instance.darkMode ? AppColors.nightGold : AppColors.ink,
                    size: 20),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: context.tr('notifications'),
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.line),
                  fixedSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.notifications_none, color: AppColors.ink, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Next prayer with a live countdown; tap for all times.
          const PrayerCard(),
          // «حان وقت أذكار …» by the prayer times; hidden when not due.
          const AthkarTimeBanner(),
          const SizedBox(height: 16),

          // Fridays: a Friday-sunnah hadith; tap for all of them. Always
          // shown on Fridays (the Settings switch is for the notification).
          if (isFriday(DateTime.now())) ...[
            _FridayCard(
              hadith: fridayHadithFor(DateTime.now()),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const FridayScreen(),
              )),
            ),
            const SizedBox(height: 16),
          ],

          _HadithOfTheDayCard(
            hadith: hadith,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HadithDetailScreen(hadith: hadith),
            )),
          ),
          const SizedBox(height: 16),

          // Morning / evening athkar: real counts, done-today from UserStore.
          // From its time (morning 4:00, evening 15:00) the card glows until
          // the user taps it; tapping opens that category's athkar.
          StreamBuilder<void>(
            stream: _minuteTicks,
            builder: (context, _) => ListenableBuilder(
            listenable: UserStore.instance,
            builder: (context, _) {
              final now = DateTime.now();
              Widget card(String slug, String titleKey, Widget icon, String whenKey) {
                final c = ContentStore.instance.athkarCategoryBySlug(slug);
                final n = c == null ? 0 : ContentStore.instance.athkarIn(c.id).length;
                final done = c != null && UserStore.instance.athkarDoneToday(c.id);
                final seen = c != null && UserStore.instance.athkarSeenToday(c.id);
                final due = !done &&
                    !seen &&
                    n > 0 &&
                    (slug == 'morning' ? isMorningAthkarTime(now) : isEveningAthkarTime(now));
                return _AthkarStatusCard(
                  highlight: due,
                  icon: icon,
                  title: context.tr(titleKey),
                  progress: done ? 1 : 0,
                  status: done
                      ? context.tr('completed_n', {'a': n, 'b': n})
                      : context.tr('not_started_n', {'a': 0, 'b': n}),
                  trailing: done
                      ? Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                              color: AppColors.green, shape: BoxShape.circle),
                          child: Icon(Icons.check,
                              size: 14,
                              color: Colors.white,
                              semanticLabel: context.tr('completed')),
                        )
                      : due
                          ? Pill(context.tr('athkar_now'),
                              background: AppColors.gold, foreground: Colors.white)
                          : Text(context.tr(whenKey),
                              style: AppText.ui(
                                  size: 11, weight: FontWeight.w600, color: AppColors.gold)),
                  onTap: () {
                    if (c == null || n == 0) {
                      onOpenTab(AppTab.athkar);
                      return;
                    }
                    UserStore.instance.setAthkarSeenToday(c.id);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AthkarCounterScreen(
                        title: c.name.v,
                        athkar: ContentStore.instance.athkarIn(c.id),
                        onFinished: () => UserStore.instance.setAthkarDoneToday(c.id),
                      ),
                    ));
                  },
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: card('morning', 'morning_athkar',
                        const Icon(Icons.wb_sunny_outlined, color: AppColors.gold, size: 22),
                        'after_fajr'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: card('evening', 'evening_athkar',
                        const Icon(Icons.nights_stay_outlined,
                            color: AppColors.green, size: 22),
                        'after_asr'),
                  ),
                ],
              );
            },
          ),
          ),
          const SizedBox(height: 16),

          // «وردك من القرآن»: where you stopped reading; tap to continue.
          const QuranWirdCard(),
        ],
      ),
    );
  }
}

class _HadithOfTheDayCard extends StatelessWidget {
  final Hadith hadith;
  final VoidCallback onTap;
  const _HadithOfTheDayCard({required this.hadith, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        return AppCard(
          color: AppColors.green,
          borderWidth: 0,
          radius: 24,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: Stack(
            children: [
              const PositionedDirectional(
                end: -40,
                top: -40,
                child: Opacity(
                  opacity: 0.12,
                  child: StarMotif(
                      size: 160, color: Colors.white, strokeWidth: 4, withInner: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.tr('hadith_of_day'),
                        style: AppText.overline(color: AppColors.sand)
                            .copyWith(fontSize: S.isRtl ? 13 : 11)),
                    const SizedBox(height: 14),
                    ArabicText(hadith.arabic,
                        style: AppText.arabic(
                            size: AppSettings.instance.arabicSize + (S.isArabic ? 3 : -1),
                            color: Colors.white,
                            height: 1.75)),
                    // The Arabic text is the hadith itself, so no translation in Arabic.
                    if (!S.isArabic) ...[
                      const SizedBox(height: 14),
                      Text(hadith.translation,
                          style: AppText.ui(
                              size: 15, color: AppColors.onGreenBody, height: 1.5)),
                    ],
                    const SizedBox(height: 14),
                    const Divider(color: Color(0x2EFFFFFF), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hadith.reference.v,
                                  style: AppText.ui(
                                      size: 13,
                                      weight: FontWeight.w600,
                                      color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(
                                  context.tr('narrated_by',
                                      {'name': hadith.narrator.v}),
                                  style: AppText.ui(
                                      size: 12, color: AppColors.onGreenMuted)),
                            ],
                          ),
                        ),
                        if (hadith.grade.v.isNotEmpty)
                          Pill(hadith.grade.v,
                              background: AppColors.sand,
                              foreground: const Color(0xFF3D2A08)),
                        const SizedBox(width: 4),
                        HadithAudioButton(hadith: hadith, color: AppColors.sand, size: 22),
                        IconButton(
                          tooltip: context.tr('share_card'),
                          onPressed: () => showHadithShare(context, hadith),
                          icon: const Icon(Icons.ios_share, color: AppColors.sand, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Minute ticks so the "time for athkar" highlight follows the clock.
final Stream<void> _minuteTicks =
    Stream<void>.periodic(const Duration(minutes: 1)).asBroadcastStream();

/// Morning athkar start: Fajr (4:00 if no location is set yet).
/// From then the card glows until tapped.
bool isMorningAthkarTime(DateTime t) {
  final day = PrayerStore.instance.dayOf(t);
  return day == null ? t.hour >= 4 : !t.isBefore(day[Prayer.fajr]);
}

/// Evening athkar start: Asr (15:00 if no location is set yet).
bool isEveningAthkarTime(DateTime t) {
  final day = PrayerStore.instance.dayOf(t);
  return day == null ? t.hour >= 15 : !t.isBefore(day[Prayer.asr]);
}

class _AthkarStatusCard extends StatefulWidget {
  final Widget icon;
  final String title;
  final double progress;
  final String status;
  final Widget trailing;
  final VoidCallback onTap;

  /// It's time for these athkar and they aren't done yet: pulse the card.
  final bool highlight;

  const _AthkarStatusCard({
    required this.icon,
    required this.title,
    required this.progress,
    required this.status,
    required this.trailing,
    required this.onTap,
    this.highlight = false,
  });

  @override
  State<_AthkarStatusCard> createState() => _AthkarStatusCardState();
}

class _AthkarStatusCardState extends State<_AthkarStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _AthkarStatusCard old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.highlight && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.highlight && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [widget.icon, widget.trailing],
        ),
        const SizedBox(height: 10),
        Text(widget.title, style: AppText.ui(size: 15, weight: FontWeight.w600)),
        const SizedBox(height: 10),
        ProgressLine(value: widget.progress),
        const SizedBox(height: 10),
        Text(widget.status, style: AppText.ui(size: 12, color: AppColors.muted)),
      ],
    );

    if (!widget.highlight) {
      return AppCard(onTap: widget.onTap, child: body);
    }

    // People who turned off animations get a steady gold border instead.
    final still = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = still ? 1.0 : Curves.easeInOut.transform(_pulse.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.15 + 0.25 * t),
                blurRadius: 6 + 12 * t,
                spreadRadius: 1 * t,
              ),
            ],
          ),
          child: AppCard(
            onTap: widget.onTap,
            color: Color.lerp(AppColors.surface, AppColors.sandSoft, 0.6 * t)!,
            borderColor: Color.lerp(AppColors.line, AppColors.gold, 0.5 + 0.5 * t)!,
            borderWidth: 1.5,
            child: child!,
          ),
        );
      },
      child: body,
    );
  }
}

/// Friday card on Today: «تذكير بسنن يوم الجمعة» with one Friday hadith
/// (a different one each week). Tap → all Friday sunnahs.
class _FridayCard extends StatelessWidget {
  final Hadith hadith;
  final VoidCallback onTap;
  const _FridayCard({required this.hadith, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    return AppCard(
      color: AppColors.sandSoft,
      borderColor: AppColors.gold,
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mosque, color: AppColors.goldDark, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.tr('friday_title'),
                    style: AppText.ui(size: 15, weight: FontWeight.w700, color: AppColors.goldDark)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(h.title.v,
              style: AppText.ui(size: 14, weight: FontWeight.w700, color: AppColors.green)),
          const SizedBox(height: 6),
          Text(h.arabic,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppText.arabic(
                  size: AppSettings.instance.arabicSize - 4, height: 1.8)),
          if (!S.isArabic && h.translation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(h.translation,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.ui(size: 13, color: AppColors.body, height: 1.5)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(h.reference.v,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.ui(size: 12, color: AppColors.muted)),
              ),
              Text(context.tr('friday_all', {'n': fridayHadith.length}),
                  style: AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.goldDark)),
              Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                  size: 18, color: AppColors.goldDark),
            ],
          ),
        ],
      ),
    );
  }
}
