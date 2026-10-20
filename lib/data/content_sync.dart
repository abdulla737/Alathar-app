import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'content_store.dart';

enum SyncResult { updated, upToDate, offline }

/// Downloads new or changed content from Supabase when the phone is online.
/// Never blocks the app: if there is no internet, it quietly does nothing
/// and the app keeps using the content already on the phone.
class ContentSync {
  static bool _ready = false;
  static Future<SyncResult>? _running;

  /// Call once in main(). Works offline (no network needed to initialize).
  static Future<void> init() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey, // publishable key goes here
      );
      _ready = true;
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
  }

  /// Checks for new content. Safe to call any time; only one runs at once.
  static Future<SyncResult> run() =>
      _running ??= _run().whenComplete(() => _running = null);

  static const _pageSize = 1000; // Supabase returns at most 1000 rows per request

  static Future<SyncResult> _run() async {
    if (!_ready) return SyncResult.offline;
    final store = ContentStore.instance;
    final db = Supabase.instance.client;

    try {
      // 1. What is the newest content version on the server?
      final latest = await db
          .from('content_versions')
          .select('version')
          .order('version', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      final serverVersion = (latest?['version'] as int?) ?? 0;
      if (serverVersion <= store.version) return SyncResult.upToDate;

      // 2. For each table, download only rows changed since the last time.
      //    Books first, then chapters, then texts.
      var total = 0;
      for (final table in ContentStore.tables) {
        try {
          final rows = await _download(db, table, store.lastSync(table));
          store.applyRows(table, rows);
          total += rows.length;
        } on PostgrestException catch (e) {
          // e.g. the "chapters" table wasn't created yet — skip it for now.
          debugPrint('Skipped table $table: ${e.message}');
        }
      }

      // 3. Refresh the screens.
      store.finishSync(serverVersion);
      debugPrint('Content updated to v$serverVersion ($total rows)');
      return SyncResult.updated;
    } on TimeoutException {
      return SyncResult.offline;
    } catch (e) {
      // No internet, project paused, etc. Try again next launch.
      debugPrint('Content sync skipped: $e');
      return SyncResult.offline;
    }
  }

  static Future<List<Map<String, dynamic>>> _download(
      SupabaseClient db, String table, String? since) async {
    final rows = <Map<String, dynamic>>[];
    for (var from = 0;; from += _pageSize) {
      var query = db.from(table).select();
      if (since != null) query = query.gt('updated_at', since);
      final page = await query
          .order('updated_at')
          .order('id')
          .range(from, from + _pageSize - 1)
          .timeout(const Duration(seconds: 20));
      rows.addAll(page);
      if (page.length < _pageSize) break;
    }
    return rows;
  }
}
