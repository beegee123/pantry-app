import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import ItemRow from './ItemRow.jsx'
import FilterChips from './FilterChips.jsx'
import { fetchItems, saveItemStatus } from '../api/items.js'
import { supabase } from '../lib/supabase.js'
import { subscribeToTables } from '../lib/realtime.js'

// Categories we know about, in display order. Any new category goes at the end.
const CATEGORY_ORDER = ['Dairy & eggs', 'Produce', 'Pantry', 'Frozen', 'Household']

function groupByCategory(items) {
  const groups = {}
  for (const item of items) {
    if (!groups[item.category]) groups[item.category] = []
    groups[item.category].push(item)
  }
  return groups
}

const EMPTY_MESSAGES = {
  all: 'No items yet.',
  low: 'Nothing is low right now.',
  out: 'Nothing is out right now.',
}

export default function KitchenScreen() {
  const [items, setItems] = useState(null) // null = still loading
  const [loadError, setLoadError] = useState(null)
  const [saveError, setSaveError] = useState(null)
  const [filter, setFilter] = useState('all')
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
          setItems((current) =>
            current?.map((i) =>
              i.id === row.id
                ? { ...i, name: row.name, category: row.category, status: row.status, usual_amount: row.usual_amount }
                : i,
            ),
          )
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

  const visibleItems = filter === 'all' ? items : items.filter((i) => i.status === filter)
  const groups = groupByCategory(visibleItems)
  const categories = [
    ...CATEGORY_ORDER.filter((c) => groups[c]),
    ...Object.keys(groups).filter((c) => !CATEGORY_ORDER.includes(c)),
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
            <button type="button" className="link-button" onClick={() => supabase.auth.signOut()}>
              Sign out
            </button>
          </div>
          <span className="counts">
            {outCount} out · {lowCount} low
          </span>
        </div>
      </header>

      <FilterChips filter={filter} onChange={setFilter} />

      {saveError && (
        <p className="notice notice-inline" role="alert">
          {saveError}
        </p>
      )}

      <main className="item-list">
        {categories.length === 0 && <p className="empty">{EMPTY_MESSAGES[filter]}</p>}

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
