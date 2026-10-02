-- =====================================================================
-- Pantry App · Step 8d-1 · Categories become a table
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================
--
-- Before: each item stored its category as text ("Produce"), and the list of
-- categories lived in the app's code (src/lib/categories.js).
-- After:  a categories table (name + display order), and each item LINKS to one
-- via items.category_id — like an item's stores, or a lookup field in Salesforce.
--
-- items.category (the text) stays for now, kept in step automatically by a trigger.
-- That way the app version that's live right now, save_item and the recipe import
-- scripts all keep working while you deploy. It can be dropped later.


-- 1. CATEGORIES
create table categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null unique,
  position    integer not null,        -- display order on the Kitchen: 1 first
  created_at  timestamptz not null default now()
);

alter table categories enable row level security;
create policy "household can do everything" on categories
  for all to authenticated using (true) with check (true);

alter publication supabase_realtime add table categories;


-- 2. Fill it: the app's current list in its current order, then any other
--    category an item already uses (A–Z), so nothing is lost.
insert into categories (name, position)
select name, position
from unnest(array['Dairy & eggs', 'Produce', 'Meat & fish', 'Pantry', 'Frozen', 'Household', 'Hygiene'])
     with ordinality as known(name, position);

insert into categories (name, position)
select name, 7 + row_number() over (order by name)
from (select distinct category as name from items) as used
where name not in (select name from categories);


-- 3. Link every item to its category.
alter table items add column category_id uuid references categories(id) on delete restrict;
-- on delete restrict: a category that items still use can't be deleted (8d-2 will offer to move them).

update items i
set category_id = c.id
from categories c
where c.name = i.category;

alter table items alter column category_id set not null;  -- every item has a category from now on
create index items_category_idx on items (category_id);


-- 4. Find a category by name (ignoring capitals), creating it at the end if it's new.
create or replace function category_id_for(p_name text)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_id   uuid;
  v_name text := coalesce(nullif(trim(p_name), ''), 'Pantry');
begin
  select id into v_id from categories where lower(name) = lower(v_name);
  if v_id is null then
    insert into categories (name, position)
    values (v_name, coalesce((select max(position) from categories), 0) + 1)
    returning id into v_id;
  end if;
  return v_id;
end;
$$;


-- 5. Keep items.category (text) and items.category_id (link) in step, whichever one a save sets.
--    Old app / save_item / import scripts send the NAME  → we look up (or create) the id.
--    Later app versions send the ID                     → we copy the name across.
create or replace function sync_item_category()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    if new.category_id is null then
      new.category_id := category_id_for(new.category);
    end if;
  elsif new.category is distinct from old.category
        and new.category_id is not distinct from old.category_id then
    new.category_id := category_id_for(new.category);   -- only the name changed
  end if;

  select name into new.category from categories where id = new.category_id;
  return new;
end;
$$;

create trigger items_sync_category
before insert or update of category, category_id on items
for each row execute function sync_item_category();


-- 6. Renaming a category renames it on its items too (needed while the text column exists).
create or replace function rename_category_on_items()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  update items set category = new.name where category_id = new.id;
  return null;
end;
$$;

create trigger categories_rename_items
after update of name on categories
for each row
when (new.name is distinct from old.name)
execute function rename_category_on_items();
