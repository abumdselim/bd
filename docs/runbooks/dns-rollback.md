# DNS Rollback Runbook

> **Purpose:** Revert Cloudflare DNS changes if bengaldesk.com becomes unreachable after a DNS edit.
> **Audience:** Solo developer with Cloudflare dashboard access and API token.
> **References:** [ADR 0004 — DNS Records](../adr/0004-dns-records.md)

---

## Prerequisites

- Cloudflare API token with `Zone:DNS:Edit` and `Zone:DNS:Read` permissions
- Zone ID for bengaldesk.com (found in Cloudflare dashboard → Overview → right sidebar)
- `curl`, `dig`, and `jq` installed locally

Export the token — never paste it into scripts or commit files:

```bash
export CLOUDFLARE_API_TOKEN="your-api-token-here"
export CF_ZONE_ID="your-zone-id-here"
```

---

## Step 0 — Diagnose: Is It Actually DNS?

Before reverting anything, confirm the problem is DNS and not an application-level outage:

```bash
# Check what the world sees
 dig bengaldesk.com +short

# Check what Cloudflare thinks it should serve
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?name=bengaldesk.com" \
  | jq '.result[] | {type, name, content, proxied}'

# Check DNSSEC validation
dig +dnssec bengaldesk.com | head -20
```

**Decision:** If `dig` returns a Cloudflare anycast IP (e.g. 104.x.x.x or 172.67.x.x) and the site still doesn't load, the problem is likely the origin (Vercel), not DNS — switch to the Vercel deployment runbook instead. If `dig` returns no answer, NXDOMAIN, or a non-Cloudflare IP, proceed with rollback.

---

## Step 1 — Check Propagation Status

DNS changes propagate at different speeds depending on TTL and proxy status:

```bash
# Query multiple resolvers to see propagation spread

echo "=== Google DNS ===" && dig @8.8.8.8 bengaldesk.com +short
echo "=== Cloudflare DNS ===" && dig @1.1.1.1 bengaldesk.com +short
echo "=== Quad9 ===" && dig @9.9.9.9 bengaldesk.com +short
echo "=== Local resolver ===" && dig bengaldesk.com +short
```

- If all resolvers agree and return the **wrong** value, the change has fully propagated — rollback is needed.
- If resolvers disagree, propagation is still in progress — wait up to the old TTL before taking action. The default TTL for proxied Cloudflare records is 300s (5 minutes).

---

## Step 2 — Revert a Single Record via API

### 2a. List All Records (identify the broken one)

```bash
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
  | jq '.result[] | {id, type, name, content, proxied, ttl}'
```

Note the `id` of the record you need to revert.

### 2b. Update (Patch) a Record

Replace the `content`, `proxied`, or `ttl` with the correct values from [ADR 0004](../adr/0004-dns-records.md):

```bash
RECORD_ID="the-record-id-from-step-2a"

curl -s -X PATCH \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID" \
  --data '{
    "type": "A",
    "name": "bengaldesk.com",
    "content": "76.76.21.21",
    "ttl": 1,
    "proxied": true
  }' | jq '.success, .errors'
```

### 2c. Delete and Recreate (if the record type or name is wrong)

```bash
# Delete
curl -s -X DELETE \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID" \
  | jq '.success'

# Recreate with correct values
curl -s -X POST \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
  --data '{
    "type": "A",
    "name": "bengaldesk.com",
    "content": "76.76.21.21",
    "ttl": 1,
    "proxied": true
  }' | jq '.success, .errors'
```

### 2d. Verify the Fix

```bash
# Wait up to 5 minutes for Cloudflare propagation, then check
dig @1.1.1.1 bengaldesk.com +short
curl -sI https://bengaldesk.com | head -5
```

---

## Step 3 — Emergency Bypass: Unproxy (Grey-Cloud) a Record

If the Cloudflare proxy itself is causing the issue (e.g. WAF misconfiguration, edge error), bypass the proxy by switching the record to DNS-only (grey cloud):

```bash
RECORD_ID="the-a-record-id"

curl -s -X PATCH \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$RECORD_ID" \
  --data '{
    "type": "A",
    "name": "bengaldesk.com",
    "content": "76.76.21.21",
    "ttl": 300,
    "proxied": false
  }' | jq '.success'
```

**Consequences of unproxying:**
- HSTS header no longer served by Cloudflare edge (Vercel must serve it instead)
- Cloudflare WAF rules (Phase 1h) and rate limiting (Phase 1i) stop applying
- Origin IP (76.76.21.21 — Vercel anycast) is directly exposed in DNS responses
- Re-proxy once the root cause is identified and fixed

---

## Decision Tree

```
bengaldesk.com is unreachable
│
├── dig returns nothing or NXDOMAIN?
│   ├── YES → Record was deleted or name is wrong
│   │         → Recreate from ADR 0004 (Step 2c)
│   └── NO  → Continue below
│
├── dig returns wrong IP (not 104.x/172.67.x and not 76.76.21.21)?
│   ├── YES → Record content was changed
│   │         → Patch record content to ADR 0004 value (Step 2b)
│   └── NO  → Continue below
│
├── dig returns Cloudflare anycast IP but site still fails?
│   ├── Check: Is SSL/TLS mode Full (Strict)?
│   │   ├── NOT Full (Strict) → Fix in Cloudflare dashboard
│   │   └── YES → Continue below
│   ├── Check: Does origin (Vercel) return 200?
│   │   ├── NO  → Application-level issue, not DNS
│   │   └── YES → Continue below
│   └── Proxy/edge issue → Unproxy record (Step 3) as emergency bypass
│
└── dig returns correct Vercel IP (76.76.21.21) directly?
    → Record was accidentally unproxied
    → Re-proxy the record: patch proxied=true, ttl=1 (Step 2b)
```

---

## Post-Rollback Checklist

- [ ] `dig bengaldesk.com` returns expected IP
- [ ] `curl -sI https://bengaldesk.com` returns HTTP 200 or a valid redirect
- [ ] `dig +dnssec bengaldesk.com` includes `ad` flag (DNSSEC intact)
- [ ] `dig TXT bengaldesk.com` still contains SPF record
- [ ] `dig TXT _dmarc.bengaldesk.com` still contains DMARC record
- [ ] `dig CNAME resend._domainkey.bengaldesk.com` still resolves
- [ ] Update [ADR 0004](../adr/0004-dns-records.md) if any record values changed permanently
- [ ] Write a brief incident note in this file under **Incident Log** below

---

## Incident Log

| Date | Record Affected | Action Taken | Root Cause | Resolution Time |
|------|-----------------|--------------|------------|-----------------|
|      |                 |              |            |                 |