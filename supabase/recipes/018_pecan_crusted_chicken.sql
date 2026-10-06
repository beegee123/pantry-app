-- =====================================================================
-- Recipe import · Pecan-Crusted Chicken (with Carrot Mash and Roasted Brussels Sprouts)
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- Safe to run again: if the recipe already exists, nothing changes.
-- Same pattern as 001: match each ingredient to a pantry item, or create it as In.
-- The method is written as HTML (numbered steps with bold titles), like the method editor saves.
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
  if exists (select 1 from recipes where lower(name) = lower('Pecan-Crusted Chicken')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Pecan-Crusted Chicken',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'olive oil, cooking oil, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Put a rack in the middle of the oven and preheat to 450°F. Wash and dry the produce. Finely chop the pecans (or crush them in their bag with a heavy pan or rolling pin).</p></li><li><p><strong>Make the crust.</strong> Microwave 1 tbsp butter in a medium microwave-safe bowl until melted, 30 sec. Let cool slightly, then stir in the chopped pecans, panko, half the fry seasoning, a drizzle of olive oil and a pinch of salt and pepper.</p></li><li><p><strong>Make the sauce.</strong> In a small bowl, combine the honey, mustard and mayo.</p></li><li><p><strong>Cook the chicken.</strong> Pat the chicken dry with paper towels and season with the rest of the fry seasoning, salt and pepper. Place on a lightly oiled baking sheet (1 tsp cooking oil). Spread the tops of the chicken with a thin layer of honey mustard sauce (save the rest for serving). Mound the pecan mixture on top, pressing firmly so it sticks (no need to coat the undersides). Roast on the middle rack until the crust is golden-brown and the chicken is cooked through, 15–20 min (165°F inside).</p></li><li><p><strong>Make the salad.</strong> Meanwhile, halve, core and thinly slice the apple. Quarter the lemon. In a large bowl, toss the mixed greens and apple with a large drizzle of olive oil and as much lemon juice as you like. Season with salt and pepper.</p></li><li><p><strong>Serve.</strong> Divide the chicken and salad between plates. Drizzle the chicken with the rest of the honey mustard sauce. Serve any remaining lemon wedges on the side.</p></li></ol><p><em>For 4 people:</em> 2 tbsp butter in the crust; same 1 tbsp olive oil and 1 tsp cooking oil; double the other ingredients.</p><p><em>Salmon instead:</em> put the rack in the top position and roast 8–10 min (145°F inside).</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', '10 oz cutlets'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pecans', 'Pantry'), 'amount_text', '½ oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Fry seasoning', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Honey', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dijon mustard', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Apples', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lemon', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spring mix', 'Produce'), 'amount_text', '2 oz mixed greens'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
