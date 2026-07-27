---
id: 0009
title: WAF Rules
status: accepted
date: 2026-07-28
supersedes: null
---

# Status

Accepted

# Context

T6 (admin panel discovery and brute force) is cheapest to close before the admin panel has any real Super Admin account to brute-force. Edge-level WAF rules also reduce load on Supabase and Vercel by rejecting obvious bot traffic before it reaches application code, protecting the free-tier quotas tracked in `docs/free-tier-budget.md`.

Cloudflare Free includes 5 custom WAF rules. This phase uses 3, leaving 2 for future phases.

# Decision

## Rule Registry

All three rules are configured in **Cloudflare Dashboard → Security → WAF → Custom Rules** for the `bengaldesk.com` zone.

### Rule 1 — Admin Path Bot Challenge

| Field | Value |
|-------|-------|
| Rule name | `Admin Bot Challenge` |
| Expression | `(http.request.uri.path contains "/admin") and (cf.bot_management.score lt 30)` |
| Action | Managed Challenge |
| Priority | 1 (highest) |
| Status | Active |

**Rationale:** Requests to `/admin/*` from clients with a Cloudflare bot score below 30 are highly likely to be automated scanners or brute-force tools, not legitimate human administrators. The Managed Challenge presents a browser-based proof-of-humanity check (JavaScript challenge, CAPTCHA, etc. — Cloudflare selects the appropriate challenge type). Legitimate users on normal browsers pass transparently; bots fail or are blocked. This directly mitigates T6 by making automated credential-stuffing against `/admin` materially harder before any request reaches the Next.js application.

### Rule 2 — Dashboard Path Bot Challenge

| Field | Value |
|-------|-------|
| Rule name | `Dashboard Bot Challenge` |
| Expression | `(http.request.uri.path contains "/dashboard") and (cf.bot_management.score lt 30)` |
| Action | Managed Challenge |
| Priority | 2 |
| Status | Active |

**Rationale:** Same logic as Rule 1, applied to `/dashboard/*`. Journalists and editors accessing the dashboard are human users on normal browsers who will pass the Managed Challenge transparently. Automated path scanners and credential stuffers targeting `/dashboard` are challenged or blocked. Mitigates T6.

### Rule 3 — Admin/Dashboard Rate Limit

| Field | Value |
|-------|-------|
| Rule name | `Admin/Dashboard Rate Limit` |
| Expression | `(http.request.uri.path contains "/admin") or (http.request.uri.path contains "/dashboard")` |
| Action | Block |
| Rate limit | 30 requests per 1 minute per IP |
| Duration | Block for 10 minutes on exceed |
| Priority | 3 |
| Status | Active |

**Rationale:** Even a human-speed attacker cannot guess 30 credentials in one minute without automation assistance. This hard rate limit catches any traffic that bypasses the bot-score challenge (e.g., a bot with a score above 30, or a human manually testing credentials at speed). The 10-minute block duration is long enough to make brute-force impractical while short enough that a legitimate user who triggers the limit (e.g., rapidly refreshing during a debugging session) regains access quickly. Mitigates T6 as a second layer behind Rules 1–2.

## Configuration Notes

### Bot Score Threshold

The `cf.bot_management.score lt 30` threshold is a starting value. Cloudflare's bot score ranges from 1 (definitely a bot) to 99 (definitely human). A threshold of 30 is conservative — it only challenges clearly bot-like traffic.

This value is **tunable** based on false-positive reports gathered post-launch. Phase 10f's rate-limit audit revisits this number with real traffic data.

### No Country Blocking

Country-based blocking is intentionally not configured in this phase. It is deferred to Part 10, where real traffic data will determine whether it is needed. Unnecessary country blocking risks blocking legitimate readers and journalists accessing via VPNs or proxy services.

### No CAPTCHA Configuration

Cloudflare's Managed Challenge is used instead of a manually-configured CAPTCHA. Managed Challenge automatically selects the appropriate challenge type (JS challenge, interactive CAPTCHA, etc.) based on the traffic signal, requiring no application code.

### Free Tier Headroom

Cloudflare Free includes 5 custom WAF rules. This phase uses 3:

| Rule | Slot Used |
|------|-----------|
| Admin Bot Challenge | 1 of 5 |
| Dashboard Bot Challenge | 2 of 5 |
| Admin/Dashboard Rate Limit | 3 of 5 |
| **Remaining** | **2 of 5** |

If Part 10's launch hardening needs more than 2 additional rules, either consolidate expressions or evaluate Cloudflare's paid WAF tier.

## Keeping This ADR in Sync

Any change to the live Cloudflare WAF rules (threshold adjustment, new rule, disabled rule) must be reflected in this ADR. If the live config drifts from this document, the ADR is stale and must be updated.

# Consequences

- /admin and /dashboard paths have edge-level protection before any real credentials exist.
- Legitimate users on normal browsers pass the Managed Challenge transparently (one-time per session, cookie-based).
- Public routes (/, /articles, etc.) are unaffected — no WAF rules target them in this phase.
- The 2 remaining free-tier rule slots must be budgeted for future phases.
- False-positive handling is documented in `docs/runbooks/waf-false-positive.md`.
- Application-layer rate limiting (Phase 1i, Upstash) is the complementary control — WAF handles edge-level, Upstash handles per-endpoint business logic.
