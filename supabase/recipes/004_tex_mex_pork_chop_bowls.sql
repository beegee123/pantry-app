-- =====================================================================
-- Recipe import · Smart Tex-Mex Pork Chop Bowls (with Roasted Pepper Salsa)
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
  if exists (select 1 from recipes where lower(name) = lower('Smart Tex-Mex Pork Chop Bowls')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Smart Tex-Mex Pork Chop Bowls',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Make bulgur.</strong> Add ⅔ cup water and ½ tsp salt to a medium pot. Cover and bring to a boil over high heat. Once boiling, stir in the bulgur until the water returns to a boil, then cover and remove from heat. Let stand until the bulgur is tender and the liquid is absorbed, 16–18 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, core the hot pepper, then cut into ¼-inch pieces (tip: wear gloves). Cut the tomatoes into ¼-inch pieces. Roughly chop the cilantro. Zest, then juice the lime. Pat the pork chops dry with paper towels, then cut into ¼-inch slices.</p></li><li><p><strong>Char the hot pepper.</strong> Heat a large non-stick pan over medium-high heat. When hot, add the pepper to the dry pan. Cover and cook, flipping halfway through, until dark golden, 4–5 min. Transfer to a medium bowl.</p></li><li><p><strong>Cook the pork.</strong> Add ½ tbsp oil to the same pan, then the pork. Pan-fry until golden and cooked through, 3–4 min (145°F inside). Remove the pan from the heat, then add the Tex-Mex paste, ¼ tsp sugar and 1 tbsp water. Cook, stirring often, until the pork is coated, 1 min. Remove from the heat.</p></li><li><p><strong>Make the salsa.</strong> Meanwhile, add the tomatoes, lime juice and half the cilantro to the bowl with the pepper. Season with salt and pepper and stir to combine.</p></li><li><p><strong>Finish and serve.</strong> Fluff the bulgur with a fork and stir in the rest of the cilantro. In a small bowl, stir the sour cream and lime zest together and season with salt and pepper. Divide the bulgur between bowls, top with the pork, then the salsa and lime crema. Sprinkle with feta.</p></li></ol><p><em>For 4 people:</em> 1 cup water and 1 tsp salt for the bulgur; cook the pork in 2 batches with ½ tbsp oil each; ½ tsp sugar and 2 tbsp water for the sauce; double the ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Pork chops', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bulgur', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Hot pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cilantro', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lime', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tex-Mex paste', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
