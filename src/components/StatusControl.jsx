// The In / Low / Out switch on each row.
// It shows the current status and reports taps to its parent through `onChange`.

const STATUSES = [
  { value: 'in', label: 'In' },
  { value: 'low', label: 'Low' },
  { value: 'out', label: 'Out' },
]

// Props:
//   status   — the current status: 'in', 'low' or 'out'
//   onChange — a function to call with the new status when a button is tapped
export default function StatusControl({ status, onChange }) {
  return (
    <div className="status-control" role="group" aria-label="Stock status">
      {STATUSES.map((s) => (
        <button
          key={s.value} // React needs a unique key for each item in a list
          type="button"
          className={status === s.value ? `is-on is-${s.value}` : ''}
          aria-pressed={status === s.value}
          onClick={() => {
            // Tapping the status it already has does nothing.
            if (s.value !== status) onChange(s.value)
          }}
        >
          {s.label}
        </button>
      ))}
    </div>
  )
}
