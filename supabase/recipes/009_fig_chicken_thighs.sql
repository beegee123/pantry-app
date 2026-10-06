-- =====================================================================
-- Recipe import · Seared Chicken Thighs in Fig Sauce (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Seared Chicken Thighs in Fig Sauce')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Seared Chicken Thighs in Fig Sauce',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Preheat the oven to 450°F. Wash and dry all produce. Cut the potatoes and sweet potatoes into ½-inch pieces. Cut the broccoli into bite-size pieces. Strip 1 tbsp thyme leaves from the stems, then finely chop.</p></li><li><p><strong>Roast the potatoes.</strong> On an unlined baking sheet, toss the potatoes and sweet potatoes with half the garlic puree, half the thyme and 1 tbsp oil. Season with salt and pepper. Roast in the middle of the oven, stirring halfway, until golden, 22–24 min.</p></li><li><p><strong>Roast the broccoli.</strong> Meanwhile, on another unlined baking sheet, toss the broccoli with 1 tbsp oil and the rest of the garlic puree. Season with salt and pepper. Roast in the top of the oven until tender-crisp, 13–15 min.</p></li><li><p><strong>Season the chicken.</strong> Pat the chicken dry with paper towels. Season both sides with salt, pepper and the rest of the thyme.</p></li><li><p><strong>Cook the chicken.</strong> Heat a large non-stick pan over medium-high heat. When hot, add 1 tbsp oil, then the chicken. Cook until golden and cooked through, 3–4 min per side (165°F inside). When almost cooked, add half the fig spread and 2 tbsp butter, and baste the chicken until sticky, 1–2 min.</p></li><li><p><strong>Serve.</strong> Divide the chicken, potatoes and broccoli between plates. Spoon the remaining fig spread over the chicken.</p></li></ol><p><em>For 4 people:</em> double the thyme (2 tbsp), every oil amount and the butter (4 tbsp), and the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken thighs', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sweet potatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broccoli', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Thyme', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic puree', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Fig spread', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
