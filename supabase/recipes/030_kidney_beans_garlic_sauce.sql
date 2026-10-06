-- =====================================================================
-- Recipe import · Kidney Beans in a Rich Garlic Sauce (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Kidney Beans in a Rich Garlic Sauce')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Kidney Beans in a Rich Garlic Sauce',
    p_meal_type    => 'dinner',
    p_minutes      => 60,
    p_servings     => 4,
    p_is_favourite => false,
    p_basics       => 'water, salt',
    p_method       => '<ol><li><p><strong>Cook the beans.</strong> Soak the kidney beans overnight, then drain. Pressure cook them with 4 cups water until very soft. Keep the cooking water.</p></li><li><p><strong>Bloom the cumin.</strong> Heat the ghee in a pan over medium heat. Once melted, add the cumin seeds and let them sizzle for a few seconds.</p></li><li><p><strong>Brown the onions.</strong> Add the chopped onions and sauté until golden-brown.</p></li><li><p><strong>Add garlic and ginger.</strong> Add the crushed and chopped garlic and the grated ginger. Sauté until the raw smell is gone, 2 min.</p></li><li><p><strong>Cook the tomato.</strong> Stir in the tomato puree and cook until the oil starts to separate from the mixture, 5–7 min.</p></li><li><p><strong>Add the spices.</strong> Add the coriander powder, turmeric and salt. Mix well and cook for 2 min.</p></li><li><p><strong>Simmer.</strong> Add the beans with their cooking water and stir well. Add the whole garlic cloves and the garam masala. Simmer on low heat until the gravy thickens and the flavours come together, 10–15 min.</p></li><li><p><strong>Serve.</strong> Garnish with fresh cilantro.</p></li></ol><p><em>Shortcut:</em> use canned kidney beans (drained, plus about 1 cup water) and skip step 1.</p><p><em>Source:</em> Honest Cooking, by Suchitra Vaidyaram.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Kidney beans', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Ghee', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cumin seeds', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', 'chopped'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', 'chopped, plus whole cloves'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Ginger', 'Produce'), 'amount_text', 'grated'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomato puree', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Coriander powder', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Turmeric', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garam masala', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cilantro', 'Produce'), 'amount_text', 'to garnish')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
