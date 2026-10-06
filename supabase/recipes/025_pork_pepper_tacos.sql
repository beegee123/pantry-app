-- =====================================================================
-- Recipe import · Pork and Pepper Tacos (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Pork and Pepper Tacos')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Pork and Pepper Tacos',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Roast the veggies.</strong> Preheat the oven to 450°F. Wash and dry all produce. Core, then cut the pepper into ¼-inch slices. Peel, then cut the onion into ¼-inch slices. On an unlined baking sheet, toss the peppers, three-quarters of the onions, half the Mexican seasoning, 1 tbsp oil and ⅛ tsp chipotle powder (see the heat guide below). Season with salt and pepper. Roast in the middle of the oven, stirring halfway, until tender, 12–14 min.</p></li><li><p><strong>Make the salsa fresca.</strong> Meanwhile, zest, then juice half the lime. Cut any remaining lime into wedges. Cut the tomatoes into ¼-inch pieces. Finely chop the rest of the onions. In a small bowl, combine the tomatoes, chopped onions, ½ tsp sugar, ½ tbsp lime juice and ½ tbsp oil. Season with salt and pepper and set aside.</p></li><li><p><strong>Make the lime crema.</strong> In another small bowl, stir together the sour cream and lime zest. Season with salt and pepper and set aside.</p></li><li><p><strong>Cook the pork.</strong> Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the pork. Cook, breaking it into smaller pieces, until no pink remains, 4–5 min (165°F inside). Carefully drain and discard the excess fat. Add the rest of the Mexican seasoning and cook, stirring often, until fragrant, 1 min. Season with pepper.</p></li><li><p><strong>Warm the tortillas.</strong> Meanwhile, wrap the tortillas in foil and warm them in the top of the oven, 4–5 min. (You can skip this if you don’t want them warm.)</p></li><li><p><strong>Finish and serve.</strong> Top the tortillas with the pork and veggies, then spoon the salsa fresca over the top. Dollop with the lime crema and sprinkle with the cheese. Squeeze a lime wedge over the top, if you like.</p></li></ol><p><em>Heat guide (chipotle powder):</em> mild ⅛ tsp, medium ¼ tsp, spicy ½ tsp, extra-spicy 1 tsp.</p><p><em>For 4 people:</em> the whole lime juiced; 2 tbsp oil for the veggies; 1 tsp sugar, 1 tbsp lime juice and 1 tbsp oil in the salsa; 1 tbsp oil for the pork; double the other ingredients.</p><p><em>Ground turkey</em> cooks the same way as the pork; no need to drain the fat.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground pork', 'Meat & fish'), 'amount_text', '250 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Flour tortillas', 'Pantry'), 'amount_text', '6'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', '160 g Roma'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '160 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', '113 g yellow onion'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lime', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cheddar cheese', 'Dairy & eggs'), 'amount_text', '½ cup shredded'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', '6 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mexican seasoning', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chipotle powder', 'Pantry'), 'amount_text', '⅛ tsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
