// Everything that reads or writes stores in the database.
import { supabase } from '../lib/supabase.js'

// Postgres reports "that value already exists" with the error code 23505
// (our stores.name column is UNIQUE). Turn it into a message people understand.
function friendlyError(error, name) {
  if (error.code === '23505') return new Error(`You already have a store called ${name}.`)
  return error
}

const isNeeded = (status) => status === 'low' || status === 'out'

// Each store with how many items are linked to it and how many of those are low or out.
export async function fetchStores() {
  const { data, error } = await supabase
    .from('stores')
    .select('id, name, item_stores ( items ( status ) )')
    .order('name')
  if (error) throw error

  return data.map((store) => ({
    id: store.id,
    name: store.name,
    linkedCount: store.item_stores.length,
    neededCount: store.item_stores.filter((link) => isNeeded(link.items.status)).length,
  }))
}

// The "Any store" row: items with no store linked at all.
export async function fetchAnyStoreSummary() {
  const { data, error } = await supabase.from('items').select('status, item_stores ( store_id )')
  if (error) throw error

  const unlinked = data.filter((item) => item.item_stores.length === 0)
  return {
    linkedCount: unlinked.length,
    neededCount: unlinked.filter((item) => isNeeded(item.status)).length,
  }
}

export async function addStore(name) {
  const { error } = await supabase.from('stores').insert({ name })
  if (error) throw friendlyError(error, name)
}

export async function renameStore(storeId, name) {
  const { data, error } = await supabase
    .from('stores')
    .update({ name })
    .eq('id', storeId)
    .select('id')
  if (error) throw friendlyError(error, name)
  if (data.length === 0) throw new Error('The change was not saved.')
}

// Removing a store also removes its item_stores links (ON DELETE CASCADE),
// so its items fall back to "Any store". The items themselves are kept.
export async function removeStore(storeId) {
  const { data, error } = await supabase.from('stores').delete().eq('id', storeId).select('id')
  if (error) throw error
  if (data.length === 0) throw new Error('The store was not removed.')
}
