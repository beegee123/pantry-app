-- =====================================================================
-- Recipe import · Garlic Bocconcini Bites (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Garlic Bocconcini Bites')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Garlic Bocconcini Bites',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Preheat the oven to 450°F. Wash and dry all produce. Halve the tomatoes. Core, then cut the pepper into ½-inch pieces. Cut the bocconcini in half, then pat dry with paper towels. Season with salt and pepper.</p></li><li><p><strong>Toast the pine nuts.</strong> Heat a large non-stick pan over medium heat. When hot, add the pine nuts to the dry pan. Toast, stirring often, until golden-brown, 4–5 min (watch them so they don’t burn). Move to a plate.</p></li><li><p><strong>Toast the garlic bread.</strong> Halve the ciabatta and arrange cut side up on an unlined baking sheet. In a small bowl, combine half the garlic puree and 2 tbsp oil. Season with salt and pepper. Spread the garlic oil on the ciabatta. Toast in the middle of the oven until golden-brown, 3–5 min (watch it so it doesn’t burn).</p></li><li><p><strong>Coat the bocconcini.</strong> In a medium bowl, toss the bocconcini with the rest of the garlic puree. Heat the same pan over medium heat. When hot, add 1 tbsp oil, then the breadcrumbs. Cook, stirring constantly, until golden, 2–3 min. Take the pan off the heat, add the bocconcini, then shake the pan and toss to coat.</p></li><li><p><strong>Make the salad.</strong> In a large bowl, whisk together the vinegar, half the balsamic glaze and 1 tbsp oil. Season with salt and pepper. Add the tomatoes, spring mix and peppers, then toss.</p></li><li><p><strong>Finish and serve.</strong> Divide the salad between plates and top with the bocconcini and pine nuts. Drizzle the rest of the balsamic glaze over the top. Serve the garlic bread alongside.</p></li></ol><p><em>For 4 people:</em> double every oil amount and the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Bocconcini', 'Dairy & eggs'), 'amount_text', '100 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Ciabatta rolls', 'Pantry'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Italian breadcrumbs', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', '113 g baby tomatoes'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spring mix', 'Produce'), 'amount_text', '113 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '160 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic puree', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pine nuts', 'Pantry'), 'amount_text', '28 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Balsamic glaze', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Balsamic vinegar', 'Pantry'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
