# Architecture

How Hopin is built. Decisions and progress are in [PLAN.md](PLAN.md); this file is the design, updated whenever it changes. Draft of 2026-11-03, before M0: package versions are checked again against current docs when each one is first added.

## Decisions

- **One Flutter app, Android only** (min SDK 26, arm64 APK). No web app and no iPhone app: the work happens in the background on the phone.
- **Local first.** Each phone keeps a drift (SQLite) database per person; every screen reads only that database, so the app works offline on a bus with a weak signal. Firestore is the sync layer, reached through a `Remote` interface, with a cursor-based sync engine (`updatedAt > cursor`) that reads only what changed.
- **The vehicle trigger is native.** A small Kotlin receiver registers Google's Activity Recognition Transition API for entering and leaving IN_VEHICLE (plus WALKING and STILL). The system delivers those events even when the app is closed, and an activity transition is one of the cases where Android lets an app start a foreground service from the background. The Flutter activity plugins only stream while the app runs, so they can't do this part.
- **Rides run in a location foreground service:** `flutter_foreground_task` (MIT, maintained) with a Dart task handler that reads GPS through `geolocator`. On Android 14 and later, starting a location service from the background needs "Allow all the time" location, which this sideloaded app asks for once, with a short reason screen.
- **Bus logic is plain Dart** (`lib/core/ride/`), with no Flutter or plugin imports, so it is unit tested against synthetic GPS traces: generated bus-like and car-like rides, since the repo is public and real rides never go in it.
- **No server code.** Firebase Spark only (Firestore, Google sign-in, App Distribution); access is enforced by Firestore rules that admit only the two riders' accounts.
- **Map:** `flutter_map` with OpenStreetMap tiles (two riders is light use, inside OSM's tile policy, with a proper user agent and tile caching); place search through Photon (komoot's free OSM search, which allows search as you type, unlike Nominatim). Names in English, Tamil and Sinhala come from OSM's `name`, `name:ta` and `name:si`.
- **Notifications and alerts are local:** `flutter_local_notifications` for "On a bus?" (with action buttons) and the get-off alert; the phone's vibrator for the buzz; `flutter_tts` for the optional spoken line, only if M1a shows it's easy.

## System overview

```text
 Phone (Flutter, Android)
 +-----------------------------------------------------------+
 | Kotlin: transition receiver (IN_VEHICLE enter / exit)      |
 |   starts / stops                                           |
 | Foreground service (Dart task):                            |
 |   GPS samples -> bus logic -> "On a bus?" notification     |
 |   get-off guide -> vibration (+ optional spoken line)      |
 |   live share -> position writes                            |
 | Screens (one Cubit each) -> repositories -> drift (SQLite) |
 | Sync engine                                                |
 +---------------------------+-------------------------------+
                             | writes, pulls changes
                             v
        +------------------------------------------------+
        | Firestore (Spark) + rules (the two riders)      |
        | Firebase Authentication (Google sign-in)        |
        +------------------------------------------------+
        GitHub Actions: release -> Firebase App Distribution (APK)
        GitHub Actions (M2): route data job, if the data check finds a usable source
```

## Repository layout

```text
app/                  Flutter app (Android)
  lib/app/            shell: app, router, theme, shared widgets
  lib/core/           data (drift, sync, repositories), ride (bus logic, guide maths), platform, format
  lib/features/       onboarding, home, guide, rides, places, share, settings (M2: which_bus, M3: commute)
  lib/l10n/           app_en.arb, app_ta.arb
  test/               mirrors lib/; test/fixtures/traces/ holds synthetic rides
  android/            includes the Kotlin transition receiver and boot receiver
firebase/             firestore.rules, firestore.indexes.json, rules tests (Node, emulator)
scripts/release/      next version and release notes (Python, standard library)
docs/                 PLAN.md, ARCHITECTURE.md
firebase.json
```

## Data model (Firestore)

Every synced document carries `updatedAt` (a server timestamp) and is soft-deleted with `deletedAt`, so the incremental sync carries deletions too.

| Path | Who | Fields |
| --- | --- | --- |
| `people/{uid}` | both read, owner writes | `name`, `photoUrl`, `language` (`en` or `ta`), `updatedAt` |
| `people/{uid}/places/{placeId}` | owner only | `name`, `lat`, `lng`, `kind` (`home`, `work`, `uni`, `other`), `updatedAt`, `deletedAt` |
| `people/{uid}/rides/{rideId}` | owner only | `startedAt`, `endedAt`, `start` and `end` (lat, lng, place name), `path` (encoded polyline, thinned), `distanceM`, `stopsSeen` (stop IDs), `verdict` (`bus`, `not_bus`, `unknown`), `features` (the numbers the bus logic used), `destinationId`, `routeId` (M2), `updatedAt`, `deletedAt` |
| `stops/{stopId}` | both | `lat`, `lng`, `nameEn`, `nameTa`, `nameSi`, `source` (`osm`, `learned`, `added`), `seen` (how many rides halted there), `lastSeenAt`, `addedBy`, `updatedAt`, `deletedAt` |
| `routes/{routeId}` (M2) | both | `number`, `from` and `to` (names in en, ta, si), `via`, `stopIds`, `boardSi` (the board text), `source`, `addedBy`, `updatedAt`, `deletedAt` |
| `shares/{rideId}` | both read, rider writes | `uid`, `lat`, `lng`, `speedKmh`, `heading`, `destinationName`, `etaMin`, `startedAt`, `endedAt`, `updatedAt` |

- **Access:** the rules hold the two riders' Firebase account IDs (UIDs, which are opaque) as the allow list, starting with yours and gaining the second rider's later; never emails, since the repo is public. Every path also checks the owner where the table says so. A rules change starts with a failing rules test, on the emulator.
- **Ride IDs** are made on the phone, so a ride is created offline. A ride's raw GPS points stay in drift; only the thinned path syncs (a one-hour ride is a few KB).
- **Live share:** the rider writes the share document about every 10 s while sharing (about 360 writes an hour, far inside Spark's 20K a day) and sets `endedAt` at the end; the other person's app listens to open shares only.
- **Pooled stops:** a learned stop is a point where confirmed bus rides keep halting; nearby candidates merge (within about 30 m) and `seen` counts up, so one stray halt doesn't become a stop.

## Ride detection

1. The transition receiver hears IN_VEHICLE enter and starts the foreground service in scoring mode (GPS every 10 s, balanced accuracy). It also re-registers the transitions after a reboot or an app update.
2. The bus logic scores the ride from features: speeds (buses rarely sustain the top speeds cars reach on open road), halts per kilometre and their length (roadside halts of 10 to 60 s), halts at known stops, closeness to past confirmed bus rides, and the time of day.
3. When the score passes the threshold (after about 3 minutes), a quiet notification asks "On a bus?" with **Yes** and **Not a bus**; tapping it opens the ride screen, where the destination can be picked for the get-off guide.
4. **Not a bus** stops sampling until the vehicle leaves; no answer keeps the ride as `unknown`. Each answer is stored with the ride's features, and the thresholds are tuned from those labels as rides accumulate.
5. IN_VEHICLE exit followed by walking or still ends the ride; it is saved, synced and its halts feed the pooled stops.
6. The guide can always be started by hand from the app, which is how M1a works before detection exists.

## Get-off guide

- A destination is a saved place, a search result or a dropped pin. During a guided ride the service samples GPS every 5 s at high accuracy.
- The alert fires once when the bus is about 2 minutes or 600 m away, whichever comes first (exact rules in M1a's grilling): a distinct vibration pattern, a notification showing the stop's name with the Sinhala name beside it, and the optional spoken line.
- The ride screen shows the map, your position, the next known stop or town and the distance and time to go.

## Phones that kill background apps

Xiaomi and Samsung both stop background services beyond Android's own rules, and the riders use one of each. Onboarding checks the battery optimisation state, asks for the exemption, and shows a one-time screen for the maker: on Xiaomi (MIUI or HyperOS), Autostart on and battery saver "No restrictions"; on Samsung (One UI), Hopin in "Never sleeping apps" and battery "Unrestricted". The transition receiver needs no running process, so detection survives even when the service has been stopped.

## Permissions

Each is declared in the change that first uses it: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `ACTIVITY_RECOGNITION`, `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.

## Releases and CI

- Conventional Commits decide the version; a release workflow builds the signed arm64 APK and sends it to an App Distribution group of the two riders (App Tester tells them about updates); a GitHub Release records it. No Hosting.
- CI is one job on pull requests that runs only the checks for what changed (format, analyze, tests, rules tests, release script tests) and builds nothing, so a pull request gets its answer fast. The repo is public, so GitHub's standard runners cost nothing.

## Testing

- Bus logic and guide maths: unit tests over synthetic traces in `test/fixtures/traces/`, generated to look like bus rides and car or tuk rides. Real rides never go in the repo; the thresholds are tuned from the riders' labelled rides, which stay in Firestore.
- Repositories and sync: in-memory drift and a fake `Remote`.
- Rules: the emulator, never the live project.
- On the phone: battery over a normal day, screen-off alerts and the makers' background limits, checked by you before each milestone is ticked.
