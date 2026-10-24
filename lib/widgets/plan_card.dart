import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/reading_plans.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../screens/plan_settings.dart' show showAddPlan;
import '../screens/quran_reader_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'prayer_widgets.dart';
import 'quran_wird_card.dart' show WirdBar;

/// «سورة البقرة» / "Al-Baqarah".
String surahLabel(QuranData q, int n) =>
    S.isArabic ? 'سورة ${q.surah(n).name}' : q.surah(n).translit;

/// A plan's name: «ختمة», «سورة …» or «من سورة … إلى سورة …».
String planTitle(BuildContext context, ReadingPlan p) {
  final q = QuranData.instance;
  if (!q.isLoaded) return context.tr('plan_khatma');
  return switch (p.kind) {
    PlanKind.khatma => context.tr('plan_khatma'),
    PlanKind.surah => surahLabel(q, p.fromSurah),
    PlanKind.range => context.tr('plan_range',
        {'a': surahLabel(q, p.fromSurah), 'b': surahLabel(q, p.toSurah)}),
  };
}

/// Today cards for every plan ticked in Settings, each followed by a gap;
/// with none, a short «ليس لديك ورد يومي» card that adds one.
class ActivePlanCards extends StatelessWidget {
  const ActivePlanCards({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: QuranData.instance.ensureLoaded(),
      builder: (context, _) {
        if (!QuranData.instance.isLoaded) return const SizedBox(height: 0);
        return ListenableBuilder(
          listenable: PlanStore.instance,
          builder: (context, _) {
            final active = PlanStore.instance.activePlans;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (active.isEmpty) ...[
                  const _NoPlanCard(),
                  const SizedBox(height: 16),
                ],
                for (final p in active) ...[
                  PlanCard(plan: p),
                  const SizedBox(height: 16),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// End of Today: a short «أضف وردًا يوميًا آخر» row that opens the
/// add-plan sheet (only when a plan is already shown; else the
/// «ليس لديك ورد يومي» card is there).
class AddPlanStrip extends StatelessWidget {
  const AddPlanStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlanStore.instance,
      builder: (context, _) {
        if (PlanStore.instance.activePlans.isEmpty) return const SizedBox(height: 0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          // Same colours as the «الأمثال في القرآن» card above it.
          child: AppCard(
            radius: 18,
            color: const Color(0xFFEEF0E2),
            borderColor: const Color(0xFF5A6B1E),
            borderWidth: 1.5,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            onTap: () => showAddPlan(context),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration:
                      const BoxDecoration(color: Color(0xFF5A6B1E), shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('plan_add_more'),
                          style: AppText.ui(
                              size: 14, weight: FontWeight.w700, color: const Color(0xFF4A5818))),
                      Text(context.tr('plan_add_more_sub'),
                          style: AppText.ui(size: 12, color: const Color(0xFF4F5640))),
                    ],
                  ),
                ),
                Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: const Color(0xFF4A5818), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// «ليس لديك ورد يومي» — tap or «أضف وردًا» opens the add-plan sheet.
class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 22,
      borderColor: AppColors.gold,
      borderWidth: 1.2,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: () => showAddPlan(context),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: AppColors.sandSoft, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.auto_stories_outlined, color: AppColors.goldDark, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('plan_none_title'),
                    style: AppText.ui(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(context.tr('plan_none_body'),
                    style: AppText.ui(size: 12, height: 1.5, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => showAddPlan(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.tr('plan_none_btn'),
                style: AppText.ui(size: 13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Today page: one plan — today's pages, the plan's own progress,
/// and a ✓ box once today's pages are read.
class PlanCard extends StatelessWidget {
  final ReadingPlan plan;
  const PlanCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final q = QuranData.instance;
    final store = PlanStore.instance;
    final (first, last) = plan.pages(q);
    final startPage = store.startPage(plan, first, last);
    final endPage = (startPage + plan.sidesPerDay - 1).clamp(startPage, last);
    final (s, ayah) = q.ayatOnPage(startPage).firstWhere(
        (v) => v.$1 >= plan.fromSurah && v.$1 <= plan.toSurah,
        orElse: () => q.ayatOnPage(startPage).first);
    final surah = q.surah(s);

    final goal = plan.sidesPerDay;
    final read = store.readToday(plan);
    final done = read >= goal;
    final total = last - first + 1;
    final pagesDone = store.pagesDone(plan, first, last);
    final percent = (pagesDone / total * 100).floor();
    final started = store.begunToday(plan) || pagesDone > 0;

    void open() {
      store.begin(plan, startPage);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuranReaderScreen(
            surah: s, ayah: ayah, wirdStartPage: startPage, planId: plan.id),
      ));
    }

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
              const Icon(Icons.menu_book_outlined, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('plan_card_label'),
                        style: AppText.ui(size: 11, weight: FontWeight.w700, color: AppColors.gold)),
                    Text(planTitle(context, plan),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.ui(size: 15, weight: FontWeight.w700)),
                  ],
                ),
              ),
              if (done)
                Pill(context.tr('wird_done'),
                    background: AppColors.greenSoft, foreground: AppColors.green)
              else
                Text(context.tr('quran_page', {'n': localNum(startPage)}),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: WirdBar(
                  value: (read / goal).clamp(0.0, 1.0),
                  color: AppColors.green,
                  label: context.tr('quran_today_progress',
                      {'n': localNum(read.clamp(0, goal)), 't': localNum(goal)}),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: WirdBar(
                  value: (pagesDone / total).clamp(0.0, 1.0),
                  color: AppColors.gold,
                  label: context.tr('plan_round_progress', {
                    'p': localNum(percent),
                    'n': localNum(pagesDone),
                    't': localNum(total),
                  }),
                ),
              ),
            ],
          ),
          if (done) ...[
            const SizedBox(height: 10),
            _doneBox(context, q, store),
          ],
          if (plan.rounds > 0) ...[
            const SizedBox(height: 4),
            Text(context.tr('plan_rounds', {'n': localNum(plan.rounds)}),
                style: AppText.ui(size: 11, color: AppColors.gold)),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                    '${surahLabel(q, s)} · ${context.tr('quran_ayah', {'n': localNum(ayah)})} · ${context.tr('quran_page', {'n': localNum(startPage)})}–${localNum(endPage)}',
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

  Widget _doneBox(BuildContext context, QuranData q, PlanStore store) {
    final pages = store.pagesToday(plan);
    final details = <String>[];
    if (pages.isNotEmpty) {
      final a = pages.first, b = pages.last;
      details.add(context.tr('done_wird_pages',
          {'p': a == b ? localNum(a) : '${localNum(a)}–${localNum(b)}'}));
      details.add(surahLabel(q, q.ayatOnPage(a).first.$1));
    }
    final at = UserStore.instance.doneAt('plan:${plan.id}:${UserStore.dayKey(DateTime.now())}');
    if (at != null) details.add(context.tr('done_at', {'t': formatPrayerTime(context, at)}));
    return DoneBox(title: context.tr('done_wird'), details: details.join(' · '));
  }
}
