import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings, saved on the phone with shared_preferences.
/// No account or internet needed. Call [load] once at startup.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  SharedPreferences? _prefs;

  /// App language: 'ar' (default), 'en' or 'ur'.
  /// MaterialApp listens to this to switch locale and text direction.
  final ValueNotifier<String> languageNotifier = ValueNotifier<String>('ar');
  String get language => languageNotifier.value;

  /// Dark mode (moon/sun button on the Today page). MaterialApp listens to
  /// this and rebuilds the whole app in the new colors.
  final ValueNotifier<bool> darkNotifier = ValueNotifier<bool>(false);
  bool get darkMode => darkNotifier.value;

  double arabicSize = 26;

  /// Range for the reading size (settings slider and two-finger pinch).
  static const minArabicSize = 18.0;
  static const maxArabicSize = 44.0;

  /// Size of the «الشرح» (explanation) text on the hadith page, set with
  /// its own A− / A+ bar there.
  double explanationSize = 16;
  static const minExplanationSize = 12.0;
  static const maxExplanationSize = 28.0;

  /// Zoom for the athkar reading screen (A− / A+ at its top), 1.0 = normal.
  /// A multiplier because that screen sizes each dhikr by its length.
  double athkarScale = 1.0;
  static const minAthkarScale = 0.7;
  static const maxAthkarScale = 1.6;

  /// Zoom for a book chapter page (e.g. كتاب التوحيد), set with A− / A+ at
  /// its top. Scales every text on that page together. 1.0 = normal.
  double bookScale = 1.0;
  static const minBookScale = 0.8;
  static const maxBookScale = 1.8;
  /// Daily reading goals (Settings → «الورد اليومي»): hadith per day,
  /// Qur'an pages per day, and the surahs the Qur'an reading covers.
  int hadithPerDay = 1;
  static const maxHadithPerDay = 10;
  int quranPagesPerDay = 2;
  static const maxQuranPagesPerDay = 40;
  /// «ختمة» (the whole mushaf, page 1 to 604; default) or a custom range of
  /// surahs ([rangeFrom] … [rangeTo]).
  bool quranKhatma = true;
  int rangeFrom = 1;
  int rangeTo = 114;

  /// The surahs the daily reading covers now (whole Qur'an for a khatma).
  int get quranFromSurah => quranKhatma ? 1 : rangeFrom;
  int get quranToSurah => quranKhatma ? 114 : rangeTo;

  String translation = 'English';
  bool onboardingDone = false;

  /// The user's first name for the Today greeting («السلام عليكم عبدالله»).
  String userName = '';

  final Map<String, bool> reminders = {
    'hadith': true,
    'morning': true,
    'evening': true,
    'quran': true, // «ورد التلاوة اليومية»
    'friday': true, // «تذكير بسنن يوم الجمعة»: Friday card on Today
    'nudges': false,
  };

  // Storage keys
  static const _kLanguage = 'language';
  static const _kDark = 'dark_mode';
  static const _kArabicSize = 'arabic_size';
  static const _kExplanationSize = 'explanation_size';
  static const _kAthkarScale = 'athkar_scale';
  static const _kBookScale = 'book_scale';
  static const _kTranslation = 'translation';
  static const _kHadithPerDay = 'goal_hadith_per_day';
  static const _kQuranPages = 'goal_quran_pages';
  static const _kQuranFrom = 'goal_quran_from';
  static const _kQuranTo = 'goal_quran_to';
  static const _kQuranKhatma = 'goal_quran_khatma';
  static const _kOnboarding = 'onboarding_done';
  static const _kUserName = 'user_name';
  static String _kReminder(String key) => 'reminder_$key';

  /// Reads saved settings from the phone. Missing values keep their defaults.
  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    languageNotifier.value = p.getString(_kLanguage) ?? 'ar';
    darkNotifier.value = p.getBool(_kDark) ?? false;
    arabicSize = (p.getDouble(_kArabicSize) ?? 26).clamp(minArabicSize, maxArabicSize);
    explanationSize = (p.getDouble(_kExplanationSize) ?? 16)
        .clamp(minExplanationSize, maxExplanationSize);
    athkarScale = (p.getDouble(_kAthkarScale) ?? 1.0).clamp(minAthkarScale, maxAthkarScale);
    bookScale = (p.getDouble(_kBookScale) ?? 1.0).clamp(minBookScale, maxBookScale);
    translation = p.getString(_kTranslation) ?? 'English';
    hadithPerDay = (p.getInt(_kHadithPerDay) ?? 1).clamp(1, maxHadithPerDay);
    quranPagesPerDay = (p.getInt(_kQuranPages) ?? 2).clamp(1, maxQuranPagesPerDay);
    // The daily reading is always a khatma (chosen surahs were removed).
    quranKhatma = true;
    rangeFrom = (p.getInt(_kQuranFrom) ?? 1).clamp(1, 113);
    rangeTo = (p.getInt(_kQuranTo) ?? 114).clamp(rangeFrom + 1, 114);
    onboardingDone = p.getBool(_kOnboarding) ?? false;
    userName = p.getString(_kUserName) ?? '';
    for (final key in reminders.keys.toList()) {
      reminders[key] = p.getBool(_kReminder(key)) ?? reminders[key]!;
    }
  }

  void setLanguage(String value) {
    if (value == languageNotifier.value) return;
    languageNotifier.value = value;
    _prefs?.setString(_kLanguage, value);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    if (value == darkNotifier.value) return;
    darkNotifier.value = value;
    _prefs?.setBool(_kDark, value);
    notifyListeners();
  }

  /// [save] false while a pinch is still moving; saved when the fingers lift.
  void setArabicSize(double value, {bool save = true}) {
    arabicSize = value.clamp(minArabicSize, maxArabicSize);
    if (save) _prefs?.setDouble(_kArabicSize, arabicSize);
    notifyListeners();
  }

  void setExplanationSize(double value) {
    explanationSize = value.clamp(minExplanationSize, maxExplanationSize);
    _prefs?.setDouble(_kExplanationSize, explanationSize);
    notifyListeners();
  }

  void setAthkarScale(double value) {
    // Rounded to one decimal so repeated taps don't drift.
    athkarScale =
        (value.clamp(minAthkarScale, maxAthkarScale) * 10).roundToDouble() / 10;
    _prefs?.setDouble(_kAthkarScale, athkarScale);
    notifyListeners();
  }

  void setBookScale(double value) {
    bookScale = (value.clamp(minBookScale, maxBookScale) * 10).roundToDouble() / 10;
    _prefs?.setDouble(_kBookScale, bookScale);
    notifyListeners();
  }

  void setHadithPerDay(int value) {
    hadithPerDay = value.clamp(1, maxHadithPerDay);
    _prefs?.setInt(_kHadithPerDay, hadithPerDay);
    notifyListeners();
  }

  void setQuranPagesPerDay(int value) {
    quranPagesPerDay = value.clamp(1, maxQuranPagesPerDay);
    _prefs?.setInt(_kQuranPages, quranPagesPerDay);
    notifyListeners();
  }

  void setQuranKhatma(bool value) {
    quranKhatma = value;
    _prefs?.setBool(_kQuranKhatma, value);
    notifyListeners();
  }

  /// A custom range of surahs: [to] comes after [from].
  void setQuranRange(int from, int to) {
    rangeFrom = from.clamp(1, 113);
    rangeTo = to.clamp(rangeFrom + 1, 114);
    _prefs?.setInt(_kQuranFrom, rangeFrom);
    _prefs?.setInt(_kQuranTo, rangeTo);
    notifyListeners();
  }

  void setUserName(String value) {
    final v = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (v == userName) return;
    userName = v.length > 30 ? v.substring(0, 30) : v;
    _prefs?.setString(_kUserName, userName);
    notifyListeners();
  }

  void setTranslation(String value) {
    translation = value;
    _prefs?.setString(_kTranslation, value);
    notifyListeners();
  }

  void toggleReminder(String key) {
    final value = !(reminders[key] ?? false);
    reminders[key] = value;
    _prefs?.setBool(_kReminder(key), value);
    notifyListeners();
  }

  /// Called when the user taps "Get started", so onboarding shows only once.
  void completeOnboarding() {
    onboardingDone = true;
    _prefs?.setBool(_kOnboarding, true);
  }
}
