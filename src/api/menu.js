// Everything the weekly menu reads or writes (table: meal_plan, supabase/008_meal_plan.sql).
// The app plans dinners only for now.
import { supabase } from '../lib/supabase.js'

const MEAL = 'dinner'

// Planned dinners between two dates (inclusive), with what each recipe needs:
// [{ plan_date, recipe: { id, name, minutes, photo_path, ingredients: [{ item_id, name, status }] } }]
export async function fetchPlan(fromDate, toDate) {
  const { data, error } = await supabase
    .from('meal_plan')
    .select('plan_date, recipes ( id, name, minutes, photo_path, recipe_ingredients ( item_id, items ( name, status ) ) )')
    .eq('meal', MEAL)
    .gte('plan_date', fromDate)
    .lte('plan_date', toDate)
    .order('plan_date')
  if (error) throw error

  return data.map((row) => ({
    plan_date: row.plan_date,
    recipe: {
      id: row.recipes.id,
      name: row.recipes.name,
      minutes: row.recipes.minutes,
      photo_path: row.recipes.photo_path,
      ingredients: row.recipes.recipe_ingredients.map((ri) => ({
        item_id: ri.item_id,
        name: ri.items.name,
        status: ri.items.status,
      })),
    },
  }))
}

// Plan a dinner. UPSERT = insert, or update the row if that day already has a dinner
// (the table's primary key is plan_date + meal).
export async function setDinner(planDate, recipeId) {
  const { error } = await supabase
    .from('meal_plan')
    .upsert({ plan_date: planDate, meal: MEAL, recipe_id: recipeId }, { onConflict: 'plan_date,meal' })
  if (error) throw error
}

// Save several days at once (the generator). One request = all saved, or none.
// picks: [{ date, recipeId }]
export async function setDinners(picks) {
  if (picks.length === 0) return
  const rows = picks.map((p) => ({ plan_date: p.date, meal: MEAL, recipe_id: p.recipeId }))
  const { error } = await supabase.from('meal_plan').upsert(rows, { onConflict: 'plan_date,meal' })
  if (error) throw error
}

// Rearrange (step 16a): move a dinner to another day of the week.
// If that day already has a dinner, the two swap: one upsert saves both days together.
// If it's empty, the dinner is saved on the new day first, then removed from the old one
// (so a failure halfway leaves it on both days, never on neither).
export async function moveDinner(fromDate, toDate, fromRecipeId, toRecipeId) {
  if (toRecipeId) {
    await setDinners([
      { date: toDate, recipeId: fromRecipeId },
      { date: fromDate, recipeId: toRecipeId },
    ])
  } else {
    await setDinner(toDate, fromRecipeId)
    await clearDinner(fromDate)
  }
}

export async function clearDinner(planDate) {
  const { error } = await supabase.from('meal_plan').delete().eq('plan_date', planDate).eq('meal', MEAL)
  if (error) throw error
}

// Step 18: which needed (Low / Out) items do the planned dinners use?
// Returns a Map: item_id → [{ plan_date, recipeName }], in date order.
export function neededByMenu(plan) {
  const map = new Map()
  for (const { plan_date, recipe } of plan) {
    for (const ing of recipe.ingredients) {
      if (ing.status === 'in') continue
      if (!map.has(ing.item_id)) map.set(ing.item_id, [])
      map.get(ing.item_id).push({ plan_date, recipeName: recipe.name })
    }
  }
  return map
}
