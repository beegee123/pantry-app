-- =====================================================================
-- Recipe import · Veggie Burrito Bowls (with Carrot Mash and Roasted Brussels Sprouts)
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
  if exists (select 1 from recipes where lower(name) = lower('Veggie Burrito Bowls')) then
    insert into import_log values ('—', '—', 'Recipe already exists: nothing changed');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Veggie Burrito Bowls',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Cook the rice.</strong> Preheat the oven to 450°F. Wash and dry all produce. In a medium pot, bring 1¼ cups water and ⅛ tsp salt to a boil over high heat. Once boiling, add the rice, then reduce the heat to low. Cover and cook until the rice is tender and the liquid is absorbed, 12–14 min. Take off the heat and leave covered.</p></li><li><p><strong>Roast the sweet potatoes.</strong> Meanwhile, peel, then cut the sweet potato into ½-inch pieces. On a parchment-lined baking sheet, toss with 1 tsp enchilada spice blend and ½ tbsp oil. Season with salt and pepper. Roast in the middle of the oven, stirring halfway, until golden-brown and tender, 15–18 min.</p></li><li><p><strong>Cook the peppers.</strong> Meanwhile, core, then cut the pepper into ¼-inch pieces. Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the peppers. Cook, stirring occasionally, until tender-crisp and charred in spots, 3–4 min. Season with salt and pepper. Move the peppers to a plate to cool.</p></li><li><p><strong>Cook the Beyond Meat.</strong> Heat the same pan over medium heat. When hot, add 1 tbsp oil, then the Beyond Meat patties. Cook, breaking them into bite-sized pieces, until slightly crispy, 5–6 min. Add the rest of the enchilada spice blend, the chipotle sauce and ⅓ cup water. Cook, stirring occasionally, until thickened, 2–3 min. Take the pan off the heat.</p></li><li><p><strong>Make the DIY salsa.</strong> Meanwhile, cut the tomato into ½-inch pieces. Thinly slice the green onion. Zest, then juice half the lime. Cut any remaining lime into wedges. In a medium bowl, combine the tomatoes, half the peppers, half the green onions, half the lime juice and ½ tsp sugar. Season with salt and pepper and stir.</p></li><li><p><strong>Finish and serve.</strong> In a small bowl, stir together the sour cream, lime zest and the rest of the lime juice. Season with salt and pepper. Fluff the rice with a fork, then stir in the rest of the peppers and green onions. Divide the rice between bowls and top with the sweet potatoes, Beyond Meat and salsa. Dollop with the lime crema and squeeze a lime wedge over the top, if you like.</p></li></ol><p><em>For 4 people:</em> ¼ tsp salt for the rice; 1 tbsp oil each for the sweet potatoes and peppers, 2 tbsp for the Beyond Meat; ⅔ cup water in step 4; the whole lime juiced; 1 tsp sugar; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Beyond Meat', 'Meat & fish'), 'amount_text', '2 patties'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '¾ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sweet potatoes', 'Produce'), 'amount_text', '170 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '160 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', '80 g Roma'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lime', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Enchilada spice blend', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chipotle sauce', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', '3 tbsp')
    )
  );
end;
$$;

-- What happened: one row per ingredient.
select * from import_log;
