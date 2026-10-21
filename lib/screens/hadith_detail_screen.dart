import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/sample_data.dart';
import '../data/user_store.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/audio_button.dart';
import '../widgets/common.dart';
import '../widgets/share_card.dart';
import '../widgets/text_size_buttons.dart';

class HadithDetailScreen extends StatelessWidget {
  final Hadith hadith;
  const HadithDetailScreen({super.key, required this.hadith});

  static const _step = 2.0;

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    final settings = AppSettings.instance;
    final store = UserStore.instance;
    // Counts as read (daily-hadith progress on the Today page).
    WidgetsBinding.instance.addPostFrameCallback((_) => store.markRead(h.id));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text('${h.collection.v} · ${h.topic.v}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.ui(size: 15, weight: FontWeight.w600)),
        actions: [
          HadithAudioButton(hadith: h),
          // Hadith text size: A− / A+ (same setting as the slider in Settings)
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) {
              final size = settings.arabicSize;
              return TextSizeButtons(
                onSmaller: size > AppSettings.minArabicSize
                    ? () => settings.setArabicSize(size - _step)
                    : null,
                onBigger: size < AppSettings.maxArabicSize
                    ? () => settings.setArabicSize(size + _step)
                    : null,
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      // Rebuilds when the Arabic size changes or when favorites / ticks change.
      body: ListenableBuilder(
        listenable: Listenable.merge([settings, store]),
        builder: (context, _) {
          // Other reading text grows with the Arabic text (26 = default).
          final k = settings.arabicSize / 26;
          return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            AppCard(
              radius: 24,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (h.title.v.isNotEmpty) ...[
                    Text(
                      h.numberInBook > 0 && h.chapterId == null
                          ? '${h.numberInBook} · ${h.title.v}'
                          : h.title.v,
                      style: AppText.ui(
                          size: 16 * k, weight: FontWeight.w700, color: AppColors.green, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ArabicText(h.arabic,
                      style: AppText.arabic(
                          size: settings.arabicSize + (S.isArabic ? 4 : 1),
                          height: 1.85)),
                  if (!S.isArabic) ...[
                    const SizedBox(height: 14),
                    Text(h.translation, style: AppText.ui(size: 16 * k, height: 1.55)),
                  ],
                  if (h.grade.v.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Pill(h.grade.v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _MetaTile(
                        label: context.tr('narrator'), value: h.narrator.v)),
                const SizedBox(width: 10),
                Expanded(
                    child: _MetaTile(
                        label: context.tr('source'), value: h.fullReference.v)),
              ],
            ),
            // Explanation and "Act on it" show only when the content has them.
            if (h.explanation.v.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(context.tr('explanation'),
                        style: AppText.ui(size: 15, weight: FontWeight.w700)),
                  ),
                  // «الشرح» text size: A− / A+
                  TextSizeButtons(
                    onSmaller: settings.explanationSize > AppSettings.minExplanationSize
                        ? () => settings.setExplanationSize(settings.explanationSize - _step)
                        : null,
                    onBigger: settings.explanationSize < AppSettings.maxExplanationSize
                        ? () => settings.setExplanationSize(settings.explanationSize + _step)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(h.explanation.v,
                  style: AppText.ui(
                      size: settings.explanationSize,
                      height: 1.7,
                      color: AppColors.body)),
            ],
            if (h.action.v.isNotEmpty) ...[
            const SizedBox(height: 16),
            Material(
              color: AppColors.sandSoft,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: CheckboxListTile(
                value: store.actedToday(h.id),
                onChanged: (v) => store.setActedToday(h.id, v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.green,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                title: Text(context.tr('act_today'),
                    style: AppText.ui(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.goldDark,
                        letterSpacing: 0.6)),
                subtitle: Text(h.action.v, style: AppText.ui(size: 14 * k)),
              ),
            ),
            ],
            const SizedBox(height: 16),
            Text(h.attribution.v, style: AppText.ui(size: 11, color: AppColors.muted)),
          ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    final saved = store.isFavorite(h.id);
                    return SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => store.toggleFavorite(h.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          backgroundColor:
                              saved ? AppColors.greenSoft : AppColors.surface,
                          side: const BorderSide(color: AppColors.green),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                            size: 20),
                        label: Text(context.tr(saved ? 'saved' : 'save'),
                            style: AppText.ui(
                                size: 15,
                                weight: FontWeight.w600,
                                color: AppColors.green)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => showHadithShare(context, h),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.ios_share, size: 20),
                    label: Text(context.tr('share_card'),
                        style: AppText.ui(
                            size: 15, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetaTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.ui(size: 12, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: AppText.ui(size: 14, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

