# Architecture

How Hopin is built. Decisions and progress are in [PLAN.md](PLAN.md); this file is the design, updated whenever it changes. Draft of 2026-11-03, before M0: package versions are checked again against current docs when each one is first added.

## Decisions

- **One Flutter app, Android only** (min SDK 26, arm64 APK). No web app and no iPhone app: the work happens in the background on the phone.
- **Local first.** Each phone keeps a drift (SQLite) database per person; every screen reads only that database, so the app works offline on a bus with a weak signal. Firestore is the sync layer, reached through a `Remote` interface, with a cursor-based sync engine (`updatedAt > cursor`) that reads only what changed.
- **The vehicle trigger is native.** A small Kotlin receiver registers Google's Activity Recognition Transition API for entering and leaving IN_VEHICLE (plus WALKING and STILL). The system delivers those events even when the app is closed, and an activity transition is one of the cases where Android lets an app start a foreground service from the background. The Flutter activity plugins only stream while the app runs, so they can't do this part.
- **Rides run in a location foreground service:** `flutter_foreground_task` (MIT, maintained) with a Dart task handler that reads GPS through `geolocator`. On Android 14 and later, starting a location service from the background needs "Allow all the time" location, which this sideloaded app asks for once, with a short reason screen.
- **Bus logic is plain Dart** (`lib/core/ride/`), with no Flutter or plugin imports, so it is unit tested against synthetic GPS traces: generated bus-like and car-like rides, since the repo is public and real rides never go in it.
- **No server code.** Firebase Spark only (Firestore, Google sign-in, and Hosting for the shared ride's web page); access is enforced by Firestore rules that admit only the two riders' accounts, except one shared ride read by its link.
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
        GitHub Actions: route data (weekly) -> the "data" release (route files)
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
scripts/data/         the weekly route data job (Python; pdfplumber reads NTC's sheets)
docs/                 PLAN.md, ARCHITECTURE.md
firebase.json
```

## Data model (Firestore)

Every synced document carries `updatedAt` (a server timestamp) and is soft-deleted with `deletedAt`, so the incremental sync carries deletions too.

| Path | Who | Fields |
| --- | --- | --- |
| `people/{uid}` | both read, owner writes | `name`, `photoUrl`, `language` (`en` or `ta`), `updatedAt` |
| `people/{uid}/places/{placeId}` | owner only | `name`, `lat`, `lng`, `kind` (`home`, `work`, `uni`, `other`), `placeEn`, `placeTa`, `placeSi`, `order` (the rider's own order, 0 to 999), `shareRides` (a guide here shares itself), `updatedAt`, `deletedAt` |
| `people/{uid}/settings/app` | owner only | `language` (`en` or `ta`), `stages` (1 to 3 of `metres` and `pattern`, from the fixed lists), `updatedAt`; one document, never deleted |
| `people/{uid}/rides/{rideId}` | owner only | `startedAt`, `endedAt`, `start` and `end` (lat, lng, place name), `path` (encoded polyline, thinned), `distanceM`, `stopsSeen` (stop IDs), `verdict` (`bus`, `not_bus`, `unknown`), `features` (the numbers the bus logic used), `destinationId`, `routeId` (M2), `updatedAt`, `deletedAt` |
| `halts/{rideId}` | both read, the ride's rider writes | `uid`, `points` (a bus ride's halts of 10 to 90 s, as "lat,lng,seconds;..."; empty once taken back), `updatedAt`, `deletedAt` |
| `stopNotes/{noteId}` | both | `lat`, `lng`, `name` (a rename) or `removed`, `by`, `updatedAt`; never deleted |
| `routes/{routeId}` (M2) | both | `number`, `from` and `to` (names in en, ta, si), `via`, `stopIds`, `boardSi` (the board text), `source`, `addedBy`, `updatedAt`, `deletedAt` |
| `shares/{shareId}` | anyone reads one by its link; riders list open ones; its rider writes and deletes it at the end | `uid`, `lat`, `lng`, `toName`, `toTa`, `toLat`, `toLng`, `leftMin`, `metresLeft` (null for a noticed ride), `startedAt`, `endedAt`, `updatedAt`; no name |

- **Access:** a rider is a signed-in account whose token carries the custom claim `rider: true`. The project owner sets it from a PC with the Firebase CLI's login (Google's Identity Toolkit API), first for your account after its first sign-in and later for the second rider's. So no account IDs or emails live in the public repo, adding a rider needs no rules change, and the check costs no reads. A new rider's app picks the claim up when its sign-in token refreshes. Every path also checks the owner where the table says so. A rules change starts with a failing rules test, on the emulator.
- **Ride IDs** are made on the phone, so a ride is created offline. A ride's raw GPS points stay in drift; only the thinned path syncs (a one-hour ride is a few KB).
- **Live share** (docs/PLAN.md, Sharing and stops): a share's id is 20 random letters and digits, and its link is `https://hopin-riders.web.app/r/<id>`. The ride service writes it from its own isolate (it starts Firebase there the first time a ride is shared), so a share goes on with Hopin swiped away: about every 10 s while moving and once a minute while halted (at most about 360 writes an hour, far inside Spark's 20K a day), never waiting on the network. When the service stops it deletes the share, so nothing of it is kept, and a page still open says "Ride ended". A share the phone's battery saver cut off is ended the next time Hopin opens without the service running. The other rider's Home listens to open shares, leaving out its own and any silent for 15 minutes.
- **The shared ride's page** (`firebase/hosting/public/share.html`, Firebase Hosting, deployed by hand with an OK): one static page at `/r/<id>`, MapLibre GL JS with the same Board styles as the app (`firebase/hosting/public/map`, written by `scripts/map_style/build_styles.py` with the app's), and the Firebase web SDK listening to that one document. Its Firebase settings come from Hosting's own `/__/firebase/init.json`, so no key is in the repo. It says "Lost contact" after 10 minutes without an update, and "Ride ended" for an ended share or a wrong link; English, or Tamil when the browser is.
- **Stops** (docs/PLAN.md, Sharing and stops): no stops collection. OpenStreetMap's bus stops come from the Overpass API in squares of 0.05 degrees (about 5.5 km), fetched around the saved places, where rides halt and any view at street level, kept on the phone and fetched again after a month. A bus ride's halts of 10 to 90 s go into `halts/{rideId}` (`RidesRepository` puts them there and takes them back when the ride is deleted or no longer a bus), and both phones work the stops out from the pool (`lib/core/ride/stops.dart`, plain Dart): a halt within 30 m of an OSM stop counts towards it; elsewhere, halts from two different rides within 30 m make a learned stop at their centre. A rename or removal is a `stopNotes` document at the stop's spot, and the latest note within 30 m wins, so it holds as more rides move the centre a few metres. A learned stop's name is looked up once at street level (Nominatim, zoom 17) and kept on the phone. The map draws every stop as one GeoJSON source and circle layer (one update however many stops, shown from zoom 15 in, under the other markers); a tap opens the panel of the nearest stop within a fingertip (24 logical pixels, in metres at the zoom), since the map itself counts a tap on a dot only within a few pixels.

## Route data (M2)

The buses that go to a place come from route files the app downloads (docs/PLAN.md, Which bus). A weekly workflow (`.github/workflows/data.yml`, also run by hand) runs `scripts/data/build_data.py`, which builds one file per source for the whole island, so nothing in the repo points at the riders' routes, and publishes them on the repo's `data` release: a prerelease that is never marked latest (the updater reads the latest release) with a tag that isn't `v*` (release versioning reads only those). The phones download the files from github.com, which has no API limit, and keep them for offline use.

- **Towns and boards:** OpenStreetMap's towns and bus stands (Overpass) give each route end its board: Tamil, Sinhala and English names. OSM has them for every city but for only a part of the towns and few suburbs, so Wikidata's labels fill in where a town links to it; a name nobody has stays missing and the app shows the others. Route ends are matched to towns by the closest spelling ("Trinco", "Mt. Lavinia", "Kurunagala").
- **OpenStreetMap** (`osm-routes.json`, ODbL): every relation with a number. Most of Sri Lanka's are one unordered bag of ways for both directions, often with gaps and often mapped only part of the way, so the job treats a relation's ways as a small road network and takes the shortest road through it between its two end towns. An end that isn't a town ("Bakery Junction") is the network's far end, with its English name. A name with several towns at one end ("A/B/C - D") gives a direction to each. A partly mapped route keeps the part that is mapped.
- **NTC** (`ntc-routes.json`): the text PDFs in NTC's public Drive folders. A sheet is usually two halves side by side, one per direction, each a row of times per trip at the timing points, or "arrive at the terminal" and "depart" columns. The headers are Sinhala whose letters partly come out of the PDF wrong, so a half's direction is found by comparing the consonants of its first and last headers with the end towns' names; the end towns come from the English file name. Scans, special-day sheets, time cards and unclear sheets are left out, and so is a route whose newest sheet is a scan. Each direction keeps its departures, the two towns' points and a bus stand near the start.
- **LMT** (`lmt-routes.json`): the community server's GTFS feed (`api.transit.seyone.dev`), built from the buses' own runs, so each day is a service of its own and its trips are pieces of runs. A direction's timetable is the busiest recent weekday, Saturday and Sunday; the minutes to each stop chain the median time from stop to stop; pieces of one run give one departure; and a direction whose trips run backwards along its shape (the feed has swapped two) is turned round.
- **The files** share one shape, described at the top of `build_data.py`: routes with a number and directions, each with its board and origin names, and as the source allows a path (encoded polyline), stops, the two ends' points, a bus stand and departures by day. A source that fails writes nothing, so last week's file stays on the release.
- **On the phone** (M2a2): `RoutesRepository` fetches each file once a week from github.com (`RouteFiles`), sending its ETag so an unchanged file comes back empty, and keeps it as it came in the local database (`RouteData`, a row per source; a file the release didn't have is asked for again a day later, and a broken one or one of a newer format keeps the old). The files are read into plain Dart directions (`lib/core/ride/routes.dart`) whenever they change. `WhichBus` (`lib/core/ride/which_bus.dart`, plain Dart) finds the buses from where you are to the destination: one bus, its road within 500 m of both ends and in the right order, at least 300 m of riding, none for a trip under 800 m; an NTC route by its towns instead (within 10 km, or a third of the way between them). It boards at the route's stop nearest you (or the road, or the bus stand), with the next three times there from the day's departures and the stop's minutes, and shows the same bus from two sources once. Home's Cubit works the buses out again when the destination, your position (by 50 m) or the routes change. A board's names show in one order everywhere (`BoardNames`): Tamil large, Sinhala, English small, the next taking the lead where one is missing.
- **drift's watched queries** are shared by their SQL alone, not by the tables they read: two `customSelect('SELECT 1', readsFrom: ...)` streams would be one stream, following the first one's tables. The routes watch their own table's rows for that reason.

## Ride detection

1. **Turning it on** (a one-time card on Home, or Settings): Physical activity, then location "Allow all the time" (Android's settings page). Hopin then hands `MainActivity`'s channel the ride service's start options (the same map `flutter_foreground_task`'s startService sends, with the task's callback handle), kept natively because the plugin wipes its own copy whenever the service stops, and asks Android for the IN_VEHICLE enter and exit transitions.
2. **A vehicle:** the transition receiver (`RideDetection.kt`) hears IN_VEHICLE enter and starts the ride service through the plugin's own service manager; a broadcast from an activity transition is one of the cases where Android lets an app start a foreground service from the background, and "Allow all the time" lets it use location there. With no guide saved, the Dart task watches the ride: GPS every 10 s at high accuracy into the bus logic. IN_VEHICLE exit is noted for the task, and the boot receiver asks for the transitions again after a reboot or an update.
   - **A backstop:** on a phone, Play services once saw a 35-minute bus ride as "in a vehicle" without ever sending the transition. So the same registration also asks for its readings every 3 minutes (one brief wake each, no GPS), and a reading at least 75% "in a vehicle" starts watching. When the ride service stops it leaves a quiet mark (`ride.quiet`), and the backstop keeps quiet until a reading at least 75% on foot, the vehicle exit, or 2 hours, so Not a bus and End aren't undone in the same vehicle. Both registrations are asked for again each time Hopin opens.
   - **"On a bus" in quick settings** (`RideTileService`): one tap starts watching, for a ride that wasn't noticed, and it shows as on while the ride service runs; a tap then ends the ride, as End does. "Checking your ride" carries End as well. Where Android won't let the service start from the panel, it opens Hopin, which starts it from the screen. Its label is an Android string resource, in the phone's language, since Android draws it.
3. **The bus logic** (`lib/core/ride/bus_logic.dart`, plain Dart, tested on synthetic rides) keeps the path (points at least 40 m apart), the halts (slower than 1.5 m/s between fixes for at least 8 s, after the ride first moves; steps under 15 m are GPS wobble) and the top speed held over 30 s. The score is mostly bus-like halts per kilometre (10 to 90 s) and partly a speed that stays below a car's on an open road. At 3 minutes and 600 m with a score of 0.6 or more it asks once; it errs towards asking, since the answer is cheap and is kept with the numbers to tune it.
4. **"On a bus?"** is a quiet alert with the rider's first two saved places (from the ride config the app keeps up to date: places, stages, language), Yes when there are fewer, and Not a bus; it is asked once, there, while the service's own notification stays "Checking your ride" (asking in both showed two notifications for one question). Home shows it as a card when Hopin is open or opened from the alert (the app asks the running service for an open question). A place starts the guide to it in the same service (fixes every 5 s from then). Not a bus stops at once.
   - A button on an alert runs in the notification plugin's own isolate (`alertButtonPressed`), which hands it to the service like the app's answers. Alerts are a group of their own: left ungrouped, Xiaomi's phones bundle them with the service's notification and show neither one's buttons.
   - Messages between the service and the app are maps built at run time: a `const` map sent across isolates trips a debug check in the receiving isolate.
5. **The end:** the vehicle left and 2 minutes without moving, or 15 minutes without moving; a guide ends as before. Whatever stops the service, the ride is kept: rides under 2 minutes or 300 m are dropped, except Not a bus. A ride the user guided by hand is logged as a bus.
6. **Logged rides** go from the service to the app (one stored key per ride until the app has it, so none is lost with Hopin closed), into the local database and `people/{uid}/rides`, private: times, verdict, distance, the path and halts as encoded polylines (none for Not a bus), the logic's numbers, and the guide's stop. They are kept until deleted.
7. **The Rides page** (Settings, Rides) reads only the local database: rides by day, and a ride's own page with its path on a small map of its own in the Board look (`RideMap`, swappable in widget tests like the home map), its label and Delete. `RideNamer` (one per workspace) names a ride's ends once: a saved place within 300 m, otherwise Nominatim's suburb at zoom 14 in the app's language; it runs when Hopin keeps a ride and when the page opens, so rides kept offline are named later. Marking a ride Not a bus removes its path, halts and names after asking.

## Get-off guide

- **Start:** a destination is a saved place, a search result or a dropped pin; Start, in its panel, turns Home into ride mode on the same map (the ride board, the map framing you and the stop). The first Start explains notifications before Android's popup, asks Android to let Hopin run in the background, and shows the maker's steps (below).
- **The service:** the guide runs in a foreground service of type location (`flutter_foreground_task`), in its own isolate, so it keeps guiding with the app swiped away. It is started while the app is open, which lets "while using the app" location cover it after the app closes. It never restarts by itself: a service started from the background gets no location without "Allow all the time", which waits for M1b, so the maker's steps are what keep it alive.
- **The maths** (`lib/core/ride/guide_engine.dart`, plain Dart, tested on synthetic traces): GPS every 5 s at high accuracy. Each alert stage fires once, at its distance or, on a fast bus, about 45 seconds before the stop; when several come due at once only the innermost fires. Within 100 m and walking or still (under 2.5 m/s) for a minute ends the guide with a gentle tap. Having been within 400 m, 300 m further on is a missed stop: the strongest pattern and "You passed your stop", once, and the guide goes on. Speeds come from how far you moved over the last 30 s and 2 min, so GPS jitter while still reads as still; the time left uses the 2-minute speed and hides under 1 m/s. Fixes vaguer than 100 m are ignored, and the guide ends or warns only on fixes within 50 m.
- **An alert:** the stage's pattern twice (Android's alarm vibration, which plays with the screen off), plus a silent alert on the lock screen ("Stop alerts"). The ongoing notification ("Ride guide") shows the distance and time left, with End.
- **The app and the service** talk through the plugin's ports: the service sends its status after every fix and a last message when it ends; the ride itself is kept in the plugin's storage, so a reopened app finds the running guide and asks for its status.
- **"Now near"** is the suburb or village around you (Nominatim at zoom 14), looked up by the app at most once a minute while it is open; nothing on the ride waits on it.
- **A guide that never arrives:** after 20 minutes without getting 100 m closer than its best, the guide asks "Still going to (stop)?": a gentle buzz, an alert with Keep, and Keep beside End on its notification and on the ride board. Keep starts the 20 minutes again; no answer keeps guiding. After 2 hours without getting closer it ends itself with a gentle tap. A long trip that keeps getting closer is never asked.
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
