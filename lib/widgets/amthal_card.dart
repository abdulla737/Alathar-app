import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/quran.dart';
import '../data/stories.dart';
import '../data/story_store.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../screens/quran_reader_screen.dart' show localNum, quranStyle;
import '../screens/story_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'prayer_widgets.dart';

/// Olive colours of the «الأمثال في القرآن» card.
const _olive = Color(0xFF5A6B1E);
const _oliveText = Color(0xFF4A5818);
const _oliveMuted = Color(0xFF4F5640);
const _oliveBg = Color(0xFFEEF0E2);
const _oliveTrack = Color(0xFFDCE0C8);
const _verseInk = Color(0xFF2E3320);

/// Today page: «الأمثال في القرآن» — one parable a day: its name, the key
/// verse, the meaning in short and «اقرأ المثل»; ✓ with details when read,
/// and tomorrow's parable.
class AmthalCard extends StatelessWidget {
  const AmthalCard({super.key});

  void _open(BuildContext context, StoryUnit unit) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => StoryScreen(unit: unit)));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: QuranData.instance.ensureLoaded(),
      builder: (context, _) => ListenableBuilder(
        listenable: Listenable.merge([StoryStore.instance, AppSettings.instance]),
        builder: (context, _) => _card(context),
      ),
    );
  }

  Widget _card(BuildContext context) {
    final store = StoryStore.instance;
    final unit = store.todayMathal;
    final story = unit.story;
    final part = unit.part;
    final q = QuranData.instance;
    final surah = q.isLoaded ? q.surah(part.surah) : null;
    final no = dailyAmthalUnits.indexWhere((u) => u.key == unit.key) + 1;
    final counter = context.tr('amthal_n_of',
        {'n': localNum(no), 't': localNum(dailyAmthalUnits.length)});
    final where = surah == null
        ? ''
        : '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${part.from == part.to ? context.tr('quran_ayah', {'n': localNum(part.from)}) : context.tr('tafsir_ayat_range', {'a': localNum(part.from), 'b': localNum(part.to)})}';
    final done = store.isDone(unit);

    final header = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: _olive, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.park_outlined, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('amthal_title'),
                  style: AppText.ui(size: 12, weight: FontWeight.w700, color: _oliveText)),
              Text('${context.tr('amthal_today')} · $counter',
                  style: AppText.ui(size: 12, color: _oliveMuted)),
            ],
          ),
        ),
        if (done)
          Pill(context.tr('wird_done'),
              background: AppColors.greenSoft, foreground: AppColors.green),
      ],
    );

    if (done) {
      final next = store.tomorrowMathal;
      final at = UserStore.instance.doneAt('story:${unit.key}');
      return AppCard(
        color: _oliveBg,
        borderWidth: 0,
        radius: 24,
        onTap: () => _open(context, unit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 10),
            Text(story.name.v, style: AppText.ui(size: 17, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            DoneBox(
              title: context.tr('amthal_done'),
              details: [
                if (where.isNotEmpty) where,
                if (at != null) context.tr('done_at', {'t': formatPrayerTime(context, at)}),
              ].join(' · '),
              background: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(context.tr('amthal_tomorrow', {'name': next.story.name.v}),
                style: AppText.ui(size: 13, color: const Color(0xFF2E3833))),
          ],
        ),
      );
    }

    final (ks, ka) = story.keyVerse;
    final keyText = q.isLoaded && ks <= q.surahs.length && ka <= q.surah(ks).count
        ? '﴿${q.surah(ks).ayat[ka - 1]}﴾'
        : null;
    final progress = store.progressOf(unit);
    final started = store.isStarted(unit);

    return AppCard(
      color: _oliveBg,
      borderWidth: 0,
      radius: 24,
      onTap: () => _open(context, unit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 12),
          Text(story.name.v, style: AppText.ui(size: 19, weight: FontWeight.w700, height: 1.4)),
          if (where.isNotEmpty)
            Text(where, style: AppText.ui(size: 13, weight: FontWeight.w600, color: _oliveText)),
          if (keyText != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration:
                  BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Text(keyText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: quranStyle(19, height: 1.9, color: _verseInk)),
            ),
          ],
          const SizedBox(height: 10),
          Text(story.summary.v,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.ui(size: 14, height: 1.7, color: const Color(0xFF2E3833))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProgressLine(value: progress, height: 6, color: _olive, track: _oliveTrack),
                    const SizedBox(height: 4),
                    Text(
                        started
                            ? context.tr('stories_progress_pct',
                                {'p': localNum((progress * 100).round())})
                            : context.tr('amthal_hint'),
                        style: AppText.ui(size: 11, color: _oliveMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _open(context, unit),
                style: FilledButton.styleFrom(
                  backgroundColor: _olive,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr(started ? 'quran_continue' : 'amthal_read'),
                    style: AppText.ui(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
