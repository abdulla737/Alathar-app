/// Audio settings.
///
/// Qur'an verses are played from verse-by-verse recordings by Sheikh
/// Mahmoud Khalil al-Husary (EveryAyah.com). Each verse is one file named
/// SSSAAA.mp3 (surah and verse, three digits each), e.g. 002255.mp3.
/// Files are saved on the phone after the first play, so they work offline.
///
/// To use another reciter, change [quranBase] to that reciter's folder,
/// e.g. 'https://everyayah.com/data/Husary_128kbps' (higher quality) or
/// 'https://everyayah.com/data/Alafasy_128kbps'.
/// Check the site's terms of use before release.
class AudioConfig {
  /// Master switch for all 🔊 buttons. Off for now: the recitation and the
  /// phone voice weren't good enough. Set to true to bring sound back.
  static const enabled = false;

  static const quranBase = 'https://everyayah.com/data/Husary_64kbps';
  static const reciterAr = 'محمود خليل الحصري';
  static const reciterEn = 'Mahmoud Khalil al-Husary';

  /// Language for the phone's built-in voice (hadith and athkar until
  /// recordings are added). Falls back to plain 'ar' if not installed.
  static const ttsLanguage = 'ar-SA';
  static const ttsRate = 0.42; // 0.0–1.0; slower is clearer for Arabic
}
