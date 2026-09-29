-- =====================================================================
-- Pantry App · Step 6 · Shopping list: cart ticks and finishing a trip
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================

-- 1. Remember which items are already in the cart.
--    Saved in the database so ticks survive a refresh and sync between
--    two people shopping at the same time.
alter table items add column in_cart boolean not null default false;


-- 2. Extend the step 1 trigger: when an item goes back to 'in', clear its tick.
--    (Otherwise, the next time it runs low, it would show up already ticked.)
--    Because the database enforces this, every screen and the future chat bot get it for free.
create or replace function touch_status_changed_at()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status then
    new.status_changed_at := now();
  end if;
  if new.status = 'in' then
    new.in_cart := false;
  end if;
  return new;
end;
$$;


-- 3. finish_trip: everything ticked goes back to 'in', in ONE transaction.
--    Returns how many items were restocked.
create or replace function finish_trip()
returns integer
language plpgsql
security invoker            -- runs with the signed-in user's permissions (RLS applies)
set search_path = public
as $$
declare
  v_count integer;
begin
  update items
  set status = 'in'          -- the trigger above clears in_cart at the same time
  where in_cart;

  get diagnostics v_count = row_count;   -- how many rows the update changed
  return v_count;
end;
$$;

revoke execute on function finish_trip() from public, anon;
grant  execute on function finish_trip() to authenticated;
