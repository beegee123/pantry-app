-- =====================================================================
-- Recipe import · French-Inspired Lentil Salad (with Herby Goat Cheese and Walnuts)
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- Safe to run again: if the recipe already exists, nothing changes.
-- Same pattern as 001: match each ingredient to a pantry item, or create it as In.
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
  if exists (select 1 from recipes where lower(name) = lower('French-Inspired Lentil Salad')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'French-Inspired Lentil Salad',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => true,   -- it's in the kit's favourites
    p_basics       => 'oil, water, salt, pepper',
    p_method       =>
'1. Peel, then thinly slice the shallot. Zest, then juice the lemon. Add the shallots, lemon juice, honey and 2 tbsp water to a small pot and season with salt. Bring to a simmer over medium-high heat and cook, stirring often, until the salt dissolves, 1–2 min. Take off the heat and transfer the shallots and pickling liquid to a large bowl.

2. Meanwhile, thinly slice the chives. Peel the cucumber if you like, halve it lengthwise, then cut into ¼-inch half-moons. Cut the ciabatta into ½-inch pieces. Drain and rinse the lentils in a strainer. Add the mustard, half the garlic salt and 1 tbsp oil to the bowl with the shallots, season with pepper and stir. Add the lentils and cucumber and toss to combine.

3. Heat a large non-stick pan over medium heat. Add the walnuts to the dry pan and toast, stirring often, until golden-brown, 4–5 min. (Tip: keep an eye on them so they don''t burn!) Transfer to a plate.

4. Reheat the same pan over medium. Add 1 tbsp oil, then the ciabatta, and season with the rest of the garlic salt and pepper. Cook, stirring occasionally, until golden-brown on all sides, 3–4 min. Transfer the croutons to the plate with the walnuts.

5. Meanwhile, mix the chives and lemon zest in a shallow dish and season with pepper. Roll the goat cheese into 6 equal balls, then roll each one in the chive mixture to coat completely.

6. Add the croutons and the arugula and spinach mix to the bowl with the lentils and toss. Divide between plates and top with the herby goat cheese and walnuts.

For 4 people: double the water, oil and ingredients, cook the croutons in 2 batches (1 tbsp oil each) and make 12 goat cheese balls.',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Lentils', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Shallot', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lemon', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Honey', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chives', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cucumber', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Ciabatta', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dijon mustard', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Walnuts', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Goat cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Arugula & spinach mix', 'Produce'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
