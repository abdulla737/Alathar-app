-- =====================================================================
-- Alathar — remove «رياض الصالحين» — STEP 1 of 2: hide it
-- Supabase → SQL Editor → New query → Run. Safe to run again.
--
-- Marks the book, its 20 chapters and all its hadith as deleted. Phones
-- remove them the next time the app opens (it only downloads changes, so
-- deleting rows straight away would leave them on phones that already
-- have them).
--
-- After you have opened the app once with internet (on every test phone),
-- run STEP 2 to delete the rows permanently.
-- =====================================================================
begin;

update hadith      set deleted = true, updated_at = now() where collection_id = 2;
update chapters    set deleted = true, updated_at = now() where collection_id = 2;
update collections set deleted = true, updated_at = now() where id = 2;

insert into content_versions (version, notes)
select coalesce(max(version), 0) + 1, 'حذف رياض الصالحين' from content_versions;

commit;

-- Check: all three should be 0.
select
  (select count(*) from hadith      where collection_id = 2 and not deleted) as hadith_left,
  (select count(*) from chapters    where collection_id = 2 and not deleted) as chapters_left,
  (select count(*) from collections where id = 2 and not deleted)            as book_left;
