-- =====================================================================
-- Pantry App · Step 5a · Live updates for stores and store links
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================

-- Step 4b added items. Now that stores can be added, renamed and removed,
-- other devices also need to hear about changes to stores and item_stores.
alter publication supabase_realtime add table stores, item_stores;
