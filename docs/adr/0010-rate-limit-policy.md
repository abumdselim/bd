---
id: 0010
title: Rate Limit Policy
status: accepted
date: 2026-07-28
supersedes: null
---

# Status

Accepted

# Context

This is the application-layer complement to Phase 1h's edge-layer WAF. Cloudflare's WAF protects /admin and /dashboard paths at the network edge, but Upstash rate limiting protects individual API routes (search, article submission, login attempts) at the application layer with route-specific granularity the WAF can't express.

# Decision

## Per-Route-Category Limits

| Policy | Key Prefix | Limit | Window | Owning Phase | Threat Mitigated |
|--------|-----------|-------|--------|-------------|-----------------|
| `login` | `rl:login` | 5 requests | 60 seconds (sliding) | 3b | T3 (credential stuffing) |
| `publicRead` | `rl:public` | 60 requests | 60 seconds (sliding) | 6a | T5 (scraper quota exhaustion) |
| `articleSubmit` | `rl:submit` | 10 requests | 60 seconds (sliding) | 4c | T5 (abusive submissions) |

## Implementation

- **Library:** `@upstash/ratelimit` with `Ratelimit.slidingWindow()` — no `fixedWindow` (fixed windows allow a burst at the boundary)
- **Storage:** Upstash Redis (REST API, no persistent TCP connection)
- **Scope:** Per-IP (per-user rate limiting requires auth, deferred to Part 3)
- **Middleware:** Root `middleware.ts` matches `/api/auth/:path*` and `/api/public/:path*`
- **Response:** 429 JSON with `{ error, code }` and `Retry-After` header

## Adding a New Rate-Limited Route

1. If the new route fits an existing policy, add its path prefix to `pathPolicyMap` in `middleware.ts`
2. If it needs a new limit, add a new policy to `rateLimitPolicies` in `lib/rate-limit.ts` with a distinct prefix
3. Add the policy to this ADR's table above
4. Wire the path in `middleware.ts`'s `pathPolicyMap`

## Upstash Free Tier Budget Impact

Each `checkRateLimit()` call consumes ~2–3 Redis commands (sliding window read + write).

| Scenario | Daily Requests | Redis Commands | % of 10K Daily Limit |
|----------|---------------|----------------|----------------------|
| Rate limiting alone | ~1,000 | ~2,500 | 25% |
| + Phase 6j trending cache | ~1,500 | ~4,000 | 40% |
| + Phase 8b/8j view counter | ~3,000 | ~7,000 | 70% |

If daily Redis commands approach 8,000+, the project needs either Upstash paid tier or an alternative caching strategy. This is flagged for Phase 10f's audit.

# Consequences

- Every future API route that needs rate limiting imports from `lib/rate-limit.ts` and `lib/api-error.ts` — no per-phase reinvention.
- The 429 response shape (`{ error, code, statusCode, retryAfter }`) is the contract for all API error responses (constitution Section E).
- `UPSTASH_REDIS_REST_URL` was added to `env.mjs` in this phase (deferred from Phase 1e's ADR 0007).
- Middleware's `config.matcher` must be updated when new rate-limited path patterns are added.
- Local development shares a single rate-limit bucket (IP fallback is `127.0.0.1`) — acceptable for dev.
