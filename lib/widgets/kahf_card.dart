import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/reading_plans.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../screens/quran_reader_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'prayer_widgets.dart';

/// Today page, Fridays only: «قراءة سورة الكهف» — how many of its pages
/// are read today, continue where you stopped, and ✓ with details when the
/// whole surah is read.
class KahfCard extends StatelessWidget {
  const KahfCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: QuranData.instance.ensureLoaded(),
      builder: (context, _) {
        if (!QuranData.instance.isLoaded) return const SizedBox(height: 0);
        return ListenableBuilder(
          listenable: Listenable.merge([PlanStore.instance, UserStore.instance]),
          builder: (context, _) => _card(context),
        );
      },
    );
  }

  Widget _card(BuildContext context) {
    final q = QuranData.instance;
    const s = PlanStore.kahfSurah;
    final (first, last) = q.surahPages(s);
    final total = last - first + 1;
    final readPages = PlanStore.instance.kahfPagesToday;
    final read = readPages.where((p) => p >= first && p <= last).length;
    final done = read >= total;
    final started = read > 0;

    // Opens at the first page not read yet (the start when done).
    var page = first;
    if (!done) {
      for (var p = first; p <= last; p++) {
        if (!readPages.contains(p)) {
          page = p;
          break;
        }
      }
    }
    final ayah = q.firstAyahOnPage(s, page);

    void open() => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              QuranReaderScreen(surah: s, ayah: ayah, wirdStartPage: first, kahf: true),
        ));

    final at = UserStore.instance.doneAt('kahf:${UserStore.dayKey(DateTime.now())}');

    return AppCard(
      radius: 22,
      borderColor: done ? AppColors.line : AppColors.gold,
      borderWidth: done ? 1 : 1.5,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.sandSoft, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.light_mode_outlined, color: AppColors.goldDark, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('kahf_title'),
                        style: AppText.ui(size: 16, weight: FontWeight.w700)),
                    Text(context.tr('kahf_sub'),
                        style: AppText.ui(size: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              if (done)
                Pill(context.tr('occ_done'),
                    background: AppColors.greenSoft, foreground: AppColors.green)
              else
                Text(context.tr(started ? 'quran_continue' : 'quran_start'),
                    style: AppText.ui(size: 14, weight: FontWeight.w700, color: AppColors.green)),
            ],
          ),
          const SizedBox(height: 12),
          ProgressLine(value: read / total, height: 8),
          const SizedBox(height: 6),
          Text(
              context.tr('kahf_progress', {'n': localNum(read), 't': localNum(total)}),
              style: AppText.ui(size: 12, color: AppColors.muted)),
          if (done) ...[
            const SizedBox(height: 10),
            DoneBox(
              title: context.tr('kahf_done_box'),
              details: [
                context.tr('kahf_done_details', {'t': localNum(total)}),
                if (at != null) context.tr('done_at', {'t': formatPrayerTime(context, at)}),
              ].join(' · '),
            ),
          ],
        ],
      ),
    );
  }
}
