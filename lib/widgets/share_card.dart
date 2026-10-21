import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_links.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Opens a preview of the share card for [h]. "Share" turns the card into an
/// image and opens the phone's share sheet (choose WhatsApp there), with a
/// short message and the download link.
Future<void> showHadithShare(BuildContext context, Hadith h) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.ground,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheet) => SharePreview(
      card: HadithShareCard(hadith: h),
      fileName: 'alathar-hadith-${h.id}.png',
      text: shareMessage(context, h),
    ),
  );
}

/// Preview of a designed card with a "Share" button that sends it as an
/// image. [text] goes with the image (null = the image only).
class SharePreview extends StatefulWidget {
  final Widget card;
  final String fileName;
  final String? text;
  const SharePreview({super.key, required this.card, required this.fileName, this.text});

  @override
  State<SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends State<SharePreview> {
  final _cardKey = GlobalKey();
  final _buttonKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      // 1. The card as a PNG (3× for a sharp 1080-pixel-wide image).
      final boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception('no image data');
      final bytes = data.buffer.asUint8List();

      // 2. Where the share sheet opens from (needed on iPad).
      final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin =
          box == null ? null : box.localToGlobal(Offset.zero) & box.size;

      // 3. Share image + message. Pick WhatsApp in the share sheet.
      await Share.shareXFiles(
        [
          XFile.fromData(bytes, mimeType: 'image/png', name: widget.fileName),
        ],
        text: widget.text,
        sharePositionOrigin: origin,
      );
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('share_failed'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.line, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            // The preview is scaled to fit; the image is made at full size.
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.62),
              child: FittedBox(
                child: RepaintBoundary(
                  key: _cardKey,
                  child: widget.card,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                key: _buttonKey,
                onPressed: _busy ? null : _share,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.ios_share, size: 20),
                label: Text(context.tr('share_now'),
                    style: AppText.ui(
                        size: 15, weight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
            Text(context.tr('share_hint'),
                textAlign: TextAlign.center,
                style: AppText.ui(size: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

/// The text sent with the image (WhatsApp shows it as the caption on
/// Android; on iPhone WhatsApp may drop it, so the link is also on the image).
String shareMessage(BuildContext context, Hadith h) {
  final text = h.arabic.length > 220 ? '${h.arabic.substring(0, 220)}…' : h.arabic;
  final ref = [h.narrator.v, h.reference.v].where((s) => s.isNotEmpty).join(' · ');
  final link = AppLinks.forSharing;
  return [
    '«$text»',
    if (ref.isNotEmpty) ref,
    '',
    link.isEmpty ? context.tr('share_from_app') : '${context.tr('share_download')} $link',
  ].join('\n');
}

/// The designed card that becomes the shared image (360 × 450, 4:5).
class HadithShareCard extends StatelessWidget {
  final Hadith hadith;
  const HadithShareCard({super.key, required this.hadith});

  static const _maxChars = 420;

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    final long = h.arabic.length > _maxChars;
    final text = long ? '${h.arabic.substring(0, _maxChars)}…' : h.arabic;
    final link = AppLinks.forSharing;
    final textSize = text.length > 300
        ? 17.0
        : text.length > 160
            ? 19.0
            : 23.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 360,
        height: 450,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: book · title
            Row(
              children: [
                const StarMotif(size: 22, color: AppColors.sand),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [h.collection.ar, h.title.ar].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.arabic(size: 14, color: AppColors.sand, height: 1.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Hadith text
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Long texts shrink to fit the box instead of overflowing.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: box.maxWidth,
                              child: Text(
                                text,
                                textAlign: TextAlign.center,
                                style: AppText.arabic(size: textSize, height: 1.75),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (long)
                      Text('… اقرأ الحديث كاملًا في تطبيق الأثر',
                          textAlign: TextAlign.center,
                          style: AppText.arabic(size: 11, color: AppColors.gold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [h.narrator.ar, h.reference.ar]
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.arabic(
                                size: 11, color: AppColors.muted, height: 1.4),
                          ),
                        ),
                        if (h.grade.ar.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Pill(h.grade.ar),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Footer: app name + download link
            Row(
              children: [
                Text('الأثر',
                    style: AppText.arabic(
                        size: 20,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1)),
                const SizedBox(width: 6),
                Text('Alathar',
                    textDirection: TextDirection.ltr,
                    style: AppText.ui(size: 12, color: AppColors.onGreenMuted)),
                const Spacer(),
                Flexible(
                  flex: 3,
                  child: Text(
                    link.isEmpty ? 'تطبيق الأحاديث والأذكار' : link,
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
