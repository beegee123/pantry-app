// One shared connection to Supabase for the whole app.
import { createClient } from '@supabase/supabase-js'

// Vite reads these from .env.local. Only variables starting with VITE_ reach the browser.
const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

// If either is missing we don't crash — App shows a helpful message instead.
export const missingConfig = !url || !key

// ---- Retry for "JWT issued at future" ----
// Right after signing in (or when the sign-in token is renewed), Supabase's
// database server can briefly see the new token as "issued in the future",
// because its clock is a fraction of a second behind the sign-in server's.
// It fixes itself within moments, so we wait and try again instead of
// showing an error. Every other error is passed straight through.
const RETRY_DELAYS_MS = [500, 1000, 2000] // up to 3 retries, waiting a little longer each time

const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

async function fetchWithRetry(input, init) {
  for (let attempt = 0; ; attempt++) {
    const response = await fetch(input, init)
    if (response.status !== 401 || attempt >= RETRY_DELAYS_MS.length) return response

    // Read a COPY of the body, so the original can still be read by supabase-js if we return it.
    const body = await response.clone().text()
    if (!/issued at future/i.test(body)) return response

    await wait(RETRY_DELAYS_MS[attempt])
  }
}

// global.fetch tells supabase-js to send every request through our function.
export const supabase = missingConfig
  ? null
  : createClient(url, key, { global: { fetch: fetchWithRetry } })
