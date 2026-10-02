// A CUSTOM HOOK: any screen that needs the category list calls useCategories().
// It loads the list once, reloads it when categories change on any device,
// and returns them in display order as [{ id, name }] ([] while loading).
//
// Hooks are just functions whose names start with "use" and that call other hooks
// (useState, useEffect). They let several screens share the same loading logic.
import { useEffect, useState } from 'react'
import { fetchCategories } from '../api/categories.js'
import { subscribeToTables } from './realtime.js'


export function useCategories() {
  const [categories, setCategories] = useState([])

  useEffect(() => {
    let ignore = false
    const load = () =>
      fetchCategories()
        .then((rows) => {
          if (!ignore) setCategories(rows.map((c) => ({ id: c.id, name: c.name })))
        })
        .catch(() => {}) // keep whatever we had; screens still work, just without the list
    load()
    const stop = subscribeToTables(`categories-${Math.random()}`, ['categories'], load)
    return () => {
      ignore = true
      stop()
    }
  }, [])

  return categories
}

// The category a new item starts in: Pantry if it exists, else the first one.
export const defaultCategoryId = (categories) =>
  (categories.find((c) => c.name === 'Pantry') ?? categories[0])?.id ?? null
