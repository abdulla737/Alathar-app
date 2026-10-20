import 'sample_data.dart';

/// Sunnahs of Friday (سنن يوم الجمعة): authentic hadith shown on the Today
/// page every Friday and on their own page. Ids 90001+ (bundled only).
///
/// Wording follows the cited collections; please have it reviewed before
/// release like the other content.

const _collection = LText(ar: 'سنن يوم الجمعة', en: 'Sunnahs of Friday', ur: 'جمعہ کی سنتیں');
const _topic = LText(ar: 'الجمعة', en: 'Friday', ur: 'جمعہ');
const _agreed = LText(ar: 'متفق عليه', en: 'Agreed upon', ur: 'متفق علیہ');
const _sahih = LText(ar: 'صحيح', en: 'Sahih', ur: 'صحیح');
const _none = LText(ar: '', en: '');
const _attribution = LText(
  ar: 'مختارات تطبيق الأثر من الأحاديث الصحيحة في سنن يوم الجمعة.',
  en: 'Alathar selection of authentic hadith on the sunnahs of Friday.',
  ur: 'جمعہ کی سنتوں پر صحیح احادیث کا الاثر انتخاب۔',
);

const fridayHadith = <Hadith>[
  Hadith(
    id: 90001,
    collectionId: 9,
    numberInBook: 1,
    dailyOk: false,
    title: LText(ar: 'فضل يوم الجمعة', en: 'The virtue of Friday', ur: 'جمعہ کی فضیلت'),
    arabic:
        'خَيْرُ يَوْمٍ طَلَعَتْ عَلَيْهِ الشَّمْسُ يَوْمُ الْجُمُعَةِ، فِيهِ خُلِقَ آدَمُ، وَفِيهِ أُدْخِلَ الْجَنَّةَ، وَفِيهِ أُخْرِجَ مِنْهَا، وَلَا تَقُومُ السَّاعَةُ إِلَّا فِي يَوْمِ الْجُمُعَةِ',
    translation:
        'The best day on which the sun has risen is Friday. On it Adam was created, on it he was admitted into Paradise, on it he was expelled from it, and the Hour will only be established on a Friday.',
    reference: LText(ar: 'صحيح مسلم', en: 'Sahih Muslim', ur: 'صحیح مسلم'),
    fullReference: LText(ar: 'صحيح مسلم (854)', en: 'Sahih Muslim 854', ur: 'صحیح مسلم (854)'),
    narrator: LText(ar: 'أبو هريرة رضي الله عنه', en: 'Abu Hurayrah', ur: 'ابو ہریرہ رضی اللہ عنہ'),
    grade: _sahih,
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'استقبل الجمعة بنيّة أن تجعلها أفضل أيام أسبوعك عبادةً.',
        en: 'Welcome Friday intending to make it the best day of your week in worship.',
        ur: 'جمعہ کو اس نیت سے شروع کریں کہ یہ عبادت میں ہفتے کا بہترین دن ہو۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90002,
    collectionId: 9,
    numberInBook: 2,
    dailyOk: false,
    title: LText(
        ar: 'الإكثار من الصلاة على النبي ﷺ',
        en: 'Sending abundant salawat on the Prophet ﷺ',
        ur: 'نبی ﷺ پر کثرت سے درود'),
    arabic:
        'إِنَّ مِنْ أَفْضَلِ أَيَّامِكُمْ يَوْمَ الْجُمُعَةِ، فِيهِ خُلِقَ آدَمُ، وَفِيهِ قُبِضَ، وَفِيهِ النَّفْخَةُ، وَفِيهِ الصَّعْقَةُ، فَأَكْثِرُوا عَلَيَّ مِنَ الصَّلَاةِ فِيهِ، فَإِنَّ صَلَاتَكُمْ مَعْرُوضَةٌ عَلَيَّ',
    translation:
        'Among the best of your days is Friday. On it Adam was created and on it he died; on it the Trumpet will be blown and on it all will swoon. So send abundant salawat upon me on it, for your salawat are presented to me.',
    reference: LText(ar: 'سنن أبي داود', en: 'Sunan Abi Dawud', ur: 'سنن ابی داود'),
    fullReference: LText(
        ar: 'سنن أبي داود (1047)، والنسائي (1374)، وابن ماجه (1085)',
        en: 'Abu Dawud 1047, an-Nasa\'i 1374, Ibn Majah 1085',
        ur: 'سنن ابی داود (1047)، نسائی (1374)، ابن ماجہ (1085)'),
    narrator: LText(ar: 'أوس بن أوس رضي الله عنه', en: 'Aws ibn Aws', ur: 'اوس بن اوس رضی اللہ عنہ'),
    grade: LText(ar: 'صحيح (الألباني)', en: 'Sahih (al-Albani)', ur: 'صحیح (البانی)'),
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'أكثر اليوم من قول: اللهم صلِّ وسلم على نبينا محمد.',
        en: 'Today, say often: O Allah, send blessings and peace upon our Prophet Muhammad.',
        ur: 'آج کثرت سے کہیں: اللهم صلِّ وسلم على نبينا محمد۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90003,
    collectionId: 9,
    numberInBook: 3,
    dailyOk: false,
    title: LText(ar: 'قراءة سورة الكهف', en: 'Reciting Surah al-Kahf', ur: 'سورۃ الکہف کی تلاوت'),
    arabic:
        'مَنْ قَرَأَ سُورَةَ الْكَهْفِ فِي يَوْمِ الْجُمُعَةِ أَضَاءَ لَهُ مِنَ النُّورِ مَا بَيْنَ الْجُمُعَتَيْنِ',
    translation:
        'Whoever recites Surah al-Kahf on Friday, light will shine for him between the two Fridays.',
    reference: LText(ar: 'المستدرك للحاكم', en: 'Al-Mustadrak (al-Hakim)', ur: 'مستدرک حاکم'),
    fullReference: LText(
        ar: 'الحاكم (3392)، والبيهقي في السنن الكبرى (3/249)، وصححه الألباني في صحيح الجامع (6470)',
        en: 'Al-Hakim 3392, al-Bayhaqi (Sunan al-Kubra 3/249); graded sahih by al-Albani (Sahih al-Jami 6470)',
        ur: 'حاکم (3392)، بیہقی (السنن الکبریٰ 3/249)؛ البانی نے صحیح الجامع (6470) میں صحیح کہا'),
    narrator: LText(ar: 'أبو سعيد الخدري رضي الله عنه', en: 'Abu Sa\'id al-Khudri', ur: 'ابو سعید خدری رضی اللہ عنہ'),
    grade: LText(ar: 'صحيح (الألباني)', en: 'Sahih (al-Albani)', ur: 'صحیح (البانی)'),
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'اقرأ سورة الكهف اليوم، ولو على مراحل بين الصلوات.',
        en: 'Read Surah al-Kahf today, even in parts between the prayers.',
        ur: 'آج سورۃ الکہف پڑھیں، چاہے نمازوں کے درمیان حصوں میں۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90004,
    collectionId: 9,
    numberInBook: 4,
    dailyOk: false,
    title: LText(ar: 'الاغتسال للجمعة', en: 'Ghusl for Friday', ur: 'جمعہ کا غسل'),
    arabic: 'إِذَا جَاءَ أَحَدُكُمُ الْجُمُعَةَ فَلْيَغْتَسِلْ',
    translation: 'When one of you comes to the Friday prayer, let him take a bath (ghusl).',
    reference: LText(ar: 'متفق عليه', en: 'Bukhari and Muslim', ur: 'بخاری و مسلم'),
    fullReference: LText(
        ar: 'صحيح البخاري (877)، وصحيح مسلم (844)',
        en: 'Sahih al-Bukhari 877, Sahih Muslim 844',
        ur: 'صحیح بخاری (877)، صحیح مسلم (844)'),
    narrator: LText(ar: 'عبد الله بن عمر رضي الله عنهما', en: 'Abdullah ibn Umar', ur: 'عبداللہ بن عمر رضی اللہ عنہما'),
    grade: _agreed,
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'اغتسل قبل الذهاب إلى صلاة الجمعة.',
        en: 'Take a ghusl before going to the Friday prayer.',
        ur: 'جمعہ کی نماز کے لیے جانے سے پہلے غسل کریں۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90005,
    collectionId: 9,
    numberInBook: 5,
    dailyOk: false,
    title: LText(ar: 'السواك والطيب', en: 'Siwak and perfume', ur: 'مسواک اور خوشبو'),
    arabic:
        'الْغُسْلُ يَوْمَ الْجُمُعَةِ وَاجِبٌ عَلَى كُلِّ مُحْتَلِمٍ، وَأَنْ يَسْتَنَّ، وَأَنْ يَمَسَّ طِيبًا إِنْ وَجَدَ',
    translation:
        'Ghusl on Friday is obligatory for every adult, and that he uses the siwak and puts on perfume if he finds any.',
    reference: LText(ar: 'متفق عليه', en: 'Bukhari and Muslim', ur: 'بخاری و مسلم'),
    fullReference: LText(
        ar: 'صحيح البخاري (880)، وصحيح مسلم (846)',
        en: 'Sahih al-Bukhari 880, Sahih Muslim 846',
        ur: 'صحیح بخاری (880)، صحیح مسلم (846)'),
    narrator: LText(ar: 'أبو سعيد الخدري رضي الله عنه', en: 'Abu Sa\'id al-Khudri', ur: 'ابو سعید خدری رضی اللہ عنہ'),
    grade: _agreed,
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'استعمل السواك وتطيّب قبل الخروج إلى المسجد.',
        en: 'Use the siwak and wear perfume before leaving for the mosque.',
        ur: 'مسجد جانے سے پہلے مسواک کریں اور خوشبو لگائیں۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90006,
    collectionId: 9,
    numberInBook: 6,
    dailyOk: false,
    title: LText(ar: 'التبكير إلى الجمعة', en: 'Going early to the Friday prayer', ur: 'جمعہ کے لیے جلدی جانا'),
    arabic:
        'مَنِ اغْتَسَلَ يَوْمَ الْجُمُعَةِ غُسْلَ الْجَنَابَةِ ثُمَّ رَاحَ فَكَأَنَّمَا قَرَّبَ بَدَنَةً، وَمَنْ رَاحَ فِي السَّاعَةِ الثَّانِيَةِ فَكَأَنَّمَا قَرَّبَ بَقَرَةً، وَمَنْ رَاحَ فِي السَّاعَةِ الثَّالِثَةِ فَكَأَنَّمَا قَرَّبَ كَبْشًا أَقْرَنَ، وَمَنْ رَاحَ فِي السَّاعَةِ الرَّابِعَةِ فَكَأَنَّمَا قَرَّبَ دَجَاجَةً، وَمَنْ رَاحَ فِي السَّاعَةِ الْخَامِسَةِ فَكَأَنَّمَا قَرَّبَ بَيْضَةً، فَإِذَا خَرَجَ الْإِمَامُ حَضَرَتِ الْمَلَائِكَةُ يَسْتَمِعُونَ الذِّكْرَ',
    translation:
        'Whoever takes a bath on Friday like the bath for janabah and then goes (to the mosque) in the first hour, it is as if he offered a camel; in the second hour, a cow; in the third hour, a horned ram; in the fourth hour, a hen; in the fifth hour, an egg. When the imam comes out, the angels attend to listen to the reminder.',
    reference: LText(ar: 'متفق عليه', en: 'Bukhari and Muslim', ur: 'بخاری و مسلم'),
    fullReference: LText(
        ar: 'صحيح البخاري (881)، وصحيح مسلم (850)',
        en: 'Sahih al-Bukhari 881, Sahih Muslim 850',
        ur: 'صحیح بخاری (881)، صحیح مسلم (850)'),
    narrator: LText(ar: 'أبو هريرة رضي الله عنه', en: 'Abu Hurayrah', ur: 'ابو ہریرہ رضی اللہ عنہ'),
    grade: _agreed,
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'اخرج إلى الجمعة اليوم أبكر من عادتك.',
        en: 'Leave for the Friday prayer earlier than usual today.',
        ur: 'آج جمعہ کے لیے معمول سے پہلے نکلیں۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90007,
    collectionId: 9,
    numberInBook: 7,
    dailyOk: false,
    title: LText(ar: 'آداب الخروج إلى الجمعة', en: 'Manners of attending Friday', ur: 'جمعہ کے آداب'),
    arabic:
        'لَا يَغْتَسِلُ رَجُلٌ يَوْمَ الْجُمُعَةِ، وَيَتَطَهَّرُ مَا اسْتَطَاعَ مِنْ طُهْرٍ، وَيَدَّهِنُ مِنْ دُهْنِهِ، أَوْ يَمَسُّ مِنْ طِيبِ بَيْتِهِ، ثُمَّ يَخْرُجُ فَلَا يُفَرِّقُ بَيْنَ اثْنَيْنِ، ثُمَّ يُصَلِّي مَا كُتِبَ لَهُ، ثُمَّ يُنْصِتُ إِذَا تَكَلَّمَ الْإِمَامُ، إِلَّا غُفِرَ لَهُ مَا بَيْنَهُ وَبَيْنَ الْجُمُعَةِ الْأُخْرَى',
    translation:
        'No man takes a bath on Friday, purifies himself as much as he can, oils his hair or puts on perfume from his house, then goes out and does not separate two people (sitting together), then prays what is written for him and listens quietly when the imam speaks, except that his sins between that Friday and the next are forgiven.',
    reference: LText(ar: 'صحيح البخاري', en: 'Sahih al-Bukhari', ur: 'صحیح بخاری'),
    fullReference: LText(ar: 'صحيح البخاري (883)', en: 'Sahih al-Bukhari 883', ur: 'صحیح بخاری (883)'),
    narrator: LText(ar: 'سلمان الفارسي رضي الله عنه', en: 'Salman al-Farisi', ur: 'سلمان فارسی رضی اللہ عنہ'),
    grade: _sahih,
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'لا تتخطَّ الرقاب، وصلِّ ما تيسّر قبل الخطبة.',
        en: 'Don\'t step over people; pray what you can before the khutbah.',
        ur: 'لوگوں کی گردنیں نہ پھلانگیں، اور خطبے سے پہلے جتنا ہو سکے نماز پڑھیں۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90008,
    collectionId: 9,
    numberInBook: 8,
    dailyOk: false,
    title: LText(ar: 'الإنصات للخطبة', en: 'Listening to the khutbah', ur: 'خطبہ خاموشی سے سننا'),
    arabic: 'إِذَا قُلْتَ لِصَاحِبِكَ يَوْمَ الْجُمُعَةِ: أَنْصِتْ، وَالْإِمَامُ يَخْطُبُ، فَقَدْ لَغَوْتَ',
    translation:
        'If you say to your companion on Friday “Be quiet” while the imam is delivering the khutbah, you have spoken idly.',
    reference: LText(ar: 'متفق عليه', en: 'Bukhari and Muslim', ur: 'بخاری و مسلم'),
    fullReference: LText(
        ar: 'صحيح البخاري (934)، وصحيح مسلم (851)',
        en: 'Sahih al-Bukhari 934, Sahih Muslim 851',
        ur: 'صحیح بخاری (934)، صحیح مسلم (851)'),
    narrator: LText(ar: 'أبو هريرة رضي الله عنه', en: 'Abu Hurayrah', ur: 'ابو ہریرہ رضی اللہ عنہ'),
    grade: _agreed,
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'أغلق هاتفك وأنصت للخطبة من أولها إلى آخرها.',
        en: 'Silence your phone and listen to the whole khutbah.',
        ur: 'فون بند کریں اور پورا خطبہ خاموشی سے سنیں۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90009,
    collectionId: 9,
    numberInBook: 9,
    dailyOk: false,
    title: LText(ar: 'ساعة الإجابة', en: 'The hour of response', ur: 'قبولیت کی گھڑی'),
    arabic:
        'فِيهِ سَاعَةٌ لَا يُوَافِقُهَا عَبْدٌ مُسْلِمٌ وَهُوَ قَائِمٌ يُصَلِّي يَسْأَلُ اللَّهَ تَعَالَى شَيْئًا إِلَّا أَعْطَاهُ إِيَّاهُ',
    translation:
        'In it (Friday) there is an hour: no Muslim servant happens upon it while standing in prayer, asking Allah the Exalted for something, except that He gives it to him.',
    reference: LText(ar: 'متفق عليه', en: 'Bukhari and Muslim', ur: 'بخاری و مسلم'),
    fullReference: LText(
        ar: 'صحيح البخاري (935)، وصحيح مسلم (852)',
        en: 'Sahih al-Bukhari 935, Sahih Muslim 852',
        ur: 'صحیح بخاری (935)، صحیح مسلم (852)'),
    narrator: LText(ar: 'أبو هريرة رضي الله عنه', en: 'Abu Hurayrah', ur: 'ابو ہریرہ رضی اللہ عنہ'),
    grade: _agreed,
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'خصّص وقتًا اليوم للدعاء وسؤال الله حاجاتك.',
        en: 'Set aside time today for du\'a and ask Allah for your needs.',
        ur: 'آج دعا کے لیے وقت نکالیں اور اللہ سے اپنی حاجتیں مانگیں۔'),
    attribution: _attribution,
  ),
  Hadith(
    id: 90010,
    collectionId: 9,
    numberInBook: 10,
    dailyOk: false,
    title: LText(ar: 'آخر ساعة بعد العصر', en: 'The last hour after Asr', ur: 'عصر کے بعد آخری گھڑی'),
    arabic:
        'يَوْمُ الْجُمُعَةِ ثِنْتَا عَشْرَةَ سَاعَةً، لَا يُوجَدُ فِيهَا عَبْدٌ مُسْلِمٌ يَسْأَلُ اللَّهَ شَيْئًا إِلَّا آتَاهُ إِيَّاهُ، فَالْتَمِسُوهَا آخِرَ سَاعَةٍ بَعْدَ الْعَصْرِ',
    translation:
        'Friday is twelve hours; there is no Muslim servant who asks Allah for something in it except that He gives it to him. So seek it in the last hour after Asr.',
    reference: LText(ar: 'سنن أبي داود', en: 'Sunan Abi Dawud', ur: 'سنن ابی داود'),
    fullReference: LText(
        ar: 'سنن أبي داود (1048)، والنسائي (1389)، وصححه الألباني',
        en: 'Abu Dawud 1048, an-Nasa\'i 1389; graded sahih by al-Albani',
        ur: 'سنن ابی داود (1048)، نسائی (1389)؛ البانی نے صحیح کہا'),
    narrator: LText(ar: 'جابر بن عبد الله رضي الله عنهما', en: 'Jabir ibn Abdullah', ur: 'جابر بن عبداللہ رضی اللہ عنہما'),
    grade: LText(ar: 'صحيح (الألباني)', en: 'Sahih (al-Albani)', ur: 'صحیح (البانی)'),
    collection: _collection,
    topic: _topic,
    explanation: _none,
    action: LText(
        ar: 'اجلس قبل المغرب في ذكر ودعاء.',
        en: 'Sit in dhikr and du\'a in the hour before Maghrib.',
        ur: 'مغرب سے پہلے ذکر اور دعا میں بیٹھیں۔'),
    attribution: _attribution,
  ),
];

/// The hadith featured on the Today card: a different one each Friday.
Hadith fridayHadithFor(DateTime day) {
  final week = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/
      (7 * 24 * 3600 * 1000);
  return fridayHadith[week % fridayHadith.length];
}

/// Friday in the phone's time. Set [previewFridayEveryDay] to true to see the
/// Friday card on any day while testing.
const previewFridayEveryDay = false;
bool isFriday(DateTime t) => previewFridayEveryDay || t.weekday == DateTime.friday;
