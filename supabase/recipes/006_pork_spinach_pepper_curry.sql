-- =====================================================================
-- Recipe import · Smart Pork, Spinach and Pepper Curry (with Buttery Bulgur)
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
  if exists (select 1 from recipes where lower(name) = lower('Smart Pork, Spinach and Pepper Curry')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Smart Pork, Spinach and Pepper Curry',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook bulgur.</strong> Add ⅔ cup water and ½ tsp salt to a medium pot. Cover and bring to a boil over high heat. Once boiling, stir in the bulgur until the water returns to a boil, then cover and remove from heat. Let stand until the bulgur is tender and the liquid is absorbed, 16–18 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, core, then cut the pepper into ¼-inch pieces. Roughly chop the spinach. Thinly slice the green onions.</p></li><li><p><strong>Cook the pork.</strong> Heat a large non-stick pan over medium-high heat. When hot, add the pork to the dry pan. Cook, breaking it up into smaller pieces, until no pink remains, 3–4 min. Season with salt and pepper. Add the pepper and cook, stirring occasionally, until tender-crisp, 3–4 min.</p></li><li><p><strong>Make the sauce.</strong> Reduce the heat to medium. Add the Indian spice mix and curry paste and cook, stirring constantly, until fragrant, 1 min. Add ½ cup water and cook, stirring occasionally, until slightly thickened, 1–2 min. Add the spinach and 1 tbsp butter and stir until the spinach wilts, 30 sec. Season with salt and pepper.</p></li><li><p><strong>Finish and serve.</strong> Fluff the bulgur with a fork, then stir in 1 tbsp butter and half the green onions. Divide the bulgur between bowls and top with the pork curry. Sprinkle with the rest of the green onions.</p></li></ol><p><em>For 4 people:</em> 1 cup water and 1 tsp salt for the bulgur; 1 cup water and 2 tbsp butter for the sauce; 2 tbsp butter for the bulgur; double the ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground pork', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bulgur', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Indian spice mix', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Curry paste', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
