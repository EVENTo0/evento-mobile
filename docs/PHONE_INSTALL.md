# EVENTO — Permanent Android Phone Test Loop

This repository is the source of truth for EVENTO Mobile.

## Install the latest Android dev build

1. Open this repository on the designated Android test phone.
2. Open **Releases**.
3. Open **EVENTO Dev Latest** (`dev-latest`).
4. Download **evento-dev.apk**.
5. If Android asks, allow GitHub/your browser to install apps from this source.
6. Install the APK.

Future builds use the same EVENTO dev signing identity so a new APK can update the existing dev installation.

## Daily loop

ChatGPT/Codex change → push to `main` → GitHub Actions analyze/test/build → `dev-latest` updated → download/install update on the same phone.

## Safety

- The dev build is not the Play Store production build.
- Production signing keys must never be committed to this repository.
- Only the Supabase publishable key is permitted in the mobile build; server secrets stay server-side.

## Build troubleshooting

Check `PHONE_BUILD_STATUS.md` and the **Actions** tab. A successful validated build publishes `evento-dev.apk` and its SHA-256 file.
