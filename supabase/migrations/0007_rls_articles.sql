-- Phase 2g: RLS policies for articles table
-- Replaces the deny-by-default state from Phase 2a.
-- Depends on: articles (2a), profiles (2b).
--
-- Policy naming convention: articles_{operation}_{scope}
-- Separate named policies per role/purpose for individual auditability.

-- ============================================================
-- SELECT policies (3)
-- ============================================================

-- 1. Public + all authenticated roles can read published articles.
--    No TO clause → applies to anon, authenticated, and service_role.
CREATE POLICY articles_select_published ON articles
  FOR SELECT
  USING (status = 'published');

-- 2. Authenticated users can always see their own articles, any status.
CREATE POLICY articles_select_own ON articles
  FOR SELECT TO authenticated
  USING (author_id = auth.uid());

-- 3. Editors and super_admins can see all articles (any status).
--    Supersedes the published-only and own-only views for staff.
CREATE POLICY articles_select_staff ON articles
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('editor', 'super_admin')
    )
  );

-- ============================================================
-- INSERT policy (1)
-- ============================================================

-- 4. Contributors and journalists can create their own draft articles.
--    WITH CHECK forces status = 'draft' → self-publishing is impossible.
--    WITH CHECK also forces author_id = auth.uid() → can't author as someone else.
CREATE POLICY articles_insert_own ON articles
  FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND status = 'draft'
    AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('contributor', 'journalist')
    )
  );

-- ============================================================
-- UPDATE policies (2)
-- ============================================================

-- 5. Authors can update their own articles only while in editable status.
--    USING: which rows are targetable (draft, pending, rejected only).
--    WITH CHECK: what the row is allowed to become (author_id stays the same).
--    Published and scheduled articles are NOT targetable → post-publish
--    corrections require editorial review (Phase 5c/5d).
CREATE POLICY articles_update_own ON articles
  FOR UPDATE TO authenticated
  USING (author_id = auth.uid() AND status IN ('draft', 'pending', 'rejected'))
  WITH CHECK (author_id = auth.uid());

-- 6. Editors and super_admins can update any article.
--    USING: all articles are visible/targetable.
--    WITH CHECK: no restriction on what they can change (status, title, etc.).
CREATE POLICY articles_update_staff ON articles
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role IN ('editor', 'super_admin')
    )
  );

-- ============================================================
-- DELETE policies (2)
-- ============================================================

-- 7. Authors can delete their own articles only while in draft.
CREATE POLICY articles_delete_own_draft ON articles
  FOR DELETE TO authenticated
  USING (author_id = auth.uid() AND status = 'draft');

-- 8. Only super_admins can delete non-draft articles.
--    (Own-draft deletion above covers the super_admin's own drafts too,
--     so this policy handles everything else.)
CREATE POLICY articles_delete_super_admin ON articles
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
        AND profiles.role = 'super_admin'
    )
  );
