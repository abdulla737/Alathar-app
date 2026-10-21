import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/quran.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/text_size_buttons.dart';

/// Numbers in the app language: «١٢» in Arabic, "12" otherwise.
String localNum(int n) => S.isArabic ? arabicDigits(n) : '$n';

/// The Qur'an text style (Amiri Quran, bundled with the app).
TextStyle quranStyle(double size, {Color? color, double height = 2.1}) => TextStyle(
      fontFamily: 'AmiriQuran',
      fontSize: size,
      height: height,
      color: color ?? AppColors.ink,
    );

/// Verse end marker: ﴿١٢﴾.
String ayahMarker(int ayah) => '﴿${arabicDigits(ayah)}﴾';

/// Reads one surah: banner, Basmala and the verses as flowing text.
/// A− / A+ at the top change the size (remembered). Tap a verse to
/// bookmark, copy or share it. The place you stop is saved automatically.
class QuranReaderScreen extends StatefulWidget {
  final int surah;
  final int ayah; // verse to open at
  const QuranReaderScreen({super.key, required this.surah, this.ayah = 1});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  static const _perChunk = 5; // verses per paragraph block
  final _centerKey = GlobalKey();
  final _viewportKey = GlobalKey();
  final Map<int, GlobalKey> _chunkKeys = {};
  final Map<int, TapGestureRecognizer> _taps = {};
  late final Surah _s = QuranData.instance.surah(widget.surah);
  int? _selected;

  int get _chunkCount => (_s.count + _perChunk - 1) ~/ _perChunk;

  /// Items: 0 = banner, 1.._chunkCount = verse blocks, last = next/previous.
  int get _itemCount => _chunkCount + 2;

  /// The list starts at the block holding the verse to open.
  late final int _startItem =
      widget.ayah <= 1 ? 0 : 1 + (widget.ayah.clamp(1, _s.count) - 1) ~/ _perChunk;

  @override
  void initState() {
    super.initState();
    QuranStore.instance.setPosition(_s.number, widget.ayah.clamp(1, _s.count));
  }

  @override
  void dispose() {
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _tap(int ayah) =>
      _taps[ayah] ??= TapGestureRecognizer()..onTap = () => _onAyahTap(ayah);

  Future<void> _onAyahTap(int ayah) async {
    setState(() => _selected = ayah);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (_) => _AyahSheet(surah: _s, ayah: ayah),
    );
    if (mounted) setState(() => _selected = null);
  }

  /// Saves the first verse block at the top of the screen as the place to
  /// continue from.
  void _savePosition() {
    final viewport = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || !viewport.attached) return;
    final top = viewport.localToGlobal(Offset.zero).dy;
    int? best;
    for (final e in _chunkKeys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy;
      final bottom = y + box.size.height;
      if (bottom > top + 24 && (best == null || e.key < best)) best = e.key;
    }
    final ayah = best == null ? 1 : best * _perChunk + 1;
    QuranStore.instance.setPosition(_s.number, ayah.clamp(1, _s.count));
  }

  Widget _item(BuildContext context, int i, double size) {
    if (i == 0) return _Banner(surah: _s, size: size);
    if (i == _itemCount - 1) return _Footer(surah: _s);
    return _chunk(i - 1, size);
  }

  Widget _chunk(int c, double size) {
    final store = QuranStore.instance;
    final first = c * _perChunk + 1;
    final last = math.min(first + _perChunk - 1, _s.count);
    final spans = <InlineSpan>[];
    for (var a = first; a <= last; a++) {
      final selected = _selected == a;
      final saved = store.isBookmarked(_s.number, a);
      final highlight = selected ? AppColors.greenSoft : null;
      spans.add(TextSpan(
        text: _s.ayat[a - 1],
        recognizer: _tap(a),
        style: TextStyle(backgroundColor: highlight),
      ));
      spans.add(TextSpan(
        text: ' ${ayahMarker(a)} ',
        recognizer: _tap(a),
        style: TextStyle(
          color: saved ? AppColors.green : AppColors.gold,
          backgroundColor: highlight,
          fontWeight: saved ? FontWeight.w700 : FontWeight.w400,
        ),
      ));
    }
    return Padding(
      key: _chunkKeys[c] ??= GlobalKey(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        style: quranStyle(size),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: QuranStore.instance,
      builder: (context, _) {
        final store = QuranStore.instance;
        final size = store.size;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.ground,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: Text(S.isArabic ? 'سورة ${_s.name}' : _s.translit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.ui(size: 16, weight: FontWeight.w700)),
            actions: [
              TextSizeButtons(
                onSmaller:
                    size > QuranStore.minSize ? () => store.setSize(size - 2) : null,
                onBigger: size < QuranStore.maxSize ? () => store.setSize(size + 2) : null,
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: NotificationListener<ScrollEndNotification>(
            onNotification: (_) {
              _savePosition();
              return false;
            },
            child: CustomScrollView(
              key: _viewportKey,
              center: _centerKey,
              slivers: [
                // Blocks above the opening verse (built upwards).
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _item(context, _startItem - 1 - i, size),
                    childCount: _startItem,
                  ),
                ),
                SliverList(
                  key: _centerKey,
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _item(context, _startItem + i, size),
                    childCount: _itemCount - _startItem,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// «سورة الكهف» banner, its details and the Basmala.
class _Banner extends StatelessWidget {
  final Surah surah;
  final double size;
  const _Banner({required this.surah, required this.size});

  @override
  Widget build(BuildContext context) {
    final q = QuranData.instance;
    final meta = [
      context.tr(surah.medinan ? 'quran_medinan' : 'quran_meccan'),
      context.tr('quran_ayat', {'n': localNum(surah.count)}),
      context.tr('quran_juz', {'n': localNum(q.juzOf(surah.number, 1))}),
      context.tr('quran_page', {'n': localNum(q.pageOf(surah.number, 1))}),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.sandSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: Column(
              children: [
                Text('سُورَةُ ${surah.name}',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: quranStyle(24, color: AppColors.goldDark, height: 1.6)),
                Text(meta,
                    textAlign: TextAlign.center,
                    style: AppText.ui(size: 12, color: AppColors.muted)),
              ],
            ),
          ),
          if (surah.showsBasmala) ...[
            const SizedBox(height: 10),
            Text(q.basmala,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: quranStyle(size * 0.9, color: AppColors.green, height: 1.9)),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Previous / next surah at the end of a surah.
class _Footer extends StatelessWidget {
  final Surah surah;
  const _Footer({required this.surah});

  void _open(BuildContext context, int n) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuranReaderScreen(surah: n)),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Row(
        children: [
          if (surah.number > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _open(context, surah.number - 1),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr('quran_prev'),
                    style: AppText.ui(size: 14, weight: FontWeight.w600, color: AppColors.green)),
              ),
            ),
          if (surah.number > 1 && surah.number < 114) const SizedBox(width: 10),
          if (surah.number < 114)
            Expanded(
              child: FilledButton(
                onPressed: () => _open(context, surah.number + 1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(context.tr('quran_next'),
                    style: AppText.ui(size: 14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Actions for a tapped verse: bookmark, copy, share, "I stopped here".
class _AyahSheet extends StatelessWidget {
  final Surah surah;
  final int ayah;
  const _AyahSheet({required this.surah, required this.ayah});

  String get _text => surah.ayat[ayah - 1];
  String get _reference => '[${surah.name}: ${arabicDigits(ayah)}]';
  String get _shareText => '$_text ${ayahMarker(ayah)}\n$_reference';

  @override
  Widget build(BuildContext context) {
    final store = QuranStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final saved = store.isBookmarked(surah.number, ayah);
        Widget action(IconData icon, String label, VoidCallback onTap, {bool on = false}) =>
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Icon(icon, color: on ? AppColors.gold : AppColors.green, size: 24),
                      const SizedBox(height: 4),
                      Text(label,
                          textAlign: TextAlign.center,
                          style: AppText.ui(size: 12, weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${context.tr('quran_ayah', {'n': localNum(ayah)})}',
                    style: AppText.ui(size: 13, weight: FontWeight.w700, color: AppColors.gold)),
                const SizedBox(height: 6),
                Text('$_text ${ayahMarker(ayah)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: quranStyle(20, height: 1.9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    action(saved ? Icons.bookmark : Icons.bookmark_border,
                        context.tr(saved ? 'quran_unbookmark' : 'quran_bookmark'),
                        () => store.toggleBookmark(surah.number, ayah),
                        on: saved),
                    action(Icons.copy_rounded, context.tr('quran_copy'), () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final done = context.tr('quran_copied');
                      final nav = Navigator.of(context);
                      await Clipboard.setData(ClipboardData(text: _shareText));
                      nav.pop();
                      messenger.showSnackBar(SnackBar(content: Text(done)));
                    }),
                    action(Icons.ios_share, context.tr('quran_share'), () {
                      final box = context.findRenderObject() as RenderBox?;
                      Share.share(_shareText,
                          sharePositionOrigin: box == null
                              ? null
                              : box.localToGlobal(Offset.zero) & box.size);
                    }),
                    action(Icons.flag_outlined, context.tr('quran_mark_read'), () {
                      final messenger = ScaffoldMessenger.of(context);
                      final done = context.tr('quran_marked');
                      store.setPosition(surah.number, ayah);
                      Navigator.of(context).pop();
                      messenger.showSnackBar(SnackBar(content: Text(done)));
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
