import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import {
  fetchCategoriesWithCounts,
  addCategory,
  renameCategory,
  reorderCategories,
  removeCategory,
} from '../api/categories.js'
import { subscribeToTables } from '../lib/realtime.js'

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

// Add, rename, reorder and remove categories. The Kitchen sections follow this order.
// Built like the Stores screen: run() handles busy / error / reload for every action.
export default function CategoriesScreen() {
  const [categories, setCategories] = useState(null) // null = loading
  const [loadError, setLoadError] = useState(null)
  const [actionError, setActionError] = useState(null)
  const [reloadCount, setReloadCount] = useState(0)
  const reload = () => setReloadCount((n) => n + 1)

  const [newName, setNewName] = useState('')
  const [editingId, setEditingId] = useState(null) // being renamed
  const [editName, setEditName] = useState('')
  const [removing, setRemoving] = useState(null) // { id, moveToId } while choosing where its items go
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    let ignore = false
    fetchCategoriesWithCounts()
      .then((data) => {
        if (ignore) return
        setCategories(data)
        setLoadError(null)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [reloadCount])

  // Changes on another phone (or items moving category) → reload.
  useEffect(() => subscribeToTables('categories-screen', ['categories', 'items'], reload), [])

  async function run(action) {
    setBusy(true)
    setActionError(null)
    try {
      await action()
      reload()
      return true
    } catch (err) {
      setActionError(err.message)
      reload() // show what's really saved (e.g. after a failed reorder)
      return false
    } finally {
      setBusy(false)
    }
  }

  async function handleAdd(event) {
    event.preventDefault()
    const typed = newName.trim()
    if (!typed) return
    const name = typed.charAt(0).toUpperCase() + typed.slice(1) // "bakery" → "Bakery"
    const lastPosition = Math.max(0, ...categories.map((c) => c.position))
    if (await run(() => addCategory(name, lastPosition + 1))) setNewName('')
  }

  function startRename(category) {
    setRemoving(null)
    setEditingId(category.id)
    setEditName(category.name)
    setActionError(null)
  }

  async function handleRename(event) {
    event.preventDefault()
    const name = editName.trim()
    const category = categories.find((c) => c.id === editingId)
    if (!name || name === category.name) {
      setEditingId(null)
      return
    }
    if (await run(() => renameCategory(editingId, name))) setEditingId(null)
  }

  // Move one place up (-1) or down (+1). OPTIMISTIC: the list moves straight away;
  // if saving fails, run() reloads the saved order and shows the error.
  function move(index, direction) {
    const next = [...categories]
    const [moved] = next.splice(index, 1)
    next.splice(index + direction, 0, moved)
    setCategories(next)
    run(() => reorderCategories(next.map((c) => c.id)))
  }

  function startRemove(category) {
    setEditingId(null)
    setActionError(null)
    if (category.itemCount === 0) {
      if (window.confirm(`Remove ${category.name}?`)) run(() => removeCategory(category.id, null))
      return
    }
    setRemoving({ id: category.id, moveToId: null }) // items need a new home first
  }

  async function confirmRemove() {
    if (await run(() => removeCategory(removing.id, removing.moveToId))) setRemoving(null)
  }

  return (
    <div className="screen">
      <header className="screen-header screen-header--sub">
        <Link to="/" className="back-link">
          ‹ Kitchen
        </Link>
        <span className="eyebrow">HOW YOUR KITCHEN IS GROUPED</span>
        <h1>Categories</h1>
      </header>
      {categories !== null && !loadError && (
        <p className="screen-subtitle">The Kitchen shows its sections in this order.</p>
      )}

      {loadError && (
        <div className="center-message">
          <p>Couldn’t load your categories.</p>
          <p className="muted">{loadError}</p>
          <button type="button" className="primary" onClick={reload}>
            Try again
          </button>
        </div>
      )}

      {!loadError && categories === null && <p className="center-message muted">Loading…</p>}

      {!loadError && categories !== null && (
        <main className="item-list">
          {actionError && (
            <p className="notice" role="alert">
              {actionError}
            </p>
          )}

          <ul>
            {categories.map((category, index) => (
              <li key={category.id} className="item-row store-row category-row">
                {editingId === category.id ? (
                  <form className="rename-form" onSubmit={handleRename}>
                    <label className="visually-hidden" htmlFor={`rename-${category.id}`}>
                      New name for {category.name}
                    </label>
                    <input
                      id={`rename-${category.id}`}
                      value={editName}
                      onChange={(e) => setEditName(e.target.value)}
                      onKeyDown={(e) => e.key === 'Escape' && setEditingId(null)}
                      autoFocus
                    />
                    <button type="submit" className="small-button" disabled={busy}>
                      Save
                    </button>
                    <button type="button" className="link-button" onClick={() => setEditingId(null)}>
                      Cancel
                    </button>
                  </form>
                ) : (
                  <>
                    <div className="ingredient-move">
                      <button
                        type="button"
                        aria-label={`Move ${category.name} up`}
                        disabled={busy || index === 0}
                        onClick={() => move(index, -1)}
                      >
                        ↑
                      </button>
                      <button
                        type="button"
                        aria-label={`Move ${category.name} down`}
                        disabled={busy || index === categories.length - 1}
                        onClick={() => move(index, +1)}
                      >
                        ↓
                      </button>
                    </div>
                    <div className="item-text">
                      <span className="item-name">{category.name}</span>
                      <span className="item-store">{plural(category.itemCount, 'item')}</span>
                    </div>
                    <button type="button" className="link-button" onClick={() => startRename(category)}>
                      Rename
                    </button>
                    <button
                      type="button"
                      className="link-button danger"
                      onClick={() => startRemove(category)}
                      disabled={busy}
                    >
                      Remove
                    </button>
                  </>
                )}

                {/* Removing a category that items use: pick where they go. */}
                {removing?.id === category.id && (
                  <div className="new-item-box move-items-box">
                    <p className="new-item-title">
                      Move its {plural(category.itemCount, 'item')} to:
                    </p>
                    <div className="chip-row">
                      {categories
                        .filter((c) => c.id !== category.id)
                        .map((c) => (
                          <button
                            key={c.id}
                            type="button"
                            className={removing.moveToId === c.id ? 'chip is-on' : 'chip'}
                            aria-pressed={removing.moveToId === c.id}
                            onClick={() => setRemoving({ ...removing, moveToId: c.id })}
                          >
                            {c.name}
                          </button>
                        ))}
                    </div>
                    <div className="new-item-actions">
                      <button type="button" className="link-button" onClick={() => setRemoving(null)}>
                        Cancel
                      </button>
                      <button
                        type="button"
                        className="small-button small-button--danger"
                        disabled={busy || !removing.moveToId}
                        onClick={confirmRemove}
                      >
                        Move and remove {category.name}
                      </button>
                    </div>
                  </div>
                )}
              </li>
            ))}
          </ul>

          <form className="add-row" onSubmit={handleAdd}>
            <label className="visually-hidden" htmlFor="new-category">
              New category name
            </label>
            <input
              id="new-category"
              placeholder="New category name"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
            />
            <button type="submit" className="primary" disabled={busy || !newName.trim()}>
              Add
            </button>
          </form>
        </main>
      )}
    </div>
  )
}
