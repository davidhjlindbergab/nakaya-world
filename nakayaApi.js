// ───────────────────────────────────────────────
// Everything the app needs from the database.
//
// Every function is safe to call before the anon key is set,
// and safe to call offline: it fails quietly and returns null
// so the app keeps working on local storage alone.
// ───────────────────────────────────────────────

import { supabase, supabaseReady } from "./supabase";

const quiet = async (fn, fallback = null) => {
  if (!supabaseReady) return fallback;
  try {
    const { data, error } = await fn();
    if (error) { console.warn("[nakaya]", error.message); return fallback; }
    return data;
  } catch (e) {
    console.warn("[nakaya]", e.message);
    return fallback;
  }
};

// ── SESSION ────────────────────────────────────
// Travelers do not make accounts. They get an anonymous
// identity the first time they open the app, which persists
// on the device. The traveler row is created automatically
// by the database trigger.

export async function ensureSession() {
  if (!supabaseReady) return null;
  const { data: { session } } = await supabase.auth.getSession();
  if (session) return session.user;
  const { data, error } = await supabase.auth.signInAnonymously();
  if (error) { console.warn("[nakaya] sign-in failed:", error.message); return null; }
  return data.user;
}

export async function currentUserId() {
  if (!supabaseReady) return null;
  const { data: { user } } = await supabase.auth.getUser();
  return user?.id ?? null;
}

// ── TRAVELER ───────────────────────────────────

export async function fetchTraveler() {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("travelers").select("*").eq("id", id).single()
  );
}

// Mirror local journey state up to the database.
export async function syncTraveler({ region, connections, regionCount, displayName }) {
  const id = await currentUserId();
  if (!id) return null;
  const patch = { last_seen_at: new Date().toISOString() };
  if (region !== undefined) patch.region = region;
  if (connections !== undefined) patch.connections = connections;
  if (regionCount !== undefined) patch.region_count = regionCount;
  if (displayName) patch.anon_name = displayName;
  return quiet(() => supabase.from("travelers").update(patch).eq("id", id));
}

// ── ENCOUNTERS ─────────────────────────────────

export async function logEncounter(beingId, region, side) {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("encounters").insert({
      traveler_id: id, being_id: beingId, region, side: side ?? null,
    })
  );
}

// ── PRACTICES ──────────────────────────────────
// Inserting here also pushes the Tide back, via a database trigger.

export async function logPractice(beingId, region) {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("practices").insert({ traveler_id: id, being_id: beingId, region })
  );
}

// ── REFLECTIONS ────────────────────────────────

export async function fetchReflections(beingId, limit = 40) {
  return quiet(
    () => supabase
      .from("reflections")
      .select("id, body, signed_name, created_at")
      .eq("being_id", beingId)
      .eq("hidden", false)
      .order("created_at", { ascending: false })
      .limit(limit),
    []
  );
}

export async function postReflection(beingId, body, signedName) {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("reflections").insert({
      traveler_id: id,
      being_id: beingId,
      body: body.slice(0, 1000),
      signed_name: signedName || null,
    }).select().single()
  );
}

export async function deleteMyReflection(reflectionId) {
  return quiet(() => supabase.from("reflections").delete().eq("id", reflectionId));
}

// ── THE TIDE ───────────────────────────────────

export async function fetchTide() {
  const row = await quiet(() =>
    supabase.from("tide").select("level, updated_at").eq("id", 1).single()
  );
  return row?.level ?? null;
}

// Live updates: the Tide moves as other travelers act.
export function subscribeTide(onChange) {
  if (!supabaseReady) return () => {};
  const channel = supabase
    .channel("tide-changes")
    .on("postgres_changes",
      { event: "UPDATE", schema: "public", table: "tide" },
      payload => onChange(payload.new.level))
    .subscribe();
  return () => supabase.removeChannel(channel);
}

// ── SEND A BEING ───────────────────────────────

export async function createSentBeing(code, beingId, note) {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("sent_beings").insert({
      code, being_id: beingId, sender_id: id, note: note?.slice(0, 200) || null,
    })
  );
}

export async function openSentBeing(code) {
  const id = await currentUserId();
  const row = await quiet(() =>
    supabase.from("sent_beings").select("*").eq("code", code.toUpperCase()).single()
  );
  if (row && id && !row.opened_by) {
    await quiet(() => supabase.from("sent_beings").update({ opened_by: id }).eq("code", row.code));
  }
  return row;
}

// ── KIN ────────────────────────────────────────

export async function createKinBond(code) {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("kin_bonds").insert({ code, traveler_a: id }).select().single()
  );
}

export async function joinKinBond(code) {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("kin_bonds").update({ traveler_b: id })
      .eq("code", code.toUpperCase()).is("traveler_b", null).select().single()
  );
}

export async function fetchKinBond(code) {
  return quiet(() =>
    supabase.from("kin_bonds").select("*").eq("code", code.toUpperCase()).single()
  );
}

// Monday of the current week, as a date string.
export function weekStart(d = new Date()) {
  const day = (d.getDay() + 6) % 7;
  const monday = new Date(d);
  monday.setDate(d.getDate() - day);
  return monday.toISOString().slice(0, 10);
}

export async function answerKin(bondId, beingId, body) {
  const id = await currentUserId();
  if (!id) return null;
  return quiet(() =>
    supabase.from("kin_answers").upsert({
      bond_id: bondId, traveler_id: id, week: weekStart(), being_id: beingId, body,
    }, { onConflict: "bond_id,traveler_id,week" }).select().single()
  );
}

// Both answers are only returned once both people have written.
export async function fetchKinAnswers(bondId) {
  const rows = await quiet(
    () => supabase.from("kin_answers").select("*").eq("bond_id", bondId).eq("week", weekStart()),
    []
  );
  const me = await currentUserId();
  const mine = rows.find(r => r.traveler_id === me) || null;
  const theirs = rows.find(r => r.traveler_id !== me) || null;
  return { mine, theirs: mine && theirs ? theirs : null, bothIn: !!(mine && theirs) };
}
