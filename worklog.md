# Worklog

---
Task ID: 1
Agent: Main Agent
Task: Phase 1a — Project Constitution as Decision Records

Work Log:
- Created `docs/adr/` directory structure in `/home/z/bd/`
- Created `docs/adr/template.md` with exactly 5 frontmatter fields (id, title, status, date, supersedes)
- Created `docs/adr/0001-project-constitution.md` with: 15 color hex tokens, 8 typography sizes, 11 spacing values, 6 breakpoints, 10 performance budget metrics, content architecture section
- Created `docs/adr/0002-stack-decision.md` with 10 stack choices (Next.js 16, TypeScript 5, Tailwind CSS 4, shadcn/ui, Lucide React, Prisma, SQLite, NextAuth.js v4, Zustand, TanStack Query) each with a rejected alternative and rationale
- Created `docs/adr/0003-security-threat-model.md` with T1-T10 threat table (SQL Injection, XSS, CSRF, Insecure Auth, Insecure Session, Data Exposure, Broken Access Control, Security Misconfiguration, SSRF, Dependency Vulnerabilities), all with Mitigation Status = "Not Started"
- Created `.editorconfig` with `charset = utf-8` under `[*]`, `end_of_line = lf`, `indent_style = space`, `indent_size = 2`
- Created `README.md` with ADR index table and placeholder dev setup
- Ran full verification checklist: all checks passed (15 color tokens, 10 threat rows, charset utf-8, 5 template fields, #1a1a2e present, 8 typography sizes, 11 spacing values, 6 breakpoints, 10 performance metrics)
- Committed as `c019fc9` — push blocked by missing GitHub credentials in sandbox

Stage Summary:
- All 6 Phase 1a deliverables created and verified
- Git commit ready locally at `/home/z/bd/` — user must push manually or provide auth token
- No application code produced (documentation-only phase, as required)

---
Task ID: 2
Agent: Main Agent
Task: Phase 1b — Domain + Cloudflare

Work Log:
- Pushed Phase 1a commit (c019fc9) to GitHub using user-provided PAT
- Created `docs/adr/0004-dns-records.md` with: 5-record DNS table (A, CNAME www, TXT SPF, CNAME DKIM, TXT DMARC), Cloudflare config (SSL Full Strict, HSTS max-age=31536000, DNSSEC two-step), email authentication summary with p=quarantine rationale
- Created `docs/runbooks/dns-rollback.md` with: propagation diagnostic steps, single-record revert via Cloudflare API (Authorization: Bearer $CLOUDFLARE_API_TOKEN), correct API path (api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{id}), emergency unproxy bypass, full decision tree, post-rollback checklist, incident log table
- Verified: 5 frontmatter fields in ADR 0004 (no extras), 5 DNS table rows, p=quarantine (not p=reject), Bearer token with env var, correct API path, unproxy/grey-cloud in runbook
- Committed as `e348a2a` and pushed to GitHub

Stage Summary:
- Phase 1b deliverables committed and pushed to `main`
- DNS records documented as source of truth in ADR 0004
- Rollback runbook ready for operational use
- T8 mitigation tracking: DNSSEC documented, implementation is manual (developer action in dashboards)
- Both Phase 1a and 1b now pushed to https://github.com/abumdselim/bd

---
Task ID: 3
Agent: Main Agent
Task: Phase 1c — Service Accounts

Work Log:
- Created `docs/adr/0005-service-accounts.md` with: 7-service registry table (Cloudflare, Supabase, Vercel, Upstash, Resend, Sentry, UptimeRobot), all with 2FA=Yes, owner email selimabmd@gmail.com, UptimeRobot 1-minute interval mismatch explicitly flagged for Phase 10d
- Created `docs/free-tier-budget.md` with: 7 rows, exact limits from spec, consumed=0 for all, last-updated phase column, update procedure, known limitations section
- Created `.env.example` with: 8 placeholder variables grouped by service (Supabase 3, Upstash 2, Resend 1, Sentry 2), all blank — no real or realistic-looking fake keys
- Created `.gitignore` with `.env` and variants excluded
- Verified: no secrets in git history, .env gitignored, 7 service rows, 7 consumed=0 rows, UptimeRobot 1-minute flag present, no sk_/eyJ patterns in .env.example
- Committed as `3c38e69` and pushed to GitHub

Stage Summary:
- Phase 1c deliverables committed and pushed to `main`
- Free tier budget established as baseline — every future phase decrements against these numbers
- UptimeRobot 5-min vs 1-min decision documented and deferred to Phase 10d
- All three phases (1a, 1b, 1c) pushed to https://github.com/abumdselim/bd

---
Task ID: 4
Agent: Main Agent
Task: Phase 1d — Next.js 14.2.5 Scaffold

Work Log:
- Created `package.json` with exact pinned versions: next 14.2.5, react/react-dom 18.3.1, typescript 5.5.4, tailwindcss 3.4.7, zod 3.23.8, plus dev deps (postcss, autoprefixer, @types, eslint, class-variance-authority, clsx, tailwind-merge, lucide-react)
- Created `tsconfig.json` with strict: true, noUncheckedIndexedAccess: true, @/* path alias
- Created `tailwind.config.ts` with 15 color tokens (primary #1a1a2e, accent, surface, surface-alt, border, text-primary, text-secondary, text-muted, success, warning, danger, dark-bg, dark-surface, dark-border, dark-text), 6 breakpoints (xs:320px through 2xl:1536px), Bangla font stack
- Created `components.json` (shadcn/ui neutral base theme), `postcss.config.js`, `next.config.js`
- Created `app/layout.tsx` — single root layout with `<html lang="bn">` and `<body>`
- Created `app/(public)/layout.tsx` + `page.tsx` — public surface, inherits lang="bn", homepage at /
- Created `app/dashboard/layout.tsx` + `page.tsx` — dashboard surface at /dashboard, lang="en"
- Created `app/admin/layout.tsx` + `page.tsx` — admin surface at /admin, lang="en"
- Created `components/set-lang.tsx` — client component for html lang override (avoids duplicate <html> tags)
- Created `lib/utils.ts` — cn() helper for shadcn/ui pattern
- Created `docs/adr/0006-folder-structure.md` — route group decision, HTML lang strategy, folder tree
- Installed deps with bun, ran `bun run build`: 0 type errors, 87kB first load JS (under 120kB budget)
- Verified: strict mode, noUncheckedIndexedAccess, 15 color tokens, 6 breakpoints, 3 top-level route groups, exactly 1 `<html>` tag, no pages/ directory, tokens present in compiled CSS (as rgb() per Tailwind standard)
- Committed as `e563e4e` and pushed to GitHub

Stage Summary:
- Phase 1d deliverables committed and pushed to `main`
- Scaffold is the performance baseline: 87kB first load JS, all 3 routes statically generated
- Route group separation ready for Phase 3e middleware gating
- Phases 1a through 1d pushed to https://github.com/abumdselim/bd

---
Task ID: 5
Agent: Main Agent
Task: Phase 1e — T3 Env Build-Time Validation

Work Log:
- Installed @t3-oss/env-nextjs@0.10.1 (pinned exact version)
- Created env.mjs at project root with: 4 server vars (SUPABASE_SERVICE_ROLE_KEY, UPSTASH_REDIS_REST_TOKEN, RESEND_API_KEY, SENTRY_AUTH_TOKEN), 3 client vars (NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, NEXT_PUBLIC_SENTRY_DSN), all required (no .optional())
- RESEND_API_KEY validated with z.string().startsWith("re_")
- Renamed next.config.js → next.config.mjs (ESM required for import syntax)
- Updated .env.example to match T3 Env schema with server/client scope documentation
- Created docs/adr/0007-env-validation.md: rule against direct process.env access, table of all vars with scope/schema/owning phase
- Verified all 5 checklist items:
  1. Build fails naming RESEND_API_KEY when set to empty string
  2. Build succeeds (exit 0) with all 7 valid placeholders
  3. Zero direct process.env outside env.mjs
  4. .env is gitignored
  5. Zero server-only secrets in .next/static/ client bundle
- Committed as `5020e1b` and pushed to GitHub

Stage Summary:
- Phase 1e deliverables committed and pushed to `main`
- Build-time validation is the gatekeeper: no deployment ships with missing/malformed secrets
- Note: GitHub Dependabot flagged 36 vulnerabilities in pinned deps — T10 (Dependency Vulnerabilities) owner phase, to be addressed in CI/CD setup
- Phases 1a through 1e pushed to https://github.com/abumdselim/bd

---
Task ID: 6
Agent: Main Agent
Task: Phase 1f — Supabase Client Architecture

Work Log:
- Installed @supabase/ssr@0.5.1 and @supabase/supabase-js@2.45.1 (pinned exact versions)
- Created lib/supabase/server.ts: Server Component client with createServerClient, cookie-reading via next/headers, try/catch on setAll (Server Components can't set cookies)
- Created lib/supabase/client.ts: Browser client with createBrowserClient, anon key only, never touches service-role
- Created lib/supabase/middleware.ts: updateSession() function for middleware session refresh, reusable by Phase 3e
- Created lib/supabase/admin.ts: createAdminClient() using service-role key, DANGER file-level comment, auth: { autoRefreshToken: false, persistSession: false }
- Created types/database.types.ts: Placeholder empty Database type
- Added db:types script to package.json
- Verified all 5 checklist items: 4 files exist, admin unused elsewhere, no deprecated auth-helpers, db:types script present, DANGER comment, no process.env, build exits 0
- Committed as `71a7454` and pushed to GitHub

Stage Summary:
- Phase 1f deliverables committed and pushed to `main`
- Three correctly-scoped clients + one admin client with explicit danger boundary
- T2 structural mitigation: admin client is grep-auditable by distinct name and file isolation
- Build still 87kB (Supabase code tree-shaken since nothing calls it yet)
- Phases 1a through 1f pushed to https://github.com/abumdselim/bd

---
Task ID: 7
Agent: Main Agent
Task: Phase 1g — Security Headers

Work Log:
- Updated next.config.mjs with async headers() function applying to all routes via source: "/(.*)"
- CSP: 9 directives (default-src, script-src, style-src, img-src, font-src, connect-src, frame-ancestors, base-uri, form-action, object-src)
- No unsafe-eval in script-src (intentionally absent per spec)
- wss://*.supabase.co present in connect-src (required for Phase 4h/8g Realtime features)
- 4 additional security headers: X-Content-Type-Options nosniff, X-Frame-Options DENY, Referrer-Policy strict-origin-when-cross-origin, Permissions-Policy camera/mic/geo disabled
- Created docs/adr/0008-content-security-policy.md: directive-by-directive rationale table, future extension table (Phase 8c FCM, 9b AdSense), Cloudflare defense-in-depth notes, A/A+ target grade
- Verified via production server (port 3001): all 5 headers confirmed in HTTP response with correct values
- T7 (clickjacking) mitigated: frame-ancestors 'none' + X-Frame-Options DENY
- T1 (content injection) mitigated: CSP script-src restriction + object-src 'none'
- Committed as `2067986` and pushed to GitHub

Stage Summary:
- Phase 1g deliverables committed and pushed to `main`
- Full CSP and security header set ready — later phases extend via ADR 0008
- securityheaders.com manual verification deferred to deployed preview URL
- Cloudflare Transform Rules must mirror these headers (external config, documented in ADR 0008)
- Phases 1a through 1g pushed to https://github.com/abumdselim/bd

---
Task ID: 8
Agent: Main Agent
Task: Phase 1h — Cloudflare WAF

Work Log:
- Created docs/adr/0009-waf-rules.md with 3 WAF rules:
  Rule 1: Admin Bot Challenge (cf.bot_management.score lt 30 → Managed Challenge)
  Rule 2: Dashboard Bot Challenge (cf.bot_management.score lt 30 → Managed Challenge)
  Rule 3: Admin/Dashboard Rate Limit (30 req/min per IP → Block 10 min)
- Bot score threshold documented as tunable (Phase 10f revisits with real traffic data)
- Free tier headroom: 3 of 5 custom rules used, 2 remaining
- Country blocking explicitly excluded (deferred to Part 10)
- Created docs/runbooks/waf-false-positive.md: 5-step diagnosis runbook with incident log
- Verified: correct Cloudflare expression syntax, no country blocking, T6 referenced 4 times, public routes unaffected
- Committed as `e3a1254` and pushed to GitHub

Stage Summary:
- Phase 1h deliverables committed and pushed to `main`
- T6 mitigation active at edge before any real admin credentials exist
- WAF rules documented for manual Cloudflare dashboard configuration by developer
- Phases 1a through 1h pushed to https://github.com/abumdselim/bd

---
Task ID: 9
Agent: Main Agent
Task: Phase 1i — Upstash Rate Limiting Middleware

Work Log:
- Installed @upstash/ratelimit@2.0.1 and @upstash/redis@1.34.3 (pinned)
- Added UPSTASH_REDIS_REST_URL to env.mjs (z.string().url()) and .env.example (Phase 1e deferred it)
- Created lib/rate-limit.ts: 3 sliding-window policies with distinct Redis key prefixes (rl:login, rl:public, rl:submit)
- Created lib/api-error.ts: ApiError interface, RateLimitErrorResponse with retryAfter, rateLimitError() factory
- Created middleware.ts: root middleware with x-forwarded-for IP extraction (127.0.0.1 fallback), 429 JSON response with Retry-After header, config.matcher scoped to /api/auth/* and /api/public/*
- Created docs/adr/0010-rate-limit-policy.md: per-route limits table, Upstash free tier budget projection (70% at 3K daily requests), extension procedure
- Fixed literal \n in comment that caused `response` variable to be inside comment text
- Verified: slidingWindow (not fixedWindow), distinct prefixes, Retry-After, no process.env, no fixedWindow, build exits 0 (middleware: 91kB server-only)
- Committed as `a7ec5b0` and pushed to GitHub

Stage Summary:
- Phase 1i deliverables committed and pushed to `main`
- T3 (credential stuffing) and T5 (scraper quota) mitigated at application layer
- 429 response shape is the contract for all future API errors (Section E)
- Middleware matches /api/auth/* and /api/public/* — no impact on public page routes
- Phases 1a through 1i pushed to https://github.com/abumdselim/bd

---
Task ID: 10
Agent: Main Agent
Task: Phase 1j — Git + CI

Work Log:
- Created .github/workflows/ci.yml: lint + type-check + build on PRs to main, dummy env vars (RESEND_API_KEY=re_ prefix, valid https:// URLs for .url() schemas), npm ci for lockfile-exact installs
- Updated package.json: lint now uses --max-warnings=0, added type-check (tsc --noEmit), format (prettier --write), prepare (husky) scripts
- Created .eslintrc.json extending next/core-web-vitals
- Installed husky@9.1.6, lint-staged@15.2.10, prettier@3.3.3 as dev deps (pinned)
- Created .husky/pre-commit (Husky v9 file-based, executable): runs npx lint-staged
- Created .lintstagedrc.json: eslint --fix + prettier --write on .ts/.tsx, prettier --write on .json/.md
- Created .prettierignore: node_modules, .next, dist, lock files
- Created docs/adr/0011-branch-protection.md: 7-rule branch protection table, CI steps, local hooks, Vercel deployment config
- Verified: lint (0 warnings), type-check (0 errors), build (exit 0) — all pass with CI dummy env vars
- All 7 checks passed: re_ prefix in CI, --max-warnings=0, prepare script, Husky v9 file-based, no .huskyrc, lint-staged config, npm ci
- Committed as c634637 and pushed to GitHub

Stage Summary:
- Phase 1j deliverables committed and pushed to main
- Part 1 complete: Phases 1a through 1j all pushed to https://github.com/abumdselim/bd
- No commit reaches main without passing lint + type-check + build
- Branch protection must be configured manually in GitHub repo settings (documented in ADR 0011)
- T10 indirect support: npm ci enforces lockfile-exact deps, preventing supply-chain drift

---
Task ID: 11
Agent: Main Agent
Task: Phase 2a — Articles Table (Supabase Migration)

Work Log:
- Created `supabase/migrations/0001_articles.sql`: article_status enum (5 values), articles table (26 columns), 3 CHECK constraints (breaking_requires_ticker, rejected_requires_reason, scheduled_requires_time), 5 indexes (status, category, author, published_at partial, slug), set_updated_at() trigger, RLS enabled with zero policies
- Created `docs/adr/0012-articles-schema.md`: column-by-column rationale table, JSONB body decision, deny-by-default RLS rationale, 5-index coverage map, Bangla/Unicode handling note
- Verified: no RLS policies in migration file, body is jsonb (not text), no pgcrypto/CREATE EXTENSION, no stub table definitions for profiles/categories/media
- Note: migration depends on profiles (2b), categories (2c), media (2e) — deploy order interleaved by filename numbering

Stage Summary:
- Phase 2a deliverables created (not yet committed/pushed — awaiting dependent phases 2b/2c/2e)
- articles table schema is locked: 26 columns, 3 constraints, 5 indexes, RLS deny-by-default
- body is JSONB (Tiptap native format) — contractual for Phase 4c editor and 6c renderer
- article_status enum (draft/pending/published/rejected/scheduled) — contractual for all editorial workflow phases