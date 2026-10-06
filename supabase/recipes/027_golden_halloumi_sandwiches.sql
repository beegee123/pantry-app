-- =====================================================================
-- Recipe import · Golden Halloumi Sandwiches (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Golden Halloumi Sandwiches')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Golden Halloumi Sandwiches',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Roast the potato wedges.</strong> Preheat the oven to 450°F. Wash and dry all produce. Cut the potatoes into ½-inch wedges. On a parchment-lined baking sheet, toss them with half the smoked paprika-garlic blend and 1 tbsp oil. Season with salt and pepper. Roast in the middle of the oven, flipping halfway, until golden-brown, 25–28 min.</p></li><li><p><strong>Caramelize the onions.</strong> Meanwhile, peel, then cut the onion into ¼-inch slices. Heat a large non-stick pan over medium heat. When hot, add 2 tsp oil, then the onions. Cook, stirring occasionally, until softened, 3–4 min. Add 1 tsp sugar and season with salt. Cook, stirring occasionally, until dark golden-brown, 6–8 min. Take the pan off the heat, add the vinegar and stir until the onions are coated, 1 min. Move to a plate and set aside.</p></li><li><p><strong>Prep the halloumi.</strong> Meanwhile, carefully slice the halloumi in half, parallel to the cutting board. Rinse it in cold water, then pat dry with paper towels. In a small bowl, stir together the breadcrumbs and 1 tsp oil. Arrange the halloumi on another parchment-lined baking sheet. Spread ½ tbsp mayo over the top of each slice, then top with the breadcrumb mixture, pressing gently so it sticks.</p></li><li><p><strong>Roast the halloumi.</strong> Roast in the top of the oven until the breadcrumbs are golden, 8–10 min.</p></li><li><p><strong>Toast the buns and make the aioli.</strong> Halve the buns. Arrange them directly on the top rack of the oven, cut side up, and toast until golden-brown, 2–3 min (watch them so they don’t burn). Meanwhile, in another small bowl, stir together the rest of the mayo and the rest of the smoked paprika-garlic blend. Season with pepper.</p></li><li><p><strong>Finish and serve.</strong> Spread some smoky aioli onto the top buns. Stack the caramelized onions, spring mix and halloumi on the bottom buns and close with the top buns. Divide the sandwiches and potato wedges between plates, with the rest of the smoky aioli alongside for dipping.</p></li></ol><p><em>For 4 people:</em> double every oil and sugar amount, and the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Halloumi cheese', 'Dairy & eggs'), 'amount_text', '200 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Brioche buns', 'Pantry'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', '460 g russet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', '113 g yellow onion'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spring mix', 'Produce'), 'amount_text', '28 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Italian breadcrumbs', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', '4 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Smoked paprika-garlic blend', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Balsamic vinegar', 'Pantry'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
