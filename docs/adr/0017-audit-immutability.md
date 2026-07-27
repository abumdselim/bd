---
id: '0017'
title: 'Audit Log Immutability via Grant-Level REVOKE'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0017: Audit Log Immutability via Grant-Level REVOKE

## Context

Section G requires "every decision written to audit_logs." Phase 5j promises "no delete button exists in UI or API." But a promise about missing UI code and a promise about missing API endpoints are both fragile — they can be accidentally re-introduced by a future developer, or bypassed by a compromised service-role credential that directly executes SQL.

## Decision

Make `audit_logs` structurally immutable at the **Postgres grant level**, not just via RLS policy absence.

### Why RLS alone is insufficient

In Supabase, `service_role` **bypasses RLS entirely**. This is by design — service_role is meant for trusted server-side operations that need full data access. The consequence:

| Protection mechanism | Blocks anon/authenticated? | Blocks service_role? |
|---|---|---|
| No DELETE RLS policy | Yes (RLS deny-by-default) | **No** (bypasses RLS) |
| `REVOKE DELETE` at grant level | Yes | **Yes** |
| Both combined | Yes | Yes |

RLS and grant-level permissions are separate Postgres mechanisms. RLS filters rows; grants control whether a role has the permission at all. A role that bypasses RLS still needs the underlying table privilege.

### The exact REVOKE statements

```sql
REVOKE DELETE ON audit_logs FROM anon;
REVOKE DELETE ON audit_logs FROM authenticated;
REVOKE DELETE ON audit_logs FROM service_role;
```

After these revocations:

- `SELECT has_table_privilege('service_role', 'audit_logs', 'DELETE');` returns `false`.
- Even a `DELETE FROM audit_logs WHERE ...` executed with the service-role key fails with a permission-denied error.
- The only way to delete a row is a direct **superuser** connection to the underlying Postgres cluster — which Supabase's infrastructure controls, not application-level credentials.

### Why only DELETE, not UPDATE

The constitution's Section E specifies "no DELETE permission for any role" — not update-immutability. Reasons to leave UPDATE ungoverned at the grant level:

1. No application code ever issues `UPDATE` against this table (it's append-only by design).
2. A future phase might use `INSERT ... ON CONFLICT` (upsert) which requires some update-like privileges.
3. Over-scoping the REVOKE could break legitimate patterns without adding real security.

### Why `action` and `entity_type` are `text`, not enum

The set of loggable actions grows across many phases:

- 3d: `journalist_application_submitted`, `journalist_approved`, `journalist_rejected`
- 5b: `article_approved`, `article_rejected`
- 5g: `breaking_expired` (system-initiated, no human actor)
- Future: `user_deactivated`, `category_created`, `media_deleted`, etc.

An enum would require a new migration for every new action type. Free-text `text` columns let any phase log a new action string without a schema change. The trade-off (typos in action strings) is acceptable because:

- Phase 5j's viewer filters by action — a typo just means that action won't show up in filters, not a data-integrity failure.
- The `diff` JSONB column carries the actual meaningful change; `action` is a label.

### Why `actor_id` is nullable

System-initiated actions (e.g., Phase 5g's Vercel cron job auto-expiring a breaking-news flag) have no human actor. Making `actor_id` nullable avoids needing a synthetic "system" profile row.

## Consequences

- **Positive:** Even a fully compromised service-role key cannot delete audit entries.
- **Positive:** The REVOKE is auditable — `has_table_privilege()` queries prove it.
- **Positive:** Free-text action/entity_type columns avoid a migration-per-action-type pattern.
- **Trade-off:** The `diff` column is unstructured JSONB — consumers must agree on its shape per action type. This is documented per-phase in each phase's own spec.
- **Trade-off:** `audit_logs` is append-only with no archival strategy. At BengalDesk's scale on Supabase Free (500MB), this table will eventually approach the ceiling. An archival strategy (e.g., export-and-purge rows older than 90 days) is deferred to Part 10 (launch hardening).
