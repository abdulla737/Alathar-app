import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/quran.dart';
import '../data/stories.dart';
import '../data/story_store.dart';
import '../l10n/strings.dart';
import '../screens/quran_reader_screen.dart' show localNum, quranStyle;
import '../screens/story_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Today page: «قصص قرآنية · قصة اليوم» — today's reading with its key verse;
/// «أكمل» with progress once started; ✓ and tomorrow's story when done.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key});

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
    final unit = store.today;
    final story = unit.story;
    final part = unit.part;
    final q = QuranData.instance;
    final surah = q.isLoaded ? q.surah(part.surah) : null;
    final storyNo = dailyStories.indexOf(story) + 1;
    final counter = context.tr('stories_n_of',
        {'n': localNum(storyNo), 't': localNum(dailyStories.length)});
    final title = story.hasParts
        ? '${story.name.v} · ${context.tr('stories_part', {'n': localNum(unit.index + 1), 't': localNum(story.parts.length)})}'
        : story.name.v;

    if (store.isDone(unit)) {
      final next = store.tomorrow;
      return AppCard(
        color: AppColors.greenSoft,
        borderWidth: 0,
        radius: 24,
        onTap: () => _open(context, unit),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${context.tr('stories_title')} · ${context.tr('stories_done')}',
                          style: AppText.ui(
                              size: 12, weight: FontWeight.w700, color: AppColors.green)),
                      Text(title, style: AppText.ui(size: 17, weight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(counter,
                    style: AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.green)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
                context.tr('stories_tomorrow', {
                  'name': next.story.hasParts
                      ? '${next.story.name.v} (${localNum(next.index + 1)}/${localNum(next.story.parts.length)})'
                      : next.story.name.v
                }),
                style: AppText.ui(size: 13, color: AppColors.body)),
          ],
        ),
      );
    }

    final started = store.isStarted(unit);
    final progress = store.progressOf(unit);
    final (ks, ka) = story.keyVerse;
    final keyText = q.isLoaded && ks <= q.surahs.length && ka <= q.surah(ks).count
        ? '﴿${q.surah(ks).ayat[ka - 1]}﴾'
        : null;
    final minutes = (part.count * 0.5).ceil().clamp(2, 30);

    return AppCard(
      radius: 24,
      borderColor: AppColors.gold,
      borderWidth: 1.5,
      onTap: () => _open(context, unit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_stories_outlined, color: AppColors.sand, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('stories_title'),
                        style: AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                    Text(context.tr('stories_group_seerah'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.ui(size: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(counter,
                    style: AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.green)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: AppText.ui(size: 20, weight: FontWeight.w700, height: 1.35)),
          if (surah != null)
            Text(
                '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${context.tr('tafsir_ayat_range', {'a': localNum(part.from), 'b': localNum(part.to)})}',
                style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.green)),
          if (keyText != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              decoration: BoxDecoration(
                color: AppColors.sandSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(keyText,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: quranStyle(19, height: 1.9, color: AppColors.brown)),
            ),
          ],
          const SizedBox(height: 10),
          Text(story.summary.v,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.ui(size: 14, height: 1.7, color: AppColors.body)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.divider,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        started
                            ? context.tr('stories_progress_pct',
                                {'p': localNum((progress * 100).round())})
                            : '${context.tr('quran_ayat', {'n': localNum(part.count)})} · ${context.tr('stories_minutes', {'n': localNum(minutes)})}',
                        style: AppText.ui(size: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _open(context, unit),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr(started ? 'stories_continue' : 'stories_read'),
                    style: AppText.ui(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
