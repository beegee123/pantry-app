// Categories live in the database (supabase/009_categories.sql), in display order.
import { supabase } from '../lib/supabase.js'

// categories.name is UNIQUE: Postgres reports a clash as error code 23505.
function friendlyError(error, name) {
  if (error.code === '23505') return new Error(`You already have a category called ${name}.`)
  return error
}

export async function fetchCategories() {
  const { data, error } = await supabase.from('categories').select('id, name, position').order('position')
  if (error) throw error
  return data
}

// For the Categories screen: each category with how many items use it.
// items(count) asks the database to count the linked items instead of sending them all.
export async function fetchCategoriesWithCounts() {
  const { data, error } = await supabase
    .from('categories')
    .select('id, name, position, items(count)')
    .order('position')
  if (error) throw error
  return data.map((c) => ({ id: c.id, name: c.name, position: c.position, itemCount: c.items[0]?.count ?? 0 }))
}

// New categories go at the end of the list.
export async function addCategory(name, position) {
  const { error } = await supabase.from('categories').insert({ name, position })
  if (error) throw friendlyError(error, name)
}

// Its items follow automatically (trigger in 009_categories.sql).
export async function renameCategory(categoryId, name) {
  const { data, error } = await supabase.from('categories').update({ name }).eq('id', categoryId).select('id')
  if (error) throw friendlyError(error, name)
  if (data.length === 0) throw new Error('The change was not saved.')
}

// ids = every category, in the new order (supabase/010_categories_screen.sql).
export async function reorderCategories(ids) {
  const { error } = await supabase.rpc('reorder_categories', { p_ids: ids })
  if (error) throw error
}

// moveToId = where its items go (null when no items use it).
export async function removeCategory(categoryId, moveToId) {
  const { error } = await supabase.rpc('remove_category', { p_id: categoryId, p_move_to: moveToId })
  if (error) throw error
}
