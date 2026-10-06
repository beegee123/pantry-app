-- =====================================================================
-- Recipe import · Cheesy Stuffed Chicken and Sweet Potato Mash (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Cheesy Stuffed Chicken and Sweet Potato Mash')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Cheesy Stuffed Chicken and Sweet Potato Mash',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Boil the sweet potatoes.</strong> Preheat the oven to 425°F. Wash and dry all produce. Peel, then cut the sweet potatoes into ½-inch pieces. Add them to a large pot with 1 tsp salt and enough water to cover by 1–2 inches. Cover and bring to a boil over high heat. Once boiling, reduce the heat to medium and simmer uncovered until fork-tender, 10–12 min. Drain and return to the same pot, off the heat.</p></li><li><p><strong>Stuff the chicken.</strong> Meanwhile, thinly slice the chives. In a small bowl, mix the cheddar, cream cheese, half the crispy shallots and half the chives. Pat the chicken dry with paper towels. Carefully slice into the centre of each breast, parallel to the cutting board, leaving 1 inch intact on the other end. Open each breast like a book and season inside with ¼ tsp garlic salt and pepper. Divide the cheese filling between the breasts, then fold closed. Season the outside with ¼ tsp garlic salt and pepper.</p></li><li><p><strong>Sear and bake the chicken.</strong> Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the chicken (don’t overcrowd the pan; cook in 2 batches if needed). Cook until golden, 1–2 min per side. Move the chicken to a parchment-lined baking sheet and bake in the middle of the oven until cooked through, 14–16 min (165°F inside).</p></li><li><p><strong>Make the dressing.</strong> Meanwhile, in a large bowl, whisk together the vinegar, 1 tbsp oil and ½ tsp sugar. Season with salt and pepper, then set aside.</p></li><li><p><strong>Mash.</strong> Mash 2 tbsp butter into the sweet potatoes until smooth. Stir in the rest of the chives. Season with salt and pepper.</p></li><li><p><strong>Serve.</strong> When the chicken is done, let it rest on a plate for 3–5 min. Add the spring mix to the bowl with the dressing and toss. Divide the mash, chicken and salad between plates. Drizzle any juices from the baking sheet over the chicken, and sprinkle the rest of the crispy shallots over the salad.</p></li></ol><p><em>For 4 people:</em> same 1 tsp salt for the potatoes; ½ tsp garlic salt inside and ½ tsp outside the chicken; 1 tbsp oil to sear; 2 tbsp oil and 1 tsp sugar in the dressing; 4 tbsp butter in the mash; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sweet potatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chives', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cheddar cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cream cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Crispy shallots', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spring mix', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
