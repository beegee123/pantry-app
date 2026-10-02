import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import SearchBox from './SearchBox.jsx'
import RecipeThumb from './RecipeThumb.jsx'
import { fetchRecipes, mealLabel } from '../api/recipes.js'
import { fetchPlan, setDinner, clearDinner } from '../api/menu.js'
import { getPhotoUrls } from '../api/photos.js'
import { readiness, compareByReadiness } from '../lib/readiness.js'
import { fromISODate, shortDay, startOfWeek, toISODate, weekDates } from '../lib/dates.js'

const normalize = (text) =>
  text.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim()

// Pick the dinner for one day: /menu/pick/2026-10-06
export default function MenuPick() {
  const { date } = useParams()
  const navigate = useNavigate()
  const monday = startOfWeek(fromISODate(date))
  const weekURL = `/menu?week=${toISODate(monday)}`
  const dayTitle = fromISODate(date).toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })

  const [recipes, setRecipes] = useState(null)
  const [weekPlan, setWeekPlan] = useState([]) // the rest of this week, to show repeats
  const [photoUrls, setPhotoUrls] = useState({})
  const [query, setQuery] = useState('')
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    let ignore = false
    const dates = weekDates(monday)
    Promise.all([fetchRecipes(), fetchPlan(dates[0], dates[6])])
      .then(([recipeList, plan]) => {
        if (ignore) return
        setRecipes(recipeList)
        setWeekPlan(plan)
        return getPhotoUrls(recipeList.map((r) => r.photo_path))
          .then((urls) => {
            if (!ignore) setPhotoUrls(urls)
          })
          .catch(() => {})
      })
      .catch((err) => {
        if (!ignore) setError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [date]) // eslint-disable-line react-hooks/exhaustive-deps -- `monday` follows `date`

  async function run(action) {
    setBusy(true)
    setError(null)
    try {
      await action()
      navigate(weekURL) // back to the week, which now shows the change
    } catch (err) {
      setError(err.message)
      setBusy(false)
    }
  }

  const current = weekPlan.find((p) => p.plan_date === date)?.recipe.id
  // recipe id → other days this week it's planned: "Also Thu" helps avoid repeats.
  const otherDays = new Map()
  for (const p of weekPlan) {
    if (p.plan_date === date) continue
    otherDays.set(p.recipe.id, [...(otherDays.get(p.recipe.id) ?? []), shortDay(p.plan_date)])
  }

  const search = normalize(query)
  const visible = (recipes ?? [])
    .map((r) => ({ ...r, readiness: readiness(r.ingredientStatuses) }))
    .filter((r) => search === '' || normalize(r.name).includes(search))
    // Dinners first, then everything else; each group Ready first.
    .sort((a, b) => (a.meal_type === 'dinner') === (b.meal_type === 'dinner') ? compareByReadiness(a, b) : a.meal_type === 'dinner' ? -1 : 1)

  return (
    <div className="screen">
      <header className="form-header">
        <Link to={weekURL} className="back-link">
          Cancel
        </Link>
        <h1>Dinner for {dayTitle}</h1>
        <span className="form-header-spacer" />
      </header>

      {error && (
        <p className="notice notice-inline" role="alert">
          {error}
        </p>
      )}

      {recipes === null && !error && <p className="center-message muted">Loading…</p>}

      {recipes !== null && recipes.length === 0 && (
        <div className="empty">
          <p>No recipes yet.</p>
          <Link to="/recipes/new" className="small-button">
            + Add your first recipe
          </Link>
        </div>
      )}

      {recipes !== null && recipes.length > 0 && (
        <>
          <SearchBox value={query} onChange={setQuery} id="pick-search" placeholder="Search recipes" />
          <main className="item-list">
            {visible.length === 0 && <p className="empty">No recipes match.</p>}
            <ul>
              {visible.map((recipe) => {
                const also = otherDays.get(recipe.id)
                const meta = [mealLabel(recipe.meal_type)]
                if (recipe.minutes) meta.push(`${recipe.minutes} min`)
                if (also) meta.push(`Also ${also.join(', ')}`)
                const isCurrent = recipe.id === current
                return (
                  <li key={recipe.id}>
                    <button
                      type="button"
                      className={isCurrent ? 'item-row recipe-row pick-row is-current' : 'item-row recipe-row pick-row'}
                      disabled={busy}
                      aria-pressed={isCurrent}
                      onClick={() => run(() => setDinner(date, recipe.id))}
                    >
                      <RecipeThumb name={recipe.name} url={photoUrls[recipe.photo_path]} />
                      <span className="item-text">
                        <span className="item-name">
                          {recipe.name}
                          {recipe.is_favourite && <span aria-label="favourite"> ★</span>}
                        </span>
                        <span className="item-store">{meta.join(' · ')}</span>
                      </span>
                      {isCurrent ? (
                        <span className="pill pill-in">PLANNED</span>
                      ) : (
                        <span className={`pill pill-${recipe.readiness.kind}`}>{recipe.readiness.label}</span>
                      )}
                    </button>
                  </li>
                )
              })}
            </ul>

            {current && (
              <button
                type="button"
                className="link-button danger delete-button"
                disabled={busy}
                onClick={() => run(() => clearDinner(date))}
              >
                Clear {shortDay(date)}’s dinner
              </button>
            )}
          </main>
        </>
      )}
    </div>
  )
}
