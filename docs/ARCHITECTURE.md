# Architecture

How Hopin is built. Decisions and progress are in [PLAN.md](PLAN.md); this file is the design, updated whenever it changes. Draft of 2026-11-03, before M0: package versions are checked again against current docs when each one is first added.

## Decisions

- **One Flutter app, Android only** (min SDK 26, arm64 APK). No web app and no iPhone app: the work happens in the background on the phone.
- **Local first.** Each phone keeps a drift (SQLite) database per person; every screen reads only that database, so the app works offline on a bus with a weak signal. Firestore is the sync layer, reached through a `Remote` interface, with a cursor-based sync engine (`updatedAt > cursor`) that reads only what changed.
- **The vehicle trigger is native.** A small Kotlin receiver registers Google's Activity Recognition Transition API for entering and leaving IN_VEHICLE (plus WALKING and STILL). The system delivers those events even when the app is closed, and an activity transition is one of the cases where Android lets an app start a foreground service from the background. The Flutter activity plugins only stream while the app runs, so they can't do this part.
- **Rides run in a location foreground service:** `flutter_foreground_task` (MIT, maintained) with a Dart task handler that reads GPS through `geolocator`. On Android 14 and later, starting a location service from the background needs "Allow all the time" location, which this sideloaded app asks for once, with a short reason screen.
- **Bus logic is plain Dart** (`lib/core/ride/`), with no Flutter or plugin imports, so it is unit tested against synthetic GPS traces: generated bus-like and car-like rides, since the repo is public and real rides never go in it.
- **No server code.** Firebase Spark only (Firestore and Google sign-in); access is enforced by Firestore rules that admit only the two riders' accounts.
- **Map:** MapLibre (`maplibre_gl`, native and GPU-drawn) with OpenFreeMap's vector tiles: free, no key, no usage limits, commercial use allowed. The app ships its own style JSON per theme, derived from OpenFreeMap's Positron and Dark and recoloured to the Board palette, showing only streets, water, parks, buildings and town names (the app draws its own markers). Attribution "OpenFreeMap © OpenMapTiles Data from OpenStreetMap" stays on the map. Tiles the map has shown are cached by MapLibre. The map renders into a `TextureView` (`MapLibreMap.useHybridComposition`, set before the first map): the default `GLSurfaceView` can only be embedded through a virtual display, which stuttered and flickered under closing sheets on the phone. Markers are the map's own circles, redrawn one at a time and only when they move. The styles come from `scripts/map_style/build_styles.py`.
- **Search:** Nominatim, typed then searched (its policy forbids search as you type), at most one request a second, with an identifying user agent and results cached on the phone. Results ask for `namedetails`, so each carries `name:en`, `name:ta` and `name:si`; "Now near" uses Nominatim's reverse lookup about once a minute.
- **Notifications and alerts are local:** `flutter_local_notifications` for "On a bus?" (with action buttons) and the get-off alert; the phone's vibrator for the buzz. The spoken line is left out until after the field test (M4).
- **Updates come from GitHub Releases:** release builds know their own build number (`HOPIN_BUILD`, set by the release workflow; versions number builds as major * 1,000,000 + minor * 1,000 + patch). When Hopin opens, at most every 6 hours, it asks GitHub's API for the latest release; a newer one shows a calm banner on Home. Update downloads the APK into the app's cache with progress and hands it to Android's installer through a file provider (`REQUEST_INSTALL_PACKAGES`; the first time, Android's page to allow it opens instead). Other builds never look. No background check and no notification: the riders open Hopin before every ride, and Xiaomi's battery saver often blocks background jobs.

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
        GitHub Actions: release -> GitHub Releases (signed APK)
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
| `people/{uid}/places/{placeId}` | owner only | `name`, `lat`, `lng`, `kind` (`home`, `work`, `uni`, `other`), `placeEn`, `placeTa`, `placeSi`, `order` (the rider's own order, 0 to 999), `updatedAt`, `deletedAt` |
| `people/{uid}/settings/app` | owner only | `language` (`en` or `ta`), `stages` (1 to 3 of `metres` and `pattern`, from the fixed lists), `updatedAt`; one document, never deleted |
| `people/{uid}/rides/{rideId}` | owner only | `startedAt`, `endedAt`, `start` and `end` (lat, lng, place name), `path` (encoded polyline, thinned), `distanceM`, `stopsSeen` (stop IDs), `verdict` (`bus`, `not_bus`, `unknown`), `features` (the numbers the bus logic used), `destinationId`, `routeId` (M2), `updatedAt`, `deletedAt` |
| `stops/{stopId}` | both | `lat`, `lng`, `nameEn`, `nameTa`, `nameSi`, `source` (`osm`, `learned`, `added`), `seen` (how many rides halted there), `lastSeenAt`, `addedBy`, `updatedAt`, `deletedAt` |
| `routes/{routeId}` (M2) | both | `number`, `from` and `to` (names in en, ta, si), `via`, `stopIds`, `boardSi` (the board text), `source`, `addedBy`, `updatedAt`, `deletedAt` |
| `shares/{rideId}` | both read, rider writes | `uid`, `lat`, `lng`, `speedKmh`, `heading`, `destinationName`, `etaMin`, `startedAt`, `endedAt`, `updatedAt` |

- **Access:** a rider is a signed-in account whose token carries the custom claim `rider: true`. The project owner sets it from a PC with the Firebase CLI's login (Google's Identity Toolkit API), first for your account after its first sign-in and later for the second rider's. So no account IDs or emails live in the public repo, adding a rider needs no rules change, and the check costs no reads. A new rider's app picks the claim up when its sign-in token refreshes. Every path also checks the owner where the table says so. A rules change starts with a failing rules test, on the emulator.
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

- **Start:** a destination is a saved place, a search result or a dropped pin; Start, in its panel, turns Home into ride mode on the same map (the ride board, the map framing you and the stop). The first Start explains notifications before Android's popup, asks Android to let Hopin run in the background, and shows the maker's steps (below).
- **The service:** the guide runs in a foreground service of type location (`flutter_foreground_task`), in its own isolate, so it keeps guiding with the app swiped away. It is started while the app is open, which lets "while using the app" location cover it after the app closes. It never restarts by itself: a service started from the background gets no location without "Allow all the time", which waits for M1b, so the maker's steps are what keep it alive.
- **The maths** (`lib/core/ride/guide_engine.dart`, plain Dart, tested on synthetic traces): GPS every 5 s at high accuracy. Each alert stage fires once, at its distance or, on a fast bus, about 45 seconds before the stop; when several come due at once only the innermost fires. Within 100 m and walking or still (under 2.5 m/s) for a minute ends the guide with a gentle tap. Having been within 400 m, 300 m further on is a missed stop: the strongest pattern and "You passed your stop", once, and the guide goes on. Speeds come from how far you moved over the last 30 s and 2 min, so GPS jitter while still reads as still; the time left uses the 2-minute speed and hides under 1 m/s. Fixes vaguer than 100 m are ignored, and the guide ends or warns only on fixes within 50 m.
- **An alert:** the stage's pattern twice (Android's alarm vibration, which plays with the screen off), plus a silent alert on the lock screen ("Stop alerts"). The ongoing notification ("Ride guide") shows the distance and time left, with End.
- **The app and the service** talk through the plugin's ports: the service sends its status after every fix and a last message when it ends; the ride itself is kept in the plugin's storage, so a reopened app finds the running guide and asks for its status.
- **"Now near"** is the suburb or village around you (Nominatim at zoom 14), looked up by the app at most once a minute while it is open; nothing on the ride waits on it.
- **A guide that never arrives:** after 20 minutes without getting 100 m closer than its best, the guide asks "Still going to (stop)?": a gentle buzz, an alert, and Keep beside End on its notification and on the ride board. Keep starts the 20 minutes again; no answer keeps guiding. After 2 hours without getting closer it ends itself with a gentle tap. A long trip that keeps getting closer is never asked.
- **The stages** are the rider's own (Settings, Alerts), saved with the language in `people/{uid}/settings/app` and synced like places; a guide takes them at Start.

## Phones that kill background apps

Xiaomi and Samsung both stop background services beyond Android's own rules, and the riders use one of each. The first Start asks Android for the battery exemption (unless Hopin has it), then shows the maker's steps once: on Xiaomi (MIUI or HyperOS), Autostart on and battery saver "No restrictions", with a button to Xiaomi's Autostart list; on Samsung (One UI), battery "Unrestricted" and Hopin in "Never sleeping apps", with a button to Hopin's settings. A small method channel in `MainActivity` reports the maker and opens the Autostart list, which Dart can't do without a plugin. The transition receiver needs no running process, so detection survives even when the service has been stopped.

## Permissions

Each is declared in the change that first uses it: `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `ACTIVITY_RECOGNITION`, `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.

## Releases and CI

- Conventional Commits decide the version. A release workflow builds the signed arm64 APK, checks that it carries the release key's certificate (the build falls back to the debug key without one), and publishes a GitHub Release with the APK and its checksum. A manual build-only run tests the pipeline without publishing. The signing key lives outside the repo, in GitHub's encrypted secrets for the workflow, which runs only on main and by hand.
- Updates (from M1a): the app reads the repo's latest release from GitHub's public API about once a day, compares its build number with its own (`HOPIN_BUILD`), and offers the update; a tap downloads the APK and Android installs it over the old one.
- CI is one job on pull requests that runs only the checks for what changed (format, analyze, tests, rules tests, release script tests) and builds nothing, so a pull request gets its answer fast. The repo is public, so GitHub's standard runners cost nothing.

## Testing

- Bus logic and guide maths: unit tests over synthetic traces in `test/fixtures/traces/`, generated to look like bus rides and car or tuk rides. Real rides never go in the repo; the thresholds are tuned from the riders' labelled rides, which stay in Firestore.
- Repositories and sync: in-memory drift and a fake `Remote`.
- Rules: the emulator, never the live project.
- On the phone: battery over a normal day, screen-off alerts and the makers' background limits, checked by you before each milestone is ticked.
