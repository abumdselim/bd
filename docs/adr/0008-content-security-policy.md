---
id: 0008
title: Content Security Policy
status: accepted
date: 2026-07-28
supersedes: null
---

# Status

Accepted

# Context

Security headers are cheap to enforce early and expensive to retrofit once third-party scripts (AdSense in Part 9, Firebase Cloud Messaging in Part 8) are integrated and a CSP has to be reverse-engineered from what's already running in production. Writing the CSP now means every later phase that adds a third-party script has a single known file to extend.

# Decision

## CSP Directives

| Directive | Value | Rationale |
|-----------|-------|----------|
| `default-src` | `'self'` | Baseline deny-all for directives not explicitly listed. Any new resource type must be opted in. |
| `script-src` | `'self' 'unsafe-inline' https://va.vercel-scripts.com` | `'unsafe-inline'` is required by Next.js's inline style/script injection in development. `va.vercel-scripts.com` is Vercel's analytics injection endpoint. `'unsafe-eval'` is intentionally absent — no dependency in the constitution's stack requires it. If a future dependency genuinely needs eval, that phase must update this ADR with specific justification. |
| `style-src` | `'self' 'unsafe-inline'` | Required by Tailwind CSS's runtime class generation and Next.js's inline style injection. |
| `img-src` | `'self' data: https://*.supabase.co` | `data:` for inline SVGs/base64 images. `*.supabase.co` for Supabase Storage avatars and uploaded images. |
| `font-src` | `'self' data:` | `data:` for inline font loading (Next.js's font optimization may embed font data). |
| `connect-src` | `'self' https://*.supabase.co wss://*.supabase.co https://va.vercel-scripts.com` | Supabase REST over HTTPS and Realtime subscriptions over WSS. `va.vercel-scripts.com` for Vercel Analytics beacon. |
| `frame-ancestors` | `'none'` | Blocks all iframing of BengalDesk. Belt-and-suspenders with X-Frame-Options: DENY. Mitigates T7 (clickjacking). |
| `base-uri` | `'self'` | Prevents injection of a malicious `<base>` tag that could redirect relative URLs. |
| `form-action` | `'self'` | Forms can only submit to the same origin. Prevents form-hijacking to external endpoints. |
| `object-src` | `'none'` | Blocks `<object>`, `<embed>`, and `<applet>` elements entirely. Reduces T1 (content injection) surface. |

## Additional Security Headers

| Header | Value | Threat Mitigated |
|--------|-------|-----------------|
| `X-Content-Type-Options` | `nosniff` | Prevents MIME-type sniffing (T1 — content injection defense in depth) |
| `X-Frame-Options` | `DENY` | Legacy-browser clickjacking protection (T7); CSP `frame-ancestors` is the modern equivalent |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Prevents leaking full URL paths (including internal dashboard/admin routes) in Referer headers to third-party sites |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Disables camera, microphone, and geolocation APIs — BengalDesk has no legitimate use for these |

## Future CSP Extensions

This section tracks domains that will be added to the CSP by later phases:

| Phase | Domain | Directive | Purpose |
|-------|--------|-----------|---------|
| 8c | Firebase Cloud Messaging endpoints | `connect-src`, `script-src` | Push notification service worker |
| 9b | Google AdSense / DoubleClick | `script-src`, `img-src`, `frame-src` | Ad serving (will require `frame-src` addition) |

> When adding a domain: update this table, update `cspDirectives` in `next.config.mjs`, and mirror the updated CSP in Cloudflare Transform Rules.

## Cloudflare Defense in Depth

The same headers are mirrored at the Cloudflare edge via Transform Rules. This provides:
- Protection even if the Next.js headers() function is bypassed (e.g., a misconfigured rewrite).
- Edge-level enforcement before requests reach the origin.
- Redundancy: if one layer fails, the other still enforces.

Cloudflare configuration is external (not repo-tracked) but must match the `next.config.mjs` header set. Any update to `next.config.mjs` headers requires a corresponding Cloudflare Transform Rules update.

# Consequences

- Every phase that adds a third-party script or resource must update this ADR and the `cspDirectives` object in `next.config.mjs`.
- `'unsafe-eval'` is deliberately excluded. If any dependency requires it, it becomes a blocking issue that must be resolved (find an alternative library, or document the security trade-off in a new ADR).
- `'unsafe-inline'` in `script-src` and `style-src` is a necessary concession to Next.js/Tailwind. Nonce-based CSP is the stricter alternative but requires infrastructure (nonce generation in middleware) that adds complexity without proportional benefit at this project scale.
- CSP violations in browser DevTools console must be zero before a phase is considered complete — if a new dependency causes violations, the CSP must be updated, not the dependency accepted with violations.
- The securityheaders.com target grade is A or A+. Reaching A+ would require adding `report-uri` or `report-to` directives (deferred to Phase 10i at go-live).