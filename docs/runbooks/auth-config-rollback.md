# Auth Configuration Rollback Runbook

## When to use
After Phase 3a, if auth emails stop arriving or signups break, follow these steps.

## Current production state (verified 2026-07-27)

| Setting | Value | Set via |
|---|---|---|
| Site URL | `https://bengaldesk.com` | Management API |
| Redirect allowlist | `https://bengaldesk.com/auth/callback`, `http://localhost:3000/auth/callback` | Management API |
| JWT expiry | 3600s | Management API |
| Signup enabled | true | Management API |
| Confirmations required | true (autoconfirm=false) | Management API |
| Double email change | true | Management API |
| OTP expiry | 1800s (30 min) | Management API |
| SMTP host | `smtp.resend.com` | Management API |
| SMTP port | 465 | Management API |
| SMTP user | `resend` | Management API |
| SMTP password | Dashboard secret (via Management API) | Management API |
| Sender name | BengalDesk | Management API |
| Admin email | `no-reply@bengaldesk.com` | Management API |
| Email max frequency | 60s | Management API |
| Password min length | 10 | Management API |
| Password required chars | lowercase + uppercase + digits | Management API |
| HIBP | **Disabled (Pro plan required)** | N/A |
| Refresh token reuse | 10s | Management API |
| TOTP MFA enroll | true | Management API |
| Email templates | Branded (confirmation, recovery, email_change) | Management API |

## Rollback: disable Resend SMTP

```bash
SUPABASE_PAT="<your-pat>"
PROJECT_REF="ixaazhidgikpvthxwifg"

curl -X PATCH "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer ${SUPABASE_PAT}" \
  -H 'Content-Type: application/json' \
  -d '{
    "smtp_host": null,
    "smtp_port": null,
    "smtp_user": null,
    "smtp_pass": null,
    "smtp_sender_name": null,
    "smtp_admin_email": null
  }'
```

This reverts to Supabase's built-in mailer (rate-limited on free tier).

## Re-apply: enable Resend SMTP

```bash
curl -X PATCH "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer ${SUPABASE_PAT}" \
  -H 'Content-Type: application/json' \
  -d '{
    "smtp_host": "smtp.resend.com",
    "smtp_port": "465",
    "smtp_user": "resend",
    "smtp_pass": "<resend-api-key>",
    "smtp_sender_name": "BengalDesk",
    "smtp_admin_email": "no-reply@bengaldesk.com"
  }'
```

## Verify email delivery

1. Sign up with a disposable email address.
2. Check that the email arrives from `no-reply@bengaldesk.com`.
3. Inspect email headers — `Received` should show `smtp.resend.com`.

## Verify password policy

```bash
SUPABASE_URL="https://ixaazhidgikpvthxwifg.supabase.co"
SUPABASE_KEY="<service-role-key>"

# Should return 422 weak_password
curl -X POST "${SUPABASE_URL}/auth/v1/signup" \
  -H "apikey: ${SUPABASE_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","password":"short1"}'
```

## Enable HIBP (requires Pro plan)

```bash
curl -X PATCH "https://api.supabase.com/v1/projects/${PROJECT_REF}/config/auth" \
  -H "Authorization: Bearer ${SUPABASE_PAT}" \
  -H 'Content-Type: application/json' \
  -d '{"password_hibp_enabled": true}'
```
