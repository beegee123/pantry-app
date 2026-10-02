import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate, useSearchParams } from 'react-router'
import RecipeThumb from './RecipeThumb.jsx'
import { fetchPlan, neededByMenu } from '../api/menu.js'
import { getPhotoUrls } from '../api/photos.js'
import { subscribeToTables } from '../lib/realtime.js'
import { readiness } from '../lib/readiness.js'
import {
  addDays,
  dayName,
  dayNumber,
  fromISODate,
  shortDay,
  startOfWeek,
  toISODate,
  today,
  weekDates,
  weekRangeLabel,
} from '../lib/dates.js'

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

// "This week", "Next week", "Last week", or "Week of Oct 12".
function weekTitle(monday) {
  const weeksAway = Math.round((monday - startOfWeek(new Date())) / (7 * 24 * 60 * 60 * 1000))
  if (weeksAway === 0) return 'This week'
  if (weeksAway === 1) return 'Next week'
  if (weeksAway === -1) return 'Last week'
  return `Week of ${monday.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}`
}

// Step 18: what the rest of the week still needs. Out and Low items are already on the
// shopping list (that's how the list works), so this card just shows them and links there.
function WeekNeeds({ plan, fromDate, title }) {
  const upcoming = plan.filter((p) => p.plan_date >= fromDate)
  if (upcoming.length === 0) return null

  const needed = neededByMenu(upcoming)
  if (needed.size === 0) {
    return <p className="readiness-card is-ready">Everything for the planned dinners is in.</p>
  }

  // One entry per item, with the first day it's needed: "Rice (Tue)".
  const names = new Map()
  for (const { recipe } of upcoming) {
    for (const ing of recipe.ingredients) {
      if (needed.has(ing.item_id)) names.set(ing.item_id, ing.name)
    }
  }
  const list = [...needed.entries()].map(([itemId, uses]) => `${names.get(itemId)} (${shortDay(uses[0].plan_date)})`)

  return (
    <div className="readiness-card week-needs">
      <p className="readiness-title">
        {title} needs {plural(needed.size, 'item')}
      </p>
      <p className="week-needs-list">{list.join(' · ')}</p>
      <Link to="/shopping?show=menu" className="text-link">
        Already on your shopping list ›
      </Link>
    </div>
  )
}

export default function MenuScreen() {
  const [searchParams, setSearchParams] = useSearchParams()
  const location = useLocation()
  const navigate = useNavigate()
  // A one-time message from the generator ("Planned 5 dinners."), passed as navigation state.
  const [message, setMessage] = useState(location.state?.message ?? null)
  useEffect(() => {
    // Clear it from the history entry, so a refresh or Back doesn't show it again.
    if (location.state?.message) navigate(location.pathname + location.search, { replace: true, state: null })
  }, []) // eslint-disable-line react-hooks/exhaustive-deps -- only on arrival
  // The week comes from the address (/menu?week=2026-10-05), so Back returns to the same week.
  const monday = startOfWeek(searchParams.get('week') ? fromISODate(searchParams.get('week')) : new Date())
  const mondayISO = toISODate(monday)
  const dates = weekDates(monday)

  const [plan, setPlan] = useState(null) // null = loading
  const [photoUrls, setPhotoUrls] = useState({})
  const [loadError, setLoadError] = useState(null)
  const [reloadCount, setReloadCount] = useState(0)
  const reload = () => setReloadCount((n) => n + 1)

  useEffect(() => {
    let ignore = false
    setPlan(null)
    fetchPlan(dates[0], dates[6])
      .then((data) => {
        if (ignore) return
        setPlan(data)
        setLoadError(null)
        return getPhotoUrls(data.map((p) => p.recipe.photo_path))
          .then((urls) => {
            if (!ignore) setPhotoUrls(urls)
          })
          .catch(() => {})
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [mondayISO, reloadCount]) // eslint-disable-line react-hooks/exhaustive-deps -- `dates` follows mondayISO

  // Someone plans a dinner on another phone, or an ingredient's status changes → reload.
  useEffect(
    () => subscribeToTables('menu', ['meal_plan', 'items', 'recipes', 'recipe_ingredients'], reload),
    [],
  )

  const goToWeek = (offsetWeeks) => setSearchParams({ week: toISODate(addDays(monday, offsetWeeks * 7)) })
  const isThisWeek = mondayISO === toISODate(startOfWeek(new Date()))
  const todayISO = today()

  const header = (
    <header className="screen-header">
      <div>
        <span className="eyebrow">{weekRangeLabel(monday)} · DINNERS</span>
        <h1>{weekTitle(monday)}</h1>
      </div>
      <div className="week-nav">
        <button type="button" className="small-button" onClick={() => goToWeek(-1)} aria-label="Previous week">
          ‹
        </button>
        <button type="button" className="small-button" onClick={() => goToWeek(1)} aria-label="Next week">
          ›
        </button>
      </div>
    </header>
  )

  if (loadError) {
    return (
      <div className="screen">
        {header}
        <div className="center-message">
          <p>Couldn’t load the menu.</p>
          <p className="muted">{loadError}</p>
          <button type="button" className="primary" onClick={reload}>
            Try again
          </button>
        </div>
      </div>
    )
  }

  // plan_date → that day's planned dinner
  const byDate = new Map((plan ?? []).map((p) => [p.plan_date, p]))
  const plannedCount = byDate.size

  return (
    <div className="screen">
      {header}
      <p className="screen-subtitle">
        {plan === null ? 'Loading…' : `${plannedCount} of 7 dinners planned`}
        {!isThisWeek && (
          <>
            {' · '}
            <button type="button" className="link-button" onClick={() => setSearchParams({})}>
              Back to this week
            </button>
          </>
        )}
      </p>

      {dates[6] >= todayISO && (
        <div className="menu-actions">
          <Link to={`/menu/generate?week=${mondayISO}`} className="primary primary-link">
            Generate week
          </Link>
        </div>
      )}

      {message && (
        <p className="notice notice-success notice-inline" role="status">
          {message}{' '}
          <button type="button" className="link-button" onClick={() => setMessage(null)}>
            OK
          </button>
        </p>
      )}

      {plan !== null && (
        <main className="item-list">
          <ul className="menu-days">
            {dates.map((date) => {
              const planned = byDate.get(date)
              const isPast = date < todayISO
              const dayClass = ['menu-day', date === todayISO && 'is-today', isPast && 'is-past'].filter(Boolean).join(' ')
              const dayLabel = (
                <span className="menu-date">
                  <span>{dayName(date)}</span>
                  <span>{dayNumber(date)}</span>
                </span>
              )

              if (!planned) {
                return (
                  <li key={date} className={dayClass}>
                    <Link to={`/menu/pick/${date}`} className="menu-row menu-row--empty">
                      {dayLabel}
                      <span className="menu-pick">+ Pick a recipe</span>
                    </Link>
                  </li>
                )
              }

              const r = readiness(planned.recipe.ingredients.map((i) => i.status))
              return (
                <li key={date} className={dayClass}>
                  <div className="menu-row">
                    {dayLabel}
                    <Link to={`/recipes/${planned.recipe.id}`} className="menu-recipe">
                      <RecipeThumb name={planned.recipe.name} url={photoUrls[planned.recipe.photo_path]} />
                      <span className="item-name">{planned.recipe.name}</span>
                      <span className={`pill pill-${r.kind}`}>{r.label}</span>
                    </Link>
                    <Link
                      to={`/menu/pick/${date}`}
                      className="small-button menu-change"
                      aria-label={`Change dinner for ${dayName(date)} ${dayNumber(date)}`}
                    >
                      Change
                    </Link>
                  </div>
                </li>
              )
            })}
          </ul>

          {/* Past days don't need shopping: count from today in the current week; skip weeks that are over. */}
          {dates[6] >= todayISO && (
            <WeekNeeds
              plan={plan}
              fromDate={isThisWeek ? todayISO : dates[0]}
              title={weekTitle(monday).startsWith('Week of') ? 'This menu' : weekTitle(monday)}
            />
          )}
        </main>
      )}
    </div>
  )
}
