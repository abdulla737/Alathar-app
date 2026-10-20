-- =====================================================================
-- Alathar (الأثر) — Supabase schema
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
--
-- Content tables can be READ by anyone using the app (anon key),
-- but only YOU can add or edit content (dashboard or service role).
-- Every table has updated_at + deleted so the app can download
-- only what changed since its last update.
-- =====================================================================

-- ---------- helper: keep updated_at current on every edit -------------
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ---------------------------- collections -----------------------------
create table if not exists collections (
  id          int primary key,
  slug        text unique not null,          -- e.g. 'nawawi40'
  badge_ar    text not null,                 -- short title on the tile
  name_ar     text not null,
  name_en     text,
  name_ur     text,
  meta_ar     text,
  meta_en     text,
  meta_ur     text,
  sort        int not null default 0,
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

-- ------------------------------- topics -------------------------------
create table if not exists topics (
  id          int primary key,
  slug        text unique not null,          -- e.g. 'tawheed'
  name_ar     text not null,
  name_en     text,
  name_ur     text,
  sort        int not null default 0,
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

-- ------------------------------- hadith -------------------------------
create table if not exists hadith (
  id              int primary key,
  collection_id   int references collections(id),
  topic_id        int references topics(id),
  arabic          text not null,             -- the hadith text with tashkeel
  translation_en  text,
  translation_ur  text,
  narrator_ar     text,
  narrator_en     text,
  narrator_ur     text,
  grade_ar        text,                      -- صحيح، حسن …
  grade_en        text,
  grade_ur        text,
  reference_ar    text,                      -- صحيح البخاري 1
  reference_en    text,
  reference_ur    text,
  full_ref_ar     text,                      -- البخاري 1 · مسلم 1907
  full_ref_en     text,
  full_ref_ur     text,
  explanation_ar  text,
  explanation_en  text,
  explanation_ur  text,
  action_ar       text,                      -- "Act on it today"
  action_en       text,
  action_ur       text,
  source          text,                      -- 'hadeethenc', 'sunnah.com' …
  source_ref      text,                      -- id or URL at the source
  daily_ok        boolean not null default true,  -- may appear as hadith of the day
  updated_at      timestamptz not null default now(),
  deleted         boolean not null default false
);
create index if not exists hadith_topic_idx      on hadith(topic_id);
create index if not exists hadith_collection_idx on hadith(collection_id);

-- -------------------------- athkar categories -------------------------
create table if not exists athkar_categories (
  id          int primary key,
  slug        text unique not null,          -- 'morning', 'evening', 'sleep' …
  badge_ar    text not null,
  name_ar     text not null,
  name_en     text,
  name_ur     text,
  sort        int not null default 0,
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

-- ------------------------------- athkar -------------------------------
create table if not exists athkar (
  id               int primary key,
  category_id      int not null references athkar_categories(id),
  sort             int not null default 0,
  arabic           text not null,
  transliteration  text,
  translation_en   text,
  translation_ur   text,
  virtue_ar        text,
  virtue_en        text,
  virtue_ur        text,
  source_ar        text,                     -- صحيح مسلم 2692
  source_en        text,
  repeat_count     int not null default 1,
  hadith_id        int references hadith(id), -- "Why this?" link
  updated_at       timestamptz not null default now(),
  deleted          boolean not null default false
);
create index if not exists athkar_category_idx on athkar(category_id, sort);

-- --------------------------- Tawheed lessons --------------------------
create table if not exists lessons (
  id          int primary key,
  sort        int not null default 0,
  topic_ar    text not null,
  topic_en    text,
  topic_ur    text,
  title_ar    text not null,
  title_en    text,
  title_ur    text,
  hadith_id   int references hadith(id),
  updated_at  timestamptz not null default now(),
  deleted     boolean not null default false
);

-- --------------------- content version (for updates) ------------------
-- Add a row each time you publish new content. The app compares the
-- latest version with the one it has and downloads rows changed since.
create table if not exists content_versions (
  version       int primary key,
  published_at  timestamptz not null default now(),
  notes         text
);

-- --------------------------- triggers --------------------------------
do $$
declare t text;
begin
  foreach t in array array['collections','topics','hadith','athkar_categories','athkar','lessons']
  loop
    execute format('drop trigger if exists %I_updated_at on %I', t, t);
    execute format('create trigger %I_updated_at before update on %I
                    for each row execute function set_updated_at()', t, t);
    execute format('create index if not exists %I_updated_idx on %I(updated_at)', t, t);
  end loop;
end $$;

-- ------------------- security: public read, no public write -----------
do $$
declare t text;
begin
  foreach t in array array['collections','topics','hadith','athkar_categories','athkar','lessons','content_versions']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "public read" on %I', t);
    execute format('create policy "public read" on %I for select to anon, authenticated using (true)', t);
  end loop;
end $$;

-- =====================================================================
-- Sample content (same as the app's sample_data.dart) — safe to re-run
-- =====================================================================
insert into collections (id, slug, badge_ar, name_ar, name_en, name_ur, meta_ar, meta_en, meta_ur, sort) values
 (1,'nawawi40','الأربعون','الأربعون النووية','The 40 Hadith of an-Nawawi','اربعین نووی','42 حديثًا · مناسبة للحفظ','42 hadith · Great for memorizing','42 احادیث · حفظ کے لیے بہترین',1),
 (2,'riyad','رياض الصالحين','رياض الصالحين','Riyad as-Salihin','ریاض الصالحین','الأخلاق والعبادة اليومية','Daily character and worship','روزمرہ اخلاق اور عبادت',2),
 (3,'bukhari','البخاري','صحيح البخاري','Sahih al-Bukhari','صحیح بخاری','الكتاب كاملًا · تنزيل اختياري','Full collection · Optional download','مکمل کتاب · اختیاری ڈاؤن لوڈ',3),
 (4,'muslim','مسلم','صحيح مسلم','Sahih Muslim','صحیح مسلم','الكتاب كاملًا · تنزيل اختياري','Full collection · Optional download','مکمل کتاب · اختیاری ڈاؤن لوڈ',4),
 (5,'bulugh','بلوغ المرام','بلوغ المرام','Bulugh al-Maram','بلوغ المرام','أحاديث الأحكام','Hadith of rulings','احکام کی احادیث',5)
on conflict (id) do nothing;

insert into topics (id, slug, name_ar, name_en, name_ur, sort) values
 (1,'tawheed','التوحيد','Tawheed','توحید',1),
 (2,'intention','النية','Intention','نیت',2),
 (3,'prayer','الصلاة','Prayer','نماز',3),
 (4,'character','الأخلاق','Character','اخلاق',4),
 (5,'parents','بر الوالدين','Parents','والدین',5),
 (6,'patience','الصبر','Patience','صبر',6),
 (7,'dhikr','الذكر','Remembrance','ذکر',7),
 (8,'fasting','الصيام','Fasting','روزہ',8)
on conflict (id) do nothing;

insert into hadith (id, collection_id, topic_id, arabic, translation_en,
  narrator_ar, narrator_en, grade_ar, grade_en, reference_ar, reference_en,
  full_ref_ar, full_ref_en, source) values
 (1, 2, 2,
  'إِنَّمَا الْأَعْمَالُ بِالنِّيَّاتِ، وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى',
  '“Actions are only by intentions, and every person will have only what they intended.”',
  'عمر بن الخطاب رضي الله عنه','Umar ibn al-Khattab','صحيح','Sahih',
  'صحيح البخاري 1','Sahih al-Bukhari 1','البخاري 1 · مسلم 1907','Bukhari 1 · Muslim 1907','sample'),
 (2, 3, 1,
  'حَقُّ اللَّهِ عَلَى الْعِبَادِ أَنْ يَعْبُدُوهُ وَلَا يُشْرِكُوا بِهِ شَيْئًا، وَحَقُّ الْعِبَادِ عَلَى اللَّهِ أَنْ لَا يُعَذِّبَ مَنْ لَا يُشْرِكُ بِهِ شَيْئًا',
  '“The right of Allah over His servants is that they worship Him and associate nothing with Him, and the right of the servants over Allah is that He does not punish whoever associates nothing with Him.”',
  'معاذ بن جبل رضي الله عنه','Mu''adh ibn Jabal','صحيح','Sahih',
  'صحيح البخاري 2856','Sahih al-Bukhari 2856','البخاري 2856 · مسلم 30','Bukhari 2856 · Muslim 30','sample'),
 (3, 1, 1,
  'احْفَظِ اللَّهَ يَحْفَظْكَ، احْفَظِ اللَّهَ تَجِدْهُ تُجَاهَكَ، إِذَا سَأَلْتَ فَاسْأَلِ اللَّهَ، وَإِذَا اسْتَعَنْتَ فَاسْتَعِنْ بِاللَّهِ',
  '“Be mindful of Allah and He will protect you. Be mindful of Allah and you will find Him before you. When you ask, ask Allah; and when you seek help, seek help from Allah.”',
  'عبد الله بن عباس رضي الله عنهما','Abdullah ibn Abbas','حسن صحيح','Hasan Sahih',
  'جامع الترمذي 2516','Jami'' at-Tirmidhi 2516','الترمذي 2516 · الأربعون النووية 19','Tirmidhi 2516 · Nawawi 40, no. 19','sample')
on conflict (id) do nothing;

insert into content_versions (version, notes) values (1, 'Initial sample content')
on conflict (version) do nothing;

-- =====================================================================
-- OPTIONAL — only when you add sign-in for syncing across devices.
-- Each user can see and change only their own rows.
-- =====================================================================
-- create table if not exists user_favorites (
--   user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
--   hadith_id  int  not null references hadith(id),
--   note       text,
--   saved_at   timestamptz not null default now(),
--   primary key (user_id, hadith_id)
-- );
-- alter table user_favorites enable row level security;
-- create policy "own favorites" on user_favorites for all to authenticated
--   using (auth.uid() = user_id) with check (auth.uid() = user_id);
