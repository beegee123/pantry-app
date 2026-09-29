-- =====================================================================
-- Pantry App · Step 5b · save_item: save an item AND its stores in one go
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================
--
-- Saving an item touches two tables: items and item_stores.
-- A function runs as ONE transaction: if any part fails, nothing is saved
-- (no item left behind with its stores half-updated).
--
-- p_id = null      → create a new item
-- p_id = an id     → update that item
-- Returns the item's id.

create or replace function save_item(
  p_id                 uuid,
  p_name               text,
  p_category           text,
  p_status             item_status,
  p_usual_amount       text,
  p_always_stocked     boolean,
  p_store_ids          uuid[],    -- every store the item can be bought at (may be empty)
  p_preferred_store_id uuid       -- one of p_store_ids, or null
)
returns uuid
language plpgsql
security invoker           -- runs with the signed-in user's permissions, so RLS still applies
set search_path = public
as $$
declare
  v_id        uuid;
  v_store_ids uuid[] := coalesce(p_store_ids, '{}');
begin
  -- The preferred store must be one of the chosen stores.
  if p_preferred_store_id is not null and not (p_preferred_store_id = any (v_store_ids)) then
    raise exception 'The preferred store must be one of the chosen stores.';
  end if;

  if p_id is null then
    insert into items (name, category, status, usual_amount, always_stocked)
    values (
      nullif(trim(p_name), ''),              -- blank name → NULL → rejected by NOT NULL
      p_category,
      coalesce(p_status, 'in'),
      nullif(trim(p_usual_amount), ''),
      coalesce(p_always_stocked, false)
    )
    returning id into v_id;
  else
    update items
    set name           = nullif(trim(p_name), ''),
        category       = p_category,
        status         = coalesce(p_status, status),
        usual_amount   = nullif(trim(p_usual_amount), ''),
        always_stocked = coalesce(p_always_stocked, false)
    where id = p_id
    returning id into v_id;

    if v_id is null then
      raise exception 'That item no longer exists.';
    end if;
  end if;

  -- Replace the item's store links with exactly the chosen ones.
  delete from item_stores where item_id = v_id;

  insert into item_stores (item_id, store_id, is_preferred)
  select v_id, store_id, store_id is not distinct from p_preferred_store_id  -- true only for the preferred one
  from (select distinct unnest(v_store_ids) as store_id) as chosen;

  return v_id;
end;
$$;

-- Only signed-in household members may call it (not anonymous visitors).
revoke execute on function save_item(uuid, text, text, item_status, text, boolean, uuid[], uuid) from public, anon;
grant  execute on function save_item(uuid, text, text, item_status, text, boolean, uuid[], uuid) to authenticated;
