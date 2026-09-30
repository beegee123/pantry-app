// The search box at the top of the Kitchen screen.
// It only holds the text; KitchenScreen decides what matches.

// Props:
//   value    — the current search text
//   onChange — function(newText), called on every keystroke and when cleared
export default function SearchBox({ value, onChange }) {
  return (
    <div className="search-box" role="search">
      <label htmlFor="kitchen-search" className="visually-hidden">
        Search items
      </label>
      <svg className="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor"
        strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
        <circle cx="11" cy="11" r="7" />
        <path d="M20 20l-3.5-3.5" />
      </svg>
      <input
        id="kitchen-search"
        type="search"
        placeholder="Search items"
        autoComplete="off"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onKeyDown={(e) => e.key === 'Escape' && onChange('')}
      />
      {value && (
        <button type="button" className="search-clear" aria-label="Clear search" onClick={() => onChange('')}>
          ✕
        </button>
      )}
    </div>
  )
}
