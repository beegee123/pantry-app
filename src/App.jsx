import ItemRow from './components/ItemRow.jsx'
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

export default function App() {
  const items = sampleItems
  const groups = groupByCategory(items)

  // Categories in a fixed, sensible order; skip empty ones.
  const categories = CATEGORY_ORDER.filter((c) => groups[c])

  const outCount = items.filter((i) => i.status === 'out').length
  const lowCount = items.filter((i) => i.status === 'low').length

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

      <main className="item-list">
        {categories.map((category) => (
          <section key={category}>
            <h2 className="section-title">{category.toUpperCase()}</h2>
            <ul>
              {groups[category].map((item) => (
                <ItemRow key={item.id} item={item} />
              ))}
            </ul>
          </section>
        ))}
      </main>
    </div>
  )
}
