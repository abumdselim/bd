---
id: '0014'
title: 'Category Taxonomy — Exactly 9 at Launch'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0014: Category Taxonomy

## Context

Section D of the constitution fixes exactly 9 top-level categories at launch. This decision becomes data in Phase 2c. A wrong number, wrong order, or corrupted Bangla name propagates to every consumer: the homepage category rows (6a), the article metadata form (4e), the category page (6d), and the article-count badges — all of which query this table.

## Decision

### The 9 launch categories

| Position | Name (Bangla) | Slug | English gloss |
|---|---|---|---|
| 1 | রাজনীতি | `rajniti` | Politics |
| 2 | অর্থনীতি | `arthaniti` | Economy |
| 3 | আন্তর্জাতিক | `antorjatik` | International |
| 4 | খেলাধুলা | `kheladhula` | Sports |
| 5 | প্রযুক্তি | `projukti` | Technology |
| 6 | বিনোদন | `binodhan` | Entertainment |
| 7 | শিক্ষা | `shikkha` | Education |
| 8 | স্বাস্থ্য | `swasthya` | Health |
| 9 | চট্টগ্রাম | `chittagong` | Chittagong (regional) |

### Why 9, not more or fewer

- **9 is sufficient** for launch coverage of Bangladesh's major news beats.
- **9 is not too many** for the homepage category row (6a) to display without horizontal scrolling on mobile.
- **Chittagong is the sole regional category** — the constitution explicitly includes one regional category as a proof-of-concept for future geographic expansion.

### Self-referencing parent_id (not a separate subcategories table)

A single `categories` table with a nullable `parent_id` referencing itself:

1. **One query** serves both levels — `parent_id IS NULL` for top-level, `parent_id = ?` for subcategories.
2. **One RLS policy** covers both levels (Phase 2i).
3. **One admin UI** (Phase 5i) manages both levels.

The `no_self_parent` CHECK constraint (`id != parent_id`) prevents a data-integrity mistake where a category references itself.

### No category icon/image field

Section B of the constitution specifies editorial clarity with no decorative iconography. Category pages and the homepage use the Bangla name as the sole visual identifier.

### Post-launch: adding a 10th category

Adding a category after launch is **not** a simple database INSERT. The process is:

1. Create an ADR proposing the new category with rationale (name, slug, position).
2. Update this ADR (0014) with `supersedes: ''` → the new ADR's ID.
3. The new ADR must specify the position number and confirm the homepage category row still fits without horizontal scroll on the smallest supported viewport (xs: 320px).
4. Only after the ADR is accepted does a migration add the seed row.

This process prevents Section D's "exactly 9" rule from silently drifting.

## Consequences

- **Positive**: The taxonomy is locked at launch — no ad-hoc category creation.
- **Positive**: Single-table design simplifies every consumer query.
- **Positive**: `no_self_parent` constraint costs nothing and prevents a subtle data-integrity bug.
- **Trade-off**: Adding a category post-launch requires an ADR — this is deliberate friction to prevent taxonomy bloat.
- **Trade-off**: Self-referencing FK means a `DELETE CASCADE` on a parent category would delete all its subcategories — this is acceptable because category deletion should be a rare, deliberate action performed by a super_admin.
