import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// One surah of the Qur'an.
class Surah {
  final int number; // 1..114
  final String name; // Arabic, e.g. «الكهف»
  final String translit; // e.g. "Al-Kahf"
  final String english; // e.g. "The Cave"
  final bool medinan;
  final List<String> ayat; // verse texts, verse 1 first
  final int firstIndex; // index of verse 1 among all 6,236 verses (0-based)

  const Surah(this.number, this.name, this.translit, this.english, this.medinan, this.ayat,
      this.firstIndex);

  int get count => ayat.length;

  /// Every surah starts with the Basmala except at-Tawbah (9). In al-Fatiha
  /// (1) it is verse 1 itself, so it is not shown separately there.
  bool get showsBasmala => number != 1 && number != 9;
}

/// The whole Qur'an text, read from the app (no internet needed).
///
/// Text: Tanzil Uthmani (Hafs ʿan ʿAsim, tanzil.net), unchanged.
/// Tajweed: quran-tajweed by cpfair (CC BY 4.0), aligned to this text.
/// Font: Amiri Quran (OFL).
class QuranData {
  QuranData._();
  static final QuranData instance = QuranData._();

  static const totalAyat = 6236;

  List<Surah> surahs = const [];
  List<int> _pages = const []; // Madinah mushaf page of every verse
  List<(int, int)> juzStarts = const []; // (surah, verse) where each juz begins
  Set<int> _sajda = const {};
  Future<void>? _loading;

  bool get isLoaded => surahs.isNotEmpty;

  /// Loads the text once (about 1.4 MB, parsed off the main thread).
  Future<void> ensureLoaded() => _loading ??= _load().catchError((Object e) {
        _loading = null; // try again next time
        throw e;
      });

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/quran/quran.json');
    final data = await compute(_decode, raw);
    final list = <Surah>[];
    var index = 0;
    final s = data['s'] as List;
    for (var i = 0; i < s.length; i++) {
      final e = s[i] as List;
      final ayat = (e[4] as List).cast<String>();
      list.add(Surah(i + 1, e[0] as String, e[1] as String, e[2] as String, e[3] == 1, ayat,
          index));
      index += ayat.length;
    }
    _pages = (data['p'] as List).cast<int>();
    juzStarts = [
      for (final j in (data['j'] as List)) ((j as List)[0] as int, j[1] as int),
    ];
    surahs = list;
    _pageFirst = [
      for (var i = 0; i < _pages.length; i++)
        if (i == 0 || _pages[i] != _pages[i - 1]) i,
    ];
    _sajda = {for (final j in (data['sj'] as List)) indexOf((j as List)[0] as int, j[1] as int)};
  }

  static Map<String, dynamic> _decode(String raw) => jsonDecode(raw) as Map<String, dynamic>;

  Surah surah(int number) => surahs[number - 1];

  /// The Basmala, exactly as written in al-Fatiha verse 1.
  String get basmala => surahs.first.ayat.first;

  /// Position of a verse among all 6,236 (0-based).
  int indexOf(int surah, int ayah) => surahs[surah - 1].firstIndex + ayah - 1;

  int pageOf(int surah, int ayah) => _pages[indexOf(surah, ayah)];

  // ---------------------------------------------------------------- Pages
  List<int> _pageFirst = const []; // first verse (overall index) of each page

  /// Pages of the Madinah mushaf (604).
  int get pageCount => _pageFirst.length;

  /// (surah, ayah) of a verse by its overall index (0-based).
  (int, int) verseAt(int index) {
    var lo = 0, hi = surahs.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (surahs[mid].firstIndex <= index) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return (lo + 1, index - surahs[lo].firstIndex + 1);
  }

  /// The verses on a page (1-based), in order.
  List<(int, int)> ayatOnPage(int page) {
    final start = _pageFirst[page - 1];
    final end = page < pageCount ? _pageFirst[page] : totalAyat;
    return [for (var i = start; i < end; i++) verseAt(i)];
  }

  int juzOf(int surah, int ayah) {
    final i = indexOf(surah, ayah);
    var juz = 1;
    for (var j = 0; j < juzStarts.length; j++) {
      final (s, a) = juzStarts[j];
      if (indexOf(s, a) <= i) juz = j + 1;
    }
    return juz;
  }

  bool isSajda(int surah, int ayah) => _sajda.contains(indexOf(surah, ayah));

  // ------------------------------------------------------------- Tajweed
  List<String> _rules = const [];
  List<List<int>> _tajweed = const [];
  Future<void>? _tajweedLoading;

  bool get hasTajweed => _tajweed.isNotEmpty;

  /// Loads the tajweed rules (about 0.5 MB) the first time they are shown.
  Future<void> ensureTajweed() =>
      _tajweedLoading ??= _loadTajweed().catchError((Object e) {
        _tajweedLoading = null;
        throw e;
      });

  Future<void> _loadTajweed() async {
    final raw = await rootBundle.loadString('assets/quran/tajweed.json');
    final data = await compute(_decode, raw);
    _rules = (data['rules'] as List).cast<String>();
    _tajweed = [for (final a in (data['a'] as List)) (a as List).cast<int>()];
  }

  /// Tajweed rules in one verse: (rule, start, end) character ranges.
  List<(String, int, int)> tajweedOf(int surah, int ayah) {
    if (!hasTajweed) return const [];
    final row = _tajweed[indexOf(surah, ayah)];
    return [
      for (var i = 0; i + 2 < row.length; i += 3) (_rules[row[i]], row[i + 1], row[i + 2]),
    ];
  }
}

/// Where the reader stopped, bookmarks and reading size. Saved on the phone.
class QuranStore extends ChangeNotifier {
  QuranStore._();
  static final QuranStore instance = QuranStore._();

  SharedPreferences? _prefs;

  int? lastSurah; // null = never opened
  int lastAyah = 1;
  final Set<String> bookmarks = {}; // "surah:ayah"

  /// Colour the text by tajweed rules (switch on the reading page).
  bool tajweed = true;

  /// Colour of the surah banners and verse medallions (0 = green).
  int ornament = 0;

  /// Mushaf pages read today (daily-goal progress); reset at midnight.
  final Set<int> _pagesToday = {};
  String _pagesDay = '';

  /// Qur'an text size on the reading page (its own A− / A+).
  double size = 24;
  static const minSize = 20.0;
  static const maxSize = 48.0;

  static const _kSurah = 'quran_last_surah';
  static const _kAyah = 'quran_last_ayah';
  static const _kBookmarks = 'quran_bookmarks';
  static const _kSize = 'quran_size';
  static const _kTajweed = 'quran_tajweed';
  static const _kOrnament = 'quran_ornament';
  static const _kPagesToday = 'quran_pages_today'; // "YYYY-MM-DD:1,2"

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    lastSurah = p.getInt(_kSurah);
    lastAyah = p.getInt(_kAyah) ?? 1;
    bookmarks
      ..clear()
      ..addAll(p.getStringList(_kBookmarks) ?? const []);
    size = (p.getDouble(_kSize) ?? 24).clamp(minSize, maxSize);
    tajweed = p.getBool(_kTajweed) ?? true;
    ornament = p.getInt(_kOrnament) ?? 0;
    final pt = p.getString(_kPagesToday) ?? '';
    final colon = pt.indexOf(':');
    if (colon > 0) {
      _pagesDay = pt.substring(0, colon);
      _pagesToday.addAll(pt.substring(colon + 1).split(',').map(int.tryParse).whereType<int>());
    }
  }

  void setPosition(int surah, int ayah) {
    if (lastSurah == surah && lastAyah == ayah) return;
    lastSurah = surah;
    lastAyah = ayah;
    _prefs?.setInt(_kSurah, surah);
    _prefs?.setInt(_kAyah, ayah);
    notifyListeners();
  }

  bool isBookmarked(int surah, int ayah) => bookmarks.contains('$surah:$ayah');

  void toggleBookmark(int surah, int ayah) {
    final key = '$surah:$ayah';
    if (!bookmarks.remove(key)) bookmarks.add(key);
    _prefs?.setStringList(_kBookmarks, bookmarks.toList());
    notifyListeners();
  }

  /// Bookmarks as (surah, ayah), in Qur'an order.
  List<(int, int)> get bookmarkList {
    final list = [
      for (final b in bookmarks)
        (int.parse(b.split(':')[0]), int.parse(b.split(':')[1])),
    ]..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    return list;
  }

  void setTajweed(bool value) {
    tajweed = value;
    _prefs?.setBool(_kTajweed, value);
    notifyListeners();
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _rollPagesDay() {
    final today = _day(DateTime.now());
    if (_pagesDay == today) return;
    _pagesDay = today;
    _pagesToday.clear();
  }

  /// Pages read today.
  int get pagesReadToday {
    _rollPagesDay();
    return _pagesToday.length;
  }

  /// Called when a page is shown in the reader.
  void markPageRead(int page) {
    _rollPagesDay();
    if (!_pagesToday.add(page)) return;
    _prefs?.setString(_kPagesToday, '$_pagesDay:${_pagesToday.join(',')}');
    notifyListeners();
  }

  void setOrnament(int value) {
    ornament = value;
    _prefs?.setInt(_kOrnament, value);
    notifyListeners();
  }

  void setSize(double value) {
    size = value.clamp(minSize, maxSize);
    _prefs?.setDouble(_kSize, size);
    notifyListeners();
  }
}

/// 12 → «١٢» (Arabic-Indic digits), for verse numbers in the Qur'an text.
String arabicDigits(int n) {
  const d = '٠١٢٣٤٥٦٧٨٩';
  return n.toString().split('').map((c) => d[int.parse(c)]).join();
}
