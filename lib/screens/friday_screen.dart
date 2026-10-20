import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/friday_data.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/text_size_buttons.dart';
import 'hadith_detail_screen.dart';

/// «سنن يوم الجمعة»: every Friday hadith, each opening its full page.
class FridayScreen extends StatelessWidget {
  const FridayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(context.tr('friday_page'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.ui(size: 16, weight: FontWeight.w600)),
        actions: [
          // Text size for the whole page: A− / A+ (shared with book pages)
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
        listenable: settings,
        builder: (context, _) => MediaQuery(
          // Every text on the page scales together.
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                  MediaQuery.textScalerOf(context).scale(14) / 14 * settings.bookScale)),
          child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text(context.tr('friday_intro'),
                style: AppText.ui(size: 14, color: AppColors.muted, height: 1.6)),
            const SizedBox(height: 14),
            for (final h in fridayHadith) ...[
              _FridayTile(
                hadith: h,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => HadithDetailScreen(hadith: h),
                )),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _FridayTile extends StatelessWidget {
  final Hadith hadith;
  final VoidCallback onTap;
  const _FridayTile({required this.hadith, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.sandSoft, shape: BoxShape.circle),
                child: Text('${h.numberInBook}',
                    style: AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.goldDark)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(h.title.v,
                    style: AppText.ui(size: 15, weight: FontWeight.w700, color: AppColors.green)),
              ),
              Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 10),
          Text(h.arabic,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppText.arabic(
                  size: AppSettings.instance.arabicSize - 6, height: 1.8)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(h.reference.v,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.ui(size: 12, color: AppColors.muted)),
              ),
              Pill(h.grade.v),
            ],
          ),
        ],
      ),
    );
  }
}
