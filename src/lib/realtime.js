// Small helper: call `onChange` whenever any of the given tables changes.
// Returns a function that stops listening — use it as a useEffect cleanup.
import { supabase } from './supabase.js'

export function subscribeToTables(channelName, tables, onChange) {
  let channel = supabase.channel(channelName)
  for (const table of tables) {
    channel = channel.on('postgres_changes', { event: '*', schema: 'public', table }, onChange)
  }
  channel.subscribe()
  return () => supabase.removeChannel(channel)
}
