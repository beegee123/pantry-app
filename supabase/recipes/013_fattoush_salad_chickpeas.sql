-- =====================================================================
-- Recipe import · Fattoush Salad and Roasted Chickpeas (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Fattoush Salad and Roasted Chickpeas')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Fattoush Salad and Roasted Chickpeas',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Prep the chickpeas and garlic.</strong> Preheat the oven to 425°F. Wash and dry all produce. Drain and rinse the chickpeas, then pat dry with paper towels. On a parchment-lined baking sheet, toss the chickpeas with half the shawarma spice blend and 2 tbsp oil. Season with salt and pepper. Peel the garlic, toss the cloves with ½ tbsp oil on a small sheet of foil, wrap tightly and put it on the same baking sheet.</p></li><li><p><strong>Roast the chickpeas.</strong> Roast in the bottom of the oven until the chickpeas are almost crispy, 10–12 min. Carefully take the sheet out, stir the chickpeas, then cover loosely with foil (or another baking sheet). Return to the oven and roast until crispy, 6–8 min.</p></li><li><p><strong>Bake the pitas.</strong> Meanwhile, cut the pitas into 1-inch pieces. On another parchment-lined baking sheet, toss them with the rest of the shawarma spice blend and 1 tbsp oil. Season with salt and pepper. Bake in the top of the oven until golden-brown and crispy, 5–6 min.</p></li><li><p><strong>Prep the veggies.</strong> Meanwhile, halve the tomatoes. Thinly slice the green onions. Core, then cut the pepper into ½-inch pieces. Drain, then roughly chop the olives. Roughly chop the parsley.</p></li><li><p><strong>Make the dressing.</strong> Put the roasted garlic cloves in a large bowl and mash with a fork. Add the vinegar, 1 tsp sugar, 2 tbsp oil and 1 tbsp water. Season with salt and pepper, then whisk.</p></li><li><p><strong>Toss and serve.</strong> Add the roasted chickpeas, green onions, tomatoes, peppers, parsley, olives and half the feta to the bowl with the dressing. Toss to coat. Divide the spiced pitas between bowls, top with the chickpea mixture and sprinkle the rest of the feta over the top.</p></li></ol><p><em>For 4 people:</em> double every oil, sugar and water amount, and the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chickpeas', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pitas', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Shawarma spice blend', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Olives', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parsley', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
