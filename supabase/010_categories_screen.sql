-- =====================================================================
-- Pantry App · Step 8d-2 · Categories screen
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================
-- Two actions on the Categories screen change several rows at once, so each is a
-- function = one transaction: either all of it happens, or none of it.


-- 1. Reorder: the screen sends every category id in the new order;
--    each gets position 1, 2, 3… in that order.
create or replace function reorder_categories(p_ids uuid[])
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if (select count(*) from categories) <> coalesce(array_length(p_ids, 1), 0) then
    raise exception 'The category list changed on another device. Refresh and try again.';
  end if;

  update categories c
  set position = o.ord
  from unnest(p_ids) with ordinality as o(id, ord)   -- ordinality = the id's place in the list
  where c.id = o.id;
end;
$$;


-- 2. Remove a category. If items still use it, they move to p_move_to first.
--    (Items can't be left without a category: category_id is NOT NULL.)
create or replace function remove_category(p_id uuid, p_move_to uuid)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  if p_move_to = p_id then
    raise exception 'Pick a different category to move the items to.';
  end if;

  if p_move_to is not null then
    update items set category_id = p_move_to where category_id = p_id;
  elsif exists (select 1 from items where category_id = p_id) then
    raise exception 'Some items still use this category. Choose where to move them.';
  end if;

  delete from categories where id = p_id;
  if not found then
    raise exception 'That category no longer exists.';
  end if;
end;
$$;
