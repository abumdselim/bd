---
id: 0002
title: Stack Decision
status: accepted
date: 2026-07-28
supersedes: null
---

# Status

Accepted

# Context

The project requires a modern, type-safe full-stack framework capable of server-side rendering, API routes, and static generation. The stack must support Bangla (UTF-8) natively, run within free-tier infrastructure limits, and remain maintainable by a solo developer across 100+ incremental phases. Each choice below was evaluated against ecosystem maturity, bundle size impact on the performance budget (ADR 0001), and long-term solo-developer ergonomics.

# Decision

## Framework: Next.js 16 (App Router)

- **Chosen:** Next.js 16 with App Router
- **Rejected:** Remix
- **Rationale:** Next.js 16 provides the widest ecosystem of middleware, deployment targets, and community examples. Remix's loader/action pattern is elegant but its ecosystem is smaller, fewer deployment platforms offer zero-config support, and the App Router's server-components model aligns with the performance budget (reduced client JS). Remix was rejected because migrating from its convention to a custom setup adds friction the solo developer cannot afford at phase 50+.

## Language: TypeScript 5

- **Chosen:** TypeScript 5 (strict mode)
- **Rejected:** JavaScript (ES2022+)
- **Rationale:** TypeScript's static analysis catches prop-type mismatches and API shape drift before runtime — critical when a solo developer cannot manually regression-test every endpoint after each phase. JavaScript was rejected because the lack of type contracts between API routes and frontend consumers would cause silent breakages that compound across 100 phases.

## Styling: Tailwind CSS 4

- **Chosen:** Tailwind CSS 4
- **Rejected:** CSS Modules
- **Rationale:** Tailwind's utility-first approach produces smaller CSS bundles (meeting the 30KB gz budget) by purging unused classes. CSS Modules were rejected because they generate scoped class names that bloat HTML, make responsiveness harder to scan visually (no utility classes in markup), and provide no design-token constraint mechanism equivalent to tailwind.config.ts.

## UI Component Library: shadcn/ui (New York style)

- **Chosen:** shadcn/ui
- **Rejected:** Material UI (MUI)
- **Rationale:** shadcn/ui copies component source into the project, giving full control over markup and styling — no vendor lock-in, no black-box overrides. MUI was rejected because its opinionated design system conflicts with the project's custom color tokens (ADR 0001), its bundle size exceeds the JS budget even with tree-shaking, and theming MUI to match non-Material aesthetics requires fighting the library.

## Icons: Lucide React

- **Chosen:** Lucide React
- **Rejected:** Heroicons
- **Rationale:** Lucide provides a larger icon set (1400+ vs ~280), consistent 24px default sizing, and lighter per-icon bundle weight through modular imports. Heroicons was rejected because its smaller catalog would require fallback SVGs for missing icons, breaking visual consistency.

## Database ORM: Prisma

- **Chosen:** Prisma ORM
- **Rejected:** Drizzle ORM
- **Rationale:** Prisma's migration tooling (prisma migrate, prisma db push) and type-safe client generation reduce boilerplate for schema evolution across phases. Drizzle was rejected because its migration system is less mature, and its SQL-like API offers no ergonomic advantage for a solo developer who benefits more from Prisma's declarative schema and auto-generated types.

## Database: SQLite

- **Chosen:** SQLite (via Prisma)
- **Rejected:** PostgreSQL
- **Rationale:** SQLite requires zero external services, runs within the free-tier process boundary, and provides sufficient performance for a solo-developer project. PostgreSQL was rejected because it requires a separate database server (or managed service), introduces network latency, and consumes free-tier resources that are better allocated to the application process.

## Authentication: NextAuth.js v4

- **Chosen:** NextAuth.js v4
- **Rejected:** Supabase Auth
- **Rationale:** NextAuth.js integrates natively with Next.js API routes, supports multiple providers, and keeps authentication logic in-repo. Supabase Auth was rejected because it creates vendor lock-in to Supabase's ecosystem, requires an external service, and limits custom session handling compared to NextAuth's callback architecture.

## Client State: Zustand

- **Chosen:** Zustand
- **Rejected:** Redux Toolkit
- **Rationale:** Zustand's minimal API (create a store with a function call) eliminates boilerplate for simple UI state like modals, filters, and form drafts. Redux Toolkit was rejected because its action/reducer/dispatch ceremony is disproportionate to the project's state complexity, and the middleware/slice architecture adds cognitive load without corresponding benefit at this scale.

## Server State: TanStack Query

- **Chosen:** TanStack Query (React Query)
- **Rejected:** SWR
- **Rationale:** TanStack Query provides richer caching strategies (stale-while-revalidate, cache invalidation by query key), optimistic updates, and mutation lifecycle hooks. SWR was rejected because its simpler API lacks built-in mutation revalidation patterns and its caching is less configurable, which would require hand-rolled workarounds as data complexity grows in later phases.

## Caching: Local Memory

- **Chosen:** In-process Map-based caching (no external cache)
- **Rejected:** Redis
- **Rationale:** For a single-instance deployment, an in-process LRU cache avoids network round-trips and external service dependencies. Redis was rejected because it requires a separate process, adds operational complexity, and is unnecessary when the application runs as a single Node.js instance within free-tier constraints.

# Consequences

- All stack choices are locked. Switching any dependency requires a new ADR that supersedes this one.
- Bundle size impact of each choice is bounded by ADR 0001's performance budget — any dependency update that breaches the JS (150KB gz) or CSS (30KB gz) budget must be flagged.
- The SQLite choice means no horizontal database scaling; if the project outgrows single-instance capacity, a migration ADR will be required.
- shadcn/ui's copy-paste model means component updates are manual — the project owns its component code, which is intentional for control but requires discipline to keep components current.
- NextAuth.js v4 may require migration to v5 (Auth.js) in a future phase — that migration is tracked as a standalone ADR when the time comes.