-- =====================================================================
-- Pantry App · Step 9 (Phase 2a) · Recipes
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================

-- 1. The kinds of meal a recipe can be.
create type meal_type as enum ('breakfast', 'lunch', 'dinner', 'snack', 'side', 'dessert');


-- 2. RECIPES
create table recipes (
  id            uuid primary key default gen_random_uuid(),
  name          text not null unique,
  meal_type     meal_type not null default 'dinner',
  minutes       integer check (minutes > 0),          -- total time; optional
  servings      integer check (servings > 0),         -- optional
  is_favourite  boolean not null default false,
  basics        text,     -- "salt, oil, water": shown on the recipe, never affects readiness
  method        text,     -- the steps, as plain text
  photo_path    text,     -- added in step 13 (photos)
  created_at    timestamptz not null default now()
);


-- 3. RECIPE_INGREDIENTS — the link between a recipe and a PANTRY ITEM (never free text).
--    Same many-to-many pattern as item_stores.
create table recipe_ingredients (
  recipe_id    uuid not null references recipes(id) on delete cascade,   -- delete a recipe → its ingredient rows go too
  item_id      uuid not null references items(id)   on delete restrict,  -- can't delete an item a recipe still uses
  amount_text  text,                 -- "2 cups" — display only, no maths
  position     integer not null,     -- the order ingredients are listed in
  primary key (recipe_id, item_id)   -- an item appears once per recipe
);

-- Fast look-up of "which recipes use this item?" (used when an item changes status).
create index recipe_ingredients_item_idx on recipe_ingredients (item_id);


-- 4. Security: signed-in household members only, same as the other tables.
alter table recipes            enable row level security;
alter table recipe_ingredients enable row level security;

create policy "household can do everything" on recipes
  for all to authenticated using (true) with check (true);
create policy "household can do everything" on recipe_ingredients
  for all to authenticated using (true) with check (true);


-- 5. Live updates on other devices.
alter publication supabase_realtime add table recipes, recipe_ingredients;


-- 6. save_recipe: save a recipe AND its full ingredient list in ONE transaction.
--    p_id = null → new recipe; otherwise update that recipe. Returns the recipe's id.
--    p_ingredients is a JSON list, in display order:
--      [{"item_id": "…", "amount_text": "2 cups"}, …]
create or replace function save_recipe(
  p_id           uuid,
  p_name         text,
  p_meal_type    meal_type,
  p_minutes      integer,
  p_servings     integer,
  p_is_favourite boolean,
  p_basics       text,
  p_method       text,
  p_ingredients  jsonb
)
returns uuid
language plpgsql
security invoker            -- runs with the signed-in user's permissions (RLS applies)
set search_path = public
as $$
declare
  v_id uuid;
begin
  if p_id is null then
    insert into recipes (name, meal_type, minutes, servings, is_favourite, basics, method)
    values (
      nullif(trim(p_name), ''),           -- blank name → NULL → rejected by NOT NULL
      coalesce(p_meal_type, 'dinner'),
      p_minutes,
      p_servings,
      coalesce(p_is_favourite, false),
      nullif(trim(p_basics), ''),
      nullif(trim(p_method), '')
    )
    returning id into v_id;
  else
    update recipes
    set name         = nullif(trim(p_name), ''),
        meal_type    = coalesce(p_meal_type, meal_type),
        minutes      = p_minutes,
        servings     = p_servings,
        is_favourite = coalesce(p_is_favourite, false),
        basics       = nullif(trim(p_basics), ''),
        method       = nullif(trim(p_method), '')
    where id = p_id
    returning id into v_id;

    if v_id is null then
      raise exception 'That recipe no longer exists.';
    end if;
  end if;

  -- Replace the ingredient list with exactly the one sent, keeping its order.
  -- If the same item is sent twice, only its first appearance is kept.
  delete from recipe_ingredients where recipe_id = v_id;

  insert into recipe_ingredients (recipe_id, item_id, amount_text, position)
  select distinct on (item_id)
         v_id, item_id, amount_text, position
  from (
    select (elem ->> 'item_id')::uuid                     as item_id,
           nullif(trim(elem ->> 'amount_text'), '')       as amount_text,
           ord::integer                                   as position
    from jsonb_array_elements(coalesce(p_ingredients, '[]'::jsonb)) with ordinality as t(elem, ord)
  ) as sent
  order by item_id, position;

  return v_id;
end;
$$;

revoke execute on function save_recipe(uuid, text, meal_type, integer, integer, boolean, text, text, jsonb) from public, anon;
grant  execute on function save_recipe(uuid, text, meal_type, integer, integer, boolean, text, text, jsonb) to authenticated;
