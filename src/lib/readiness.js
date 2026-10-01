// "Can I cook this?" — worked out from the live status of a recipe's ingredients.
// Basics (salt, oil, water) are not ingredients, so they never count.
//
// Returns { kind, label, missing, low, total }
//   kind: 'ready' | 'low' | 'missing' | 'empty'
export function readiness(statuses) {
  const total = statuses.length
  const missing = statuses.filter((s) => s === 'out').length
  const low = statuses.filter((s) => s === 'low').length

  if (total === 0) return { kind: 'empty', label: 'NO INGREDIENTS', missing, low, total }
  if (missing > 0) return { kind: 'missing', label: `MISSING ${missing}`, missing, low, total }
  if (low > 0) return { kind: 'low', label: `${low} LOW`, missing, low, total }
  return { kind: 'ready', label: 'READY', missing, low, total }
}

// Sort order for the Recipes list: Ready first, then fewest missing, then fewest low, then A–Z.
// Recipes with no ingredients go last (we can't tell if they're ready).
export function compareByReadiness(a, b) {
  const ra = a.readiness
  const rb = b.readiness
  const emptyA = ra.kind === 'empty' ? 1 : 0
  const emptyB = rb.kind === 'empty' ? 1 : 0
  return emptyA - emptyB || ra.missing - rb.missing || ra.low - rb.low || a.name.localeCompare(b.name)
}
