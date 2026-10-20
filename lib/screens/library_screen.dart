import 'package:flutter/material.dart';

import '../data/content_store.dart';
import '../data/tawheed_search.dart';
import '../data/sample_data.dart';
import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'collection_screen.dart';
import 'hadith_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _showTopics = false;
  final _search = TextEditingController();
  String _query = '';

  // Rebuild when new books download from Supabase.
  void _onContent() => setState(() {});

  @override
  void initState() {
    super.initState();
    ContentStore.instance.addListener(_onContent);
  }

  @override
  void dispose() {
    ContentStore.instance.removeListener(_onContent);
    _search.dispose();
    super.dispose();
  }

  void _openCollection(Collection c) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CollectionScreen(collection: c),
    ));
  }

  void _openResult(Hadith h) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HadithDetailScreen(hadith: h),
    ));
  }

  void _openHadith() {
    // TODO: open the selected collection/topic list instead.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HadithDetailScreen(hadith: ContentStore.instance.hadithOfToday()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(context.tr('hadith_title'), style: AppText.title()),
          const SizedBox(height: 16),
          // Search كتاب التوحيد: the 10 closest texts appear below as you type.
          TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            style: AppText.ui(size: 15),
            decoration: InputDecoration(
              hintText: context.tr('search_hint'),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.tr('search_clear'),
                      icon: const Icon(Icons.close, color: AppColors.muted),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              hintStyle: AppText.ui(size: 15, color: AppColors.muted),
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.green, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_query.trim().length >= 2)
            ..._results(context)
          else ...[
          _Segmented(
            first: context.tr('collections'),
            second: context.tr('topics'),
            secondSelected: _showTopics,
            onChanged: (v) => setState(() => _showTopics = v),
          ),
          const SizedBox(height: 16),
          if (!_showTopics)
            ...[
              for (final c in ContentStore.instance.collections) ...[
                _CollectionTile(collection: c, onTap: () => _openCollection(c)),
                const SizedBox(height: 10),
              ],
            ]
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.0,
              children: [
                for (final t in SampleData.topics)
                  AppCard(
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    onTap: _openHadith,
                    child: S.isArabic
                        // Arabic: one large title is enough.
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(t.name.v,
                                style: AppText.arabic(
                                    size: 22,
                                    weight: FontWeight.w700,
                                    color: AppColors.green,
                                    height: 1.3)),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ArabicText(t.arabic,
                                  style: AppText.arabic(
                                      size: 18, color: AppColors.gold, height: 1.2)),
                              Text(t.name.v,
                                  style: AppText.ui(size: 15, weight: FontWeight.w600)),
                            ],
                          ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _results(BuildContext context) {
    final results = TawheedSearch.search(_query, limit: 10);
    return [
      Text(
          results.isEmpty
              ? context.tr('search_none')
              : context.tr('search_results', {'n': results.length}),
          style: AppText.ui(size: 13, weight: FontWeight.w600, color: AppColors.muted)),
      const SizedBox(height: 10),
      for (final h in results) ...[
        _ResultTile(hadith: h, query: _query, onTap: () => _openResult(h)),
        const SizedBox(height: 8),
      ],
    ];
  }
}

/// One search result: chapter, kind, and the text around the word found.
class _ResultTile extends StatelessWidget {
  final Hadith hadith;
  final String query;
  final VoidCallback onTap;
  const _ResultTile({required this.hadith, required this.query, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final h = hadith;
    final ch = h.chapterId == null ? null : ContentStore.instance.chapter(h.chapterId!);
    final kind = switch (h.kind) {
      HadithKind.ayah => context.tr('kind_ayah'),
      HadithKind.athar => context.tr('kind_athar'),
      HadithKind.hadith => context.tr('kind_hadith'),
    };
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Pill(kind),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    ch == null
                        ? h.collection.v
                        : '${context.tr('chapter_n', {'n': ch.number})} · ${ch.title.v}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.ui(size: 12, weight: FontWeight.w600, color: AppColors.green)),
              ),
              Icon(S.isRtl ? Icons.chevron_left : Icons.chevron_right,
                  size: 20, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 8),
          Text(TawheedSearch.snippet(h.arabic, query),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppText.arabic(size: 17, height: 1.75)),
        ],
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;
  const _CollectionTile({required this.collection, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          IconTile(
            size: 52,
            color: AppColors.green,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(collection.badge,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: AppText.arabic(
                      size: 15,
                      weight: FontWeight.w700,
                      color: AppColors.sand,
                      height: 1.1)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collection.name.v,
                    style: AppText.ui(size: 15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(collection.meta.v,
                    style: AppText.ui(size: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String first;
  final String second;
  final bool secondSelected;
  final ValueChanged<bool> onChanged;

  const _Segmented({
    required this.first,
    required this.second,
    required this.secondSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool selected, VoidCallback onTap) {
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: selected
                    ? const [
                        BoxShadow(
                            color: Color(0x1417201C), blurRadius: 2, offset: Offset(0, 1))
                      ]
                    : null,
              ),
              child: Text(label,
                  style: AppText.ui(
                      size: 14,
                      weight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColors.ink : AppColors.muted)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segment,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg(first, !secondSelected, () => onChanged(false)),
          seg(second, secondSelected, () => onChanged(true)),
        ],
      ),
    );
  }
}
