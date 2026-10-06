-- =====================================================================
-- Recipe import · Coconut Curry with Chickpeas (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Coconut Curry with Chickpeas')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Coconut Curry with Chickpeas',
    p_meal_type    => 'dinner',
    p_minutes      => 40,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Prep.</strong> Wash and dry the produce. Peel and mince the garlic. Halve, peel and finely dice half the onion. Core, deseed and finely dice the bell pepper. Drain and rinse the chickpeas. Finely chop the cilantro.</p></li><li><p><strong>Cook the rice.</strong> Melt 1 tbsp butter in a small pot over medium-high heat. Add half the garlic and cook until fragrant, 30 sec. Add the rice, ¾ cup water and a big pinch of salt. Bring to a boil, then cover and reduce the heat to low. Cook until the rice is tender, 15–18 min. Keep covered off the heat until ready to serve.</p></li><li><p><strong>Cook the curry.</strong> Heat a drizzle of oil in a medium pot over medium-high heat. Add the onion and bell pepper and cook until softened and lightly browned, 3–5 min. Stir in the tomato paste, curry powder, paprika, half the garam masala and the rest of the garlic until fragrant, 1 min. (Tip: add more garam masala if you like its earthy warmth.) Stir in the chickpeas, coconut milk, stock concentrate, ¼ cup water and ½ tsp sugar. Bring to a simmer, then reduce the heat to low and cook until thickened, stirring occasionally, 4–5 min. Take off the heat and stir in 1 tbsp butter until melted. (Tip: if the curry seems too thick, stir in a splash of water.) Season with salt and pepper.</p></li><li><p><strong>Finish and serve.</strong> Fluff the rice with a fork and season with salt and pepper. Divide between bowls, top with the curry, dollop with the yogurt and garnish with the cilantro.</p></li></ol><p><em>For 4 people:</em> the whole onion; 1½ cups water for the rice; 1 tsp sugar; 2 tbsp butter in the curry; double the other ingredients.</p><p><em>Want it hotter?</em> Add a dash of hot sauce or a pinch of chili flakes with the spices in step 3.</p><p><em>Chicken or turkey:</em> pat 10 oz dry, season with salt and pepper and cook with the onion until cooked through, 4–6 min (165°F inside), then carry on as above.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chickpeas', 'Pantry'), 'amount_text', '1 can'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Coconut milk', 'Pantry'), 'amount_text', '1 can'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '½ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', '1 clove'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cilantro', 'Produce'), 'amount_text', '¼ oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomato paste', 'Pantry'), 'amount_text', '1 packet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Curry powder', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Paprika', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garam masala', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', '1 veggie stock'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Yogurt', 'Dairy & eggs'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
