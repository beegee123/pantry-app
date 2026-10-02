-- =====================================================================
-- Recipe import · Honey Chili-Garlic Roasted Salmon (with Pan-Fried Vegetables)
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- Safe to run again: if the recipe already exists, nothing changes.
-- Same pattern as 001: match each ingredient to a pantry item, or create it as In.
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

  insert into items (name, category, status) values (p_name, p_category, 'in')
  returning id into v_id;
  insert into import_log values (p_name, p_name, 'NEW item in ' || p_category || ' (In)');
  return v_id;
end;
$$;


do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Honey Chili-Garlic Roasted Salmon')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Honey Chili-Garlic Roasted Salmon',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => true,   -- it's in the kit's favourites
    p_basics       => 'oil, water, salt, pepper',
    p_method       =>
'1. Preheat the oven to 425°F. Add 1¼ cups water and ½ tsp garlic salt to a medium pot. Cover and bring to a boil over high heat. Meanwhile, halve the zucchini lengthwise, then cut into ½-inch half-moons, and halve the tomatoes. Add the rice to the boiling water, reduce heat to low, cover and cook until the rice is tender and the water is absorbed, 12–14 min. Take off the heat and leave covered.

2. Meanwhile, combine the chili-garlic sauce and honey in a small bowl. Pat the salmon dry with paper towels, then season with salt and pepper. Arrange skin-side down on a parchment-lined baking sheet and spoon the honey chili-garlic sauce over top. Roast in the middle of the oven until cooked through, 10–12 min (145°F inside).

3. Meanwhile, heat a large non-stick pan over medium-high heat. Add 1 tbsp oil, then the zucchini. Cook, stirring occasionally, until tender-crisp, 3–4 min.

4. Add the tomatoes and cook, stirring occasionally, until slightly blistered, 1–2 min. Take off the heat, add the garlic puree, season with the rest of the garlic salt and pepper, and stir to combine.

5. Fluff the rice with a fork, add 1 tbsp butter, season with salt and pepper and stir. Divide the veggies and rice between plates, top with the salmon and drizzle over any sauce left on the baking sheet.

For 4 people: double the water, garlic salt, oil, butter and ingredients.',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Salmon fillets', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zucchini', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chili-garlic sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Honey', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic puree', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', '½ tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
