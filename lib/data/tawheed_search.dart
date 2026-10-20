import 'content_store.dart';
import 'sample_data.dart';

/// Search inside كتاب التوحيد: verses, hadith and athar.
///
/// Arabic is compared without tashkeel and with common spelling variants
/// unified (أ إ آ ٱ → ا, ى → ي, ة → ه, ؤ → و, ئ → ي), so «التوحيد» also finds
/// «التَّوْحِيدِ». A leading «ال» (or وال، بال، فال، لل) is ignored, so
/// «التوكل» also finds «يتوكلون». Every word typed must appear; if no text
/// has them all, texts with the most of them are shown. Results are ranked: words in
/// the chapter or text title count most, then the text itself, then the
/// narrator, explanation and translation; ties keep book order.
class TawheedSearch {
  static const slug = 'kitab-at-tawhid';
  static const fallbackId = 6;

  static final _tashkeel = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');

  /// Text in a form that ignores tashkeel, letter variants and case.
  static String normalize(String s) => s
      .replaceAll(_tashkeel, '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي')
      .replaceAll(RegExp(r'[«»"“”\(\)\[\]﴿﴾،,.؛:!?؟]'), ' ')
      .toLowerCase();

  /// Drops a leading article so the word matches its other forms.
  static String _stem(String w) {
    for (final p in const ['وال', 'بال', 'فال', 'كال', 'لل', 'ال']) {
      if (w.startsWith(p) && w.length - p.length >= 3) return w.substring(p.length);
    }
    return w;
  }

  static int get collectionId {
    for (final c in ContentStore.instance.collections) {
      if (c.slug == slug) return c.id;
    }
    return fallbackId;
  }

  /// Up to [limit] entries of the book matching [query] (best first).
  static List<Hadith> search(String query, {int limit = 10}) {
    final words = normalize(query)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map(_stem)
        .toList();
    if (words.isEmpty) return const [];

    final store = ContentStore.instance;
    final id = collectionId;
    final scored = <(int, Hadith)>[];
    final partial = <(int, Hadith)>[]; // some of the words (fallback)

    for (final h in store.allHadith) {
      if (h.collectionId != id) continue;
      final chapter = h.chapterId == null ? null : store.chapter(h.chapterId!);
      final title = normalize('${h.title.ar} ${h.title.en} ${h.title.ur ?? ''} '
          '${chapter?.title.ar ?? ''} ${chapter?.title.en ?? ''}');
      final text = normalize(h.arabic);
      final other = normalize('${h.narrator.ar} ${h.narrator.en} ${h.explanation.ar} '
          '${h.explanation.en} ${h.translation} ${h.topic.ar} ${h.topic.en}');

      var score = 0;
      var found = 0;
      for (final w in words) {
        final inTitle = title.contains(w);
        final inText = text.contains(w);
        final inOther = other.contains(w);
        if (!inTitle && !inText && !inOther) continue;
        found++;
        if (inTitle) score += 5;
        if (inText) score += 3;
        if (inOther) score += 1;
      }
      if (found == words.length) {
        scored.add((score, h));
      } else if (found > 0) {
        partial.add((found * 100 + score, h));
      }
    }
    final results = scored.isNotEmpty ? scored : partial;

    int order(Hadith h) {
      final ch = h.chapterId == null ? null : store.chapter(h.chapterId!);
      return (ch?.number ?? 0) * 1000 + h.numberInBook;
    }

    results.sort((a, b) {
      final s = b.$1.compareTo(a.$1);
      return s != 0 ? s : order(a.$2).compareTo(order(b.$2));
    });
    return [for (final e in results.take(limit)) e.$2];
  }

  /// A short piece of [text] around the first word found, for the result
  /// list (falls back to the start of the text).
  static String snippet(String text, String query, {int length = 110}) {
    if (text.length <= length) return text;
    final words =
        normalize(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map(_stem);
    // Map positions in the normalized text back to the original text.
    final map = <int>[];
    final buf = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final n = normalize(text[i]);
      for (var k = 0; k < n.length; k++) {
        map.add(i);
      }
      buf.write(n);
    }
    final norm = buf.toString();
    var at = -1;
    for (final w in words) {
      at = norm.indexOf(w);
      if (at >= 0) break;
    }
    if (at < 0 || map.isEmpty) return '${text.substring(0, length)}…';
    final pos = map[at.clamp(0, map.length - 1).toInt()];
    var start = (pos - length ~/ 3).clamp(0, text.length).toInt();
    // Start at a word boundary.
    final space = text.lastIndexOf(' ', start);
    if (space > 0 && start - space < 20) start = space + 1;
    final end = (start + length).clamp(0, text.length).toInt();
    return '${start > 0 ? '…' : ''}${text.substring(start, end)}${end < text.length ? '…' : ''}';
  }
}
