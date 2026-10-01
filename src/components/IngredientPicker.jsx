import { useState } from 'react'
import StatusControl from './StatusControl.jsx'
import { CATEGORIES } from '../lib/categories.js'

// Same matching as the Kitchen search: ignore case and accents.
const normalize = (text) =>
  text.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim()

const MAX_SUGGESTIONS = 6

// The ingredient list on the recipe form.
// Every ingredient is a PANTRY ITEM — you search your pantry, or create a new item here.
//
// Props:
//   items        — all pantry items [{ id, name, category, status }]
//   ingredients  — the chosen list, in order [{ item_id, name, amount_text }]
//   onChange     — function(newIngredients)
//   onCreateItem — async function({ name, category, status }) → the new item { id, name, ... }
export default function IngredientPicker({ items, ingredients, onChange, onCreateItem }) {
  const [query, setQuery] = useState('')
  const [creating, setCreating] = useState(null) // { name, category, status } while the mini form is open
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(null)

  const chosenIds = new Set(ingredients.map((i) => i.item_id))
  const search = normalize(query)
  const suggestions = search
    ? items.filter((i) => !chosenIds.has(i.id) && normalize(i.name).includes(search)).slice(0, MAX_SUGGESTIONS)
    : []
  const exactMatch = items.some((i) => normalize(i.name) === search)

  // ---- changing the list (always a NEW array — immutability) ----
  function add(item) {
    onChange([...ingredients, { item_id: item.id, name: item.name, amount_text: '' }])
    setQuery('')
  }
  function setAmount(index, amount_text) {
    onChange(ingredients.map((ing, i) => (i === index ? { ...ing, amount_text } : ing)))
  }
  function remove(index) {
    onChange(ingredients.filter((_, i) => i !== index))
  }
  function move(index, direction) {
    const target = index + direction
    if (target < 0 || target >= ingredients.length) return
    const next = [...ingredients]
    ;[next[index], next[target]] = [next[target], next[index]] // swap the two
    onChange(next)
  }

  // ---- creating a new pantry item without leaving the recipe ----
  function startCreate() {
    const name = query.trim()
    // "scotch bonnet" → "Scotch bonnet", to match how the rest of the pantry is written.
    setCreating({ name: name.charAt(0).toUpperCase() + name.slice(1), category: 'Pantry', status: 'in' })
    setError(null)
  }
  async function finishCreate() {
    setBusy(true)
    setError(null)
    try {
      const item = await onCreateItem(creating)
      add(item)
      setCreating(null)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="ingredient-picker">
      {ingredients.length === 0 && <p className="muted small">No ingredients yet. Search your pantry below.</p>}

      <ol className="ingredient-list">
        {ingredients.map((ing, index) => (
          <li key={ing.item_id} className="ingredient-row">
            <div className="ingredient-move">
              <button type="button" aria-label={`Move ${ing.name} up`} onClick={() => move(index, -1)} disabled={index === 0}>
                ↑
              </button>
              <button
                type="button"
                aria-label={`Move ${ing.name} down`}
                onClick={() => move(index, 1)}
                disabled={index === ingredients.length - 1}
              >
                ↓
              </button>
            </div>
            <span className="ingredient-name">{ing.name}</span>
            <label className="visually-hidden" htmlFor={`amount-${ing.item_id}`}>
              Amount of {ing.name}
            </label>
            <input
              id={`amount-${ing.item_id}`}
              className="ingredient-amount"
              placeholder="Amount"
              value={ing.amount_text}
              onChange={(e) => setAmount(index, e.target.value)}
            />
            <button type="button" className="ingredient-remove" aria-label={`Remove ${ing.name}`} onClick={() => remove(index)}>
              ✕
            </button>
          </li>
        ))}
      </ol>

      {!creating && (
        <div className="ingredient-search">
          <label className="visually-hidden" htmlFor="ingredient-search">
            Add an ingredient from your pantry
          </label>
          <input
            id="ingredient-search"
            placeholder="+ Add an ingredient…"
            autoComplete="off"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              // Enter picks the first match instead of submitting the whole form.
              if (e.key === 'Enter') {
                e.preventDefault()
                if (suggestions[0]) add(suggestions[0])
                else if (search && !exactMatch) startCreate()
              }
            }}
          />
          {search && (
            <ul className="suggestions">
              {suggestions.map((item) => (
                <li key={item.id}>
                  <button type="button" onClick={() => add(item)}>
                    {item.name}
                    <span className="muted"> · {item.category}</span>
                  </button>
                </li>
              ))}
              {!exactMatch && (
                <li>
                  <button type="button" className="suggestion-new" onClick={startCreate}>
                    + Add “{query.trim()}” to pantry
                  </button>
                </li>
              )}
            </ul>
          )}
        </div>
      )}

      {creating && (
        <div className="new-item-box">
          <p className="new-item-title">New pantry item: {creating.name}</p>
          <div className="chip-row">
            {CATEGORIES.map((c) => (
              <button
                key={c}
                type="button"
                className={creating.category === c ? 'chip is-on' : 'chip'}
                aria-pressed={creating.category === c}
                onClick={() => setCreating({ ...creating, category: c })}
              >
                {c}
              </button>
            ))}
          </div>
          <div className="new-item-status">
            <span className="muted small">Do you have it right now?</span>
            <StatusControl status={creating.status} onChange={(status) => setCreating({ ...creating, status })} />
          </div>
          {error && <p className="notice">{error}</p>}
          <div className="new-item-actions">
            <button type="button" className="link-button" onClick={() => setCreating(null)}>
              Cancel
            </button>
            <button type="button" className="small-button" onClick={finishCreate} disabled={busy}>
              {busy ? 'Adding…' : 'Add to pantry and recipe'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
