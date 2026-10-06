-- =====================================================================
-- Recipe import · Seasoned Shrimp and Roasted Potatoes (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Seasoned Shrimp and Roasted Potatoes')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Seasoned Shrimp and Roasted Potatoes',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Roast the potatoes.</strong> Preheat the oven to 450°F. Wash and dry all produce. Cut the potatoes into ½-inch wedges. On an unlined baking sheet, toss them with 1 tbsp oil and 1½ tsp Old Bay seasoning. Roast in the middle of the oven until golden-brown, 23–26 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, halve the tomatoes. Halve the cucumber lengthwise, then cut into ½-inch half-moons. Roughly chop the parsley. In a strainer, drain and rinse the shrimp, then pat dry with paper towels.</p></li><li><p><strong>Make the salad.</strong> In a large bowl, whisk together the vinegar, ½ tsp sugar and 1 tbsp oil. Season with salt and pepper. Add the spinach, tomatoes and cucumbers and toss.</p></li><li><p><strong>Cook the shrimp.</strong> In a medium bowl, toss the shrimp with the garlic puree, ½ tsp Old Bay seasoning and ½ tbsp oil. Heat a large non-stick pan over medium-high heat. When hot, add the shrimp (don’t overcrowd the pan; cook in 2 batches for 4 people). Cook, stirring occasionally, until the shrimp just turn pink, 2–3 min (165°F inside). Take the pan off the heat. Add half the parsley and 1 tbsp butter, then toss to coat.</p></li><li><p><strong>Serve.</strong> Divide the potatoes and salad between plates. Top the potatoes with the shrimp. Sprinkle the feta and the rest of the parsley over the salad.</p></li></ol><p><em>For 4 people:</em> double every oil, sugar and butter amount, the Old Bay, and the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Shrimp', 'Meat & fish'), 'amount_text', '285 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', '460 g russet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Old Bay seasoning', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic puree', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red wine vinegar', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parsley', 'Produce'), 'amount_text', '7 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '56 g baby spinach'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cucumber', 'Produce'), 'amount_text', '1 mini (66 g)'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', '113 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
