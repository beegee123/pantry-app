-- =====================================================================
-- Recipe import · Crispy Kickin' Cayenne Chicken Cutlets (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Crispy Kickin'' Cayenne Chicken Cutlets')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Crispy Kickin'' Cayenne Chicken Cutlets',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep and make the sauce.</strong> Put racks in the top and middle of the oven and preheat to 425°F. Wash and dry the produce. Trim, peel and cut the carrots on a diagonal into ½-inch-thick pieces. Trim and thinly slice the scallions, keeping the whites and greens separate. In a small bowl, combine half the sour cream, ½ tsp Frank’s seasoning blend (you’ll use the rest in step 2) and a big pinch of salt. Stir in water, 1 tsp at a time, until it’s thin enough to drizzle.</p></li><li><p><strong>Mix the panko.</strong> Microwave 1 tbsp butter in a medium microwave-safe bowl until melted, 30–45 sec. Stir in the panko, Monterey Jack, the rest of the Frank’s seasoning blend and a big pinch of salt and pepper.</p></li><li><p><strong>Make the mashed potatoes.</strong> Dice the potatoes into ½-inch pieces. Put them in a medium pot with enough salted water to cover by 2 inches. Bring to a boil and cook until tender, 15–20 min. Keep ½ cup of the cooking water, then drain. Heat a drizzle of oil and the scallion whites in the empty pot over low heat until softened, 1 min. Return the potatoes and mash with the rest of the sour cream and 1 tbsp butter until smooth, adding splashes of the cooking water as needed. Season with salt and pepper. Keep covered off the heat.</p></li><li><p><strong>Roast the carrots.</strong> While the potatoes cook, lightly oil a baking sheet. Toss the carrots on one side of the sheet with a drizzle of oil, salt and pepper. Roast on the top rack for 5 min (you’ll add the chicken to the sheet then).</p></li><li><p><strong>Coat and roast the chicken.</strong> Meanwhile, pat the chicken dry with paper towels and season with salt and pepper. Mound the tops with the panko mixture, pressing firmly so it sticks. When the carrots have roasted 5 min, take the sheet out and place the chicken, coated side up, on the empty side. Roast on the top rack until the chicken is golden-brown and cooked through and the carrots are tender, 15–18 min (165°F inside).</p></li><li><p><strong>Finish and serve.</strong> Toss the roasted carrots in a large bowl with 1 tbsp butter until melted. Divide the carrots, mashed potatoes and chicken between plates. Drizzle the chicken with the creamy Buffalo sauce and honey (or serve them on the side for dipping). Garnish the potatoes and chicken with the scallion greens.</p></li></ol><p><em>For 4 people:</em> 1 tsp Frank’s seasoning in the sauce; 2 tbsp butter in the panko, 2 tbsp in the mash; roast the chicken on a second oiled sheet on the middle rack, with the carrots staying on top; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', '10 oz cutlets'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', '12 oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Carrots', 'Produce'), 'amount_text', '12 oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', '2 scallions'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', '3 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Frank''s seasoning blend', 'Pantry'), 'amount_text', '¼ oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Monterey Jack cheese', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Honey', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '3 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
