/* ======================================================================
   Bridge to China — Supabase connection
   ======================================================================
   This is the ONLY file you need to edit to turn on real accounts.

   1. Go to https://supabase.com and create a free project.
   2. In your project: Settings → API.
   3. Copy "Project URL" and paste it below as SUPABASE_URL.
   4. Copy the "anon public" key and paste it below as SUPABASE_ANON_KEY.
      (This key is MEANT to be public / visible in website code — it only
      allows what your Row Level Security rules permit, which is why the
      schema file restricts every volunteer to their own row.)
   5. In Supabase: SQL Editor → paste the contents of supabase-schema.sql
      → Run. This creates the profiles table.
   6. (Recommended for now) Authentication → Providers → Email →
      turn OFF "Confirm email", so new volunteers can log in immediately
      without waiting on a confirmation email. You can turn this back on
      later once you've set up a "from" email address.

   Every page loads this file, so
   you only ever update your keys in one place.
   ====================================================================== */

const SUPABASE_URL = "YOUR_SUPABASE_PROJECT_URL";      // e.g. "https://abcdxyz.supabase.co"
const SUPABASE_ANON_KEY = "YOUR_SUPABASE_ANON_KEY";     // the long "anon public" key

const isConfigured = SUPABASE_URL.startsWith("https://") && SUPABASE_ANON_KEY.length > 20;

let supabaseClient = null;
if (isConfigured) {
  supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}
