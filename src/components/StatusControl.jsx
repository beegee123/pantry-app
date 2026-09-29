// The In / Low / Out switch on each row.
// Step 2: it only SHOWS the current status. Step 3 makes the buttons work.

const STATUSES = [
  { value: 'in', label: 'In' },
  { value: 'low', label: 'Low' },
  { value: 'out', label: 'Out' },
]

// A component is a function that takes "props" (inputs) and returns what to draw.
// Here the only prop is `status` — 'in', 'low' or 'out'.
export default function StatusControl({ status }) {
  return (
    <div className="status-control" role="group" aria-label="Stock status">
      {STATUSES.map((s) => (
        <button
          key={s.value} // React needs a unique key for each item in a list
          type="button"
          className={status === s.value ? `is-on is-${s.value}` : ''}
          aria-pressed={status === s.value}
        >
          {s.label}
        </button>
      ))}
    </div>
  )
}
