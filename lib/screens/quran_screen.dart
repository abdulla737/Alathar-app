import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/tawheed_search.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'quran_reader_screen.dart';

/// «القرآن» tab: continue reading, search, and the list of surahs or juz.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final _search = TextEditingController();
  String _query = '';
  bool _showJuz = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(int surah, [int ayah = 1]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuranReaderScreen(surah: surah, ayah: ayah),
    ));
  }

  /// Surahs matching the search: Arabic name (without tashkeel, any alef
  /// form), English name, or number (also in Arabic digits).
  List<Surah> _filtered(List<Surah> all) {
    final q = _query.trim();
    if (q.isEmpty) return all;
    final digits = q.replaceAllMapped(
        RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
    final number = int.tryParse(digits);
    if (number != null) return all.where((s) => s.number == number).toList();
    final nq = TawheedSearch.normalize(q);
    final lower = q.toLowerCase();
    return all
        .where((s) =>
            TawheedSearch.normalize(s.name).contains(nq) ||
            s.translit.toLowerCase().contains(lower) ||
            s.english.toLowerCase().contains(lower))
        .toList();
  }

  void _showBookmarks() {
    final store = QuranStore.instance;
    final q = QuranData.instance;
    showModalBottomSheet<void>(
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.divider),
                      itemBuilder: (sheet, i) {
                        final (s, a) = list[i];
                        final surah = q.surah(s);
                        return InkWell(
                          onTap: () {
                            Navigator.of(sheet).pop();
                            _open(s, a);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${sheet.tr('quran_ayah', {'n': localNum(a)})}',
                                    style: AppText.ui(
                                        size: 13, weight: FontWeight.w700, color: AppColors.gold)),
                                Text(surah.ayat[a - 1],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textDirection: TextDirection.rtl,
                                    style: quranStyle(18, height: 1.8)),
                              ],
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: FutureBuilder<void>(
        future: QuranData.instance.ensureLoaded(),
        builder: (context, snap) {
          if (!QuranData.instance.isLoaded) {
            return Center(
              child: snap.hasError
                  ? Text('${snap.error}', style: AppText.ui(color: AppColors.muted))
                  : const CircularProgressIndicator(color: AppColors.green),
            );
          }
          return ListenableBuilder(
            listenable: QuranStore.instance,
            builder: (context, _) => _content(context),
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context) {
    final q = QuranData.instance;
    final store = QuranStore.instance;
    final surahs = _filtered(q.surahs);
    final searching = _query.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('quran_title'), style: AppText.title()),
                  Text(context.tr('quran_subtitle'),
                      style: AppText.ui(size: 13, color: AppColors.muted)),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: context.tr('quran_bookmarks'),
              onPressed: _showBookmarks,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.line),
                fixedSize: const Size(44, 44),
              ),
              icon: Icon(
                  store.bookmarks.isEmpty ? Icons.bookmark_border : Icons.bookmark,
                  color: store.bookmarks.isEmpty ? AppColors.ink : AppColors.gold,
                  size: 20),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          style: AppText.ui(size: 15),
          decoration: InputDecoration(
            hintText: context.tr('quran_search'),
            hintStyle: AppText.ui(size: 14, color: AppColors.muted),
            prefixIcon: const Icon(Icons.search, color: AppColors.muted),
            suffixIcon: searching
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => setState(() {
                      _search.clear();
                      _query = '';
                    }),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),

        if (!searching) ...[
          _ContinueCard(onOpen: _open),
          const SizedBox(height: 12),
          _Segment(
            left: context.tr('quran_surahs'),
            right: context.tr('quran_juz_tab'),
            rightSelected: _showJuz,
            onChanged: (juz) => setState(() => _showJuz = juz),
          ),
          const SizedBox(height: 12),
        ],

        if (!searching && _showJuz)
          for (var j = 0; j < q.juzStarts.length; j++)
            _JuzRow(juz: j + 1, onOpen: _open)
        else if (surahs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(context.tr('quran_no_results'),
                textAlign: TextAlign.center,
                style: AppText.ui(size: 14, color: AppColors.muted)),
          )
        else
          for (final s in surahs) _SurahRow(surah: s, onTap: () => _open(s.number)),
        const SizedBox(height: 8),
        Text(context.tr('quran_credit'),
            textAlign: TextAlign.center,
            style: AppText.ui(size: 11, color: AppColors.muted, height: 1.6)),
      ],
    );
  }
}

/// «تابع القراءة» — or «ابدأ القراءة» before the first read.
class _ContinueCard extends StatelessWidget {
  final void Function(int surah, [int ayah]) onOpen;
  const _ContinueCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final store = QuranStore.instance;
    final q = QuranData.instance;
    final s = store.lastSurah;
    final surah = s == null ? null : q.surah(s);
    final ayah = store.lastAyah.clamp(1, surah?.count ?? 1);
    final title = surah == null
        ? context.tr('quran_start_body')
        : '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${context.tr('quran_ayah', {'n': localNum(ayah)})}';
    final sub = surah == null
        ? context.tr('quran_juz', {'n': localNum(1)})
        : '${context.tr('quran_juz', {'n': localNum(q.juzOf(surah.number, ayah))})} · ${context.tr('quran_page', {'n': localNum(q.pageOf(surah.number, ayah))})}';
    return AppCard(
      color: AppColors.green,
      borderWidth: 0,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: () => surah == null ? onOpen(1) : onOpen(surah.number, ayah),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(surah == null ? 'quran_start' : 'quran_continue'),
                    style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.sand)),
                const SizedBox(height: 2),
                Text(title,
                    style: AppText.ui(size: 16, weight: FontWeight.w700, color: Colors.white)),
                Text(sub, style: AppText.ui(size: 12, color: AppColors.onGreenMuted)),
              ],
            ),
          ),
          Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
              color: AppColors.sand, size: 26),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;
  const _Segment(
      {required this.left,
      required this.right,
      required this.rightSelected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget part(String label, bool selected, bool value) => Expanded(
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: AppText.ui(
                      size: 14,
                      weight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.ink : AppColors.muted)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segment,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [part(left, !rightSelected, false), part(right, rightSelected, true)]),
    );
  }
}

class _SurahRow extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;
  const _SurahRow({required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = [
      context.tr(surah.medinan ? 'quran_medinan' : 'quran_meccan'),
      context.tr('quran_ayat', {'n': localNum(surah.count)}),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: onTap,
        child: Row(
          children: [
            _NumberBadge(localNum(surah.number)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.isArabic ? surah.name : '${surah.translit} · ${surah.english}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.ui(size: 15, weight: FontWeight.w700)),
                  Text(meta, style: AppText.ui(size: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Text(surah.name,
                textDirection: TextDirection.rtl,
                style: quranStyle(20, color: AppColors.green, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _JuzRow extends StatelessWidget {
  final int juz;
  final void Function(int surah, [int ayah]) onOpen;
  const _JuzRow({required this.juz, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final q = QuranData.instance;
    final (s, a) = q.juzStarts[juz - 1];
    final surah = q.surah(s);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        onTap: () => onOpen(s, a),
        child: Row(
          children: [
            _NumberBadge(localNum(juz)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('quran_juz', {'n': localNum(juz)}),
                      style: AppText.ui(size: 15, weight: FontWeight.w700)),
                  Text(
                      '${S.isArabic ? 'سورة ${surah.name}' : surah.translit} · ${context.tr('quran_ayah', {'n': localNum(a)})}',
                      style: AppText.ui(size: 12, color: AppColors.muted)),
                ],
              ),
            ),
            Expanded(
              child: Text(surah.ayat[a - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: quranStyle(16, color: AppColors.green, height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final String label;
  const _NumberBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.sandSoft, shape: BoxShape.circle),
        child: Text(label,
            style: AppText.ui(size: 13, weight: FontWeight.w700, color: AppColors.goldDark)),
      );
}
