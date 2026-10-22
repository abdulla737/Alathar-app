import 'package:flutter/material.dart';

import '../data/app_settings.dart';
import '../data/quran.dart';
import '../data/stories.dart';
import '../data/story_store.dart';
import '../data/tafsir.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/slide_to_confirm.dart';
import '../widgets/text_size_buttons.dart';
import 'quran_reader_screen.dart';

/// «قصص قرآنية»: one reading — the summary, every verse of it with the Sa'di
/// tafsir (as Sa'di groups them), the lessons, and a slide to finish.
class StoryScreen extends StatefulWidget {
  final StoryUnit unit;
  const StoryScreen({super.key, required this.unit});

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

/// Verses [from]..[to] of one surah with the tafsir that covers them.
class _Block {
  final int from;
  final int to;
  final String? tafsir;
  const _Block(this.from, this.to, this.tafsir);
}

class _StoryScreenState extends State<StoryScreen> {
  static const _step = 2.0;
  final _scroll = ScrollController();
  late final Future<void> _ready =
      Future.wait([QuranData.instance.ensureLoaded(), TafsirStore.instance.ensureLoaded()]);
  bool _withTafsir = true;
  final Set<int> _closed = {};
  bool _resumed = false;

  StoryUnit get unit => widget.unit;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_saveProgress);
  }

  @override
  void dispose() {
    _scroll.removeListener(_saveProgress);
    _scroll.dispose();
    super.dispose();
  }

  /// Keeps how far down the page was read (only ever moves forward).
  void _saveProgress() {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (max <= 0) return;
    final store = StoryStore.instance;
    final f = (_scroll.offset / max).clamp(0.0, 1.0);
    if (f > store.progressOf(unit)) store.setProgress(unit, f);
  }

  /// Back where the reading stopped last time.
  void _resume() {
    if (_resumed) return;
    _resumed = true;
    final f = StoryStore.instance.progressOf(unit);
    if (f <= 0.02 || f >= 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent * f);
    });
  }

  List<_Block> _blocks() {
    final p = unit.part;
    final t = TafsirStore.instance;
    final out = <_Block>[];
    var a = p.from;
    while (a <= p.to) {
      final e = t.of(p.surah, a);
      if (e == null) {
        out.add(_Block(a, a, null));
        a++;
        continue;
      }
      final to = e.to < p.to ? e.to : p.to;
      out.add(_Block(a, to, e.text));
      a = to + 1;
    }
    return out;
  }

  void _openNext() {
    final next = StoryUnit(unit.story, unit.index + 1);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => StoryScreen(unit: next)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.ground,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(context.tr('stories_title'),
            style: AppText.ui(size: 15, weight: FontWeight.w600)),
        actions: [
          ListenableBuilder(
            listenable: settings,
            builder: (context, _) => TextSizeButtons(
              onSmaller: settings.explanationSize > AppSettings.minExplanationSize
                  ? () => settings.setExplanationSize(settings.explanationSize - _step)
                  : null,
              onBigger: settings.explanationSize < AppSettings.maxExplanationSize
                  ? () => settings.setExplanationSize(settings.explanationSize + _step)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snap) {
          if (!QuranData.instance.isLoaded || !TafsirStore.instance.isLoaded) {
            return Center(
              child: snap.hasError
                  ? Text(context.tr('tafsir_error'), style: AppText.ui(size: 14))
                  : const CircularProgressIndicator(color: AppColors.green),
            );
          }
          _resume();
          return ListenableBuilder(
            listenable: Listenable.merge([settings, StoryStore.instance]),
            builder: (context, _) => _content(context, settings),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, AppSettings settings) {
    final story = unit.story;
    final part = unit.part;
    final surah = QuranData.instance.surah(part.surah);
    final store = StoryStore.instance;
    final blocks = _blocks();
    final textSize = settings.explanationSize;
    String n(int v) => localNum(v);

    Widget chip(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(t,
              style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.onGreenBody)),
        );

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        // Header
        AppCard(
          color: AppColors.green,
          borderWidth: 0,
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (story.hasParts) ...[
                Text(
                    '${context.tr('stories_part', {'n': n(unit.index + 1), 't': n(story.parts.length)})} · ${part.name?.v ?? ''}',
                    style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.sand)),
                const SizedBox(height: 6),
              ],
              Text(story.name.v,
                  style: AppText.ui(
                      size: 26, weight: FontWeight.w700, color: Colors.white, height: 1.3)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  chip(S.isArabic ? 'سورة ${surah.name}' : surah.translit),
                  chip(context.tr('tafsir_ayat_range', {'a': n(part.from), 'b': n(part.to)})),
                  chip(context.tr('quran_ayat', {'n': n(part.count)})),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // «القصة باختصار»
        Text(context.tr('stories_summary'), style: AppText.ui(size: 15, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        AppCard(
          child: Text(story.summary.v,
              style: AppText.ui(size: textSize, height: 1.8, color: AppColors.body)),
        ),
        const SizedBox(height: 18),

        // The verses with the tafsir
        Row(
          children: [
            Expanded(
              child: Text(context.tr('stories_verses_tafsir'),
                  style: AppText.ui(size: 15, weight: FontWeight.w700)),
            ),
            _Toggle(
              first: context.tr('stories_with_tafsir'),
              second: context.tr('stories_verses_only'),
              firstSelected: _withTafsir,
              onChanged: (v) => setState(() => _withTafsir = v),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < blocks.length; i++) ...[
          _VerseBlock(
            surah: surah,
            block: blocks[i],
            showTafsir: _withTafsir,
            open: !_closed.contains(i),
            textSize: textSize,
            onToggle: () => setState(() => _closed.contains(i) ? _closed.remove(i) : _closed.add(i)),
          ),
          const SizedBox(height: 10),
        ],

        // «دروس وعبر» after the last part
        if (unit.isLast) ...[
          const SizedBox(height: 8),
          Text(context.tr('stories_lessons'), style: AppText.ui(size: 15, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          AppCard(
            color: AppColors.sandSoft,
            borderWidth: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < story.lessons.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Text(n(i + 1),
                              style: AppText.ui(
                                  size: 14, weight: FontWeight.w700, color: AppColors.gold)),
                        ),
                        Expanded(
                          child: Text(story.lessons[i].v,
                              style: AppText.ui(size: 14, height: 1.7, color: AppColors.brown)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Open these verses in the mushaf
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => QuranReaderScreen(surah: part.surah, ayah: part.from),
          )),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.green,
            side: const BorderSide(color: AppColors.green, width: 1.2),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.menu_book_outlined, size: 20),
          label: Text(context.tr('stories_open_mushaf'),
              style: AppText.ui(size: 15, weight: FontWeight.w700, color: AppColors.green)),
        ),
        const SizedBox(height: 14),

        SlideToConfirm(
          label: context.tr('stories_slide'),
          doneLabel: context.tr('stories_slide_done'),
          confirmed: store.isDone(unit),
          onConfirm: () => store.setDone(unit, true),
          onUndo: () => store.setDone(unit, false),
        ),

        // Next part, once this one is done
        if (store.isDone(unit) && !unit.isLast) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _openNext,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.green,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
                '${context.tr('stories_next_part')} · ${story.parts[unit.index + 1].name?.v ?? ''}',
                style: AppText.ui(size: 15, weight: FontWeight.w700, color: Colors.white)),
          ),
        ],
        const SizedBox(height: 16),
        Text(context.tr('tafsir_credit'), style: AppText.ui(size: 11, color: AppColors.muted)),
      ],
    );
  }
}

/// One group of verses on mushaf paper, with its tafsir that opens and closes.
class _VerseBlock extends StatelessWidget {
  final Surah surah;
  final _Block block;
  final bool showTafsir;
  final bool open;
  final double textSize;
  final VoidCallback onToggle;
  const _VerseBlock({
    required this.surah,
    required this.block,
    required this.showTafsir,
    required this.open,
    required this.textSize,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final verses = [
      for (var a = block.from; a <= block.to; a++) '${surah.ayat[a - 1]} ${ayahMarker(a)}',
    ].join(' ');
    final hasTafsir = showTafsir && (block.tafsir?.isNotEmpty ?? false);
    final label = block.from == block.to
        ? context.tr('tafsir_saadi')
        : '${context.tr('tafsir_saadi')} · ${context.tr('tafsir_ayat_range', {'a': localNum(block.from), 'b': localNum(block.to)})}';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.paper,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(verses,
                textDirection: TextDirection.rtl,
                style: quranStyle(textSize + 6, height: 2.0)),
          ),
          if (hasTafsir) ...[
            InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.gold),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(open ? label : context.tr('stories_read_tafsir'),
                          style: AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.gold)),
                    ),
                    Icon(open ? Icons.expand_less : Icons.expand_more,
                        size: 20, color: AppColors.muted),
                  ],
                ),
              ),
            ),
            if (open)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(block.tafsir!,
                    textDirection: TextDirection.rtl,
                    style: AppText.ui(size: textSize, height: 1.8, color: AppColors.body)),
              ),
          ],
        ],
      ),
    );
  }
}

/// «مع التفسير | الآيات فقط».
class _Toggle extends StatelessWidget {
  final String first;
  final String second;
  final bool firstSelected;
  final ValueChanged<bool> onChanged;
  const _Toggle(
      {required this.first,
      required this.second,
      required this.firstSelected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget part(String label, bool selected, bool value) => GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(label,
                style: AppText.ui(
                    size: 12,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.ink : AppColors.muted)),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.segment,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [part(first, firstSelected, true), part(second, !firstSelected, false)],
      ),
    );
  }
}
