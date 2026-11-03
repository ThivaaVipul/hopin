# Hopin

A bus companion for Android: it notices when you are on a bus, tells you when your stop is near, shows which bus to take and where to board, and learns your regular rides. A personal app for two riders, on free services only.

- Plan and decisions: [docs/PLAN.md](docs/PLAN.md)
- Design: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Working on it: [CLAUDE.md](CLAUDE.md)

## Layout

```text
app/              Flutter app (Android)
firebase/         Firestore rules and their tests (emulator)
scripts/release/  next version and release notes (Python, standard library)
docs/             plan and architecture
```

## Releases

Merging a change that ships (a `feat` or `fix` in `app/`) publishes a release: `.github/workflows/release.yml` builds the signed APK and attaches it to a GitHub Release. The signing key lives outside the repo; the workflow reads it from four repository secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`. Run the workflow by hand with "build only" to test the build and the signing without publishing.

## Getting started

```bash
cd app
flutter pub get
flutter test
flutter run
```
