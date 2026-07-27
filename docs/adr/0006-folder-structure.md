---
id: 0006
title: Folder Structure
date: 2026-07-28
status: accepted
supersedes: null
---

# Status

Accepted

# Context

Every phase in Parts 4 through 9 needs the correct route-group separation to work. If (public), dashboard, and admin are not physically separate route groups at the top level of app/, then Phase 3e's middleware matrix cannot gate them independently, Phase 4a's dashboard shell bleeds into public pages, and admin role checks have no route-level boundary to attach to.

The alternative considered was a single layout with client-side role switching. This was rejected because it means all three surfaces ship JavaScript for all three roles to every visitor — a performance and security anti-pattern.

# Decision

## Route Groups

Three top-level route groups under `app/`, each with its own layout:

- **(public)** — Route group (parenthesized, does not appear in URL). The homepage `/` maps here. No auth required. Language: Bangla (`lang="bn"`).
- **dashboard** — Route segment (appears in URL as `/dashboard`). Auth required (middleware added in Phase 3e). Language: English (`lang="en"`).
- **admin** — Route segment (appears in URL as `/admin`). Auth + super-admin role required (Phase 3e). Language: English (`lang="en"`).

## Folder Tree

```
app/
  layout.tsx              # Root layout — owns <html> and <body>
  globals.css             # Tailwind directives
  (public)/
    layout.tsx            # Public shell (inherits lang="bn" from root)
    page.tsx              # Homepage → /
  dashboard/
    layout.tsx            # Journalist/editor shell (overrides lang="en")
    page.tsx              # Dashboard → /dashboard
  admin/
    layout.tsx            # Super admin shell (overrides lang="en")
    page.tsx              # Admin → /admin
  api/                    # Route handlers (added per-phase)
components/
  set-lang.tsx            # Client component for <html lang> override
  ui/                     # shadcn/ui components (added per-phase)
lib/
  utils.ts                # cn() helper (shadcn/ui pattern)
docs/
  adr/
  runbooks/
  free-tier-budget.md
```

## HTML Lang Strategy

Next.js App Router requires exactly one `<html>` tag in the render tree. The root `app/layout.tsx` owns it with `lang="bn"` as the default (Bangla-primary project).

The dashboard and admin layouts override the lang attribute to `"en"` using a client component (`components/set-lang.tsx`) that calls `document.documentElement.lang = lang` in a `useEffect`. This avoids duplicating `<html>` tags (which would cause a build error) while correctly setting the language per surface.

The (public) layout does not override — it inherits `lang="bn"` from root.

## Route Group vs Route Segment

`(public)` uses parentheses because it must NOT appear in the URL — the homepage is `/`, not `/(public)`. The `dashboard` and `admin` groups are NOT parenthesized because their URL paths (`/dashboard`, `/admin`) are meaningful identifiers that users and middleware reference.

# Consequences

- Phase 3e's middleware can gate `/dashboard/*` and `/admin/*` independently from `/*` (public routes).
- Adding a new surface (e.g., `/api-studio`) requires a new route group at the same level — not nested inside an existing one.
- The `set-lang.tsx` component is a client component, so dashboard/admin pages lose pure-server-rendering of the lang attribute. The visual flash is imperceptible (the attribute changes before first paint in practice) but the trade-off is documented.
- No `pages/` directory exists — this project uses App Router exclusively. Any file referencing `getServerSideProps` or `_app.tsx` is a mistake.