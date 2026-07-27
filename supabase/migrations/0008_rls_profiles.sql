-- Phase 2h: RLS policies for profiles table
-- Replaces the deny-by-default state from Phase 2b.
-- Depends on: profiles (2b).
--
-- No INSERT policies — profiles are created only via handle_new_user() trigger (2b).
-- No DELETE policies — profile deletion cascades from auth.users, not direct client ops.

-- ============================================================
-- SELECT policies (3)
-- ============================================================

-- 1. Anyone (including anon) can read any active profile.
--    Needed for public author pages (Phase 6a: /author/[username]/).
--    No TO clause → applies to all roles.
CREATE POLICY profiles_select_public ON profiles
  FOR SELECT
  USING (is_active = true);

-- 2. Authenticated users can see their own profile even if deactivated.
CREATE POLICY profiles_select_own ON profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid());

-- 3. Editors and super_admins can see all profiles regardless of active status.
CREATE POLICY profiles_select_staff ON profiles
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid() AND p.role IN ('editor', 'super_admin')
    )
  );

-- ============================================================
-- UPDATE policies (2)
-- ============================================================

-- 4. Users can update their own profile — EXCEPT the role column.
--    USING: only own row is targetable.
--    WITH CHECK: the incoming role value must equal the CURRENT committed
--    role value (fetched via subquery against the existing row).
--    This is the load-bearing line: even if a compromised client sends
--    role: 'super_admin' in a self-update request, Postgres evaluates
--    WITH CHECK against the pre-update state and rejects the write.
--
--    IMPORTANT: This is NOT "role = role" (a tautology on NEW.role).
--    The subquery reads the committed row, not the incoming NEW row.
CREATE POLICY profiles_update_own ON profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT role FROM profiles WHERE id = auth.uid())
  );

-- 5. Super_admins can update any profile (used for is_active toggling
--    in Phase 5h's user management — not exposed as a generic role-edit UI).
CREATE POLICY profiles_update_super_admin ON profiles
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = auth.uid() AND p.role = 'super_admin'
    )
  );
