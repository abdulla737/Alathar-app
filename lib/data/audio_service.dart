import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../config/audio_config.dart';
import 'sample_data.dart';

/// Why playing failed, so the screen can tell the user.
enum AudioError { none, offline, noArabicVoice, nothingToPlay }

/// Plays the 🔊 audio everywhere in the app, one thing at a time:
///
/// 1. An own recording (`audio_url`) if the row has one.
/// 2. Qur'an verses (`quran_ref`) from al-Husary's verse-by-verse recordings,
///    saved on the phone after the first play.
/// 3. Otherwise hadith and athkar are read by the phone's Arabic voice.
///    Qur'an text is never read by the phone voice.
///
/// Screens listen to this (it's a ChangeNotifier) to show ▶ or ■ on the
/// button whose [playingKey] matches.
class AudioService extends ChangeNotifier {
  AudioService._() {
    _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) _finished();
    });
    _tts.setCompletionHandler(_finished);
    _tts.setCancelHandler(() {});
    _tts.setErrorHandler((_) => _clear());
  }
  static final AudioService instance = AudioService._();

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  /// What is playing now, e.g. "h:123" (hadith) or "d:101" (dhikr).
  String? playingKey;
  VoidCallback? _onDone;

  bool isPlaying(String key) => playingKey == key;

  static String hadithKey(Hadith h) => 'h:${h.id}';
  static String dhikrKey(Dhikr d) => 'd:${d.id}:${d.categoryId}:${d.sort}';

  /// Whether a 🔊 button makes sense for this text.
  static bool canPlayHadith(Hadith h) =>
      h.audioUrl.isNotEmpty ||
      h.quranRef.isNotEmpty ||
      (h.kind != HadithKind.ayah && h.arabic.isNotEmpty);

  /// Play (or stop, if it's already playing) a hadith, verse or athar.
  Future<AudioError> toggleHadith(Hadith h) async {
    final key = hadithKey(h);
    if (isPlaying(key)) {
      await stop();
      return AudioError.none;
    }
    if (h.audioUrl.isNotEmpty) return _playUrls(key, [h.audioUrl]);
    if (h.quranRef.isNotEmpty) return _playUrls(key, quranUrls(h.quranRef));
    if (h.kind == HadithKind.ayah) return AudioError.nothingToPlay;
    return _speak(key, h.arabic);
  }

  /// Play (or stop) a dhikr. [onDone] runs when it finishes playing on its
  /// own (not when stopped) — the counter uses it to count one repetition.
  Future<AudioError> toggleDhikr(Dhikr d, {VoidCallback? onDone}) async {
    final key = dhikrKey(d);
    if (isPlaying(key)) {
      await stop();
      return AudioError.none;
    }
    final AudioError result;
    if (d.audioUrl.isNotEmpty) {
      result = await _playUrls(key, [d.audioUrl]);
    } else if (d.quranRef.isNotEmpty) {
      result = await _playUrls(key, quranUrls(d.quranRef));
    } else {
      result = await _speak(key, d.arabic);
    }
    if (result == AudioError.none) _onDone = onDone;
    return result;
  }

  Future<void> stop() async {
    _onDone = null;
    try {
      await _player.stop();
      await _tts.stop();
    } catch (_) {}
    _clear();
  }

  // ------------------------------------------------------------ Qur'an

  /// "2:255" → [.../002255.mp3]; "112:1-4|113:1-5" → the basmala, then each
  /// verse. The basmala is added before a surah recited from its first
  /// verse (not for al-Fatiha, where it is verse 1, nor for at-Tawbah).
  static List<String> quranUrls(String ref) {
    final urls = <String>[];
    String file(int s, int a) =>
        '${AudioConfig.quranBase}/${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';
    for (final part in ref.split('|')) {
      final m = RegExp(r'^\s*(\d+):(\d+)(?:-(\d+))?\s*$').firstMatch(part);
      if (m == null) continue;
      final s = int.parse(m.group(1)!);
      final from = int.parse(m.group(2)!);
      final to = int.parse(m.group(3) ?? m.group(2)!);
      if (from == 1 && s != 1 && s != 9) urls.add(file(1, 1));
      for (var a = from; a <= to; a++) {
        urls.add(file(s, a));
      }
    }
    return urls;
  }

  Future<AudioError> _playUrls(String key, List<String> urls) async {
    if (urls.isEmpty) return AudioError.nothingToPlay;
    await stop();
    playingKey = key;
    notifyListeners();
    try {
      // Saved on the phone after the first play (not on the web build).
      final sources = <AudioSource>[
        for (final u in urls)
          if (kIsWeb) AudioSource.uri(Uri.parse(u)) else LockCachingAudioSource(Uri.parse(u)),
      ];
      await _player.setAudioSource(ConcatenatingAudioSource(children: sources));
      _player.play(); // not awaited: completes when playback ends
      return AudioError.none;
    } catch (e) {
      debugPrint('Audio failed: $e');
      _clear();
      return AudioError.offline;
    }
  }

  // ------------------------------------------------- phone's Arabic voice

  Future<bool> _prepareTts() async {
    if (_ttsReady) return true;
    for (final lang in [AudioConfig.ttsLanguage, 'ar']) {
      try {
        final ok = await _tts.isLanguageAvailable(lang);
        if (ok == true || ok == 1) {
          await _tts.setLanguage(lang);
          await _tts.setSpeechRate(AudioConfig.ttsRate);
          await _tts.awaitSpeakCompletion(false);
          return _ttsReady = true;
        }
      } catch (_) {}
    }
    return false;
  }

  /// Text as the voice should read it.
  static String _forSpeech(String text) => text
      .replaceAll('ﷺ', ' صلى الله عليه وسلم ')
      .replaceAll(RegExp(r'[«»﴿﴾\[\]()…]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  Future<AudioError> _speak(String key, String text) async {
    if (text.trim().isEmpty) return AudioError.nothingToPlay;
    await stop();
    if (!await _prepareTts()) return AudioError.noArabicVoice;
    playingKey = key;
    notifyListeners();
    await _tts.speak(_forSpeech(text));
    return AudioError.none;
  }

  // ------------------------------------------------------------ state

  void _finished() {
    final done = _onDone;
    _onDone = null;
    _clear();
    done?.call();
  }

  void _clear() {
    if (playingKey == null) return;
    playingKey = null;
    notifyListeners();
  }
}
