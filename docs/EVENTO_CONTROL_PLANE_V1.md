# EVENTO Control Plane V1

Status: implementation branch `feat/evento-control-plane-v1`

## Mission

Turn EVENTO into a phone-first operating system for Evento Project Development: customer requests, AI analysis, scope approval, delivery workflow, payments, revenue, team, agents, builds, deployments, marketing and risk from one secure control plane.

## Verified live baseline — 2026-08-11

- Supabase project: `Evento project 1` — active/healthy.
- Live tables: `project_requests`, `request_analyses`, `project_workflows`, `project_request_events`.
- Live Edge Functions: `analyze-request` and authenticated `workflow-transition`.
- Flutter mobile app uses Supabase and the implementation branch routes workflow transitions through the Edge Function instead of direct client RPC calls.
- Owner/admin authorization is backed by a private company-membership table and role-aware RLS.
- Anonymous users can use the demo/analysis path but are blocked from commercial workflow transitions.

## V1 dashboard access model

The control plane reads live Supabase data. RLS now applies a role-aware rule:

- EVENTO owner/admin/ops can read company-wide operational rows.
- Customers can read only their own rows.
- Infrastructure credentials never enter Flutter or browser clients.

Current live indicators include:

- project request count
- completed analysis count
- requests awaiting scope
- workflow count
- active workflow count
- project event count
- Supabase live/auth status

## Security work completed

1. Added `private.evento_company_memberships`.
2. Registered the current permanent company account as `owner` without hard-coding a generated Auth user ID in migration source.
3. Added private staff-role helpers for RLS.
4. Consolidated duplicate SELECT policies into one role-aware policy per table.
5. Added missing workflow foreign-key indexes.
6. Added a verified-account gate to commercial workflow transitions.
7. Restricted analysis finalization RPC execution to `service_role`.
8. Added the authenticated `workflow-transition` Edge Function.
9. Added atomic server-only `evento_transition_project_workflow_v1`, executable by `service_role` only.

## Verification completed

- Transactional smoke test verified `analyzed -> scope_review -> scope_approved` and rolled back the temporary test data.
- Anonymous transition smoke test verified `verified_account_required` before any commercial workflow write.
- Server-only atomic transition smoke test passed and rolled back the temporary data.
- Supabase performance advisors no longer report the previous duplicate-policy, Auth init-plan, or missing workflow foreign-key index warnings.

## Temporary compatibility boundary

The legacy public `start_project_workflow` and `approve_project_scope` RPC functions remain callable by verified authenticated users until this branch is promoted into the release path. They enforce ownership, state checks and the verified-account gate.

After the new mobile client path is accepted, revoke their `authenticated` EXECUTE grants. That will remove the remaining public SECURITY DEFINER compatibility warnings.

## Remaining production gates

1. Enable Supabase leaked-password protection in Auth settings.
2. Decide whether anonymous demo sign-ins remain in the production acquisition funnel. If retained, add CAPTCHA/Turnstile and rate-limit controls.
3. Promote the Edge Function client path, then revoke legacy workflow RPC client access.
4. Add quotes/pricing, approval and Build Queue after `scope_approved`.
5. Add customer support/refund cases and audit history.
6. Add payment and revenue ledger; payment secrets and webhooks stay server-side.
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
