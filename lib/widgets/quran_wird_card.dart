import 'package:flutter/material.dart';

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
          listenable: QuranStore.instance,
          builder: (context, _) => _card(context),
        );
      },
    );
  }

  Widget _card(BuildContext context) {
    final q = QuranData.instance;
    final store = QuranStore.instance;
    final s = store.lastSurah ?? 1;
    final surah = q.surah(s);
    final ayah = store.lastSurah == null ? 1 : store.lastAyah.clamp(1, surah.count);
    final started = store.lastSurah != null;
    final progress = started ? (q.indexOf(s, ayah) + 1) / QuranData.totalAyat : 0.0;
    final percent = (progress * 100).round();

    void open() => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => QuranReaderScreen(surah: s, ayah: ayah),
        ));

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
          ProgressLine(value: progress, height: 5),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                    started
                        ? '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${context.tr('quran_ayah', {'n': localNum(ayah)})} · ${context.tr('quran_progress', {'p': localNum(percent)})}'
                        : context.tr('quran_start_body'),
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
