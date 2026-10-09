# EVENTO Hostinger Control Plane

Status: approved integration design for EVENTO Control Plane V1.

## Purpose

Hostinger is the infrastructure/account control layer for EVENTO. Use it to inventory and manage the Hostinger products actually owned by the company: hosting/websites, domains and DNS, subscriptions and billing, email marketing, VPS, Ecommerce, WordPress capabilities exposed by the Hostinger connector, and Hostinger Email where provisioned.

## Security

- Never commit Hostinger credentials to GitHub.
- Never embed Hostinger credentials in Flutter, browser clients, APK/IPA files, screenshots, logs, or public environment variables.
- Interactive owner/admin sessions should prefer OAuth when supported.
- Automation should use a revocable credential held only in an approved secret store.
- Any credential exposed in chat, source code, issues, or documentation must be rotated before production use.

## EVENTO architecture

- Hostinger: domains, DNS, existing hosting/WordPress, subscriptions, marketing, VPS/Ecommerce, and company email where used.
- Supabase: customers, requests, workflows, quotes, payment ledger, support/refund cases, audit events and app authorization/data.
- Vercel: website/admin/customer portal deployments and preview URLs where appropriate.
- GitHub: source control, PRs, CI, builds, release evidence and automation definitions.
- evento-mobile: phone-first owner/customer UI. It never holds infrastructure credentials.

## MCP scope

Prefer product-scoped Hostinger MCP services when practical so agents only see the infrastructure area needed for the current task. The user-provided setup includes hosting, domains, DNS, billing, Reach, VPS and Ecommerce scopes.

WordPress is a Hostinger MCP product surface, but the current official package documentation should be checked before assuming a standalone executable name. Hostinger Email uses its own Mail API/MCP service and can require an email-order-scoped credential.

## Control Plane read model

The EVENTO app should show normalized operational status instead of calling Hostinger directly from the mobile client:

- Domains: domain, expiry, renewal state, DNS health, SSL state, linked EVENTO project.
- Websites: domain, hosting plan, WordPress/non-WordPress, production URL, health and backup/deployment state.
- Email: official mailbox inventory and health; message contents are outside the general company dashboard unless explicitly authorized.
- Billing: active Hostinger subscriptions, renewal dates and infrastructure cost totals.
- VPS: health plus CPU/RAM/disk/network summaries and incidents.
- Marketing: account/campaign status and later aggregated performance metrics.
- Ecommerce: store/account status when EVENTO uses that Hostinger product.

## Permission model

- Owner: full inventory visibility; high-impact actions require explicit confirmation.
- Admin/Ops: operational reads and approved maintenance actions.
- Finance: billing/subscription read scope.
- Marketing: marketing scope only.
- Developer/Agent: minimum scope required for the current job.
- Customer: no Hostinger infrastructure access.

High-impact actions such as replacing DNS, transferring domains, cancelling subscriptions, rebuilding VPS instances, deleting mailboxes, or deleting production sites require explicit owner approval and audit logging.

## Rollout

1. Rotate any credential exposed outside a secret store.
2. Connect Hostinger MCP in the owner development environment using OAuth or a fresh credential.
3. Run read-only inventory first across domains, DNS, websites/hosting, subscriptions, VPS and enabled products.
4. Identify the official EVENTO domain and existing official mailboxes before purchasing anything new.
5. Map each live domain/site to an EVENTO project record.
6. Add Hostinger status cards to EVENTO Control Plane.
7. Enable only carefully scoped write actions after inventory and audit controls are in place.

## Production rule

Do not purchase a replacement domain, hosting plan, mailbox, VPS or related subscription until the live Hostinger inventory has been reconciled. Reuse existing official company assets where appropriate and avoid duplicate spending.
