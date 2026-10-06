-- =====================================================================
-- Recipe import · Crispy Chicken Parmigiana (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Crispy Chicken Parmigiana')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Crispy Chicken Parmigiana',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Bread the chicken.</strong> Preheat the broiler to high. Wash and dry all produce. In a shallow dish, stir together the panko and half the Parmesan. Pat the chicken dry with paper towels. Carefully slice into the centre of each breast, parallel to the cutting board, leaving ½ inch intact on the other end, and open it like a book. Season both sides with salt, pepper and half the Italian seasoning. Coat each breast all over with mayo, then, one at a time, press both sides into the panko mixture to coat completely.</p></li><li><p><strong>Pan-fry the chicken.</strong> Heat a large non-stick pan over medium heat. When hot, add 1 tbsp oil, then the chicken. Pan-fry until golden-brown, 3–4 min per side. Move the chicken to a foil-lined baking sheet. Carefully wipe the pan clean.</p></li><li><p><strong>Broil.</strong> Spoon the marinara sauce over the chicken, then sprinkle with the rest of the Parmesan. Broil in the middle of the oven until the cheese is golden-brown and the chicken is cooked through, 4–6 min (165°F inside).</p></li><li><p><strong>Cook the veggies.</strong> Meanwhile, core, then cut the pepper into ¼-inch slices. Peel, then cut half the onion into ¼-inch slices. Heat the same pan over medium-high heat. When hot, add ½ tbsp oil, then the peppers, onions and the rest of the Italian seasoning. Season with salt and pepper. Cook, stirring occasionally, until tender, 3–4 min. Move to a plate to cool slightly.</p></li><li><p><strong>Make the dressing.</strong> Meanwhile, in a large bowl, whisk together the Dijon, vinegar, ½ tsp sugar and 1 tbsp oil. Season with salt and pepper.</p></li><li><p><strong>Serve.</strong> Add the spinach, peppers and onions to the bowl with the dressing and toss. Divide the chicken parmigiana and salad between plates.</p></li></ol><p><em>For 4 people:</em> pan-fry the chicken in batches, 1 tbsp oil per batch; the whole onion and 1 tbsp oil for the veggies; 1 tsp sugar and 2 tbsp oil in the dressing; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parmesan cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Italian seasoning', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Marinara sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red onion', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dijon mustard', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
