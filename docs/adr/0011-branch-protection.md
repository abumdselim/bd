---
id: 0011
title: Branch Protection and CI
status: accepted
date: 2026-07-28
supersedes: null
---

# Status

Accepted

# Context
This is the last Part 1 phase because it depends on everything before it existing (scaffold, env validation, headers) to have something meaningful to lint and type-check. For a solo developer, branch protection and CI are not bureaucracy — they are the only thing standing between a late-night change with a subtle type error and that change reaching production directly.

# Decision

## Branch Protection Rules (GitHub Repo Settings)

| Rule | Setting |
|------|--------|
| Require a pull request before merging | Enabled |
| Require approvals | Not required (solo project) |
| Require status checks to pass before merging | Enabled — `lint-and-typecheck` |
| Require branches to be up to date before merging | Enabled |
| Require signed commits | Not required (no GPG key setup at this stage) |
| Do not allow force pushes | Enabled |
| Do not allow deletions | Enabled |

## GitHub Actions CI Workflow

File: `.github/workflows/ci.yml`

Triggered on: Pull requests targeting `main`

Steps:
1. `actions/checkout@v4`
2. `actions/setup-node@v4` with Node 20, npm cache
3. `npm ci` (lockfile-exact install)
4. `npm run lint` (ESLint with `--max-warnings=0`)
5. `npm run type-check` (`tsc --noEmit`)
6. `npm run build` (Next.js production build with T3 Env validation)

CI uses dummy environment variables that pass Zod schema validation but do not connect to any real service. Real secrets are never needed for lint/type-check/build.

## Local Pre-Commit Hook

Husky v9 + lint-staged runs on every `git commit`:

| File type | Actions |
|-----------|---------|
| `*.{ts,tsx}` | `eslint --fix` then `prettier --write` |
| `*.{json,md}` | `prettier --write` |

The `prepare` script (`"prepare": "husky"`) runs automatically on `npm install` / `bun install`, ensuring hooks are active on fresh clones.

## Vercel Deployment

| Setting | Value |
|---------|-------|
| Production branch | `main` |
| Preview deploys | Enabled for every PR |
| Preview URL | Vercel bot comments on each PR |
| Production deploy | Automatic on merge to `main` |

# Consequences

- No commit reaches `main` without passing lint, type-check, and build.
- `--max-warnings=0` is intentional — any ESLint warning blocks CI.
- `npm ci` in CI (not `npm install`) ensures lockfile-exact dependency resolution.
- Dummy env vars in CI mean the build step validates Zod schema structure, not live connectivity.
- Husky's `prepare` script auto-installs git hooks on fresh clones — no manual setup needed.
- Bangla string literals in future phases must not trigger ESLint encoding errors — Prettier handles UTF-8 by default, and ESLint's default config does not flag non-ASCII.
- E2E test CI wiring is deferred to Part 3 (Playwright) — only added to this workflow then.
