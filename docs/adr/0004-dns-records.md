---
id: 0004
title: DNS Records
date: 2026-07-28
status: accepted
supersedes: null
---

# Status

Accepted

# Context

The domain bengaldesk.com must resolve through Cloudflare with proper proxying, email authentication (SPF/DKIM/DMARC), and DNSSEC. These records are the foundation for all subsequent infrastructure phases: Vercel deployment (1d), Resend email (1c), WAF rules (1h), and edge rate limiting (1i) all depend on this DNS zone being correctly configured. This ADR documents the deployed record set as the source of truth; the actual records are configured in the Cloudflare dashboard.

# Decision

## DNS Record Table

| Type  | Name                      | Content                                                | Proxy   | Notes                                      |
|-------|---------------------------|--------------------------------------------------------|---------|--------------------------------------------|
| A     | bengaldesk.com            | 76.76.21.21                                            | Proxied | Vercel anycast IP                          |
| CNAME | www.bengaldesk.com        | bengaldesk.com                                         | Proxied | Apex redirect                              |
| TXT   | bengaldesk.com            | "v=spf1 include:_spf.resend.com ~all"                 | DNS only| SPF — authorizes Resend to send mail       |
| CNAME | resend._domainkey.bengaldesk.com | (value from Resend dashboard)                    | DNS only| DKIM — cryptographic mail signature key    |
| TXT   | _dmarc.bengaldesk.com     | "v=DMARC1; p=quarantine; rua=mailto:dmarc@bengaldesk.com" | DNS only| DMARC — policy for SPF/DKIM failures       |

## Cloudflare Configuration

| Setting              | Value                        | Notes                                            |
|----------------------|------------------------------|--------------------------------------------------|
| SSL/TLS Mode         | Full (Strict)                | Requires valid cert at origin (Vercel provides)  |
| HSTS                 | Enabled                      | max-age=31536000, includeSubDomains, preload     |
| HSTS Preload Submit  | Deferred to Phase 7          | Awaiting subdomain stability confirmation        |
| DNSSEC               | Enabled                      | DS record added at registrar after Cloudflare generates it |
| Auto Minify          | Off                          | Not yet — no frontend assets to minify            |
| Always Use HTTPS     | On                           | Redirects HTTP → HTTPS at edge                    |
| Minimum TLS Version  | 1.2                          |                                                   |

## DNSSEC Setup

DNSSEC is a two-step process across two dashboards:

1. **Cloudflare:** Enable DNSSEC in the Cloudflare dashboard for the bengaldesk.com zone. Cloudflare generates a DS record.
2. **Registrar:** Add the DS record at the domain registrar's DNSSEC configuration panel.
3. **Verify:** Run `dig +dnssec bengaldesk.com` — the response must include the `ad` (authenticated data) flag.

## Email Authentication Summary

| Protocol | Record                          | Purpose                                              | Policy                                        |
|----------|---------------------------------|------------------------------------------------------|-----------------------------------------------|
| SPF      | TXT bengaldesk.com              | Authorizes Resend's mail servers to send as @bengaldesk.com | ~all (softfail)                        |
| DKIM     | CNAME resend._domainkey         | Cryptographic signature for outbound Resend mail    | Key rotation handled by Resend               |
| DMARC    | TXT _dmarc.bengaldesk.com       | Tells receivers what to do when SPF/DKIM fail       | p=quarantine (not reject — see note)         |

> **Note on p=quarantine vs p=reject:** p=quarantine is intentional for Phase 1b. A misconfigured Resend template early in the project lifecycle must not hard-bounce all journalist notification emails. p=reject will be evaluated in Phase 10a's security audit once the mail pipeline is proven stable.

# Consequences

- All 5 DNS records are the single source of truth. Any record change must update this ADR and commit the update to the repo.
- The DKIM CNAME value is populated from the Resend dashboard — it is not fabricated and must be copied verbatim.
- DNSSEC status must be re-verified after any registrar transfer or Cloudflare zone setting change.
- This ADR is referenced by Phase 1c (Resend account), Phase 1d (Vercel deployment), Phase 1h (WAF), and Phase 1i (rate limiting).
- The rollback procedure for DNS changes is documented in `docs/runbooks/dns-rollback.md`.
