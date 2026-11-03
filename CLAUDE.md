# Hopin

A bus companion for Android, for two riders: it notices a bus ride, buzzes before your stop, shows which bus to take and learns your regular rides. One Flutter app on Firebase's free plan; each phone keeps a local drift database that syncs through Firestore. The design is in `docs/ARCHITECTURE.md`. Progress and decisions are in `docs/PLAN.md`: tick items as they land and log design changes there.

## Commands

```bash
# App, from app/
flutter pub get
dart format lib test          # CI fails on unformatted code
flutter analyze               # strict mode, must be clean
flutter test
flutter build apk --debug
flutter gen-l10n              # after editing lib/l10n/*.arb; the generated files are committed

# Firestore rules, from firebase/
npm ci
npm run typecheck
npm test                      # rules tests on the Firestore emulator (demo-hopin, never the live project)
firebase deploy --only firestore   # from the repo root, only after the rules tests pass, and with an OK

# Release tooling, from the repo root with .venv active
pip install -r scripts/requirements-dev.txt
ruff format .                 # CI fails on unformatted code
ruff check .
pytest scripts/release
```

Dart tests mirror `lib/` under `app/test/`.

## Architecture rules

- Firebase Spark plan only: Firestore and Authentication (Google). Nothing that needs the Blaze plan or a card: no Cloud Functions, Cloud Storage, scheduled backups or point-in-time recovery.
- Screens read only the local drift database. Repositories write to drift and Firestore together; the sync engine pulls changes after its cursor (`updatedAt > cursor`). Never query Firestore from a screen or a Cubit.
- Every synced document has `updatedAt` (a server timestamp). Deletes are soft (`deletedAt`).
- Access is enforced in `firebase/firestore.rules`, never only in the UI. A rules change starts with a failing rules test.
- Bus logic and guide maths live in `lib/core/ride/` as plain Dart with no Flutter or plugin imports, tested against synthetic traces in `test/fixtures/traces/` (never real rides).
- Native Android code is kept to what Dart can't do: the activity transition receiver and boot receiver. Location runs only inside the ride foreground service.
- Everything works offline. Nothing on a ride waits on the network.
- Notifications are local. No push service.
- User-facing text lives in the ARB files (`lib/l10n/`, English and Tamil), never in code. English is the default; Tamil is the person's choice in Settings, independent of the phone's language. Sinhala appears only in place and board names, which are data.

## Git workflow and releases

- Branches `feat/...`, `fix/...`, `docs/...`, `chore/...` off `main`; a pull request, CI green, then squash merge with a Conventional Commit title.
- The commit type decides the release: `feat` is minor, `fix`/`perf`/`revert` patch, `!` or `BREAKING CHANGE:` major, everything else none. Pick the type honestly. Only commits that change `app/` count toward releases.
- A release (`release.yml`) builds the signed arm64 APK, checks that it carries the release key's certificate, and publishes it as a GitHub Release, where the app looks for updates. Run it by hand with "build only" to test the pipeline without publishing.
- Never create `v*` tags by hand, and never change the version in `app/pubspec.yaml` unless asked to force one.
- Release logic lives in `scripts/release/` (Python, standard library only). Change it test-first.

## Constraints

- Fully free: GitHub Free with a public repo (GitHub's standard runners cost nothing there), Firebase Spark, nothing that needs a card. CI (`ci.yml`) stays one quick job on pull requests that runs only the checks for what changed and builds nothing, so pull requests merge fast. Before every push, run those checks locally, plus `flutter build apk --debug` when `app/android/` or the pubspec changed.
- Workflows pin `ubuntu-24.04`. Moving to a newer runner image is its own change, tested first.
- Android only, min SDK 26, arm64 release APK. Installed from GitHub Releases, never the Play Store.
- Add a package only in the change that first uses it. Declare an Android permission only in the change that uses it.
- Check versions and APIs against current docs (Context7) before adding or upgrading a dependency or a GitHub Action.

## Public repo

The repo is public, and whatever it ever held stays public. Keep it free of anything personal:

- No names, places, phone models or email addresses of the riders, and no other projects, in code, comments, docs, commits or pull requests.
- No real GPS data. Test traces are synthetic; recorded rides stay in Firestore.
- Riders are marked by a custom claim (`rider: true`) on their sign-in token, set outside the repo; the rules never hold account IDs or emails.
- Secrets live only in GitHub's encrypted secrets; signing keys and `key.properties` never enter the repo. Workflows never use `pull_request_target`, so pull requests from forks get no secrets.
- Firebase config files are public by design: their API keys carry app and API restrictions, and access rests on the rules alone.

## Conventions

- Flutter: app shell in `lib/app/`, shared code in `lib/core/`, feature-first folders (`lib/features/<feature>/` with `cubit/`, `view/` and `widgets/`), one Cubit per screen (Bloc only when events need it), package imports, `Equatable` state.
- UI: Material 3, smooth and calm, short labels, no explanatory paragraphs on screens. Colours and text styles come from the theme (set in the look pass); widgets don't hard-code either. Check every layout with Tamil strings and with large text.
- Motion: purposeful and quick; shared durations and curves from the theme, never ad hoc. Respect `MediaQuery.disableAnimations` with a static path. Animate with implicit widgets first, controllers only when needed, and keep rebuilds small.
- Plain ASCII punctuation in code, comments, docs and commits (generated files aside): no em or en dashes, arrows, smart quotes or emoji.
- Line endings are LF (enforced by `.gitattributes`).
- Commits: small, imperative subject. Never commit or push without asking.

## Claude tooling

Installed for this project (`.claude/settings.json`, `.claude/skills/`). Use the matching skill before the work it covers. In a session started outside this folder they don't load by themselves: read the SKILL.md at the path below and follow it.

| Work | Skill | SKILL.md |
| --- | --- | --- |
| Layers, routing, localization, layout fixes, widget/integration tests, previews | dart-flutter plugin (`flutter-*`, `dart-*`) | `~/.claude/plugins/cache/dart-flutter/dart-flutter/<version>/skills/<name>/` |
| Animations, transitions, springs, reduced motion | flutter-animations | `.claude/skills/flutter-animations/` |
| drift tables, queries, streams | flutter-drift | `.claude/skills/flutter-drift/` |
| Colours, type, UX and accessibility review | ui-ux-pro-max (run its `scripts/search.py` with Python) | `~/.claude/plugins/cache/ui-ux-pro-max-skill/ui-ux-pro-max/<version>/.claude/skills/ui-ux-pro-max/` |

Project rules win where a skill disagrees: the local database is rebuilt from Firestore instead of migrated (so no drift migrations), and generated localizations live in `lib/l10n` (no `synthetic-package`).

Hot reload (the Flutter team's rule): after editing a `.dart` file under `app/lib/` while the app is running, hot reload through the Dart MCP server; hot restart when `initState`, global state or `main()` changed. Skip it for comment-only edits and for files outside `lib/`.

## Testing on a device

- Ask before installing on a phone or starting the emulator; the emulator is shared with other debug sessions.
- Ride features need a real phone and a real ride: battery, screen-off alerts and the makers' battery savers (Xiaomi and Samsung) are checked there.
