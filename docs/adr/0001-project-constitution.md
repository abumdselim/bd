---
id: 0001
title: Project Constitution
status: accepted
date: 2026-07-28
supersedes: null
---

# Status

Accepted

# Context

This document is the single source of truth for all design tokens, performance budgets, and content architecture decisions. Every future phase references this file by path when implementing colors, typography, spacing, breakpoints, or performance constraints. No phase may introduce a token, size, or budget number not listed here without first issuing a superseding ADR.

# Decision

## Identity

- **Project name:** bd
- **Repository:** [abumdselim/bd](https://github.com/abumdselim/bd)
- **Language:** Bangla-primary with English secondary
- **Character set:** UTF-8 (enforced repo-wide via .editorconfig)

## Color System

All 15 design tokens as hex values. Every color reference in application code resolves to one of these tokens.

```
background:       #ffffff
foreground:       #0f172a
primary:          #1a1a2e
primary-foreground: #ffffff
secondary:        #16213e
secondary-foreground: #e2e8f0
accent:           #0f3460
accent-foreground: #ffffff
muted:            #f1f5f9
muted-foreground: #64748b
destructive:      #ef4444
destructive-foreground: #ffffff
border:           #e2e8f0
input:            #e2e8f0
ring:             #0f3460
```

## Typography Scale

All 8 type sizes. Line-height is paired with each step. Font family is system-first: `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Noto Sans Bengali", sans-serif`.

```
xs:    font-size: 0.75rem;   line-height: 1rem;    /* 12px / 16px */
sm:    font-size: 0.875rem;  line-height: 1.25rem;  /* 14px / 20px */
base:  font-size: 1rem;      line-height: 1.5rem;   /* 16px / 24px */
lg:    font-size: 1.125rem;  line-height: 1.75rem;  /* 18px / 28px */
xl:    font-size: 1.25rem;   line-height: 1.75rem;  /* 20px / 28px */
2xl:   font-size: 1.5rem;    line-height: 2rem;     /* 24px / 32px */
3xl:   font-size: 1.875rem;  line-height: 2.25rem;  /* 30px / 36px */
4xl:   font-size: 2.25rem;   line-height: 2.5rem;   /* 36px / 40px */
```

Font weights:

```
normal:  400
medium:  500
semibold: 600
bold:    700
```

## Spacing System

All 11 spacing values. These map directly to Tailwind's default spacing scale.

```
0:   0
1:   0.25rem   /* 4px  */
2:   0.5rem    /* 8px  */
3:   0.75rem   /* 12px */
4:   1rem      /* 16px */
6:   1.5rem    /* 24px */
8:   2rem      /* 32px */
10:  2.5rem    /* 40px */
12:  3rem      /* 48px */
16:  4rem      /* 64px */
20:  5rem      /* 80px */
```

## Breakpoints

All 6 responsive breakpoints. Mobile-first: base styles target < 640px; each breakpoint sets a `min-width` media query.

```
sm:  640px
md:  768px
lg:  1024px
xl:  1280px
2xl: 1536px
3xl: 1920px
```

## Performance Budget

All 10 metrics. Every deployment must pass automated Lighthouse CI against these thresholds. No phase may add a dependency or asset that causes a budget breach without an explicit ADR approving the trade-off.

| # | Metric                          | Budget       | Tool               |
|---|---------------------------------|--------------|--------------------|
| 1 | First Contentful Paint (FCP)    | < 1.2s       | Lighthouse         |
| 2 | Largest Contentful Paint (LCP)  | < 2.5s       | Lighthouse         |
| 3 | First Input Delay (FID)         | < 50ms       | Lighthouse         |
| 4 | Cumulative Layout Shift (CLS)   | < 0.1        | Lighthouse         |
| 5 | Time to Interactive (TTI)       | < 3.0s       | Lighthouse         |
| 6 | Total Blocking Time (TBT)       | < 200ms      | Lighthouse         |
| 7 | JS Bundle Size (initial)        | < 150KB gz   | bundlewatch        |
| 8 | CSS Bundle Size                 | < 30KB gz    | bundlewatch        |
| 9 | Total Page Weight (initial)     | < 500KB      | Lighthouse         |
| 10 | HTTP Requests (initial)         | < 20         | Lighthouse         |

## Content Architecture

Content is organized into two locales: `bn` (Bangla, primary) and `en` (English, secondary). All user-facing strings live in JSON namespace files under a `messages/` directory structure resolved at build time. No hardcoded Bangla or English strings appear in component source.

# Consequences

- Every phase that touches visual output must grep this file for the relevant token before writing CSS or Tailwind classes.
- Performance regressions introduced by any phase are measurable against the 10-metric table above.
- Bangla content safety is guaranteed at the editor level by .editorconfig charset enforcement (ADR side-effect, not a performance concern).
- Adding a new color, size, or breakpoint requires a new ADR that supersedes this one — no ad-hoc additions.