import { useEffect, useState } from 'react'
import ItemRow from './ItemRow.jsx'
import FilterChips from './FilterChips.jsx'
import { fetchItems, saveItemStatus } from '../api/items.js'
import { supabase } from '../lib/supabase.js'

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
          <button type="button" className="link-button" onClick={() => supabase.auth.signOut()}>
            Sign out
          </button>
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
