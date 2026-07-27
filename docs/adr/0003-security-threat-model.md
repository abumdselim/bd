---
id: 0003
title: Security Threat Model
status: accepted
date: 2026-07-28
supersedes: null
---

# Status

Accepted

# Context

This threat model identifies the top 10 security threats relevant to the project. Each threat is assigned an owner phase responsible for implementing its mitigation. This table is the tracking mechanism — it does not implement mitigations itself. At project initiation, no phase has run, so all mitigation statuses are "Not Started."

The threat landscape accounts for: a Next.js 16 application with API routes, SQLite database via Prisma, NextAuth.js v4 authentication, user-uploaded content, and Bangla/English bilingual input. The application targets free-tier infrastructure, which constrains available mitigations (e.g., no WAF, no dedicated security appliance).

# Decision

## Threat Table

| ID  | Threat                                | Owner Phase | Mitigation Status |
|-----|---------------------------------------|-------------|-------------------|
| T1  | SQL Injection                         | Phase 3a    | Not Started       |
| T2  | Cross-Site Scripting (XSS)            | Phase 3b    | Not Started       |
| T3  | Cross-Site Request Forgery (CSRF)     | Phase 3c    | Not Started       |
| T4  | Insecure Authentication               | Phase 4a    | Not Started       |
| T5  | Insecure Session Management           | Phase 4b    | Not Started       |
| T6  | Sensitive Data Exposure               | Phase 5a    | Not Started       |
| T7  | Broken Access Control                 | Phase 5b    | Not Started       |
| T8  | Security Misconfiguration             | Phase 5c    | Not Started       |
| T9  | Server-Side Request Forgery (SSRF)    | Phase 6a    | Not Started       |
| T10 | Dependency Vulnerabilities            | Phase 1j    | Not Started       |

## Threat Descriptions

### T1: SQL Injection
Adversary injects malicious SQL via user input fields, API parameters, or URL paths to read, modify, or delete database contents. Prisma's parameterized queries provide baseline protection, but raw query usage or dynamic table/column names can reintroduce the vector.

### T2: Cross-Site Scripting (XSS)
Adversary injects client-side scripts into pages viewed by other users. React's JSX escaping mitigates stored XSS, but `dangerouslySetInnerHTML`, user-generated markdown/HTML rendering, and improper URL handling can bypass this protection. Bangla content with mixed script is not inherently more vulnerable but must be tested for encoding edge cases.

### T3: Cross-Site Request Forgery (CSRF)
Adversary tricks an authenticated user into executing unwanted actions. Next.js API routes with same-site cookie auth and NextAuth's CSRF tokens provide baseline protection, but state-changing endpoints without token validation are vulnerable.

### T4: Insecure Authentication
Weak password policies, missing rate limiting on auth endpoints, or improper credential storage enable account takeover. NextAuth.js handles much of this, but configuration gaps (e.g., missing session expiry, no brute-force protection) create exposure.

### T5: Insecure Session Management
Session tokens that are not rotated, lack secure/httponly/samesite flags, or are transmitted over unencrypted channels enable session hijacking. JWT configuration and cookie policy in NextAuth.js must be audited.

### T6: Sensitive Data Exposure
API responses leaking user emails, internal IDs, or database schema details. Bangla content stored in the database must not expose user PII in error messages or API responses.

### T7: Broken Access Control
Users accessing resources or performing actions beyond their authorization level. Every API route must verify the authenticated user's permissions before returning data or mutating state.

### T8: Security Misconfiguration
Exposed debug endpoints, verbose error messages revealing stack traces, missing security headers (CSP, X-Frame-Options, HSTS), or default credentials. Next.js and Caddy configuration must be hardened.

### T9: Server-Side Request Forgery (SSRF)
Adversary tricks the server into making requests to internal services or external targets. Relevant when the application fetches external URLs (e.g., web reader, image proxy) based on user input.

### T10: Dependency Vulnerabilities
Known CVEs in npm packages, Prisma, Next.js, or Node.js runtime. Mitigated through automated dependency auditing in CI/CD and timely updates.

# Consequences

- No mitigation is implemented by this phase — this ADR creates the tracking mechanism only.
- Each owner phase is responsible for updating its threat's Mitigation Status from "Not Started" to "Implemented" upon completion, and referencing this ADR by path.
- New threats discovered after this ADR is accepted require a new ADR that supersedes this one — no row additions to the T1–T10 table are permitted without a superseding ADR.
- The owner phase assignments are tentative and may be adjusted in future ADRs if phase ordering changes.