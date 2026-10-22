-- =====================================================================
-- Alathar — remove «رياض الصالحين» — STEP 2 of 2: delete permanently
-- Run only AFTER step 1, and after the app has been opened once with
-- internet on each phone (so phones have already removed the book).
-- Supabase → SQL Editor → New query → Run. This cannot be undone.
-- =====================================================================
begin;

-- Nothing should point at these hadith; clear any link just in case.
update athkar  set hadith_id = null where hadith_id in (select id from hadith where collection_id = 2);
update lessons set hadith_id = null where hadith_id in (select id from hadith where collection_id = 2);

delete from hadith      where collection_id = 2;
delete from chapters    where collection_id = 2;
delete from collections where id = 2;

commit;

-- Check: all three should be 0.
select
  (select count(*) from hadith      where collection_id = 2) as hadith_left,
  (select count(*) from chapters    where collection_id = 2) as chapters_left,
  (select count(*) from collections where id = 2)            as book_left;
