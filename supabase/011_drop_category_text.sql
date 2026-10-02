-- =====================================================================
-- Pantry App · Step 8d-3 · Retire the old category text
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- Run it AFTER the new app version is live on Vercel (see the step notes).
-- =====================================================================
--
-- Step 8d-1 added items.category_id (a link to the categories table) but kept the old
-- items.category text, with triggers keeping the two in step. That was the "expand"
-- half of the change. This is the "contract" half: everything now saves the link,
-- so the text and its triggers go.


-- 1. save_item takes a category ID instead of a name.
--    (A function's argument list is part of its identity, so the old one is dropped
--    and a new one created, rather than "create or replace".)
drop function save_item(uuid, text, text, item_status, text, boolean, uuid[], uuid);

create function save_item(
  p_id                 uuid,
  p_name               text,
  p_category_id        uuid,       -- was p_category text
  p_status             item_status,
  p_usual_amount       text,
  p_always_stocked     boolean,
  p_store_ids          uuid[],
  p_preferred_store_id uuid
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_id          uuid;
  v_store_ids   uuid[] := coalesce(p_store_ids, '{}');
  -- No category sent → the first one in your list (never creates a new category).
  v_category_id uuid   := coalesce(p_category_id, (select id from categories order by position limit 1));
begin
  if p_preferred_store_id is not null and not (p_preferred_store_id = any (v_store_ids)) then
    raise exception 'The preferred store must be one of the chosen stores.';
  end if;

  if p_id is null then
    insert into items (name, category_id, status, usual_amount, always_stocked)
    values (
      nullif(trim(p_name), ''),
      v_category_id,
      coalesce(p_status, 'in'),
      nullif(trim(p_usual_amount), ''),
      coalesce(p_always_stocked, false)
    )
    returning id into v_id;
  else
    update items
    set name           = nullif(trim(p_name), ''),
        category_id    = v_category_id,
        status         = coalesce(p_status, status),
        usual_amount   = nullif(trim(p_usual_amount), ''),
        always_stocked = coalesce(p_always_stocked, false)
    where id = p_id
    returning id into v_id;

    if v_id is null then
      raise exception 'That item no longer exists.';
    end if;
  end if;

  delete from item_stores where item_id = v_id;

  insert into item_stores (item_id, store_id, is_preferred)
  select v_id, store_id, store_id is not distinct from p_preferred_store_id
  from (select distinct unnest(v_store_ids) as store_id) as chosen;

  return v_id;
end;
$$;

revoke execute on function save_item(uuid, text, uuid, item_status, text, boolean, uuid[], uuid) from public, anon;
grant  execute on function save_item(uuid, text, uuid, item_status, text, boolean, uuid[], uuid) to authenticated;


-- 2. The triggers that kept the text in step (from 009_categories.sql).
drop trigger items_sync_category on items;
drop function sync_item_category();
drop trigger categories_rename_items on categories;
drop function rename_category_on_items();


-- 3. The old text column itself.
alter table items drop column category;

-- category_id_for(name) stays: recipe import scripts use it to find (or create) a category by name.
