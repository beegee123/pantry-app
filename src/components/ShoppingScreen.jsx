import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router'
import { fetchShoppingList, setInCart, finishTrip } from '../api/shopping.js'
import { subscribeToTables } from '../lib/realtime.js'
import { fetchPlan, neededByMenu } from '../api/menu.js'
import { addDays, dayNumber, shortDay, startOfWeek, today, toISODate } from '../lib/dates.js'

const ANY_STORE = 'any'
const MENU = 'menu' // the "This week" chip: items this week's planned dinners need (today → Sunday)
const NEXT = 'next' // the "Next week" chip: items next week's dinners need (Monday → Sunday)

// Decide which store heading each item goes under:
//   its preferred store → else its first store (A–Z) → else "Any store".
// Each item appears ONCE, with the other stores listed as "also at".
function groupByStore(items) {
  const groups = new Map() // key → { key, name, items }

  for (const item of items) {
    const byName = [...item.stores].sort((a, b) => a.name.localeCompare(b.name))
    const home = item.stores.find((s) => s.is_preferred) ?? byName[0]
    const key = home ? home.id : ANY_STORE
    const name = home ? home.name : 'Any store'
    const alsoAt = byName.filter((s) => s !== home).map((s) => s.name)

    if (!groups.has(key)) groups.set(key, { key, name, items: [] })
    groups.get(key).items.push({ ...item, alsoAt })
  }

  // Stores A–Z, with "Any store" last.
  return [...groups.values()].sort((a, b) => {
    if (a.key === ANY_STORE) return 1
    if (b.key === ANY_STORE) return -1
    return a.name.localeCompare(b.name)
  })
}

// Store chips: every store where at least one needed item can be bought,
// counting ALL items available there (not just the ones whose preferred store it is).
function storeChips(items) {
  const chips = new Map() // key → { key, name, count }
  for (const item of items) {
    if (item.stores.length === 0) {
      if (!chips.has(ANY_STORE)) chips.set(ANY_STORE, { key: ANY_STORE, name: 'Any store', count: 0 })
      chips.get(ANY_STORE).count++
    }
    for (const store of item.stores) {
      if (!chips.has(store.id)) chips.set(store.id, { key: store.id, name: store.name, count: 0 })
      chips.get(store.id).count++
    }
  }
  return [...chips.values()].sort((a, b) => {
    if (a.key === ANY_STORE) return 1
    if (b.key === ANY_STORE) return -1
    return a.name.localeCompare(b.name)
  })
}

// One store's view: everything you can buy THERE, even if its preferred store is elsewhere.
// "also at" lists the item's other stores, so you know it could wait for another trip.
function itemsAtStore(items, storeKey) {
  return items
    .filter((item) =>
      storeKey === ANY_STORE ? item.stores.length === 0 : item.stores.some((s) => s.id === storeKey),
    )
    .map((item) => ({
      ...item,
      alsoAt: item.stores
        .filter((s) => s.id !== storeKey)
        .map((s) => s.name)
        .sort((a, b) => a.localeCompare(b)),
    }))
}

// The small grey line under an item: "Usual: 1 bag · also at No Frills"
function rowDetails(item) {
  const parts = []
  if (item.in_cart) parts.push('In cart')
  else if (item.usual_amount) parts.push(`Usual: ${item.usual_amount}`)
  if (item.atStores) parts.push(`at ${item.atStores.join(', ')}`) // "This week" view: where to buy it
  if (item.alsoAt.length > 0) parts.push(`also at ${item.alsoAt.join(', ')}`)
  return parts.join(' · ')
}

// Step 18: "For Tue Jollof rice, Thu Fried rice" — which planned dinners need this item.
// Next week's dinners carry the date too ("Tue 13"), so the two weeks can't be mixed up.
const menuTag = (uses, nextMonday) =>
  `For ${uses
    .map((u) => `${shortDay(u.plan_date)}${u.plan_date >= nextMonday ? ` ${dayNumber(u.plan_date)}` : ''} ${u.recipeName}`)
    .join(', ')}`

// The calendar weeks the Menu tab shows: this one (from today) and the next, as "YYYY-MM-DD".
function menuWeeks() {
  const thisMonday = startOfWeek(new Date())
  return {
    today: today(),
    nextMonday: toISODate(addDays(thisMonday, 7)),
    nextSunday: toISODate(addDays(thisMonday, 13)),
  }
}

const plural = (n, word) => `${n} ${word}${n === 1 ? '' : 's'}`

export default function ShoppingScreen() {
  const [items, setItems] = useState(null) // null = loading
  const [loadError, setLoadError] = useState(null)
  const [actionError, setActionError] = useState(null)
  const [message, setMessage] = useState(null) // e.g. "Restocked 4 items."
  const [searchParams] = useSearchParams()
  // The Menu screen links here with ?show=menu (this week) or ?show=next to open on that chip.
  const shown = searchParams.get('show')
  const [storeFilter, setStoreFilter] = useState(shown === MENU || shown === NEXT ? shown : 'all')
  // item_id → planned dinners that need it: both weeks (for the tags), and each week (for its chip)
  const [menuUses, setMenuUses] = useState({ all: new Map(), [MENU]: new Map(), [NEXT]: new Map() })
  const weeks = menuWeeks()
  const [busy, setBusy] = useState(false)
  const [reloadCount, setReloadCount] = useState(0)
  const reload = () => setReloadCount((n) => n + 1)

  useEffect(() => {
    let ignore = false
    // Dinners planned from today to the end of next week, to tag the items they need.
    const { today: from, nextMonday, nextSunday } = menuWeeks()
    Promise.all([fetchShoppingList(), fetchPlan(from, nextSunday).catch(() => [])]) // no plan → no tags
      .then(([data, plan]) => {
        if (ignore) return
        setItems(data)
        setMenuUses({
          all: neededByMenu(plan),
          [MENU]: neededByMenu(plan.filter((p) => p.plan_date < nextMonday)),
          [NEXT]: neededByMenu(plan.filter((p) => p.plan_date >= nextMonday)),
        })
        setLoadError(null)
      })
      .catch((err) => {
        if (!ignore) setLoadError(err.message)
      })
    return () => {
      ignore = true
    }
  }, [reloadCount])

  // Someone else ticks an item, changes a status or edits stores → reload.
  useEffect(() => subscribeToTables('shopping', ['items', 'item_stores', 'stores', 'meal_plan'], reload), [])

  // Tick / untick: optimistic, like the status buttons on the Kitchen.
  async function toggleCart(item) {
    const next = !item.in_cart
    const setTick = (value) =>
      setItems((current) => current.map((i) => (i.id === item.id ? { ...i, in_cart: value } : i)))

    setTick(next)
    setActionError(null)
    setMessage(null)
    try {
      await setInCart(item.id, next)
    } catch {
      setTick(!next)
      setActionError(`Couldn’t update ${item.name}. Check your connection and try again.`)
    }
  }

  async function handleFinish() {
    setBusy(true)
    setActionError(null)
    try {
      const count = await finishTrip()
      setMessage(`Restocked ${plural(count, 'item')}.`)
      reload()
    } catch (err) {
      setActionError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const header = (
    <header className="screen-header">
      <div>
        <span className="eyebrow">TO BUY</span>
        <h1>Shopping list</h1>
      </div>
    </header>
  )

  if (loadError) {
    return (
      <div className="screen">
        {header}
        <div className="center-message">
          <p>Couldn’t load your shopping list.</p>
          <p className="muted">{loadError}</p>
          <button type="button" className="primary" onClick={reload}>
            Try again
          </button>
        </div>
      </div>
    )
  }

  if (items === null) {
    return (
      <div className="screen">
        {header}
        <p className="center-message muted">Loading…</p>
      </div>
    )
  }

  // TWO VIEWS:
  //   All        → each item once, under its preferred store (so nothing is bought twice)
  //   One store  → everything you can buy at that store
  const groups = groupByStore(items)
  const chips = storeChips(items)
  // If the chosen store has nothing left (e.g. after finishing), fall back to All.
  // The two week chips: the items each week's dinners need. An item both weeks need is in both
  // (it's still one item: ticking it in one ticks it in the other).
  const weekItems = (key) =>
    items
      .filter((i) => menuUses[key].has(i.id))
      .map((i) => ({ ...i, alsoAt: [], atStores: i.stores.length ? i.stores.map((s) => s.name).sort() : null }))
  const weekChips = [
    { key: MENU, label: 'This week', heading: 'For this week’s dinners', items: weekItems(MENU) },
    { key: NEXT, label: 'Next week', heading: 'For next week’s dinners', items: weekItems(NEXT) },
  ].filter((w) => w.items.length > 0)
  const activeChip = chips.find((c) => c.key === storeFilter)
  const activeWeek = weekChips.find((w) => w.key === storeFilter)
  const activeFilter = activeChip || activeWeek ? storeFilter : 'all'
  const visibleGroups =
    activeFilter === 'all'
      ? groups
      : activeWeek
        ? [{ key: activeWeek.key, name: activeWeek.heading, items: activeWeek.items }]
        : [{ key: activeChip.key, name: activeChip.name, items: itemsAtStore(items, activeChip.key) }]
  // On a week chip, each row's tag lists only that week's dinners; elsewhere, both weeks'.
  const tagUses = activeWeek ? menuUses[activeWeek.key] : menuUses.all
  const nextWeekRange = `${shortDay(weeks.nextMonday)} ${dayNumber(weeks.nextMonday)} – ${shortDay(weeks.nextSunday)} ${dayNumber(weeks.nextSunday)}`
  const cartCount = items.filter((i) => i.in_cart).length

  return (
    <div className="screen">
      {header}
      <p className="screen-subtitle">
        {items.length === 0
          ? 'Nothing to buy right now.'
          : activeFilter === 'all'
            ? `${plural(items.length, 'item')} across ${plural(groups.length, 'store')}`
            : activeFilter === MENU
              ? 'Needed for this week’s dinners, today to Sunday'
              : activeFilter === NEXT
              ? `Needed for next week’s dinners, ${nextWeekRange}`
              : activeFilter === ANY_STORE
              ? 'Items with no store picked — buy them anywhere'
              : `Everything you can get at ${activeChip.name}`}
      </p>

      {(chips.length > 1 || weekChips.length > 0) && (
        <div className="filter-chips filter-chips--scroll" role="group" aria-label="Show store">
          <button
            type="button"
            className={activeFilter === 'all' ? 'chip is-on' : 'chip'}
            aria-pressed={activeFilter === 'all'}
            onClick={() => setStoreFilter('all')}
          >
            All
          </button>
          {weekChips.map((w) => (
            <button
              key={w.key}
              type="button"
              className={activeFilter === w.key ? 'chip is-on' : 'chip'}
              aria-pressed={activeFilter === w.key}
              onClick={() => setStoreFilter(w.key)}
            >
              {w.label} {w.items.length}
            </button>
          ))}
          {chips.map((c) => (
            <button
              key={c.key}
              type="button"
              className={activeFilter === c.key ? 'chip is-on' : 'chip'}
              aria-pressed={activeFilter === c.key}
              onClick={() => setStoreFilter(c.key)}
            >
              {c.name} {c.count}
            </button>
          ))}
        </div>
      )}

      {message && (
        <p className="notice notice-success notice-inline" role="status">
          {message}
        </p>
      )}
      {actionError && (
        <p className="notice notice-inline" role="alert">
          {actionError}
        </p>
      )}

      <main className="item-list">
        {visibleGroups.map((group) => (
          <section key={group.key}>
            <h2 className="section-title section-title--split">
              <span>{group.name.toUpperCase()}</span>
              <span>{group.items.length}</span>
            </h2>
            <ul>
              {group.items.map((item) => (
                <li key={item.id} className={item.in_cart ? 'shop-row is-done' : 'shop-row'}>
                  <button
                    type="button"
                    className="cart-check"
                    aria-pressed={item.in_cart}
                    aria-label={item.in_cart ? `Take ${item.name} out of the cart` : `Put ${item.name} in the cart`}
                    onClick={() => toggleCart(item)}
                  >
                    <span className={item.in_cart ? 'box is-on' : 'box'} aria-hidden="true">
                      {item.in_cart ? '✓' : ''}
                    </span>
                  </button>
                  <div className="item-text">
                    <span className="item-name">{item.name}</span>
                    <span className="item-store">{rowDetails(item)}</span>
                    {tagUses.has(item.id) && (
                      <span className="menu-tag">{menuTag(tagUses.get(item.id), weeks.nextMonday)}</span>
                    )}
                  </div>
                  <span className={`pill pill-${item.status}`}>{item.status.toUpperCase()}</span>
                </li>
              ))}
            </ul>
          </section>
        ))}

        {items.length > 0 && (
          <button
            type="button"
            className="primary finish-button"
            onClick={handleFinish}
            disabled={busy || cartCount === 0}
          >
            {busy
              ? 'Finishing…'
              : cartCount === 0
                ? 'Tick items as they go in the cart'
                : `Finish trip · restock ${plural(cartCount, 'item')}`}
          </button>
        )}
      </main>
    </div>
  )
}
