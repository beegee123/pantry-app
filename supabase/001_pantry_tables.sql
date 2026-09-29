-- =====================================================================
-- Pantry App · Step 1 · Phase 1 tables
-- Run once in Supabase: Dashboard → SQL Editor → New query → paste → Run
-- =====================================================================

-- 1. The three statuses an item can have.
--    An ENUM means the database itself rejects anything else (e.g. 'gone').
create type item_status as enum ('in', 'low', 'out');


-- 2. STORES — where you shop.
create table stores (
  id          uuid primary key default gen_random_uuid(),  -- unique id, generated for you
  name        text not null unique,                        -- no two stores with the same name
  created_at  timestamptz not null default now()
);


-- 3. ITEMS — everything you keep in the kitchen.
create table items (
  id                 uuid primary key default gen_random_uuid(),
  name               text not null unique,                 -- "Rice, 8 kg"
  category           text not null default 'Pantry',       -- Dairy & eggs, Pantry, Produce, Frozen, Household
  status             item_status not null default 'in',
  usual_amount       text,                                 -- "1 bag" — display text only, no maths
  always_stocked     boolean not null default false,       -- nudge me when it goes low
  status_changed_at  timestamptz not null default now(),   -- when status last changed
  created_at         timestamptz not null default now()
);


-- 4. ITEM_STORES — the linking table (many-to-many).
--    One row = "this item can be bought at this store".
--    Same idea as a junction object in Salesforce.
create table item_stores (
  item_id       uuid not null references items(id)  on delete cascade,  -- delete an item → its links go too
  store_id      uuid not null references stores(id) on delete cascade,
  is_preferred  boolean not null default false,
  primary key (item_id, store_id)                    -- can't link the same item to the same store twice
);

-- At most ONE preferred store per item.
-- A "partial unique index": uniqueness only applies to rows where is_preferred is true.
create unique index one_preferred_store_per_item
  on item_stores (item_id)
  where is_preferred;


-- 5. Keep status_changed_at up to date automatically.
--    A trigger runs this function before every update to items.
create function touch_status_changed_at()
returns trigger
language plpgsql
as $$
begin
  if new.status is distinct from old.status then
    new.status_changed_at := now();
  end if;
  return new;
end;
$$;

create trigger items_status_changed
  before update on items
  for each row
  execute function touch_status_changed_at();


-- 6. Security (Row Level Security).
--    Supabase exposes every table through a web API, so we lock them down:
--    only signed-in household members can read or change anything.
--    (We add the sign-in screen in step 4.)
alter table stores      enable row level security;
alter table items       enable row level security;
alter table item_stores enable row level security;

create policy "household can do everything" on stores
  for all to authenticated using (true) with check (true);
create policy "household can do everything" on items
  for all to authenticated using (true) with check (true);
create policy "household can do everything" on item_stores
  for all to authenticated using (true) with check (true);


-- 7. Starter data — the examples from the wireframe. Edit freely.
insert into stores (name) values ('Costco'), ('No Frills'), ('Walmart');

insert into items (name, category, status, usual_amount) values
  ('Eggs',          'Dairy & eggs', 'out', '1 dozen'),
  ('Milk',          'Dairy & eggs', 'low', '4 L'),
  ('Rice, 8 kg',    'Pantry',       'out', '1 bag'),
  ('Tomato paste',  'Pantry',       'out', '3 cans'),
  ('Olive oil',     'Pantry',       'in',  '1 bottle'),
  ('Toilet paper',  'Household',    'low', '1 pack of 30');

-- Link items to stores. (Eggs and Milk get no store → they show under "Any store".)
insert into item_stores (item_id, store_id, is_preferred)
select i.id, s.id, x.preferred
from (values
  ('Rice, 8 kg',   'Costco',    true),
  ('Tomato paste', 'No Frills', true),
  ('Olive oil',    'Costco',    true),
  ('Olive oil',    'No Frills', false),
  ('Toilet paper', 'Costco',    true)
) as x(item_name, store_name, preferred)
join items  i on i.name = x.item_name
join stores s on s.name = x.store_name;
