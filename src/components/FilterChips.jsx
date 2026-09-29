// The All / Low / Out chips under the header.

const FILTERS = [
  { value: 'all', label: 'All' },
  { value: 'low', label: 'Low' },
  { value: 'out', label: 'Out' },
]

// Props:
//   filter   — the chip that is currently selected
//   onChange — function(newFilter), called when a chip is tapped
export default function FilterChips({ filter, onChange }) {
  return (
    <div className="filter-chips" role="group" aria-label="Show">
      {FILTERS.map((f) => (
        <button
          key={f.value}
          type="button"
          className={filter === f.value ? 'chip is-on' : 'chip'}
          aria-pressed={filter === f.value}
          onClick={() => onChange(f.value)}
        >
          {f.label}
        </button>
      ))}
    </div>
  )
}
