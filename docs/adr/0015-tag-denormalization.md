---
id: '0015'
title: 'Tag Usage Count Denormalization'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0015: Tag Usage Count Denormalization

## Context

Phase 6i (tag pages) and Phase 4e (tag-autocomplete) need to display and sort tags by popularity. Two approaches exist:

1. **Live COUNT(*)** — compute `SELECT tags.*, COUNT(article_tags.article_id) FROM tags LEFT JOIN article_tags ... GROUP BY tags.id` on every request.
2. **Denormalized `usage_count`** — maintain a counter column on `tags`, updated by a trigger on `article_tags`.

## Decision

Denormalize `usage_count` onto the `tags` table, maintained by a trigger on `article_tags`.

### Why denormalize

BengalDesk's traffic profile is read-heavy: news readers vastly outnumber writes. A tag page (6i) loads on every public visit; a tag is attached/detached only when a journalist writes or edits an article.

| Approach | Read cost | Write cost | Complexity |
|---|---|---|---|
| Live `COUNT(*)` | O(n) aggregate + join on every tag-page load | Zero | Low (one query, no trigger) |
| Denormalized `usage_count` | O(1) column read, index-backed sort | O(1) single-row UPDATE per tag-attach/detach | Medium (trigger function) |

At BengalDesk's expected scale (thousands of reads per write), the denormalized approach wins on total compute.

### Trigger design

- **Fires on:** `AFTER INSERT OR DELETE ON article_tags` (not UPDATE — tag-attach/detach is insert/delete, never an in-place update to the join row)
- **Increments** `usage_count + 1` on INSERT
- **Decrements** `GREATEST(usage_count - 1, 0)` on DELETE — the `GREATEST` floor prevents negative counts under edge-case concurrent deletes or manual admin cleanup of orphaned rows
- **`FOR EACH ROW`** — required because the function references `NEW.tag_id` / `OLD.tag_id`

### Composite primary key on article_tags

The join table uses `PRIMARY KEY (article_id, tag_id)` — a composite key, not a surrogate `id uuid`. Rationale:

1. No application code needs to reference an individual `article_tags` row by its own ID.
2. The composite PK inherently prevents duplicate tag-attachments to the same article (a separate `UNIQUE` constraint would be redundant).
3. One fewer index to maintain compared to a surrogate-key-plus-unique-constraint approach.

### What's NOT in the database

- **Max tags per article** — enforced in Phase 4e's Zod schema (application layer), not a DB constraint. It's a UX concern, not data integrity.
- **Tag moderation** — any journalist can create tags freely. No approval flow.
- **Tag merging/renaming** — manual Super Admin SQL operation if needed post-launch.

## Consequences

- **Positive:** Tag-page and autocomplete queries are O(1) column reads with index-backed sorting.
- **Positive:** Composite PK prevents duplicate tag-attachments without an extra unique constraint.
- **Trade-off:** The trigger adds a single-row UPDATE on every tag-attach/detach. At BengalDesk's write frequency, this is negligible.
- **Trade-off:** `usage_count` could theoretically drift out of sync if someone directly INSERTs/DELETEs `article_tags` rows bypassing the trigger (e.g., via service-role bulk operations). A periodic reconciliation query (`UPDATE tags SET usage_count = (SELECT COUNT(*) FROM article_tags WHERE tag_id = tags.id)`) can fix this if needed.
