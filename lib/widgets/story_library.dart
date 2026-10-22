import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/stories.dart';
import '../data/story_store.dart';
import '../data/tawheed_search.dart';
import '../l10n/strings.dart';
import '../screens/quran_reader_screen.dart' show localNum;
import '../screens/story_parts_screen.dart';
import '../screens/story_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Opens a story: its parts list when it has parts, else the reading itself.
void openStory(BuildContext context, QuranStory story) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => story.hasParts
        ? StoryPartsScreen(story: story)
        : StoryScreen(unit: StoryUnit(story, 0)),
  ));
}

/// «القصص» in the Qur'an tab: free reading of every story, grouped, with
/// ✓ / progress, today's story tagged; [query] filters by name.
class StoryLibrary extends StatelessWidget {
  final String query;
  const StoryLibrary({super.key, this.query = ''});

  static const _groups = {
    StoryGroup.prophets: 'stories_group_prophets',
    StoryGroup.nations: 'stories_group_nations',
    StoryGroup.people: 'stories_group_people',
  };

  bool _matches(QuranStory s) {
    final q = query.trim();
    if (q.isEmpty) return true;
    final nq = TawheedSearch.normalize(q);
    final lower = q.toLowerCase();
    return TawheedSearch.normalize(s.name.ar).contains(nq) ||
        TawheedSearch.normalize(s.name.ur ?? '').contains(nq) ||
        (s.name.en ?? '').toLowerCase().contains(lower);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoryStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final today = store.today;
        final total = quranStories.length;
        final done = store.storiesDone;
        final searching = query.trim().isNotEmpty;
        final children = <Widget>[];

        if (!searching) {
          children
            ..add(AppCard(
              color: AppColors.green,
              borderWidth: 0,
              radius: 20,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              onTap: () => openStory(context, today.story),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                            context.tr('stories_done_count',
                                {'n': localNum(done), 't': localNum(total)}),
                            style: AppText.ui(
                                size: 15, weight: FontWeight.w700, color: Colors.white)),
                      ),
                      Flexible(
                        child: Text('${context.tr('stories_today')}: ${today.story.name.v}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.ui(size: 12, color: AppColors.sand)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : done / total,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      color: AppColors.sand,
                    ),
                  ),
                ],
              ),
            ))
            ..add(const SizedBox(height: 6));
        }

        var number = 0;
        final numbers = {for (final s in quranStories) s.id: ++number};
        var any = false;
        for (final g in StoryGroup.values) {
          final items = quranStories.where((s) => s.group == g && _matches(s)).toList();
          if (items.isEmpty) continue;
          any = true;
          children
            ..add(Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Text(context.tr(_groups[g]!),
                  style: AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
            ))
            ..add(AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _StoryRow(
                      story: items[i],
                      number: numbers[items[i].id]!,
                      first: i == 0,
                      isToday: items[i].id == today.story.id,
                    ),
                ],
              ),
            ));
        }
        if (!any) {
          children.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(context.tr('stories_no_results'),
                textAlign: TextAlign.center,
                style: AppText.ui(size: 14, color: AppColors.muted)),
          ));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
      },
    );
  }
}

class _StoryRow extends StatelessWidget {
  final QuranStory story;
  final int number;
  final bool first;
  final bool isToday;
  const _StoryRow(
      {required this.story, required this.number, required this.first, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final store = StoryStore.instance;
    final done = store.storyDone(story);
    final progress = store.storyProgress(story);
    final started = !done && progress > 0.02;
    final p = story.parts.first;
    final surah = QuranData.instance.isLoaded ? QuranData.instance.surah(p.surah) : null;
    final surahName = surah == null ? '' : (S.isArabic ? surah.name : surah.translit);
    final oneSurah = story.parts.every((x) => x.surah == p.surah);
    final sub = story.hasParts
        ? (oneSurah
            ? '${S.isArabic ? 'سورة $surahName' : surahName} · ${context.tr('stories_parts', {'n': localNum(story.parts.length)})}'
            : context.tr('stories_parts', {'n': localNum(story.parts.length)}))
        : '$surahName ${localNum(p.from)}–${localNum(p.to)} · ${context.tr('quran_ayat', {'n': localNum(p.count)})}';

    final units = store.unitsOf(story);
    return InkWell(
      onTap: () => openStory(context, story),
      // Long press: reset this story's reading (✓ and progress).
      onLongPress: store.hasReading(units)
          ? () => confirmResetReading(context, story.name.v, () => store.reset(units))
          : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          border: first ? null : const Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.green
                    : (started ? AppColors.sandSoft : AppColors.divider),
              ),
              child: done
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                  : Text(localNum(number),
                      style: AppText.ui(
                          size: 13,
                          weight: FontWeight.w700,
                          color: started ? AppColors.brown : AppColors.muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(story.name.v,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.ui(size: 15, weight: FontWeight.w700)),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.sandSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(context.tr('stories_today_tag'),
                              style: AppText.ui(
                                  size: 10, weight: FontWeight.w700, color: AppColors.goldDark)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(sub, style: AppText.ui(size: 12, color: AppColors.muted)),
                  if (started) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: AppColors.divider,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                size: 20, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
