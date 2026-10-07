# EVENTO ONE Hosted + Physical Device Proof V1

This gate proves the already-merged Mobile ↔ EVENTO ONE login/read path against the configured hosted TEST tenant and then on a real Android device. It does not add write/payment/customer-self-service scope and it does not authorize store release.

## Authority boundary

- Source of product behavior: `main`.
- Hosted build source must be an exact commit SHA from `main`.
- Provider values are supplied only through the protected GitHub Environment `g3-integrated-acceptance`.
- Only public/publishable provider configuration may enter the APK.
- Passwords, access tokens, service-role keys, secret keys, customer data exports and production credentials are forbidden as build inputs or evidence.
- Stripe and store publishing are outside this gate.

## Required hosted preview evidence

The manual workflow `EVENTO Mobile ONE Preview Build` must produce:

- exact source SHA;
- API 36 target verification;
- SHA-256 of the configured TEST APK;
- build target `lib/main_one.dart`;
- backend mode `one`;
- proof that provider configuration was supplied without exposing its values;
- signing mode recorded as Android debug/test only;
- explicit flags stating that hosted login and physical-device proof are not claimed by the build alone.

A successful build is **PREVIEW_BUILD_READY**, not end-to-end proof.

## Physical-device acceptance matrix

Run the configured TEST APK on a real Android device. Record no passwords or tokens.

| ID | Check | PASS requirement |
| --- | --- | --- |
| D1 | Install/launch | APK installs and opens the ONE TEST entry without legacy fallback. |
| D2 | Password login | A real permitted member can sign in through hosted Supabase Auth. |
| D3 | Actor binding | Returned ONE context actor matches the authenticated hosted user. |
| D4 | Membership A | First real permitted organization loads bounded booking/quotation/invoice summaries. |
| D5 | Membership B | A second real permitted organization can be selected and data changes tenant correctly. |
| D6 | Cross-tenant isolation | No records from the prior organization remain visible after switch. |
| D7 | Denied session | A non-member/denied path returns a sanitized denied state with no protected data. |
| D8 | Expired session | Expiry/401 returns to signed-out state and clears visible data. |
| D9 | Background/resume | Backgrounding hides protected lists; resume revalidates membership before showing data again. |
| D10 | Logout | Logout clears identity, selected organization and all lists; stale token reuse is blocked. |
| D11 | App switcher | Verify sensitive data is not unintentionally exposed in the Android recent-apps/app-switcher surface; record actual observed behavior. |
| D12 | Network failure | Temporary outage shows sanitized unavailable/retry UI and no stale cross-tenant data. |

## Evidence record

Store only non-secret evidence:

- source SHA;
- Preview workflow run ID;
- APK SHA-256;
- device manufacturer/model;
- Android version/API;
- UTC test timestamp;
- tester identifier or role;
- D1–D12 PASS/FAIL;
- screenshots only where they contain no credentials, tokens, personal customer data or secrets;
- short sanitized failure notes.

## Final states

- `BLOCKED`: configured preview cannot be produced, or any mandatory device check fails.
- `PREVIEW_BUILD_READY`: configured TEST APK built successfully, but no complete real-device proof yet.
- `DEVICE_VERIFIED`: D1–D12 all pass on a real device using the hosted TEST tenant.
- `MOBILE_ONE_E2E_VERIFIED`: DEVICE_VERIFIED plus the corresponding hosted EVENTO ONE Auth/API tenant evidence is linked and source SHAs are recorded.

None of these states authorize production deployment, payment activation, signing/release-channel enablement, Play Store upload or customer production use.
