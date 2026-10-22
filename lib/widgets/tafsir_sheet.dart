import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/quran.dart';
import '../data/tafsir.dart';
import '../l10n/strings.dart';
import '../screens/quran_reader_screen.dart' show localNum, ayahMarker, quranStyle;
import '../theme/app_theme.dart';
import 'text_size_buttons.dart';

/// «تفسير السعدي» for one verse, with previous / next to move through the surah.
Future<void> showTafsir(BuildContext context, int surah, int ayah) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _TafsirView(surah: surah, ayah: ayah, controller: controller),
    ),
  );
}

class _TafsirView extends StatefulWidget {
  final int surah;
  final int ayah;
  final ScrollController controller;
  const _TafsirView({required this.surah, required this.ayah, required this.controller});

  @override
  State<_TafsirView> createState() => _TafsirViewState();
}

class _TafsirViewState extends State<_TafsirView> {
  static const _step = 2.0;
  final _store = TafsirStore.instance;
  late int _surah = widget.surah;
  late int _ayah = widget.ayah;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (!_store.isLoaded) {
      _store.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      }, onError: (Object e) {
        if (mounted) setState(() => _error = e);
      });
    }
  }

  void _go(int surah, int ayah) {
    setState(() {
      _surah = surah;
      _ayah = ayah;
    });
    if (widget.controller.hasClients) widget.controller.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final q = QuranData.instance;
    if (!_store.isLoaded) {
      return Center(
        child: _error != null
            ? Text(context.tr('tafsir_error'), style: AppText.ui(size: 14))
            : const CircularProgressIndicator(),
      );
    }
    final e = _store.of(_surah, _ayah);
    final s = q.surah(_surah);
    final range = e == null || e.from == e.to
        ? context.tr('quran_ayah', {'n': localNum(e?.from ?? _ayah)})
        : context.tr('tafsir_ayat_range',
            {'a': localNum(e.from), 'b': localNum(e.to)});
    final from = e?.from ?? _ayah;
    final to = e?.to ?? _ayah;
    final verses = [
      for (var a = from; a <= to; a++) '${s.ayat[a - 1]} ${ayahMarker(a)}',
    ].join(' ');

    // Previous / next explanation (crossing into the next or previous surah).
    final hasPrev = from > 1 || _surah > 1;
    final hasNext = to < s.count || _surah < 114;
    void prev() => from > 1
        ? _go(_surah, from - 1)
        : _go(_surah - 1, q.surah(_surah - 1).count);
    void next() => to < s.count ? _go(_surah, to + 1) : _go(_surah + 1, 1);

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('tafsir_saadi'),
                          style: AppText.ui(size: 17, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                          '${S.isArabic ? 'سورة ${s.name}' : s.translit} · $range',
                          style: AppText.ui(
                              size: 13, weight: FontWeight.w600, color: AppColors.gold)),
                    ],
                  ),
                ),
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
          ),
          Expanded(
            child: ListView(
              controller: widget.controller,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.greenSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(verses,
                      textDirection: TextDirection.rtl,
                      style: quranStyle(20, height: 1.9)),
                ),
                const SizedBox(height: 16),
                Text(
                  e?.text ?? context.tr('tafsir_none'),
                  textDirection: TextDirection.rtl,
                  style: AppText.ui(
                      size: settings.explanationSize, height: 1.8, color: AppColors.body),
                ),
                const SizedBox(height: 12),
                Text(context.tr('tafsir_credit'),
                    style: AppText.ui(size: 11, color: AppColors.muted)),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasPrev ? prev : null,
                      icon: const Icon(Icons.chevron_left),
                      label: Text(context.tr('tafsir_prev'),
                          style: AppText.ui(size: 14, weight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasNext ? next : null,
                      icon: const Icon(Icons.chevron_right),
                      label: Text(context.tr('tafsir_next'),
                          style: AppText.ui(size: 14, weight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
