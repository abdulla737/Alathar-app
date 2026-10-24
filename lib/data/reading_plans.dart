import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'quran.dart';
import 'user_store.dart';

/// What an extra reading plan covers.
enum PlanKind { khatma, surah, range }

/// An extra daily-reading plan (Settings → «الورد اليومي» → +): another
/// khatma, one surah, or from one surah to another. Each has its own pages
/// per day and its own progress; once «تفعيل» it shows as a Today card.
class ReadingPlan {
  ReadingPlan({
    required this.id,
    required this.kind,
    required this.fromSurah,
    required this.toSurah,
    this.pagesPerDay = 1,
    this.active = false,
  });

  final String id;
  PlanKind kind;
  int fromSurah;
  int toSurah;

  /// «صفحة» = one leaf = two mushaf sides, as in the main daily reading.
  int pagesPerDay;
  int get sidesPerDay => pagesPerDay * 2;
  bool active;

  // Progress -------------------------------------------------------------
  String day = ''; // the day [start] belongs to
  int? start; // today's first page
  int? next; // where the next day starts
  String todayDay = '';
  final Set<int> today = {}; // pages read today
  int furthest = 0; // furthest page reached in this round
  int rounds = 0; // times the whole plan was finished
  String completedDay = '';

  /// First and last mushaf page of the plan (the Qur'an must be loaded).
  (int, int) pages(QuranData q) {
    final first = q.pageOf(fromSurah, 1);
    final last = q.surah(toSurah);
    return (first, q.pageOf(last.number, last.count));
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'k': kind.index,
        'f': fromSurah,
        't': toSurah,
        'n': pagesPerDay,
        'a': active,
        'd': day,
        's': start,
        'x': next,
        'td': todayDay,
        'tp': today.toList(),
        'fu': furthest,
        'r': rounds,
        'cd': completedDay,
      };

  static ReadingPlan fromJson(Map<String, dynamic> j) {
    final p = ReadingPlan(
      id: j['id'] as String,
      kind: PlanKind.values[((j['k'] as num?)?.toInt() ?? 0).clamp(0, PlanKind.values.length - 1)],
      fromSurah: ((j['f'] as num?)?.toInt() ?? 1).clamp(1, 114),
      toSurah: ((j['t'] as num?)?.toInt() ?? 114).clamp(1, 114),
      pagesPerDay: ((j['n'] as num?)?.toInt() ?? 1).clamp(1, PlanStore.maxPagesPerDay),
      active: j['a'] as bool? ?? false,
    );
    if (p.toSurah < p.fromSurah) p.toSurah = p.fromSurah;
    p.day = j['d'] as String? ?? '';
    p.start = (j['s'] as num?)?.toInt();
    p.next = (j['x'] as num?)?.toInt();
    p.todayDay = j['td'] as String? ?? '';
    p.today.addAll([for (final v in (j['tp'] as List? ?? const [])) (v as num).toInt()]);
    p.furthest = (j['fu'] as num?)?.toInt() ?? 0;
    p.rounds = (j['r'] as num?)?.toInt() ?? 0;
    p.completedDay = j['cd'] as String? ?? '';
    return p;
  }
}

/// The extra reading plans, and Friday's «سورة الكهف». Saved on the phone.
class PlanStore extends ChangeNotifier {
  PlanStore._();
  static final PlanStore instance = PlanStore._();

  static const maxPagesPerDay = 40;
  static const kahfSurah = 18;

  static const _kPlans = 'reading_plans';
  static const _kKahf = 'kahf_pages'; // "YYYY-MM-DD:293,294"

  SharedPreferences? _prefs;
  final List<ReadingPlan> plans = [];

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    plans.clear();
    try {
      final raw = p.getString(_kPlans);
      if (raw != null) {
        for (final j in jsonDecode(raw) as List) {
          plans.add(ReadingPlan.fromJson((j as Map).cast<String, dynamic>()));
        }
      }
    } catch (_) {}
    final k = p.getString(_kKahf) ?? '';
    final colon = k.indexOf(':');
    if (colon > 0) {
      _kahfDay = k.substring(0, colon);
      _kahfPages.addAll(k.substring(colon + 1).split(',').map(int.tryParse).whereType<int>());
    }
  }

  static String _today() => UserStore.dayKey(DateTime.now());

  void _save() {
    _prefs?.setString(_kPlans, jsonEncode([for (final p in plans) p.toJson()]));
    notifyListeners();
  }

  // Plans ----------------------------------------------------------------
  List<ReadingPlan> get activePlans => [for (final p in plans) if (p.active) p];

  ReadingPlan? plan(String id) {
    for (final p in plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// A new plan (not active until «تفعيل»).
  ReadingPlan add(PlanKind kind, int from, int to, int pagesPerDay) {
    if (kind == PlanKind.khatma) {
      from = 1;
      to = 114;
    } else if (kind == PlanKind.surah) {
      to = from;
    }
    final p = ReadingPlan(
      id: 'p${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      fromSurah: from.clamp(1, 114),
      toSurah: to.clamp(from.clamp(1, 114), 114),
      pagesPerDay: pagesPerDay.clamp(1, maxPagesPerDay),
    );
    plans.add(p);
    _save();
    return p;
  }

  void remove(String id) {
    plans.removeWhere((p) => p.id == id);
    _save();
  }

  void setActive(String id, bool active) {
    final p = plan(id);
    if (p == null || p.active == active) return;
    p.active = active;
    _save();
  }

  void setPagesPerDay(String id, int value) {
    final p = plan(id);
    if (p == null) return;
    p.pagesPerDay = value.clamp(1, maxPagesPerDay);
    _save();
  }

  /// Starts the plan again from its first page (rounds are kept).
  void restart(String id) {
    final p = plan(id);
    if (p == null) return;
    p
      ..day = ''
      ..start = null
      ..next = null
      ..todayDay = ''
      ..furthest = 0
      ..completedDay = '';
    p.today.clear();
    _save();
  }

  // Daily reading of a plan ----------------------------------------------
  /// Pages of the plan read today.
  int readToday(ReadingPlan p) => p.todayDay == _today() ? p.today.length : 0;

  List<int> pagesToday(ReadingPlan p) =>
      p.todayDay == _today() ? (p.today.toList()..sort()) : const <int>[];

  bool doneToday(ReadingPlan p) => readToday(p) >= p.sidesPerDay;

  /// Today's first page (without changing anything).
  int startPage(ReadingPlan p, int first, int last) {
    int? inRange(int? v) => v != null && v >= first && v <= last ? v : null;
    if (p.day == _today()) {
      final s = inRange(p.start);
      if (s != null) return s;
    }
    return inRange(p.next) ?? first;
  }

  bool begunToday(ReadingPlan p) => p.day == _today();

  void begin(ReadingPlan p, int page) {
    final today = _today();
    if (p.day == today && p.start == page) return;
    p.day = today;
    p.start = page;
    _save();
  }

  /// A page of the plan was shown in its reader.
  void markPage(ReadingPlan p, int page) {
    final today = _today();
    if (p.todayDay != today) {
      p.todayDay = today;
      p.today.clear();
    }
    if (!p.today.add(page)) return;
    if (p.today.length >= p.sidesPerDay) {
      UserStore.instance.stampDone('plan:${p.id}:$today');
    }
    _save();
  }

  /// Pages of this round finished.
  int pagesDone(ReadingPlan p, int first, int last) =>
      (p.furthest - first + 1).clamp(0, last - first + 1);

  void recordProgress(ReadingPlan p, int page, int first, int last) {
    if (page <= p.furthest || page < first || page > last) return;
    if (p.completedDay == _today()) return;
    p.furthest = page;
    _save();
  }

  void finishDay(ReadingPlan p, int nextPage) {
    if (p.next == nextPage) return;
    p.next = nextPage;
    _save();
  }

  /// The plan's last page was read: one more round, start again.
  void completeRound(ReadingPlan p, int first) {
    final today = _today();
    if (p.completedDay == today) return;
    p
      ..completedDay = today
      ..furthest = 0
      ..next = first
      ..rounds = p.rounds + 1;
    _save();
  }

  // Friday: «سورة الكهف» -------------------------------------------------
  String _kahfDay = '';
  final Set<int> _kahfPages = {};

  /// Pages of al-Kahf read today.
  Set<int> get kahfPagesToday => _kahfDay == _today() ? _kahfPages : const <int>{};

  void markKahfPage(int page, int total) {
    final today = _today();
    if (_kahfDay != today) {
      _kahfDay = today;
      _kahfPages.clear();
    }
    if (!_kahfPages.add(page)) return;
    if (_kahfPages.length >= total) UserStore.instance.stampDone('kahf:$today');
    _prefs?.setString(_kKahf, '$_kahfDay:${_kahfPages.join(',')}');
    notifyListeners();
  }
}
