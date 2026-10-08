import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import SearchBox from './SearchBox.jsx'
import RecipeThumb from './RecipeThumb.jsx'
import { fetchRecipes, mealLabel } from '../api/recipes.js'
import { getPhotoUrls } from '../api/photos.js'
import { subscribeToTables } from '../lib/realtime.js'
import { readiness, compareByReadiness } from '../lib/readiness.js'

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

const normalize = (text) =>
  text.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().trim()

const FILTERS = [
  { value: 'all', label: 'Ready first' },
  { value: 'favourites', label: '★ Favourites' },
  { value: 'quick', label: 'Under 30 min' },
]

// "Dinner · 40 min · 8 ingredients"
function recipeMeta(recipe) {
  const parts = [mealLabel(recipe.meal_type)]
  if (recipe.minutes) parts.push(`${recipe.minutes} min`)
  parts.push(plural(recipe.ingredientStatuses.length, 'ingredient'))
  return parts.join(' · ')
}

export default function RecipesScreen() {
  const [recipes, setRecipes] = useState(null)
  const [photoUrls, setPhotoUrls] = useState({}) // photo_path → signed link
  const [loadError, setLoadError] = useState(null)
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState('all')
  const [reloadCount, setReloadCount] = useState(0)
  const reload = () => setReloadCount((n) => n + 1)

  useEffect(() => {
    let ignore = false
    fetchRecipes()
      .then((data) => {
        if (ignore) return
        setRecipes(data)
        setLoadError(null)
        // Photos load second, so the list shows straight away. If links fail, letters stay.
        return getPhotoUrls(data.map((r) => r.photo_path))
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
  }, [reloadCount])

  // Recipes, their ingredients, or item statuses changed on any device → reload,
  // so readiness stays live (mark Eggs Out on the Kitchen → Pancakes shows Missing 1).
  useEffect(() => subscribeToTables('recipes-screen', ['recipes', 'recipe_ingredients', 'items'], reload), [])

  const header = (
    <header className="screen-header">
      <div>
        <span className="eyebrow">WHAT CAN I COOK?</span>
        <h1>Recipes</h1>
      </div>
      <Link to="/recipes/new" className="small-button add-button" aria-label="New recipe">
        +
      </Link>
    </header>
  )

  if (loadError) {
    return (
      <div className="screen">
        {header}
        <div className="center-message">
          <p>Couldn’t load your recipes.</p>
          <p className="muted">{loadError}</p>
          <button type="button" className="primary" onClick={reload}>
            Try again
          </button>
        </div>
      </div>
    )
  }

  if (recipes === null) {
    return (
      <div className="screen">
        {header}
        <p className="center-message muted">Loading…</p>
      </div>
    )
  }

  // DERIVED: readiness for each recipe, then search + filter + sort.
  const search = normalize(query)
  const visible = recipes
    .map((r) => ({ ...r, readiness: readiness(r.ingredientStatuses) }))
    .filter((r) => filter !== 'favourites' || r.is_favourite)
    .filter((r) => filter !== 'quick' || (r.minutes && r.minutes <= 30))
    .filter((r) => search === '' || normalize(r.name).includes(search))
    .sort(compareByReadiness)

  // The list as shown (search, chip and order), handed to the recipe page for its ‹ › arrows (step 8f).
  const reviewList = visible.map((r) => ({ id: r.id, name: r.name }))

  const readyCount = recipes.filter((r) => readiness(r.ingredientStatuses).kind === 'ready').length

  return (
    <div className="screen">
      {header}

      {recipes.length === 0 ? (
        <div className="empty">
          <p>No recipes yet.</p>
          <Link to="/recipes/new" className="small-button">
            + Add your first recipe
          </Link>
        </div>
      ) : (
        <>
          <p className="screen-subtitle">
            {readyCount} of {plural(recipes.length, 'recipe')} ready to cook
          </p>
          <SearchBox value={query} onChange={setQuery} id="recipe-search" placeholder="Search recipes" />
          <div className="filter-chips" role="group" aria-label="Show">
            {FILTERS.map((f) => (
              <button
                key={f.value}
                type="button"
                className={filter === f.value ? 'chip is-on' : 'chip'}
                aria-pressed={filter === f.value}
                onClick={() => setFilter(f.value)}
              >
                {f.label}
              </button>
            ))}
          </div>

          <main className="item-list">
            {visible.length === 0 && <p className="empty">No recipes match.</p>}
            <ul>
              {visible.map((recipe) => (
                <li key={recipe.id}>
                  <Link to={`/recipes/${recipe.id}`} state={{ reviewList }} className="item-row recipe-row">
                    <RecipeThumb name={recipe.name} url={photoUrls[recipe.photo_path]} />
                    <div className="item-text">
                      <span className="item-name">
                        {recipe.name}
                        {recipe.is_favourite && <span aria-label="favourite"> ★</span>}
                      </span>
                      <span className="item-store">{recipeMeta(recipe)}</span>
                    </div>
                    <span className={`pill pill-${recipe.readiness.kind}`}>{recipe.readiness.label}</span>
                  </Link>
                </li>
              ))}
            </ul>
          </main>
        </>
      )}
    </div>
  )
}
