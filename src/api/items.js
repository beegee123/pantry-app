// Everything that reads or writes items in the database lives here,
// so the components never talk to Supabase directly.
import { supabase } from '../lib/supabase.js'

// Ask for each item AND, through the item_stores link table, the names of its stores.
// Supabase follows the foreign keys for us — like a relationship query in SOQL.
const ITEM_FIELDS = `
  id, name, category, status, usual_amount,
  item_stores ( is_preferred, stores ( name ) )
`

// Reshape one database row into the shape the components already use:
//   { ..., stores: [{ name, is_preferred }] }
function toAppItem(row) {
  return {
    id: row.id,
    name: row.name,
    category: row.category,
    status: row.status,
    usual_amount: row.usual_amount,
    stores: row.item_stores.map((link) => ({
      name: link.stores.name,
      is_preferred: link.is_preferred,
    })),
  }
}

export async function fetchItems() {
  const { data, error } = await supabase.from('items').select(ITEM_FIELDS).order('name')
  if (error) throw error
  return data.map(toAppItem)
}

export async function saveItemStatus(itemId, status) {
  // .select('id') returns the rows that were actually changed.
  // If security rules block an update, Supabase changes 0 rows WITHOUT an error,
  // so we check the count ourselves rather than assume it worked.
  const { data, error } = await supabase
    .from('items')
    .update({ status })
    .eq('id', itemId)
    .select('id')
  if (error) throw error
  if (data.length === 0) throw new Error('The change was not saved.')
}

// ---- Step 5b: one item, save, delete ----

// One item for the edit form, with the ids of its stores. Returns null if it doesn't exist.
export async function fetchItem(itemId) {
  const { data, error } = await supabase
    .from('items')
    .select('id, name, category, status, usual_amount, always_stocked, item_stores ( store_id, is_preferred )')
    .eq('id', itemId)
    .maybeSingle() // one row or null, instead of a list
  if (error) throw error
  if (!data) return null

  const preferred = data.item_stores.find((link) => link.is_preferred)
  return {
    id: data.id,
    name: data.name,
    category: data.category,
    status: data.status,
    usual_amount: data.usual_amount ?? '',
    always_stocked: data.always_stocked,
    storeIds: data.item_stores.map((link) => link.store_id),
    preferredStoreId: preferred ? preferred.store_id : null,
  }
}

// Create (no id) or update (with id) an item and its store links, in ONE
// database transaction, by calling the save_item function (supabase/004_save_item.sql).
export async function saveItem(item) {
  const { data, error } = await supabase.rpc('save_item', {
    p_id: item.id ?? null,
    p_name: item.name,
    p_category: item.category,
    p_status: item.status,
    p_usual_amount: item.usual_amount,
    p_always_stocked: item.always_stocked,
    p_store_ids: item.storeIds,
    p_preferred_store_id: item.preferredStoreId,
  })
  if (error) {
    if (error.code === '23505') throw new Error(`You already have an item called ${item.name.trim()}.`)
    throw error
  }
  return data // the item's id
}

export async function deleteItem(itemId) {
  const { data, error } = await supabase.from('items').delete().eq('id', itemId).select('id')
  // 23503 = "still referenced": a recipe uses this item (recipe_ingredients won't let it go).
  if (error?.code === '23503') {
    throw new Error('This item is used in a recipe. Remove it from those recipes first.')
  }
  if (error) throw error
  if (data.length === 0) throw new Error('The item was not deleted.')
}

// ---- Phase 2: pantry items for the recipe ingredient picker ----
export async function fetchItemOptions() {
  const { data, error } = await supabase.from('items').select('id, name, category, status').order('name')
  if (error) throw error
  return data
}
