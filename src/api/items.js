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
