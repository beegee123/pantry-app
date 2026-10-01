import { useEffect, useRef, useState } from 'react'
import { Link, useParams } from 'react-router'
import { fetchRecipe, mealLabel } from '../api/recipes.js'
import { getPhotoUrls, setRecipePhoto, removeRecipePhoto } from '../api/photos.js'
import { shrinkImage } from '../lib/image.js'
import RecipeThumb from './RecipeThumb.jsx'
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
  const [photoUrl, setPhotoUrl] = useState(null)
  const [photoBusy, setPhotoBusy] = useState(false)
  const [photoError, setPhotoError] = useState(null)
  const fileInput = useRef(null) // the hidden file picker; the button "clicks" it

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

  // Get a viewable link whenever the recipe points at a different photo.
  const photoPath = recipe?.photo_path
  useEffect(() => {
    let ignore = false
    if (!photoPath) {
      setPhotoUrl(null)
      return
    }
    getPhotoUrls([photoPath])
      .then((urls) => {
        if (!ignore) setPhotoUrl(urls[photoPath] ?? null)
      })
      .catch(() => {
        if (!ignore) setPhotoUrl(null) // the letter tile shows instead
      })
    return () => {
      ignore = true
    }
  }, [photoPath])

  // Shared by "Add / Change photo" and "Remove photo": busy flag, error message, reload.
  async function runPhotoAction(action) {
    setPhotoBusy(true)
    setPhotoError(null)
    try {
      await action()
      setReloadCount((n) => n + 1)
    } catch (err) {
      setPhotoError(err.message)
    } finally {
      setPhotoBusy(false)
    }
  }

  function handleFileChosen(event) {
    const file = event.target.files[0]
    event.target.value = '' // so picking the same photo again still fires onChange
    if (!file) return
    runPhotoAction(async () => {
      const blob = await shrinkImage(file)
      await setRecipePhoto(recipe.id, recipe.photo_path, blob)
    })
  }

  function handleRemovePhoto() {
    if (!window.confirm('Remove this photo?')) return
    runPhotoAction(() => removeRecipePhoto(recipe.id, recipe.photo_path))
  }

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
          <div className="detail-actions">
            {/* Opens the New recipe form filled in from this one. */}
            <Link to={`/recipes/new?from=${recipe.id}`} className="small-button">
              Duplicate
            </Link>
            <Link to={`/recipes/${recipe.id}/edit`} className="small-button">
              Edit
            </Link>
          </div>
        </div>
        <h1>
          {recipe.name}
          {recipe.is_favourite && <span aria-label="favourite"> ★</span>}
        </h1>
        <span className="item-store">{meta.join(' · ')}</span>
      </header>

      <main className="item-list detail-body">
        <section className="detail-photo">
          <RecipeThumb name={recipe.name} url={photoUrl} size="hero" />
          <div className="photo-actions">
            {/* accept="image/*" lets a phone offer "Take photo" or "Choose from library". */}
            <input ref={fileInput} type="file" accept="image/*" hidden onChange={handleFileChosen} />
            <button type="button" className="small-button" disabled={photoBusy} onClick={() => fileInput.current.click()}>
              {photoBusy ? 'Saving…' : recipe.photo_path ? 'Change photo' : 'Add photo'}
            </button>
            {recipe.photo_path && (
              <button type="button" className="small-button small-button--danger" disabled={photoBusy} onClick={handleRemovePhoto}>
                Remove photo
              </button>
            )}
          </div>
          {photoError && (
            <p className="notice" role="alert">
              {photoError}
            </p>
          )}
        </section>

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
