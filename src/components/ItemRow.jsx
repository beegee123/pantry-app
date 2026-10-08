import { Link } from 'react-router'
import StatusControl from './StatusControl.jsx'

// Turn an item's store list into the small grey line under its name.
// Preferred store first; no stores at all → "Any store".
function storeLabel(stores) {
  if (stores.length === 0) return 'Any store'
  const sorted = [...stores].sort((a, b) => b.is_preferred - a.is_preferred)
  return sorted.map((s) => s.name).join(' · ')
}

// One row in the Kitchen list.
// Props:
//   item           — the item to show
//   onStatusChange — function(itemId, newStatus), provided by App
//   reviewList     — the Kitchen's visible items in order [{ id, name }], handed to the edit
//                    screen so its ‹ › arrows can step through them (step 8e)
export default function ItemRow({ item, onStatusChange, reviewList }) {
  return (
    <li className="item-row">
      <div className="item-text">
        {/* Tap the name to edit the item. */}
        <Link to={`/items/${item.id}`} state={{ reviewList }} className="item-name item-link">
          {item.name}
        </Link>
        <span className="item-store">{storeLabel(item.stores)}</span>
      </div>
      {/* The switch only knows the new status; we add which item it belongs to. */}
      <StatusControl
        status={item.status}
        onChange={(newStatus) => onStatusChange(item.id, newStatus)}
      />
    </li>
  )
}
