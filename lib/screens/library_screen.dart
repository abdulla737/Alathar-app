import 'package:flutter/material.dart';

import '../data/content_store.dart';
import '../data/sample_data.dart';
import '../data/tawheed_search.dart';
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
          for (final c in ContentStore.instance.collections) ...[
            _CollectionTile(collection: c, onTap: () => _openCollection(c)),
            const SizedBox(height: 10),
          ],
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
