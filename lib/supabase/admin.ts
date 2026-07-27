// DANGER: This client bypasses Row Level Security (RLS) entirely.
//
// Server-only. NEVER import this file from any Client Component or any
// code path that runs in the browser bundle. The service-role key must
// never reach the client — env.mjs enforces this at build time by
// keeping SUPABASE_SERVICE_ROLE_KEY in the server-only block.
//
// Used exclusively for operations the Journalist Approval Constitution
// (Section G) explicitly scopes to a trusted server-side trigger-adjacent
// path. Every call site must be documented in the PR that introduces it.
// If you find an undocumented call site, flag it as a potential T2 violation.

import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { env } from "@/env.mjs";
import type { Database } from "@/types/database.types";

export function createAdminClient() {
  return createSupabaseClient<Database>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}
