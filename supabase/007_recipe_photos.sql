-- =====================================================================
-- Pantry App · Step 13 (Phase 2c) · Recipe photos
-- Run once in Supabase: SQL Editor → New query → paste → Run
-- =====================================================================

-- 1. A PRIVATE storage bucket (a folder for files) for recipe photos.
--    Private = no public links; the app asks for short-lived signed links instead.
--    Limits: 2 MB per file, images only. The app shrinks photos to ~200 KB before upload.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('recipe-photos', 'recipe-photos', false, 2097152, array['image/jpeg', 'image/webp', 'image/png'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;


-- 2. Who may do what with files in that bucket: signed-in household members only.
--    (storage.objects is Supabase's table of all stored files; RLS applies to it like any table.)
create policy "household can view recipe photos" on storage.objects
  for select to authenticated
  using (bucket_id = 'recipe-photos');

create policy "household can add recipe photos" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'recipe-photos');

create policy "household can replace recipe photos" on storage.objects
  for update to authenticated
  using (bucket_id = 'recipe-photos')
  with check (bucket_id = 'recipe-photos');

create policy "household can remove recipe photos" on storage.objects
  for delete to authenticated
  using (bucket_id = 'recipe-photos');

-- recipes.photo_path already exists (added in 006_recipes.sql). It stores the file's
-- path inside the bucket, e.g. "3f2a…/1727741234567.jpg" — not a web link, because
-- links to private files expire.
