import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { env } from "@/env.mjs";
import type { Database } from "@/types/database.types";

export function createClient() {
  const cookieStore = cookies();

  return createServerClient<Database>(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Called from a Server Component — safe to ignore.
            // Server Components cannot set cookies; only
            // Server Actions and Route Handlers can.
            // Middleware refresh handles session persistence.
          }
        },
      },
    }
  );
}
