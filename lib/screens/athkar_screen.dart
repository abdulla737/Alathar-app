import 'package:flutter/material.dart';

import '../data/content_store.dart';
import '../data/sample_data.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'athkar_counter_screen.dart';

class AthkarScreen extends StatelessWidget {
  const AthkarScreen({super.key});

  void _openCategory(BuildContext context, AthkarCategory c) {
    final athkar = ContentStore.instance.athkarIn(c.id);
    if (athkar.isEmpty) return;
    UserStore.instance.setAthkarSeenToday(c.id);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AthkarCounterScreen(
        title: c.name.v,
        athkar: athkar,
        onFinished: () => UserStore.instance.setAthkarDoneToday(c.id),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = ContentStore.instance;
    final user = UserStore.instance;
    return SafeArea(
      bottom: false,
      // Refreshes when new athkar download or a session is completed.
      child: ListenableBuilder(
        listenable: Listenable.merge([store, user]),
        builder: (context, _) {
          final morning = store.athkarCategoryBySlug('morning');
          final evening = store.athkarCategoryBySlug('evening');
          final others = store.athkarCategories
              .where((c) => c.slug != 'morning' && c.slug != 'evening')
              .toList();

          Widget session(AthkarCategory c, String when, IconData icon, bool dark) {
            final n = store.athkarIn(c.id).length;
            final done = user.athkarDoneToday(c.id);
            return _SessionCard(
              title: c.name.v,
              subtitle: '$when · ${context.tr('n_athkar', {'n': n})}',
              status: context.tr(done ? 'done' : 'start'),
              progress: done ? 1 : 0,
              icon: icon,
              dark: dark,
              onTap: () => _openCategory(context, c),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text(context.tr('athkar_title'), style: AppText.title())),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(context.tr('from_hisn'),
                        style: AppText.ui(size: 13, color: AppColors.muted)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (morning != null) ...[
                session(morning, context.tr('after_fajr'), Icons.wb_sunny_outlined, false),
                const SizedBox(height: 10),
              ],
              if (evening != null) ...[
                session(evening, context.tr('after_asr'), Icons.nights_stay_outlined, true),
                const SizedBox(height: 22),
              ],

              Text(context.tr('through_day'),
                  style: AppText.ui(size: 15, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.72,
                children: [
                  for (final c in others)
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _openCategory(context, c),
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: user.athkarDoneToday(c.id)
                                    ? AppColors.greenSoft
                                    : AppColors.surface,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Text(c.badge,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                  style: AppText.arabic(
                                      size: 15,
                                      weight: FontWeight.w700,
                                      color: AppColors.green,
                                      height: 1.1)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(c.name.v,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: AppText.ui(
                                  size: 12, weight: FontWeight.w500, height: 1.25)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => AthkarCounterScreen(
                      title: context.tr('free_tasbih'), athkar: SampleData.freeTasbih),
                )),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text('33',
                          style: AppText.ui(
                              size: 15, weight: FontWeight.w700, color: AppColors.green)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('free_tasbih'),
                              style: AppText.ui(size: 15, weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(context.tr('free_tasbih_sub'),
                              style: AppText.ui(size: 12, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final double progress;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _SessionCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.progress,
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : AppColors.ink;
    return AppCard(
      color: dark ? AppColors.green : AppColors.surface,
      borderWidth: dark ? 0 : 1,
      onTap: onTap,
      child: Row(
        children: [
          IconTile(
            size: 52,
            radius: 16,
            color: dark ? const Color(0x1FFFFFFF) : AppColors.sandSoft,
            child: Icon(icon, size: 26, color: dark ? AppColors.sand : AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppText.ui(
                              size: 16, weight: FontWeight.w600, color: fg)),
                    ),
                    Text(status,
                        style: AppText.ui(
                            size: 13,
                            weight: FontWeight.w600,
                            color: dark ? AppColors.sand : AppColors.green)),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressLine(
                  value: progress,
                  color: dark ? AppColors.sand : AppColors.green,
                  track: dark ? const Color(0x2EFFFFFF) : AppColors.greenSoft,
                ),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: AppText.ui(
                        size: 12,
                        color: dark ? AppColors.onGreenMuted : AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
