import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'audio_button.dart';
import 'common.dart';

/// One text inside a book: a Qur'an verse, a hadith or an athar.
/// Verses sit on a sand background in ﴿ ﴾ brackets; hadith open their page.
class EntryCard extends StatelessWidget {
  final Hadith entry;
  final VoidCallback? onTap;

  const EntryCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final isAyah = e.kind == HadithKind.ayah;
    final label = switch (e.kind) {
      HadithKind.ayah => context.tr('kind_ayah'),
      HadithKind.athar => context.tr('kind_athar'),
      HadithKind.hadith => context.tr('kind_hadith'),
    };
    final text = isAyah ? '﴿${e.arabic}﴾' : e.arabic;

    return AppCard(
      radius: 18,
      color: isAyah ? AppColors.sandSoft : AppColors.surface,
      borderWidth: isAyah ? 0 : 1,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill(label,
                  background: isAyah ? AppColors.surface : AppColors.greenSoft,
                  foreground: isAyah ? AppColors.goldDark : AppColors.green),
              if (e.grade.v.isNotEmpty) ...[
                const SizedBox(width: 6),
                Pill(e.grade.v,
                    background: AppColors.ground,
                    foreground: AppColors.ink,
                    weight: FontWeight.w600),
              ],
              const Spacer(),
              // Verses are read in place, so they get their own 🔊 (al-Husary).
              if (isAyah && e.quranRef.isNotEmpty)
                SizedBox(
                  height: 32,
                  child: HadithAudioButton(
                      hadith: e, color: AppColors.goldDark, size: 22),
                ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          ArabicText(text,
              align: isAyah ? TextAlign.center : TextAlign.right,
              style: AppText.arabic(
                  size: isAyah ? 24 : 21,
                  height: 1.8,
                  color: isAyah ? AppColors.brown : AppColors.ink)),
          if (!S.isArabic && e.localTranslation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(e.localTranslation,
                textDirection: TextDirection.ltr,
                style: AppText.ui(size: 14, height: 1.5, color: AppColors.body)),
          ],
          const SizedBox(height: 10),
          Text(
            [
              if (e.narrator.v.isNotEmpty) e.narrator.v,
              if (e.reference.v.isNotEmpty) e.reference.v,
            ].join(' · '),
            style: AppText.ui(size: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
