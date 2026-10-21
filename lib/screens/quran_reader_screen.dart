import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_settings.dart';
import '../data/quran.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/quran_ornaments.dart';
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

/// One verse as coloured pieces by its tajweed rules. Where rules overlap
/// the stronger one shows; spaces keep the normal colour.
List<InlineSpan> tajweedSpans(String text, List<(String, int, int)> rules,
    {GestureRecognizer? recognizer, Color? background}) {
  if (rules.isEmpty) {
    return [
      TextSpan(text: text, recognizer: recognizer, style: TextStyle(backgroundColor: background)),
    ];
  }
  final colors = List<Color?>.filled(text.length, null);
  final prio = List<int>.filled(text.length, 0);
  for (final (rule, start, ruleEnd) in rules) {
    final c = TajweedColors.of(rule);
    if (c == null) continue;
    final p = TajweedColors.priority(rule);
    // Ikhfa, iqlab and idgham: colour only the noon / meem / tanween, as in
    // the printed tajweed mushaf, not the letter it meets.
    final end = _onlyFirstLetter.contains(rule) ? _firstLetterEnd(text, start, ruleEnd) : ruleEnd;
    for (var i = start; i < end && i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x20) continue;
      if (p >= prio[i]) {
        colors[i] = c;
        prio[i] = p;
      }
    }
  }
  final out = <InlineSpan>[];
  var from = 0;
  for (var i = 1; i <= text.length; i++) {
    if (i == text.length || !identical(colors[i], colors[from])) {
      out.add(TextSpan(
        text: text.substring(from, i),
        recognizer: recognizer,
        style: TextStyle(color: colors[from], backgroundColor: background),
      ));
      from = i;
    }
  }
  return out;
}

const _onlyFirstLetter = {
  'ikhfa', 'ikhfa_shafawi', 'iqlab', 'idghaam_ghunnah', 'idghaam_no_ghunnah',
  'idghaam_shafawi', 'idghaam_mutajanisayn', 'idghaam_mutaqaribayn',
};

/// Harakat and Qur'anic marks that sit on a letter.
bool _isMark(int c) =>
    (c >= 0x064B && c <= 0x065F) ||
    c == 0x0670 ||
    (c >= 0x06D6 && c <= 0x06DC) ||
    (c >= 0x06DF && c <= 0x06E4) ||
    c == 0x06E7 ||
    c == 0x06E8 ||
    (c >= 0x06EA && c <= 0x06ED);

/// End of the first letter (with its marks) from [start], within one word.
int _firstLetterEnd(String text, int start, int end) {
  var i = start;
  var letter = false;
  while (i < end && i < text.length) {
    final c = text.codeUnitAt(i);
    if (c == 0x20) break;
    if (!_isMark(c)) {
      if (letter) break;
      letter = true;
    }
    i++;
  }
  return i;
}

/// Verse end marker: ﴿١٢﴾.
String ayahMarker(int ayah) => '﴿${arabicDigits(ayah)}﴾';

/// The Qur'an as mushaf pages (604, Madinah layout): swipe to turn pages.
/// Each surah starts with an arabesque banner; verse numbers sit in
/// medallions. A− / A+ change the size (remembered). Tap a verse to
/// bookmark, copy or share it. The page you stop on is saved automatically.
class QuranReaderScreen extends StatefulWidget {
  final int surah;
  final int ayah; // verse to open at (its page)

  /// Daily reading («ورد التلاوة اليومية»): only today's pages, starting at
  /// this page (count from Settings), then a "done" page. Null = whole mushaf.
  final int? wirdStartPage;
  const QuranReaderScreen(
      {super.key, required this.surah, this.ayah = 1, this.wirdStartPage});

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final _q = QuranData.instance;
  late final int _openAyah = widget.ayah.clamp(1, _q.surah(widget.surah).count);
  late int _page = _q.pageOf(widget.surah, _openAyah).clamp(_firstPage, _lastPage);
  late final PageController _pages = PageController(initialPage: _page - _firstPage);

  bool get _wird => widget.wirdStartPage != null;

  /// First and last page this reader shows (the whole mushaf, or today's
  /// pages in daily-reading mode).
  int get _firstPage => widget.wirdStartPage ?? 1;
  int get _lastPage {
    if (!_wird) return _q.pageCount;
    final end = _firstPage + AppSettings.instance.quranPagesPerDay - 1;
    final rangeEnd = _rangeLastPage();
    // Never below the first page, even if the range changed meanwhile.
    return end.clamp(_firstPage, rangeEnd < _firstPage ? _firstPage : rangeEnd);
  }

  /// Last page of the chosen surahs (Settings → «الورد اليومي»).
  int _rangeLastPage() {
    final last = _q.surah(AppSettings.instance.quranToSurah);
    return _q.pageOf(last.number, last.count);
  }

  int get _windowPages => _lastPage - _firstPage + 1;

  /// Reached the last page of today's reading: tomorrow starts after it
  /// (back to the first chosen surah after the last one).
  void _checkWirdEnd(int page) {
    if (!_wird) return;
    final store = QuranStore.instance;
    final from = _q.pageOf(AppSettings.instance.quranFromSurah, 1);
    final to = _rangeLastPage();
    store.recordProgress(page, from, to);
    if (page != _lastPage) return;
    if (page + 1 > to) {
      // The whole khatma / range is done: start again from its first page.
      store.completeCycle(from, to);
      store.finishWird(from);
    } else {
      store.finishWird(page + 1);
    }
  }
  final Map<int, TapGestureRecognizer> _taps = {};
  int? _selected; // overall index of the tapped verse

  @override
  void initState() {
    super.initState();
    // Saved after the first frame: changing the store while this page is
    // being built would stop it from opening.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      QuranStore.instance.setPosition(widget.surah, _openAyah);
      _countPage(_page);
      _checkWirdEnd(_page);
    });
    _loadTajweed();
    // Briefly highlight the verse that was opened (juz / bookmark / search).
    if (_openAyah > 1) {
      _selected = _q.indexOf(widget.surah, _openAyah);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _selected == _q.indexOf(widget.surah, _openAyah)) {
          setState(() => _selected = null);
        }
      });
    }
  }

  /// Counts the page toward today's reading goal when it is inside the
  /// chosen range of surahs (Settings → «الورد اليومي»).
  void _countPage(int page) {
    final settings = AppSettings.instance;
    final from = _q.pageOf(settings.quranFromSurah, 1);
    final last = _q.surah(settings.quranToSurah);
    final to = _q.pageOf(last.number, last.count);
    if (page >= from && page <= to) QuranStore.instance.markPageRead(page);
  }

  /// The surah shown in the title: the one opened, while its verses are on
  /// the page; otherwise the first surah on the page.
  int _titleSurah(int page) {
    final ayat = _q.ayatOnPage(page);
    if (ayat.any((v) => v.$1 == widget.surah)) return widget.surah;
    return ayat.first.$1;
  }

  @override
  void dispose() {
    _pages.dispose();
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  void _loadTajweed() {
    if (!QuranStore.instance.tajweed || _q.hasTajweed) return;
    _q.ensureTajweed().then((_) {
      if (mounted) setState(() {});
    }, onError: (Object e) => debugPrint('Tajweed not loaded: $e'));
  }

  void _showTajweedSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _TajweedSheet(),
    ).then((_) => _loadTajweed());
  }

  /// Turns to the page of a verse (from the saved list).
  void _goTo(int s, int a) {
    final page = _q.pageOf(s, a);
    if (page < _firstPage || page > _lastPage) {
      // Outside today's pages: open it in the full mushaf.
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => QuranReaderScreen(surah: s, ayah: a),
      ));
      return;
    }
    _pages.jumpToPage(page - _firstPage);
  }

  void _onPageChanged(int index) {
    if (index >= _windowPages) return; // the "done" page after today's reading
    setState(() {
      _page = _firstPage + index;
      _selected = null;
    });
    final (s, a) = _q.ayatOnPage(_page).first;
    QuranStore.instance.setPosition(s, a);
    _countPage(_page);
    _checkWirdEnd(_page);
  }

  TapGestureRecognizer _tap(int s, int a) =>
      _taps[_q.indexOf(s, a)] ??= TapGestureRecognizer()..onTap = () => _onAyahTap(s, a);

  Future<void> _onAyahTap(int s, int a) async {
    setState(() => _selected = _q.indexOf(s, a));
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (_) => _AyahSheet(
        surah: _q.surah(s),
        ayah: a,
        onBookmarks: () => showQuranBookmarks(context, onOpen: _goTo),
      ),
    );
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([QuranStore.instance, AppSettings.instance]),
      builder: (context, _) {
        final store = QuranStore.instance;
        final size = store.size;
        final surah = _q.surah(_titleSurah(_page));
        final titleText = Text(S.isArabic ? 'سورة ${surah.name}' : surah.translit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.ui(size: 16, weight: FontWeight.w700));
        return Scaffold(
          backgroundColor: AppColors.ground,
          appBar: AppBar(
            backgroundColor: AppColors.ground,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 0,
            title: _wird
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleText,
                      Text(
                          context.tr('quran_wird_page', {
                            'n': localNum(_page - _firstPage + 1),
                            't': localNum(_windowPages),
                          }),
                          style: AppText.ui(size: 12, color: AppColors.gold)),
                    ],
                  )
                : titleText,
            actions: [
              IconButton(
                tooltip: context.tr('tajweed_title'),
                onPressed: _showTajweedSheet,
                icon: Icon(store.tajweed ? Icons.palette : Icons.palette_outlined,
                    color: store.tajweed ? TajweedColors.maddJaiz : AppColors.muted),
              ),
              TextSizeButtons(
                onSmaller:
                    size > QuranStore.minSize ? () => store.setSize(size - 2) : null,
                onBigger: size < QuranStore.maxSize ? () => store.setSize(size + 2) : null,
              ),
              const SizedBox(width: 12),
            ],
          ),
          // Pages turn right-to-left like a printed mushaf, in every language.
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: PageView.builder(
              controller: _pages,
              itemCount: _windowPages + (_wird ? 1 : 0),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, i) => i >= _windowPages
                  ? _WirdDone(nextPage: _lastPage + 1 > _q.pageCount ? 1 : _lastPage + 1)
                  : _buildPage(_firstPage + i, size, OrnamentPalette.of(store.ornament)),
            ),
          ),
        );
      },
    );
  }

  /// One mushaf page: double-line border, surah and juz at the top, the
  /// verses (with banners where a surah starts) and the page number.
  Widget _buildPage(int page, double size, OrnamentPalette palette) {
    final store = QuranStore.instance;
    final ayat = _q.ayatOnPage(page);
    final (firstS, firstA) = ayat.first;
    const gold = AppColors.mushafLine;

    final body = <Widget>[];
    var spans = <InlineSpan>[];
    void flush() {
      if (spans.isEmpty) return;
      body.add(Text.rich(
        TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
        style: quranStyle(size),
      ));
      spans = <InlineSpan>[];
    }

    for (final (s, a) in ayat) {
      final surah = _q.surah(s);
      if (a == 1) {
        flush();
        body.add(Padding(
          padding: EdgeInsets.only(top: body.isEmpty ? 0 : 10, bottom: 4),
          child: SurahBanner(
              title: 'سُورَةُ ${surah.name}', palette: palette, fontSize: size * 0.8),
        ));
        if (surah.showsBasmala) {
          body.add(Text(_q.basmala,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: quranStyle(size * 0.92, color: palette.text, height: 1.9)));
        }
      }
      final index = _q.indexOf(s, a);
      final highlight = _selected == index ? AppColors.greenSoft : null;
      spans.addAll(tajweedSpans(
        surah.ayat[a - 1],
        store.tajweed ? _q.tajweedOf(s, a) : const [],
        recognizer: _tap(s, a),
        background: highlight,
      ));
      spans.add(const TextSpan(text: ' '));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => _onAyahTap(s, a),
          child: AyahMedallion(
            number: arabicDigits(a),
            size: size * 1.15,
            palette: palette,
            saved: store.isBookmarked(s, a),
          ),
        ),
      ));
      spans.add(const TextSpan(text: ' '));
    }
    flush();

    final header = AppText.ui(size: 12, weight: FontWeight.w700, color: AppColors.goldDark);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: gold, width: 1.6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: gold, width: 0.7),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Every surah on this page, as in the printed mushaf.
                      Expanded(
                        child: Text(
                            {for (final v in ayat) _q.surah(v.$1).name}.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: header),
                      ),
                      Text(context.tr('quran_juz', {'n': localNum(_q.juzOf(firstS, firstA))}),
                          style: header),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: body,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(arabicDigits(page),
                      textAlign: TextAlign.center,
                      style: AppText.ui(size: 13, weight: FontWeight.w700, color: AppColors.goldDark)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// After today's pages: well done, add a page to today's reading, or go on
/// in the full mushaf.
class _WirdDone extends StatelessWidget {
  final int nextPage;
  const _WirdDone({required this.nextPage});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final q = QuranData.instance;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.gold, size: 64),
            const SizedBox(height: 12),
            Text(context.tr('quran_wird_done_title'),
                textAlign: TextAlign.center,
                style: AppText.ui(size: 20, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(context.tr('quran_wird_done_body'),
                textAlign: TextAlign.center,
                style: AppText.ui(size: 14, color: AppColors.muted, height: 1.6)),
            const SizedBox(height: 22),
            if (settings.quranPagesPerDay < AppSettings.maxQuranPagesPerDay)
              FilledButton.icon(
                onPressed: () => settings.setQuranPagesPerDay(settings.quranPagesPerDay + 1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add),
                label: Text(context.tr('quran_wird_add_page'),
                    style: AppText.ui(size: 15, weight: FontWeight.w700, color: Colors.white)),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                final (s, a) = q.ayatOnPage(nextPage).first;
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => QuranReaderScreen(surah: s, ayah: a),
                ));
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: AppColors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.menu_book_outlined, color: AppColors.green),
              label: Text(context.tr('quran_wird_open_full'),
                  style: AppText.ui(size: 15, weight: FontWeight.w700, color: AppColors.green)),
            ),
          ],
        ),
      ),
    );
  }
}

/// «المحفوظات»: every saved verse; tap to open it, or remove it with ✕.
Future<void> showQuranBookmarks(BuildContext context,
    {required void Function(int surah, int ayah) onOpen}) {
  final store = QuranStore.instance;
  final q = QuranData.instance;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => ListenableBuilder(
      listenable: store,
      builder: (sheet, _) {
        final list = store.bookmarkList;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(sheet.tr('quran_bookmarks'),
                    style: AppText.ui(size: 17, weight: FontWeight.w700)),
              ),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Text(sheet.tr('quran_no_bookmarks'),
                      style: AppText.ui(size: 14, color: AppColors.muted, height: 1.6)),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 8, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
                    itemBuilder: (sheet, i) {
                      final (s, a) = list[i];
                      final surah = q.surah(s);
                      return Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(sheet).pop();
                                onOpen(s, a);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${sheet.tr('quran_ayah', {'n': localNum(a)})} · ${sheet.tr('quran_page', {'n': localNum(q.pageOf(s, a))})}',
                                        style: AppText.ui(
                                            size: 13,
                                            weight: FontWeight.w700,
                                            color: AppColors.gold)),
                                    Text(surah.ayat[a - 1],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection: TextDirection.rtl,
                                        style: quranStyle(18, height: 1.8)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: sheet.tr('quran_unbookmark'),
                            onPressed: () => store.toggleBookmark(s, a),
                            icon: const Icon(Icons.close, color: AppColors.muted),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

/// Actions for a tapped verse: bookmark, copy, share, "I stopped here".
class _AyahSheet extends StatelessWidget {
  final Surah surah;
  final int ayah;
  final VoidCallback? onBookmarks; // opens the list of all saved verses
  const _AyahSheet({required this.surah, required this.ayah, this.onBookmarks});

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
                    if (onBookmarks != null)
                      action(Icons.collections_bookmark_outlined,
                          '${context.tr('quran_bookmarks')} (${localNum(store.bookmarks.length)})', () {
                        Navigator.of(context).pop();
                        onBookmarks!();
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

/// «التجويد»: switch the colours on or off, and what each colour means.
class _TajweedSheet extends StatelessWidget {
  const _TajweedSheet();

  @override
  Widget build(BuildContext context) {
    final store = QuranStore.instance;
    final items = <(Color, String)>[
      (TajweedColors.madd6, 'tj_madd6'),
      (TajweedColors.maddWajib, 'tj_madd_wajib'),
      (TajweedColors.maddJaiz, 'tj_madd_jaiz'),
      (TajweedColors.madd2, 'tj_madd2'),
      (TajweedColors.ghunnah, 'tj_ghunnah'),
      (TajweedColors.qalqalah, 'tj_qalqalah'),
      (TajweedColors.silent, 'tj_silent'),
    ];
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('tajweed_title'),
                  style: AppText.ui(size: 17, weight: FontWeight.w700)),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: store.tajweed,
                activeTrackColor: AppColors.green,
                onChanged: store.setTajweed,
                title: Text(context.tr('tajweed_switch'),
                    style: AppText.ui(size: 15, weight: FontWeight.w600)),
              ),
              const Divider(color: AppColors.divider),
              Text(context.tr('quran_ornament'),
                  style: AppText.ui(size: 15, weight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 0; i < OrnamentPalette.all.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 10),
                      child: GestureDetector(
                        onTap: () => store.setOrnament(i),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: OrnamentPalette.all[i].band,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: store.ornament == i ? AppColors.ink : AppColors.line,
                              width: store.ornament == i ? 3 : 1,
                            ),
                          ),
                          child: store.ornament == i
                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.divider),
              for (final (color, key) in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(context.tr(key),
                            style: AppText.ui(size: 14, color: AppColors.body)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text(context.tr('tajweed_note'),
                  style: AppText.ui(size: 12, color: AppColors.muted, height: 1.6)),
            ],
          ),
        ),
      ),
    );
  }
}
