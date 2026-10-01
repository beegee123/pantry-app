import { useEffect, useState } from 'react'
import { Link, useParams } from 'react-router'
import { fetchRecipe, mealLabel } from '../api/recipes.js'
import { subscribeToTables } from '../lib/realtime.js'
import { readiness } from '../lib/readiness.js'

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

// The summary card under the title.
function ReadinessCard({ r }) {
  if (r.kind === 'empty') {
    return <p className="readiness-card">Add ingredients to see whether you can cook this.</p>
  }
  if (r.kind === 'ready') {
    return <p className="readiness-card is-ready">Ready to cook: everything’s in.</p>
  }
  const parts = []
  if (r.missing) parts.push(`Missing ${r.missing}`)
  if (r.low) parts.push(`Low ${r.low}`)
  return (
    <div className="readiness-card">
      <p className="readiness-title">{parts.join(' · ')}</p>
      {/* Out and Low items are on the shopping list automatically — no extra button needed. */}
      <Link to="/shopping" className="text-link">
        Already on your shopping list ›
      </Link>
    </div>
  )
}

export default function RecipeDetail() {
  const { id } = useParams()
  const [recipe, setRecipe] = useState(undefined) // undefined = loading, null = not found
  const [loadError, setLoadError] = useState(null)
  const [reloadCount, setReloadCount] = useState(0)

  useEffect(() => {
    let ignore = false
    fetchRecipe(id)
      .then((data) => {
        if (ignore) return
        setRecipe(data)
        setLoadError(null)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [id, reloadCount])

  // An ingredient's status changes in the Kitchen, or someone edits the recipe → reload.
  useEffect(
    () => subscribeToTables('recipe-detail', ['items', 'recipes', 'recipe_ingredients'], () => setReloadCount((n) => n + 1)),
    [],
  )

  const back = (
    <Link to="/recipes" className="back-link">
      ‹ Recipes
    </Link>
  )

  if (loadError || recipe === null) {
    return (
      <div className="screen">
        <header className="screen-header screen-header--sub">{back}</header>
        <div className="center-message">
          <p>{recipe === null ? 'That recipe doesn’t exist any more.' : 'Couldn’t load this recipe.'}</p>
          {loadError && <p className="muted">{loadError}</p>}
        </div>
      </div>
    )
  }

  if (recipe === undefined) {
    return (
      <div className="screen">
        <header className="screen-header screen-header--sub">{back}</header>
        <p className="center-message muted">Loading…</p>
      </div>
    )
  }

  const r = readiness(recipe.ingredients.map((i) => i.status))
  const meta = [mealLabel(recipe.meal_type)]
  if (recipe.minutes) meta.push(`${recipe.minutes} min`)
  if (recipe.servings) meta.push(`Serves ${recipe.servings}`)

  return (
    <div className="screen">
      <header className="screen-header screen-header--sub">
        <div className="detail-topbar">
          {back}
          <Link to={`/recipes/${recipe.id}/edit`} className="small-button">
            Edit
          </Link>
        </div>
        <h1>
          {recipe.name}
          {recipe.is_favourite && <span aria-label="favourite"> ★</span>}
        </h1>
        <span className="item-store">{meta.join(' · ')}</span>
      </header>

      <main className="item-list detail-body">
        <ReadinessCard r={r} />

        <section>
          <h2 className="section-title section-title--split">
            <span>INGREDIENTS</span>
            <span>{r.total ? `${r.total - r.missing} of ${plural(r.total, 'item')} in stock` : ''}</span>
          </h2>
          <ul className="detail-ingredients">
            {recipe.ingredients.map((ing) => (
              <li key={ing.item_id}>
                <span className="detail-ing-name">{ing.name}</span>
                <span className="detail-ing-amount">{ing.amount_text}</span>
                <span className={`pill pill-${ing.status}`}>{ing.status.toUpperCase()}</span>
              </li>
            ))}
          </ul>
          {recipe.basics && <p className="muted small detail-basics">Assumed in stock: {recipe.basics}</p>}
        </section>

        {recipe.method && (
          <section>
            <h2 className="section-title">METHOD</h2>
            <p className="detail-method">{recipe.method}</p>
          </section>
        )}
      </main>
    </div>
  )
}
