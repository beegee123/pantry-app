-- =====================================================================
-- Pantry App · Step 14 (Phase 3a) · Meal plan
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================

-- MEAL_PLAN — one row per planned meal: "on this date, for this meal, cook this recipe".
-- For now the app plans dinners only; the `meal` column leaves room for
-- breakfast and lunch later without changing the table.
create table meal_plan (
  plan_date   date not null,
  meal        text not null default 'dinner' check (meal in ('breakfast', 'lunch', 'dinner')),
  recipe_id   uuid not null references recipes(id) on delete cascade,  -- delete a recipe → it leaves the plan
  is_locked   boolean not null default false,  -- used by the generator later (step 17): locked days are kept
  created_at  timestamptz not null default now(),
  primary key (plan_date, meal)                -- one dinner per day
);

-- "Which days use this recipe?" (the generator's "skip last week" rule will ask this).
create index meal_plan_recipe_idx on meal_plan (recipe_id);


-- Security: signed-in household members only, same as the other tables.
alter table meal_plan enable row level security;

create policy "household can do everything" on meal_plan
  for all to authenticated using (true) with check (true);


-- Live updates on other devices.
alter publication supabase_realtime add table meal_plan;
