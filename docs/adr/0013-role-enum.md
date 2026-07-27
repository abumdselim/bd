---
id: '0013'
title: 'Role Enum and Profiles Auto-Create Trigger'
status: accepted
date: '2025-06-26'
supersedes: ''
---

# ADR-0013: Role Enum and Profiles Auto-Create Trigger

## Context

BengalDesk has four user roles that gate access across the entire application: dashboard pages, API routes, RLS policies, and editorial workflow transitions all read `profiles.role` to make authorization decisions. A wrong enum value or a missing auto-create trigger means either an authenticated-but-profile-less user hitting an RLS policy (error), or a self-promoted user gaining journalist/editor access (security breach).

## Decision

### The four roles

| Role | Intended access | Can self-assign at signup? |
|---|---|---|
| `contributor` | Read public content, submit journalist applications (3d) | **Yes** — this is the default and only signup-time role |
| `journalist` | Dashboard: create/edit/submit articles, view own analytics | **No** — assigned by an `editor` or `super_admin` after application review (3d) |
| `editor` | Dashboard: review/approve/reject articles, manage journalists, all journalist perms | **No** — assigned by `super_admin` only |
| `super_admin` | Full platform administration, all editor perms, system settings | **No** — assigned via SQL/Supabase dashboard only, never through the application UI |

### Why `journalist` is never a signup-time default

This is the single most important security property of the profiles table.

The signup path creates a profile via the `handle_new_user()` trigger. This trigger is `SECURITY DEFINER` (runs as the function owner, a superuser) because the Supabase Auth internal signup process has no direct INSERT rights on `public.profiles` under RLS.

Because the trigger runs with elevated privileges, its logic is the **sole gatekeeper** of what role a new row gets. The function hardcodes `role = 'contributor'` and never reads any client-supplied value — specifically, it never reads `raw_user_meta_data->>'role'`. This means:

- A crafted signup request with `{ "role": "super_admin" }` in metadata is silently ignored.
- There is no code path, at any layer, that allows a user to promote themselves.
- Role promotion is an explicit, separate action performed by an authorized user (editor or super_admin) through a dedicated UI flow.

### Username generation

The auto-generated username `'user_' || substr(NEW.id::text, 1, 8)` is a placeholder that satisfies the `NOT NULL UNIQUE` constraint at signup time. The user changes it in profile settings (Phase 4b). This uses the UUID prefix rather than email because:

1. Emails contain `@` and `.` which fail the `^[a-z0-9_]{3,30}$` CHECK constraint.
2. The UUID prefix is collision-resistant (16^8 = 4 billion possibilities).
3. It's immediately obvious which usernames are placeholder vs. user-chosen.

### Why `SECURITY DEFINER` is required

Without `SECURITY DEFINER`, the `handle_new_user()` function would run with the privileges of the invoking context (Supabase Auth's internal signup process). Under RLS, this context has no INSERT rights on `public.profiles`, so every signup would fail with a permissions error.

The trade-off is that a `SECURITY DEFINER` function runs as its owner (a superuser), so its logic must be audited carefully. This ADR and the inline comments in `0002_profiles.sql` serve as that audit trail.

## Consequences

- **Positive**: No user can ever exist in `auth.users` without a corresponding `profiles` row — the trigger closes the gap.
- **Positive**: Self-promotion is structurally impossible from the signup path — the role is hardcoded.
- **Positive**: The `ON DELETE CASCADE` on `auth.users(id)` means deleting a user (e.g., GDPR request) automatically cleans up the profile.
- **Trade-off**: `SECURITY DEFINER` functions are a privilege-escalation mechanism — the function body is the trust boundary. Any future modification to `handle_new_user()` must re-verify that role is still hardcoded.
- **Trade-off**: The placeholder username (`user_<8-char-id>`) is not human-readable — this is intentional, as it forces the user to choose a real username before they can be meaningfully referenced.
- **Cross-reference**: Section G (Constitution) owns the full role-assignment flow. Phase 3d owns the journalist application table and review workflow.