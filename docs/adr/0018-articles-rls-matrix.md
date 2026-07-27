---
id: '0018'
title: 'Articles RLS Access Matrix'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0018: Articles RLS Access Matrix

## Context

Section G states: "RLS on articles is the actual security boundary — never the API layer alone." This phase replaces Phase 2a's deny-by-default (zero policies) state with the complete, gap-free access model that every dashboard phase (Part 4, 5) assumes before writing any query.

## Decision

### Access Matrix

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| **anon (public)** | Published articles only | None | None | None |
| **contributor** | Own articles (any status) | Own, `status='draft'` only | Own, only while `status IN ('draft','pending','rejected')` | Own, only while `status='draft'` |
| **journalist** | Own articles (any status) + published articles (any author) | Own, `status='draft'` only | Own, only while `status IN ('draft','pending','rejected')` | None |
| **editor** | All articles (any status) | None | All articles | None |
| **super_admin** | All articles (any status) | None | All articles | All articles |

### Role-by-role reasoning

**anon (public):** Sees only published articles. This is the hottest query path (homepage, category pages, article pages) and uses the simple `status = 'published'` USING clause, backed by Phase 2a's partial index on `published_at DESC WHERE status = 'published'`. No INSERT/UPDATE/DELETE — public users can't modify anything.

**contributor:** Can read their own articles at any status (to see what they've submitted), create new drafts, and edit/delete only while in draft. They lose UPDATE and DELETE access once an article leaves draft — they can't self-publish (INSERT forces `status = 'draft'`), can't edit after submission (UPDATE USING blocks `status IN ('published','scheduled')`), and can't delete non-drafts. A contributor who wants to become a journalist applies through Phase 3d's flow; until then, their editorial capabilities are intentionally minimal.

**journalist:** Same read access as contributor (own articles at any status) plus the ability to read published articles by any author (needed for research/reference in the dashboard). Same INSERT restriction (draft only — self-publishing is blocked). Same UPDATE restriction (can't touch own published/scheduled articles). No DELETE — deletion of journalist articles is an editor/super_admin action. The key difference from contributor is that journalists can submit for review (Phase 4g transitions `draft → pending`), which contributors cannot.

**editor:** Full read access to all articles at all statuses (needed for the review queue). No INSERT (editors don't author articles). Full UPDATE access (approve, reject, edit-in-review). No DELETE (deletion is a super_admin action). Editors can change any article's status, including publishing approved articles.

**super_admin:** Full access to all operations on all articles. This is the only role that can delete non-draft articles — a destructive action that should be rare and auditable (Phase 2f's audit_logs captures it).

### Why authors lose UPDATE on published

Once an article is published, the author cannot self-edit — even for typo fixes. Post-publish corrections go through the editor (Phase 5c/5d's edit-in-review capability). This preserves the review workflow's integrity: if a published article had a factual error, the correction must be reviewed before going live, not silently self-patched. The `articles_update_own` policy's `USING (status IN ('draft', 'pending', 'rejected'))` enforces this at the database level.

### Why journalists can't delete

A journalist might want to delete a rejected article to "try again with a clean slate." This is explicitly not allowed — rejected articles are preserved for editorial accountability. The editor or super_admin handles deletion when appropriate.

## Consequences

- **Positive:** Every cell in the matrix is enforced at the database level, not just the API layer.
- **Positive:** Self-publishing is structurally impossible — `INSERT` forces `status = 'draft'`.
- **Positive:** Published articles are immutable by their authors — corrections require editorial review.
- **Trade-off:** The `EXISTS (SELECT 1 FROM profiles WHERE ...)` subquery in every staff-scoped policy adds a join-like cost. This is kept cheap by `idx_profiles_role` (Phase 2b) and `profiles.id` being the PK.
- **Trade-off:** No role can delete a published article except `super_admin` — this is intentional, but means accidental published-article cleanup requires a super_admin action.
