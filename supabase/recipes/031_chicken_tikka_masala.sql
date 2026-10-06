-- =====================================================================
-- Recipe import · Chicken Tikka Masala with Garlic Rice (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Chicken Tikka Masala with Garlic Rice')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Chicken Tikka Masala with Garlic Rice',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook the garlic rice.</strong> Peel, then mince or grate the garlic. Heat a medium pot over medium heat. When hot, add ½ tbsp oil, then the rice and garlic. Cook, stirring often, until fragrant, 2–3 min. Add 1¼ cups water and half the garlic salt, and bring to a boil over high heat. Once boiling, reduce the heat to low. Cover and cook until the rice is tender and the liquid is absorbed, 12–14 min. Take off the heat and leave covered.</p></li><li><p><strong>Prep.</strong> Meanwhile, peel, then halve the carrot lengthwise and cut into ¼-inch half-moons. Roughly chop the spinach.</p></li><li><p><strong>Cook the carrots.</strong> Heat a large non-stick pan over medium-high heat. When hot, add ½ cup water, then the carrots. Cook, stirring often, until the water is absorbed and the carrots are tender-crisp, 5–6 min. Season with salt and pepper, then move to a plate.</p></li><li><p><strong>Start the chicken.</strong> Pat the chicken dry with paper towels, cut into 1-inch pieces and season with the rest of the garlic salt and pepper. Reheat the same pan over medium heat. When hot, add ½ tbsp oil, then the chicken. Cook until golden-brown, 2–3 min per side (it finishes cooking in the next step).</p></li><li><p><strong>Make the sauce and finish the chicken.</strong> Add the curry paste to the pan with the chicken and cook, stirring often, until fragrant, 30 sec. Reduce the heat to medium-low, then add the tikka sauce, cream and ¼ cup water. Cook, stirring occasionally, until the sauce thickens slightly and the chicken is cooked through, 5–7 min (165°F inside). Add the carrots and spinach, season with salt and pepper, and stir until the spinach wilts, 1–2 min.</p></li><li><p><strong>Finish and serve.</strong> Fluff the garlic rice with a fork. Divide between plates and top with the chicken tikka masala.</p></li></ol><p><em>For 4 people:</em> 1 tbsp oil for the rice and 1 tbsp for the chicken; 2½ cups water for the rice; ¾ cup water for the carrots; ½ cup water in the sauce; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '¾ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', '1 clove'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Carrots', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '28 g baby spinach'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Curry paste', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tikka sauce', 'Pantry'), 'amount_text', '½ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cream', 'Dairy & eggs'), 'amount_text', '56 ml')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
