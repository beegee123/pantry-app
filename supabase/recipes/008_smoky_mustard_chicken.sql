-- =====================================================================
-- Recipe import · Smart Smoky Mustard Chicken (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Smart Smoky Mustard Chicken')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Smart Smoky Mustard Chicken',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Roast the Brussels sprouts.</strong> Preheat the oven to 450°F. Halve the Brussels sprouts (quarter any large ones). On a parchment-lined baking sheet, toss them with 1½ tbsp oil, pepper and half the garlic salt. Roast in the top of the oven until tender, 16–20 min.</p></li><li><p><strong>Boil the carrots.</strong> Meanwhile, peel, then cut the carrots into ¼-inch rounds. Add to a medium pot with enough water to cover by about 1 inch. Cover and bring to a boil over high heat, then reduce the heat to medium-high and simmer, uncovered, until fork-tender, 14–15 min.</p></li><li><p><strong>Sear the chicken.</strong> Meanwhile, pat the chicken dry with paper towels and season with pepper and the rest of the garlic salt. Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the chicken (don’t overcrowd the pan; cook in 2 batches if needed). Cook until golden, 1–2 min per side, then remove from the heat.</p></li><li><p><strong>Roast the chicken.</strong> Transfer the chicken to another parchment-lined baking sheet and roast in the middle of the oven until cooked through, 10–12 min (165°F inside). Let it rest on a plate for 3–5 min.</p></li><li><p><strong>Make the sauce.</strong> Meanwhile, peel, then cut the shallot into ½-inch pieces, and peel, then mince or grate the garlic. In a small bowl, combine the chipotle sauce, half the mustard, the broth concentrate and ¼ cup water. Reheat the pan from step 3 over medium heat. When hot, add ½ tbsp oil, then the shallot and garlic, and cook, stirring often, until fragrant, 30 sec. Add the sauce mixture and cook, stirring often, until slightly thickened, 1–3 min.</p></li><li><p><strong>Mash and serve.</strong> Thinly slice the chicken. Drain the carrots and return them to the pot, off the heat. Mash in 2 tbsp butter and season with salt and pepper. Divide the chicken, Brussels sprouts and mash between plates, and spoon the sauce over the chicken and sprouts.</p></li></ol><p><em>For 4 people:</em> 3 tbsp oil for the sprouts; 1 tbsp oil each for the chicken and the sauce; all the mustard and ½ cup water in the sauce; 4 tbsp butter in the mash; double the other ingredients.</p><p><em>Chicken thighs</em> cook exactly the same way as breasts.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Brussels sprouts', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Carrots', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Shallot', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chipotle sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dijon mustard', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
