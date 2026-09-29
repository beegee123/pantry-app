import StatusControl from './StatusControl.jsx'

// Turn an item's store list into the small grey line under its name.
// Preferred store first; no stores at all → "Any store".
function storeLabel(stores) {
  if (stores.length === 0) return 'Any store'
  const sorted = [...stores].sort((a, b) => b.is_preferred - a.is_preferred)
  return sorted.map((s) => s.name).join(' · ')
}

// One row in the Kitchen list.
export default function ItemRow({ item }) {
  return (
    <li className="item-row">
      <div className="item-text">
        <span className="item-name">{item.name}</span>
        <span className="item-store">{storeLabel(item.stores)}</span>
      </div>
      <StatusControl status={item.status} />
    </li>
  )
}
