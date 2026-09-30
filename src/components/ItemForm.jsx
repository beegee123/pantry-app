import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router'
import StatusControl from './StatusControl.jsx'
import { fetchItem, saveItem, deleteItem } from '../api/items.js'
import { fetchStoreOptions } from '../api/stores.js'
import { CATEGORIES } from '../lib/categories.js'

// What a brand-new item starts as.
const EMPTY_ITEM = {
  name: '',
  category: 'Pantry',
  status: 'in',
  usual_amount: '',
  always_stocked: false,
  storeIds: [],
  preferredStoreId: null,
}

// One screen for both "Add item" (/items/new) and "Edit item" (/items/:id).
export default function ItemForm() {
  const { id } = useParams() // undefined on /items/new
  const isNew = !id
  const navigate = useNavigate() // lets code move to another screen
  const [searchParams] = useSearchParams() // e.g. /items/new?name=Oat%20milk from the Kitchen search
  const startName = searchParams.get('name') ?? ''

  const [form, setForm] = useState(null) // null = loading
  const [stores, setStores] = useState([])
  const [loadError, setLoadError] = useState(null)
  const [notFound, setNotFound] = useState(false)
  const [saveError, setSaveError] = useState(null)
  const [busy, setBusy] = useState(false)

  // Load the store list and, when editing, the item — at the same time.
  useEffect(() => {
    let ignore = false
    Promise.all([fetchStoreOptions(), isNew ? null : fetchItem(id)])
      .then(([storeList, item]) => {
        if (ignore) return
        setStores(storeList)
        if (isNew) setForm({ ...EMPTY_ITEM, name: startName })
        else if (item) setForm(item)
        else setNotFound(true)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [id, isNew, startName])

  // Change one field of the form, keeping the rest (immutability again).
  const setField = (field, value) => setForm((f) => ({ ...f, [field]: value }))

  function toggleStore(storeId) {
    setForm((f) => {
      if (f.storeIds.includes(storeId)) {
        // Unticking: remove it, and clear the star if it was the preferred one.
        return {
          ...f,
          storeIds: f.storeIds.filter((s) => s !== storeId),
          preferredStoreId: f.preferredStoreId === storeId ? null : f.preferredStoreId,
        }
      }
      // Ticking: add it. The first store ticked becomes preferred automatically.
      return {
        ...f,
        storeIds: [...f.storeIds, storeId],
        preferredStoreId: f.storeIds.length === 0 ? storeId : f.preferredStoreId,
      }
    })
  }

  function togglePreferred(storeId) {
    setForm((f) => ({ ...f, preferredStoreId: f.preferredStoreId === storeId ? null : storeId }))
  }

  async function handleSubmit(event) {
    event.preventDefault()
    if (!form.name.trim()) {
      setSaveError('Give the item a name.')
      return
    }
    setBusy(true)
    setSaveError(null)
    try {
      await saveItem({ ...form, id: isNew ? null : id })
      navigate('/') // back to the Kitchen
    } catch (err) {
      setSaveError(err.message)
      setBusy(false)
    }
  }

  async function handleDelete() {
    if (!window.confirm(`Delete ${form.name}? This can’t be undone.`)) return
    setBusy(true)
    setSaveError(null)
    try {
      await deleteItem(id)
      navigate('/')
    } catch (err) {
      setSaveError(err.message)
      setBusy(false)
    }
  }

  const header = (
    <header className="form-header">
      <Link to="/" className="back-link">
        Cancel
      </Link>
      <h1>{isNew ? 'Add item' : 'Edit item'}</h1>
      <span className="form-header-spacer" />
    </header>
  )

  if (loadError || notFound) {
    return (
      <div className="screen">
        {header}
        <div className="center-message">
          <p>{notFound ? 'That item doesn’t exist any more.' : 'Couldn’t load this item.'}</p>
          {loadError && <p className="muted">{loadError}</p>}
          <Link to="/" className="primary primary-link">
            Back to Kitchen
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

  // If an old item has a category that's no longer in the list, still offer it.
  const categoryChoices = CATEGORIES.includes(form.category) ? CATEGORIES : [...CATEGORIES, form.category]

  return (
    <div className="screen">
      {header}

      <form className="item-form" onSubmit={handleSubmit}>
        <label className="field">
          <span className="field-label">Name</span>
          <input
            value={form.name}
            onChange={(e) => setField('name', e.target.value)}
            placeholder="e.g. Basmati rice, 8 kg"
            required
          />
        </label>

        <label className="field">
          <span className="field-label">
            Usual amount <span className="field-hint">Shows on your shopping list</span>
          </span>
          <input
            value={form.usual_amount}
            onChange={(e) => setField('usual_amount', e.target.value)}
            placeholder="e.g. 1 bag"
          />
        </label>

        <fieldset className="field">
          <legend className="field-label">Category</legend>
          <div className="chip-row">
            {categoryChoices.map((c) => (
              <button
                key={c}
                type="button"
                className={form.category === c ? 'chip is-on' : 'chip'}
                aria-pressed={form.category === c}
                onClick={() => setField('category', c)}
              >
                {c}
              </button>
            ))}
          </div>
        </fieldset>

        <fieldset className="field">
          <legend className="field-label">
            Where do you buy it? <span className="field-hint">Pick one or more</span>
          </legend>
          {stores.length === 0 && <p className="muted">No stores yet.</p>}
          <ul className="store-picker">
            {stores.map((store) => {
              const picked = form.storeIds.includes(store.id)
              const preferred = form.preferredStoreId === store.id
              return (
                <li key={store.id} className="store-pick">
                  <button
                    type="button"
                    className="store-pick-toggle"
                    aria-pressed={picked}
                    onClick={() => toggleStore(store.id)}
                  >
                    <span className={picked ? 'box is-on' : 'box'} aria-hidden="true">
                      {picked ? '✓' : ''}
                    </span>
                    {store.name}
                  </button>
                  {picked && (
                    <button
                      type="button"
                      className={preferred ? 'pref is-on' : 'pref'}
                      aria-pressed={preferred}
                      aria-label={preferred ? `${store.name} is the preferred store` : `Make ${store.name} the preferred store`}
                      onClick={() => togglePreferred(store.id)}
                    >
                      {preferred ? '★ Preferred' : '☆ Make preferred'}
                    </button>
                  )}
                </li>
              )
            })}
          </ul>
          <Link to="/stores" className="text-link">
            + Add or rename stores
          </Link>
        </fieldset>

        <fieldset className="field">
          <legend className="field-label">Status right now</legend>
          <StatusControl status={form.status} onChange={(s) => setField('status', s)} />
        </fieldset>

        <label className="toggle-row">
          <span>
            <span className="toggle-title">Always keep stocked</span>
            <span className="field-hint">Nudge me when it goes low</span>
          </span>
          <input
            type="checkbox"
            className="switch"
            checked={form.always_stocked}
            onChange={(e) => setField('always_stocked', e.target.checked)}
          />
        </label>

        {saveError && (
          <p className="notice" role="alert">
            {saveError}
          </p>
        )}

        <button type="submit" className="primary" disabled={busy}>
          {busy ? 'Saving…' : isNew ? 'Add item' : 'Save changes'}
        </button>

        {!isNew && (
          <button type="button" className="link-button danger delete-button" onClick={handleDelete} disabled={busy}>
            Delete item
          </button>
        )}
      </form>
    </div>
  )
}
