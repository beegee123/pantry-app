-- =====================================================================
-- Recipe import · Hearty Turkey and Black Bean Chili (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Hearty Turkey and Black Bean Chili')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Hearty Turkey and Black Bean Chili',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Roast the sweet potatoes.</strong> Preheat the oven to 425°F. Peel, then cut the sweet potatoes into ½-inch pieces. On an unlined baking sheet, toss them with half the Mexican seasoning and ½ tbsp oil. Season with salt and pepper. Roast in the middle of the oven, flipping halfway, until tender and golden-brown, 18–20 min.</p></li><li><p><strong>Brown the turkey.</strong> Heat a large pot over medium-high heat. When hot, add ½ tbsp oil, then the turkey. Cook, breaking it into smaller pieces, until no pink remains, 4–5 min (165°F inside). Add the rest of the Mexican seasoning and the Tex-Mex paste. Cook, stirring often, until fragrant and well combined, 1–2 min. Season with pepper.</p></li><li><p><strong>Simmer the chili.</strong> Add the broth concentrate, the black beans with their liquid, the crushed tomatoes and ¼ tsp sugar. (Tip: for a looser chili, add water 1 tbsp at a time.) Reduce the heat to medium-low and simmer, stirring occasionally, until slightly thickened, 6–9 min. Season with salt and pepper.</p></li><li><p><strong>Serve.</strong> Stir the sweet potatoes into the chili. Divide between bowls, top with the cheese and dollop the sour cream over the top.</p></li></ol><p><em>For 4 people:</em> 1 tbsp oil for the sweet potatoes and 1 tbsp for the turkey; ½ tsp sugar; double the other ingredients.</p><p><em>Ground beef</em> cooks exactly the same way as turkey.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground turkey', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sweet potatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Black beans', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Crushed tomatoes', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mexican seasoning', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tex-Mex paste', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cheddar cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', '')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
