---
id: '0021'
title: 'Bangla Full-Text Search Approach — Simple Config + Unaccent'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0021: Bangla Full-Text Search Approach

## Context

PostgreSQL's full-text search has built-in support for English, French, German, Spanish, and ~20 other languages via configuration dictionaries that implement language-specific stemming ("running" → "run", "cats" → "cat"). Bangla (বাংলা) is **not** among them. The options are:

1. **`to_tsvector('english', ...)`** — applies English stemming rules to Bangla text. Meaningless at best, harmful at worst (could mis-strip Bangla syllables).
2. **`to_tsvector('simple', ...)`** — no stemming at all. Splits on whitespace/punctuation and lowercases. Safe for any script.
3. **Custom Bangla dictionary** — possible but significant effort (writing a Bangla stemmer in C/PLpgSQL as a Postgres text search configuration). Out of scope.

## Decision

Use `to_tsvector('simple', unaccent(...))` — the conservative, safe approach.

### What this means in practice

- **Token-based matching**, not stem-aware. Searching "খেলা" matches articles containing the exact token "খেলা" but does **not** automatically match "খেলাধুলা" (which contains "খেলা" as a substring but is a different token).
- This is acceptable for a news site where:
  - Search queries are typically multi-word Bangla phrases (e.g., "ঢাকা বিশ্ববিদ্যালয় ভর্তি")
  - Exact token matches against titles and excerpts return highly relevant results
  - The 9-category taxonomy (Phase 2c) and tag system (Phase 2d) provide navigation paths that complement search
- **`unaccent`** extension's effect on Bangla: minimal. Bangla doesn't use Latin diacritics (é, ü, ñ). `unaccent` passes Bangla characters through unchanged. Its value here is for **mixed-language content** — English company names, technical terms, or person names in Bangla articles benefit from accent stripping ("Café" → "cafe").

### Why not pg_trgm (trigram similarity search)?

The constitution specifies PostgreSQL FTS, not trigram search. Trigram search (`pg_trgm`) enables:
- Fuzzy/typo-tolerant matching ("বাংলাদেশ" matches even if mistyped as "বাঙলাদেশ")
- Substring matching ("খেলা" matches "খেলাধুলা")

These are valuable features but not specified. A future phase could add a `pg_trgm`-based "did you mean?" suggestion alongside the FTS results, but that's an enhancement, not the foundation.

### Why `websearch_to_tsquery`?

Three Postgres functions convert user text to tsquery:

| Function | Handles | Example input | Behavior |
|---|---|---|---|
| `to_tsquery` | Operator syntax only | `bangla & news` | Requires `&`, `|`, `!` — breaks on raw user input with spaces |
| `plainto_tsquery` | Unquoted words as AND | `bangla news` | `bangla & news` — but no phrase or negation support |
| `websearch_to_tsquery` | Web-style syntax | `"bangla news" -sports` | Supports quotes, `-exclude`, OR — matches what users actually type |

`websearch_to_tsquery` is the correct choice for a search box where users type naturally.

### Generated STORED column, not trigger

The `search_vector` column uses `GENERATED ALWAYS AS (...) STORED`:

- Postgres maintains it automatically on every INSERT/UPDATE to `title` or `excerpt`.
- No separate trigger function to write, test, or maintain.
- Guaranteed consistent — can't get out of sync because it's computed, not copied.
- Requires Postgres 12+ (Supabase runs Postgres 15).

### Column weights

- `title` → weight `A` (highest rank contribution)
- `excerpt` → weight `B` (medium rank contribution)

`ts_rank` uses these weights so a title match ranks higher than an excerpt-only match.

## Consequences

- **Positive:** Safe for Bangla — no English stemming misapplied.
- **Positive:** `websearch_to_tsquery` gives users natural search syntax.
- **Positive:** Generated column is zero-maintenance.
- **Trade-off:** No stemming means "রাজনীতি" doesn't match "রাজনৈতিক" (political). Users must search the exact form. Acceptable at launch.
- **Trade-off:** The GIN index adds storage per row. Flagged in `free-tier-budget.md` as a growth factor.
- **Trade-off:** `unaccent` is mostly a no-op for pure Bangla text. Its value is for mixed-language content only.
