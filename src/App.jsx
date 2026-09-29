import { useState } from 'react'
import ItemRow from './components/ItemRow.jsx'
import FilterChips from './components/FilterChips.jsx'
import { sampleItems, CATEGORY_ORDER } from './data/sampleItems.js'

// Group a flat list of items into { 'Pantry': [...], 'Household': [...] }.
function groupByCategory(items) {
  const groups = {}
  for (const item of items) {
    if (!groups[item.category]) groups[item.category] = []
    groups[item.category].push(item)
  }
  return groups
}

// What to say when a filter matches nothing.
const EMPTY_MESSAGES = {
  all: 'No items yet.',
  low: 'Nothing is low right now.',
  out: 'Nothing is out right now.',
}

export default function App() {
  // STATE — data that can change. When it changes, React redraws the screen.
  // `items` lives here in App (not in each row) because the counts and the
  // filters need to see every item. This is "lifting state up".
  const [items, setItems] = useState(sampleItems)
  const [filter, setFilter] = useState('all') // 'all' | 'low' | 'out'

  // Called by a row when you tap In / Low / Out.
  // We build a NEW list with that one item changed (immutability),
  // instead of editing the old list, so React notices the change.
  function updateStatus(itemId, newStatus) {
    setItems((current) =>
      current.map((item) => (item.id === itemId ? { ...item, status: newStatus } : item)),
    )
  }

  // DERIVED values — worked out from state on every redraw, never stored.
  const outCount = items.filter((i) => i.status === 'out').length
  const lowCount = items.filter((i) => i.status === 'low').length

  const visibleItems = filter === 'all' ? items : items.filter((i) => i.status === filter)
  const groups = groupByCategory(visibleItems)
  const categories = CATEGORY_ORDER.filter((c) => groups[c]) // fixed order, skip empty ones

  return (
    <div className="screen">
      <header className="screen-header">
        <div>
          <span className="eyebrow">PANTRY</span>
          <h1>Kitchen</h1>
        </div>
        <span className="counts">
          {outCount} out · {lowCount} low
        </span>
      </header>

      <FilterChips filter={filter} onChange={setFilter} />

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
