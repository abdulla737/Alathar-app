-- =====================================================================
-- Alathar — remove 4 books — STEP 2 of 2: delete permanently
--   2 = رياض الصالحين · 3 = صحيح البخاري · 4 = صحيح مسلم · 5 = بلوغ المرام
-- Run only AFTER step 1, and after the app has been opened once with
-- internet on each phone. This cannot be undone.
-- =====================================================================
begin;

-- Nothing should point at these hadith; clear any link just in case.
update athkar  set hadith_id = null where hadith_id in (select id from hadith where collection_id in (2, 3, 4, 5));
update lessons set hadith_id = null where hadith_id in (select id from hadith where collection_id in (2, 3, 4, 5));

delete from hadith      where collection_id in (2, 3, 4, 5);
delete from chapters    where collection_id in (2, 3, 4, 5);
delete from collections where id in (2, 3, 4, 5);

commit;

-- Check: all three should be 0.
select
  (select count(*) from hadith      where collection_id in (2, 3, 4, 5)) as hadith_left,
  (select count(*) from chapters    where collection_id in (2, 3, 4, 5)) as chapters_left,
  (select count(*) from collections where id in (2, 3, 4, 5))            as books_left;
