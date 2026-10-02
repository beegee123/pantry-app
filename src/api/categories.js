// Categories live in the database (supabase/009_categories.sql), in display order.
import { supabase } from '../lib/supabase.js'

export async function fetchCategories() {
  const { data, error } = await supabase.from('categories').select('id, name, position').order('position')
  if (error) throw error
  return data
}
