// One shared connection to Supabase for the whole app.
import { createClient } from '@supabase/supabase-js'

// Vite reads these from .env.local. Only variables starting with VITE_ reach the browser.
const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

// If either is missing we don't crash — App shows a helpful message instead.
export const missingConfig = !url || !key

export const supabase = missingConfig ? null : createClient(url, key)
