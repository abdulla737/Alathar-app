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
  String translation = 'English';
  bool onboardingDone = false;

  final Map<String, bool> reminders = {
    'hadith': true,
    'morning': true,
    'evening': true,
    'friday': true, // «تذكير بسنن يوم الجمعة»: Friday card on Today
    'nudges': false,
  };

  // Storage keys
  static const _kLanguage = 'language';
  static const _kArabicSize = 'arabic_size';
  static const _kExplanationSize = 'explanation_size';
  static const _kAthkarScale = 'athkar_scale';
  static const _kBookScale = 'book_scale';
  static const _kTranslation = 'translation';
  static const _kOnboarding = 'onboarding_done';
  static String _kReminder(String key) => 'reminder_$key';

  /// Reads saved settings from the phone. Missing values keep their defaults.
  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    languageNotifier.value = p.getString(_kLanguage) ?? 'ar';
    arabicSize = (p.getDouble(_kArabicSize) ?? 26).clamp(minArabicSize, maxArabicSize);
    explanationSize = (p.getDouble(_kExplanationSize) ?? 16)
        .clamp(minExplanationSize, maxExplanationSize);
    athkarScale = (p.getDouble(_kAthkarScale) ?? 1.0).clamp(minAthkarScale, maxAthkarScale);
    bookScale = (p.getDouble(_kBookScale) ?? 1.0).clamp(minBookScale, maxBookScale);
    translation = p.getString(_kTranslation) ?? 'English';
    onboardingDone = p.getBool(_kOnboarding) ?? false;
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
