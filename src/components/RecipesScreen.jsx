import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { fetchRecipes, mealLabel } from '../api/recipes.js'
import { subscribeToTables } from '../lib/realtime.js'

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

// "Dinner · 40 min · 8 ingredients"
function recipeMeta(recipe) {
  const parts = [mealLabel(recipe.meal_type)]
  if (recipe.minutes) parts.push(`${recipe.minutes} min`)
  parts.push(plural(recipe.ingredientStatuses.length, 'ingredient'))
  return parts.join(' · ')
}

// Step 9–10 version of the Recipes list: names and details.
// Step 11 adds readiness (Ready / Low / Missing), sorting and filters.
export default function RecipesScreen() {
  const [recipes, setRecipes] = useState(null)
  const [loadError, setLoadError] = useState(null)
  const [reloadCount, setReloadCount] = useState(0)
  const reload = () => setReloadCount((n) => n + 1)

  useEffect(() => {
    let ignore = false
    fetchRecipes()
      .then((data) => {
        if (ignore) return
        setRecipes(data)
        setLoadError(null)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [reloadCount])

  // Recipes, their ingredients, or item statuses changed on any device → reload.
  useEffect(() => subscribeToTables('recipes-screen', ['recipes', 'recipe_ingredients', 'items'], reload), [])

  return (
    <div className="screen">
      <header className="screen-header">
        <div>
          <span className="eyebrow">WHAT CAN I COOK?</span>
          <h1>Recipes</h1>
        </div>
        <Link to="/recipes/new" className="small-button add-button" aria-label="New recipe">
          +
        </Link>
      </header>

      {loadError && (
        <div className="center-message">
          <p>Couldn’t load your recipes.</p>
          <p className="muted">{loadError}</p>
          <button type="button" className="primary" onClick={reload}>
            Try again
          </button>
        </div>
      )}

      {!loadError && recipes === null && <p className="center-message muted">Loading…</p>}

      {!loadError && recipes !== null && (
        <main className="item-list">
          {recipes.length === 0 && (
            <div className="empty">
              <p>No recipes yet.</p>
              <Link to="/recipes/new" className="small-button">
                + Add your first recipe
              </Link>
            </div>
          )}
          <ul>
            {recipes.map((recipe) => (
              <li key={recipe.id}>
                {/* Step 12 sends this to the recipe detail screen; for now it opens the editor. */}
                <Link to={`/recipes/${recipe.id}/edit`} className="item-row recipe-row">
                  <div className="item-text">
                    <span className="item-name">
                      {recipe.name}
                      {recipe.is_favourite && <span aria-label="favourite"> ★</span>}
                    </span>
                    <span className="item-store">{recipeMeta(recipe)}</span>
                  </div>
                  <span className="chevron" aria-hidden="true">
                    ›
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </main>
      )}
    </div>
  )
}
