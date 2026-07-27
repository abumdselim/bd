---
id: 0007
title: Environment Variable Validation
date: 2026-07-28
status: accepted
supersedes: null
---

# Status

Accepted

# Context

Without build-time env validation, a missing SUPABASE_SERVICE_ROLE_KEY in production fails silently at runtime as a cryptic error deep in RLS-protected queries. This phase establishes T3 Env as the single validation layer so every later phase that adds a new env var has a pre-existing pattern to extend.

# Decision

## Validation Mechanism

All environment variables are validated at build time via `@t3-oss/env-nextjs` with Zod schemas defined in `env.mjs` at the project root. The `next.config.js` imports `env.mjs` so validation runs before the build completes.

If any required variable is missing or malformed, the build fails with a T3-Env-formatted error naming the exact variable.

## Server/Client Split

| Variable | Scope | Schema | Owning Phase |
|----------|-------|--------|-------------|
| SUPABASE_SERVICE_ROLE_KEY | Server | `z.string().min(1)` | 1f |
| UPSTASH_REDIS_REST_TOKEN | Server | `z.string().min(1)` | 1i |
| RESEND_API_KEY | Server | `z.string().startsWith("re_")` | 3i / 5d |
| SENTRY_AUTH_TOKEN | Server | `z.string().min(1)` | 10b |
| NEXT_PUBLIC_SUPABASE_URL | Client | `z.string().url()` | 1f |
| NEXT_PUBLIC_SUPABASE_ANON_KEY | Client | `z.string().min(1)` | 1f |
| NEXT_PUBLIC_SENTRY_DSN | Client | `z.string().url()` | 10b |

## Rule

**No code may read `process.env` directly outside `env.mjs`.** Any file needing an env var imports `{ env }` from `@/env.mjs` and reads `env.VARIABLE_NAME`. Direct `process.env` access bypasses Zod validation and is the exact mistake this phase exists to prevent.

When a new phase needs to add an env var, it must:
1. Add the Zod schema entry to `env.mjs` (server or client block)
2. Add the `runtimeEnv` mapping
3. Add the variable to `.env.example`
4. Update this ADR's table

# Consequences

- The build is the gatekeeper: no deployment ships with a missing or malformed secret.
- Adding a new env var requires touching `env.mjs`, `.env.example`, and this ADR — three files, every time.
- Server-only variables are structurally prevented from reaching the client bundle by T3 Env's client/server split.
- The `UPSTASH_REDIS_REST_URL` from Phase 1c's `.env.example` is not in the T3 Env schema because it is a URL with no sensitive component — it can be read directly or added to the schema later when the owning phase (1i) determines whether validation is needed.
- The old `SENTRY_DSN` (without NEXT_PUBLIC_ prefix) from Phase 1c has been replaced by `NEXT_PUBLIC_SENTRY_DSN` since Sentry's client SDK needs browser-accessible DSN.
