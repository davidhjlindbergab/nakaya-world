-- ═══════════════════════════════════════════════════════════
-- NAKÃYA PORTAL · DATABASE
-- Paste this whole file into Supabase → SQL Editor → Run.
-- Safe to run more than once.
-- ═══════════════════════════════════════════════════════════


-- ───────────────────────────────────────────────
-- 1. TRAVELERS
-- One row per person. Created automatically on signup.
-- ───────────────────────────────────────────────
create table if not exists travelers (
  id            uuid primary key references auth.users on delete cascade,
  anon_name     text not null,              -- display name on reflections
  region        text not null default 'Jérikko',
  connections   int  not null default 0,    -- total encounters
  region_count  int  not null default 0,    -- encounters in current region
  created_at    timestamptz not null default now(),
  last_seen_at  timestamptz not null default now()
);

-- ───────────────────────────────────────────────
-- 2. ENCOUNTERS
-- One row each time a being is met.
-- ───────────────────────────────────────────────
create table if not exists encounters (
  id          bigint generated always as identity primary key,
  traveler_id uuid not null references travelers on delete cascade,
  being_id    text not null,                -- "vermaya", "maw", etc
  region      text not null,
  side        text,                         -- 'river' or 'drift'
  met_at      timestamptz not null default now()
);
create index if not exists encounters_traveler_idx on encounters (traveler_id);
create index if not exists encounters_being_idx    on encounters (being_id);

-- ───────────────────────────────────────────────
-- 3. REFLECTIONS
-- Public answers to a being's question.
-- ───────────────────────────────────────────────
create table if not exists reflections (
  id          bigint generated always as identity primary key,
  traveler_id uuid not null references travelers on delete cascade,
  being_id    text not null,
  body        text not null check (char_length(body) between 1 and 1000),
  signed_name text,                         -- null = anonymous
  hidden      bool not null default false,  -- your moderation switch
  created_at  timestamptz not null default now()
);
create index if not exists reflections_being_idx on reflections (being_id, created_at desc);

-- ───────────────────────────────────────────────
-- 4. PRACTICES
-- One row each time someone marks "I did this".
-- Feeds the Pattern and pushes back the Tide.
-- ───────────────────────────────────────────────
create table if not exists practices (
  id          bigint generated always as identity primary key,
  traveler_id uuid not null references travelers on delete cascade,
  being_id    text not null,
  region      text not null,
  done_at     timestamptz not null default now()
);
create index if not exists practices_traveler_idx on practices (traveler_id);

-- ───────────────────────────────────────────────
-- 5. KIN BONDS
-- Two travelers, one weekly question.
-- ───────────────────────────────────────────────
create table if not exists kin_bonds (
  id          bigint generated always as identity primary key,
  code        text unique not null,         -- the invite code
  traveler_a  uuid not null references travelers on delete cascade,
  traveler_b  uuid references travelers on delete cascade,
  created_at  timestamptz not null default now()
);

create table if not exists kin_answers (
  id          bigint generated always as identity primary key,
  bond_id     bigint not null references kin_bonds on delete cascade,
  traveler_id uuid not null references travelers on delete cascade,
  week        date not null,                -- monday of that week
  being_id    text not null,
  body        text not null,
  created_at  timestamptz not null default now(),
  unique (bond_id, traveler_id, week)
);

-- ───────────────────────────────────────────────
-- 6. SENT BEINGS
-- "Send a being" codes.
-- ───────────────────────────────────────────────
create table if not exists sent_beings (
  code        text primary key,
  being_id    text not null,
  sender_id   uuid references travelers on delete set null,
  note        text,
  opened_by   uuid references travelers on delete set null,
  created_at  timestamptz not null default now()
);

-- ───────────────────────────────────────────────
-- 7. THE TIDE
-- One single row. The shared world state.
-- ───────────────────────────────────────────────
create table if not exists tide (
  id         int primary key default 1 check (id = 1),
  level      numeric not null default 50,   -- 0 = pushed back, 100 = Maw wins
  updated_at timestamptz not null default now()
);
insert into tide (id, level) values (1, 50) on conflict do nothing;


-- ═══════════════════════════════════════════════════════════
-- SECURITY
-- Row Level Security: everyone can only touch their own rows.
-- Without this, anyone could read or delete anyone's data.
-- ═══════════════════════════════════════════════════════════

alter table travelers   enable row level security;
alter table encounters  enable row level security;
alter table reflections enable row level security;
alter table practices   enable row level security;
alter table kin_bonds   enable row level security;
alter table kin_answers enable row level security;
alter table sent_beings enable row level security;
alter table tide        enable row level security;

-- Travelers: read and edit only yourself
create policy "own row"     on travelers   for select using (auth.uid() = id);
create policy "own update"  on travelers   for update using (auth.uid() = id);
create policy "own insert"  on travelers   for insert with check (auth.uid() = id);

-- Encounters and practices: yours only
create policy "own read"    on encounters  for select using (auth.uid() = traveler_id);
create policy "own write"   on encounters  for insert with check (auth.uid() = traveler_id);
create policy "own read"    on practices   for select using (auth.uid() = traveler_id);
create policy "own write"   on practices   for insert with check (auth.uid() = traveler_id);

-- Reflections: everyone reads the visible ones, you write your own
create policy "public read" on reflections for select using (hidden = false);
create policy "own write"   on reflections for insert with check (auth.uid() = traveler_id);
create policy "own delete"  on reflections for delete using (auth.uid() = traveler_id);

-- Kin: only the two people in the bond
create policy "in bond"     on kin_bonds   for select using (auth.uid() in (traveler_a, traveler_b));
create policy "own write"   on kin_answers for insert with check (auth.uid() = traveler_id);
create policy "in bond"     on kin_answers for select using (
  exists (select 1 from kin_bonds b where b.id = bond_id and auth.uid() in (b.traveler_a, b.traveler_b))
);

-- Sent beings: anyone with the code can look it up
create policy "code lookup" on sent_beings for select using (true);
create policy "own write"   on sent_beings for insert with check (auth.uid() = sender_id);

-- Tide: everyone sees it, nobody edits it directly
create policy "public read" on tide        for select using (true);


-- ═══════════════════════════════════════════════════════════
-- AUTOMATIC BEHAVIOR
-- ═══════════════════════════════════════════════════════════

-- When someone signs up, create their traveler row automatically.
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into travelers (id, anon_name)
  values (new.id, 'Traveler ' || substr(new.id::text, 1, 4));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();


-- Every practice done pushes the Tide back a little.
create or replace function push_tide_back()
returns trigger language plpgsql security definer as $$
begin
  update tide set level = greatest(0, level - 0.05), updated_at = now() where id = 1;
  return new;
end;
$$;

drop trigger if exists on_practice_done on practices;
create trigger on_practice_done
  after insert on practices
  for each row execute function push_tide_back();


-- ═══════════════════════════════════════════════════════════
-- YOUR STATS
-- Read these in Supabase → SQL Editor, or build a screen on them.
-- ═══════════════════════════════════════════════════════════

create or replace view stats_overview as
select
  (select count(*) from travelers)                                              as total_travelers,
  (select count(*) from travelers where created_at > now() - interval '7 days') as new_this_week,
  (select count(*) from travelers where last_seen_at > now() - interval '1 day')as active_today,
  (select count(*) from encounters)                                             as total_encounters,
  (select count(*) from practices)                                              as total_practices,
  (select count(*) from reflections where hidden = false)                       as total_reflections,
  (select level from tide where id = 1)                                         as tide_level;

-- Which beings land hardest
create or replace view stats_by_being as
select
  e.being_id,
  count(distinct e.traveler_id)                     as travelers_met,
  count(distinct p.traveler_id)                     as did_the_practice,
  count(distinct r.traveler_id)                     as left_reflection,
  round(100.0 * count(distinct p.traveler_id)
        / nullif(count(distinct e.traveler_id), 0), 1) as practice_rate_pct
from encounters e
left join practices   p on p.being_id = e.being_id
left join reflections r on r.being_id = e.being_id and r.hidden = false
group by e.being_id
order by travelers_met desc;

-- Where people stop
create or replace view stats_by_region as
select region, count(*) as travelers_here
from travelers group by region order by count(*) desc;

-- Signups per day
create or replace view stats_daily as
select date_trunc('day', created_at)::date as day, count(*) as signups
from travelers group by 1 order by 1 desc;
