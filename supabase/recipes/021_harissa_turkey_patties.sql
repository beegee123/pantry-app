-- =====================================================================
-- Recipe import · Spicy Harissa-Glazed Turkey Patties (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Spicy Harissa-Glazed Turkey Patties')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Spicy Harissa-Glazed Turkey Patties',
    p_meal_type    => 'dinner',
    p_minutes      => 50,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook the rice.</strong> Put a rack in the top of the oven and preheat to 425°F. Wash and dry the produce. In a small pot, combine the rice, 1¼ cups water and a pinch of salt. Bring to a boil, then cover and reduce to a low simmer. Cook until the rice is tender, 15–18 min. Keep covered off the heat until ready to serve.</p></li><li><p><strong>Prep and roast the veggies.</strong> Trim, peel and cut the carrots on a diagonal into ¼-inch-thick pieces. Trim and halve the zucchini lengthwise, then cut crosswise into ½-inch-thick half-moons. Trim and thinly slice the scallions, keeping the whites and greens separate. Pick and roughly chop the dill fronds. On a baking sheet, toss the carrots and zucchini with a large drizzle of oil, salt and pepper. Roast on the top rack until browned and tender, 15–20 min.</p></li><li><p><strong>Make the patties.</strong> Meanwhile, in a large bowl, combine the turkey, scallion whites, garlic powder, panko, stock concentrate, 2 tsp curry powder, 2 tsp water, salt and pepper. (Measure the curry powder: the kit sends more.) Mix gently until combined. Form into 6 balls about 1½ inches wide. (Tip: rub your hands with a little oil first so it doesn’t stick.)</p></li><li><p><strong>Cook the patties.</strong> Heat a drizzle of oil in a large pan over medium-high heat. Add the turkey balls and gently press each one with a spatula into a ½-inch-thick patty. Cook until browned and cooked through, 2–3 min per side (165°F inside). Turn off the heat. Move the patties to a plate and tent with foil to keep warm. Let the pan cool 1 min, then wipe it out.</p></li><li><p><strong>Make the harissa glaze.</strong> Heat a drizzle of oil in the same pan over medium-low heat. Add the scallion greens and harissa powder and cook, stirring, until fragrant and the scallions are bright green, 1–2 min. Stir in the apricot jam and ⅓ cup water. Simmer, stirring occasionally, until thickened, 2–3 min. Take off the heat, stir in 1 tbsp butter until melted, and season with salt and pepper.</p></li><li><p><strong>Finish and serve.</strong> Add as much dill as you like to the roasted veggies and toss. Divide the rice and veggies between shallow bowls in separate sections. Top the rice with the patties and drizzle with the harissa glaze.</p></li></ol><p><em>For 4 people:</em> 2½ cups water for the rice; 4 tsp curry powder and 4 tsp water in the patties, formed into 12 balls (cook in batches); ⅔ cup water and 2 tbsp butter in the glaze; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground turkey', 'Meat & fish'), 'amount_text', '10 oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '¾ cup jasmine'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Carrots', 'Produce'), 'amount_text', '12 oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zucchini', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', '2 scallions'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dill', 'Produce'), 'amount_text', '¼ oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic powder', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Curry powder', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Harissa powder', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', '1 chicken stock'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Apricot jam', 'Pantry'), 'amount_text', '1 packet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
