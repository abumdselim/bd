---
id: 0022
title: Supabase Auth Configuration — SMTP relay, password policy, OTP expiry
date: 2025-07-28
status: accepted
supersedes: null
---

# Status

accepted

# Context

BengalDesk requires contributor authentication powered by Supabase Auth. Auth settings live in two places that must never drift:

1. **Supabase Dashboard** (source of truth in production)
2. **`supabase/config.toml`** (source of truth for local/CI parity)

If these diverge, bugs surface silently — a 3600-second OTP expiry in code but 1800 in the Dashboard means a contributor's confirmation link expires at the wrong time. Worse, the Supabase free-tier built-in mailer is rate-limited (~3–4 emails/hour), which is insufficient for real signup volume and will silently drop confirmation emails.

The project constitution mandates:
- Email change requires confirmation of both old and new addresses (double_confirm_changes)
- Passwords must resist credential stuffing
- Magic links and OTPs must have a short window to limit replay value

# Decision

## 1. SMTP relay through Resend

All Supabase Auth outbound email (confirmation, recovery, email change) is routed through **Resend SMTP** instead of Supabase's default sender.

| Setting | Value | Rationale |
|---|---|---|
| SMTP host | `smtp.resend.com` | Resend's SMTP relay endpoint |
| SMTP port | `465` | Implicit TLS, avoids STARTTLS downgrade |
| SMTP user | `resend` | Resend's SMTP username (constant) |
| SMTP password | Dashboard-managed secret | Never committed; set in Supabase Dashboard → Auth → SMTP Settings |
| Sender name | `BengalDesk` | Branded sender display name |
| Admin email | `no-reply@bengaldesk.com` | Envelope sender / Reply-To |

**Why not Supabase's built-in mailer?** The free-tier default SMTP is rate-limited too low for real signup volume. Relaying through Resend keeps all transactional mail — auth and future app notifications (Phase 8h) — under one quota, one deliverability reputation, one dashboard.

## 2. config.toml values

```toml
[auth]
site_url = "https://bengaldesk.com"
additional_redirect_urls = [
  "https://bengaldesk.com/auth/callback",
  "http://localhost:3000/auth/callback"
]
jwt_expiry = 3600
enable_confirmations = true

[auth.email]
enable_signup = true
double_confirm_changes = true
max_frequency = "60s"
otp_expiry = 1800

[auth.email.smtp]
enabled = true
host = "smtp.resend.com"
port = 465
user = "resend"
sender_name = "BengalDesk"
admin_email = "no-reply@bengaldesk.com"

[auth.mfa.totp]
enroll_enabled = true
```

## 3. Dashboard-only toggles (not expressible in config.toml)

These are set manually in the Supabase Dashboard and documented here as the record of truth:

| Toggle | Value | Location in Dashboard |
|---|---|---|
| Password strength | Lowercase + uppercase + digits, minimum length **10** | Auth → Password requirements |
| Leaked password protection (HIBP) | **BLOCKED — Pro plan only** | Auth → Password requirements. Free tier returns: "Configuring leaked password protection via HaveIBeenPwned.org is available on Pro Plans and up." Upgrade to Pro to enable, or implement client-side HIBP check (zxcvbn + k-anonymity API) as a workaround. |
| Refresh token reuse interval | **10 seconds** | Auth → Sessions → Refresh token reuse detection |
| Email rate limit | **60s** between emails | Auth → Email → Max frequency (also in config.toml) |

## 4. Branded email templates

Three transactional HTML templates are stored in `supabase/templates/`:
- `confirmation.html` — account signup confirmation
- `recovery.html` — password reset
- `email_change.html` — email address change (dual-send context)

All templates use:
- Inline CSS only (email-client safe)
- Max-width 480px
- Primary color `#1a1a2e`, accent `#e63946`
- Supabase template variables: `{{ .ConfirmationURL }}`, `{{ .SiteURL }}`
- Transactional footer (no unsubscribe link)

## 5. Environment variables

Added to `.env.example`:
```
NEXT_PUBLIC_SITE_URL=https://bengaldesk.com
```
Used to construct OAuth/email redirect URLs on both client and server.

# Consequences

## Positive
- Contributor signups reliably receive confirmation emails via Resend's deliverability infrastructure.
- Stolen or intercepted magic links become useless after 30 minutes.
- Breached passwords would be rejected at signup (HIBP), but this is **blocked on the free tier**. Mitigation: the 10-character minimum + required character classes still provide a strong floor against T3. Plan to enable HIBP on Pro upgrade.
- Email changes require confirming both old and new addresses, preventing unauthorized account takeover via email swap.
- `config.toml` provides local/CI parity with production auth behavior.

## Negative / Trade-offs
- Resend free tier caps at 100 emails/day, 3,000/month. At ~50 contributor signups/month projected pre-launch, this is negligible headroom, but must be monitored.
- SMTP password is stored in the Supabase Dashboard (set via Management API during Phase 3a). It is NOT committed to config.toml. If the password needs rotation, update via the Management API: `PATCH /v1/projects/{ref}/config/auth` with `smtp_pass`.
- HIBP (HaveIBeenPwned) password leak check is a **Pro plan feature** and cannot be enabled on the free tier.
- 10-second refresh token reuse interval is aggressive; if a user has two devices in a slow network, one may get logged out. This is an acceptable trade-off for security.

## Rollback plan
1. In Supabase Dashboard → Auth → SMTP, disable custom SMTP to revert to Supabase's built-in mailer.
2. Revert `supabase/config.toml` to remove `[auth.email.smtp]` block.
3. Delete email templates from `supabase/templates/`.
4. No database migration is involved; this phase is config-only.

## Dependencies
- Phase 1f (Supabase client architecture) — `lib/supabase/` client files must exist.
- Phase 1c (service accounts) — Resend API key must be provisioned.

## Future work flagged
- **Forgot-password flow** is not present anywhere in the 100-phase sequence. This must ship before launch. Recommend inserting as Phase 3k before Part 4 begins. (The recovery template is built here in anticipation, but no UI flow exists yet.)
