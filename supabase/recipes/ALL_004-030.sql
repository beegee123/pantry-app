-- =====================================================================
-- Recipe import · ALL recipes 004–030 in one go (27 recipes)
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- Safe to run again: recipes that already exist are skipped.
-- It runs as one unit: if anything fails, nothing is saved.
-- (The individual files 004–030 do exactly the same thing, one at a time.)
-- =====================================================================

create temp table if not exists import_log (
  n serial, recipe text, ingredient text, pantry_item text, result text
);
truncate import_log;
create temp table if not exists import_current (recipe text);
truncate import_current;

-- Find the pantry item for an ingredient, or create it (same rules as the single files).
create or replace function pg_temp.pantry_item(p_name text, p_category text)
returns uuid
language plpgsql
as $$
declare
  v_id   uuid;
  v_name text;
  v_key  text := lower(trim(p_name));
  v_rec  text := (select recipe from import_current limit 1);
begin
  select id, name into v_id, v_name
  from items
  where lower(name) in (v_key, v_key || 's', regexp_replace(v_key, 's$', ''))
     or lower(name) like v_key || ',%'
  order by lower(name) = v_key desc,
           lower(name) like '%,%'
  limit 1;

  if v_id is not null then
    insert into import_log (recipe, ingredient, pantry_item, result) values (v_rec, p_name, v_name, 'matched existing item');
    return v_id;
  end if;

  insert into items (name, category_id, status) values (p_name, category_id_for(p_category), 'in')
  returning id into v_id;
  insert into import_log (recipe, ingredient, pantry_item, result) values (v_rec, p_name, p_name, 'NEW item in ' || p_category || ' (In)');
  return v_id;
end;
$$;


-- ── 004 · Smart Tex-Mex Pork Chop Bowls (with Roasted Pepper Salsa) ──
truncate import_current; insert into import_current values ('Smart Tex-Mex Pork Chop Bowls (with Roasted Pepper Salsa)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Smart Tex-Mex Pork Chop Bowls')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Smart Tex-Mex Pork Chop Bowls',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Make bulgur.</strong> Add ⅔ cup water and ½ tsp salt to a medium pot. Cover and bring to a boil over high heat. Once boiling, stir in the bulgur until the water returns to a boil, then cover and remove from heat. Let stand until the bulgur is tender and the liquid is absorbed, 16–18 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, core the hot pepper, then cut into ¼-inch pieces (tip: wear gloves). Cut the tomatoes into ¼-inch pieces. Roughly chop the cilantro. Zest, then juice the lime. Pat the pork chops dry with paper towels, then cut into ¼-inch slices.</p></li><li><p><strong>Char the hot pepper.</strong> Heat a large non-stick pan over medium-high heat. When hot, add the pepper to the dry pan. Cover and cook, flipping halfway through, until dark golden, 4–5 min. Transfer to a medium bowl.</p></li><li><p><strong>Cook the pork.</strong> Add ½ tbsp oil to the same pan, then the pork. Pan-fry until golden and cooked through, 3–4 min (145°F inside). Remove the pan from the heat, then add the Tex-Mex paste, ¼ tsp sugar and 1 tbsp water. Cook, stirring often, until the pork is coated, 1 min. Remove from the heat.</p></li><li><p><strong>Make the salsa.</strong> Meanwhile, add the tomatoes, lime juice and half the cilantro to the bowl with the pepper. Season with salt and pepper and stir to combine.</p></li><li><p><strong>Finish and serve.</strong> Fluff the bulgur with a fork and stir in the rest of the cilantro. In a small bowl, stir the sour cream and lime zest together and season with salt and pepper. Divide the bulgur between bowls, top with the pork, then the salsa and lime crema. Sprinkle with feta.</p></li></ol><p><em>For 4 people:</em> 1 cup water and 1 tsp salt for the bulgur; cook the pork in 2 batches with ½ tbsp oil each; ½ tsp sugar and 2 tbsp water for the sauce; double the ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Pork chops', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bulgur', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Hot pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cilantro', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lime', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tex-Mex paste', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '')
    )
  );
end;
$$;

-- ── 005 · Cal Smart Mexi-Cali Shrimp Bowls (with Warm Bulgur Salad and Baja Sauce) ──
truncate import_current; insert into import_current values ('Cal Smart Mexi-Cali Shrimp Bowls (with Warm Bulgur Salad and Baja Sauce)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Cal Smart Mexi-Cali Shrimp Bowls')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Cal Smart Mexi-Cali Shrimp Bowls',
    p_meal_type    => 'dinner',
    p_minutes      => 20,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Make bulgur.</strong> Combine the stock powder and ⅔ cup water in a medium pot. Cover and bring to a boil over high heat. Once boiling, stir in the bulgur and return to a boil, then cover and remove from heat. Let stand until the bulgur is tender and the liquid is absorbed, 16–18 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, roughly chop the spinach. Thinly slice the green onions. Halve the tomatoes. Zest, then juice half the lemon; cut the rest into wedges. Add the tomatoes to a medium bowl, squeeze a lemon wedge over them and toss to coat.</p></li><li><p><strong>Make the Baja sauce.</strong> In a small bowl, combine the mayo, sour cream, half the chipotle sauce, half the lemon juice and ½ tsp Southwest spice blend. Season with salt and pepper and stir to combine.</p></li><li><p><strong>Cook the shrimp.</strong> Heat a large non-stick pan over medium-high heat. While it heats, drain and rinse the shrimp in a strainer, then pat dry with paper towels. Transfer to another medium bowl, season with salt, pepper and the rest of the spice blend, and toss to coat. When the pan is hot, add ½ tbsp oil, then the shrimp. Cook, stirring occasionally, until the shrimp just turn pink, 2–3 min. Remove the pan from the heat, add the rest of the chipotle sauce and stir to coat.</p></li><li><p><strong>Make the bulgur salad.</strong> Add the lemon zest to the pot with the bulgur and fluff with a fork. Add the spinach, the rest of the lemon juice and half the green onions. Drizzle ½ tbsp oil over the top, season with pepper and toss to combine.</p></li><li><p><strong>Finish and serve.</strong> Divide the bulgur salad between bowls. Top with the shrimp and tomatoes, dollop the Baja sauce over and sprinkle with the rest of the green onions. Squeeze a lemon wedge over the top, if you like.</p></li></ol><p><em>For 4 people:</em> 1 cup water for the bulgur; 1 tsp spice blend in the sauce; 1 tbsp oil for the shrimp and 1 tbsp for the salad; double the ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Shrimp', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bulgur', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Stock powder', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lemon', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chipotle sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Southwest spice blend', 'Pantry'), 'amount_text', '')
    )
  );
end;
$$;

-- ── 006 · Smart Pork, Spinach and Pepper Curry (with Buttery Bulgur) ──
truncate import_current; insert into import_current values ('Smart Pork, Spinach and Pepper Curry (with Buttery Bulgur)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Smart Pork, Spinach and Pepper Curry')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Smart Pork, Spinach and Pepper Curry',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook bulgur.</strong> Add ⅔ cup water and ½ tsp salt to a medium pot. Cover and bring to a boil over high heat. Once boiling, stir in the bulgur until the water returns to a boil, then cover and remove from heat. Let stand until the bulgur is tender and the liquid is absorbed, 16–18 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, core, then cut the pepper into ¼-inch pieces. Roughly chop the spinach. Thinly slice the green onions.</p></li><li><p><strong>Cook the pork.</strong> Heat a large non-stick pan over medium-high heat. When hot, add the pork to the dry pan. Cook, breaking it up into smaller pieces, until no pink remains, 3–4 min. Season with salt and pepper. Add the pepper and cook, stirring occasionally, until tender-crisp, 3–4 min.</p></li><li><p><strong>Make the sauce.</strong> Reduce the heat to medium. Add the Indian spice mix and curry paste and cook, stirring constantly, until fragrant, 1 min. Add ½ cup water and cook, stirring occasionally, until slightly thickened, 1–2 min. Add the spinach and 1 tbsp butter and stir until the spinach wilts, 30 sec. Season with salt and pepper.</p></li><li><p><strong>Finish and serve.</strong> Fluff the bulgur with a fork, then stir in 1 tbsp butter and half the green onions. Divide the bulgur between bowls and top with the pork curry. Sprinkle with the rest of the green onions.</p></li></ol><p><em>For 4 people:</em> 1 cup water and 1 tsp salt for the bulgur; 1 cup water and 2 tbsp butter for the sauce; 2 tbsp butter for the bulgur; double the ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground pork', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bulgur', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Indian spice mix', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Curry paste', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- ── 007 · Harvest Salmon (with Roasted Veggies and Herby Pesto Orzo) ──
truncate import_current; insert into import_current values ('Harvest Salmon (with Roasted Veggies and Herby Pesto Orzo)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Harvest Salmon')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Harvest Salmon',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Start the orzo water and marinate the tomatoes.</strong> Preheat the oven to 450°F. Add 8 cups water and 1 tsp salt to a medium pot, cover and bring to a boil over high heat. Meanwhile, halve the tomatoes, roughly chop the parsley, and peel, then mince or grate the garlic. In a large bowl, combine the tomatoes, pesto, half the vinegar, half the garlic salt, half the garlic and ¼ tsp sugar. Season with salt and pepper and toss.</p></li><li><p><strong>Prep the veggies.</strong> Cut the zucchini into ½-inch rounds. Core, then cut the pepper into 1-inch pieces. Peel, then cut the onion into ½-inch slices. On a parchment-lined baking sheet, toss the zucchini, pepper, onion, Zesty Garlic Blend and 1 tbsp oil. Season with salt and pepper and spread in a single layer.</p></li><li><p><strong>Roast the veggies.</strong> Roast in the middle of the oven, tossing halfway through, until tender, 16–20 min.</p></li><li><p><strong>Cook the orzo.</strong> Add the orzo to the boiling water and cook, uncovered, stirring occasionally, until tender, 10–12 min. Drain (rinse under cool water if you’d like a cold orzo salad), then add to the bowl with the marinated tomatoes and toss.</p></li><li><p><strong>Cook the salmon.</strong> Meanwhile, heat a large non-stick pan over medium-high heat. Pat the salmon dry and season with the rest of the garlic salt and pepper. When the pan is hot, add ½ tbsp oil, then the salmon. Pan-fry until golden-brown and cooked through, 3–5 min per side (145°F inside).</p></li><li><p><strong>Make the aioli and serve.</strong> In a small bowl, combine the mayo with as much of the remaining garlic as you like, and season with salt and pepper. Divide the orzo between plates and top with the veggies and salmon. Dollop the aioli over the salmon or serve it alongside. Sprinkle with parsley.</p></li></ol><p><em>For 4 people:</em> the same 8 cups water; use all the vinegar; roast on two baking sheets (half the Zesty Garlic Blend and 1 tbsp oil on each) in the middle and bottom of the oven, swapping them halfway; 1 tbsp oil for the salmon; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Salmon fillets', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Orzo', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pesto', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parsley', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zucchini', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red onion', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zesty garlic blend', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', '')
    )
  );
end;
$$;

-- ── 008 · Smart Smoky Mustard Chicken (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Smart Smoky Mustard Chicken (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Smart Smoky Mustard Chicken')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Smart Smoky Mustard Chicken',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Roast the Brussels sprouts.</strong> Preheat the oven to 450°F. Halve the Brussels sprouts (quarter any large ones). On a parchment-lined baking sheet, toss them with 1½ tbsp oil, pepper and half the garlic salt. Roast in the top of the oven until tender, 16–20 min.</p></li><li><p><strong>Boil the carrots.</strong> Meanwhile, peel, then cut the carrots into ¼-inch rounds. Add to a medium pot with enough water to cover by about 1 inch. Cover and bring to a boil over high heat, then reduce the heat to medium-high and simmer, uncovered, until fork-tender, 14–15 min.</p></li><li><p><strong>Sear the chicken.</strong> Meanwhile, pat the chicken dry with paper towels and season with pepper and the rest of the garlic salt. Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the chicken (don’t overcrowd the pan; cook in 2 batches if needed). Cook until golden, 1–2 min per side, then remove from the heat.</p></li><li><p><strong>Roast the chicken.</strong> Transfer the chicken to another parchment-lined baking sheet and roast in the middle of the oven until cooked through, 10–12 min (165°F inside). Let it rest on a plate for 3–5 min.</p></li><li><p><strong>Make the sauce.</strong> Meanwhile, peel, then cut the shallot into ½-inch pieces, and peel, then mince or grate the garlic. In a small bowl, combine the chipotle sauce, half the mustard, the broth concentrate and ¼ cup water. Reheat the pan from step 3 over medium heat. When hot, add ½ tbsp oil, then the shallot and garlic, and cook, stirring often, until fragrant, 30 sec. Add the sauce mixture and cook, stirring often, until slightly thickened, 1–3 min.</p></li><li><p><strong>Mash and serve.</strong> Thinly slice the chicken. Drain the carrots and return them to the pot, off the heat. Mash in 2 tbsp butter and season with salt and pepper. Divide the chicken, Brussels sprouts and mash between plates, and spoon the sauce over the chicken and sprouts.</p></li></ol><p><em>For 4 people:</em> 3 tbsp oil for the sprouts; 1 tbsp oil each for the chicken and the sauce; all the mustard and ½ cup water in the sauce; 4 tbsp butter in the mash; double the other ingredients.</p><p><em>Chicken thighs</em> cook exactly the same way as breasts.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Brussels sprouts', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Carrots', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Shallot', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chipotle sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dijon mustard', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- ── 009 · Seared Chicken Thighs in Fig Sauce (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Seared Chicken Thighs in Fig Sauce (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Seared Chicken Thighs in Fig Sauce')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 010 · One-Pot Southwest Beef and Cavatappi (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('One-Pot Southwest Beef and Cavatappi (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('One-Pot Southwest Beef and Cavatappi')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'One-Pot Southwest Beef and Cavatappi',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Wash and dry all produce. Core, then cut the pepper into ½-inch pieces. Peel, then cut half the onion into ½-inch pieces. Peel, then mince or grate the garlic.</p></li><li><p><strong>Cook the peppers.</strong> Heat a large pot over medium-high heat. When hot, add ½ tbsp oil, then the peppers. Cook, stirring occasionally, until tender-crisp, 3–4 min. Season with salt and pepper. Move the peppers to a plate and set aside.</p></li><li><p><strong>Brown the beef.</strong> Reheat the same pot over medium-high heat. When hot, add the beef and onions to the dry pot. Cook, breaking the beef into smaller pieces, until no pink remains, 4–5 min (160°F inside). Carefully drain and discard excess fat, if you like.</p></li><li><p><strong>Cook the pasta.</strong> Add the Tex-Mex paste, garlic, marinara sauce, broth concentrate, 2¾ cups water and ½ tsp salt to the pot. Stir to combine, then bring to a boil over high heat. Once boiling, stir in the cavatappi and reduce the heat to medium. Simmer uncovered, stirring often so it doesn’t stick, until the cavatappi is tender, 12–16 min. (Tip: if the pasta is sticking too much, add more water, ¼ cup at a time, and scrape up anything stuck to the bottom of the pot.)</p></li><li><p><strong>Add the veggies.</strong> Add the peppers and spinach to the pot. Cook, stirring often, until the spinach wilts, 1–2 min. Season with pepper.</p></li><li><p><strong>Serve.</strong> Divide the beef and cavatappi between bowls. Sprinkle the cheese over the top.</p></li></ol><p><em>For 4 people:</em> the whole onion; 1 tbsp oil; 5 cups water and 1 tsp salt in step 4; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground beef', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cavatappi', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tex-Mex paste', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Marinara sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Monterey Jack cheese', 'Dairy & eggs'), 'amount_text', '')
    )
  );
end;
$$;

-- ── 011 · Cheesy Stuffed Chicken and Sweet Potato Mash (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Cheesy Stuffed Chicken and Sweet Potato Mash (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Cheesy Stuffed Chicken and Sweet Potato Mash')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Cheesy Stuffed Chicken and Sweet Potato Mash',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Boil the sweet potatoes.</strong> Preheat the oven to 425°F. Wash and dry all produce. Peel, then cut the sweet potatoes into ½-inch pieces. Add them to a large pot with 1 tsp salt and enough water to cover by 1–2 inches. Cover and bring to a boil over high heat. Once boiling, reduce the heat to medium and simmer uncovered until fork-tender, 10–12 min. Drain and return to the same pot, off the heat.</p></li><li><p><strong>Stuff the chicken.</strong> Meanwhile, thinly slice the chives. In a small bowl, mix the cheddar, cream cheese, half the crispy shallots and half the chives. Pat the chicken dry with paper towels. Carefully slice into the centre of each breast, parallel to the cutting board, leaving 1 inch intact on the other end. Open each breast like a book and season inside with ¼ tsp garlic salt and pepper. Divide the cheese filling between the breasts, then fold closed. Season the outside with ¼ tsp garlic salt and pepper.</p></li><li><p><strong>Sear and bake the chicken.</strong> Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the chicken (don’t overcrowd the pan; cook in 2 batches if needed). Cook until golden, 1–2 min per side. Move the chicken to a parchment-lined baking sheet and bake in the middle of the oven until cooked through, 14–16 min (165°F inside).</p></li><li><p><strong>Make the dressing.</strong> Meanwhile, in a large bowl, whisk together the vinegar, 1 tbsp oil and ½ tsp sugar. Season with salt and pepper, then set aside.</p></li><li><p><strong>Mash.</strong> Mash 2 tbsp butter into the sweet potatoes until smooth. Stir in the rest of the chives. Season with salt and pepper.</p></li><li><p><strong>Serve.</strong> When the chicken is done, let it rest on a plate for 3–5 min. Add the spring mix to the bowl with the dressing and toss. Divide the mash, chicken and salad between plates. Drizzle any juices from the baking sheet over the chicken, and sprinkle the rest of the crispy shallots over the salad.</p></li></ol><p><em>For 4 people:</em> same 1 tsp salt for the potatoes; ½ tsp garlic salt inside and ½ tsp outside the chicken; 1 tbsp oil to sear; 2 tbsp oil and 1 tsp sugar in the dressing; 4 tbsp butter in the mash; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sweet potatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Chives', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cheddar cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cream cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Crispy shallots', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spring mix', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- ── 012 · Crispy Chicken Parmigiana (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Crispy Chicken Parmigiana (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Crispy Chicken Parmigiana')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Crispy Chicken Parmigiana',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Bread the chicken.</strong> Preheat the broiler to high. Wash and dry all produce. In a shallow dish, stir together the panko and half the Parmesan. Pat the chicken dry with paper towels. Carefully slice into the centre of each breast, parallel to the cutting board, leaving ½ inch intact on the other end, and open it like a book. Season both sides with salt, pepper and half the Italian seasoning. Coat each breast all over with mayo, then, one at a time, press both sides into the panko mixture to coat completely.</p></li><li><p><strong>Pan-fry the chicken.</strong> Heat a large non-stick pan over medium heat. When hot, add 1 tbsp oil, then the chicken. Pan-fry until golden-brown, 3–4 min per side. Move the chicken to a foil-lined baking sheet. Carefully wipe the pan clean.</p></li><li><p><strong>Broil.</strong> Spoon the marinara sauce over the chicken, then sprinkle with the rest of the Parmesan. Broil in the middle of the oven until the cheese is golden-brown and the chicken is cooked through, 4–6 min (165°F inside).</p></li><li><p><strong>Cook the veggies.</strong> Meanwhile, core, then cut the pepper into ¼-inch slices. Peel, then cut half the onion into ¼-inch slices. Heat the same pan over medium-high heat. When hot, add ½ tbsp oil, then the peppers, onions and the rest of the Italian seasoning. Season with salt and pepper. Cook, stirring occasionally, until tender, 3–4 min. Move to a plate to cool slightly.</p></li><li><p><strong>Make the dressing.</strong> Meanwhile, in a large bowl, whisk together the Dijon, vinegar, ½ tsp sugar and 1 tbsp oil. Season with salt and pepper.</p></li><li><p><strong>Serve.</strong> Add the spinach, peppers and onions to the bowl with the dressing and toss. Divide the chicken parmigiana and salad between plates.</p></li></ol><p><em>For 4 people:</em> pan-fry the chicken in batches, 1 tbsp oil per batch; the whole onion and 1 tbsp oil for the veggies; 1 tsp sugar and 2 tbsp oil in the dressing; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parmesan cheese', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Italian seasoning', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Marinara sauce', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red onion', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dijon mustard', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '')
    )
  );
end;
$$;

-- ── 013 · Fattoush Salad and Roasted Chickpeas (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Fattoush Salad and Roasted Chickpeas (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Fattoush Salad and Roasted Chickpeas')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Fattoush Salad and Roasted Chickpeas',
    p_meal_type    => 'dinner',
    p_minutes      => 30,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Prep the chickpeas and garlic.</strong> Preheat the oven to 425°F. Wash and dry all produce. Drain and rinse the chickpeas, then pat dry with paper towels. On a parchment-lined baking sheet, toss the chickpeas with half the shawarma spice blend and 2 tbsp oil. Season with salt and pepper. Peel the garlic, toss the cloves with ½ tbsp oil on a small sheet of foil, wrap tightly and put it on the same baking sheet.</p></li><li><p><strong>Roast the chickpeas.</strong> Roast in the bottom of the oven until the chickpeas are almost crispy, 10–12 min. Carefully take the sheet out, stir the chickpeas, then cover loosely with foil (or another baking sheet). Return to the oven and roast until crispy, 6–8 min.</p></li><li><p><strong>Bake the pitas.</strong> Meanwhile, cut the pitas into 1-inch pieces. On another parchment-lined baking sheet, toss them with the rest of the shawarma spice blend and 1 tbsp oil. Season with salt and pepper. Bake in the top of the oven until golden-brown and crispy, 5–6 min.</p></li><li><p><strong>Prep the veggies.</strong> Meanwhile, halve the tomatoes. Thinly slice the green onions. Core, then cut the pepper into ½-inch pieces. Drain, then roughly chop the olives. Roughly chop the parsley.</p></li><li><p><strong>Make the dressing.</strong> Put the roasted garlic cloves in a large bowl and mash with a fork. Add the vinegar, 1 tsp sugar, 2 tbsp oil and 1 tbsp water. Season with salt and pepper, then whisk.</p></li><li><p><strong>Toss and serve.</strong> Add the roasted chickpeas, green onions, tomatoes, peppers, parsley, olives and half the feta to the bowl with the dressing. Toss to coat. Divide the spiced pitas between bowls, top with the chickpea mixture and sprinkle the rest of the feta over the top.</p></li></ol><p><em>For 4 people:</em> double every oil, sugar and water amount, and the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chickpeas', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pitas', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Shawarma spice blend', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Olives', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parsley', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '')
    )
  );
end;
$$;

-- ── 014 · Carb Smart Cobb Salad (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Carb Smart Cobb Salad (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Carb Smart Cobb Salad')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Carb Smart Cobb Salad',
    p_meal_type    => 'dinner',
    p_minutes      => 20,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'water, salt, pepper',
    p_method       => '<ol><li><p><strong>Boil the eggs.</strong> Wash and dry all produce. Bring 4 cups warm water to a boil in a small pot over high heat. Once boiling, reduce the heat to medium-high and lower the eggs in with a spoon. Cook for 7 min for a runny yolk or 9 min for a set yolk. Drain and rinse under cold water until cool enough to peel, 30 sec. Peel, then halve the eggs and season with salt and pepper.</p></li><li><p><strong>Prep the produce.</strong> Meanwhile, cut the tomato into ¼-inch pieces. Core, then cut the apple into ¼-inch slices.</p></li><li><p><strong>Cut the bacon.</strong> Cut the bacon crosswise into ¼-inch strips.</p></li><li><p><strong>Cook the bacon.</strong> Heat a large non-stick pan over medium heat. When hot, add the bacon. Cook, stirring often, until crispy, 7–10 min. Take the pan off the heat. With a slotted spoon, move the bacon to a paper-towel-lined plate. Keep 1 tbsp bacon fat in a large bowl and carefully discard the rest.</p></li><li><p><strong>Toss the salad.</strong> Add the bacon, apples, tomatoes, dried cranberries, spinach and vinegar to the bowl with the bacon fat. Season with salt and pepper, then toss.</p></li><li><p><strong>Serve.</strong> Divide the salad and eggs between plates. Drizzle the ranch dressing over the top and sprinkle with the feta and pepitas.</p></li></ol><p><em>For 4 people:</em> 8 cups water for the eggs; keep 2 tbsp bacon fat; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Eggs', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bacon', 'Meat & fish'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Apples', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dried cranberries', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Ranch dressing', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pepitas', 'Pantry'), 'amount_text', '')
    )
  );
end;
$$;

-- ── 015 · Hearty Turkey and Black Bean Chili (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Hearty Turkey and Black Bean Chili (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Hearty Turkey and Black Bean Chili')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 016 · Seasoned Shrimp and Roasted Potatoes (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Seasoned Shrimp and Roasted Potatoes (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Seasoned Shrimp and Roasted Potatoes')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Seasoned Shrimp and Roasted Potatoes',
    p_meal_type    => 'dinner',
    p_minutes      => 25,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Roast the potatoes.</strong> Preheat the oven to 450°F. Wash and dry all produce. Cut the potatoes into ½-inch wedges. On an unlined baking sheet, toss them with 1 tbsp oil and 1½ tsp Old Bay seasoning. Roast in the middle of the oven until golden-brown, 23–26 min.</p></li><li><p><strong>Prep.</strong> Meanwhile, halve the tomatoes. Halve the cucumber lengthwise, then cut into ½-inch half-moons. Roughly chop the parsley. In a strainer, drain and rinse the shrimp, then pat dry with paper towels.</p></li><li><p><strong>Make the salad.</strong> In a large bowl, whisk together the vinegar, ½ tsp sugar and 1 tbsp oil. Season with salt and pepper. Add the spinach, tomatoes and cucumbers and toss.</p></li><li><p><strong>Cook the shrimp.</strong> In a medium bowl, toss the shrimp with the garlic puree, ½ tsp Old Bay seasoning and ½ tbsp oil. Heat a large non-stick pan over medium-high heat. When hot, add the shrimp (don’t overcrowd the pan; cook in 2 batches for 4 people). Cook, stirring occasionally, until the shrimp just turn pink, 2–3 min (165°F inside). Take the pan off the heat. Add half the parsley and 1 tbsp butter, then toss to coat.</p></li><li><p><strong>Serve.</strong> Divide the potatoes and salad between plates. Top the potatoes with the shrimp. Sprinkle the feta and the rest of the parsley over the salad.</p></li></ol><p><em>For 4 people:</em> double every oil, sugar and butter amount, the Old Bay, and the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Shrimp', 'Meat & fish'), 'amount_text', '285 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', '460 g russet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Old Bay seasoning', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic puree', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red wine vinegar', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Parsley', 'Produce'), 'amount_text', '7 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '56 g baby spinach'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cucumber', 'Produce'), 'amount_text', '1 mini (66 g)'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Grape tomatoes', 'Produce'), 'amount_text', '113 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- ── 017 · Homestead Chicken Stew (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Homestead Chicken Stew (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Homestead Chicken Stew')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Homestead Chicken Stew',
    p_meal_type    => 'dinner',
    p_minutes      => 40,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook the potatoes.</strong> Wash and dry all produce. Peel, then cut the potatoes into 1-inch pieces. Add them to a medium pot with 2 tsp salt and enough water to cover by about 1 inch. Cover and bring to a boil over high heat. Meanwhile, thinly slice the green onions. Once boiling, reduce the heat to medium-high and simmer uncovered until fork-tender, 10–12 min. Drain in a colander.</p></li><li><p><strong>Prep the chicken.</strong> Meanwhile, pat the chicken dry with paper towels, then cut into 1-inch pieces. Season with salt and pepper.</p></li><li><p><strong>Start the stew.</strong> Heat a large pot over medium heat. When hot, add 1½ tbsp butter and swirl until melted. Add the chicken and cook, stirring occasionally, until golden-brown, 3–4 min. Add the aromatics blend and 2–3 thyme sprigs. Cook, stirring occasionally, until the veggies soften slightly, 1–2 min. Sprinkle in the cream sauce spice blend and ¾ tsp garlic salt and cook, stirring often, until the chicken and veggies are coated, 30 sec.</p></li><li><p><strong>Finish the stew.</strong> Stir in 1 cup water and the broth concentrate. Bring to a gentle boil over high heat. Once boiling, add the peas, then reduce the heat to medium. Cover and cook, stirring occasionally, until the veggies are tender and the chicken is cooked through, 8–10 min (165°F inside). The stew will be on the thin side. Season with pepper.</p></li><li><p><strong>Make the brown butter.</strong> Meanwhile, while the potatoes drain, wipe the medium pot dry and heat it over medium heat. When hot, add 2 tbsp butter and swirl until golden-brown and no longer foaming, 1–2 min (watch it so it doesn’t burn). Add the green onions, take the pot off the heat and stir until they soften slightly, 30 sec.</p></li><li><p><strong>Mash and serve.</strong> Return the potatoes to the pot with the brown butter and green onions. Add 3 tbsp milk and the rest of the garlic salt, then mash until creamy. Season with pepper. Remove the thyme sprigs from the stew. Divide the mash between bowls and top with the stew.</p></li></ol><p><em>For 4 people:</em> same 2 tsp salt for the potatoes; 3 tbsp butter for the stew; 3–4 thyme sprigs; 1½ tsp garlic salt; 2 cups water; 4 tbsp butter for the brown butter; 6 tbsp milk; double the other ingredients.</p><p><em>Chicken breasts</em> cook exactly the same way as thighs.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken thighs', 'Meat & fish'), 'amount_text', '280 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', '460 g russet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Aromatics blend', 'Produce'), 'amount_text', '227 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green peas', 'Frozen'), 'amount_text', '56 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Thyme', 'Produce'), 'amount_text', '7 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', 'chicken'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cream sauce spice blend', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', ''),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '3½ tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Milk', 'Dairy & eggs'), 'amount_text', '3 tbsp')
    )
  );
end;
$$;

-- ── 018 · Pecan-Crusted Chicken (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Pecan-Crusted Chicken (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Pecan-Crusted Chicken')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Pecan-Crusted Chicken',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'olive oil, cooking oil, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Put a rack in the middle of the oven and preheat to 450°F. Wash and dry the produce. Finely chop the pecans (or crush them in their bag with a heavy pan or rolling pin).</p></li><li><p><strong>Make the crust.</strong> Microwave 1 tbsp butter in a medium microwave-safe bowl until melted, 30 sec. Let cool slightly, then stir in the chopped pecans, panko, half the fry seasoning, a drizzle of olive oil and a pinch of salt and pepper.</p></li><li><p><strong>Make the sauce.</strong> In a small bowl, combine the honey, mustard and mayo.</p></li><li><p><strong>Cook the chicken.</strong> Pat the chicken dry with paper towels and season with the rest of the fry seasoning, salt and pepper. Place on a lightly oiled baking sheet (1 tsp cooking oil). Spread the tops of the chicken with a thin layer of honey mustard sauce (save the rest for serving). Mound the pecan mixture on top, pressing firmly so it sticks (no need to coat the undersides). Roast on the middle rack until the crust is golden-brown and the chicken is cooked through, 15–20 min (165°F inside).</p></li><li><p><strong>Make the salad.</strong> Meanwhile, halve, core and thinly slice the apple. Quarter the lemon. In a large bowl, toss the mixed greens and apple with a large drizzle of olive oil and as much lemon juice as you like. Season with salt and pepper.</p></li><li><p><strong>Serve.</strong> Divide the chicken and salad between plates. Drizzle the chicken with the rest of the honey mustard sauce. Serve any remaining lemon wedges on the side.</p></li></ol><p><em>For 4 people:</em> 2 tbsp butter in the crust; same 1 tbsp olive oil and 1 tsp cooking oil; double the other ingredients.</p><p><em>Salmon instead:</em> put the rack in the top position and roast 8–10 min (145°F inside).</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', '10 oz cutlets'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pecans', 'Pantry'), 'amount_text', '½ oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Fry seasoning', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Honey', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dijon mustard', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Apples', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lemon', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spring mix', 'Produce'), 'amount_text', '2 oz mixed greens'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- ── 019 · Crispy Kickin' Cayenne Chicken Cutlets (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Crispy Kickin'' Cayenne Chicken Cutlets (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Crispy Kickin'' Cayenne Chicken Cutlets')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Crispy Kickin'' Cayenne Chicken Cutlets',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep and make the sauce.</strong> Put racks in the top and middle of the oven and preheat to 425°F. Wash and dry the produce. Trim, peel and cut the carrots on a diagonal into ½-inch-thick pieces. Trim and thinly slice the scallions, keeping the whites and greens separate. In a small bowl, combine half the sour cream, ½ tsp Frank’s seasoning blend (you’ll use the rest in step 2) and a big pinch of salt. Stir in water, 1 tsp at a time, until it’s thin enough to drizzle.</p></li><li><p><strong>Mix the panko.</strong> Microwave 1 tbsp butter in a medium microwave-safe bowl until melted, 30–45 sec. Stir in the panko, Monterey Jack, the rest of the Frank’s seasoning blend and a big pinch of salt and pepper.</p></li><li><p><strong>Make the mashed potatoes.</strong> Dice the potatoes into ½-inch pieces. Put them in a medium pot with enough salted water to cover by 2 inches. Bring to a boil and cook until tender, 15–20 min. Keep ½ cup of the cooking water, then drain. Heat a drizzle of oil and the scallion whites in the empty pot over low heat until softened, 1 min. Return the potatoes and mash with the rest of the sour cream and 1 tbsp butter until smooth, adding splashes of the cooking water as needed. Season with salt and pepper. Keep covered off the heat.</p></li><li><p><strong>Roast the carrots.</strong> While the potatoes cook, lightly oil a baking sheet. Toss the carrots on one side of the sheet with a drizzle of oil, salt and pepper. Roast on the top rack for 5 min (you’ll add the chicken to the sheet then).</p></li><li><p><strong>Coat and roast the chicken.</strong> Meanwhile, pat the chicken dry with paper towels and season with salt and pepper. Mound the tops with the panko mixture, pressing firmly so it sticks. When the carrots have roasted 5 min, take the sheet out and place the chicken, coated side up, on the empty side. Roast on the top rack until the chicken is golden-brown and cooked through and the carrots are tender, 15–18 min (165°F inside).</p></li><li><p><strong>Finish and serve.</strong> Toss the roasted carrots in a large bowl with 1 tbsp butter until melted. Divide the carrots, mashed potatoes and chicken between plates. Drizzle the chicken with the creamy Buffalo sauce and honey (or serve them on the side for dipping). Garnish the potatoes and chicken with the scallion greens.</p></li></ol><p><em>For 4 people:</em> 1 tsp Frank’s seasoning in the sauce; 2 tbsp butter in the panko, 2 tbsp in the mash; roast the chicken on a second oiled sheet on the middle rack, with the carrots staying on top; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', '10 oz cutlets'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Potatoes', 'Produce'), 'amount_text', '12 oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Carrots', 'Produce'), 'amount_text', '12 oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Green onions', 'Produce'), 'amount_text', '2 scallions'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Sour cream', 'Dairy & eggs'), 'amount_text', '3 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Frank''s seasoning blend', 'Pantry'), 'amount_text', '¼ oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Monterey Jack cheese', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Honey', 'Pantry'), 'amount_text', '2 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '3 tbsp')
    )
  );
end;
$$;

-- ── 020 · Lemon-Pesto Chicken (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Lemon-Pesto Chicken (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Lemon-Pesto Chicken')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Lemon-Pesto Chicken',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Cook the rice.</strong> Preheat the oven to 425°F. Wash and dry all produce. In a medium pot, combine 1¼ cups water, 1 tbsp butter and half the zesty garlic blend. Cover and bring to a boil over high heat. Once boiling, add the rice, then reduce the heat to low. Cover and cook until the rice is tender and the liquid is absorbed, 12–14 min. Take off the heat and leave covered.</p></li><li><p><strong>Prep.</strong> Meanwhile, zest, then juice half the lemon. Cut the other half into wedges. Core, then cut the pepper into ½-inch pieces. Peel, then cut half the onion into ¼-inch pieces.</p></li><li><p><strong>Cook the chicken.</strong> Pat the chicken dry with paper towels, then season with salt, pepper and the rest of the zesty garlic blend. Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the chicken. Sear until golden-brown, 2–3 min per side. Move the chicken to an unlined baking sheet and roast in the middle of the oven until cooked through, 12–14 min (165°F inside).</p></li><li><p><strong>Cook the veggies.</strong> Meanwhile, heat the same pan over medium-high heat. When hot, add ½ tbsp oil, then the peppers and onions. Season with salt and pepper. Cook, stirring occasionally, until tender-crisp, 5–6 min. Move to a plate and cover to keep warm.</p></li><li><p><strong>Make the lemon-pesto sauce.</strong> Meanwhile, in a small bowl, stir together the pesto, half the lemon zest and ½ tsp lemon juice. Season with salt and pepper.</p></li><li><p><strong>Finish and serve.</strong> Fluff the rice with a fork and season with salt. Stir in the veggies and the rest of the lemon zest. Thinly slice the chicken. Divide the pilaf and chicken between plates, spoon the lemon-pesto sauce over the chicken and sprinkle with the feta. Squeeze a lemon wedge over the top, if you like.</p></li></ol><p><em>For 4 people:</em> 2½ cups water and 2 tbsp butter for the rice; 1 tbsp oil each for the chicken and the veggies; the whole onion; 1 tsp lemon juice in the sauce; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chicken breasts', 'Meat & fish'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '¾ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '160 g sweet bell pepper'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', '56 g yellow onion'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Lemon', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Pesto', 'Pantry'), 'amount_text', '¼ cup basil pesto'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Zesty garlic blend', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '1 tbsp')
    )
  );
end;
$$;

-- ── 021 · Spicy Harissa-Glazed Turkey Patties (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Spicy Harissa-Glazed Turkey Patties (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Spicy Harissa-Glazed Turkey Patties')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 022 · Coconut Curry with Chickpeas (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Coconut Curry with Chickpeas (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Coconut Curry with Chickpeas')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Coconut Curry with Chickpeas',
    p_meal_type    => 'dinner',
    p_minutes      => 40,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Prep.</strong> Wash and dry the produce. Peel and mince the garlic. Halve, peel and finely dice half the onion. Core, deseed and finely dice the bell pepper. Drain and rinse the chickpeas. Finely chop the cilantro.</p></li><li><p><strong>Cook the rice.</strong> Melt 1 tbsp butter in a small pot over medium-high heat. Add half the garlic and cook until fragrant, 30 sec. Add the rice, ¾ cup water and a big pinch of salt. Bring to a boil, then cover and reduce the heat to low. Cook until the rice is tender, 15–18 min. Keep covered off the heat until ready to serve.</p></li><li><p><strong>Cook the curry.</strong> Heat a drizzle of oil in a medium pot over medium-high heat. Add the onion and bell pepper and cook until softened and lightly browned, 3–5 min. Stir in the tomato paste, curry powder, paprika, half the garam masala and the rest of the garlic until fragrant, 1 min. (Tip: add more garam masala if you like its earthy warmth.) Stir in the chickpeas, coconut milk, stock concentrate, ¼ cup water and ½ tsp sugar. Bring to a simmer, then reduce the heat to low and cook until thickened, stirring occasionally, 4–5 min. Take off the heat and stir in 1 tbsp butter until melted. (Tip: if the curry seems too thick, stir in a splash of water.) Season with salt and pepper.</p></li><li><p><strong>Finish and serve.</strong> Fluff the rice with a fork and season with salt and pepper. Divide between bowls, top with the curry, dollop with the yogurt and garnish with the cilantro.</p></li></ol><p><em>For 4 people:</em> the whole onion; 1½ cups water for the rice; 1 tsp sugar; 2 tbsp butter in the curry; double the other ingredients.</p><p><em>Want it hotter?</em> Add a dash of hot sauce or a pinch of chili flakes with the spices in step 3.</p><p><em>Chicken or turkey:</em> pat 10 oz dry, season with salt and pepper and cook with the onion until cooked through, 4–6 min (165°F inside), then carry on as above.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Chickpeas', 'Pantry'), 'amount_text', '1 can'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Coconut milk', 'Pantry'), 'amount_text', '1 can'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '½ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Onion', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '1'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', '1 clove'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Cilantro', 'Produce'), 'amount_text', '¼ oz'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomato paste', 'Pantry'), 'amount_text', '1 packet'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Curry powder', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Paprika', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garam masala', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Broth concentrate', 'Pantry'), 'amount_text', '1 veggie stock'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Yogurt', 'Dairy & eggs'), 'amount_text', '2 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- ── 023 · Veggie Burrito Bowls (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Veggie Burrito Bowls (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Veggie Burrito Bowls')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 024 · Kadai-Style Paneer (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Kadai-Style Paneer (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Kadai-Style Paneer')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Kadai-Style Paneer',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, water, salt, pepper',
    p_method       => '<ol><li><p><strong>Prep.</strong> Wash and dry all produce. Core, then cut the pepper into ½-inch pieces. Peel, then cut the onion into ½-inch pieces. Peel, then mince or grate the garlic. Cut the paneer into ½-inch cubes and season with salt and pepper. Roughly chop the spinach.</p></li><li><p><strong>Cook the rice.</strong> Heat a medium pot over medium heat. When hot, add 1 tbsp butter, then the rice and half the garlic. Cook, stirring often, until fragrant, 2–3 min. Add 1¼ cups water and bring to a boil over high heat. Once boiling, reduce the heat to low. Cover and cook until the rice is tender and the liquid is absorbed, 12–14 min. Take off the heat and leave covered.</p></li><li><p><strong>Cook the paneer.</strong> Meanwhile, heat a large non-stick pan over medium-high heat. When hot, add 1 tbsp butter and swirl until melted, 1 min. Add the paneer and pan-fry, turning occasionally, until crispy and golden-brown all over, 5–6 min. Move the paneer to a plate and set aside.</p></li><li><p><strong>Cook the veggies.</strong> Reduce the heat to medium. Add ½ tbsp oil to the same pan, then the onions and peppers. Cook, stirring occasionally, until tender-crisp, 3–4 min. Add the dal spice blend and the rest of the garlic and cook, stirring often, until fragrant, 1–2 min.</p></li><li><p><strong>Make the sauce.</strong> Add the tikka sauce and coconut milk to the pan with the veggies. Reduce the heat to medium-low and cook, stirring occasionally, until the sauce thickens slightly, 5–7 min. Add the paneer and spinach and cook, stirring often, until the spinach wilts, 1–2 min. Season with salt.</p></li><li><p><strong>Finish and serve.</strong> Fluff the rice with a fork and season with salt. Divide the rice between plates and top with the paneer, veggies and any sauce left in the pan.</p></li></ol><p><em>For 4 people:</em> 2 tbsp butter for the rice; 2½ cups water; cook the paneer in 2 batches, 1 tbsp butter per batch; 1 tbsp oil for the veggies; add the spinach in batches; double the other ingredients.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Paneer', 'Dairy & eggs'), 'amount_text', '200 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Rice', 'Pantry'), 'amount_text', '¾ cup basmati'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Bell pepper', 'Produce'), 'amount_text', '160 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Red onion', 'Produce'), 'amount_text', '113 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic', 'Produce'), 'amount_text', '2 cloves'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '56 g baby spinach'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tikka sauce', 'Pantry'), 'amount_text', '½ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Coconut milk', 'Pantry'), 'amount_text', '165 ml'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Dal spice blend', 'Pantry'), 'amount_text', '1 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Butter', 'Dairy & eggs'), 'amount_text', '2 tbsp')
    )
  );
end;
$$;

-- ── 025 · Pork and Pepper Tacos (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Pork and Pepper Tacos (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Pork and Pepper Tacos')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 026 · Ricotta and Squash Flatbreads (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Ricotta and Squash Flatbreads (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Ricotta and Squash Flatbreads')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 027 · Golden Halloumi Sandwiches (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Golden Halloumi Sandwiches (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Golden Halloumi Sandwiches')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 028 · Feta Beef Burgers (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Feta Beef Burgers (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Feta Beef Burgers')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
    return;
  end if;

  perform save_recipe(
    p_id           => null,
    p_name         => 'Feta Beef Burgers',
    p_meal_type    => 'dinner',
    p_minutes      => 35,
    p_servings     => 2,
    p_is_favourite => false,
    p_basics       => 'oil, salt, pepper, sugar',
    p_method       => '<ol><li><p><strong>Prep.</strong> Preheat the broiler to high. Wash and dry all produce. Finely chop 1 tbsp oregano leaves. Cut the tomato into ¼-inch pieces. In a small bowl, stir together the mayo and half the feta. Season with pepper.</p></li><li><p><strong>Make the patties.</strong> In a large bowl, combine the beef, panko, oregano and half the garlic salt. Season with pepper. (Tip: for a more tender patty, add an egg to the mixture.) Form into two 4-inch-wide patties.</p></li><li><p><strong>Cook the patties.</strong> Heat a large non-stick pan over medium-high heat. When hot, add ½ tbsp oil, then the patties (don’t overcrowd the pan). Pan-fry until golden-brown and cooked through, 4–5 min per side (165°F inside). Move to a plate and cover to keep warm.</p></li><li><p><strong>Toast the buns.</strong> Meanwhile, halve the buns. Arrange them cut side up on an unlined baking sheet. Broil in the middle of the oven until golden-brown, 1–2 min (watch them so they don’t burn).</p></li><li><p><strong>Make the salad.</strong> Meanwhile, in another large bowl, whisk together the rest of the garlic salt, ½ tbsp vinegar, ¼ tsp sugar and 1 tbsp oil. Add the tomatoes, spinach and the rest of the feta. Sprinkle the olives over the top, if you like. Season with pepper and toss.</p></li><li><p><strong>Finish and serve.</strong> Spread the feta-mayo on the bottom buns, then stack with the patties and some salad. Close with the top buns. Divide the burgers between plates and serve the rest of the salad alongside.</p></li></ol><p><em>For 4 people:</em> 2 tbsp oregano; 4 patties, cooked in 2 batches; 1 tbsp oil for the patties; 1 tbsp vinegar, ½ tsp sugar and 2 tbsp oil in the salad; double the other ingredients.</p><p><em>Ground turkey:</em> moisten your hands slightly to form the patties, then cook them the same way.</p>',
    p_ingredients  => jsonb_build_array(
      jsonb_build_object('item_id', pg_temp.pantry_item('Ground beef', 'Meat & fish'), 'amount_text', '250 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Artisan buns', 'Pantry'), 'amount_text', '2'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Panko', 'Pantry'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Oregano', 'Produce'), 'amount_text', '7 g'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Garlic salt', 'Pantry'), 'amount_text', '1 tsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Mayo', 'Pantry'), 'amount_text', '4 tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Feta', 'Dairy & eggs'), 'amount_text', '¼ cup'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Tomatoes', 'Produce'), 'amount_text', '80 g Roma'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Spinach', 'Produce'), 'amount_text', '56 g baby spinach'),
      jsonb_build_object('item_id', pg_temp.pantry_item('White wine vinegar', 'Pantry'), 'amount_text', '½ tbsp'),
      jsonb_build_object('item_id', pg_temp.pantry_item('Olives', 'Pantry'), 'amount_text', '30 g mixed')
    )
  );
end;
$$;

-- ── 029 · Garlic Bocconcini Bites (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Garlic Bocconcini Bites (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Garlic Bocconcini Bites')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- ── 030 · Kidney Beans in a Rich Garlic Sauce (with Carrot Mash and Roasted Brussels Sprouts) ──
truncate import_current; insert into import_current values ('Kidney Beans in a Rich Garlic Sauce (with Carrot Mash and Roasted Brussels Sprouts)');
do $$
begin
  if exists (select 1 from recipes where lower(name) = lower('Kidney Beans in a Rich Garlic Sauce')) then
    insert into import_log (recipe, ingredient, pantry_item, result) values ((select recipe from import_current), '—', '—', 'Recipe already exists: skipped');
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

-- What happened: one row per ingredient, grouped by recipe.
select recipe, ingredient, pantry_item, result from import_log order by n;
