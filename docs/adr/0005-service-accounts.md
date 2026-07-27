---
id: 0005
title: Service Accounts
date: 2026-07-28
status: accepted
supersedes: null
---

# Status

Accepted

# Context

Every later phase assumes credentials exist and free-tier ceilings are known quantities, not surprises discovered mid-build. A solo developer without a logged limits table will hit quota walls during testing and lose hours diagnosing what looks like an application bug but is actually a ceiling breach. This phase front-loads that discovery so every subsequent phase's "FREE TIER IMPACT" section has real numbers to subtract from.

All seven service accounts are created under a single project-owner identity (selimabmd@gmail.com) for billing/ownership clarity. 2FA is enabled on every account at creation time — this is a hard requirement, not optional hardening.

# Decision

## Service Account Registry

| Service      | Plan    | 2FA Required | Free Tier Ceiling                                            | Owner Email           | Account Created |
|--------------|---------|--------------|--------------------------------------------------------------|-----------------------|-----------------|
| Cloudflare   | Free    | Yes          | Unlimited bandwidth / 100K Workers requests/day             | selimabmd@gmail.com   | Phase 1b        |
| Supabase     | Free    | Yes          | 500MB DB / 1GB storage / 50MB upload / 500K fn calls/mo     | selimabmd@gmail.com   | Phase 1c        |
| Vercel       | Hobby   | Yes          | 100GB bandwidth/mo / 100 deploys/day                         | selimabmd@gmail.com   | Phase 1c        |
| Upstash      | Free    | Yes          | 10,000 Redis commands/day                                    | selimabmd@gmail.com   | Phase 1c        |
| Resend       | Free    | Yes          | 3,000 emails/mo / 100/day                                    | selimabmd@gmail.com   | Phase 1c        |
| Sentry       | Free    | Yes          | 5,000 errors/mo                                              | selimabmd@gmail.com   | Phase 1c        |
| UptimeRobot  | Free    | Yes          | 50 monitors / 5-min interval                                 | selimabmd@gmail.com   | Phase 1c        |

## UptimeRobot Interval Mismatch

> **Flag for Phase 10d:** UptimeRobot's free tier default interval is **5 minutes**, not the 1-minute interval that Phase 10d's monitoring specification calls for. Resolving this requires either accepting the 5-minute free-tier interval or budgeting for UptimeRobot's paid tier (which unlocks 1-minute checks). This is documented here so it is not a surprise nine parts later.

## 2FA Requirement

2FA is enabled on all seven accounts at creation. This is non-negotiable for a solo developer project because:

- An attacker who phishes a weak password still hits a 2FA wall at the account layer.
- Account compromise is independent of the application's own auth (Part 3) — a breached Cloudflare or Vercel account is game-over regardless of application-level security.
- Passwords are unique per service and stored in a password manager.
- No credentials are shared across services.

**Verification (attested):** Each of the seven dashboards must show 2FA as "Enabled" under account security settings. This is confirmed manually by the developer — QA cannot independently verify dashboard access for a solo project.

## Password Manager

One password manager entry per service. All entries include:
- Service URL
- Email (selimabmd@gmail.com)
- Unique password (not reused across any service)
- 2FA backup codes (stored in the password manager, not in the repo)

Password manager state is external — never tracked in the repository.

# Consequences

- Every phase that touches an external service must update `docs/free-tier-budget.md` with consumption impact.
- `.env.example` lists the shape of every required variable; real values are entered locally and never committed.
- Adding a new service requires a new ADR that updates this registry.
- The UptimeRobot 1-minute interval decision is deferred to Phase 10d with full context available here.
- Cloudflare is listed but was fully configured in Phase 1b — this ADR records it for completeness alongside the other six services.
