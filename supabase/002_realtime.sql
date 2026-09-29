-- =====================================================================
-- Pantry App · Step 4b · Live updates
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================

-- Supabase Realtime only broadcasts changes for tables added to this
-- "publication". Adding items means every signed-in device hears about
-- changes to items as they happen.
-- Row Level Security still applies: only signed-in household members
-- receive these messages.
alter publication supabase_realtime add table items;
