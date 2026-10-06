-- =====================================================================
-- Recipe import · Harvest Salmon (with Roasted Veggies and Herby Pesto Orzo)
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
  if exists (select 1 from recipes where lower(name) = lower('Harvest Salmon')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Harvest Salmon',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Start the orzo water and marinate the tomatoes.</strong> Preheat the oven to 450°F. Add 8 cups water and 1 tsp salt to a medium pot, cover and bring to a boil over high heat. Meanwhile, halve the tomatoes, roughly chop the parsley, and peel, then mince or grate the garlic. In a large bowl, combine the tomatoes, pesto, half the vinegar, half the garlic salt, half the garlic and ¼ tsp sugar. Season with salt and pepper and toss.</p></li><li><p><strong>Prep the veggies.</strong> Cut the zucchini into ½-inch rounds. Core, then cut the pepper into 1-inch pieces. Peel, then cut the onion into ½-inch slices. On a parchment-lined baking sheet, toss the zucchini, pepper, onion, Zesty Garlic Blend and 1 tbsp oil. Season with salt and pepper and spread in a single layer.</p></li><li><p><strong>Roast the veggies.</strong> Roast in the middle of the oven, tossing halfway through, until tender, 16–20 min.</p></li><li><p><strong>Cook the orzo.</strong> Add the orzo to the boiling water and cook, uncovered, stirring occasionally, until tender, 10–12 min. Drain (rinse under cool water if you’d like a cold orzo salad), then add to the bowl with the marinated tomatoes and toss.</p></li><li><p><strong>Cook the salmon.</strong> Meanwhile, heat a large non-stick pan over medium-high heat. Pat the salmon dry and season with the rest of the garlic salt and pepper. When the pan is hot, add ½ tbsp oil, then the salmon. Pan-fry until golden-brown and cooked through, 3–5 min per side (145°F inside).</p></li><li><p><strong>Make the aioli and serve.</strong> In a small bowl, combine the mayo with as much of the remaining garlic as you like, and season with salt and pepper. Divide the orzo between plates and top with the veggies and salmon. Dollop the aioli over the salmon or serve it alongside. Sprinkle with parsley.</p></li></ol><p><em>For 4 people:</em> the same 8 cups water; use all the vinegar; roast on two baking sheets (half the Zesty Garlic Blend and 1 tbsp oil on each) in the middle and bottom of the oven, swapping them halfway; 1 tbsp oil for the salmon; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Salmon fillets', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Orzo', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pesto', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parsley', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zucchini', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red onion', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zesty garlic blend', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
