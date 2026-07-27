---
id: '0019'
title: 'Profiles RLS Matrix and Role-Column Lock'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0019: Profiles RLS Matrix and Role-Column Lock

## Context

Phase 2b closed the creation path for self-escalation (signup trigger hardcodes `role = 'contributor'`). This phase closes the **update path** — ensuring no authenticated user can change their own `profiles.role` column, even by sending a manipulated `role: 'super_admin'` in a self-update request.

## Decision

### Access Matrix

| Role | SELECT | UPDATE | INSERT | DELETE |
|---|---|---|---|---|
| **anon** | Active profiles only | None | None | None |
| **contributor** | Own profile + active profiles | Own profile, role locked | None | None |
| **journalist** | Own profile + active profiles | Own profile, role locked | None | None |
| **editor** | All profiles (any status) | Own profile, role locked | None | None |
| **super_admin** | All profiles (any status) | Any profile | None | None |

### The role-column lock mechanism

The `profiles_update_own` policy's `WITH CHECK` clause is the load-bearing security line:

```sql
WITH CHECK (
  id = auth.uid()
  AND role = (SELECT role FROM profiles WHERE id = auth.uid())
);
```

**How it works:**

1. In RLS `WITH CHECK`, the unqualified `role` refers to the **incoming NEW value** (what the client is trying to write).
2. The subquery `(SELECT role FROM profiles WHERE id = auth.uid())` reads the **currently committed row** — the pre-update state.
3. If a contributor sends `UPDATE profiles SET role = 'super_admin' WHERE id = auth.uid()`, the `WITH CHECK` evaluates as: `'super_admin' = 'contributor'` → `false` → the write is rejected.

**Why a subquery, not `OLD.role`:**

RLS `WITH CHECK` doesn't have access to the `OLD` row reference (that's available in trigger functions, not in RLS policies). The subquery is the idiomatic Postgres way to read the pre-update state in an RLS `WITH CHECK` clause.

**Why not a trigger:**

A `BEFORE UPDATE` trigger that resets `NEW.role = OLD.role` would silently succeed (1 row affected, but role unchanged). The RLS `WITH CHECK` approach **rejects** the write (0 rows affected). The rejection behavior is preferred because:

- It makes self-escalation attempts visible in the application (the update returns 0 rows, triggering an error state in the UI/API).
- A silent overwrite could mask a bug where the application code is accidentally sending a role field it shouldn't.

### No INSERT or DELETE policies

- **INSERT:** Profiles are created exclusively by the `handle_new_user()` trigger (Phase 2b). No client code should ever `INSERT INTO profiles` directly.
- **DELETE:** Profile deletion cascades from `auth.users(id) ON DELETE CASCADE` (Phase 2b). Account deletion, if ever built, goes through a dedicated audited flow, not a direct `DELETE FROM profiles`.

## Consequences

- **Positive:** Self-escalation via profile update is structurally impossible — even a compromised client sending `role: 'super_admin'` is rejected at the database level.
- **Positive:** Combined with Phase 2b's signup trigger, there is no creation or update path for role self-escalation.
- **Positive:** Legitimate own-profile edits (bio, username, avatar_url) work normally — the role-lock only constrains the `role` column.
- **Trade-off:** The subquery in `WITH CHECK` adds a small per-UPDATE cost (single-row PK lookup). Negligible at any realistic scale.
- **Trade-off:** The `profiles_update_super_admin` policy allows any column change by super_admin, including role. This is intentional — super_admin is the escape hatch for role management (Phase 5h's user deactivation and Phase 3d's journalist approval flow write role changes via the admin client, which bypasses RLS, not through this policy).
