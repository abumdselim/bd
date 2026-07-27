-- Phase 2f: Audit Logs (immutable)
-- Records every actor, action, and JSONB diff across the platform.
-- Depends on: profiles (2b).
--
-- IMMUTABILITY NOTE:
-- RLS alone does NOT protect this table from the service_role, because
-- service_role bypasses RLS entirely in Supabase. A REVOKE at the
-- Postgres grant level is the only mechanism that makes DELETE
-- impossible even for a compromised service-role credential.
-- This is why REVOKE DELETE is here, not just "no DELETE policy."

CREATE TABLE audit_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    uuid REFERENCES profiles(id),
  action      text NOT NULL,
  entity_type text NOT NULL,
  entity_id   uuid NOT NULL,
  diff        jsonb,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
-- Zero policies added here — deny-by-default until Phase 2i.

-- Immutability enforced at the GRANT level, not just RLS.
-- service_role normally bypasses RLS entirely, so the only way to
-- make DELETE truly impossible for service_role is to revoke the
-- grant itself. Even a compromised service-role key cannot delete
-- audit rows — only a direct superuser connection (which Supabase
-- controls, not application credentials) could bypass this.
REVOKE DELETE ON audit_logs FROM anon;
REVOKE DELETE ON audit_logs FROM authenticated;
REVOKE DELETE ON audit_logs FROM service_role;
