# WAF False Positive Runbook

> **Purpose:** Diagnose and fix a legitimate user (e.g., a journalist on a VPN) who is blocked or challenged by the WAF rules documented in [ADR 0009](../adr/0009-waf-rules.md).
> **Audience:** Solo developer with Cloudflare dashboard access.

---

## Symptoms

A legitimate user reports one of:
1. **Persistent challenge page** — they see a Cloudflare "Verify you are human" page every time they visit /dashboard or /admin, even after passing it.
2. **Hard block** — they see a Cloudflare block page (HTTP 403/429) and cannot access /dashboard or /admin at all.
3. **Intermittent blocking** — access works sometimes but fails at random, usually after rapid navigation.

## Step 1 — Identify Which Rule Triggered

### Via Cloudflare Dashboard

1. Go to **Cloudflare Dashboard → bengaldesk.com → Security → WAF → Events**
2. Filter by the user's IP address (ask them for it, or check Vercel logs for their last known IP)
3. The **Rule** column shows which of the three rules matched
4. The **Action** column shows the result (Managed Challenge, Block)

### Via User Report

Ask the user:
- Are they using a VPN or proxy? (VPN exits often have low bot scores)
- Are they behind a corporate firewall? (Some corporate proxies strip cookies, breaking Managed Challenge sessions)
- What browser and version? (Very old browsers may fail JS challenges)
- Can they access the public homepage (/) normally? (If yes, the issue is specific to /admin or /dashboard rules)

## Step 2 — Immediate Fix (Unblock the User)

### Option A: Add IP to WAF Allow List

If the user has a static IP (office, home fiber):

1. **Cloudflare Dashboard → Security → WAF → Tools → IP Access Rules**
2. Add the user's IP
3. Set action to **Allow**
4. Set zone to `bengaldesk.com`
5. Save

> **Warning:** This bypasses ALL WAF rules for that IP, not just the false-positive one. Use only for trusted, static IPs.

### Option B: Skip Rules for a Known Good Session

If the user has a dynamic IP (mobile data, residential ISP):

1. Have the user clear their Cloudflare cookies for bengaldesk.com
2. Have them retry the page in a fresh private/incognito window
3. If they pass the Managed Challenge once, they should be cookied and not challenged again for the session

### Option C: Temporarily Disable the Triggering Rule

If multiple users are affected (indicating a systematic false positive, not an individual one):

1. **Cloudflare Dashboard → Security → WAF → Custom Rules**
2. Set the triggering rule's status to **Disabled**
3. Investigate root cause (Step 3)
4. Re-enable after fixing

> **Risk:** While disabled, the affected path has zero WAF protection. Re-enable as quickly as possible.

## Step 3 — Root Cause Diagnosis

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| User on VPN with low bot score | VPN exit IP is shared with bots, Cloudflare scores it low | Option A (IP allow list) or adjust bot score threshold in ADR 0009 |
| User on corporate proxy | Proxy strips cookies, breaking challenge session | Option A (IP allow list) for the corporate IP range |
| Intermittent after rapid navigation | User triggered Rule 3's 30 req/min rate limit | This is working as intended — explain the rate limit to the user |
| Persistent challenge every page load | Browser is blocking the challenge JS (privacy extension, strict content policy) | User must allow Cloudflare's challenge scripts or use a different browser |
| Legitimate API client blocked | An API integration (not a browser) hits /dashboard or /admin | Create a WAF exception for the API client's IP or user-agent |

## Step 4 — Tune Thresholds (If Systematic)

If false positives affect multiple users, consider adjusting the bot score threshold:

1. **Current threshold:** `cf.bot_management.score lt 30` (Rules 1 and 2)
2. **Lower the threshold** (e.g., to 20) to be less aggressive — fewer challenges but more bots pass
3. **Raise the threshold** (e.g., to 40) to be more aggressive — more challenges but fewer bots pass
4. After adjusting, update [ADR 0009](../adr/0009-waf-rules.md) with the new value and the date/reason for the change

> **Do not change thresholds based on a single user report.** Wait for a pattern (3+ independent reports) before adjusting.

## Step 5 — Escalation

If false positives persist after threshold tuning:

1. Consider switching from Managed Challenge to **JS Challenge** for Rules 1–2 (less aggressive, only tests JavaScript execution)
2. Consider adding the affected users to a Cloudflare Access group (requires Cloudflare Zero Trust, which is free for up to 50 users)
3. If the problem is VPN-related and affects a significant reader/journalist population in Bangladesh, investigate whether a specific VPN provider's exit IPs are consistently low-scored and request a Cloudflare bot management review

## Post-Incident

- [ ] Update [ADR 0009](../adr/0009-waf-rules.md) if any threshold was changed
- [ ] Add the incident to the WAF incident log below
- [ ] If a new IP allow list entry was added, document it in a secure location (not the repo)

## Incident Log

| Date | User/IP | Rule Triggered | Symptom | Resolution | Threshold Changed? |
|------|---------|----------------|---------|------------|-------------------|
|      |         |                |         |            |                   |