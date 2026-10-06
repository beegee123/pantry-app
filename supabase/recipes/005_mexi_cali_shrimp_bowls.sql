-- =====================================================================
-- Recipe import · Cal Smart Mexi-Cali Shrimp Bowls (with Warm Bulgur Salad and Baja Sauce)
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
  if exists (select 1 from recipes where lower(name) = lower('Cal Smart Mexi-Cali Shrimp Bowls')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Cal Smart Mexi-Cali Shrimp Bowls',
    p_meal_type    => 'dinner',
    p_minutes      => 20,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Make bulgur.</strong> Combine the stock powder and ⅔ cup water in a medium pot. Cover and bring to a boil over high heat. Once boiling, stir in the bulgur and return to a boil, then cover and remove from heat. Let stand until the bulgur is tender and the liquid is absorbed, 16–18 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, roughly chop the spinach. Thinly slice the green onions. Halve the tomatoes. Zest, then juice half the lemon; cut the rest into wedges. Add the tomatoes to a medium bowl, squeeze a lemon wedge over them and toss to coat.</p></li><li><p><strong>Make the Baja sauce.</strong> In a small bowl, combine the mayo, sour cream, half the chipotle sauce, half the lemon juice and ½ tsp Southwest spice blend. Season with salt and pepper and stir to combine.</p></li><li><p><strong>Cook the shrimp.</strong> Heat a large non-stick pan over medium-high heat. While it heats, drain and rinse the shrimp in a strainer, then pat dry with paper towels. Transfer to another medium bowl, season with salt, pepper and the rest of the spice blend, and toss to coat. When the pan is hot, add ½ tbsp oil, then the shrimp. Cook, stirring occasionally, until the shrimp just turn pink, 2–3 min. Remove the pan from the heat, add the rest of the chipotle sauce and stir to coat.</p></li><li><p><strong>Make the bulgur salad.</strong> Add the lemon zest to the pot with the bulgur and fluff with a fork. Add the spinach, the rest of the lemon juice and half the green onions. Drizzle ½ tbsp oil over the top, season with pepper and toss to combine.</p></li><li><p><strong>Finish and serve.</strong> Divide the bulgur salad between bowls. Top with the shrimp and tomatoes, dollop the Baja sauce over and sprinkle with the rest of the green onions. Squeeze a lemon wedge over the top, if you like.</p></li></ol><p><em>For 4 people:</em> 1 cup water for the bulgur; 1 tsp spice blend in the sauce; 1 tbsp oil for the shrimp and 1 tbsp for the salad; double the ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Shrimp', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bulgur', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Stock powder', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lemon', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chipotle sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Southwest spice blend', 'Pantry'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
