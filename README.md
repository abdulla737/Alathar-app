# Alathar (الأثر) – Flutter screens

Arabic is the default language (right-to-left). English and Urdu can be chosen
on the welcome screen or in Settings → App language.

## 1. Add the dependencies
In `pubspec.yaml`, under `dependencies:` add:

```yaml
  flutter_localizations:
    sdk: flutter
  google_fonts: ^6.2.1
  shared_preferences: ^2.3.0
  supabase_flutter: ^2.8.0
  share_plus: ^10.1.4
  just_audio: ^0.9.42
  flutter_tts: ^4.2.2
```

**Android release builds** also need internet permission. In
`android/app/src/main/AndroidManifest.xml`, above `<application`, add:
`<uses-permission android:name="android.permission.INTERNET"/>`
(debug builds already have it).

**Android (for the Arabic voice)** — in `AndroidManifest.xml`, inside
`<manifest>` (next to `<application>`), add:
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.TTS_SERVICE" />
  </intent>
</queries>
```

Then run `flutter pub get`.

## 2. Copy the files
Replace your project's `lib` folder with this `lib` folder:

```
lib/
  main.dart                      app entry (Arabic locale by default, starts at onboarding)
  l10n/strings.dart              all interface text in Arabic, English and Urdu
  theme/app_theme.dart           colors, fonts, theme
  data/sample_data.dart          sample hadith, athkar, lessons (replace with SQLite later)
  data/app_settings.dart         settings saved on the phone (language, Arabic size, reminders)
  data/user_store.dart           favorites + "Act on it today", saved on the phone
  widgets/common.dart            star motif, cards, pills, progress bars
  screens/onboarding_screen.dart
  screens/home_shell.dart        bottom navigation (5 tabs)
  screens/today_screen.dart
  screens/hadith_detail_screen.dart
  screens/library_screen.dart
  screens/athkar_screen.dart
  screens/athkar_counter_screen.dart
  screens/act_screen.dart        «العمل»: today's action, streak, record
  screens/settings_screen.dart
  screens/saved_screen.dart      list of saved hadith (Settings → Saved)
```

## App name on the phone's home screen
The name under the app icon is set outside `lib`. Arabic phones show «الأثر»,
all others show "Alathar".

**Android**
1. In `android/app/src/main/AndroidManifest.xml`, on the `<application` tag set:
   `android:label="@string/app_name"`
2. Create `android/app/src/main/res/values/strings.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <string name="app_name">Alathar</string>
   </resources>
   ```
3. Create `android/app/src/main/res/values-ar/strings.xml`:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources>
       <string name="app_name">الأثر</string>
   </resources>
   ```

**iOS**
1. In `ios/Runner/Info.plist` set:
   ```xml
   <key>CFBundleDisplayName</key>
   <string>Alathar</string>
   <key>CFBundleLocalizations</key>
   <array><string>ar</string><string>en</string><string>ur</string></array>
   ```
2. In Xcode, add a Strings file named `InfoPlist.strings` to Runner, click
   "Localize…" and add Arabic. In the Arabic version write:
   `"CFBundleDisplayName" = "الأثر";`

## Content updates from Supabase
- `lib/config/supabase_config.dart` holds the project URL and publishable key.
- On every launch, if the phone is online, the app checks the latest row in
  `content_versions`. If it is newer than the phone's version, it downloads only
  the hadith rows changed since the last download and saves them on the phone.
- Offline, nothing happens: the app uses what is already on the phone.
- Settings → "Content version" shows the version and hadith count, with a
  "Check" button to look for updates now.
- Hadith of the day: one per day, the same all day and on every phone. It
  goes through all hadith with `daily_ok = true` in a fixed mixed order (the
  books are interleaved), and today's pick is remembered so new downloads
  never change it mid-day. A new one appears after midnight.

**To publish new content**
1. Add or edit rows in the `hadith` table (Table Editor).
2. Add a new row in `content_versions` with the next number (2, 3, …).
3. Phones pick it up on the next launch, or with the "Check" button.

To hide a hadith, set `deleted = true` instead of deleting the row, so
phones that already downloaded it remove it too.

## Books and chapters (e.g. كتاب التوحيد)
- The app downloads three tables: `collections` (books), `chapters` and
  `hadith`. Run `alathar_add_kitab_tawhid.sql` in Supabase first so the
  `chapters` table and the new hadith columns exist. (If it's missing, the app
  skips that table and keeps working.)
- Library → a book: books with chapters show the chapter list; other books
  show their hadith.
- A chapter shows its texts in `number_in_book` order. Each text's `kind`
  decides how it looks: `ayah` (verse in ﴿ ﴾ on a sand card, read in place),
  `hadith` or `athar` (open their own page). The chapter's `masail_ar` shows
  at the end under «المسائل».
- Kitab at-Tawhid (collection 6) and its first 5 chapter titles are also
  bundled in the app, so the book shows even offline before any download.

**Books without chapters (e.g. الأربعون النووية)** list their hadith by
`number_in_book`. When a hadith has a `title_ar` (and `title_en` / `title_ur`),
the book shows a numbered list of titles, and the hadith page shows the title
above the text. Run `alathar_nawawi40.sql` to add the 42 hadith with titles.

**To add a text to a chapter:** add a row in `hadith` with `collection_id` = 6,
`chapter_id`, `number_in_book`, `kind`, the Arabic text and reference, then add
a new `content_versions` row.

## Athkar
- 10 categories: morning, evening, after prayer, before sleep, waking up, home,
  masjid, travel, food, distress — 62 athkar, each with its repeat count,
  virtue and source (texts and grades from HadeethEnc.com).
- They are bundled in `lib/data/athkar_data.dart` (works offline) and also
  downloaded from the Supabase tables `athkar_categories` and `athkar`
  (run `alathar_athkar.sql`). A downloaded row replaces the bundled one with
  the same id, so you can fix or add athkar without a new app release.
- On the Today page, from 4:00 the morning card glows, and from 15:00 the
  evening card, until the user taps it (tapping opens those athkar) or has
  already finished them today. Approximate times — switch to real Fajr/Asr
  when prayer times are added (`isMorningAthkarTime` / `isEveningAthkarTime`
  in today_screen.dart).
- Finishing every dhikr in a category marks it «تمت» for today (Athkar tab and
  the Today cards). The marks reset each day.
- English/Urdu translations of athkar are empty for now; the Arabic and the
  virtue show in every language until they are added.

## «العمل» tab (Practice)
Replaces the old sample Tawheed-path tab (Kitab at-Tawhid is in the Library).
- Shows the hadith of the day with one short practical action (`action_ar`),
  and a «عملتُ به اليوم» button. The hadith page has the same tick.
- Streak (days in a row), days of practice, number of hadith acted on, the last
  7 days, and the record of every hadith acted on (tap to open it). Saved on
  the phone (`acted_history` in shared_preferences), no account.
- The Today page shows today's action and the streak; tapping opens the tab.
- Run `alathar_actions.sql`: it adds an action to each of the 137 hadith in the
  daily rotation and leaves out partial narrations that don't suit a daily
  action. The actions are written for the app from each hadith — have them
  reviewed; edit `action_ar` in the Table Editor and add a `content_versions` row.

## Audio (🔊)
Every 🔊 button (hadith page, Today card, verses in book chapters, athkar
counter) uses one player (`lib/data/audio_service.dart`), in this order:
1. **Own recording** — if the row has `audio_url`, that file plays.
2. **Qur'an** — rows with `quran_ref` (e.g. `2:255`, `9:128-129`,
   `112:1-4|113:1-5|114:1-6`) play Sheikh Mahmoud Khalil al-Husary's
   verse-by-verse recitation from EveryAyah.com (basmala added before a surah
   recited from its start). Saved on the phone after the first listen, so it
   works offline. Reciter folder: `lib/config/audio_config.dart`.
   Qur'an text is never read by the phone voice.
3. **Phone's Arabic voice** (`flutter_tts`) for hadith and athkar until
   recordings are added. If the phone has no Arabic voice, the app says how to
   add it.
- In the athkar counter, when a dhikr finishes playing it counts one
  repetition.
- Run `alathar_audio.sql` (adds `quran_ref` and `audio_url`, and fills
  `quran_ref` for all 84 verse references and the Qur'an athkar).

**Adding your own recordings (best quality for hadith and athkar)**
1. Supabase → Storage → New bucket `audio`, set it **Public**.
2. Upload MP3/M4A files, e.g. `athkar/101.mp3`, `hadith/10001.mp3`.
3. Copy each file's public URL into `audio_url` of that row (Table Editor),
   then add a `content_versions` row. Phones use it from their next update.

## Sharing a hadith (WhatsApp etc.)
- The share button (hadith page, and the Today card) shows a preview of a
  designed card: hadith text, narrator, source, grade, «الأثر» and the
  download link. «مشاركة» makes it a sharp image (1080 × 1350) and opens the
  phone's share sheet — choose WhatsApp (or any app). The message text holds
  an excerpt and the download link too.
- **Put your store links in `lib/config/app_links.dart`** once the app is
  published (until then the card shows no link).
- On iPhone, WhatsApp keeps the image but may drop the text, which is why the
  link is also printed on the image.
- Very long hadith are cut at about 420 letters on the image, with «اقرأ
  الحديث كاملًا في تطبيق الأثر».

## What is saved on the phone (no account)
- Language (Arabic by default), Arabic text size, translation, reminder switches.
- Whether onboarding was completed, so it shows only on the first launch.
- Saved (favorite) hadith, newest first.
- "Act on it today" ticks, reset each new day.
- Athkar categories completed today, reset each new day.

All of it uses `shared_preferences`, which works on Android, iOS, Windows and
Chrome, so you can test on any target in VS Code. Android Auto Backup and
iCloud backup carry it to a new phone automatically.

To see onboarding again while testing: uninstall the app, or clear its data.

## 3. Run
`flutter run`

Requires Flutter 3.22 or newer (Dart 3).

## How languages work
- `context.tr('key')` returns text from `l10n/strings.dart` in the current language.
- Changing the language rebuilds the app with the new locale, so the layout
  flips between right-to-left and left-to-right automatically.
- In Arabic, translations and transliterations are hidden, because the Arabic
  text is the hadith or dhikr itself. Explanations show in Arabic.
- Fonts: IBM Plex Sans Arabic for the interface in Arabic/Urdu, Figtree in
  English, Amiri for hadith and dhikr text.
- The Urdu text is a first draft. Please have a native speaker review it.

## Notes
- Fonts download on first launch. For full offline use, bundle the font files
  in `assets/google_fonts/` (google_fonts picks them up automatically).
- Dates, prayer times and progress numbers are sample values. Suggested packages:
  `adhan` (prayer times), `hijri` (Hijri date), `sqflite` or `drift` (local database),
  `flutter_local_notifications` (reminders), `share_plus` (share card), `just_audio` (audio).
- Look for `TODO` comments where real data or features plug in.
