-- =====================================================================
-- Recipe import · Lemon-Pesto Chicken (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Lemon-Pesto Chicken')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Lemon-Pesto Chicken',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook the rice.</strong> Preheat the oven to 425°F. Wash and dry all produce. In a medium pot, combine 1¼ cups water, 1 tbsp butter and half the zesty garlic blend. Cover and bring to a boil over high heat. Once boiling, add the rice, then reduce the heat to low. Cover and cook until the rice is tender and the liquid is absorbed, 12–14 min. Take off the heat and leave covered.</p></li><li><p><strong>Prep.</strong> Meanwhile, zest, then juice half the lemon. Cut the other half into wedges. Core, then cut the pepper into ½-inch pieces. Peel, then cut half the onion into ¼-inch pieces.</p></li><li><p><strong>Cook the chicken.</strong> Pat the chicken dry with paper towels, then season with salt, pepper and the rest of the zesty garlic blend. Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the chicken. Sear until golden-brown, 2–3 min per side. Move the chicken to an unlined baking sheet and roast in the middle of the oven until cooked through, 12–14 min (165°F inside).</p></li><li><p><strong>Cook the veggies.</strong> Meanwhile, heat the same pan over medium-high heat. When hot, add ½ tbsp oil, then the peppers and onions. Season with salt and pepper. Cook, stirring occasionally, until tender-crisp, 5–6 min. Move to a plate and cover to keep warm.</p></li><li><p><strong>Make the lemon-pesto sauce.</strong> Meanwhile, in a small bowl, stir together the pesto, half the lemon zest and ½ tsp lemon juice. Season with salt and pepper.</p></li><li><p><strong>Finish and serve.</strong> Fluff the rice with a fork and season with salt. Stir in the veggies and the rest of the lemon zest. Thinly slice the chicken. Divide the pilaf and chicken between plates, spoon the lemon-pesto sauce over the chicken and sprinkle with the feta. Squeeze a lemon wedge over the top, if you like.</p></li></ol><p><em>For 4 people:</em> 2½ cups water and 2 tbsp butter for the rice; 1 tbsp oil each for the chicken and the veggies; the whole onion; 1 tsp lemon juice in the sauce; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '¾ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '160 g sweet bell pepper'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', '56 g yellow onion'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lemon', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pesto', 'Pantry'), 'amount_text', '¼ cup basil pesto'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zesty garlic blend', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
