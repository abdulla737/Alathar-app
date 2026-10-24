import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's own data — favorites and "Act on it today" ticks — saved on
/// the phone. No account needed.
///
/// Uses shared_preferences so it works on Android, iOS, Windows and Chrome
/// alike while you test. When the full content database (SQLite) is added,
/// this can move into a `favorites` table with the same methods.
class UserStore extends ChangeNotifier {
  UserStore._();
  static final UserStore instance = UserStore._();

  SharedPreferences? _prefs;

  /// hadith id -> time saved (milliseconds since epoch)
  final Map<int, int> _favorites = {};

  /// hadith ids the user marked as acted on today
  final Set<int> _actedToday = {};

  /// Every day the user acted on a hadith: "YYYY-MM-DD" -> hadith ids.
  /// Kept on the phone (small), for the streak and the «العمل» record.
  final Map<String, List<int>> _history = {};
  String _today = _dayKey(DateTime.now());

  /// hadith ids the user has opened to read in full (for the daily-hadith
  /// progress on the Today page)
  final Set<int> _read = {};

  /// Books with completion ticks (Kitab at-Tawhid: chapters; the Forty:
  /// hadith): collection id -> completed item ids
  final Map<int, Set<int>> _bookDone = {};

  /// hadith ids read today (daily-goal progress); reset at midnight
  final Set<int> _readToday = {};
  String _readDay = '';

  /// athkar category ids completed today (all athkar counted to the end)
  final Set<int> _athkarDoneToday = {};

  /// athkar category ids the user opened today (stops the Today-card glow)
  final Set<int> _athkarSeenToday = {};

  /// «حان الوقت» occasions marked done ("YYYY-MM-DD key"), the last few days.
  final List<String> _occasionsDone = [];

  /// When a task on the Today page was completed, for its ✓ box:
  /// 'occ:<occasion key>', 'athkar:<category>:<day>', 'hadith:<day>',
  /// 'wird:<day>', 'story:<reading>'. Only the latest 80 are kept.

  /// Athkar opened but not finished: the count of each dhikr, per sitting
  /// ("YYYY-MM-DD morning", "YYYY-MM-DD after_dhuhr" …). Reopening resumes.
  final Map<String, List<int>> _athkarProgress = {};

  static const _kFavorites = 'favorites';
  static const _kRead = 'hadith_read';
  static const _kBookDone = 'book_done_'; // + collection id
  static const _kReadToday = 'hadith_read_today'; // "YYYY-MM-DD:1,2,3"
  static const _kHistory = 'acted_history';
  static const _kActedPrefix = 'acted_';
  static const _kAthkarPrefix = 'athkar_done_';
  static const _kSeenPrefix = 'athkar_seen_';
  static const _kOccasions = 'occasions_done'; // ["2026-10-22 dhuhr", …]
  static const _kDoneAt = 'done_at'; // {"occ:2026-10-22 dhuhr": "2026-10-22T12:31:00", …}
  static const _kAthkarProgress = 'athkar_progress'; // {"2026-10-22 morning": [3,1,0,…]}

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Reads saved data from the phone. Call once at startup.
  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    _read.addAll((p.getStringList(_kRead) ?? const []).map(int.tryParse).whereType<int>());
    for (final key in p.getKeys()) {
      if (!key.startsWith(_kBookDone)) continue;
      final cid = int.tryParse(key.substring(_kBookDone.length));
      if (cid == null) continue;
      _bookDone[cid] = {...(p.getStringList(key) ?? const []).map(int.tryParse).whereType<int>()};
    }
    final rt = p.getString(_kReadToday) ?? '';
    final colon = rt.indexOf(':');
    if (colon > 0) {
      _readDay = rt.substring(0, colon);
      _readToday.addAll(rt.substring(colon + 1).split(',').map(int.tryParse).whereType<int>());
    }

    // Favorites: stored as JSON [{"id":1,"at":1729300000000}, ...]
    final raw = p.getString(_kFavorites);
    if (raw != null) {
      try {
        for (final item in jsonDecode(raw) as List) {
          final m = item as Map<String, dynamic>;
          _favorites[m['id'] as int] = m['at'] as int;
        }
      } catch (_) {
        // Corrupted value: start fresh rather than crash.
        _favorites.clear();
      }
    }

    // "Act on it" ticks for today only; older days are cleaned up.
    _today = _dayKey(DateTime.now());
    for (final key in p.getKeys().where((k) => k.startsWith(_kActedPrefix))) {
      if (key != '$_kActedPrefix$_today') p.remove(key);
    }
    final acted = p.getStringList('$_kActedPrefix$_today') ?? const [];
    _actedToday.addAll(acted.map(int.parse));

    // Acted history (all days).
    final hist = p.getString(_kHistory);
    if (hist != null) {
      try {
        (jsonDecode(hist) as Map<String, dynamic>).forEach((day, ids) {
          _history[day] = [for (final id in ids as List) id as int];
        });
      } catch (_) {
        _history.clear();
      }
    }
    if (_actedToday.isNotEmpty) {
      _history[_today] = {...?_history[_today], ..._actedToday}.toList();
    }

    // Athkar completed today; older days are cleaned up.
    for (final key in p.getKeys().where((k) => k.startsWith(_kAthkarPrefix))) {
      if (key != '$_kAthkarPrefix$_today') p.remove(key);
    }
    final done = p.getStringList('$_kAthkarPrefix$_today') ?? const [];
    _athkarDoneToday.addAll(done.map(int.parse));

    for (final key in p.getKeys().where((k) => k.startsWith(_kSeenPrefix))) {
      if (key != '$_kSeenPrefix$_today') p.remove(key);
    }
    _occasionsDone
      ..clear()
      ..addAll(p.getStringList(_kOccasions) ?? const []);
    _doneAt.clear();
    try {
      final raw = p.getString(_kDoneAt);
      if (raw != null) {
        (jsonDecode(raw) as Map).forEach((k, v) => _doneAt[k as String] = v as String);
      }
    } catch (_) {}
    _athkarProgress.clear();
    try {
      final raw = p.getString(_kAthkarProgress);
      if (raw != null) {
        (jsonDecode(raw) as Map).forEach((k, v) =>
            _athkarProgress[k as String] = [for (final n in v as List) (n as num).toInt()]);
      }
    } catch (_) {}
    final seen = p.getStringList('$_kSeenPrefix$_today') ?? const [];
    _athkarSeenToday.addAll(seen.map(int.parse));
  }

  /// Opened today (tapped the card or the category).
  /// Saved counts of an unfinished sitting (null = not started).
  List<int>? athkarProgress(String key) => _athkarProgress[key];

  void setAthkarProgress(String key, List<int> counts) {
    _athkarProgress.remove(key); // re-insert last (newest)
    _athkarProgress[key] = List.of(counts);
    while (_athkarProgress.length > 30) {
      _athkarProgress.remove(_athkarProgress.keys.first);
    }
    _prefs?.setString(_kAthkarProgress, jsonEncode(_athkarProgress));
    notifyListeners();
  }

  /// Forgets the saved progress of these sittings (their time is over).
  void dropAthkarProgress(Iterable<String> keys) {
    var changed = false;
    for (final k in keys) {
      if (_athkarProgress.remove(k) != null) changed = true;
    }
    if (!changed) return;
    _prefs?.setString(_kAthkarProgress, jsonEncode(_athkarProgress));
    notifyListeners();
  }

  /// "YYYY-MM-DD what" for today (or [day]).
  static String sittingKey(String what, [DateTime? day]) => '${_dayKey(day ?? DateTime.now())} $what';

  /// A «حان الوقت» occasion (e.g. "2026-10-22 after_dhuhr") is done.
  bool occasionDone(String key) => _occasionsDone.contains(key);

  void setOccasionDone(String key) {
    if (_occasionsDone.contains(key)) return;
    _occasionsDone.add(key);
    stampDone('occ:$key', notify: false);
    // Two days of occasions are plenty (it shows only the current one).
    while (_occasionsDone.length > 40) {
      _occasionsDone.removeAt(0);
    }
    _prefs?.setStringList(_kOccasions, _occasionsDone);
    notifyListeners();
  }

  bool athkarSeenToday(int categoryId) {
    _rollDayIfNeeded();
    return _athkarSeenToday.contains(categoryId);
  }

  void setAthkarSeenToday(int categoryId) {
    _rollDayIfNeeded();
    if (!_athkarSeenToday.add(categoryId)) return;
    _prefs?.setStringList(
        '$_kSeenPrefix$_today', [for (final id in _athkarSeenToday) '$id']);
    notifyListeners();
  }

  // ------------------------------------------------------ Hadith reading

  bool hasRead(int hadithId) => _read.contains(hadithId);

  /// How many of [ids] the user has read.
  int readCountAmong(Iterable<int> ids) => ids.where(_read.contains).length;

  /// How many of [ids] the user has read today.
  int readTodayAmong(Iterable<int> ids) {
    _rollReadDay();
    return ids.where(_readToday.contains).length;
  }

  bool readToday(int hadithId) {
    _rollReadDay();
    return _readToday.contains(hadithId);
  }

  void _rollReadDay() {
    final today = _dayKey(DateTime.now());
    if (_readDay == today) return;
    _readDay = today;
    _readToday.clear();
  }

  // ------------------------------------------------- Book completion ticks

  bool isBookItemDone(int collectionId, int itemId) =>
      _bookDone[collectionId]?.contains(itemId) ?? false;

  int bookDoneCount(int collectionId, Iterable<int> itemIds) =>
      itemIds.where((id) => isBookItemDone(collectionId, id)).length;

  void setBookItemDone(int collectionId, int itemId, bool done) {
    final set = _bookDone.putIfAbsent(collectionId, () => {});
    final changed = done ? set.add(itemId) : set.remove(itemId);
    if (!changed) return;
    _prefs?.setStringList('$_kBookDone$collectionId', [for (final id in set) '$id']);
    notifyListeners();
  }

  /// Clears every tick in one book.
  void resetBook(int collectionId) {
    _bookDone.remove(collectionId);
    _prefs?.remove('$_kBookDone$collectionId');
    notifyListeners();
  }

  /// Undo "read and applied today" for a hadith.
  void unmarkReadToday(int hadithId) {
    _rollReadDay();
    if (!_readToday.remove(hadithId)) return;
    if (_readToday.isEmpty) clearDone('hadith:${_dayKey(DateTime.now())}', notify: false);
    _prefs?.setString(_kReadToday, '$_readDay:${_readToday.join(',')}');
    notifyListeners();
  }

  /// Called when the user confirms reading a hadith (slide bar).
  void markRead(int hadithId) {
    _rollReadDay();
    final newEver = _read.add(hadithId);
    final newToday = _readToday.add(hadithId);
    if (!newEver && !newToday) return;
    if (newToday) stampDone('hadith:${_dayKey(DateTime.now())}', notify: false);
    _prefs?.setStringList(_kRead, [for (final id in _read) '$id']);
    _prefs?.setString(_kReadToday, '$_readDay:${_readToday.join(',')}');
    notifyListeners();
  }

  // ------------------------------------------------------ Athkar progress

  bool athkarDoneToday(int categoryId) {
    _rollDayIfNeeded();
    return _athkarDoneToday.contains(categoryId);
  }

  // ------------------------------------------------------ Completion times
  final Map<String, String> _doneAt = {};

  DateTime? doneAt(String key) {
    final v = _doneAt[key];
    return v == null ? null : DateTime.tryParse(v);
  }

  /// Remembers now as the time [key] was completed (keeps an earlier time).
  void stampDone(String key, {bool notify = true}) {
    if (_doneAt.containsKey(key)) return;
    _doneAt[key] = DateTime.now().toIso8601String();
    while (_doneAt.length > 80) {
      _doneAt.remove(_doneAt.keys.first);
    }
    _prefs?.setString(_kDoneAt, jsonEncode(_doneAt));
    if (notify) notifyListeners();
  }

  void clearDone(String key, {bool notify = true}) {
    if (_doneAt.remove(key) == null) return;
    _prefs?.setString(_kDoneAt, jsonEncode(_doneAt));
    if (notify) notifyListeners();
  }

  void setAthkarDoneToday(int categoryId) {
    _rollDayIfNeeded();
    if (!_athkarDoneToday.add(categoryId)) return;
    stampDone('athkar:$categoryId:${_dayKey(DateTime.now())}', notify: false);
    _prefs?.setStringList(
        '$_kAthkarPrefix$_today', [for (final id in _athkarDoneToday) '$id']);
    notifyListeners();
  }

  // ------------------------------------------------------------ Favorites

  bool isFavorite(int hadithId) => _favorites.containsKey(hadithId);

  int get favoriteCount => _favorites.length;

  /// Newest first.
  List<int> get favoriteIds {
    final entries = _favorites.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries) e.key];
  }

  void toggleFavorite(int hadithId) {
    if (_favorites.containsKey(hadithId)) {
      _favorites.remove(hadithId);
    } else {
      _favorites[hadithId] = DateTime.now().millisecondsSinceEpoch;
    }
    _saveFavorites();
    notifyListeners();
  }

  void removeFavorite(int hadithId) {
    if (_favorites.remove(hadithId) != null) {
      _saveFavorites();
      notifyListeners();
    }
  }

  void _saveFavorites() {
    final list = [
      for (final e in _favorites.entries) {'id': e.key, 'at': e.value}
    ];
    _prefs?.setString(_kFavorites, jsonEncode(list));
  }

  // ------------------------------------------------------- Act on it today

  bool actedToday(int hadithId) {
    _rollDayIfNeeded();
    return _actedToday.contains(hadithId);
  }

  void setActedToday(int hadithId, bool value) {
    _rollDayIfNeeded();
    value ? _actedToday.add(hadithId) : _actedToday.remove(hadithId);
    _prefs?.setStringList(
        '$_kActedPrefix$_today', [for (final id in _actedToday) '$id']);
    if (_actedToday.isEmpty) {
      _history.remove(_today);
    } else {
      _history[_today] = _actedToday.toList();
    }
    _prefs?.setString(_kHistory, jsonEncode(_history));
    notifyListeners();
  }

  // ------------------------------------------------------ «العمل» record

  static String dayKey(DateTime d) => _dayKey(d);

  /// Hadith ids acted on, on one day.
  List<int> actedOn(DateTime day) {
    _rollDayIfNeeded();
    return _history[_dayKey(day)] ?? const [];
  }

  /// Days in a row with at least one hadith acted on. Today counts if done;
  /// if today isn't done yet, the streak up to yesterday still shows.
  int get streak {
    _rollDayIfNeeded();
    var day = DateTime.now();
    if ((_history[_dayKey(day)] ?? const []).isEmpty) {
      day = day.subtract(const Duration(days: 1));
    }
    var n = 0;
    while ((_history[_dayKey(day)] ?? const []).isNotEmpty) {
      n++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return n;
  }

  /// Number of days with at least one hadith acted on.
  int get actedDays => _history.values.where((v) => v.isNotEmpty).length;

  /// Number of different hadith acted on.
  int get actedHadithCount => {for (final v in _history.values) ...v}.length;

  /// Record, newest day first: (day, hadith ids).
  List<MapEntry<String, List<int>>> get history {
    final list = _history.entries.where((e) => e.value.isNotEmpty).toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return list;
  }

  /// If the app stayed open past midnight, start a fresh day.
  void _rollDayIfNeeded() {
    final now = _dayKey(DateTime.now());
    if (now != _today) {
      _prefs?.remove('$_kActedPrefix$_today');
      _prefs?.remove('$_kAthkarPrefix$_today');
      _prefs?.remove('$_kSeenPrefix$_today');
      _today = now;
      _actedToday.clear();
      _athkarDoneToday.clear();
      _athkarSeenToday.clear();
    }
  }
}
