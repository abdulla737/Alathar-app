import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/content_store.dart';
import '../data/sample_data.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'hadith_detail_screen.dart';

/// «العمل» tab: one hadith a day and one action to put into practice.
/// Shows today's action with a "done" button, the streak, the last 7 days
/// and the record of every hadith the user acted on (saved on the phone).
class ActScreen extends StatelessWidget {
  const ActScreen({super.key});

  void _open(BuildContext context, Hadith h) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => HadithDetailScreen(hadith: h)));

  @override
  Widget build(BuildContext context) {
    final store = ContentStore.instance;
    final user = UserStore.instance;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([store, user, AppSettings.instance]),
        builder: (context, _) {
          final h = store.hadithOfToday();
          final done = user.actedToday(h.id);
          final record = user.history;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(context.tr('act_title'), style: AppText.title()),
              const SizedBox(height: 4),
              Text(context.tr('act_sub'),
                  style: AppText.ui(size: 14, color: AppColors.muted)),
              const SizedBox(height: 16),

              _TodayActionCard(
                hadith: h,
                done: done,
                onToggle: () => user.setActedToday(h.id, !done),
                onRead: () => _open(context, h),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                      child: _StatTile(
                          value: '${user.streak}', label: context.tr('stat_streak'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatTile(
                          value: '${user.actedDays}', label: context.tr('stat_days'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _StatTile(
                          value: '${user.actedHadithCount}',
                          label: context.tr('stat_hadith'))),
                ],
              ),
              const SizedBox(height: 16),

              Text(context.tr('act_week'),
                  style: AppText.ui(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              const _WeekStrip(),
              const SizedBox(height: 22),

              Text(context.tr('act_record'),
                  style: AppText.ui(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (record.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(context.tr('act_empty'),
                      textAlign: TextAlign.center,
                      style: AppText.ui(size: 14, color: AppColors.muted)),
                )
              else
                for (final day in record.take(30))
                  for (final id in day.value)
                    if (store.find(id) case final rh?) ...[
                      _RecordTile(
                        dayLabel: _dayLabel(context, day.key),
                        hadith: rh,
                        onTap: () => _open(context, rh),
                      ),
                      const SizedBox(height: 8),
                    ],
            ],
          );
        },
      ),
    );
  }
}

/// "Today", "Yesterday" or the date, for a "YYYY-MM-DD" key.
String _dayLabel(BuildContext context, String key) {
  final now = DateTime.now();
  if (key == UserStore.dayKey(now)) return context.tr('day_today');
  if (key == UserStore.dayKey(DateTime(now.year, now.month, now.day - 1))) {
    return context.tr('day_yesterday');
  }
  final p = key.split('-');
  return p.length == 3 ? '${int.parse(p[2])}/${int.parse(p[1])}/${p[0]}' : key;
}

class _TodayActionCard extends StatelessWidget {
  final Hadith hadith;
  final bool done;
  final VoidCallback onToggle;
  final VoidCallback onRead;

  const _TodayActionCard({
    required this.hadith,
    required this.done,
    required this.onToggle,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    final excerpt = h.title.v.isNotEmpty
        ? h.title.v
        : (h.arabic.length > 120 ? '${h.arabic.substring(0, 120)}…' : h.arabic);
    return AppCard(
      color: AppColors.green,
      borderWidth: 0,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('act_today_label'),
              style: AppText.overline(color: AppColors.sand)
                  .copyWith(fontSize: S.isRtl ? 13 : 11)),
          const SizedBox(height: 10),
          Text(h.action.v.isNotEmpty ? h.action.v : context.tr('act_fallback'),
              style: AppText.ui(
                  size: 19, weight: FontWeight.w700, color: Colors.white, height: 1.5)),
          const SizedBox(height: 14),
          // The hadith this action comes from.
          InkWell(
            onTap: onRead,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined, color: AppColors.sand, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: AppText.arabic(
                            size: 15, color: AppColors.onGreenBody, height: 1.5)),
                  ),
                  const SizedBox(width: 6),
                  Text(context.tr('act_read'),
                      style: AppText.ui(
                          size: 12, weight: FontWeight.w600, color: AppColors.sand)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onToggle,
              style: FilledButton.styleFrom(
                backgroundColor: done ? const Color(0x33FFFFFF) : AppColors.sand,
                foregroundColor: done ? Colors.white : AppColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: Icon(done ? Icons.task_alt : Icons.check_circle_outline, size: 22),
              label: Text(context.tr(done ? 'act_marked' : 'act_mark'),
                  style: AppText.ui(
                      size: 15,
                      weight: FontWeight.w700,
                      color: done ? Colors.white : AppColors.green)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Text(value,
              style: AppText.ui(size: 24, weight: FontWeight.w700, color: AppColors.green)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppText.ui(size: 12, color: AppColors.muted, height: 1.3)),
        ],
      ),
    );
  }
}

/// The last 7 days: a filled circle for each day with a hadith acted on.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  // Monday = 1 … Sunday = 7 (DateTime.weekday).
  static const _names = {
    'ar': ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'],
    'en': ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
    'ur': ['پ', 'م', 'ب', 'ج', 'ج', 'ہ', 'ا'],
  };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final names = _names[AppSettings.instance.language] ?? _names['en']!;
    final user = UserStore.instance;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 6; i >= 0; i--)
            Builder(builder: (context) {
              final day = DateTime(now.year, now.month, now.day - i);
              final done = user.actedOn(day).isNotEmpty;
              final isToday = i == 0;
              return Column(
                children: [
                  Text(names[day.weekday - 1],
                      style: AppText.ui(
                          size: 12,
                          weight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? AppColors.green : AppColors.muted)),
                  const SizedBox(height: 6),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.green : AppColors.surface,
                      border: Border.all(
                          color: done
                              ? AppColors.green
                              : (isToday ? AppColors.gold : AppColors.line),
                          width: isToday ? 2 : 1),
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final String dayLabel;
  final Hadith hadith;
  final VoidCallback onTap;
  const _RecordTile({required this.dayLabel, required this.hadith, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    final title = h.title.v.isNotEmpty
        ? h.title.v
        : (h.arabic.length > 70 ? '${h.arabic.substring(0, 70)}…' : h.arabic);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          const Icon(Icons.task_alt, color: AppColors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dayLabel,
                    style: AppText.ui(size: 11, weight: FontWeight.w600, color: AppColors.gold)),
                const SizedBox(height: 2),
                Text(h.action.v.isNotEmpty ? h.action.v : title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.ui(size: 14, weight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: 2),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: AppText.arabic(size: 13, color: AppColors.muted, height: 1.4)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}
