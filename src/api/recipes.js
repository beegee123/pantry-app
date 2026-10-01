// Everything that reads or writes recipes.
import { supabase } from '../lib/supabase.js'
import { deletePhotoFile } from './photos.js'

export const MEAL_TYPES = [
  { value: 'breakfast', label: 'Breakfast' },
  { value: 'lunch', label: 'Lunch' },
  { value: 'dinner', label: 'Dinner' },
  { value: 'snack', label: 'Snack' },
  { value: 'side', label: 'Side' },
  { value: 'dessert', label: 'Dessert' },
]

export const mealLabel = (value) => MEAL_TYPES.find((m) => m.value === value)?.label ?? value

// Postgres codes we turn into friendly messages.
function friendlyError(error, name) {
  if (error.code === '23505') return new Error(`You already have a recipe called ${name.trim()}.`)
  if (error.code === '23502') return new Error('Give the recipe a name.')
  if (error.code === '23514') return new Error('Minutes and servings must be more than 0.')
  return error
}

// The list: each recipe with its ingredients' statuses (step 11 uses them for readiness).
export async function fetchRecipes() {
  const { data, error } = await supabase
    .from('recipes')
    .select('id, name, meal_type, minutes, is_favourite, photo_path, recipe_ingredients ( item_id, items ( status ) )')
    .order('name')
  if (error) throw error

  return data.map((r) => ({
    id: r.id,
    name: r.name,
    meal_type: r.meal_type,
    minutes: r.minutes,
    is_favourite: r.is_favourite,
    photo_path: r.photo_path,
    ingredientStatuses: r.recipe_ingredients.map((ri) => ri.items.status),
  }))
}

// One recipe with its ingredients in order — for the form (and the detail screen in 2b).
export async function fetchRecipe(recipeId) {
  const { data, error } = await supabase
    .from('recipes')
    .select(
      `id, name, meal_type, minutes, servings, is_favourite, basics, method, photo_path,
       recipe_ingredients ( item_id, amount_text, position, items ( name, status ) )`,
    )
    .eq('id', recipeId)
    .maybeSingle()
  if (error) throw error
  if (!data) return null

  return {
    id: data.id,
    name: data.name,
    meal_type: data.meal_type,
    minutes: data.minutes ?? '',
    servings: data.servings ?? '',
    is_favourite: data.is_favourite,
    basics: data.basics ?? '',
    method: data.method ?? '',
    photo_path: data.photo_path,
    ingredients: [...data.recipe_ingredients]
      .sort((a, b) => a.position - b.position)
      .map((ri) => ({
        item_id: ri.item_id,
        name: ri.items.name,
        status: ri.items.status,
        amount_text: ri.amount_text ?? '',
      })),
  }
}

// Turn "45" or "" from a number box into 45 or null.
const toNumberOrNull = (value) => (String(value).trim() === '' ? null : Number(value))

// Create or update a recipe and its ingredient list in ONE transaction,
// via the save_recipe database function (supabase/006_recipes.sql).
export async function saveRecipe(recipe) {
  const { data, error } = await supabase.rpc('save_recipe', {
    p_id: recipe.id ?? null,
    p_name: recipe.name,
    p_meal_type: recipe.meal_type,
    p_minutes: toNumberOrNull(recipe.minutes),
    p_servings: toNumberOrNull(recipe.servings),
    p_is_favourite: recipe.is_favourite,
    p_basics: recipe.basics,
    p_method: recipe.method,
    p_ingredients: recipe.ingredients.map((i) => ({ item_id: i.item_id, amount_text: i.amount_text })),
  })
  if (error) throw friendlyError(error, recipe.name)
  return data // the recipe's id
}

// Delete the recipe, then its photo file (the database can't delete storage files for us).
export async function deleteRecipe(recipeId) {
  const { data, error } = await supabase.from('recipes').delete().eq('id', recipeId).select('id, photo_path')
  if (error) throw error
  if (data.length === 0) throw new Error('The recipe was not deleted.')
  try {
    await deletePhotoFile(data[0].photo_path)
  } catch {
    // The recipe is gone; a leftover photo file is harmless.
  }
}
