# Pantry App

Keep track of what's in, low or out in the kitchen, turn it into a shopping list grouped by store, and (later) plan a week of meals from what you have.

## Docs

- [Build plan](docs/BUILD_PLAN.md) — decisions, phases, steps and the data model
- [Wireframes](docs/wireframes/README.md) — the original screen designs

## Stack

- **Front end:** React, installed on the phone's home screen as a web app
- **Back end:** Supabase (Postgres database, file storage, sign-in)
- **Hosting:** Vercel

## Build phases

| Phase | What it adds |
| --- | --- |
| 1 — Pantry & shopping | Items with In / Low / Out, stores, shopping list by store |
| 1.5 — Chat bot | Telegram and WhatsApp: "out of eggs" updates the pantry |
| 2 — Recipes & photos | Recipes linked to pantry items, "can I cook this?" |
| 3 — Weekly menu | Generate a week of meals, send missing items to the list |

## Database setup

Run the files in `supabase/` in order, in the Supabase SQL Editor.

1. `001_pantry_tables.sql` — items, stores and the item–store link table, plus starter data
2. `002_realtime.sql` — live updates for items across devices
3. `003_stores_realtime.sql` — live updates for stores and item–store links
4. `004_save_item.sql` — `save_item` function: saves an item and its stores in one transaction
5. `005_shopping.sql` — cart ticks (`in_cart`) and the `finish_trip` function

## Running locally

1. Copy `.env.example` to `.env.local` and fill in your Supabase URL and publishable key.
2. `npm install`
3. `npm run dev`

## Deploying

The app is hosted on Vercel and redeploys automatically on every push to `main`.

- `vercel.json` sends every address to `index.html`, so React Router can show the right screen (refreshing on `/shopping` works).
- In Vercel → Project → Settings → Environment Variables, set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` (the same values as `.env.local`).
- In Supabase → Authentication → URL Configuration, set the Site URL to the Vercel address.
- On a phone, open the address and use **Add to Home Screen** to install it as an app.
