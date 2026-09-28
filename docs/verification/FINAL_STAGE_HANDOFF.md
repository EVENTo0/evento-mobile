# Mobile acceptance and final activation

The PR verification workflow builds a demo APK with no backend defines and no
hosted credentials. It does not publish a release, run EAS, send email, access
Stripe, or update the production database. Flutter remains pinned to 3.44.9.

## Fresh local verification (2026-09-28 UTC / 29 September Dubai)

- Flutter 3.44.9 / Dart 3.12.2: analyze PASS, 15/15 tests PASS.
- Android wrapper generated from that SDK and compileSdk/targetSdk set to 36.
- API 36 transformation checks: 3/3 PASS, including changed-template denial.
- Committed `pubspec.lock` for reproducible dependency resolution.
- No local Android SDK/device is available: APK build and manifest proof must
  come from the new PR workflow. A local wrapper check is not an APK test.

## Acceptance evidence

| Gate | Required evidence |
| --- | --- |
| Source | Flutter analyze and all tests on the exact PR head |
| Android | Generated wrapper pins compileSdk/targetSdk 36; inspect built APK |
| Device | Install the same APK on physical Android; AR/EN, navigation, resume |
| Auth | Fresh sign-in, sign-out and denied unauthorized/cross-user access |
| Payment | Server-owned Stripe TEST result, duplicate webhook protection |
| Delivery | Request → scope → test payment → preview → acceptance → delivery |

An APK build cannot satisfy physical-device or authenticated-backend gates.
Test mode must remain visible. Missing credentials do not turn a gate green.

## Authority contract v1

- Website owns acquisition and the original lead record.
- EVENTO ONE owns customers, bookings, quotations, invoices and SaaS billing.
- Mobile is a client of versioned APIs; it cannot confirm payments locally.
- OCTA owns founder orchestration only.
- Existing `project_requests` / `project_workflows` RPCs are a legacy integration.
  They require an explicit compatibility mapping to EVENTO ONE before a live
  production binding. Do not copy customer or payment tables to mobile.

## Final activation inputs

After software verification: choose the approved backend/project, bind only a
publishable frontend key, supply test accounts securely, run the authenticated
tenant journey and a Stripe TEST transaction, then perform physical-device
acceptance. Hostinger/DNS, production credentials, live Stripe, release signing
and store publishing belong to the final activation stage. No secret belongs
in this document or in a client bundle.

Official Android requirement checked 2026-09-28 UTC:
https://developer.android.com/google/play/requirements/target-sdk


## Separate ONE read-client foundation branch

The new native `EventoOneApiClient` is intentionally opt-in and is not instantiated by `lib/main.dart`, RC6 or any existing entrypoint. The current entrypoints still use historical Supabase project-request contracts. Default-entry initialization now displays TEST, not LIVE; DEMO remains unconfigured mode. See `docs/authority/ONE_READ_CLIENT_V1.md` for delivered transport checks and remaining **code adoption** work. Hosted values alone do not complete this integration.
