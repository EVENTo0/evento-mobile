# EVENTO Control Plane V1

Status: implementation branch `feat/evento-control-plane-v1`

## Mission

Turn EVENTO into a phone-first operating system for Evento Project Development: customer requests, AI analysis, scope approval, delivery workflow, payments, revenue, team, agents, builds, deployments, marketing and risk from one secure control plane.

## Verified live baseline — 2026-08-11

- Supabase project: `Evento project 1` — active/healthy.
- Live tables: `project_requests`, `request_analyses`, `project_workflows`, `project_request_events`.
- Live Edge Function: `analyze-request`.
- Existing request flow reaches analysis; workflow activation exists server-side.
- Flutter mobile app uses Supabase and already includes RC6 workflow controls.
- V1 control-plane screen reads live metrics allowed by current RLS policies.

## V1 dashboard

The first dashboard slice intentionally contains no privileged company-wide bypass. It reports only rows visible to the signed-in user:

- project request count
- completed analysis count
- requests awaiting scope
- workflow count
- active workflow count
- project event count
- Supabase live/auth status

## Next secure slices

1. Owner/Admin authorization model using `app_metadata` or a dedicated membership/role table; never `user_metadata`.
2. Admin KPI RPC/view layer with explicit authorization and audit logging.
3. Quotes, approvals and Build Queue after `scope_approved`.
4. Customer records, support/refund cases and SLA tracking.
5. Payments and revenue ledger (Stripe/Tap/Apple Pay integrations server-side only).
6. GitHub project/build/PR status and deployment previews.
7. Vercel/Hostinger/WordPress operational status connectors.
8. AI/agent run registry, cost, success rate and human approval gates.
9. Marketing campaigns, leads, conversion funnel and attribution.
10. Risk register, incidents, backups, security advisories and operational score.

## Platform recommendation

- `evento.ae` or the company's owned primary domain: customer-facing EVENTO website.
- `app.<primary-domain>`: customer portal and project tracking.
- `ops.<primary-domain>`: private owner/team Control Plane.
- Supabase: primary operational database, Auth, storage and server functions.
- Vercel: preferred deployment/preview plane for modern Next.js control surfaces.
- Hostinger: keep domains, email and existing WordPress assets where useful; do not make WordPress the source of truth for operational data.
- Flutter app: phone-first EVENTO customer + owner companion; production admin actions require stronger authorization than ordinary customer RLS.

## Release gates

V1 is not considered production-owner-ready until:

- Supabase security advisors are reviewed and high-risk findings resolved or explicitly justified.
- Administrative access cannot be obtained through editable user metadata.
- Payment secrets and webhook verification remain server-side.
- Customer refund/support actions are audited.
- CI produces a reproducible phone artifact.
- A live preview demonstrates requests -> analysis -> scope -> quote -> approval -> build queue.
- Backup/recovery and incident runbooks exist.
