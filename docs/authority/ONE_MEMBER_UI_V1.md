# ONE member read UI

This change adopts the typed EVENTO ONE v1 client in a real Flutter entry point,
`lib/main_one.dart`. It is an operator/member read workspace for existing active
organization roles. It does not create a customer, booking, quotation, invoice,
payment, or legacy `project_requests` record.

## Entry and final configuration

The safe default is an unconfigured TEST screen. No provider is initialized and no
sign-in form is enabled until **all** explicit ONE values are valid. The legacy
`SUPABASE_URL` / `SUPABASE_ANON_KEY` are never used by this entry point.

For the final configured test build, supply an untracked JSON build configuration
with these exact keys through Flutter's `--dart-define-from-file`:

| Key | Meaning |
| --- | --- |
| `EVENTO_BACKEND_MODE` | Exactly `one` |
| `EVENTO_ONE_API_ORIGIN` | HTTPS origin serving the reviewed ONE v1 routes |
| `EVENTO_ONE_SUPABASE_URL` | The matching ONE Supabase Auth HTTPS origin |
| `EVENTO_ONE_PUBLISHABLE_KEY` | Public publishable key or legacy anon key, never a secret/service key |

Run `flutter run -t lib/main_one.dart --dart-define-from-file=<untracked-config.json>`.
Configuration is compiled into the app; public provider configuration is not a
secret store. Passwords and tokens must never be build defines. This PR does not
add, rotate, or store any hosted credentials. HTTP, credential-bearing origins,
subpaths, fragments, query strings, missing mode, and privileged keys fail closed.

`lib/main.dart` remains the separate legacy/demo entry; `lib/main_rc6.dart` remains
the separate RC6 demo. Neither is silently switched to ONE. The new dedicated
entry has its own TEST indicator, never a LIVE state or legacy fallback.

## Implemented behavior

- Dedicated `SupabaseClient`, independent of `Supabase.instance`, with password
  login plus server `getUser` verification. Its verified actor must match the API
  context. The typed client restricts token issuer to the configured ONE origin.
- Memory-only identity and lists; no session persistence or silent refresh.
  App restart or expiry requires login again. Password input is cleared on submit.
- Organization selection comes only from `/api/v1/context`; active membership,
  organization status, role and RLS authorization remain enforced by the ONE API.
- Read screens for bounded booking, quotation and invoice summaries. Invoice
  balances are displayed from ONE, never locally interpreted as payment proof.
- Loading, no-membership, empty list, denied, unavailable, retry, logout and
  session-expiry states. User-visible errors never include raw provider responses.
- Switching organization, refresh, denial and logout clear visible data. Generation
  checks discard late results from a prior tenant/session. Backgrounding hides
  lists; resuming forces membership refresh even if an older read is pending.
  OS app-switcher capture behavior still needs physical-device verification.

## Evidence and its limits

Local Flutter 3.44.9 / Dart 3.12.2 verification: source analysis found no issues,
42/42 Flutter tests passed (24 baseline + 18 adoption tests), and all three Android
wrapper transformation tests passed. Final CI results and artifact links are
recorded in the PR body to avoid changing the tested source for report updates.

`one_member_controller_test.dart` tests configuration, membership selection,
cross-tenant late responses, unknown organization denial, 401/403/503 handling,
logout/expiry, resume revalidation and sanitized login failure.
`one_member_app_test.dart` renders the real widgets for login, three read views,
tenant selection, denial/retry, expiry, empty membership/list and lifecycle states.
Optional PNG evidence comes from those actual Flutter widget renders using
explicitly synthetic fixtures; it is not a hosted or physical-device screenshot.

`one_member_gateway_test.dart` executes the pinned Supabase SDK and actual typed
API client against a loopback wire fixture. It verifies the precise Auth token,
user and logout paths, the distinct ONE API origin, actor mismatch denial, typed
records and blocked token reuse after logout. Auth responses are synthetic in
this fixture: it is transport/adoption evidence, not an independent Auth/RLS proof.

The producer API has separate real isolated Supabase Auth/RLS/production-HTTP
evidence in EVENTO ONE PR #4, source `cd4630073905674976e71fb35bade6fff449b089`,
run `36491752661` (17 v1 checks). This PR does not convert that into a hosted mobile
E2E claim. The final configured device test must verify password login against
that deployed API, two actual member organizations, denied/expired sessions,
background/resume, and logout over the real network.

CI analyzes the full source, runs the Flutter suite, generates the pinned API36
wrapper and builds both the existing RC6 demo and the new unconfigured ONE TEST
APK. The ONE APK is unsigned for production (debug signing), contains no supplied
provider defines, and is retained in a GitHub artifact for seven days, not in git.
Its provenance records the exact PR head and API36 result. It intentionally cannot
sign in until a separately configured test build is prepared at the final setup
stage. Store publication, live payments, writes, customer self-service, hosted
provider setup and physical-device evidence remain outside this software gate.
