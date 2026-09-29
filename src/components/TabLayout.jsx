import { useEffect, useState } from 'react'
import { NavLink, Outlet } from 'react-router'
import { fetchNeededCount } from '../api/shopping.js'
import { subscribeToTables } from '../lib/realtime.js'

// A LAYOUT ROUTE: draws the bottom tab bar once, and <Outlet /> shows
// whichever screen inside it is active (Kitchen or Shopping).
export default function TabLayout() {
  const [neededCount, setNeededCount] = useState(null)

  useEffect(() => {
    const refresh = () =>
      fetchNeededCount()
        .then(setNeededCount)
        .catch(() => setNeededCount(null)) // the badge is a nice-to-have; hide it on error
    refresh()
    // Keep the badge up to date when any item's status changes, on any device.
    return subscribeToTables('tab-badge', ['items'], refresh)
  }, [])

  // NavLink knows whether its address is the current one, and lets us style it.
  const tabClass = ({ isActive }) => (isActive ? 'tab is-active' : 'tab')

  return (
    <div className="with-tabs">
      <Outlet />
      <nav className="tab-bar" aria-label="Main">
        <NavLink to="/" end className={tabClass}>
          Kitchen
        </NavLink>
        <NavLink to="/shopping" className={tabClass}>
          Shopping
          {neededCount > 0 && <span className="badge">{neededCount}</span>}
        </NavLink>
      </nav>
    </div>
  )
}
