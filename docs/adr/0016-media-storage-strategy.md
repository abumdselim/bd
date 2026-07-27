---
id: '0016'
title: 'Media Storage Strategy — Path Over Signed URL'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0016: Media Storage Strategy

## Context

Every article image and avatar image needs a persistent, queryable reference. Two storage strategies exist:

1. **Store the signed URL** — Supabase Storage generates time-limited signed URLs. Baking this into the database at upload time means the URL works when the row is created but expires later.
2. **Store the Storage path** — the stable path within the bucket (e.g., `article-images/uuid.webp`). The application constructs a public or signed URL at request time.

## Decision

Store the `storage_path` (the bucket-relative path), not a signed URL.

### Why path, not URL

| Concern | Signed URL stored | Storage path stored |
|---|---|---|
| Expiration | URL expires, row becomes stale | Path never expires |
| Image transformations | Need a new signed URL per size | Construct per-size URL at request time |
| Caching | Cache key changes on re-sign | Stable cache key from stable path |
| Phase 7h (next/image) | Would need to re-sign before passing to `<Image>` | Directly constructs transform URL from path |
| Section C budget (< 400kb/image) | Can't audit without fetching | `size_bytes` column + path = auditable |

### Supabase Storage bucket

The bucket `article-images` must be created manually in the Supabase dashboard:

1. Go to **Storage → New Bucket**.
2. Name: `article-images`.
3. **Public bucket**: Yes — article images must be publicly readable by anonymous visitors (Phase 6c renders them on the public article page).
4. **File size limit**: 50 MB (matches `size_bytes <= 52428800` constraint).

This is not a SQL migration — Supabase Storage buckets are managed via the dashboard or the Storage API, not DDL. This ADR is the single source of truth for the bucket name and configuration.

### Why `alt_text` is `NOT NULL` at the database level

Making `alt_text` structurally required means:

- No application bug, direct SQL insert, or migration script can create an alt-text-less media row.
- The common real-world failure mode (alt text is "optional in practice because it's optional in the schema") is eliminated by construction.
- Phase 4d's upload form will enforce the 5–250 character range with Bangla-language guidance, but even if that UI is bypassed, the database catches it.

### Why `mime_type` has a CHECK allow-list

The column records the **server-verified** MIME type (after Phase 4d's magic-byte sniffing), not a client-supplied claim. The allow-list (`image/jpeg`, `image/png`, `image/webp`) is a database-level backstop:

- Phase 4d's upload handler does the real validation (sniffing file bytes, not trusting the upload's Content-Type header).
- If Phase 4d has a bug and writes the wrong type, this constraint catches it.
- The allow-list covers all formats Phase 7h's image pipeline needs to support.

### `original_size_bytes` for compression auditing

Storing both `size_bytes` (post-compression) and `original_size_bytes` (pre-compression) enables a post-Phase 4d audit query:

```sql
SELECT id, storage_path,
       original_size_bytes,
       size_bytes,
       ROUND((1.0 - size_bytes::numeric / original_size_bytes) * 100, 1) AS compression_pct
FROM media
WHERE original_size_bytes IS NOT NULL
ORDER BY compression_pct ASC;
```

This supports the Section C performance budget (< 400kb per article page) empirically.

### No `is_avatar` column

The table is intentionally generic. Avatars (Phase 4b) reuse this table rather than a separate `avatars` table. Any avatar-vs-article-image distinction is inferable from which table references a given `media.id`:

- `articles.cover_image_id` → article image
- `profiles.avatar_url` → stored as a URL string, not a FK to media (per Phase 2b's schema)


## Consequences

- **Positive**: Storage paths are stable — no expiration, no re-signing.
- **Positive**: `alt_text NOT NULL` makes accessibility-by-construction, not just accessibility-by-convention.
- **Positive**: `original_size_bytes` enables compression-ratio auditing without fetching actual files.
- **Trade-off**: Public bucket means any URL-guesser can access images. This is intentional for a news site (images must be publicly readable), but means hotlinking is possible — mitigated by Cloudflare in production (Phase 7h or 10b).
- **Trade-off**: `mime_type` CHECK is a backstop, not a defense — it validates the stored record, not the actual file bytes. Full T4 (malware/polyglot) defense is Phase 4d's responsibility.
