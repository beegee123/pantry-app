import { useEffect, useState } from 'react'
import { Link, useLocation, useNavigate, useSearchParams } from 'react-router'
import RecipeThumb from './RecipeThumb.jsx'
import { fetchPlan, moveDinner, neededByMenu } from '../api/menu.js'
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
// show: which Shopping chip the link opens on ('menu' = This week, 'next' = Next week, null = All).
function WeekNeeds({ plan, fromDate, title, show }) {
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
      <Link to={show ? `/shopping?show=${show}` : '/shopping'} className="text-link">
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

  // Rearrange mode (step 16a): tap a dinner, then the day to move it to.
  const [rearranging, setRearranging] = useState(false)
  const [picked, setPicked] = useState(null) // the date of the dinner being moved
  const [moveError, setMoveError] = useState(null)

  useEffect(() => {
    let ignore = false
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

  // A different week: show Loading… and leave rearrange mode.
  useEffect(() => {
    setPlan(null)
    setRearranging(false)
    setPicked(null)
  }, [mondayISO])

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
  const weekIsOver = dates[6] < todayISO
  const canRearrange = !weekIsOver && [...byDate.keys()].some((d) => d >= todayISO)

  function stopRearranging() {
    setRearranging(false)
    setPicked(null)
    setMoveError(null)
  }

  // In rearrange mode, a tap on a day: pick up its dinner, put it down, or drop the pick.
  async function tapDay(date) {
    if (picked === null) {
      if (byDate.has(date)) setPicked(date)
      return
    }
    if (picked === date) {
      setPicked(null)
      return
    }
    const from = byDate.get(picked)
    const to = byDate.get(date) ?? null
    setPicked(null)
    setMoveError(null)

    // Show the result straight away; put it back if saving fails.
    const before = plan
    setPlan(
      plan
        .filter((p) => p.plan_date !== picked && p.plan_date !== date)
        .concat([{ ...from, plan_date: date }], to ? [{ ...to, plan_date: picked }] : [])
        .sort((a, b) => a.plan_date.localeCompare(b.plan_date)),
    )
    try {
      await moveDinner(picked, date, from.recipe.id, to?.recipe.id ?? null)
    } catch (err) {
      setPlan(before)
      setMoveError(`Couldn’t move it: ${err.message}`)
      reload()
    }
  }

  return (
    <div className="screen">
      {header}
      <p className="screen-subtitle">
        {plan === null ? 'Loading…' : `${plannedCount} of 7 dinners planned`}
        {canRearrange && !rearranging && (
          <>
            {' · '}
            <button type="button" className="link-button" onClick={() => setRearranging(true)}>
              Rearrange
            </button>
          </>
        )}
        {!isThisWeek && !rearranging && (
          <>
            {' · '}
            <button type="button" className="link-button" onClick={() => setSearchParams({})}>
              Back to this week
            </button>
          </>
        )}
      </p>

      {rearranging && (
        <div className="rearrange-bar" role="status">
          <span>{picked ? `Now tap the day to move ${shortDay(picked)}’s dinner to.` : 'Tap a dinner, then the day to move it to.'}</span>
          <button type="button" className="small-button" onClick={stopRearranging}>
            Done
          </button>
        </div>
      )}
      {moveError && (
        <p className="notice notice-inline" role="alert">
          {moveError}
        </p>
      )}

      {!weekIsOver && !rearranging && (
        <div className="menu-actions">
          <Link to={`/menu/generate?week=${mondayISO}`} className="primary primary-link">
            Generate week
          </Link>
        </div>
      )}

      {message && !rearranging && (
        <p className="notice notice-success notice-inline" role="status">
          {message}{' '}
          <button type="button" className="link-button" onClick={() => setMessage(null)}>
            OK
          </button>
        </p>
      )}

      {plan !== null && (
        <main className="item-list">
          <ul className={rearranging ? 'menu-days is-rearranging' : 'menu-days'}>
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

              if (rearranging) {
                // Every day becomes one big button. Past days stay put.
                const r = planned && readiness(planned.recipe.ingredients.map((i) => i.status))
                const canTap = !isPast && (picked !== null || Boolean(planned))
                const rowClass = [
                  'menu-row',
                  'menu-row--button',
                  !planned && 'menu-row--empty',
                  picked === date && 'is-picked',
                  picked !== null && picked !== date && !isPast && 'is-target',
                ]
                  .filter(Boolean)
                  .join(' ')
                const longDay = fromISODate(date).toLocaleDateString('en-US', { weekday: 'long' })
                const label = planned ? `${longDay}: ${planned.recipe.name}` : `${longDay}: no dinner`
                return (
                  <li key={date} className={dayClass}>
                    <button
                      type="button"
                      className={rowClass}
                      disabled={!canTap}
                      aria-pressed={picked === date}
                      aria-label={label}
                      onClick={() => tapDay(date)}
                    >
                      {dayLabel}
                      {planned ? (
                        <span className="menu-recipe">
                          <RecipeThumb name={planned.recipe.name} url={photoUrls[planned.recipe.photo_path]} />
                          <span className="item-name">{planned.recipe.name}</span>
                          <span className={`pill pill-${r.kind}`}>{r.label}</span>
                        </span>
                      ) : (
                        <span className="menu-pick">{picked && !isPast ? 'Move here' : 'No dinner'}</span>
                      )}
                    </button>
                  </li>
                )
              }

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
          {!weekIsOver && !rearranging && (
            <WeekNeeds
              plan={plan}
              fromDate={isThisWeek ? todayISO : dates[0]}
              title={weekTitle(monday).startsWith('Week of') ? 'This menu' : weekTitle(monday)}
              show={isThisWeek ? 'menu' : weekTitle(monday) === 'Next week' ? 'next' : null}
            />
          )}
        </main>
      )}
    </div>
  )
}
