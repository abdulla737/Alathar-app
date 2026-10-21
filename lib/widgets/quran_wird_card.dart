import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/quran.dart';
import '../l10n/strings.dart';
import '../screens/quran_reader_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Today page: «وردك من القرآن» — the verse where you stopped, how far you
/// are through the Qur'an, and one tap to continue reading.
class QuranWirdCard extends StatelessWidget {
  const QuranWirdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: QuranData.instance.ensureLoaded(),
      builder: (context, _) {
        if (!QuranData.instance.isLoaded) return const SizedBox(height: 0);
        return ListenableBuilder(
          listenable: Listenable.merge([QuranStore.instance, AppSettings.instance]),
          builder: (context, _) => _card(context),
        );
      },
    );
  }

  Widget _card(BuildContext context) {
    final q = QuranData.instance;
    final store = QuranStore.instance;
    final settings = AppSettings.instance;

    // The chosen range of surahs (Settings → «الورد اليومي»).
    final fromSurah = settings.quranFromSurah;
    final toSurah = settings.quranToSurah;
    final lastOfRange = q.surah(toSurah);

    // Today's pages: from today's first page (or where yesterday's reading
    // ended) for the daily number of pages, inside the chosen surahs.
    final fromPage = q.pageOf(fromSurah, 1);
    final toPage = q.pageOf(toSurah, lastOfRange.count);
    final last = store.lastSurah;
    var fallback = fromPage;
    if (last != null) {
      final la = store.lastAyah.clamp(1, q.surah(last).count);
      fallback = q.pageOf(last, la);
    }
    final startPage = store.wirdStartPage(fallback, fromPage, toPage);
    final endPage = (startPage + settings.quranPagesPerDay - 1).clamp(startPage, toPage);

    // The verse to show: where you stopped if it is within today's pages,
    // else the first verse of today's first page.
    var (s, ayah) = q.ayatOnPage(startPage).first;
    if (last != null) {
      final la = store.lastAyah.clamp(1, q.surah(last).count);
      final p = q.pageOf(last, la);
      if (p >= startPage && p <= endPage) {
        s = last;
        ayah = la;
      }
    }
    final surah = q.surah(s);
    final started = last != null && (s != fromSurah || ayah != 1);

    // Today's goal and progress through the range.
    final goal = settings.quranPagesPerDay;
    final readToday = store.pagesReadToday;
    final dayProgress = (readToday / goal).clamp(0.0, 1.0);
    final done = readToday >= goal;

    // Khatma (or chosen range) completion: pages finished in this round.
    final rangePages = toPage - fromPage + 1;
    final pagesDone = store.pagesDone(fromPage, toPage);
    final cycleProgress = (pagesDone / rangePages).clamp(0.0, 1.0);
    final cyclePercent = (cycleProgress * 100).floor();

    void open() {
      store.beginWird(startPage);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuranReaderScreen(surah: s, ayah: ayah, wirdStartPage: startPage),
      ));
    }

    final khatma = settings.quranKhatma;

    return AppCard(
      radius: 22,
      borderColor: AppColors.gold,
      borderWidth: 1.5,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.tr('quran_wird'),
                    style: AppText.ui(size: 15, weight: FontWeight.w700)),
              ),
              if (done)
                Pill(context.tr('wird_done'),
                    background: AppColors.greenSoft, foreground: AppColors.green)
              else
                Text(context.tr('quran_page', {'n': localNum(q.pageOf(s, ayah))}),
                    style: AppText.ui(size: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 6),
          Text('${surah.ayat[ayah - 1]} ${ayahMarker(ayah)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              style: quranStyle(20, color: AppColors.body, height: 1.9)),
          const SizedBox(height: 8),
          // Two bars side by side: today's pages, and the khatma / range.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Bar(
                  value: dayProgress,
                  color: AppColors.green,
                  label: context.tr('quran_today_progress',
                      {'n': localNum(readToday.clamp(0, goal)), 't': localNum(goal)}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _Bar(
                  value: cycleProgress,
                  color: AppColors.gold,
                  label: context.tr(khatma ? 'quran_khatma_progress' : 'quran_range_progress', {
                    'p': localNum(cyclePercent),
                    'n': localNum(pagesDone),
                    't': localNum(rangePages),
                  }),
                ),
              ),
            ],
          ),
          if (store.khatmasDone > 0 && khatma) ...[
            const SizedBox(height: 4),
            Text(context.tr('quran_khatmas_done', {'n': localNum(store.khatmasDone)}),
                style: AppText.ui(size: 11, color: AppColors.gold)),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                    started
                        ? '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${context.tr('quran_ayah', {'n': localNum(ayah)})}'
                        : context.tr('quran_start_from', {'s': q.surah(fromSurah).name}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.ui(size: 12, color: AppColors.muted)),
              ),
              Text(context.tr(started ? 'quran_continue' : 'quran_start'),
                  style: AppText.ui(size: 13, weight: FontWeight.w700, color: AppColors.green)),
              Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                  color: AppColors.green, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small progress bar with its caption underneath.
class _Bar extends StatelessWidget {
  final double value;
  final Color color;
  final String label;
  const _Bar({required this.value, required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressLine(value: value, height: 5, color: color),
          const SizedBox(height: 5),
          Text(label,
              maxLines: 2,
              style: AppText.ui(size: 11.5, weight: FontWeight.w600, color: color)),
        ],
      );
}
