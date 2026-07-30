# Nakãya Portal · from prototype to app store

Written for someone who has never shipped an app. Nothing here assumes you
know what any of these tools are. Do the stages in order. Each one works on
its own, so you can stop between them for days or weeks.

Realistic timeline: a few weeks of evenings, plus 1 to 2 weeks of waiting on
Apple.

---

## What you have and what is missing

You have the whole app: the world, the beings, the artwork, the screens.

What is missing is the part that connects people. Right now every reflection,
every Kin bond, and the Tide itself exists only on your own phone. Two
travelers cannot actually reach each other. That is what Stage 1 fixes, and
it is the reason it comes before the app stores.

---

## Stage 1 · The backend (Supabase)

**What Supabase is:** a database in the cloud, plus login handling, on a free
tier that is generous enough for years of a project this size. Think of it as
the shared memory the app is currently missing.

1. Go to supabase.com, sign up, create a new project.
   - Name: `nakaya-portal`
   - Region: pick Frankfurt or Stockholm (closest to your users)
   - Save the database password somewhere safe. You will not need it often,
     and you cannot recover it.
2. Wait about two minutes for it to finish setting up.
3. In the left sidebar, open **SQL Editor**, click **New query**.
4. Open `supabase-schema.sql` from this repo, copy all of it, paste, click
   **Run**. It should say Success.
5. In the sidebar, open **Table Editor**. You should now see travelers,
   encounters, reflections, practices, and the rest.
6. Go to **Project Settings → API**. Copy two values and keep them handy:
   - Project URL
   - `anon` public key

**About those keys:** the anon key is safe to put in your app code. It is
designed to be public. Never copy the `service_role` key into the app, and
never paste either key into a chat. The security is handled by the Row Level
Security rules in the schema, which make sure each traveler can only touch
their own data.

**Then:** the app code has to actually talk to it. That is a real coding
task, not a copy-paste one. Take it to Claude Code in your repo, one piece at
a time in this order:

1. Login and traveler creation
2. Encounters saving to the database
3. Reflections reading and writing from the database
4. The Tide reading its real value
5. Kin bonds and send-a-being codes

Do not do all five at once. Get login working and confirm you can see a row
appear in the Supabase table editor. That moment is the proof everything else
is built on.

---

## Stage 2 · Your dashboard

The schema already built your statistics. Four views exist:

- `stats_overview` — travelers, new this week, active today, encounters,
  practices, reflections, tide level
- `stats_by_being` — which beings people meet, and what share of them
  actually do the practice. This is your single most useful number: it tells
  you which encounters land and which fall flat.
- `stats_by_region` — where people are in the journey, and therefore where
  they stop
- `stats_daily` — signups per day

To read them: Supabase → SQL Editor → `select * from stats_overview;`

To read reflections as they come in:

```sql
select created_at, being_id, signed_name, body
from reflections
where hidden = false
order by created_at desc
limit 50;
```

To hide one you do not want public:

```sql
update reflections set hidden = true where id = 123;
```

That is enough for the first months. Later, a hidden admin screen inside the
app can show the same numbers without opening Supabase. Not urgent.

---

## Stage 3 · Making it a real app (Capacitor)

**What Capacitor is:** a wrapper that takes the web app you already have and
turns it into a real iOS and Android app. Your code barely changes. This is
why it is the right choice: rebuilding in React Native would mean redoing
every screen's styling, weeks of work, to arrive back where you already are.

You need a Mac for the iOS half. There is no way around that.

```bash
npm install @capacitor/core @capacitor/cli
npx cap init "Nakãya" world.nakaya.portal
npm install @capacitor/ios @capacitor/android
npm run build
npx cap add ios
npx cap add android
npx cap open ios      # opens Xcode
```

Things that will need attention once it runs on a phone:

- **The splash screen and icon.** Use the portal artwork.
- **Safe areas.** The notch and home indicator will cut into your layout.
  Fixed by CSS `env(safe-area-inset-*)`.
- **The background video.** iOS is strict about autoplay. It needs `muted`
  and `playsInline`, which the code already has. Test it early.
- **Fonts.** Confirm your display and serif faces load in the native shell.

---

## Stage 4 · The stores

**Apple**

- Apple Developer Program: $99/year, at developer.apple.com
- Registration can take a few days to clear, so start it early
- Builds go up through Xcode, then to TestFlight for testing
- First review usually takes 1 to 3 days, and a rejection on the first try is
  completely normal

**Google**

- Play Console: $25, one time
- Faster and more forgiving than Apple
- Internal testing track puts a build on your own devices in about an hour

**What both will ask for and what will slow you down:**

- Privacy policy, at a public URL. Required. You collect emails and written
  reflections, so this is not optional.
- What data you collect and why
- Screenshots at several sizes
- Age rating
- Account deletion. Apple requires that a user can delete their account from
  inside the app, not just email you about it. Build this before submitting.

**Since reflections are public and user-written**, Apple will look for
moderation. Have ready: a way to report a reflection, a way for you to hide
one (the `hidden` column), and terms that say what is not allowed. Apps with
user content and no moderation get rejected.

---

## How we keep working together

- **This chat** for writing, world, design decisions, single-file changes.
- **Claude Code** in the repo for anything touching multiple files: Supabase
  wiring, Capacitor, auth. It reads only what it needs, so you will not hit
  the wall you hit before.
- **Commit before each session**, so there is always a version to go back to.
- **One thing at a time.** "Wire up login" is a good session. "Add the
  backend" is not.

---

## The honest order of priority

1. Supabase login and encounters saved
2. Reflections actually shared between travelers
3. Play Store internal testing, to see it as a real app
4. Account deletion, privacy policy, moderation
5. Apple, TestFlight, App Store

Stop at step 3 for a while if you want. A working app on your own phone,
with real travelers' reflections appearing in it, teaches you more than a
store listing does.
