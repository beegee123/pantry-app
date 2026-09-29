import { useEffect, useState } from 'react'
import { fetchShoppingList, setInCart, finishTrip } from '../api/shopping.js'
import { subscribeToTables } from '../lib/realtime.js'

const ANY_STORE = 'any'

// Decide which store heading each item goes under:
//   its preferred store → else its first store (A–Z) → else "Any store".
// Each item appears ONCE, with the other stores listed as "also at".
function groupByStore(items) {
  const groups = new Map() // key → { key, name, items }

  for (const item of items) {
    const byName = [...item.stores].sort((a, b) => a.name.localeCompare(b.name))
    const home = item.stores.find((s) => s.is_preferred) ?? byName[0]
    const key = home ? home.id : ANY_STORE
    const name = home ? home.name : 'Any store'
    const alsoAt = byName.filter((s) => s !== home).map((s) => s.name)

    if (!groups.has(key)) groups.set(key, { key, name, items: [] })
    groups.get(key).items.push({ ...item, alsoAt })
  }

  // Stores A–Z, with "Any store" last.
  return [...groups.values()].sort((a, b) => {
    if (a.key === ANY_STORE) return 1
    if (b.key === ANY_STORE) return -1
    return a.name.localeCompare(b.name)
  })
}

// The small grey line under an item: "Usual: 1 bag · also at No Frills"
function rowDetails(item) {
  const parts = []
  if (item.in_cart) parts.push('In cart')
  else if (item.usual_amount) parts.push(`Usual: ${item.usual_amount}`)
  if (item.alsoAt.length > 0) parts.push(`also at ${item.alsoAt.join(', ')}`)
  return parts.join(' · ')
}

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

export default function ShoppingScreen() {
  const [items, setItems] = useState(null) // null = loading
  const [loadError, setLoadError] = useState(null)
  const [actionError, setActionError] = useState(null)
  const [message, setMessage] = useState(null) // e.g. "Restocked 4 items."
  const [storeFilter, setStoreFilter] = useState('all')
  const [busy, setBusy] = useState(false)
  const [reloadCount, setReloadCount] = useState(0)
  const reload = () => setReloadCount((n) => n + 1)

  useEffect(() => {
    let ignore = false
    fetchShoppingList()
      .then((data) => {
        if (ignore) return
        setItems(data)
        setLoadError(null)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [reloadCount])

  // Someone else ticks an item, changes a status or edits stores → reload.
  useEffect(() => subscribeToTables('shopping', ['items', 'item_stores', 'stores'], reload), [])

  // Tick / untick: optimistic, like the status buttons on the Kitchen.
  async function toggleCart(item) {
    const next = !item.in_cart
    const setTick = (value) =>
      setItems((current) => current.map((i) => (i.id === item.id ? { ...i, in_cart: value } : i)))

    setTick(next)
    setActionError(null)
    setMessage(null)
    try {
      await setInCart(item.id, next)
    } catch {
      setTick(!next)
      setActionError(`Couldn’t update ${item.name}. Check your connection and try again.`)
    }
  }

  async function handleFinish() {
    setBusy(true)
    setActionError(null)
    try {
      const count = await finishTrip()
      setMessage(`Restocked ${plural(count, 'item')}.`)
      reload()
    } catch (err) {
      setActionError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const header = (
    <header className="screen-header">
      <div>
        <span className="eyebrow">TO BUY</span>
        <h1>Shopping list</h1>
      </div>
    </header>
  )

  if (loadError) {
    return (
      <div className="screen">
        {header}
        <div className="center-message">
          <p>Couldn’t load your shopping list.</p>
          <p className="muted">{loadError}</p>
          <button type="button" className="primary" onClick={reload}>
            Try again
          </button>
        </div>
      </div>
    )
  }

  if (items === null) {
    return (
      <div className="screen">
        {header}
        <p className="center-message muted">Loading…</p>
      </div>
    )
  }

  const groups = groupByStore(items)
  // If the chosen store has nothing left (e.g. after finishing), fall back to All.
  const activeFilter = groups.some((g) => g.key === storeFilter) ? storeFilter : 'all'
  const visibleGroups = activeFilter === 'all' ? groups : groups.filter((g) => g.key === activeFilter)
  const cartCount = items.filter((i) => i.in_cart).length

  return (
    <div className="screen">
      {header}
      <p className="screen-subtitle">
        {items.length === 0
          ? 'Nothing to buy right now.'
          : `${plural(items.length, 'item')} across ${plural(groups.length, 'store')}`}
      </p>

      {groups.length > 1 && (
        <div className="filter-chips filter-chips--scroll" role="group" aria-label="Show store">
          <button
            type="button"
            className={activeFilter === 'all' ? 'chip is-on' : 'chip'}
            aria-pressed={activeFilter === 'all'}
            onClick={() => setStoreFilter('all')}
          >
            All
          </button>
          {groups.map((g) => (
            <button
              key={g.key}
              type="button"
              className={activeFilter === g.key ? 'chip is-on' : 'chip'}
              aria-pressed={activeFilter === g.key}
              onClick={() => setStoreFilter(g.key)}
            >
              {g.name} {g.items.length}
            </button>
          ))}
        </div>
      )}

      {message && (
        <p className="notice notice-success notice-inline" role="status">
          {message}
        </p>
      )}
      {actionError && (
        <p className="notice notice-inline" role="alert">
          {actionError}
        </p>
      )}

      <main className="item-list">
        {visibleGroups.map((group) => (
          <section key={group.key}>
            <h2 className="section-title section-title--split">
              <span>{group.name.toUpperCase()}</span>
              <span>{group.items.length}</span>
            </h2>
            <ul>
              {group.items.map((item) => (
                <li key={item.id} className={item.in_cart ? 'shop-row is-done' : 'shop-row'}>
                  <button
                    type="button"
                    className="cart-check"
                    aria-pressed={item.in_cart}
                    aria-label={item.in_cart ? `Take ${item.name} out of the cart` : `Put ${item.name} in the cart`}
                    onClick={() => toggleCart(item)}
                  >
                    <span className={item.in_cart ? 'box is-on' : 'box'} aria-hidden="true">
                      {item.in_cart ? '✓' : ''}
                    </span>
                  </button>
                  <div className="item-text">
                    <span className="item-name">{item.name}</span>
                    <span className="item-store">{rowDetails(item)}</span>
                  </div>
                  <span className={`pill pill-${item.status}`}>{item.status.toUpperCase()}</span>
                </li>
              ))}
            </ul>
          </section>
        ))}

        {items.length > 0 && (
          <button
            type="button"
            className="primary finish-button"
            onClick={handleFinish}
            disabled={busy || cartCount === 0}
          >
            {busy
              ? 'Finishing…'
              : cartCount === 0
                ? 'Tick items as they go in the cart'
                : `Finish trip · restock ${plural(cartCount, 'item')}`}
          </button>
        )}
      </main>
    </div>
  )
}
