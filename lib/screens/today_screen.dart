import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/content_store.dart';
import '../data/friday_data.dart';
import '../data/user_store.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/kahf_card.dart';
import '../widgets/plan_card.dart';
import '../widgets/time_now_card.dart';
import '../widgets/prayer_card.dart';
import '../widgets/prayer_widgets.dart';
import '../widgets/quran_wird_card.dart';
import '../widgets/story_card.dart';
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
            // «قراءة سورة الكهف»: Fridays only, with its own progress.
            const KahfCard(),
            const SizedBox(height: 16),
          ],

          // «حان الوقت»: the prayer or athkar of this moment, with ✓ when done.
          const TimeNowCard(),
          const SizedBox(height: 16),

          // «ورد التلاوة اليومية» first, then «ورد الحديث اليومي».
          const QuranWirdCard(),
          const SizedBox(height: 16),
          // Extra plans switched on in Settings («تفعيل»), each with its own progress.
          const ActivePlanCards(),
          // «الحديث اليومي - التوحيد».
          _HadithOfTheDayCard(
            collectionId: ContentStore.tawhidCollectionId,
            titleKey: 'hadith_daily_tawhid',
            onOpen: (h) => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => HadithDetailScreen(hadith: h),
            )),
          ),
          const SizedBox(height: 16),
          // «قصص قرآنية · قصة اليوم» — last on the page.
          const StoryCard(),
          const SizedBox(height: 16),



        ],
      ),
    );
  }
}

class _HadithOfTheDayCard extends StatelessWidget {
  final int collectionId;
  final String titleKey;
  final ValueChanged<Hadith> onOpen;
  const _HadithOfTheDayCard(
      {required this.collectionId, required this.titleKey, required this.onOpen});

  /// «ورد الحديث اليومي»: today's hadith in short, how many daily hadith
  /// you have read, and one tap to read it in full.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppSettings.instance, UserStore.instance]),
      builder: (context, _) {
        final user = UserStore.instance;
        // One hadith a day; done when the user slides to confirm on its page.
        final hadith =
            ContentStore.instance.hadithOfToday(collectionId: collectionId);
        final doneToday = user.readToday(hadith.id);
        final read = doneToday ? 1 : 0;
        const total = 1;
        void onTap() => onOpen(hadith);
        String n(int v) => S.isArabic ? _arabicDigits(v) : '$v';
        return AppCard(
          color: AppColors.green,
          borderWidth: 0,
          radius: 22,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: Stack(
            children: [
              const PositionedDirectional(
                end: -36,
                top: -36,
                child: Opacity(
                  opacity: 0.12,
                  child: StarMotif(
                      size: 130, color: Colors.white, strokeWidth: 4, withInner: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, color: AppColors.sand, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(context.tr(titleKey),
                              style: AppText.ui(
                                  size: 15, weight: FontWeight.w700, color: Colors.white)),
                        ),
                        if (doneToday)
                          Pill(context.tr('wird_done'),
                              background: AppColors.sand,
                              foreground: const Color(0xFF3D2A08)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hadith.title.v.isNotEmpty)
                      Text(hadith.title.v,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.ui(
                              size: 14, weight: FontWeight.w700, color: AppColors.sand)),
                    Text(S.isArabic || hadith.localTranslation.isEmpty ? hadith.arabic : hadith.localTranslation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: S.isArabic ? TextDirection.rtl : null,
                        style: S.isArabic
                            ? AppText.arabic(size: 20, color: Colors.white, height: 1.7)
                            : AppText.ui(size: 15, color: AppColors.onGreenBody, height: 1.5)),
                    const SizedBox(height: 4),
                    Text(hadith.reference.v,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.ui(size: 12, color: AppColors.onGreenMuted)),
                    const SizedBox(height: 10),
                    ProgressLine(
                      value: read / total,
                      height: 5,
                      color: AppColors.sand,
                      track: Colors.white.withValues(alpha: 0.18),
                    ),
                    if (doneToday) ...[
                      const SizedBox(height: 10),
                      Builder(builder: (context) {
                        final at = user.doneAt('hadith:${UserStore.dayKey(DateTime.now())}');
                        return DoneBox(
                          title: context.tr('done_hadith'),
                          details: at == null
                              ? null
                              : context.tr('done_at', {'t': formatPrayerTime(context, at)}),
                          onGreen: true,
                        );
                      }),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                              doneToday
                                  ? context.tr('hadith_confirmed')
                                  : context.tr('hadith_confirm_hint'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.ui(size: 12, color: AppColors.onGreenMuted)),
                        ),
                        Text(context.tr('hadith_read_full'),
                            style: AppText.ui(
                                size: 13, weight: FontWeight.w700, color: AppColors.sand)),
                        Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                            color: AppColors.sand, size: 18),
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

String _arabicDigits(int v) =>
    v.toString().split('').map((c) => '٠١٢٣٤٥٦٧٨٩'[int.parse(c)]).join();

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
          if (!S.isArabic && h.localTranslation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(h.localTranslation,
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
