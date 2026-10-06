-- =====================================================================
-- Recipe import · Homestead Chicken Stew (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Homestead Chicken Stew')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Homestead Chicken Stew',
    p_meal_type    => 'dinner',
    p_minutes      => 40,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook the potatoes.</strong> Wash and dry all produce. Peel, then cut the potatoes into 1-inch pieces. Add them to a medium pot with 2 tsp salt and enough water to cover by about 1 inch. Cover and bring to a boil over high heat. Meanwhile, thinly slice the green onions. Once boiling, reduce the heat to medium-high and simmer uncovered until fork-tender, 10–12 min. Drain in a colander.</p></li><li><p><strong>Prep the chicken.</strong> Meanwhile, pat the chicken dry with paper towels, then cut into 1-inch pieces. Season with salt and pepper.</p></li><li><p><strong>Start the stew.</strong> Heat a large pot over medium heat. When hot, add 1½ tbsp butter and swirl until melted. Add the chicken and cook, stirring occasionally, until golden-brown, 3–4 min. Add the aromatics blend and 2–3 thyme sprigs. Cook, stirring occasionally, until the veggies soften slightly, 1–2 min. Sprinkle in the cream sauce spice blend and ¾ tsp garlic salt and cook, stirring often, until the chicken and veggies are coated, 30 sec.</p></li><li><p><strong>Finish the stew.</strong> Stir in 1 cup water and the broth concentrate. Bring to a gentle boil over high heat. Once boiling, add the peas, then reduce the heat to medium. Cover and cook, stirring occasionally, until the veggies are tender and the chicken is cooked through, 8–10 min (165°F inside). The stew will be on the thin side. Season with pepper.</p></li><li><p><strong>Make the brown butter.</strong> Meanwhile, while the potatoes drain, wipe the medium pot dry and heat it over medium heat. When hot, add 2 tbsp butter and swirl until golden-brown and no longer foaming, 1–2 min (watch it so it doesn’t burn). Add the green onions, take the pot off the heat and stir until they soften slightly, 30 sec.</p></li><li><p><strong>Mash and serve.</strong> Return the potatoes to the pot with the brown butter and green onions. Add 3 tbsp milk and the rest of the garlic salt, then mash until creamy. Season with pepper. Remove the thyme sprigs from the stew. Divide the mash between bowls and top with the stew.</p></li></ol><p><em>For 4 people:</em> same 2 tsp salt for the potatoes; 3 tbsp butter for the stew; 3–4 thyme sprigs; 1½ tsp garlic salt; 2 cups water; 4 tbsp butter for the brown butter; 6 tbsp milk; double the other ingredients.</p><p><em>Chicken breasts</em> cook exactly the same way as thighs.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken thighs', 'Meat & fish'), 'amount_text', '280 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', '460 g russet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Aromatics blend', 'Produce'), 'amount_text', '227 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green peas', 'Frozen'), 'amount_text', '56 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Thyme', 'Produce'), 'amount_text', '7 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', 'chicken'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cream sauce spice blend', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '3½ tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Milk', 'Dairy & eggs'), 'amount_text', '3 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
