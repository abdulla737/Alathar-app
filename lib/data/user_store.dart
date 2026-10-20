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

  /// athkar category ids completed today (all athkar counted to the end)
  final Set<int> _athkarDoneToday = {};

  /// athkar category ids the user opened today (stops the Today-card glow)
  final Set<int> _athkarSeenToday = {};

  static const _kFavorites = 'favorites';
  static const _kHistory = 'acted_history';
  static const _kActedPrefix = 'acted_';
  static const _kAthkarPrefix = 'athkar_done_';
  static const _kSeenPrefix = 'athkar_seen_';

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Reads saved data from the phone. Call once at startup.
  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();

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
    final seen = p.getStringList('$_kSeenPrefix$_today') ?? const [];
    _athkarSeenToday.addAll(seen.map(int.parse));
  }

  /// Opened today (tapped the card or the category).
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

  // ------------------------------------------------------ Athkar progress

  bool athkarDoneToday(int categoryId) {
    _rollDayIfNeeded();
    return _athkarDoneToday.contains(categoryId);
  }

  void setAthkarDoneToday(int categoryId) {
    _rollDayIfNeeded();
    if (!_athkarDoneToday.add(categoryId)) return;
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
