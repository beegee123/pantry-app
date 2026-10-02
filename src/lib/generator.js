// The menu generator (step 16): pick a dinner for each chosen day.
//
// It's a plain function — no database, no React — so it's easy to test and reason about:
// recipes + options in, a plan out. Saving is done separately (api/menu.js).
//
// How it works: every recipe gets a SCORE for each day, and the best-scoring recipe wins.
// A little randomness is added so pressing Generate again doesn't always give the same week.

import { readiness } from './readiness.js'

export const LONG_MINUTES = 45 // "long recipe" = more than this

// How much the pantry matters, per priority setting.
const STOCK_WEIGHTS = {
  have: { ready: 4, perLow: -1, perMissing: -3 }, //     "Use what I have"
  balanced: { ready: 2, perLow: -0.5, perMissing: -1.5 },
  any: { ready: 0, perLow: 0, perMissing: 0 }, //        "Don't care"
}

const FAVOURITE_BONUS = 2
const WEEKEND_LONG_BONUS = 3 // with "long recipes on weekends", weekends prefer the long ones
const REPEAT_PENALTY = -3 //    with repeats allowed, each earlier use this week costs this much
const LAST_WEEK_PENALTY = -20 // "avoid last week": only picked once fresher recipes run out
const RANDOMNESS = 2 //         up to +2 at random, so close scores swap places

const isWeekend = (isoDate) => {
  const day = new Date(`${isoDate}T12:00:00`).getDay() // noon: no time-zone surprises
  return day === 0 || day === 6
}

const isLong = (recipe) => recipe.minutes > LONG_MINUTES

// "Long recipes on weekends ONLY" is strict: a long recipe can't be picked for a weekday.
// (Avoiding last week is softer — see LAST_WEEK_PENALTY — or a small recipe list would
// leave most of the week empty.)
function allowed(recipe, date, options) {
  if (options.longOnWeekends && isLong(recipe) && !isWeekend(date)) return false
  return true
}

// One recipe's score for one day: higher = better.
export function scoreRecipe(recipe, date, options, timesUsed = 0, lastWeekIds = new Set()) {
  const w = STOCK_WEIGHTS[options.priority] ?? STOCK_WEIGHTS.balanced
  const r = readiness(recipe.ingredientStatuses)
  let score = 0

  if (r.kind === 'ready') score += w.ready
  score += r.low * w.perLow + r.missing * w.perMissing

  if (options.favourites && recipe.is_favourite) score += FAVOURITE_BONUS
  if (options.longOnWeekends && isLong(recipe) && isWeekend(date)) score += WEEKEND_LONG_BONUS
  if (options.skipLastWeek && lastWeekIds.has(recipe.id)) score += LAST_WEEK_PENALTY
  score += timesUsed * REPEAT_PENALTY

  return score
}

// Pick a recipe for each date.
//   recipes      — dinner recipes [{ id, name, minutes, is_favourite, ingredientStatuses }]
//   dates        — the days to fill, "YYYY-MM-DD", in order
//   options      — { priority: 'have'|'balanced'|'any', noRepeats, skipLastWeek, favourites, longOnWeekends }
//   keptIds      — recipes already on the days you're NOT changing (they count as "used this week")
//   lastWeekIds  — recipes planned in the 7 days before this week
//   random       — a function returning 0…1 (Math.random; tests pass a fixed one)
// Returns { picks: [{ date, recipeId }], emptyDates: [dates left empty] }
export function generatePlan({ recipes, dates, options, keptIds = [], lastWeekIds = new Set(), random = Math.random }) {
  const used = new Map() // recipe id → times used this week
  const use = (id) => used.set(id, (used.get(id) ?? 0) + 1)
  keptIds.forEach(use)
  const picks = []
  const emptyDates = []

  // Weekend days first when long recipes are saved for weekends, so they get first pick of them.
  const order = options.longOnWeekends
    ? [...dates.filter(isWeekend), ...dates.filter((d) => !isWeekend(d))]
    : dates

  for (const date of order) {
    const candidates = recipes.filter(
      (r) => !(options.noRepeats && used.has(r.id)) && allowed(r, date, options),
    )
    if (candidates.length === 0) {
      emptyDates.push(date) // nothing left that fits the rules for this day
      continue
    }
    let best = null
    let bestScore = -Infinity
    for (const recipe of candidates) {
      const score = scoreRecipe(recipe, date, options, used.get(recipe.id) ?? 0, lastWeekIds) + random() * RANDOMNESS
      if (score > bestScore) {
        best = recipe
        bestScore = score
      }
    }
    picks.push({ date, recipeId: best.id })
    use(best.id)
  }

  picks.sort((a, b) => a.date.localeCompare(b.date)) // back to calendar order
  emptyDates.sort()
  return { picks, emptyDates }
}
