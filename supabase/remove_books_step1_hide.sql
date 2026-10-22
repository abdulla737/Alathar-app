-- =====================================================================
-- Alathar — remove 4 books — STEP 1 of 2: hide them
--   2 = رياض الصالحين · 3 = صحيح البخاري · 4 = صحيح مسلم · 5 = بلوغ المرام
-- Supabase → SQL Editor → New query → Run. Safe to run again
-- (also fine if you already ran the older «remove_riyad_step1» file).
--
-- Marks the books, their chapters and their hadith as deleted. Phones
-- remove them the next time the app opens with internet (the app only
-- downloads changes, so deleting rows straight away would leave them on
-- phones that already have them).
--
-- After the app has been opened once on every test phone, run STEP 2.
-- =====================================================================
begin;

update hadith      set deleted = true, updated_at = now() where collection_id in (2, 3, 4, 5);
update chapters    set deleted = true, updated_at = now() where collection_id in (2, 3, 4, 5);
update collections set deleted = true, updated_at = now() where id in (2, 3, 4, 5);

insert into content_versions (version, notes)
select coalesce(max(version), 0) + 1, 'حذف رياض الصالحين والبخاري ومسلم وبلوغ المرام' from content_versions;

commit;

-- Check: all three should be 0.
select
  (select count(*) from hadith      where collection_id in (2, 3, 4, 5) and not deleted) as hadith_left,
  (select count(*) from chapters    where collection_id in (2, 3, 4, 5) and not deleted) as chapters_left,
  (select count(*) from collections where id in (2, 3, 4, 5) and not deleted)            as books_left;
