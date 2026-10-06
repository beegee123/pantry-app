-- =====================================================================
-- Recipe import · Feta Beef Burgers (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Feta Beef Burgers')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Feta Beef Burgers',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Prep.</strong> Preheat the broiler to high. Wash and dry all produce. Finely chop 1 tbsp oregano leaves. Cut the tomato into ¼-inch pieces. In a small bowl, stir together the mayo and half the feta. Season with pepper.</p></li><li><p><strong>Make the patties.</strong> In a large bowl, combine the beef, panko, oregano and half the garlic salt. Season with pepper. (Tip: for a more tender patty, add an egg to the mixture.) Form into two 4-inch-wide patties.</p></li><li><p><strong>Cook the patties.</strong> Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the patties (don’t overcrowd the pan). Pan-fry until golden-brown and cooked through, 4–5 min per side (165°F inside). Move to a plate and cover to keep warm.</p></li><li><p><strong>Toast the buns.</strong> Meanwhile, halve the buns. Arrange them cut side up on an unlined baking sheet. Broil in the middle of the oven until golden-brown, 1–2 min (watch them so they don’t burn).</p></li><li><p><strong>Make the salad.</strong> Meanwhile, in another large bowl, whisk together the rest of the garlic salt, ½ tbsp vinegar, ¼ tsp sugar and 1 tbsp oil. Add the tomatoes, spinach and the rest of the feta. Sprinkle the olives over the top, if you like. Season with pepper and toss.</p></li><li><p><strong>Finish and serve.</strong> Spread the feta-mayo on the bottom buns, then stack with the patties and some salad. Close with the top buns. Divide the burgers between plates and serve the rest of the salad alongside.</p></li></ol><p><em>For 4 people:</em> 2 tbsp oregano; 4 patties, cooked in 2 batches; 1 tbsp oil for the patties; 1 tbsp vinegar, ½ tsp sugar and 2 tbsp oil in the salad; double the other ingredients.</p><p><em>Ground turkey:</em> moisten your hands slightly to form the patties, then cook them the same way.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground beef', 'Meat & fish'), 'amount_text', '250 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Artisan buns', 'Pantry'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Oregano', 'Produce'), 'amount_text', '7 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', '4 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', '80 g Roma'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '56 g baby spinach'),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', '½ tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Olives', 'Pantry'), 'amount_text', '30 g mixed')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
