-- =====================================================================
-- Recipe import · Kadai-Style Paneer (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Kadai-Style Paneer')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Kadai-Style Paneer',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Wash and dry all produce. Core, then cut the pepper into ½-inch pieces. Peel, then cut the onion into ½-inch pieces. Peel, then mince or grate the garlic. Cut the paneer into ½-inch cubes and season with salt and pepper. Roughly chop the spinach.</p></li><li><p><strong>Cook the rice.</strong> Heat a medium pot over medium heat. When hot, add 1 tbsp butter, then the rice and half the garlic. Cook, stirring often, until fragrant, 2–3 min. Add 1¼ cups water and bring to a boil over high heat. Once boiling, reduce the heat to low. Cover and cook until the rice is tender and the liquid is absorbed, 12–14 min. Take off the heat and leave covered.</p></li><li><p><strong>Cook the paneer.</strong> Meanwhile, heat a large non-stick pan over medium-high heat. When hot, add 1 tbsp butter and swirl until melted, 1 min. Add the paneer and pan-fry, turning occasionally, until crispy and golden-brown all over, 5–6 min. Move the paneer to a plate and set aside.</p></li><li><p><strong>Cook the veggies.</strong> Reduce the heat to medium. Add ½ tbsp oil to the same pan, then the onions and peppers. Cook, stirring occasionally, until tender-crisp, 3–4 min. Add the dal spice blend and the rest of the garlic and cook, stirring often, until fragrant, 1–2 min.</p></li><li><p><strong>Make the sauce.</strong> Add the tikka sauce and coconut milk to the pan with the veggies. Reduce the heat to medium-low and cook, stirring occasionally, until the sauce thickens slightly, 5–7 min. Add the paneer and spinach and cook, stirring often, until the spinach wilts, 1–2 min. Season with salt.</p></li><li><p><strong>Finish and serve.</strong> Fluff the rice with a fork and season with salt. Divide the rice between plates and top with the paneer, veggies and any sauce left in the pan.</p></li></ol><p><em>For 4 people:</em> 2 tbsp butter for the rice; 2½ cups water; cook the paneer in 2 batches, 1 tbsp butter per batch; 1 tbsp oil for the veggies; add the spinach in batches; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Paneer', 'Dairy & eggs'), 'amount_text', '200 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '¾ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '160 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red onion', 'Produce'), 'amount_text', '113 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', '2 cloves'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '56 g baby spinach'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tikka sauce', 'Pantry'), 'amount_text', '½ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Coconut milk', 'Pantry'), 'amount_text', '165 ml'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dal spice blend', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
