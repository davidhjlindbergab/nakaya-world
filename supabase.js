// ───────────────────────────────────────────────
// Supabase client for Nakãya
//
// PASTE YOUR ANON KEY BELOW.
// Find it: Supabase → Project Settings → API → "anon public".
// This key is designed to be public and is safe in app code.
// Never put the "service_role" key here.
// ───────────────────────────────────────────────

import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = "https://fqzfzvlubpfbnimhrgjq.supabase.co";
const SUPABASE_ANON_KEY = "PASTE_YOUR_ANON_KEY_HERE";

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: { persistSession: true, autoRefreshToken: true },
});

// True once a real key is in place. Lets the app run offline until then.
export const supabaseReady = SUPABASE_ANON_KEY !== "PASTE_YOUR_ANON_KEY_HERE";
