# EVENTO Control Plane V1

Status: implementation branch `feat/evento-control-plane-v1`

## Mission

Turn EVENTO into a phone-first operating system for Evento Project Development: customer requests, AI analysis, scope approval, quotations, payments, delivery workflow, revenue, team, agents, builds, deployments, marketing and risk from one secure control plane.

## Verified live baseline — 2026-08-11

- Supabase project: `Evento project 1` — active/healthy.
- Live core tables: `project_requests`, `request_analyses`, `project_workflows`, `project_request_events`.
- Live commercial tables: `project_quotes`, `project_build_queue`.
- Live Edge Functions: `analyze-request`, authenticated `workflow-transition`, authenticated `quote-action`.
- Flutter mobile app routes workflow transitions through the Edge Function instead of direct client RPC calls on this branch.
- Owner/admin authorization is backed by a private company-membership table and role-aware RLS.
- Anonymous users can use the demo/analysis path but are blocked from commercial workflow and quotation gates.

## V1 dashboard access model

The Control Plane reads live Supabase data with role-aware RLS:

- EVENTO owner/admin/ops can read company-wide operational rows.
- Customers can read only their own rows.
- Quotes and Build Queue require a non-anonymous account.
- Infrastructure credentials never enter Flutter or browser clients.

Current live indicators include:

- project request count
- completed analysis count
- requests awaiting scope
- workflow count and active workflow count
- quote count and accepted quote count
- pending-payment count
- Build Queue count
- accepted quote value in AED
- project event count
- Supabase live/auth status

The preview app also includes an owner-facing Quote Center for preparing/updating a quotation and sending it to the customer.

## Customer commercial flow

The RC6 workflow UI now supports the customer side of the quote lifecycle:

1. Verified customer starts Workflow after analysis.
2. Customer approves scope.
3. EVENTO prepares a quote in Quote Center.
4. EVENTO sends the quote.
5. Customer sees quote code, total AED and validity in the phone workflow UI.
6. Customer accepts the quote.
7. The project enters `project_build_queue` as `pending_payment`.
8. Build does not start until a future payment-confirmation gate promotes it.

## Security work completed

1. Added `private.evento_company_memberships`.
2. Registered the current permanent company account as `owner` without hard-coding a generated Auth user ID in migration source.
3. Added private staff-role helpers for RLS.
4. Consolidated duplicate SELECT policies into one role-aware policy per table.
5. Added missing workflow foreign-key indexes.
6. Added a verified-account gate to commercial workflow transitions.
7. Restricted analysis finalization RPC execution to `service_role`.
8. Added authenticated `workflow-transition` and `quote-action` Edge Functions.
9. Added atomic server-only workflow transition logic executable by `service_role` only.
10. Added server-only quote draft/send/accept functions.
11. Added a verified-customer gate so anonymous requests cannot receive commercial quotations.
12. Added RLS-protected quote and Build Queue tables.

## Verification completed

- Transactional smoke test verified `analyzed -> scope_review -> scope_approved` and rolled back temporary data.
- Anonymous workflow transition test verified `verified_account_required` before any commercial write.
- Server-only atomic workflow transition smoke test passed and rolled back.
- Quote transaction test verified `scope_approved -> quote_draft -> quote_sent -> quote_approved -> pending_payment`, including price arithmetic, and rolled back.
- Anonymous-customer quotation test verified `verified_customer_required` and rolled back.
- Production remains clean after tests: existing customer data was not altered by the smoke tests.
- Supabase performance advisors no longer report the previous duplicate-policy, Auth init-plan, or missing workflow foreign-key index warnings.

## CI gate

The Control Plane CI now covers the revenue-path files instead of only the dashboard:

- targeted Flutter analysis for Control Plane, RC6 workflow, repository and quote/workflow domain models
- RC6 workflow tests
- project quote model test
- Android Control Plane preview APK build
- APK artifact upload with SHA-256 handoff

## Temporary compatibility boundary

The legacy public `start_project_workflow` and `approve_project_scope` RPC functions remain callable by verified authenticated users until this branch is promoted into the release path. They enforce ownership, state checks and the verified-account gate.

After the new mobile client path is accepted, revoke their `authenticated` EXECUTE grants. That will remove the remaining public SECURITY DEFINER compatibility warnings.

## Remaining production gates

1. Latest expanded CI run must complete green and produce the new APK.
2. Enable Supabase leaked-password protection in Auth settings.
3. Decide whether anonymous demo sign-ins remain in the production acquisition funnel. If retained, add CAPTCHA/Turnstile and rate-limit controls.
4. Promote the Edge Function client path, then revoke legacy workflow RPC client access.
5. Implement payment ledger/provider webhooks and only then promote `pending_payment -> queued`.
6. Add customer support/refund cases and audit history.
7. Add GitHub/Vercel/Hostinger operational connectors to the normalized Control Plane read model.
8. Add agent-run registry, cost, success rate and approval gates.
9. Add marketing attribution, conversion funnel and risk/incident views.

## Revenue-engine sequence

`Lead -> Request -> AI Analysis -> Scope -> Quote -> Approval -> Payment -> Build Queue -> Build -> QA -> Preview -> Revision -> Delivery -> Rating -> Support`

## Platform recommendation

- Company's owned primary EVENTO domain: customer-facing website.
- `app.<primary-domain>`: customer portal and project tracking.
- `ops.<primary-domain>`: private owner/team Control Plane.
- Supabase: operational database, Auth, storage and server functions.
- Vercel: modern web/admin/customer portal deployments and previews where appropriate.
- Hostinger: domains, DNS, existing hosting/WordPress, mail and owned infrastructure after inventory reconciliation.
- Flutter: phone-first EVENTO customer + owner companion.
