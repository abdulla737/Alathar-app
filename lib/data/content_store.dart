import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'athkar_data.dart';
import 'friday_data.dart';
import 'sample_data.dart';

/// Everything the app can show: books (collections), chapters and texts
/// (hadith, verses, athar). It combines the content bundled inside the app
/// with newer rows downloaded from Supabase and saved on the phone.
///
/// The app always works offline: if nothing was downloaded yet, it simply
/// uses the bundled content.
///
/// Note: downloaded rows are kept in shared_preferences for now. When the
/// content grows to thousands of rows, move this cache into a local SQLite
/// database (same methods, different storage).
class ContentStore extends ChangeNotifier {
  ContentStore._();
  static final ContentStore instance = ContentStore._();

  /// Supabase tables the app downloads.
  static const tables = ['collections', 'chapters', 'hadith', 'athkar_categories', 'athkar'];

  SharedPreferences? _prefs;

  /// Content version on this phone (0 = only the bundled content).
  int version = 0;

  /// Per table: newest `updated_at` received (server clock).
  final Map<String, String> _lastSync = {};

  /// Per table: downloaded rows by id, exactly as Supabase returned them.
  final Map<String, Map<int, Map<String, dynamic>>> _rows = {
    for (final t in tables) t: {},
  };

  List<Collection>? _collections;
  List<Chapter>? _chapters;
  List<Hadith>? _hadith;
  List<AthkarCategory>? _athkarCategories;
  List<Dhikr>? _athkar;

  static const _kVersion = 'content_version';
  static String _kRows(String table) => 'content_$table';
  static String _kSync(String table) => 'content_last_sync_$table';

  String? lastSync(String table) => _lastSync[table];

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    version = p.getInt(_kVersion) ?? 0;
    try {
      for (final t in tables) {
        final sync = p.getString(_kSync(t)) ??
            (t == 'hadith' ? p.getString('content_last_sync') : null); // older key
        if (sync != null) _lastSync[t] = sync;
        final raw = p.getString(_kRows(t));
        if (raw == null) continue;
        for (final row in jsonDecode(raw) as List) {
          final m = Map<String, dynamic>.from(row as Map);
          _rows[t]![m['id'] as int] = m;
        }
      }
    } catch (_) {
      // Bad cache: drop it and download everything again next time.
      for (final t in tables) {
        _rows[t]!.clear();
      }
      _lastSync.clear();
      version = 0;
    }
  }

  /// Saves rows downloaded for one table.
  void applyRows(String table, List<Map<String, dynamic>> rows) {
    final store = _rows[table]!;
    for (final row in rows) {
      store[row['id'] as int] = row;
      final updated = row['updated_at'] as String?;
      final last = _lastSync[table];
      if (updated != null && (last == null || updated.compareTo(last) > 0)) {
        _lastSync[table] = updated;
      }
    }
    _prefs?.setString(_kRows(table), jsonEncode(store.values.toList()));
    final last = _lastSync[table];
    if (last != null) _prefs?.setString(_kSync(table), last);
  }

  /// Marks the download as complete and refreshes every screen.
  void finishSync(int newVersion) {
    version = newVersion;
    _prefs?.setInt(_kVersion, version);
    _collections = null;
    _chapters = null;
    _hadith = null;
    _athkarCategories = null;
    _athkar = null;
    notifyListeners();
  }

  // ------------------------------------------------------------- books

  List<Collection> get collections {
    if (_collections != null) return _collections!;
    final byId = {for (final c in SampleData.collections) c.id: c};
    for (final r in _rows['collections']!.values) {
      final id = r['id'] as int;
      if (r['deleted'] == true) {
        byId.remove(id);
      } else {
        byId[id] = _collectionFromRow(r, byId[id]);
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.sort != b.sort ? a.sort.compareTo(b.sort) : a.id.compareTo(b.id));
    return _collections = list;
  }

  Collection? collection(int id) {
    for (final c in collections) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ---------------------------------------------------------- chapters

  List<Chapter> get chapters {
    if (_chapters != null) return _chapters!;
    final byId = {for (final c in SampleData.chapters) c.id: c};
    for (final r in _rows['chapters']!.values) {
      final id = r['id'] as int;
      if (r['deleted'] == true) {
        byId.remove(id);
      } else {
        byId[id] = _chapterFromRow(r, byId[id]);
      }
    }
    return _chapters = byId.values.toList();
  }

  Chapter? chapter(int id) {
    for (final c in chapters) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Chapters of one book, in order.
  List<Chapter> chaptersOf(int collectionId) =>
      chapters.where((c) => c.collectionId == collectionId).toList()
        ..sort((a, b) => a.number.compareTo(b.number));

  /// Verses, hadith and athar of one chapter, in book order.
  List<Hadith> entriesInChapter(int chapterId) =>
      allHadith.where((h) => h.chapterId == chapterId).toList()
        ..sort((a, b) => a.numberInBook != b.numberInBook
            ? a.numberInBook.compareTo(b.numberInBook)
            : a.id.compareTo(b.id));

  // ------------------------------------------------------------ hadith

  /// Bundled content merged with downloaded rows. A downloaded row replaces
  /// the bundled one with the same id, but empty fields fall back to the
  /// bundled text. Rows marked `deleted` are hidden.
  List<Hadith> get allHadith {
    if (_hadith != null) return _hadith!;
    final byId = {for (final h in SampleData.allHadith) h.id: h};
    for (final r in _rows['hadith']!.values) {
      final id = r['id'] as int;
      if (r['deleted'] == true) {
        byId.remove(id);
      } else {
        byId[id] = _hadithFromRow(r, byId[id]);
      }
    }
    final list = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    return _hadith = list;
  }

  /// Hadith (not verses) of a book, in book order.
  List<Hadith> hadithInCollection(int collectionId) =>
      allHadith.where((h) => h.collectionId == collectionId && h.kind == HadithKind.hadith).toList()
        ..sort((a, b) => a.numberInBook != b.numberInBook
            ? a.numberInBook.compareTo(b.numberInBook)
            : a.id.compareTo(b.id));

  Hadith? find(int id) {
    for (final h in allHadith) {
      if (h.id == id) return h;
    }
    for (final h in fridayHadith) {
      if (h.id == id) return h;
    }
    return null;
  }

  static const _kHotd = 'hadith_of_the_day'; // "YYYY-MM-DD:id"

  /// One hadith per day: the same all day long and on every phone.
  ///
  /// - The pool is every hadith with `daily_ok` (verses, athar and disputed
  ///   narrations are left out).
  /// - The pool is put in a fixed shuffled order (by a hash of the id), so
  ///   the books mix instead of running chapter by chapter; each day takes
  ///   the next one, and the whole pool is shown before any repeats.
  /// - Today's pick is remembered, so new content downloaded during the day
  ///   does not change it. A new one appears after midnight.
  Hadith hadithOfToday() {
    final pool =
        allHadith.where((h) => h.dailyOk && h.kind == HadithKind.hadith).toList();
    if (pool.isEmpty) return SampleData.hadithOfTheDay;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final key = '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    // Already chosen today?
    final saved = _prefs?.getString(_kHotd);
    if (saved != null && saved.startsWith('$key:')) {
      final id = int.tryParse(saved.substring(key.length + 1));
      for (final h in pool) {
        if (h.id == id) return h;
      }
    }

    pool.sort((a, b) {
      final ha = _mix(a.id), hb = _mix(b.id);
      return ha != hb ? ha.compareTo(hb) : a.id.compareTo(b.id);
    });
    // UTC dates so daylight-saving changes never skip or repeat a day.
    final day = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(2024, 1, 1))
        .inDays;
    final pick = pool[day % pool.length];
    _prefs?.setString(_kHotd, '$key:${pick.id}');
    return pick;
  }

  /// Today's hadith reading: today's hadith and the next [count] − 1 in the
  /// same fixed order, so a goal of 3 a day gives 3 different hadith.
  List<Hadith> hadithsOfToday(int count) {
    final first = hadithOfToday();
    final pool =
        allHadith.where((h) => h.dailyOk && h.kind == HadithKind.hadith).toList();
    if (pool.length < 2 || count <= 1) return [first];
    pool.sort((a, b) {
      final ha = _mix(a.id), hb = _mix(b.id);
      return ha != hb ? ha.compareTo(hb) : a.id.compareTo(b.id);
    });
    final start = pool.indexWhere((h) => h.id == first.id);
    if (start < 0) return [first];
    final n = count.clamp(1, pool.length);
    return [for (var i = 0; i < n; i++) pool[(start + i) % pool.length]];
  }

  /// Spreads ids into a stable pseudo-random order (same on every phone and
  /// on the web build: the numbers stay below 2^53, no bit operations).
  static int _mix(int id) => (id * 2654435761) % 4294967291;

  // ------------------------------------------------------------ athkar

  /// Athkar categories (bundled + downloaded), in order.
  List<AthkarCategory> get athkarCategories {
    if (_athkarCategories != null) return _athkarCategories!;
    final byId = {for (final c in bundledAthkarCategories) c.id: c};
    final sortOf = {for (final c in bundledAthkarCategories) c.id: c.id};
    for (final r in _rows['athkar_categories']!.values) {
      final id = r['id'] as int;
      if (r['deleted'] == true) {
        byId.remove(id);
      } else {
        final fb = byId[id];
        byId[id] = AthkarCategory(
          _s(r, 'badge_ar') ?? fb?.badge ?? '',
          _lt(r, 'name', fb?.name),
          id: id,
          slug: _s(r, 'slug') ?? fb?.slug ?? '',
        );
        sortOf[id] = (r['sort'] as int?) ?? sortOf[id] ?? id;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => (sortOf[a.id] ?? a.id).compareTo(sortOf[b.id] ?? b.id));
    return _athkarCategories = list;
  }

  /// The app's own slugs and their fixed category ids. The server may name a
  /// category differently (e.g. 'prayer' for 'after_prayer'), so the id is
  /// the fallback.
  static const _slugIds = {'morning': 1, 'evening': 2, 'after_prayer': 3, 'sleep': 4};

  AthkarCategory? athkarCategoryBySlug(String slug) {
    final cats = athkarCategories;
    for (final c in cats) {
      if (c.slug == slug) return c;
    }
    final id = _slugIds[slug];
    if (id == null) return null;
    for (final c in cats) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Dhikr> get _allAthkar {
    if (_athkar != null) return _athkar!;
    final byId = {for (final d in bundledAthkar) d.id: d};
    for (final r in _rows['athkar']!.values) {
      final id = r['id'] as int;
      if (r['deleted'] == true) {
        byId.remove(id);
      } else {
        byId[id] = _dhikrFromRow(r, byId[id]);
      }
    }
    return _athkar = byId.values.toList();
  }

  /// The athkar of one category, in order.
  List<Dhikr> athkarIn(int categoryId) =>
      _allAthkar.where((d) => d.categoryId == categoryId).toList()
        ..sort((a, b) => a.sort != b.sort ? a.sort.compareTo(b.sort) : a.id.compareTo(b.id));

  // ----------------------------------------------------------- mapping

  static String? _s(Map<String, dynamic> r, String key) {
    final v = r[key];
    return (v is String && v.trim().isNotEmpty) ? v : null;
  }

  static LText _lt(Map<String, dynamic> r, String base, LText? fb) => LText(
        ar: _s(r, '${base}_ar') ?? fb?.ar ?? '',
        en: _s(r, '${base}_en') ?? fb?.en ?? _s(r, '${base}_ar') ?? '',
        ur: _s(r, '${base}_ur') ?? fb?.ur,
      );

  static Collection _collectionFromRow(Map<String, dynamic> r, Collection? fb) => Collection(
        r['id'] as int,
        _s(r, 'slug') ?? fb?.slug ?? '',
        _s(r, 'badge_ar') ?? fb?.badge ?? '',
        _lt(r, 'name', fb?.name),
        _lt(r, 'meta', fb?.meta),
        (r['sort'] as int?) ?? fb?.sort ?? 0,
      );

  static Dhikr _dhikrFromRow(Map<String, dynamic> r, Dhikr? fb) {
    // Source line shown under the virtue, e.g. «رواه مسلم · صحيح».
    String join(String? a, String? b) =>
        [a, b].where((x) => x != null && x.isNotEmpty).join(' · ');
    final srcAr = join(_s(r, 'source_ar'), _s(r, 'grade_ar'));
    final srcEn = join(_s(r, 'source_en') ?? _s(r, 'source_ar'), _s(r, 'grade_en') ?? _s(r, 'grade_ar'));
    return Dhikr(
      id: r['id'] as int,
      categoryId: (r['category_id'] as int?) ?? fb?.categoryId ?? 0,
      sort: (r['sort'] as int?) ?? fb?.sort ?? 0,
      arabic: _s(r, 'arabic') ?? fb?.arabic ?? '',
      transliteration: _s(r, 'transliteration') ?? fb?.transliteration ?? '',
      // TODO: show translation_ur in Urdu once Urdu translations are added.
      translation: _s(r, 'translation_en') ?? fb?.translation ?? '',
      virtue: _lt(r, 'virtue', fb?.virtue),
      source: srcAr.isNotEmpty
          ? LText(ar: srcAr, en: srcEn.isNotEmpty ? srcEn : srcAr)
          : (fb?.source ?? const LText(ar: '', en: '')),
      count: (r['repeat_count'] as int?) ?? fb?.count ?? 1,
      quranRef: _s(r, 'quran_ref') ?? fb?.quranRef ?? '',
      audioUrl: _s(r, 'audio_url') ?? fb?.audioUrl ?? '',
    );
  }

  static Chapter _chapterFromRow(Map<String, dynamic> r, Chapter? fb) => Chapter(
        id: r['id'] as int,
        collectionId: (r['collection_id'] as int?) ?? fb?.collectionId ?? 0,
        number: (r['number'] as int?) ?? fb?.number ?? 0,
        title: _lt(r, 'title', fb?.title),
        masail: _lt(r, 'masail', fb?.masail),
      );

  Hadith _hadithFromRow(Map<String, dynamic> r, Hadith? fb) {
    const empty = LText(ar: '', en: '');
    final collectionId = (r['collection_id'] as int?) ?? fb?.collectionId ?? 0;
    final topicId = r['topic_id'];
    final topicIndex = (topicId is int) ? topicId - 1 : -1;
    final topic = (topicIndex >= 0 && topicIndex < SampleData.topics.length)
        ? SampleData.topics[topicIndex].name
        : fb?.topic;

    return Hadith(
      id: r['id'] as int,
      collectionId: collectionId,
      chapterId: (r['chapter_id'] as int?) ?? fb?.chapterId,
      numberInBook: (r['number_in_book'] as int?) ?? fb?.numberInBook ?? 0,
      kind: r.containsKey('kind') ? kindFromString(r['kind']) : (fb?.kind ?? HadithKind.hadith),
      title: _lt(r, 'title', fb?.title),
      quranRef: _s(r, 'quran_ref') ?? fb?.quranRef ?? '',
      audioUrl: _s(r, 'audio_url') ?? fb?.audioUrl ?? '',
      arabic: _s(r, 'arabic') ?? fb?.arabic ?? '',
      translation: _s(r, 'translation_en') ?? fb?.translation ?? '',
      reference: _lt(r, 'reference', fb?.reference),
      fullReference: _lt(r, 'full_ref', fb?.fullReference),
      narrator: _lt(r, 'narrator', fb?.narrator),
      grade: _lt(r, 'grade', fb?.grade),
      collection: collection(collectionId)?.name ?? fb?.collection ?? empty,
      topic: topic ?? empty,
      explanation: _lt(r, 'explanation', fb?.explanation),
      action: _lt(r, 'action', fb?.action),
      attribution: fb?.attribution ??
          const LText(
            ar: 'المصدر: موسوعة الأحاديث النبوية HadeethEnc.com',
            en: 'Source: HadeethEnc.com',
            ur: 'ماخذ: HadeethEnc.com',
          ),
      dailyOk: r['daily_ok'] != false,
    );
  }
}
