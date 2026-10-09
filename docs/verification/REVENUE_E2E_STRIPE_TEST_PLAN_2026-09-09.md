# EVENTO revenue E2E and mobile gate plan — 2026-09-09

## Scope and safety lock

Test the first-sale chain in non-production only:

`lead → staff review → quote → contract acceptance → Stripe TEST Checkout/PaymentIntent → verified webhook → mobile reconciliation`

No live Stripe keys, live charge, production database mutation, production deployment, DNS change, store publication, or automatic customer communication is permitted. Synthetic identities must use `example.invalid`; synthetic rows must be traceable and removed after evidence capture.

## Gate matrix

| Gate | Scenario | Required evidence | Pass condition |
|---|---|---|---|
| E2E-01 | Valid bilingual lead | Preview request reference and staff-visible record | One idempotent lead; no PII in logs |
| E2E-02 | Access boundary | anonymous, invalid, non-staff, inactive staff | all rejected; active staff lists/opens only bounded fields |
| E2E-03 | Quote | staff creates TEST quote for synthetic lead | immutable amount/currency/version and accountable actor |
| E2E-04 | Contract | synthetic customer accepts exact quote/contract version | acceptance timestamp and version link; no build activation yet |
| E2E-05 | Stripe TEST success | Stripe test card and signed test webhook | server-created payment; webhook signature verified; one reconciliation |
| E2E-06 | Stripe TEST failures | decline, expiry, duplicate/replayed/out-of-order webhook | no paid state on failure; replay is idempotent |
| E2E-07 | Mobile reconciliation | RC build refreshes the synthetic request | mobile matches server state and cannot skip workflow stages |
| E2E-08 | Cleanup/recovery | remove synthetic fixtures and exercise rollback notes | zero retained test PII; audit/evidence remains non-sensitive |

## Android API 36 and device gates

1. Static gate: `compileSdkVersion=36`, `targetSdkVersion=36`, package `ae.evento.evento_mobile`, non-production entrypoint, and no live Stripe identifier in source or artifact.
2. Build gate: clean signed development APK/AAB from the source-linked branch; artifact checksum and workflow run recorded.
3. Install gate: in-place upgrade from the last accepted RC plus clean install on a second test device/emulator.
4. Device gate: Arabic RTL and English LTR, rotation, offline/online recovery, background/resume, deep-link rejection, and request/quote/payment-status refresh.
5. Stripe TEST gate: success, decline, cancellation, delayed webhook, duplicate webhook, and app restart during reconciliation. The mobile client never owns a Stripe secret and never declares payment complete from client state alone.
6. Evidence gate: Android version, device model/OS, commit SHA, artifact checksum, test timestamp, screenshots/log excerpts without secrets or customer data, failures, and rollback result.

## Commands for the approved build environment

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --target lib/rc6_main.dart
apkanalyzer manifest sdk .\build\app\outputs\flutter-apk\app-debug.apk
adb install -r .\build\app\outputs\flutter-apk\app-debug.apk
adb shell am force-stop ae.evento.evento_mobile
adb shell monkey -p ae.evento.evento_mobile 1
```

Use only Stripe TEST credentials supplied through protected CI/environment secrets. Run webhook scenarios from Stripe's supported test tooling against a non-production endpoint; never paste secrets into issues, PRs, screenshots, or the app.

## Current evidence and blockers

- Existing RC6 evidence records Android platform build code 36 and source-linked APK generation.
- This workstation does not expose Flutter/Android tooling, so no new build, analyzer, widget-test, install, or physical-device claim is made here.
- The repository currently models workflow reconciliation but contains no proven Stripe TEST server integration. E2E-03 through E2E-08 therefore remain blocked on a non-production backend/Stripe TEST endpoint and explicit synthetic test fixtures.

## Next owner gate

Provide an approved non-production backend + Stripe TEST environment and designated Android device, then execute E2E-01 through E2E-08 in order. Stop on the first boundary failure; do not enable live mode.
