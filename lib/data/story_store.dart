import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'stories.dart';
import 'user_store.dart';

/// «قصص قرآنية» progress on this phone: which readings are done, how far
/// each unfinished one was scrolled, and today's reading for the Today card.
class StoryStore extends ChangeNotifier {
  StoryStore._();
  static final StoryStore instance = StoryStore._();

  SharedPreferences? _prefs;
  final Set<String> _done = {};
  final Map<String, double> _progress = {};
  String _todayDate = '';
  String _todayKey = '';

  static const _kDone = 'story_done';
  static const _kProgress = 'story_progress';
  static const _kToday = 'story_today';

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    _done
      ..clear()
      ..addAll(p.getStringList(_kDone) ?? const []);
    _progress.clear();
    try {
      final raw = p.getString(_kProgress);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>)
            .forEach((k, v) => _progress[k] = (v as num).toDouble());
      }
    } catch (_) {}
    final today = (p.getString(_kToday) ?? '').split('|');
    if (today.length == 2) {
      _todayDate = today[0];
      _todayKey = today[1];
    }
  }

  bool isDone(StoryUnit u) => _done.contains(u.key);

  /// 0..1: how far the reading was scrolled (1 when done).
  double progressOf(StoryUnit u) => isDone(u) ? 1 : (_progress[u.key] ?? 0);

  bool isStarted(StoryUnit u) => !isDone(u) && (_progress[u.key] ?? 0) > 0.02;

  void setProgress(StoryUnit u, double value) {
    if (isDone(u)) return;
    final v = value.clamp(0.0, 1.0);
    if (((_progress[u.key] ?? 0) - v).abs() < 0.01) return;
    _progress[u.key] = v;
    _prefs?.setString(_kProgress, jsonEncode(_progress));
    notifyListeners();
  }

  void setDone(StoryUnit u, bool done) {
    if (done) {
      _done.add(u.key);
      _progress.remove(u.key);
    } else {
      _done.remove(u.key);
    }
    _prefs?.setStringList(_kDone, _done.toList());
    _prefs?.setString(_kProgress, jsonEncode(_progress));
    notifyListeners();
  }

  /// Clears the reading of [units]: ✓ and progress.
  void reset(Iterable<StoryUnit> units) {
    for (final u in units) {
      _done.remove(u.key);
      _progress.remove(u.key);
    }
    _prefs?.setStringList(_kDone, _done.toList());
    _prefs?.setString(_kProgress, jsonEncode(_progress));
    notifyListeners();
  }

  bool hasReading(Iterable<StoryUnit> units) =>
      units.any((u) => isDone(u) || (_progress[u.key] ?? 0) > 0.02);

  // ---------------------------------------------------------------- Stories
  List<StoryUnit> unitsOf(QuranStory s) =>
      [for (var i = 0; i < s.parts.length; i++) StoryUnit(s, i)];

  bool storyDone(QuranStory s) => unitsOf(s).every(isDone);

  int partsDone(QuranStory s) => unitsOf(s).where(isDone).length;

  /// 0..1 across all parts of the story.
  double storyProgress(QuranStory s) {
    final units = unitsOf(s);
    return units.fold(0.0, (n, u) => n + progressOf(u)) / units.length;
  }

  int get storiesDone => quranStories.where(storyDone).length;

  /// The part to open for a story: the first unfinished one.
  StoryUnit nextUnitOf(QuranStory s) =>
      unitsOf(s).firstWhere((u) => !isDone(u), orElse: () => StoryUnit(s, 0));

  // ---------------------------------------------------------------- Today
  /// Today's reading («سيرة النبي ﷺ» stories only): fixed for the day; a new
  /// day moves on to the next unread reading, after the previous one.
  StoryUnit get today {
    final date = UserStore.dayKey(DateTime.now());
    var saved = storyUnitByKey(_todayKey);
    if (saved != null && saved.story.group != StoryGroup.seerah) saved = null;
    if (date == _todayDate && saved != null) return saved;
    final unit = _nextUnread(after: saved);
    _todayDate = date;
    _todayKey = unit.key;
    _prefs?.setString(_kToday, '$date|${unit.key}');
    return unit;
  }

  /// The reading after today's (shown once today's is done).
  StoryUnit get tomorrow => _nextUnread(after: today, skip: today);

  StoryUnit _nextUnread({StoryUnit? after, StoryUnit? skip}) {
    final units = dailyStoryUnits;
    final start = after == null ? 0 : units.indexWhere((u) => u.key == after.key) + 1;
    for (var i = 0; i < units.length; i++) {
      final u = units[(start + i) % units.length];
      if (!isDone(u) && u.key != skip?.key) return u;
    }
    // Everything read: start the round again.
    return units[start % units.length];
  }
}
