// Date helpers for the weekly menu. Weeks run Monday → Sunday.
//
// We store plain dates like "2026-10-05" (no time, no time zone). Careful: JavaScript's
// toISOString() converts to UTC, which in Buffalo at 9 pm is already TOMORROW — so we
// build the "YYYY-MM-DD" text from the LOCAL year, month and day instead.

const pad = (n) => String(n).padStart(2, '0')

export const toISODate = (date) => `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`

// "2026-10-05" → a Date at local midnight (new Date("2026-10-05") would be UTC midnight).
export function fromISODate(text) {
  const [y, m, d] = text.split('-').map(Number)
  return new Date(y, m - 1, d)
}

export function addDays(date, days) {
  const copy = new Date(date)
  copy.setDate(copy.getDate() + days) // handles month ends and clock changes
  return copy
}

// The Monday on or before `date`. getDay(): Sunday = 0, Monday = 1 … Saturday = 6.
export function startOfWeek(date) {
  const daysSinceMonday = (date.getDay() + 6) % 7
  const monday = addDays(date, -daysSinceMonday)
  monday.setHours(0, 0, 0, 0)
  return monday
}

export const today = () => toISODate(new Date())

// The 7 dates of the week starting `monday`, as "YYYY-MM-DD" text.
export const weekDates = (monday) => Array.from({ length: 7 }, (_, i) => toISODate(addDays(monday, i)))

// "MON", "28"
export const dayName = (iso) => fromISODate(iso).toLocaleDateString('en-US', { weekday: 'short' }).toUpperCase()
export const dayNumber = (iso) => String(fromISODate(iso).getDate())
export const shortDay = (iso) => fromISODate(iso).toLocaleDateString('en-US', { weekday: 'short' }) // "Tue"

// "SEP 28 – OCT 4"
export function weekRangeLabel(monday) {
  const fmt = (d) => d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' }).toUpperCase()
  return `${fmt(monday)} – ${fmt(addDays(monday, 6))}`
}
