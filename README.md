# Nakãya World

A React experience backed by Supabase.

## Requirements

- Node.js 20.19 or newer
- npm

## Run locally

```bash
git clone https://github.com/davidhjlindbergab/nakaya-world.git
cd nakaya-world
git switch agent/make-app-runnable
npm install
npm run dev
```

Open the local address printed by Vite, normally <http://localhost:5173>.

## Validate a production build

```bash
npm test
```

This compiles the production app and catches missing imports, JSX errors, and bundling failures.

## Supabase

The frontend connects to project `fqzfzvlubpfbnimhrgjq` through the public anonymous client key. Never put a `service_role` key in frontend code.

For database-backed behavior, anonymous authentication must be enabled in the Supabase project. The app continues in local-storage mode if Supabase is unavailable.

## Manual smoke test

1. Open the app in a private browser window.
2. Complete first contact and choose a traveler name.
3. Start an encounter and make a choice.
4. Complete a practice and verify the Pattern changes.
5. Leave a reflection, refresh, and confirm the journey remains.
6. Open a second private window to test shared Tide, sent-being codes, and Kin flows as another anonymous traveler.
