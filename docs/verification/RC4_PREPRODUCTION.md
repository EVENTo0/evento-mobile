# EVENTO RC4 Pre-Production Verification

## Purpose
RC4 moves the verified phone-first Live Beta from request creation only to a customer-visible live request detail experience.

## Verified baseline before RC4
- Android app installed on the owner's physical Android phone.
- Persistent EVENTO Dev signing certificate established.
- GitHub Actions -> APK -> dev-latest -> phone update loop established.
- Supabase project `Evento project  1` is live.
- Anonymous Live Beta session created successfully.
- First real request `EVT-260809-0BF317` created from the physical phone.
- Server analysis completed and status moved from `draft` to `analyzed`.
- Timeline contains `Request created.` and `Initial server analysis completed.`.

## RC4 additions
- Dedicated `lib/main_rc4.dart` entrypoint.
- Live request detail page.
- Reads `request_analyses` through owner-scoped RLS.
- Reads `project_request_events` through owner-scoped RLS.
- Displays server complexity, summary, proposed MVP scope, risks, engine version and timeline.
- Keeps anonymous quick sign-in limited to Live Beta testing.
- Keeps the 50-item customer-safe project catalog.

## Release gates
1. `flutter analyze` has no issues.
2. All Flutter tests pass, including RC4 tests.
3. APK builds using Flutter 3.44.9.
4. Application ID equals `ae.evento.evento_mobile`.
5. Android versionCode is greater than the installed RC3 baseline.
6. APK certificate SHA-256 equals the persistent EVENTO Dev certificate.
7. `dev-latest` points to the RC4 build.
8. Existing phone installation accepts RC4 as an Update without uninstalling.
9. Existing anonymous session survives the update.
10. Existing request `EVT-260809-0BF317` appears under My live requests.
11. Opening it shows server analysis and both timeline events.

## Security notes
Anonymous users use the `authenticated` Postgres role. During Live Beta, owner-scoped RLS permits each anonymous user to see only their own request, analysis and events. The client has SELECT-only access to analysis/events and no UPDATE grant on the request `status` column.

Before Production, anonymous quick sign-in will be removed or restricted, CAPTCHA/Turnstile will be considered, and a permanent identity method such as Google/Apple will be enabled.
