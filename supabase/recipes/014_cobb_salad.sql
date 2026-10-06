-- =====================================================================
-- Recipe import · Carb Smart Cobb Salad (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Carb Smart Cobb Salad')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Carb Smart Cobb Salad',
    p_meal_type    => 'dinner',
    p_minutes      => 20,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'water, salt, pepper',
    p_method       => '<ol><li><p><strong>Boil the eggs.</strong> Wash and dry all produce. Bring 4 cups warm water to a boil in a small pot over high heat. Once boiling, reduce the heat to medium-high and lower the eggs in with a spoon. Cook for 7 min for a runny yolk or 9 min for a set yolk. Drain and rinse under cold water until cool enough to peel, 30 sec. Peel, then halve the eggs and season with salt and pepper.</p></li><li><p><strong>Prep the produce.</strong> Meanwhile, cut the tomato into ¼-inch pieces. Core, then cut the apple into ¼-inch slices.</p></li><li><p><strong>Cut the bacon.</strong> Cut the bacon crosswise into ¼-inch strips.</p></li><li><p><strong>Cook the bacon.</strong> Heat a large non-stick pan over medium heat. When hot, add the bacon. Cook, stirring often, until crispy, 7–10 min. Take the pan off the heat. With a slotted spoon, move the bacon to a paper-towel-lined plate. Keep 1 tbsp bacon fat in a large bowl and carefully discard the rest.</p></li><li><p><strong>Toss the salad.</strong> Add the bacon, apples, tomatoes, dried cranberries, spinach and vinegar to the bowl with the bacon fat. Season with salt and pepper, then toss.</p></li><li><p><strong>Serve.</strong> Divide the salad and eggs between plates. Drizzle the ranch dressing over the top and sprinkle with the feta and pepitas.</p></li></ol><p><em>For 4 people:</em> 8 cups water for the eggs; keep 2 tbsp bacon fat; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Eggs', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bacon', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Apples', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dried cranberries', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Ranch dressing', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pepitas', 'Pantry'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
