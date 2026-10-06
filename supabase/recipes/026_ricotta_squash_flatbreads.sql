-- =====================================================================
-- Recipe import · Ricotta and Squash Flatbreads (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Ricotta and Squash Flatbreads')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Ricotta and Squash Flatbreads',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Roast the squash.</strong> Preheat the oven to 450°F. Wash and dry all produce. On a parchment-lined baking sheet, toss the squash with 1 tbsp oil, half the garlic salt and pepper. Roast in the middle of the oven, stirring halfway, until tender and golden-brown, 20–22 min.</p></li><li><p><strong>Caramelize the onions.</strong> Meanwhile, peel, then cut the onion into ¼-inch slices. Heat a large non-stick pan over medium heat. When hot, add ½ tbsp oil, then the onions. Cook, stirring occasionally, until slightly softened, 3–4 min. Add 2 tbsp water and ½ tbsp balsamic glaze, then season with salt. Cook, stirring occasionally, until dark golden-brown, 4–6 min. Take off the heat, move the onions to a small bowl, and carefully rinse and wipe the pan clean.</p></li><li><p><strong>Season the ricotta and fry the sage.</strong> Directly in its container, season the ricotta with the rest of the garlic salt and pepper and stir. Pick the sage leaves from the stems. Line a plate with paper towels. Reheat the same pan over medium-high heat. When hot, add 2 tbsp oil, then the sage leaves. Fry until crisp, 1 min. (Tip: olive oil is lovely for frying sage.) With a slotted spoon, move the sage to the lined plate and season with salt while hot. Keep the sage oil in the pan for step 4.</p></li><li><p><strong>Assemble and bake the flatbreads.</strong> Arrange the flatbreads on another parchment-lined baking sheet. When the squash is done, brush the tops of the flatbreads with some of the sage oil. Spread the ricotta evenly over them, then top with the caramelized onions, roasted squash and Parmesan. Bake in the top of the oven until the Parmesan melts and the ricotta is heated through, 3–4 min.</p></li><li><p><strong>Make the salad.</strong> Meanwhile, halve the tomatoes. In a large bowl, whisk together 1 tbsp balsamic glaze and 1 tbsp oil. Season with salt and pepper. Add the tomatoes and the arugula and spinach mix, and toss just before serving.</p></li><li><p><strong>Finish and serve.</strong> Cut the flatbreads into wedges and divide between plates. Drizzle with the rest of the balsamic glaze, then top with the fried sage. Serve the salad alongside.</p></li></ol><p><em>For 4 people:</em> double every oil, water and balsamic amount and the other ingredients; use 2 baking sheets for the flatbreads and bake them in the top and middle of the oven.</p><p><em>Add bacon (100 g):</em> lay it in a single layer on another parchment-lined sheet and roast in the top of the oven until crispy and cooked through, 8–12 min. Crumble it over the flatbreads when you plate them.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Flatbread', 'Pantry'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Ricotta cheese', 'Dairy & eggs'), 'amount_text', '100 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parmesan cheese', 'Dairy & eggs'), 'amount_text', '¼ cup shredded'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butternut squash', 'Produce'), 'amount_text', '170 g cubes'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red onion', 'Produce'), 'amount_text', '113 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sage', 'Produce'), 'amount_text', '7 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', '113 g baby tomatoes'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Arugula & spinach mix', 'Produce'), 'amount_text', '56 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Balsamic glaze', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', '1 tsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
