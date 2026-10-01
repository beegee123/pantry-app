import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import IngredientPicker from './IngredientPicker.jsx'
import { fetchRecipe, saveRecipe, deleteRecipe, MEAL_TYPES } from '../api/recipes.js'
import { fetchItemOptions, saveItem } from '../api/items.js'

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

// One screen for both "New recipe" (/recipes/new) and "Edit recipe" (/recipes/:id/edit).
export default function RecipeForm() {
  const { id } = useParams()
  const isNew = !id
  const navigate = useNavigate()

  const [form, setForm] = useState(null) // null = loading
  const [items, setItems] = useState([]) // pantry items for the ingredient picker
  const [loadError, setLoadError] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [saveError, setSaveError] = useState(null)
  const [busy, setBusy] = useState(false)

  useEffect(() => {
    let ignore = false
    Promise.all([fetchItemOptions(), isNew ? null : fetchRecipe(id)])
      .then(([itemList, recipe]) => {
        if (ignore) return
        setItems(itemList)
        if (isNew) setForm(EMPTY_RECIPE)
        else if (recipe) setForm(recipe)
        else setNotFound(true)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [id, isNew])

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
      await saveRecipe({ ...form, id: isNew ? null : id })
      navigate('/recipes')
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
      <Link to="/recipes" className="back-link">
        Cancel
      </Link>
      <h1>{isNew ? 'New recipe' : 'Edit recipe'}</h1>
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
        <label className="field">
          <span className="field-label">Name</span>
          <input
            value={form.name}
            onChange={(e) => setField('name', e.target.value)}
            placeholder="e.g. Jollof rice"
            required
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

        <label className="field">
          <span className="field-label">Method</span>
          <textarea
            rows="8"
            value={form.method}
            onChange={(e) => setField('method', e.target.value)}
            placeholder={'1. Fry the onions…\n2. Add the tomato paste…'}
          />
        </label>

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
