-- =====================================================================
-- Recipe import · One-Pot Southwest Beef and Cavatappi (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('One-Pot Southwest Beef and Cavatappi')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'One-Pot Southwest Beef and Cavatappi',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Wash and dry all produce. Core, then cut the pepper into ½-inch pieces. Peel, then cut half the onion into ½-inch pieces. Peel, then mince or grate the garlic.</p></li><li><p><strong>Cook the peppers.</strong> Heat a large pot over medium-high heat. When hot, add ½ tbsp oil, then the peppers. Cook, stirring occasionally, until tender-crisp, 3–4 min. Season with salt and pepper. Move the peppers to a plate and set aside.</p></li><li><p><strong>Brown the beef.</strong> Reheat the same pot over medium-high heat. When hot, add the beef and onions to the dry pot. Cook, breaking the beef into smaller pieces, until no pink remains, 4–5 min (160°F inside). Carefully drain and discard excess fat, if you like.</p></li><li><p><strong>Cook the pasta.</strong> Add the Tex-Mex paste, garlic, marinara sauce, broth concentrate, 2¾ cups water and ½ tsp salt to the pot. Stir to combine, then bring to a boil over high heat. Once boiling, stir in the cavatappi and reduce the heat to medium. Simmer uncovered, stirring often so it doesn’t stick, until the cavatappi is tender, 12–16 min. (Tip: if the pasta is sticking too much, add more water, ¼ cup at a time, and scrape up anything stuck to the bottom of the pot.)</p></li><li><p><strong>Add the veggies.</strong> Add the peppers and spinach to the pot. Cook, stirring often, until the spinach wilts, 1–2 min. Season with pepper.</p></li><li><p><strong>Serve.</strong> Divide the beef and cavatappi between bowls. Sprinkle the cheese over the top.</p></li></ol><p><em>For 4 people:</em> the whole onion; 1 tbsp oil; 5 cups water and 1 tsp salt in step 4; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground beef', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cavatappi', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tex-Mex paste', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Marinara sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Monterey Jack cheese', 'Dairy & eggs'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
