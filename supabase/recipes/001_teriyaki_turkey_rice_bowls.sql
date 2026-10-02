-- =====================================================================
-- Recipe import · Teriyaki Turkey Rice Bowls
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- Safe to run again: if the recipe already exists, nothing changes.
-- =====================================================================

-- Throwaway notes for this run only (temp = deleted when the session ends).
create temp table if not exists import_log (ingredient text, pantry_item text, result text);
truncate import_log;

-- Find the pantry item for an ingredient, or create it.
-- Matching ignores capitals and a trailing "s" ("green onion" finds "Green onions"),
-- and also finds a name with details after a comma ("Rice" finds "Rice, 8 kg").
-- (pg_temp = a throwaway function that only exists for this run.)
create or replace function pg_temp.pantry_item(p_name text, p_category text)
returns uuid
language plpgsql
as $$
declare
  v_id   uuid;
  v_name text;
  v_key  text := lower(trim(p_name));
begin
  select id, name into v_id, v_name
  from items
  where lower(name) in (v_key, v_key || 's', regexp_replace(v_key, 's$', ''))
     or lower(name) like v_key || ',%'
  order by lower(name) = v_key desc,  -- an exact match wins,
           lower(name) like '%,%'     -- then a plural, then "Rice, 8 kg"
  limit 1;

  if v_id is not null then
    insert into import_log values (p_name, v_name, 'matched existing item');
    return v_id;
  end if;

  -- category_id_for finds the category by name, or creates it (009_categories.sql).
  insert into items (name, category_id, status) values (p_name, category_id_for(p_category), 'in')
  returning id into v_id;
  insert into import_log values (p_name, p_name, 'NEW item in ' || p_category || ' (In)');
  return v_id;
end;
$$;


do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Teriyaki Turkey Rice Bowls')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  -- save_recipe (006_recipes.sql) saves the recipe and its ingredient list in one go.
  perform save_recipe(
    p_id           => null,
    p_name         => 'Teriyaki Turkey Rice Bowls',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       =>
'1. Heat a medium pot over medium heat. Add ½ tbsp oil, then the edamame, rice and half the garlic salt. Cook, stirring often, until toasted, 2–3 min. Add 1¼ cups water and bring to a boil over high heat. Reduce heat to low, cover and cook until the rice is tender and the water is absorbed, 15–18 min. Take off the heat and leave covered.

2. Meanwhile, cut the broccoli into bite-sized pieces and thinly slice the green onions.

3. Heat a large non-stick pan over medium-high heat. Add ½ tbsp oil, then the broccoli, the rest of the garlic salt and 2 tbsp water. Cook, stirring occasionally, until tender-crisp, 4–5 min. Move to a plate and cover to keep warm.

4. In the same pan over medium heat, add ½ tbsp oil, then the turkey. Cook, breaking it up, until no pink remains, 4–5 min. Stir in the teriyaki sauce, soy sauce and mirin and cook until the sauce thickens slightly, 1 min. Take off the heat and season with salt and pepper.

5. Fluff the rice with a fork and stir in half the green onions. Divide between bowls, then top with the broccoli, turkey and any pan sauce. Sprinkle with the rest of the green onions.

For 4 people: double the oil, water and ingredients.',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground turkey',  'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice',           'Pantry'),      'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Edamame',        'Frozen'),      'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broccoli',       'Produce'),     'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions',   'Produce'),     'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt',    'Pantry'),      'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Teriyaki sauce', 'Pantry'),      'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Soy sauce',      'Pantry'),      'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mirin',          'Pantry'),      'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
