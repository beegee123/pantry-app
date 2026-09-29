# Pantry App

Keep track of what's in, low or out in the kitchen, turn it into a shopping list grouped by store, and (later) plan a week of meals from what you have.

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

## Running locally

1. Copy `.env.example` to `.env.local` and fill in your Supabase URL and publishable key.
2. `npm install`
3. `npm run dev`
