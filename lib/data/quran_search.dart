import 'package:flutter/foundation.dart';

import 'quran.dart';

/// One verse found by [QuranSearch].
class QuranHit {
  final int surah;
  final int ayah;
  final String text;
  final bool exact; // the words appear together, in the order typed
  const QuranHit(this.surah, this.ayah, this.text, this.exact);
}

/// Forgiving word search over the whole Qur'an.
///
/// The typed words do not need tashkeel, the exact letter forms, the
/// Uthmani spelling, a full word, or the same order: «الصلاة» finds
/// «ٱلصَّلَوٰةَ», «رحمن رحيم» finds «ٱلرَّحْمَٰنِ ٱلرَّحِيمِ», «كتاب» finds
/// «وَٱلْكِتَٰبِ». A verse matches when every typed word is in it; verses
/// with the words together and in order come first.
class QuranSearch {
  QuranSearch._();

  static List<String>? _index; // skeleton of every verse, mushaf order
  static Future<void>? _building;

  // Tashkeel and Qur'anic marks (keeps the letters themselves).
  static final _marks =
      RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ࣓-ࣿ]');

  /// Reduces text to a "skeleton" that ignores how a word is spelled:
  /// no marks, one form per letter, and no alef at all (Uthmani writing
  /// often drops or adds it, as in «الكتب» / «الكتاب»).
  static String skeleton(String s) => s
      .replaceAll('وٰ', 'ا') // صلوٰة → صلاة
      .replaceAll('ؤ', 'ؤ')
      .replaceAll(_marks, '')
      .replaceAll(RegExp('[أإآٱٲٳ]'), 'ا')
      .replaceAll(RegExp('[ىیئ]'), 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll(RegExp('[ةۃ]'), 'ه')
      .replaceAll('ک', 'ك')
      .replaceAll(RegExp('[اء]'), '')
      .replaceAll(RegExp(r'[^ء-ي\s]'), '')
      .toLowerCase();

  static List<String> _build(List<List<String>> surahs) => [
        for (final ayat in surahs)
          for (final a in ayat) skeleton(a).replaceAll(RegExp(r'\s+'), ' '),
      ];

  /// Builds the index in the background (about 6,236 short strings).
  static Future<void> ensureIndex() {
    if (_index != null) return Future.value();
    return _building ??= () async {
      await QuranData.instance.ensureLoaded();
      final texts = [for (final s in QuranData.instance.surahs) s.ayat];
      _index = await compute(_build, texts);
    }();
  }

  static bool get ready => _index != null;

  /// Verses matching [query] (best first), at most [limit]. [total] is how
  /// many verses matched in all.
  static ({List<QuranHit> hits, int total}) search(String query, {int limit = 60}) {
    final index = _index;
    if (index == null) return (hits: const [], total: 0);
    final words = skeleton(query)
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    // One-letter pieces (like «ما» → «م») would match almost everything.
    final useful = words.where((w) => w.length >= 2).toList();
    if (useful.isEmpty) return (hits: const [], total: 0);
    final phrase = words.join(); // «يا أيها» is one word in the mushaf

    final exact = <int>[];
    final loose = <int>[];
    for (var i = 0; i < index.length; i++) {
      final v = index[i];
      if (!useful.every(v.contains)) continue;
      (words.length > 1 && v.replaceAll(' ', '').contains(phrase) ? exact : loose)
          .add(i);
    }
    final order = [...exact, ...loose];
    final exactSet = exact.toSet();
    final q = QuranData.instance;
    final hits = <QuranHit>[];
    for (final i in order.take(limit)) {
      final (s, a) = q.verseAt(i);
      hits.add(QuranHit(s, a, q.surah(s).ayat[a - 1], exactSet.contains(i)));
    }
    return (hits: hits, total: order.length);
  }
}
