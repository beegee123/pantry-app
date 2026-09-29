import { useEffect, useState } from 'react'
import { Routes, Route, Navigate } from 'react-router'
import { supabase, missingConfig } from './lib/supabase.js'
import SignIn from './components/SignIn.jsx'
import KitchenScreen from './components/KitchenScreen.jsx'
import StoresScreen from './components/StoresScreen.jsx'

// App decides WHICH screen to show: setup problem, loading, sign-in, or one of the app's screens.
export default function App() {
  // undefined = still checking, null = signed out, object = signed in
  const [session, setSession] = useState(undefined)

  useEffect(() => {
    if (missingConfig) return

    // 1. Is someone already signed in on this device?
    supabase.auth.getSession().then(({ data }) => setSession(data.session))

    // 2. Keep listening: sign in, sign out and token refresh all land here.
    const { data } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession)
    })

    // Cleanup: stop listening when App goes away.
    return () => data.subscription.unsubscribe()
  }, [])

  if (missingConfig) {
    return (
      <div className="screen center-message">
        <p>The app isn’t connected to Supabase yet.</p>
        <p className="muted">
          Add VITE_SUPABASE_URL and VITE_SUPABASE_PUBLISHABLE_KEY to .env.local (see .env.example),
          then restart <code>npm run dev</code>.
        </p>
      </div>
    )
  }

  if (session === undefined) return <div className="screen center-message muted">Loading…</div>
  if (session === null) return <SignIn />

  // Signed in: pick the screen from the address bar.
  return (
    <Routes>
      <Route path="/" element={<KitchenScreen />} />
      <Route path="/stores" element={<StoresScreen />} />
      {/* Any unknown address goes back to the Kitchen. */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}
