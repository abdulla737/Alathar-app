import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/content_store.dart';
import '../data/user_store.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/slide_to_confirm.dart';
import '../widgets/entry_card.dart';
import '../widgets/text_size_buttons.dart';
import 'collection_screen.dart';
import 'hadith_detail_screen.dart';

/// One chapter (باب): its title, then its verses, hadith and athar in book
/// order, then its issues (المسائل).
class ChapterScreen extends StatelessWidget {
  final Chapter chapter;
  final Collection collection;

  const ChapterScreen({super.key, required this.chapter, required this.collection});

  @override
  Widget build(BuildContext context) {
    final store = ContentStore.instance;
    final settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text('${collection.name.v} · ${context.tr('chapter_n', {'n': chapter.number})}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.ui(size: 15, weight: FontWeight.w600)),
        actions: [
          // Text size for the whole page: A− / A+
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              final z = settings.bookScale;
              return TextSizeButtons(
                onSmaller: z > AppSettings.minBookScale
                    ? () => settings.setBookScale(z - 0.1)
                    : null,
                onBigger: z < AppSettings.maxBookScale
                    ? () => settings.setBookScale(z + 0.1)
                    : null,
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, settings]),
        builder: (context, _) {
          // Every text on the page (title, verse/hadith cards, المسائل) is
          // scaled together, on top of the phone's own text-size setting.
          final phone = MediaQuery.textScalerOf(context);
          final scaler = TextScaler.linear(phone.scale(14) / 14 * settings.bookScale);
          final ch = store.chapter(chapter.id) ?? chapter;
          final entries = store.entriesInChapter(ch.id);

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scaler),
            child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(ch.title.v,
                  style: S.isRtl
                      ? AppText.arabic(size: 26, weight: FontWeight.w700, height: 1.5)
                      : AppText.ui(size: 22, weight: FontWeight.w700, height: 1.35)),
              const SizedBox(height: 16),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(context.tr('chapter_empty'),
                      textAlign: TextAlign.center,
                      style: AppText.ui(size: 14, color: AppColors.muted)),
                ),
              for (final e in entries) ...[
                EntryCard(
                  entry: e,
                  // Verses are read in place; hadith and athar open their page.
                  onTap: e.kind == HadithKind.ayah
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => HadithDetailScreen(hadith: e),
                          )),
                ),
                const SizedBox(height: 10),
              ],
              if (ch.masail.v.isNotEmpty) ..._masail(context, ch),
              // Kitab at-Tawhid: slide to mark this chapter as completed.
              if (tracksCompletion(collection)) ...[
                const SizedBox(height: 18),
                ListenableBuilder(
                  listenable: UserStore.instance,
                  builder: (context, _) {
                    final user = UserStore.instance;
                    return SlideToConfirm(
                      label: context.tr('book_slide_chapter'),
                      doneLabel: context.tr('book_done_chapter'),
                      confirmed: user.isBookItemDone(collection.id, ch.id),
                      onConfirm: () => user.setBookItemDone(collection.id, ch.id, true),
                      onUndo: () => user.setBookItemDone(collection.id, ch.id, false),
                    );
                  },
                ),
              ],
            ],
          ),
          );
        },
      ),
    );
  }

  List<Widget> _masail(BuildContext context, Chapter ch) => [
                const SizedBox(height: 8),
                AppCard(
                  radius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const StarMotif(size: 20, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Text(context.tr('masail'),
                              style: AppText.ui(size: 15, weight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(ch.masail.v,
                          style: AppText.ui(size: 14, height: 1.9, color: AppColors.body)),
                    ],
                  ),
                ),
      ];
}
