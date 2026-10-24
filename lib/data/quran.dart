import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';
import 'user_store.dart';

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

  /// First and last mushaf page of a surah.
  (int, int) surahPages(int surah) {
    final s = surahs[surah - 1];
    return (pageOf(surah, 1), pageOf(surah, s.count));
  }

  /// The first verse of [surah] on [page] (1 when the surah isn't on it).
  int firstAyahOnPage(int surah, int page) {
    for (final v in ayatOnPage(page)) {
      if (v.$1 == surah) return v.$2;
    }
    return 1;
  }

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

  /// Free reading: the page saved per surah («هل تود متابعة القراءة؟» → نعم).
  /// Shown as a bar on the surah's row; opening the surah resumes there.
  final Map<int, int> _surahMarks = {};

  /// Every mushaf page ever shown in the reader; a surah is complete («✓»)
  /// once all of its pages are in here.
  final Set<int> _pagesSeen = {};

  /// Colour the text by tajweed rules (switch on the reading page).
  bool tajweed = true;

  /// Colour of the surah banners and verse medallions (0 = green).
  int ornament = 0;

  /// Daily reading window: today's first page, and where tomorrow starts
  /// once today's pages are finished.
  String _wirdDay = '';
  int? _wirdStart;
  int? _wirdNext;

  /// Furthest page reached in the daily reading of the current khatma /
  /// range ("from-to" of pages), and how many times it was completed.
  String _cycleKey = '';
  int _furthest = 0;
  int khatmasDone = 0;
  String _completedDay = ''; // a khatma is counted once, even if re-read

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
  static const _kWird = 'quran_wird'; // "YYYY-MM-DD|start|next"
  static const _kCycle = 'quran_cycle'; // "from-to|furthest|done|day"
  static const _kSurahMarks = 'quran_surah_marks'; // "surah:page,…"
  static const _kPagesSeen = 'quran_pages_seen'; // "1,2,3,…"

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
    final w = (p.getString(_kWird) ?? '').split('|');
    if (w.length == 3) {
      _wirdDay = w[0];
      _wirdStart = int.tryParse(w[1]);
      _wirdNext = int.tryParse(w[2]);
    }
    final c = (p.getString(_kCycle) ?? '').split('|');
    if (c.length >= 3) {
      _cycleKey = c[0];
      _furthest = int.tryParse(c[1]) ?? 0;
      khatmasDone = int.tryParse(c[2]) ?? 0;
      if (c.length >= 4) _completedDay = c[3];
    }
    _pagesSeen
      ..clear()
      ..addAll((p.getString(_kPagesSeen) ?? '').split(',').map(int.tryParse).whereType<int>());
    _surahMarks.clear();
    for (final e in (p.getString(_kSurahMarks) ?? '').split(',')) {
      final kv = e.split(':');
      if (kv.length != 2) continue;
      final s = int.tryParse(kv[0]), pg = int.tryParse(kv[1]);
      if (s != null && pg != null) _surahMarks[s] = pg;
    }
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

  /// A page was shown in the reader.
  void markPageSeen(int page) {
    if (!_pagesSeen.add(page)) return;
    _prefs?.setString(_kPagesSeen, _pagesSeen.join(','));
    notifyListeners();
  }

  /// Pages of [first]..[last] that have been read.
  int pagesSeenIn(int first, int last) {
    var n = 0;
    for (var p = first; p <= last; p++) {
      if (_pagesSeen.contains(p)) n++;
    }
    return n;
  }

  /// Saved page in [surah] from free reading (null = none).
  int? surahMark(int surah) => _surahMarks[surah];

  void setSurahMark(int surah, int page) {
    if (_surahMarks[surah] == page) return;
    _surahMarks[surah] = page;
    _saveSurahMarks();
  }

  /// Clears a surah's reading: its saved page and the pages read in it (so
  /// its bar and ✓ go). Pages it shares with a neighbouring surah count
  /// for that one too.
  void resetSurah(int surah, int firstPage, int lastPage) {
    _surahMarks.remove(surah);
    for (var p = firstPage; p <= lastPage; p++) {
      _pagesSeen.remove(p);
    }
    _prefs?.setString(_kPagesSeen, _pagesSeen.join(','));
    _saveSurahMarks();
  }

  void clearSurahMark(int surah) {
    if (_surahMarks.remove(surah) != null) _saveSurahMarks();
  }

  void _saveSurahMarks() {
    _prefs?.setString(_kSurahMarks,
        _surahMarks.entries.map((e) => '${e.key}:${e.value}').join(','));
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

  /// The pages read today, in order.
  List<int> get pagesToday {
    _rollPagesDay();
    return _pagesToday.toList()..sort();
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
    // Today's goal reached: remember when (the ✓ box on the Today card).
    if (_pagesToday.length >= AppSettings.instance.quranSidesPerDay) {
      UserStore.instance.stampDone('wird:$_pagesDay');
    }
    notifyListeners();
  }

  void _saveWird() =>
      _prefs?.setString(_kWird, '$_wirdDay|${_wirdStart ?? ''}|${_wirdNext ?? ''}');

  /// Today's first page of the daily reading (without changing anything):
  /// today's start if already begun, else where yesterday's reading ended,
  /// else [fallback]. Must lie in [from]..[to] (the chosen surahs).
  int wirdStartPage(int fallback, int from, int to) {
    int? inRange(int? p) => p != null && p >= from && p <= to ? p : null;
    if (_wirdDay == _day(DateTime.now())) {
      final start = inRange(_wirdStart);
      if (start != null) return start;
    }
    return inRange(_wirdNext) ?? fallback.clamp(from, to);
  }

  /// The old built-in daily reading was used (moved once into a plan).
  bool get wirdUsed =>
      _wirdDay.isNotEmpty || _wirdNext != null || _furthest > 0 || khatmasDone > 0;

  /// Where the old built-in daily reading continues.
  int? get wirdNextPage => _wirdNext;

  /// Today's reading has been opened (since the last plan change).
  bool get wirdBegunToday => _wirdDay == _day(DateTime.now());

  /// Fixes today's first page when today's reading is opened.
  void beginWird(int page) {
    final today = _day(DateTime.now());
    if (_wirdDay == today && _wirdStart == page) return;
    _wirdDay = today;
    _wirdStart = page;
    _saveWird();
  }

  /// Today's last page was reached: tomorrow continues from [nextPage].
  void finishWird(int nextPage) {
    if (_wirdNext == nextPage) return;
    _wirdNext = nextPage;
    _saveWird();
    notifyListeners();
  }

  void _saveCycle() =>
      _prefs?.setString(_kCycle, '$_cycleKey|$_furthest|$khatmasDone|$_completedDay');

  /// Pages of [from]..[to] completed in the current khatma / range (0 when
  /// the range changed).
  int pagesDone(int from, int to) {
    if (_cycleKey != '$from-$to') return 0;
    return (_furthest - from + 1).clamp(0, to - from + 1);
  }

  /// A page of [from]..[to] was read in the daily reading.
  void recordProgress(int page, int from, int to) {
    final key = '$from-$to';
    if (_cycleKey != key) {
      _cycleKey = key;
      _furthest = 0;
    }
    if (page <= _furthest || page < from || page > to) return;
    // Re-reading on the day the khatma was finished: the next one starts
    // tomorrow.
    if (_completedDay == _day(DateTime.now())) return;
    _furthest = page;
    _saveCycle();
    notifyListeners();
  }

  /// The last page of the range was read: one more khatma, start again.
  void completeCycle(int from, int to) {
    final today = _day(DateTime.now());
    if (_completedDay == today) return;
    _completedDay = today;
    _cycleKey = '$from-$to';
    _furthest = 0;
    khatmasDone++;
    _saveCycle();
    notifyListeners();
  }

  /// A new daily-reading plan (Settings → «الورد اليومي»): today's pages,
  /// where tomorrow starts and the khatma / range progress start from zero.
  /// Completed khatmas are kept.
  /// [startPage]: the plan's first page — today's reading starts there
  /// (not at the last place read in the mushaf).
  void resetWird(int startPage) {
    _wirdDay = '';
    _wirdStart = null;
    _wirdNext = startPage;
    _cycleKey = '';
    _furthest = 0;
    _completedDay = '';
    _pagesToday.clear();
    _pagesDay = '';
    _saveWird();
    _prefs?.remove(_kPagesToday);
    _saveCycle();
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
