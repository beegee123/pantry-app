// A CUSTOM HOOK: any screen that needs the category list calls useCategories().
// It loads the list once, reloads it when categories change on any device,
// and returns the names in display order ([] while loading).
//
// Hooks are just functions whose names start with "use" and that call other hooks
// (useState, useEffect). They let several screens share the same loading logic.
import { useEffect, useState } from 'react'
import { fetchCategories } from '../api/categories.js'
import { subscribeToTables } from './realtime.js'

// Used only if the list can't be loaded, so the item form still has choices.
const FALLBACK = ['Dairy & eggs', 'Produce', 'Meat & fish', 'Pantry', 'Frozen', 'Household', 'Hygiene']

export function useCategories() {
  const [names, setNames] = useState([])

  useEffect(() => {
    let ignore = false
    const load = () =>
      fetchCategories()
        .then((rows) => {
          if (!ignore) setNames(rows.map((c) => c.name))
        })
        .catch(() => {
          if (!ignore) setNames((current) => (current.length ? current : FALLBACK))
        })
    load()
    const stop = subscribeToTables(`categories-${Math.random()}`, ['categories'], load)
    return () => {
      ignore = true
      stop()
    }
  }, [])

  return names
}
