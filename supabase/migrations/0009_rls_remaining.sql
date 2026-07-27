-- Phase 2i: RLS policies for media, audit_logs, categories, tags, article_tags
-- Closes out every Part 2 table — zero tables remain in deny-by-default-no-policies state.
-- Depends on: media (2e), audit_logs (2f), categories (2c), tags/article_tags (2d),
--   profiles (2b), articles RLS (2g).

-- ============================================================
-- MEDIA (3 policies)
-- ============================================================

-- 1. Public can view any media (images on published articles must be accessible).
CREATE POLICY media_select_public ON media
  FOR SELECT
  USING (true);

-- 2. Authenticated users can create media records attributed to themselves.
CREATE POLICY media_insert_own ON media
  FOR INSERT TO authenticated
  WITH CHECK (uploader_id = auth.uid());

-- 3. Uploader or staff can delete media.
CREATE POLICY media_delete_own_or_staff ON media
  FOR DELETE TO authenticated
  USING (
    uploader_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('editor', 'super_admin')
    )
  );

-- ============================================================
-- AUDIT_LOGS (1 policy — SELECT only)
-- ============================================================
-- No INSERT policy — audit writes happen exclusively via the service-role
-- client from trusted server-side code (Phase 3d, 5d, 5e, 5h).
-- DELETE is already impossible at the grant level from Phase 2f.

-- 4. Only editors and super_admins can read audit logs.
CREATE POLICY audit_logs_select_staff ON audit_logs
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('editor', 'super_admin')
    )
  );

-- ============================================================
-- CATEGORIES (2 policies)
-- ============================================================

-- 5. Public can read categories.
CREATE POLICY categories_select_public ON categories
  FOR SELECT
  USING (true);

-- 6. Only super_admin can write categories (INSERT, UPDATE, DELETE).
CREATE POLICY categories_write_super_admin ON categories
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin'
    )
  );

-- ============================================================
-- TAGS (4 policies)
-- ============================================================

-- 7. Public can read tags.
CREATE POLICY tags_select_public ON tags
  FOR SELECT
  USING (true);

-- 8. Any authenticated user can create tags (journalists creating tags
--    while writing articles in Phase 4e).
CREATE POLICY tags_insert_authenticated ON tags
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- 9. Only staff can update tags (tag consolidation is an admin task).
CREATE POLICY tags_write_staff ON tags
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('editor', 'super_admin')
    )
  );

-- 10. Only staff can delete tags.
CREATE POLICY tags_delete_staff ON tags
  FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('editor', 'super_admin')
    )
  );

-- ============================================================
-- ARTICLE_TAGS (2 policies)
-- ============================================================

-- 11. article_tags rows are visible wherever the parent article is visible.
--     The EXISTS subquery runs as the calling user, so it implicitly
--     re-evaluates articles' own RLS policies (Phase 2g) for the
--     referenced parent row. Draft article tags are invisible to
--     non-owners/non-staff because the articles RLS filters them out.
CREATE POLICY article_tags_select ON article_tags
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM articles WHERE articles.id = article_id)
  );

-- 12. article_tags writable by whoever can edit the parent article.
--     Mirrors the ownership/staff logic from articles RLS (Phase 2g).
CREATE POLICY article_tags_write_own_or_staff ON article_tags
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM articles
      WHERE articles.id = article_id
        AND (
          articles.author_id = auth.uid()
          OR EXISTS (
            SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('editor', 'super_admin')
          )
        )
    )
  );
