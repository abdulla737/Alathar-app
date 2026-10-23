import 'dart:convert';

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One explanation and the verses it covers (some are grouped, e.g. 2:106–107).
class TafsirEntry {
  final int surah;
  final int from;
  final int to;
  final String text;
  const TafsirEntry(this.surah, this.from, this.to, this.text);
}

/// «تفسير السعدي» (تيسير الكريم الرحمن), bundled in Arabic.
/// Asset: a gzipped JSON list of 114 surahs, each a list with one string per
/// verse; an empty string means that verse is explained with the one before.
class TafsirStore {
  TafsirStore._();
  static final instance = TafsirStore._();

  List<List<String>> _data = const [];
  Future<void>? _loading;

  bool get isLoaded => _data.isNotEmpty;

  Future<void> ensureLoaded() => _loading ??= _load().catchError((Object e) {
        _loading = null; // try again next time
        throw e;
      });

  Future<void> _load() async {
    final bytes = await rootBundle.load('assets/quran/saadi.json.gz');
    _data = await compute(_decode, bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
  }

  static List<List<String>> _decode(Uint8List gz) {
    // Pure-Dart gzip, so the same code runs in the web version.
    final list = jsonDecode(utf8.decode(GZipDecoder().decodeBytes(gz))) as List;
    return [for (final s in list) (s as List).cast<String>()];
  }

  /// The explanation that covers [ayah] of [surah] (call [ensureLoaded] first).
  TafsirEntry? of(int surah, int ayah) {
    if (surah < 1 || surah > _data.length) return null;
    final s = _data[surah - 1];
    if (ayah < 1 || ayah > s.length) return null;
    var from = ayah;
    while (from > 1 && s[from - 1].isEmpty) {
      from--;
    }
    if (s[from - 1].isEmpty) return null;
    var to = from;
    while (to < s.length && s[to].isEmpty) {
      to++;
    }
    return TafsirEntry(surah, from, to, s[from - 1]);
  }
}
