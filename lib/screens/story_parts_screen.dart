import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/stories.dart';
import '../data/story_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'quran_reader_screen.dart' show localNum;
import 'story_screen.dart';

/// A long story («يوسف») as its daily parts, each with ✓ or progress.
class StoryPartsScreen extends StatelessWidget {
  final QuranStory story;
  const StoryPartsScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final store = StoryStore.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(context.tr('stories_title'),
            style: AppText.ui(size: 15, weight: FontWeight.w600)),
      ),
      body: FutureBuilder<void>(
        future: QuranData.instance.ensureLoaded(),
        builder: (context, _) => ListenableBuilder(
          listenable: store,
          builder: (context, _) => _content(context, store),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, StoryStore store) {
    final q = QuranData.instance;
    final first = story.parts.first;
    final last = story.parts.last;
    final sameSurah = story.parts.every((p) => p.surah == first.surah);
    final surah = q.isLoaded ? q.surah(first.surah) : null;
    final done = store.partsDone(story);
    final total = story.parts.length;

    Widget chip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(t,
              style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.onGreenBody)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        AppCard(
          color: AppColors.green,
          borderWidth: 0,
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(story.name.v,
                  style: AppText.ui(
                      size: 26, weight: FontWeight.w700, color: Colors.white, height: 1.3)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (surah != null && sameSurah) ...[
                    chip(S.isArabic ? 'سورة ${surah.name}' : surah.translit),
                    chip(context.tr('tafsir_ayat_range',
                        {'a': localNum(first.from), 'b': localNum(last.to)})),
                  ],
                  chip(context.tr('stories_parts', {'n': localNum(total)})),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: store.storyProgress(story),
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        color: AppColors.sand,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(context.tr('stories_n_of', {'n': localNum(done), 't': localNum(total)}),
                      style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.sand)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(story.summary.v,
            style: AppText.ui(size: 14, height: 1.8, color: AppColors.body)),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < total; i++)
                _PartRow(unit: StoryUnit(story, i), first: i == 0),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartRow extends StatelessWidget {
  final StoryUnit unit;
  final bool first;
  const _PartRow({required this.unit, required this.first});

  @override
  Widget build(BuildContext context) {
    final store = StoryStore.instance;
    final done = store.isDone(unit);
    final started = store.isStarted(unit);
    final p = unit.part;
    final q = QuranData.instance;
    final surah = q.isLoaded ? q.surah(p.surah) : null;
    final where = surah == null ? '' : '${S.isArabic ? surah.name : surah.translit} · ';
    return InkWell(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => StoryScreen(unit: unit))),
      // Long press: reset this part's reading.
      onLongPress: store.hasReading([unit])
          ? () => confirmResetReading(
              context, '${unit.story.name.v} · ${p.name?.v ?? ''}', () => store.reset([unit]))
          : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  : Text(localNum(unit.index + 1),
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
                  Text(p.name?.v ?? '',
                      style: AppText.ui(size: 15, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                      '$where${context.tr('tafsir_ayat_range', {'a': localNum(p.from), 'b': localNum(p.to)})} · ${context.tr('quran_ayat', {'n': localNum(p.count)})}',
                      style: AppText.ui(size: 12, color: AppColors.muted)),
                  if (started) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: store.progressOf(unit),
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
