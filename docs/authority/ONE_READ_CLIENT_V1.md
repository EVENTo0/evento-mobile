# EVENTO ONE native read client foundation

Task AUTHORITY-MOBILE-V1 — authorized separate branch, based on Mobile PR #9 `1148c5b9aaa57df98f556c5fa71038fb0edaabf4`. PR #9 and its verified entrypoints are not moved by this branch.

## Delivered code

`lib/data/one/evento_one_client.dart` is an opt-in native Dart HTTP client for the real EVENTO ONE v1 member read API in [ONE PR #4](https://github.com/EVENTo0/Evento-One/pull/4). `context()`, `bookings()`, `quotations()` and `invoices()` return typed immutable summary projections. Existing customer/payment state is read from ONE; no copied ledger, invoice mutation, legacy request mapping, payment confirmation or second customer database is introduced.

The constructor requires explicit `EventoBackendMode.one`, an HTTPS API origin, a separate ONE Auth origin and an access-token provider. HTTP loopback is available only through the explicit local-development flag. It rejects missing, privileged-role or wrong-issuer tokens before network, does not follow redirects, sends a Bearer header only to the chosen origin, limits response size and count, and rejects incorrect API/resource/organization envelopes. JWT issuer/role decoding is only a routing guard: the server verifies signature, current identity, active membership and RLS. It cannot be used as authorization evidence.

The default `lib/main.dart` indicator now says TEST when its legacy backend SDK initializes, or DEMO without configuration. A successful SDK initialization is not hosted Auth, backend reachability, final release or payment acceptance. Related visible text uses test-backend wording. This is a label correction without a new screen or account flow.

## Entry points and remaining adoption

| Entry | Actual behavior after this branch |
| --- | --- |
| `lib/main.dart` | Existing historical Supabase Auth and direct `project_requests`/`analyze-request` path; TEST/DEMO label |
| `lib/main_rc6.dart` → `lib/rc6_app.dart` | Existing historical `SupabaseProjectRequestRepository` and request/workflow RPCs |
| `lib/data/one/evento_one_client.dart` | New opt-in library only; no entrypoint instantiates it yet |

The inspected development defines point to historical Supabase project `jaxhaiaftpegcodkzaus`. The pinned demo APK CI has no backend defines. Neither legacy OTP identities nor `project_requests` can be turned into ONE memberships/bookings by changing a URL.

Full adoption is **pending code work**: ONE sign-in/session lifecycle, explicit backend selection in an entrypoint, organization/member navigation, UI read states and logout/suspension clearing. End-customer access requires a separate customer identity/access mapping; this operator/member API must not be exposed as a customer portal merely by hiding screens. Website qualified-lead handoff/write/replay remains another code gap. Final hosted/physical-device/Stripe TEST evidence remains separate.

## Verification

The eight new contract/transport tests use a synthetic local HTTP server. They verify exact real API paths and GET semantics, typed projections, ONE issuer separation, invalid version/tenant/limit rejection, redirect denial and sanitized errors. They do **not** authenticate against hosted or local Supabase and do not establish a Mobile→ONE E2E journey. The ONE producer's separate real Auth/RLS/HTTP evidence is in its PR #4.

The additional widget regression renders the actual status indicator for TEST and DEMO and checks absence of LIVE. Run:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test --reporter expanded
```

Local verification on Flutter 3.44.9 / Dart 3.12.2: analysis PASS and 24/24 Flutter tests PASS (15 existing + 8 new transport/model cases + 1 status-indicator regression). These counts are test evidence, not project completion percentages.

No dependency or lockfile changes are needed. Rollback is removal of the two new library files/test/doc and reversal of the status wording. No hosted setup, account creation, publication, store update or merge is performed.
