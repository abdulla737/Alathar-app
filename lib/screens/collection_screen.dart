import 'package:flutter/material.dart';

import '../data/content_store.dart';
import '../data/user_store.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/entry_card.dart';
import 'chapter_screen.dart';
import 'hadith_detail_screen.dart';

/// Books with completion ticks: Kitab at-Tawhid (per chapter) and the
/// Forty of an-Nawawi (per hadith).
bool tracksCompletion(Collection c) =>
    c.slug == 'kitab-at-tawhid' || c.slug == 'nawawi40' || c.id == 6 || c.id == 1;

/// A book. Books with chapters (like Kitab at-Tawhid) list their chapters;
/// other books list their hadith directly.
class CollectionScreen extends StatelessWidget {
  final Collection collection;
  const CollectionScreen({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final store = ContentStore.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        title: Text(collection.name.v,
            style: AppText.ui(size: 18, weight: FontWeight.w700)),
      ),
      // Refreshes when new chapters or texts download.
      body: ListenableBuilder(
        listenable: Listenable.merge([store, UserStore.instance]),
        builder: (context, _) {
          final c = store.collection(collection.id) ?? collection;
          final chapters = store.chaptersOf(c.id);
          final hadith = chapters.isEmpty ? store.hadithInCollection(c.id) : const <Hadith>[];
          final user = UserStore.instance;
          final tracked = tracksCompletion(c);
          final itemIds = chapters.isNotEmpty
              ? [for (final ch in chapters) ch.id]
              : [for (final h in hadith) h.id];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _BookHeader(collection: c, chapterCount: chapters.length),
              const SizedBox(height: 16),
              if (tracked && itemIds.isNotEmpty) ...[
                _BookProgress(
                  done: user.bookDoneCount(c.id, itemIds),
                  total: itemIds.length,
                  onReset: () => _confirmReset(context, c),
                ),
                const SizedBox(height: 12),
              ],
              if (chapters.isNotEmpty)
                ...[
                  for (final ch in chapters) ...[
                    _ChapterTile(
                      chapter: ch,
                      count: store.entriesInChapter(ch.id).length,
                      done: tracked && user.isBookItemDone(c.id, ch.id),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChapterScreen(chapter: ch, collection: c),
                      )),
                    ),
                    const SizedBox(height: 8),
                  ],
                ]
              else if (hadith.isNotEmpty)
                ...[
                  for (final h in hadith) ...[
                    // Books whose hadith have titles (like the Forty of
                    // an-Nawawi) show a numbered list of titles; others
                    // show the text cards.
                    if (h.title.ar.isNotEmpty)
                      _HadithTitleTile(
                        hadith: h,
                        done: tracked && user.isBookItemDone(c.id, h.id),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              HadithDetailScreen(hadith: h, book: tracked ? c : null),
                        )),
                      )
                    else
                      EntryCard(
                        entry: h,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              HadithDetailScreen(hadith: h, book: tracked ? c : null),
                        )),
                      ),
                    SizedBox(height: h.title.ar.isNotEmpty ? 8 : 10),
                  ],
                ]
              else
                _Empty(text: context.tr('collection_empty')),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmReset(BuildContext context, Collection c) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(ctx.tr('book_reset_q'), style: AppText.ui(size: 17, weight: FontWeight.w700)),
      content: Text(ctx.tr('book_reset_body'), style: AppText.ui(size: 14, height: 1.6)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('book_cancel'), style: AppText.ui(size: 14, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('book_reset'),
              style: AppText.ui(size: 14, weight: FontWeight.w700, color: AppColors.green)),
        ),
      ],
    ),
  );
  if (ok == true) UserStore.instance.resetBook(c.id);
}

/// «أتممت ١٢ من ٦٧» with a bar, and a reset button.
class _BookProgress extends StatelessWidget {
  final int done;
  final int total;
  final VoidCallback onReset;
  const _BookProgress({required this.done, required this.total, required this.onReset});

  @override
  Widget build(BuildContext context) {
    String n(int v) => S.isArabic ? arabicNum(v) : '$v';
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('book_progress', {'n': n(done), 't': n(total)}),
                    style: AppText.ui(size: 13, weight: FontWeight.w700, color: AppColors.green)),
                const SizedBox(height: 6),
                ProgressLine(value: total == 0 ? 0 : done / total, height: 5),
              ],
            ),
          ),
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: done == 0 ? null : onReset,
            icon: const Icon(Icons.restart_alt, size: 18),
            label: Text(context.tr('book_reset'), style: AppText.ui(size: 13, weight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: AppColors.gold),
          ),
        ],
      ),
    );
  }
}

/// Arabic-Indic digits.
String arabicNum(int v) =>
    v.toString().split('').map((c) => '٠١٢٣٤٥٦٧٨٩'[int.parse(c)]).join();

/// Number in a circle, or a green tick when the item is done.
Widget _numberBadge(String number, bool done, Color bg, Color fg) => Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: done ? AppColors.green : bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
          : Text(number, style: AppText.ui(size: 14, weight: FontWeight.w700, color: fg)),
    );

class _BookHeader extends StatelessWidget {
  final Collection collection;
  final int chapterCount;
  const _BookHeader({required this.collection, required this.chapterCount});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.green,
      borderWidth: 0,
      radius: 22,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const PositionedDirectional(
            end: -30,
            top: -30,
            child: Opacity(
              opacity: 0.12,
              child: StarMotif(size: 130, color: Colors.white, strokeWidth: 3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                IconTile(
                  size: 60,
                  radius: 16,
                  color: const Color(0x1FFFFFFF),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(collection.badge,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                            size: 16,
                            weight: FontWeight.w700,
                            color: AppColors.sand,
                            height: 1.1)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(collection.name.v,
                          style: AppText.ui(
                              size: 18, weight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(collection.meta.v,
                          style: AppText.ui(
                              size: 13, color: const Color(0xFFD5E1DB), height: 1.4)),
                      if (chapterCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(context.tr('chapters_on_device', {'n': chapterCount}),
                            style: AppText.ui(size: 12, color: AppColors.sand)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final int count;
  final bool done;
  final VoidCallback onTap;
  const _ChapterTile(
      {required this.chapter, required this.count, required this.onTap, this.done = false});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          _numberBadge('${chapter.number}', done, AppColors.sandSoft, AppColors.goldDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chapter.title.v,
                    style: AppText.ui(size: 15, weight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: 2),
                Text(context.tr('texts_n', {'n': count}),
                    style: AppText.ui(size: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// One numbered hadith in a book without chapters: number, title, narrator.
class _HadithTitleTile extends StatelessWidget {
  final Hadith hadith;
  final bool done;
  final VoidCallback onTap;
  const _HadithTitleTile({required this.hadith, required this.onTap, this.done = false});

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          _numberBadge('${h.numberInBook}', done, AppColors.greenSoft, AppColors.green),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.title.v,
                    style: AppText.ui(size: 15, weight: FontWeight.w600, height: 1.4)),
                if (h.narrator.v.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(h.narrator.v,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.ui(size: 12, color: AppColors.muted)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Column(
        children: [
          const IconTile(
            size: 60,
            radius: 18,
            child: Icon(Icons.menu_book_outlined, color: AppColors.green, size: 28),
          ),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: AppText.ui(size: 14, color: AppColors.muted, height: 1.6)),
        ],
      ),
    );
  }
}
