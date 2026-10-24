import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/reading_plans.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/plan_card.dart';
import 'quran_reader_screen.dart' show localNum;

/// Settings → «الورد اليومي»: «خطط إضافية» with a + button. Each plan has
/// «تفعيل» (shows it on Today with its own progress); tap a plan to change
/// its pages per day, start it again or delete it.
class ExtraPlansRows extends StatelessWidget {
  const ExtraPlansRows({super.key});

  @override
  Widget build(BuildContext context) {
    final q = QuranData.instance;
    return FutureBuilder<void>(
      future: q.ensureLoaded(),
      builder: (context, _) => ListenableBuilder(
        listenable: PlanStore.instance,
        builder: (context, _) => _rows(context, q),
      ),
    );
  }

  Widget _rows(BuildContext context, QuranData q) {
    final store = PlanStore.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(context.tr('plan_extra'),
                    style: AppText.ui(size: 15, weight: FontWeight.w600)),
              ),
              IconButton.filled(
                tooltip: context.tr('plan_add'),
                onPressed: q.isLoaded ? () => _showAddPlan(context) : null,
                style: IconButton.styleFrom(
                    backgroundColor: AppColors.green, foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 22),
              ),
            ],
          ),
        ),
        if (store.plans.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(context.tr('plan_extra_hint'),
                style: AppText.ui(size: 12, height: 1.5, color: AppColors.muted)),
          ),
        if (q.isLoaded)
          for (final p in store.plans) _PlanRow(plan: p),
        if (store.plans.isNotEmpty) const SizedBox(height: 8),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  final ReadingPlan plan;
  const _PlanRow({required this.plan});

  @override
  Widget build(BuildContext context) {
    final q = QuranData.instance;
    final store = PlanStore.instance;
    final (first, last) = plan.pages(q);
    final total = last - first + 1;
    final done = store.pagesDone(plan, first, last);
    final days = ((total - done) / plan.sidesPerDay).ceil();
    return InkWell(
      onTap: () => _showEditPlan(context, plan),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        child: Row(
          children: [
            Icon(plan.kind == PlanKind.khatma ? Icons.auto_stories_outlined : Icons.menu_book_outlined,
                color: plan.active ? AppColors.gold : AppColors.muted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(planTitle(context, plan),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.ui(size: 14, weight: FontWeight.w700)),
                  Text(
                      context.tr('plan_row_sub', {
                        'p': localNum(plan.pagesPerDay),
                        's': localNum(plan.sidesPerDay),
                        'd': localNum(days),
                        'x': localNum((done / total * 100).floor()),
                      }),
                      maxLines: 2,
                      style: AppText.ui(size: 12, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            plan.active
                ? OutlinedButton.icon(
                    onPressed: () => store.setActive(plan.id, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.green,
                      side: const BorderSide(color: AppColors.green),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(context.tr('plan_active'),
                        style: AppText.ui(size: 13, weight: FontWeight.w700, color: AppColors.green)),
                  )
                : FilledButton(
                    onPressed: () => store.setActive(plan.id, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(context.tr('plan_activate'),
                        style: AppText.ui(size: 13, weight: FontWeight.w700, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}

/// − n +
Widget _stepper(int value, int min, int max, ValueChanged<int> onChanged) {
  Widget button(IconData icon, VoidCallback? onTap) => IconButton.outlined(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          side: BorderSide(color: onTap == null ? AppColors.line : AppColors.green),
          foregroundColor: AppColors.green,
        ),
        icon: Icon(icon, size: 18),
      );
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      button(Icons.remove, value > min ? () => onChanged(value - 1) : null),
      SizedBox(
        width: 40,
        child: Text(localNum(value),
            textAlign: TextAlign.center,
            style: AppText.ui(size: 17, weight: FontWeight.w700, color: AppColors.green)),
      ),
      button(Icons.add, value < max ? () => onChanged(value + 1) : null),
    ],
  );
}

Widget _surahPicker(BuildContext context, int value, int min, ValueChanged<int> onChanged) {
  final q = QuranData.instance;
  return DropdownButton<int>(
    value: value,
    isExpanded: true,
    menuMaxHeight: 420,
    underline: const SizedBox.shrink(),
    borderRadius: BorderRadius.circular(12),
    style: AppText.ui(size: 14),
    items: [
      for (var n = min; n <= 114; n++)
        DropdownMenuItem(
          value: n,
          child: Text('${localNum(n)}. ${S.isArabic ? q.surah(n).name : q.surah(n).translit}',
              overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

Widget _labelled(String label, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppText.ui(size: 14, weight: FontWeight.w600)),
          ),
          Expanded(child: Align(alignment: AlignmentDirectional.centerEnd, child: child)),
        ],
      ),
    );

/// «+»: choose ختمة / سورة / من سورة إلى سورة, and pages per day.
Future<void> _showAddPlan(BuildContext context) {
  var kind = PlanKind.khatma;
  var from = 1;
  var to = 114;
  var surah = 2;
  var pages = 1;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, setState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(sheet.tr('plan_new_title'),
                  style: AppText.ui(size: 18, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in PlanKind.values)
                    ChoiceChip(
                      label: Text(sheet.tr('plan_kind_${k.name}')),
                      selected: kind == k,
                      onSelected: (_) => setState(() => kind = k),
                      selectedColor: AppColors.greenSoft,
                      labelStyle: AppText.ui(
                          size: 14,
                          weight: FontWeight.w600,
                          color: kind == k ? AppColors.green : AppColors.body),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (kind == PlanKind.surah)
                _labelled(sheet.tr('plan_surah'),
                    _surahPicker(sheet, surah, 1, (v) => setState(() => surah = v))),
              if (kind == PlanKind.range) ...[
                _labelled(
                    sheet.tr('plan_from'),
                    _surahPicker(sheet, from, 1, (v) => setState(() {
                          from = v;
                          if (to < from) to = from;
                        }))),
                _labelled(sheet.tr('plan_to'),
                    _surahPicker(sheet, to, from, (v) => setState(() => to = v))),
              ],
              _labelled(sheet.tr('wird_quran_pages'),
                  _stepper(pages, 1, PlanStore.maxPagesPerDay, (v) => setState(() => pages = v))),
              Text(sheet.tr('wird_page_hint'),
                  style: AppText.ui(size: 12, height: 1.5, color: AppColors.muted)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  switch (kind) {
                    case PlanKind.khatma:
                      PlanStore.instance.add(kind, 1, 114, pages);
                    case PlanKind.surah:
                      PlanStore.instance.add(kind, surah, surah, pages);
                    case PlanKind.range:
                      PlanStore.instance.add(kind, from, to, pages);
                  }
                  Navigator.of(sheet).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add),
                label: Text(sheet.tr('plan_save'),
                    style: AppText.ui(size: 15, weight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Tap a plan: pages per day, start again, delete.
Future<void> _showEditPlan(BuildContext context, ReadingPlan plan) {
  final store = PlanStore.instance;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (sheet) => ListenableBuilder(
      listenable: store,
      builder: (sheet, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(planTitle(sheet, plan), style: AppText.ui(size: 18, weight: FontWeight.w700)),
              const SizedBox(height: 14),
              _labelled(
                  sheet.tr('wird_quran_pages'),
                  _stepper(plan.pagesPerDay, 1, PlanStore.maxPagesPerDay,
                      (v) => store.setPagesPerDay(plan.id, v))),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await _confirm(sheet, sheet.tr('plan_restart_q'));
                  if (ok) store.restart(plan.id);
                },
                icon: const Icon(Icons.restart_alt, size: 20),
                label: Text(sheet.tr('plan_restart'),
                    style: AppText.ui(size: 15, weight: FontWeight.w700, color: AppColors.green)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final ok = await _confirm(sheet, sheet.tr('plan_delete_q'));
                  if (!ok || !sheet.mounted) return;
                  Navigator.of(sheet).pop();
                  store.remove(plan.id);
                },
                icon: const Icon(Icons.delete_outline, color: Color(0xFFB3261E)),
                label: Text(sheet.tr('plan_delete'),
                    style: AppText.ui(
                        size: 15, weight: FontWeight.w700, color: const Color(0xFFB3261E))),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<bool> _confirm(BuildContext context, String question) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(question, style: AppText.ui(size: 17, weight: FontWeight.w700)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(ctx.tr('book_cancel'), style: AppText.ui(size: 14, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(ctx.tr('quran_resume_yes'),
              style: AppText.ui(size: 14, weight: FontWeight.w700, color: AppColors.green)),
        ),
      ],
    ),
  );
  return ok == true;
}
