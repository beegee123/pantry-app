// Everything the Shopping list reads or writes.
import { supabase } from '../lib/supabase.js'

// Only items that are low or out, with their stores and whether they're in the cart.
export async function fetchShoppingList() {
  const { data, error } = await supabase
    .from('items')
    .select('id, name, status, usual_amount, in_cart, item_stores ( is_preferred, stores ( id, name ) )')
    .in('status', ['low', 'out'])
    .order('name')
  if (error) throw error

  return data.map((row) => ({
    id: row.id,
    name: row.name,
    status: row.status,
    usual_amount: row.usual_amount,
    in_cart: row.in_cart,
    stores: row.item_stores.map((link) => ({
      id: link.stores.id,
      name: link.stores.name,
      is_preferred: link.is_preferred,
    })),
  }))
}

// How many items are low or out — for the badge on the Shopping tab.
// head: true asks only for the count, not the rows themselves.
export async function fetchNeededCount() {
  const { count, error } = await supabase
    .from('items')
    .select('id', { count: 'exact', head: true })
    .in('status', ['low', 'out'])
  if (error) throw error
  return count
}

export async function setInCart(itemId, inCart) {
  const { data, error } = await supabase
    .from('items')
    .update({ in_cart: inCart })
    .eq('id', itemId)
    .select('id')
  if (error) throw error
  if (data.length === 0) throw new Error('The change was not saved.')
}

// Calls the finish_trip database function (supabase/005_shopping.sql).
// Returns how many items were restocked.
export async function finishTrip() {
  const { data, error } = await supabase.rpc('finish_trip')
  if (error) throw error
  return data
}
