import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import ItemRow from './ItemRow.jsx'
import FilterChips from './FilterChips.jsx'
import SearchBox from './SearchBox.jsx'
import { fetchItems, saveItemStatus } from '../api/items.js'
import { supabase } from '../lib/supabase.js'
import { subscribeToTables } from '../lib/realtime.js'
import { useCategories } from '../lib/useCategories.js'

function groupByCategory(items) {
  const groups = {}
  for (const item of items) {
    if (!groups[item.category]) groups[item.category] = []
    groups[item.category].push(item)
  }
  return groups
}

// Lower-case and strip accents, so "creme" finds "Crème fraîche".
const normalize = (text) =>
  text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().trim()

const EMPTY_MESSAGES = {
  all: 'No items yet.',
  in: 'Nothing is in stock right now.',
  low: 'Nothing is low right now.',
  out: 'Nothing is out right now.',
}

export default function KitchenScreen() {
  const categoryOrder = useCategories().map((c) => c.name) // names, in the order set on the database
  const [items, setItems] = useState(null) // null = still loading
  const [loadError, setLoadError] = useState(null)
  const [saveError, setSaveError] = useState(null)
  const [filter, setFilter] = useState('all')
  const [query, setQuery] = useState('') // search text
  const [reloadCount, setReloadCount] = useState(0) // bump this to load again

  // useEffect runs AFTER the screen draws — the right place to fetch data.
  // The [reloadCount] at the end means: run again whenever reloadCount changes.
  useEffect(() => {
    let ignore = false // if the screen closes before the fetch finishes, drop the result
    setLoadError(null)
    fetchItems()
      .then((data) => {
        if (!ignore) setItems(data)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true // "cleanup": React runs this when the effect is thrown away
    }
  }, [reloadCount])

  // LIVE SYNC: listen for changes made on other devices.
  useEffect(() => {
    const channel = supabase
      .channel('items-changes')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'items' }, (change) => {
        if (change.eventType === 'UPDATE') {
          // Someone changed an item: copy the new values into that row.
          // (Its stores didn't change, so we keep the ones we already have.)
          const row = change.new
          setItems((current) => {
            const old = current?.find((i) => i.id === row.id)
            // Moved to another category: reload, to get the new category's name.
            if (old && old.category_id !== row.category_id) {
              setReloadCount((n) => n + 1)
              return current
            }
            return current?.map((i) =>
              i.id === row.id ? { ...i, name: row.name, status: row.status, usual_amount: row.usual_amount } : i,
            )
          })
        } else {
          // An item was added or deleted: simplest is to load the list again.
          setReloadCount((n) => n + 1)
        }
      })
      .subscribe()

    // Phones pause web apps in the background and the live connection can drop.
    // When the app comes back to the front, reload so nothing was missed.
    function handleVisible() {
      if (document.visibilityState === 'visible') setReloadCount((n) => n + 1)
    }
    document.addEventListener('visibilitychange', handleVisible)

    // CLEANUP: stop listening when the screen closes (e.g. on sign out).
    return () => {
      supabase.removeChannel(channel)
      document.removeEventListener('visibilitychange', handleVisible)
    }
  }, []) // [] = set this up once, when the screen first appears

  // Store names and item–store links show on every row, so reload when they change.
  useEffect(
    () => subscribeToTables('kitchen-stores', ['stores', 'item_stores'], () => setReloadCount((n) => n + 1)),
    [],
  )

  // OPTIMISTIC UPDATE: change the screen first, save in the background,
  // and put it back if the save fails.
  async function updateStatus(itemId, newStatus) {
    const item = items.find((i) => i.id === itemId)
    const previousStatus = item.status

    const setStatus = (status) =>
      setItems((current) => current.map((i) => (i.id === itemId ? { ...i, status } : i)))

    setStatus(newStatus)
    setSaveError(null)
    try {
      await saveItemStatus(itemId, newStatus)
    } catch {
      setStatus(previousStatus)
      setSaveError(`Couldn’t save ${item.name}. Check your connection and try again.`)
    }
  }

  if (loadError) {
    return (
      <div className="screen center-message">
        <p>Couldn’t load your pantry.</p>
        <p className="muted">{loadError}</p>
        <button type="button" className="primary" onClick={() => setReloadCount((n) => n + 1)}>
          Try again
        </button>
      </div>
    )
  }

  if (items === null) {
    return <div className="screen center-message muted">Loading…</div>
  }

  const outCount = items.filter((i) => i.status === 'out').length
  const lowCount = items.filter((i) => i.status === 'low').length

  // Two filters work together: the status chip AND the search text.
  const search = normalize(query)
  const visibleItems = items
    .filter((i) => filter === 'all' || i.status === filter)
    .filter((i) => search === '' || normalize(i.name).includes(search))
  const groups = groupByCategory(visibleItems)
  const categories = [
    ...categoryOrder.filter((c) => groups[c]), // categories in their saved order
    ...Object.keys(groups).filter((c) => !categoryOrder.includes(c)), // anything else (e.g. still loading) at the end
  ]

  return (
    <div className="screen">
      <header className="screen-header">
        <div>
          <span className="eyebrow">PANTRY</span>
          <h1>Kitchen</h1>
        </div>
        <div className="header-side">
          <div className="header-actions">
            <Link to="/stores" className="small-button">
              Stores
            </Link>
            <Link to="/categories" className="small-button">
              Categories
            </Link>
            <Link to="/help" className="small-button help-button" aria-label="Help">
              ?
            </Link>
            <Link to="/items/new" className="small-button add-button" aria-label="Add item">
              +
            </Link>
            <button type="button" className="link-button" onClick={() => supabase.auth.signOut()}>
              Sign out
            </button>
          </div>
          <span className="counts">
            {outCount} out · {lowCount} low
          </span>
        </div>
      </header>

      <SearchBox value={query} onChange={setQuery} />
      <FilterChips filter={filter} onChange={setFilter} />

      {saveError && (
        <p className="notice notice-inline" role="alert">
          {saveError}
        </p>
      )}

      <main className="item-list">
        {categories.length === 0 && !search && <p className="empty">{EMPTY_MESSAGES[filter]}</p>}

        {categories.length === 0 && search && (
          <div className="empty">
            <p>
              No {filter === 'all' ? '' : `${filter} `}items match “{query.trim()}”.
            </p>
            {/* Offer to create it, with the name already filled in. */}
            <Link to={`/items/new?name=${encodeURIComponent(query.trim())}`} className="small-button">
              + Add “{query.trim()}” as a new item
            </Link>
          </div>
        )}

        {categories.map((category) => (
          <section key={category}>
            <h2 className="section-title">{category.toUpperCase()}</h2>
            <ul>
              {groups[category].map((item) => (
                <ItemRow key={item.id} item={item} onStatusChange={updateStatus} />
              ))}
            </ul>
          </section>
        ))}
      </main>
    </div>
  )
}
