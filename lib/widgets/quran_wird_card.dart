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
    final startIndex = q.indexOf(fromSurah, 1);
    final endIndex = q.indexOf(toSurah, lastOfRange.count);

    // Continue where you stopped, if that is inside the range.
    var s = fromSurah, ayah = 1;
    final last = store.lastSurah;
    if (last != null) {
      final la = store.lastAyah.clamp(1, q.surah(last).count);
      final i = q.indexOf(last, la);
      if (i >= startIndex && i <= endIndex) {
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
    final rangeTotal = endIndex - startIndex + 1;
    final rangePercent =
        started ? ((q.indexOf(s, ayah) - startIndex + 1) * 100 / rangeTotal).round() : 0;
    final done = readToday >= goal;

    void open() => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => QuranReaderScreen(surah: s, ayah: ayah),
        ));

    final fullQuran = fromSurah == 1 && toSurah == 114;
    final rangeLabel = fullQuran
        ? context.tr('quran_progress', {'p': localNum(rangePercent)})
        : '${q.surah(fromSurah).name} – ${q.surah(toSurah).name} · ${localNum(rangePercent)}٪';

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
          ProgressLine(value: dayProgress, height: 5),
          const SizedBox(height: 6),
          Text(
              context.tr('quran_today_progress',
                  {'n': localNum(readToday.clamp(0, goal)), 't': localNum(goal)}),
              style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.green)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                    started
                        ? '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${context.tr('quran_ayah', {'n': localNum(ayah)})} · $rangeLabel'
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
