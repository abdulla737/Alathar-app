import 'package:flutter/material.dart';

import '../config/app_links.dart';
import '../data/quran.dart';
import '../screens/quran_reader_screen.dart' show quranStyle;
import '../theme/app_theme.dart';
import 'common.dart';
import 'quran_ornaments.dart';
import 'share_card.dart';

/// Opens a preview of a verse as a mushaf-style card; "Share" sends it as
/// an image only (no text), ready for WhatsApp.
Future<void> showQuranShare(BuildContext context, int surah, int ayah) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.ground,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SharePreview(
      card: QuranShareCard(surah: surah, ayah: ayah),
      fileName: 'alathar-quran-$surah-$ayah.png',
    ),
  );
}

/// The shared image: a page of the mushaf with the surah banner, the verse
/// in full, its medallion number and the reference. 4:5, or taller for
/// long verses so the text stays readable.
class QuranShareCard extends StatelessWidget {
  final int surah;
  final int ayah;
  const QuranShareCard({super.key, required this.surah, required this.ayah});

  @override
  Widget build(BuildContext context) {
    final s = QuranData.instance.surah(surah);
    final text = s.ayat[ayah - 1];
    final palette = OrnamentPalette.of(QuranStore.instance.ornament);
    final link = AppLinks.forSharing;
    final tall = text.length > 360;
    final textSize = text.length > 700
        ? 17.0
        : text.length > 360
            ? 19.0
            : text.length > 160
                ? 22.0
                : 26.0;
    const gold = Color(0xFFB8913A);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 360,
        height: tall ? 640 : 450,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The mushaf page: paper with a gold double border.
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF7EC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: gold, width: 1.6),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: gold, width: 0.7),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SurahBanner(
                          title: 'سُورَةُ ${s.name}', palette: palette, fontSize: 17),
                      const SizedBox(height: 8),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, box) => Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: box.maxWidth,
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(text: '$text '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: AyahMedallion(
                                        number: arabicDigits(ayah),
                                        size: textSize * 1.2,
                                        palette: palette,
                                      ),
                                    ),
                                  ]),
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: quranStyle(textSize,
                                      color: const Color(0xFF1B1B18), height: 2.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('سورة ${s.name} · الآية ${arabicDigits(ayah)}',
                          textAlign: TextAlign.center,
                          style: AppText.arabic(
                              size: 12, color: const Color(0xFF8A6A22), height: 1.3)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Footer: app name + download link
            Row(
              children: [
                const StarMotif(size: 18, color: AppColors.sand),
                const SizedBox(width: 6),
                Text('الأثر',
                    style: AppText.arabic(
                        size: 19, weight: FontWeight.w700, color: Colors.white, height: 1.1)),
                const SizedBox(width: 6),
                Text('Alathar',
                    textDirection: TextDirection.ltr,
                    style: AppText.ui(size: 12, color: AppColors.onGreenMuted)),
                const Spacer(),
                Flexible(
                  flex: 3,
                  child: Text(
                    link.isEmpty ? 'القرآن والأحاديث والأذكار' : link,
                    textDirection: link.isEmpty ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppText.ui(size: 11, color: AppColors.sand),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
