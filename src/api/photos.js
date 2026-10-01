// Recipe photos live in the private "recipe-photos" storage bucket.
// The recipe row only keeps the file's path (recipes.photo_path).
import { supabase } from '../lib/supabase.js'

const BUCKET = 'recipe-photos'
const LINK_SECONDS = 60 * 60 // signed links work for 1 hour

// Signed links are cached for a while so the same photo isn't fetched again on every screen.
// path → { url, expires }
const linkCache = new Map()

// Get viewable links for several photos at once: { path: url }.
export async function getPhotoUrls(paths) {
  const now = Date.now()
  const result = {}
  const needed = []
  for (const path of new Set(paths.filter(Boolean))) {
    const cached = linkCache.get(path)
    if (cached && cached.expires > now) result[path] = cached.url
    else needed.push(path)
  }
  if (needed.length > 0) {
    const { data, error } = await supabase.storage.from(BUCKET).createSignedUrls(needed, LINK_SECONDS)
    if (error) throw error
    for (const entry of data) {
      if (!entry.signedUrl) continue // file missing — show the placeholder instead
      result[entry.path] = entry.signedUrl
      // Treat it as expiring 5 minutes early, to be safe.
      linkCache.set(entry.path, { url: entry.signedUrl, expires: now + (LINK_SECONDS - 300) * 1000 })
    }
  }
  return result
}

// Upload a (shrunk) photo for a recipe, point the recipe at it, then remove the old file.
export async function setRecipePhoto(recipeId, oldPath, blob) {
  const path = `${recipeId}/${Date.now()}.jpg` // a new name each time, so phones never show a stale cached copy
  const { error: uploadError } = await supabase.storage
    .from(BUCKET)
    .upload(path, blob, { contentType: 'image/jpeg', cacheControl: '31536000' })
  if (uploadError) throw uploadError

  const { data, error } = await supabase.from('recipes').update({ photo_path: path }).eq('id', recipeId).select('id')
  if (error || data.length === 0) {
    // Couldn't link it to the recipe: tidy up the file we just uploaded.
    await supabase.storage.from(BUCKET).remove([path])
    throw error ?? new Error('The photo was not saved.')
  }

  if (oldPath) await supabase.storage.from(BUCKET).remove([oldPath]) // best effort
  return path
}

export async function removeRecipePhoto(recipeId, oldPath) {
  const { data, error } = await supabase.from('recipes').update({ photo_path: null }).eq('id', recipeId).select('id')
  if (error) throw error
  if (data.length === 0) throw new Error('The photo was not removed.')
  if (oldPath) await supabase.storage.from(BUCKET).remove([oldPath]) // best effort
}

// Used when a recipe is deleted.
export async function deletePhotoFile(path) {
  if (path) await supabase.storage.from(BUCKET).remove([path])
}
