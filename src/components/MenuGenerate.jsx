import { useEffect, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router'
import { fetchRecipes } from '../api/recipes.js'
import { fetchPlan, setDinners } from '../api/menu.js'
import { generatePlan, LONG_MINUTES } from '../lib/generator.js'
import { addDays, dayName, fromISODate, shortDay, startOfWeek, toISODate, today, weekDates } from '../lib/dates.js'

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

const PRIORITIES = [
  { value: 'have', label: 'Use what I have' },
  { value: 'balanced', label: 'Balanced' },
  { value: 'any', label: 'Don’t care' },
]

const RULES = [
  { key: 'noRepeats', label: 'No repeats this week' },
  { key: 'skipLastWeek', label: 'Avoid last week’s dinners', hint: 'Used only if nothing fresher fits' },
  { key: 'favourites', label: 'Favourites more often' },
  { key: 'longOnWeekends', label: 'Long recipes on weekends only', hint: `Over ${LONG_MINUTES} min` },
]

// Generate a week: /menu/generate?week=2026-10-05
// Pick days and rules, press Generate; the plan is saved and you're back on the week.
export default function MenuGenerate() {
  const navigate = useNavigate()
  const [searchParams] = useSearchParams()
  const monday = startOfWeek(searchParams.get('week') ? fromISODate(searchParams.get('week')) : new Date())
  const mondayISO = toISODate(monday)
  const dates = weekDates(monday)
  const todayISO = today()
  const weekURL = `/menu?week=${mondayISO}`

  const [data, setData] = useState(null) // { recipes, plan, lastWeekIds }
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)
  const [chosen, setChosen] = useState(new Set()) // the days to fill
  const [priority, setPriority] = useState('have')
  const [rules, setRules] = useState({ noRepeats: true, skipLastWeek: true, favourites: true, longOnWeekends: false })

  useEffect(() => {
    let ignore = false
    const lastMonday = toISODate(addDays(monday, -7))
    const lastSunday = toISODate(addDays(monday, -1))
    Promise.all([fetchRecipes(), fetchPlan(dates[0], dates[6]), fetchPlan(lastMonday, lastSunday)])
      .then(([recipes, plan, lastWeek]) => {
        if (ignore) return
        setData({
          recipes: recipes.filter((r) => r.meal_type === 'dinner'),
          plan,
          lastWeekIds: new Set(lastWeek.map((p) => p.recipe.id)),
        })
        // Start with the empty days from today on.
        const planned = new Set(plan.map((p) => p.plan_date))
        setChosen(new Set(dates.filter((d) => d >= todayISO && !planned.has(d))))
      })
      .catch((err) => {
        if (!ignore) setError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [mondayISO]) // eslint-disable-line react-hooks/exhaustive-deps -- the rest follows mondayISO

  function toggleDay(date) {
    setChosen((current) => {
      const next = new Set(current)
      if (next.has(date)) next.delete(date)
      else next.add(date)
      return next
    })
  }

  async function handleGenerate() {
    const days = dates.filter((d) => chosen.has(d))
    // Dinners on the days you're keeping count as "used" for No repeats.
    const keptIds = data.plan.filter((p) => !chosen.has(p.plan_date)).map((p) => p.recipe.id)
    const { picks, emptyDates } = generatePlan({
      recipes: data.recipes,
      dates: days,
      options: { priority, ...rules },
      keptIds,
      lastWeekIds: data.lastWeekIds,
    })

    setBusy(true)
    setError(null)
    try {
      await setDinners(picks)
      // Tell the week screen what happened (it shows this once).
      const message =
        emptyDates.length === 0
          ? `Planned ${plural(picks.length, 'dinner')}.`
          : `Planned ${plural(picks.length, 'dinner')}. No recipe fitted the rules for ${emptyDates.map(shortDay).join(', ')}: add more dinner recipes or switch a rule off.`
      navigate(weekURL, { state: { message } })
    } catch (err) {
      setError(err.message)
      setBusy(false)
    }
  }

  const header = (
    <header className="form-header">
      <Link to={weekURL} className="back-link">
        Cancel
      </Link>
      <h1>Generate a week</h1>
      <span className="form-header-spacer" />
    </header>
  )

  if (data === null) {
    return (
      <div className="screen">
        {header}
        {error ? (
          <div className="center-message">
            <p>Couldn’t load your recipes.</p>
            <p className="muted">{error}</p>
          </div>
        ) : (
          <p className="center-message muted">Loading…</p>
        )}
      </div>
    )
  }

  const planned = new Map(data.plan.map((p) => [p.plan_date, p.recipe.name]))
  const replacing = [...chosen].filter((d) => planned.has(d))

  return (
    <div className="screen">
      {header}
      <div className="item-form">
        <fieldset className="field">
          <legend className="field-label">Which days</legend>
          <div className="day-chips">
            {dates.map((date) => {
              const isPast = date < todayISO
              const on = chosen.has(date)
              return (
                <button
                  key={date}
                  type="button"
                  className={on ? 'day-chip is-on' : 'day-chip'}
                  aria-pressed={on}
                  aria-label={`${dayName(date)}${planned.has(date) ? `, planned: ${planned.get(date)}` : ''}`}
                  disabled={isPast}
                  onClick={() => toggleDay(date)}
                >
                  {dayName(date).charAt(0)}
                  {planned.has(date) && <span className="day-chip-dot" aria-hidden="true" />}
                </button>
              )
            })}
          </div>
          <span className="field-hint">
            {replacing.length > 0
              ? `Replaces the dinner already planned for ${replacing.sort().map(shortDay).join(', ')}.`
              : 'A dot marks a day that already has a dinner.'}
          </span>
        </fieldset>

        <fieldset className="field">
          <legend className="field-label">Priority</legend>
          <div className="segmented" role="group" aria-label="Priority">
            {PRIORITIES.map((p) => (
              <button
                key={p.value}
                type="button"
                className={priority === p.value ? 'segment is-on' : 'segment'}
                aria-pressed={priority === p.value}
                onClick={() => setPriority(p.value)}
              >
                {p.label}
              </button>
            ))}
          </div>
        </fieldset>

        <fieldset className="field">
          <legend className="field-label">Variety &amp; rules</legend>
          <div className="toggle-group">
            {RULES.map((rule) => (
              <label key={rule.key} className="toggle-row">
                <span>
                  <span className="toggle-title">{rule.label}</span>
                  {rule.hint && <span className="field-hint">{rule.hint}</span>}
                </span>
                <input
                  type="checkbox"
                  className="switch"
                  checked={rules[rule.key]}
                  onChange={(e) => setRules({ ...rules, [rule.key]: e.target.checked })}
                />
              </label>
            ))}
          </div>
        </fieldset>

        {data.recipes.length === 0 && (
          <p className="notice">No dinner recipes yet. Add some on the Recipes tab first.</p>
        )}
        {error && (
          <p className="notice" role="alert">
            {error}
          </p>
        )}

        <button
          type="button"
          className="primary"
          disabled={busy || chosen.size === 0 || data.recipes.length === 0}
          onClick={handleGenerate}
        >
          {busy ? 'Saving…' : chosen.size === 0 ? 'Pick at least one day' : `Generate ${plural(chosen.size, 'dinner')}`}
        </button>
      </div>
    </div>
  )
}
