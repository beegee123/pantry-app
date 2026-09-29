import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import {
  fetchStores,
  fetchAnyStoreSummary,
  addStore,
  renameStore,
  removeStore,
} from '../api/stores.js'
import { subscribeToTables } from '../lib/realtime.js'

// "4 items linked" / "1 item linked"
const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

export default function StoresScreen() {
  const [stores, setStores] = useState(null) // null = loading
  const [anyStore, setAnyStore] = useState(null)
  const [loadError, setLoadError] = useState(null)
  const [actionError, setActionError] = useState(null)
  const [reloadCount, setReloadCount] = useState(0)
  const reload = () => setReloadCount((n) => n + 1)

  const [newName, setNewName] = useState('')
  const [editingId, setEditingId] = useState(null) // which store is being renamed
  const [editName, setEditName] = useState('')
  const [busy, setBusy] = useState(false)

  // Load stores and the "Any store" summary. Both requests run at the same time.
  useEffect(() => {
    let ignore = false
    Promise.all([fetchStores(), fetchAnyStoreSummary()])
      .then(([storeList, summary]) => {
        if (ignore) return
        setStores(storeList)
        setAnyStore(summary)
        setLoadError(null)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [reloadCount])

  // Reload when stores, links or item statuses change on any device.
  useEffect(() => subscribeToTables('stores-screen', ['stores', 'item_stores', 'items'], reload), [])

  // Runs an add / rename / remove, shows any error, then reloads the list.
  async function run(action) {
    setBusy(true)
    setActionError(null)
    try {
      await action()
      reload()
      return true
    } catch (err) {
      setActionError(err.message)
      return false
    } finally {
      setBusy(false)
    }
  }

  async function handleAdd(event) {
    event.preventDefault()
    const name = newName.trim()
    if (!name) return
    if (await run(() => addStore(name))) setNewName('')
  }

  function startRename(store) {
    setEditingId(store.id)
    setEditName(store.name)
    setActionError(null)
  }

  async function handleRename(event) {
    event.preventDefault()
    const name = editName.trim()
    const store = stores.find((s) => s.id === editingId)
    if (!name || name === store.name) {
      setEditingId(null) // nothing to change
      return
    }
    if (await run(() => renameStore(editingId, name))) setEditingId(null)
  }

  function handleRemove(store) {
    const message =
      store.linkedCount > 0
        ? `Remove ${store.name}? Its ${plural(store.linkedCount, 'item')} will move to Any store.`
        : `Remove ${store.name}?`
    // A destructive action always asks first.
    if (window.confirm(message)) run(() => removeStore(store.id))
  }

  return (
    <div className="screen">
      <header className="screen-header screen-header--sub">
        <Link to="/" className="back-link">
          ‹ Kitchen
        </Link>
        <span className="eyebrow">WHERE YOU SHOP</span>
        <h1>Stores</h1>
      </header>

      {loadError && (
        <div className="center-message">
          <p>Couldn’t load your stores.</p>
          <p className="muted">{loadError}</p>
          <button type="button" className="primary" onClick={reload}>
            Try again
          </button>
        </div>
      )}

      {!loadError && stores === null && <p className="center-message muted">Loading…</p>}

      {!loadError && stores !== null && (
        <main className="item-list">
          {actionError && (
            <p className="notice" role="alert">
              {actionError}
            </p>
          )}

          <ul>
            {stores.map((store) => (
              <li key={store.id} className="item-row store-row">
                {editingId === store.id ? (
                  <form className="rename-form" onSubmit={handleRename}>
                    <label className="visually-hidden" htmlFor={`rename-${store.id}`}>
                      New name for {store.name}
                    </label>
                    <input
                      id={`rename-${store.id}`}
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
                    <div className="item-text">
                      <span className="item-name">{store.name}</span>
                      <span className="item-store">
                        {plural(store.linkedCount, 'item')} linked
                        {store.neededCount > 0 && (
                          <span className="needed"> · {store.neededCount} needed</span>
                        )}
                      </span>
                    </div>
                    <button type="button" className="link-button" onClick={() => startRename(store)}>
                      Rename
                    </button>
                    <button
                      type="button"
                      className="link-button danger"
                      onClick={() => handleRemove(store)}
                      disabled={busy}
                    >
                      Remove
                    </button>
                  </>
                )}
              </li>
            ))}

            {anyStore && (
              <li className="item-row store-row store-row--any">
                <div className="item-text">
                  <span className="item-name">Any store</span>
                  <span className="item-store">
                    {plural(anyStore.linkedCount, 'item')} with no store picked
                    {anyStore.neededCount > 0 && (
                      <span className="needed"> · {anyStore.neededCount} needed</span>
                    )}
                  </span>
                </div>
              </li>
            )}
          </ul>

          <form className="add-row" onSubmit={handleAdd}>
            <label className="visually-hidden" htmlFor="new-store">
              New store name
            </label>
            <input
              id="new-store"
              placeholder="New store name"
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
