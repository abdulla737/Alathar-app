// Sample content used by the screens until the local SQLite database is
// connected. Replace these lists with queries to your database later.
// Verify every reference against your chosen source before release.

import 'app_settings.dart';
import 'athkar_data.dart';

/// A piece of content text in each language.
/// Urdu falls back to English until Urdu content is added
/// (HadeethEnc provides Urdu translations and explanations).
class LText {
  final String ar;
  final String en;
  final String? ur;
  const LText({required this.ar, required this.en, this.ur});

  String get v {
    switch (AppSettings.instance.language) {
      case 'ar':
        return ar;
      case 'ur':
        return ur ?? en;
      default:
        return en;
    }
  }
}

class Hadith {
  final int id; // stable id, used to save favorites
  final String arabic; // original text (always shown)
  final String translation; // shown only when the app is not in Arabic
  final LText reference;
  final LText fullReference;
  final LText narrator;
  final LText grade;
  final LText collection;
  final LText topic;
  final LText explanation;
  final LText action;
  final LText attribution;
  final bool dailyOk; // may appear as hadith of the day
  final int collectionId;
  final int? chapterId; // chapter (باب) in a book, if any
  final int numberInBook; // order inside the chapter
  final HadithKind kind;
  final LText title; // short title, e.g. «إنما الأعمال بالنيات» (empty if none)
  final String quranRef; // verses to recite, e.g. "2:255" or "9:128-129" (ayah rows)
  final String audioUrl; // own recording, if any (takes priority)

  const Hadith({
    this.quranRef = '',
    this.audioUrl = '',
    this.title = const LText(ar: '', en: ''),
    this.dailyOk = true,
    this.collectionId = 0,
    this.chapterId,
    this.numberInBook = 0,
    this.kind = HadithKind.hadith,
    required this.id,
    required this.arabic,
    required this.translation,
    required this.reference,
    required this.fullReference,
    required this.narrator,
    required this.grade,
    required this.collection,
    required this.topic,
    required this.explanation,
    required this.action,
    required this.attribution,
  });
}

class Dhikr {
  final int id; // stable id (category × 100 + order)
  final int categoryId;
  final int sort; // order inside the category
  final String arabic;
  final String transliteration; // hidden in Arabic; empty until translated
  final String translation; // hidden in Arabic; empty until translated
  final LText virtue;
  final LText source;
  final int count;
  final String quranRef; // Qur'an athkar, e.g. "2:255" or "112:1-4|113:1-5|114:1-6"
  final String audioUrl; // own recording, if any (takes priority)

  const Dhikr({
    this.quranRef = '',
    this.audioUrl = '',
    this.id = 0,
    this.categoryId = 0,
    this.sort = 0,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.virtue,
    required this.source,
    required this.count,
  });
}

/// What a text inside a book is: a hadith, a Qur'an verse, or a saying of
/// the Companions and Salaf. Books like Kitab at-Tawhid mix all three.
enum HadithKind { hadith, ayah, athar }

HadithKind kindFromString(Object? s) => switch (s) {
      'ayah' => HadithKind.ayah,
      'athar' => HadithKind.athar,
      _ => HadithKind.hadith,
    };

class Collection {
  final int id; // matches the Supabase collections.id
  final String slug;
  final String badge; // short Arabic title on the tile
  final LText name;
  final LText meta;
  final int sort;
  const Collection(this.id, this.slug, this.badge, this.name, this.meta, [this.sort = 0]);
}

/// A chapter (باب) of a book.
class Chapter {
  final int id;
  final int collectionId;
  final int number;
  final LText title;
  final LText masail; // المسائل — may be empty
  const Chapter({
    required this.id,
    required this.collectionId,
    required this.number,
    required this.title,
    this.masail = const LText(ar: '', en: ''),
  });
}

class Topic {
  final String arabic;
  final LText name;
  const Topic(this.arabic, this.name);
}


class AthkarCategory {
  final String badge;
  final LText name;
  final int id;
  final String slug; // 'morning', 'evening', 'sleep' …
  const AthkarCategory(this.badge, this.name, {this.id = 0, this.slug = ''});
}

class SampleData {
  static const _sampleAttribution = LText(
    ar: 'شرح تجريبي مختصر · يُستبدل بنص HadeethEnc.com',
    en: 'Sample explanation · replace with HadeethEnc.com text',
    ur: 'نمونہ تشریح · HadeethEnc.com کے متن سے بدلیں',
  );

  static const hadithOfTheDay = Hadith(
    id: 1,
    collectionId: 3,
    arabic: 'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
    translation:
        '“Actions are only by intentions, and every person will have only what they intended.”',
    reference: LText(ar: 'صحيح البخاري 1', en: 'Sahih al-Bukhari 1', ur: 'صحیح بخاری 1'),
    fullReference: LText(
        ar: 'البخاري 1 · مسلم 1907',
        en: 'Bukhari 1 · Muslim 1907',
        ur: 'بخاری 1 · مسلم 1907'),
    narrator: LText(
        ar: 'عمر بن الخطاب رضي الله عنه',
        en: 'Umar ibn al-Khattab',
        ur: 'عمر بن الخطاب رضی اللہ عنہ'),
    grade: LText(ar: 'صحيح', en: 'Sahih', ur: 'صحیح'),
    collection: LText(ar: 'صحيح البخاري', en: 'Sahih al-Bukhari', ur: 'صحیح بخاری'),
    topic: LText(ar: 'النية', en: 'Intention', ur: 'نیت'),
    explanation: LText(
      ar: 'قيمة كل عمل بنيّة صاحبه؛ فالعمل الواحد قد يكون عبادة أو عادة بحسب القصد منه، '
          'فيجدّد المؤمن نيته ويبتغي رضا الله حتى في أعماله اليومية.',
      en: 'The value of every deed depends on the intention behind it. The same act '
          'can be worship or habit depending on why it is done, so a believer renews '
          'their intention and seeks Allah\'s pleasure in ordinary acts too.',
    ),
    action: LText(
        ar: 'جدّد نيتك قبل عمل من أعمالك اليومية.',
        en: 'Renew your intention before one routine task.',
        ur: 'کسی روزمرہ کام سے پہلے اپنی نیت تازہ کریں۔'),
    attribution: _sampleAttribution,
  );

  static const rightOfAllah = Hadith(
    id: 2,
    collectionId: 3,
    chapterId: 1, // also quoted in Kitab at-Tawhid, chapter 1
    numberInBook: 1,
    arabic:
        'حَقُّ اللَّهِ عَلَى الْعِبَادِ أَنْ يَعْبُدُوهُ وَلَا يُشْرِكُوا بِهِ شَيْئًا، وَحَقُّ الْعِبَادِ عَلَى اللَّهِ أَنْ لَا يُعَذِّبَ مَنْ لَا يُشْرِكُ بِهِ شَيْئًا',
    translation:
        '“The right of Allah over His servants is that they worship Him and associate nothing with Him, '
        'and the right of the servants over Allah is that He does not punish whoever associates nothing with Him.”',
    reference: LText(ar: 'صحيح البخاري 2856', en: 'Sahih al-Bukhari 2856', ur: 'صحیح بخاری 2856'),
    fullReference: LText(
        ar: 'البخاري 2856 · مسلم 30',
        en: 'Bukhari 2856 · Muslim 30',
        ur: 'بخاری 2856 · مسلم 30'),
    narrator: LText(
        ar: 'معاذ بن جبل رضي الله عنه', en: 'Mu\'adh ibn Jabal', ur: 'معاذ بن جبل رضی اللہ عنہ'),
    grade: LText(ar: 'صحيح', en: 'Sahih', ur: 'صحیح'),
    collection: LText(ar: 'صحيح البخاري', en: 'Sahih al-Bukhari', ur: 'صحیح بخاری'),
    topic: LText(ar: 'التوحيد', en: 'Tawheed', ur: 'توحید'),
    explanation: LText(
      ar: 'بيّن النبي ﷺ أن أعظم ما أوجبه الله على عباده أن يفردوه بالعبادة ولا يشركوا به شيئًا، '
          'وأن من حقق ذلك وعده الله بفضله ألا يعذبه. فالتوحيد أصل الدين وسبب النجاة.',
      en: 'The Prophet ﷺ explained that the greatest duty Allah placed on His servants is to worship '
          'Him alone without any partner, and that whoever fulfils this, Allah by His grace has '
          'promised not to punish. Tawheed is the foundation of the religion and the means of salvation.',
    ),
    action: LText(
        ar: 'اجعل دعاءك اليوم لله وحده، واطلب حاجتك منه مباشرة.',
        en: 'Make your duas today to Allah alone, asking Him directly for what you need.',
        ur: 'آج اپنی دعائیں صرف اللہ سے کریں اور اپنی ضرورت براہِ راست اسی سے مانگیں۔'),
    attribution: _sampleAttribution,
  );

  static const askAllah = Hadith(
    id: 3,
    collectionId: 1,
    numberInBook: 19,
    title: LText(
        ar: 'احفظ الله يحفظك',
        en: 'Be mindful of Allah, He will protect you',
        ur: 'اللہ کو یاد رکھو، وہ تمہاری حفاظت کرے گا'),
    arabic:
        'احْفَظِ اللَّهَ يَحْفَظْكَ، احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ، إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ، وَإِذَا اسْتَعَنْتَ فَاسْتَعِنْ بِاللَّهِ',
    translation:
        '“Be mindful of Allah and He will protect you. Be mindful of Allah and you will find Him before you. '
        'When you ask, ask Allah; and when you seek help, seek help from Allah.”',
    reference: LText(ar: 'جامع الترمذي 2516', en: 'Jami\' at-Tirmidhi 2516', ur: 'جامع ترمذی 2516'),
    fullReference: LText(
        ar: 'الترمذي 2516 · الأربعون النووية 19',
        en: 'Tirmidhi 2516 · Nawawi 40, no. 19',
        ur: 'ترمذی 2516 · اربعین نووی 19'),
    narrator: LText(
        ar: 'عبد الله بن عباس رضي الله عنهما',
        en: 'Abdullah ibn Abbas',
        ur: 'عبد اللہ بن عباس رضی اللہ عنہما'),
    grade: LText(ar: 'حسن صحيح', en: 'Hasan Sahih', ur: 'حسن صحیح'),
    collection: LText(ar: 'الأربعون النووية', en: 'The 40 Hadith of an-Nawawi', ur: 'اربعین نووی'),
    topic: LText(ar: 'التوحيد', en: 'Tawheed', ur: 'توحید'),
    explanation: LText(
      ar: 'يوصي النبي ﷺ ابن عباس بحفظ حدود الله وأوامره، فمن حفظ الله حفظه الله في دينه ودنياه. '
          'ويعلّمه أن يكون سؤاله واستعانته بالله وحده، لأنه وحده القادر على النفع والضر.',
      en: 'The Prophet ﷺ advises Ibn Abbas to guard Allah\'s limits and commands; whoever does so, '
          'Allah protects them in their religion and worldly life. He teaches him to ask and seek help '
          'from Allah alone, since only He can bring benefit or harm.',
    ),
    action: LText(
        ar: 'قبل أن تطلب مساعدة من أحد اليوم، ادعُ الله أولًا.',
        en: 'Before asking anyone for help today, make dua to Allah first.',
        ur: 'آج کسی سے مدد مانگنے سے پہلے اللہ سے دعا کریں۔'),
    attribution: _sampleAttribution,
  );

  /// Opening verse of Kitab at-Tawhid, chapter 1 (an example of kind: ayah).
  static const ayahDhariyat = Hadith(
    id: 1001,
    collectionId: 6,
    chapterId: 1,
    numberInBook: 0,
    kind: HadithKind.ayah,
    dailyOk: false,
    quranRef: '51:56',
    arabic: 'وَمَا خَلَقْتُ الْجِنَّ وَالْإِنسَ إِلَّا لِيَعْبُدُونِ',
    translation: '“And I did not create the jinn and mankind except to worship Me.”',
    reference: LText(ar: 'الذاريات: 56', en: 'Adh-Dhariyat 51:56', ur: 'الذاریات: 56'),
    fullReference: LText(ar: 'الذاريات: 56', en: 'Adh-Dhariyat 51:56', ur: 'الذاریات: 56'),
    narrator: LText(ar: '', en: ''),
    grade: LText(ar: '', en: ''),
    collection: LText(ar: 'كتاب التوحيد', en: 'Kitab at-Tawhid', ur: 'کتاب التوحید'),
    topic: LText(ar: 'التوحيد', en: 'Tawheed', ur: 'توحید'),
    explanation: LText(ar: '', en: ''),
    action: LText(ar: '', en: ''),
    attribution: LText(ar: '', en: ''),
  );

  // hadithOfTheDay is only a fallback (shown when nothing else is loaded).
  static const allHadith = <Hadith>[rightOfAllah, askAllah, ayahDhariyat];

  /// Chapters bundled in the app (the rest download from Supabase).
  static const chapters = <Chapter>[
    Chapter(
        id: 1,
        collectionId: 6,
        number: 1,
        title: LText(ar: 'كتاب التوحيد', en: 'The Book of Tawheed', ur: 'کتاب التوحید')),
    Chapter(
        id: 2,
        collectionId: 6,
        number: 2,
        title: LText(
            ar: 'باب فضل التوحيد وما يكفّر من الذنوب',
            en: 'The virtue of Tawheed and the sins it expiates')),
    Chapter(
        id: 3,
        collectionId: 6,
        number: 3,
        title: LText(
            ar: 'باب من حقّق التوحيد دخل الجنة بغير حساب',
            en: 'Whoever fulfils Tawheed enters Paradise without reckoning')),
    Chapter(
        id: 4,
        collectionId: 6,
        number: 4,
        title: LText(ar: 'باب الخوف من الشرك', en: 'Fear of shirk')),
    Chapter(
        id: 5,
        collectionId: 6,
        number: 5,
        title: LText(
            ar: 'باب الدعاء إلى شهادة أن لا إله إلا الله',
            en: 'Calling to the testimony that there is no god but Allah')),
  ];

  /// Finds a hadith by id (later: a query on the local database).
  static Hadith? findHadith(int id) {
    for (final h in allHadith) {
      if (h.id == id) return h;
    }
    return null;
  }

  static const freeTasbih = <Dhikr>[
    Dhikr(
      arabic: 'سُبْحَانَ اللهِ',
      transliteration: 'Subhan-Allah',
      translation: 'Glory be to Allah.',
      virtue: LText(
        ar: 'يمكنك اختيار الذكر والعدد في إصدار لاحق.',
        en: 'Set your own dhikr and target in a later version.',
      ),
      source: LText(ar: 'تسبيح حر', en: 'Free tasbih', ur: 'آزاد تسبیح'),
      count: 33,
    ),
  ];

  static const collections = <Collection>[
    Collection(
        1,
        'nawawi40',
        'الأربعون',
        LText(ar: 'الأربعون النووية', en: 'The 40 Hadith of an-Nawawi', ur: 'اربعین نووی'),
        LText(
            ar: '42 حديثًا · مناسبة للحفظ',
            en: '42 hadith · Great for memorizing',
            ur: '42 احادیث · حفظ کے لیے بہترین'),
        1),
    Collection(
        3,
        'bukhari',
        'البخاري',
        LText(ar: 'صحيح البخاري', en: 'Sahih al-Bukhari', ur: 'صحیح بخاری'),
        LText(
            ar: 'الكتاب كاملًا · تنزيل اختياري',
            en: 'Full collection · Optional download',
            ur: 'مکمل کتاب · اختیاری ڈاؤن لوڈ'),
        3),
    Collection(
        4,
        'muslim',
        'مسلم',
        LText(ar: 'صحيح مسلم', en: 'Sahih Muslim', ur: 'صحیح مسلم'),
        LText(
            ar: 'الكتاب كاملًا · تنزيل اختياري',
            en: 'Full collection · Optional download',
            ur: 'مکمل کتاب · اختیاری ڈاؤن لوڈ'),
        4),
    Collection(
        5,
        'bulugh',
        'بلوغ المرام',
        LText(ar: 'بلوغ المرام', en: 'Bulugh al-Maram', ur: 'بلوغ المرام'),
        LText(ar: 'أحاديث الأحكام', en: 'Hadith of rulings', ur: 'احکام کی احادیث'),
        5),
    Collection(
        6,
        'kitab-at-tawhid',
        'التوحيد',
        LText(ar: 'كتاب التوحيد', en: 'Kitab at-Tawhid', ur: 'کتاب التوحید'),
        LText(
            ar: 'للشيخ محمد بن عبد الوهاب · 67 بابًا',
            en: 'By Muhammad ibn Abd al-Wahhab · 67 chapters',
            ur: 'شیخ محمد بن عبد الوہاب · 67 ابواب'),
        6),
  ];

  static const topics = <Topic>[
    Topic('التوحيد', LText(ar: 'التوحيد', en: 'Tawheed', ur: 'توحید')),
    Topic('النية', LText(ar: 'النية', en: 'Intention', ur: 'نیت')),
    Topic('الصلاة', LText(ar: 'الصلاة', en: 'Prayer', ur: 'نماز')),
    Topic('الأخلاق', LText(ar: 'الأخلاق', en: 'Character', ur: 'اخلاق')),
    Topic('الوالدين', LText(ar: 'بر الوالدين', en: 'Parents', ur: 'والدین')),
    Topic('الصبر', LText(ar: 'الصبر', en: 'Patience', ur: 'صبر')),
    Topic('الذكر', LText(ar: 'الذكر', en: 'Remembrance', ur: 'ذکر')),
    Topic('الصيام', LText(ar: 'الصيام', en: 'Fasting', ur: 'روزہ')),
  ];

  /// The athkar categories bundled in the app (see athkar_data.dart).
  /// Screens should use ContentStore.instance.athkarCategories, which also
  /// includes newer rows downloaded from Supabase.
  static const athkarCategories = bundledAthkarCategories;

}
