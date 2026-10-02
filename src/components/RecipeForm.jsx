import { lazy, Suspense, useEffect, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router'
import IngredientPicker from './IngredientPicker.jsx'
import { fetchRecipe, saveRecipe, deleteRecipe, MEAL_TYPES } from '../api/recipes.js'
import { fetchItemOptions, saveItem } from '../api/items.js'

// LAZY LOADING: the rich-text editor is big (it brings a whole editing engine), and only
// this form needs it. lazy() splits it into its own file that downloads the first time
// the form opens, so the Kitchen and the rest of the app load as fast as before.
const MethodEditor = lazy(() => import('./MethodEditor.jsx'))

const EMPTY_RECIPE = {
  name: '',
  meal_type: 'dinner',
  minutes: '',
  servings: '',
  is_favourite: false,
  basics: '',
  method: '',
  ingredients: [],
}

// The starting point for a duplicate: everything from the original except its id,
// photo (a copy gets its own) and favourite star; the name gets " (copy)" so it's unique.
function copyOf(recipe) {
  return {
    name: `${recipe.name} (copy)`,
    meal_type: recipe.meal_type,
    minutes: recipe.minutes,
    servings: recipe.servings,
    is_favourite: false,
    basics: recipe.basics,
    method: recipe.method,
    ingredients: recipe.ingredients,
  }
}

// One screen for "New recipe" (/recipes/new), "Duplicate" (/recipes/new?from=<id>)
// and "Edit recipe" (/recipes/:id/edit).
export default function RecipeForm() {
  const { id } = useParams()
  const isNew = !id
  const [searchParams] = useSearchParams()
  const copyFromId = isNew ? searchParams.get('from') : null // set when duplicating
  const navigate = useNavigate()

  const [form, setForm] = useState(null) // null = loading
  const [items, setItems] = useState([]) // pantry items for the ingredient picker
  const [loadError, setLoadError] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [saveError, setSaveError] = useState(null)
  const [busy, setBusy] = useState(false)
  const [copiedFrom, setCopiedFrom] = useState(null) // the original's name, for the hint

  useEffect(() => {
    let ignore = false
    const recipeId = isNew ? copyFromId : id // the recipe to load, if any
    Promise.all([fetchItemOptions(), recipeId ? fetchRecipe(recipeId) : null])
      .then(([itemList, recipe]) => {
        if (ignore) return
        setItems(itemList)
        if (!recipeId) setForm(EMPTY_RECIPE)
        else if (!recipe) setNotFound(true)
        else if (isNew) {
          setForm(copyOf(recipe)) // a duplicate: nothing is saved until you press Save
          setCopiedFrom(recipe.name)
        } else setForm(recipe)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [id, isNew, copyFromId])

  const setField = (field, value) => setForm((f) => ({ ...f, [field]: value }))

  // Called by the ingredient picker to create a pantry item on the spot.
  // Reuses save_item from step 5, so the new item is a normal pantry item (no stores yet).
  async function createItem({ name, category, status }) {
    const newId = await saveItem({
      id: null,
      name,
      category,
      status,
      usual_amount: '',
      always_stocked: false,
      storeIds: [],
      preferredStoreId: null,
    })
    const item = { id: newId, name: name.trim(), category, status }
    setItems((list) => [...list, item].sort((a, b) => a.name.localeCompare(b.name)))
    return item
  }

  async function handleSubmit(event) {
    event.preventDefault()
    if (!form.name.trim()) {
      setSaveError('Give the recipe a name.')
      return
    }
    setBusy(true)
    setSaveError(null)
    try {
      const savedId = await saveRecipe({ ...form, id: isNew ? null : id })
      navigate(`/recipes/${savedId}`) // straight to the recipe, to see what's missing
    } catch (err) {
      setSaveError(err.message)
      setBusy(false)
    }
  }

  async function handleDelete() {
    if (!window.confirm(`Delete ${form.name}? This can’t be undone.`)) return
    setBusy(true)
    try {
      await deleteRecipe(id)
      navigate('/recipes')
    } catch (err) {
      setSaveError(err.message)
      setBusy(false)
    }
  }

  const header = (
    <header className="form-header">
      {/* Cancel goes back where you came from: the recipe being edited or copied, or the list. */}
      <Link to={id || copyFromId ? `/recipes/${id ?? copyFromId}` : '/recipes'} className="back-link">
        Cancel
      </Link>
      <h1>{copyFromId ? 'Duplicate recipe' : isNew ? 'New recipe' : 'Edit recipe'}</h1>
      <span className="form-header-spacer" />
    </header>
  )

  if (loadError || notFound) {
    return (
      <div className="screen">
        {header}
        <div className="center-message">
          <p>{notFound ? 'That recipe doesn’t exist any more.' : 'Couldn’t load this recipe.'}</p>
          {loadError && <p className="muted">{loadError}</p>}
          <Link to="/recipes" className="primary primary-link">
            Back to Recipes
          </Link>
        </div>
      </div>
    )
  }

  if (form === null) {
    return (
      <div className="screen">
        {header}
        <p className="center-message muted">Loading…</p>
      </div>
    )
  }

  return (
    <div className="screen">
      {header}

      <form className="item-form" onSubmit={handleSubmit}>
        {copiedFrom && (
          <p className="copy-hint">
            Copied from <strong>{copiedFrom}</strong>. Change the name and anything that’s different, then save.
            The original stays as it is.
          </p>
        )}

        <label className="field">
          <span className="field-label">Name</span>
          <input
            value={form.name}
            onChange={(e) => setField('name', e.target.value)}
            placeholder="e.g. Jollof rice"
            required
            autoFocus={Boolean(copiedFrom)}
            onFocus={copiedFrom ? (e) => e.target.select() : undefined}
          />
        </label>

        <fieldset className="field">
          <legend className="field-label">Meal</legend>
          <div className="chip-row">
            {MEAL_TYPES.map((m) => (
              <button
                key={m.value}
                type="button"
                className={form.meal_type === m.value ? 'chip is-on' : 'chip'}
                aria-pressed={form.meal_type === m.value}
                onClick={() => setField('meal_type', m.value)}
              >
                {m.label}
              </button>
            ))}
          </div>
        </fieldset>

        <div className="field-pair">
          <label className="field">
            <span className="field-label">Minutes</span>
            <input
              type="number"
              inputMode="numeric"
              min="1"
              value={form.minutes}
              onChange={(e) => setField('minutes', e.target.value)}
              placeholder="e.g. 45"
            />
          </label>
          <label className="field">
            <span className="field-label">Serves</span>
            <input
              type="number"
              inputMode="numeric"
              min="1"
              value={form.servings}
              onChange={(e) => setField('servings', e.target.value)}
              placeholder="e.g. 4"
            />
          </label>
        </div>

        <label className="toggle-row">
          <span>
            <span className="toggle-title">★ Favourite</span>
            <span className="field-hint">Shows ★ in your recipe list</span>
          </span>
          <input
            type="checkbox"
            className="switch"
            checked={form.is_favourite}
            onChange={(e) => setField('is_favourite', e.target.checked)}
          />
        </label>

        <fieldset className="field">
          <legend className="field-label">
            Ingredients <span className="field-hint">From your pantry</span>
          </legend>
          <IngredientPicker
            items={items}
            ingredients={form.ingredients}
            onChange={(ingredients) => setField('ingredients', ingredients)}
            onCreateItem={createItem}
          />
        </fieldset>

        <label className="field">
          <span className="field-label">
            Assumed basics <span className="field-hint">Not checked against the pantry</span>
          </span>
          <input
            value={form.basics}
            onChange={(e) => setField('basics', e.target.value)}
            placeholder="e.g. salt, oil, water"
          />
        </label>

        <div className="field">
          <label className="field-label" htmlFor="method">
            Method <span className="field-hint">Type “1. ” for steps, “- ” for bullets</span>
          </label>
          <Suspense fallback={<div className="method-editor method-editor--loading">Loading editor…</div>}>
            <MethodEditor id="method" value={form.method} onChange={(html) => setField('method', html)} />
          </Suspense>
        </div>

        {saveError && (
          <p className="notice" role="alert">
            {saveError}
          </p>
        )}

        <button type="submit" className="primary" disabled={busy}>
          {busy ? 'Saving…' : isNew ? 'Save recipe' : 'Save changes'}
        </button>

        {!isNew && (
          <button type="button" className="link-button danger delete-button" onClick={handleDelete} disabled={busy}>
            Delete recipe
          </button>
        )}
      </form>
    </div>
  )
}
