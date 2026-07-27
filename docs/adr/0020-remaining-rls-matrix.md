---
id: '0020'
title: 'RLS Matrices for Media, Audit Logs, Categories, Tags, Article Tags'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0020: Remaining RLS Matrices

## Context

Phases 2g and 2h secured articles and profiles. Five tables remain in deny-by-default state: media, audit_logs, categories, tags, and article_tags. This phase closes all of them in a single migration, completing the RLS posture for the entire Part 2 schema.

## Decision

### Media

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| anon | ✅ All | — | — | — |
| authenticated | ✅ All | Own (uploader_id = auth.uid()) | — | Own or staff |
| editor/super_admin | ✅ All | ✅ Own | — | ✅ All |

Public read is required because media images are embedded in published articles (Phase 6c) — a reader doesn't need to be authenticated to see a cover image. No UPDATE policy — media records are immutable once created (Phase 4d's upload creates them, Phase 5h's cleanup deletes them).

### Audit Logs

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| anon | — | — | — | — (grant revoked) |
| contributor/journalist | — | — | — | — (grant revoked) |
| editor/super_admin | ✅ All | — | — | — (grant revoked) |

**No INSERT policy exists.** Audit log writes happen exclusively via the service-role client from trusted server-side API routes (starting Phase 3d). This means:

- What gets logged is controlled by server code, not by client-submitted payloads.
- No client can fabricate or manipulate audit entries.
- DELETE is already revoked at the grant level (Phase 2f) for all roles including service_role.

### Categories

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| anon | ✅ All | — | — | — |
| editor | ✅ All | — | — | — |
| super_admin | ✅ All | ✅ | ✅ | ✅ |

Categories are a fixed reference taxonomy (Section D's 9 categories). Only super_admin can modify them. Even editors can't — category changes are a constitutional decision (ADR 0014 requires an ADR for additions).

### Tags

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| anon | ✅ All | — | — | — |
| contributor/journalist | ✅ All | ✅ | — | — |
| editor/super_admin | ✅ All | ✅ | ✅ | ✅ |

Any authenticated user can create tags (journalists create them organically while writing articles in Phase 4e). Only staff can update or delete — tag consolidation/merging is a manual admin task.

### Article Tags

| Role | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| anon | Cascades from parent article | — | — | — |
| authenticated | Cascades from parent article | Cascades from parent article | Cascades from parent article | Cascades from parent article |

**Visibility cascades** from the parent article's RLS policies (Phase 2g). The `article_tags_select` policy uses `EXISTS (SELECT 1 FROM articles WHERE articles.id = article_id)`, which runs as the calling user — so it re-evaluates articles' own RLS for the referenced parent row. This means:

- A draft article's tags are invisible to non-owners/non-staff.
- A published article's tags are visible to everyone (including anon).
- No duplication of articles' full ownership/staff logic.

Write access mirrors the same pattern — you can attach/detach tags if you can edit the parent article.

## Consequences

- **Positive:** Zero tables remain in deny-by-default-with-no-policies state — Part 2 RLS is complete.
- **Positive:** Audit logs are read-only for staff, write-only for service-role server code — no client can fabricate or read audit entries outside their authorization.
- **Positive:** Article_tags visibility cascades automatically from articles RLS without duplicating logic.
- **Trade-off:** The article_tags nested-RLS-evaluation pattern (EXISTS subquery into articles) adds per-row cost. Acceptable at BengalDesk's scale; flagged for Phase 7f–7i performance profiling if it proves costly under real load.
- **Trade-off:** Tags are open for any authenticated user to create — no approval flow for tag names. This keeps Phase 4e's tag autocomplete simple. Tag governance (merging, renaming) is a manual super_admin task.
