# Free Tier Budget

> Living document tracking free-tier consumption across all external services.
> Updated by every phase that touches an external service.
> Last full audit: Phase 1c (initial creation).

## Service Limits & Consumption

| Service     | Free Tier Limit                                                  | Consumed So Far | Last Updated Phase | Notes                                          |
|-------------|------------------------------------------------------------------|-----------------|--------------------|------------------------------------------------|
| Cloudflare  | Unlimited bandwidth / 100K Workers requests/day                 | 0                | Phase 1b           | DNS + proxy only until Phase 1h (WAF)          |
| Supabase    | 500MB DB / 1GB storage / 50MB upload / 500K fn calls/mo        | 0                | Phase 1c           | No schema created yet (Part 2)                 |
| Vercel      | 100GB bandwidth/mo / 100 deploys/day                            | 0                | Phase 1c           | No deployment yet (Phase 1d)                   |
| Upstash     | 10,000 Redis commands/day                                       | 0                | Phase 1c           | Not wired yet (Phase 1i)                       |
| Resend      | 3,000 emails/mo / 100/day                                       | 0                | Phase 1c           | DNS auth records ready (Phase 1b); no sends yet |
| Sentry      | 5,000 errors/mo                                                 | 0                | Phase 1c           | SDK not wired yet (Phase 10b)                  |
| UptimeRobot | 50 monitors / 5-min interval                                    | 0                | Phase 1c           | 1-minute interval needs paid tier — see ADR 0005 |

## How to Update This Table

1. After completing a phase that touches an external service, calculate the new consumption for that service.
2. Update the "Consumed So Far" column with the new value.
3. Set "Last Updated Phase" to the phase number that caused the change.
4. Add a note explaining what consumed the quota.
5. If any service exceeds 80% of its limit, add a `⚠️` emoji to the Notes column and flag it in the phase's FREE TIER IMPACT section.

## Known Limitations

- **UptimeRobot 1-minute interval:** Free tier supports 5-minute intervals only. Phase 10d must decide: accept 5-min or upgrade to paid. See [ADR 0005](adr/0005-service-accounts.md) for full context.
- **Resend 100/day cap:** Daily limit is 100 emails even though monthly limit is 3,000. Batch sends must account for this daily ceiling.
- **Supabase 50MB upload:** File uploads via Supabase Storage are capped at 50MB per file on the free tier.
