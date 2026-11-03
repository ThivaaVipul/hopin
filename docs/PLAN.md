# Hopin plan

Living document, updated as work proceeds. Last updated: 2026-11-03.
Status: **plan and architecture reviewed (2026-11-03); M0 next.** The design is in [ARCHITECTURE.md](ARCHITECTURE.md). No repo or Firebase project yet.

A bus companion for two riders in different towns. It notices when you are on a bus, tells you when your stop is near, shows which bus to take and where to board, and learns your regular rides over time. Personal use only, on Android, on free services.

## Decisions (2026-11-03, grilling session)

- **Purpose:** a personal app for two riders. Not on the Play Store, not shared with drivers or conductors.
- **Why:** one rider is new to the area, rides buses often and can't read the Sinhala boards, so finding the right bus and knowing where to get off are hard. The other rides daily, around town and on long trips, where there is no live bus data.
- **No camera** anywhere in the app.
- **Ride detection (hybrid):** Android's activity recognition says "in a vehicle"; the app's own logic (stop-start rhythm, speed, where it halts, past rides) decides it is probably a bus and sends a quiet notification ("On a bus?"). One tap confirms or corrects it, and corrections improve later guesses.
- **Features, in this order:**
  1. **M1, get-off guide + ride detection:** works from day one with GPS alone. Every ride is logged from here on.
  2. **M2, which bus to take:** route numbers, where to board, and the destination in big Sinhala letters as it appears on the board, so he can match the shape without reading Sinhala.
  3. **M3, learned commute:** when buses usually pass, how long rides take, when to leave.
- **A standalone app** in its own repo. If M2 finds a usable route source, a scheduled GitHub Actions job collects it.
- **Data:** synced through Firebase on the free Spark plan (no card). Pooled between the two riders: learned routes, stops and board names. Private to each person: ride history. Live position is shared only when the rider taps "Share this ride".
- **Stop alert:** a vibration. A spoken line (in the app's language) is an optional setting, off by default, and is dropped if it turns out to be hard.
- **Language:** English by default, Tamil as a switch in Settings (your change, 2026-11-03). Sinhala appears only for board and stop names, beside the English or Tamil.
- **Name:** Hopin ("hop in"). Short and playful; no -ly names.
- **Look and feel (2026-11-03):** a smooth UI and UX with purposeful animations and a proper colour system (light and dark), at a senior quality bar. Before M1a's screens, a look pass renders a few directions from real widgets to pick from.

### Defaults (accepted 2026-11-03, change any of them)

1. Flutter, Android only (min SDK 26), arm64 APK, in a **public** GitHub repo `ThivaaVipul/hopin` (public since 2026-11-03: unlimited free Actions minutes and branch protection; nothing personal goes in it, see CLAUDE.md).
2. **Installs: GitHub Releases** (settled in M0c): each release puts the signed APK on the public repo's Releases page, and Hopin offers the update when a newer one is out (from M1a). No cloud service account, and builds never expire. (Firebase Hosting on the Spark plan refuses APK files; App Distribution was the alternative.)
3. Google sign-in; only the two riders get in. Their accounts carry a `rider` claim that you set (M0b's change: no account IDs or emails in the repo, and no rules change to add a rider). Yours is set after your first sign-in, the second rider's later.
8. **Firebase account:** your personal Google account (the Firebase CLI's login on this PC), Spark plan, no billing.
4. Map: **MapLibre** (`maplibre_gl`) drawing **OpenFreeMap** vector tiles, recoloured to the app's look (changed in the look pass, 2026-11-03: free with no key and no limits, smooth, restylable; it replaces `flutter_map` with plain OSM image tiles). Place names in English, Tamil and Sinhala come from OSM where present.
5. Destination for the get-off guide: a saved place (Home, Uni, ...), a search, or a pin dropped on the map.
6. Local first: the phone keeps its own database and syncs through Firestore, so everything works offline on a bus with a weak signal.
7. A professional setup: CLAUDE.md, docs, strict analysis, slim CI on pull requests only, Conventional Commits, automatic releases. Every git step and the Firebase project creation wait for your OK.

### Claude tooling (2026-11-03)

Free and open source, installed for this project only (`.claude/settings.json` enables the plugins; `.claude/skills/` holds the copied skills):

- **dart-flutter** (official, Flutter team, BSD-3): Flutter and Dart skills (architecture, responsive layout, layout fixes, widget and integration tests, widget previews, routing, localization, JSON, static analysis, runtime errors) and the Dart MCP server.
- **ui-ux-pro-max** (nextlevelbuilder, MIT): offline palettes, font pairings and UX and accessibility rules, used for the look pass and UX reviews. Its Flutter code guidance is thin; the Flutter skills lead on code.
- **flutter-animations** and **flutter-drift** (MADTeacher, MIT, reviewed before copying): motion patterns, reduced motion and animation performance; drift usage. Where the drift skill asks for formal migrations, this project's rule wins (the local database is rebuilt from Firestore instead of migrated).
- Already available: frontend-design (visual direction), the Dart MCP server, Context7, /simplify and /code-review, dataviz (M3 charts).
- The Flutter team's hot-reload rule goes into CLAUDE.md in M0: after editing `lib/`, hot reload a running app (hot restart for state or `main()` changes).

### Get-off guide (M1a grilling, 2026-11-03)

- **Sign-in:** one-tap Google sign-in on first launch, then the app works at once. Syncing waits quietly until the rider claim is there, then catches up.
- **Home:** map-first: the map at your position, a "Where to?" bar, saved places as chips under it.
- **Search:** Nominatim, typed then searched (its policy forbids search as you type). Each result shows its English or Tamil name with the Sinhala name beside it (OSM's `name:*` tags). Photon was the alternative: suggestions while typing, but without reliable Tamil or Sinhala names.
- **Alerts:** 1 to 3 stages in Settings, each with a distance (3 km, 2 km, 1.5 km, 1 km, 700 m, 500 m, 300 m, 150 m) and a vibration pattern (about 6, each with a "try it" button). Defaults: "Get ready" at 1.5 km with a gentle double tap, "Get off next" at 400 m with a strong long buzz. On a fast bus a stage fires early enough to give at least about 45 seconds.
- **Ride end:** by itself once within about 100 m and walking or still for a minute; an urgent "You passed your stop" about 300 m past it. End is always one tap, on the ride screen and in the notification.
- **Ride screen:** the map with you and the destination; a sheet with the distance left in big type, the time left, progress, the destination's Sinhala name, "Now near <place>" and End.
- **Defaults:** saved places from any destination (a star and a name: Home, Work, Uni or your own), managed in a list (rename, reorder, delete). Settings: language, alert stages, the spoken line (off), the phone's battery guide, sign out, version and "check for updates". Updates: a calm banner on Home plus one notification per new version. The maker's battery guide shows the first time a guide starts. M1a asks only for location while the app is in use and for notifications; "Allow all the time" waits for M1b. "Now near" refreshes about once a minute from Nominatim, cached; the map caches the tiles it has shown, with no offline download yet.

### Home and places (M1a2 grilling, 2026-11-03)

- **Location:** the first time Home opens, a board card gives the reason in one line, then Android's own popup ("while using the app"). If refused, the map still works (around Colombo) and a chip offers location again.
- **Tapping a place** (saved, searched or a dropped pin) opens a destination sheet: the name in English or Tamil, the Sinhala name in amber, the distance from you, and Save or Edit. Start joins it in M1a3.
- **Editing places:** long-press a chip on Home to rename it, change its icon (home, work, uni, other) or delete it. A full list with reordering comes with Settings in M1a4.
- **Recents:** the last 6 destinations, on this phone only. Saved places sync, private to you.
- **Defaults:** the map follows the phone's dark mode (Board light and Board dark styles, generated from OpenFreeMap's by a script in the repo); long-press the map to drop a pin, named after the nearest place; a full-screen search favouring Sri Lanka and your area, each result with its name, Sinhala name and town, at most one request a second and cached; your position as an amber dot with a board ring, drawn by the map; places are the first synced data (local database first, uploaded when you are a rider and online), with their own rules and tests.

### Look (look pass, 2026-11-03)

Three directions were rendered from real widgets on M1a's screens (Board, Ticket, Thambili); you picked **A. Board**: the bus's own destination board.

- **Colours (light):** board `#18241F` (sheets, search bar, chips, tiles), amber `#FFB020` (the Sinhala destination, progress, accents), board text `#EEF2EC`, muted `#93A39A`, page `#F2F4F1`, urgent `#E5484D`. **Dark:** page `#0F1714`, board `#1C2A24`, the same amber, urgent `#FF6B6E`. The map is recoloured to match: pale greys by day, deep green-black by night.
- **Type:** Barlow Semi Condensed for numbers and headings, Barlow for text, Anek Tamil for Tamil, Noto Sans Sinhala for Sinhala names; all OFL and bundled.
- **The signature:** the destination's Sinhala name large in amber on the board, as it appears on the bus; progress as a row of LED dots; at "Get off next" the whole sheet turns amber.
- **Shapes:** small radii (10 for controls, 18 for sheets), flat surfaces, no decorative shadows.
- **Motion:** numbers roll like a board, the dots light one by one, and the alert flips the board to amber in time with the vibration; a static path when the phone asks for reduced motion.

## What we know (research, 2026-11-03)

- **Live bus data in Sri Lanka:** only in pockets. LMT-GO "Metro Bus" (government, 7 Colombo pilot routes, live) with an unofficial open GTFS and live feed; "SP Bus" for SLTB buses in the Southern Province (Jan 2026). NTC has GPS on 1,500+ private buses but uses it for enforcement only, with no public data. Google Maps has only old Western Province timetables; Moovit doesn't cover Sri Lanka. Neither rider's routes are covered, so Hopin learns from their own rides.
- **Route data:** OpenStreetMap has only 83 Sri Lankan bus routes, mostly around Colombo, tagged unevenly. NTC's timetable page links to Google Drive folders (expressway and normal-way timetables) rather than listing routes, and its route map is an outside site (`203.189.65.204/ntc_routes`). So M2 starts with a data check, not a ready scraper. Town names in Sinhala and Tamil are widely present in OSM (`name:si`, `name:ta`), which gives the board text.
- **Android:** the activity recognition API is free and on the phone, and reports IN_VEHICLE, ON_BICYCLE, WALKING, RUNNING and STILL, but can't tell a bus from a car or tuk; that part is Hopin's own logic. Location in the background needs "Allow all the time" and a location foreground service; that's fine for a sideloaded app, since Play's background-location review doesn't apply.
- **Free packages only:** the well-known `flutter_background_geolocation` needs a paid licence for Android release builds, so it's out. Candidates to check against current docs in M1: `geolocator`, `flutter_activity_recognition`, `flutter_foreground_task`.

## Milestones

Each milestone gets a short grilling of its details before code.

- [ ] **M0 Setup**, in three steps:
  - [x] **M0a Project:** Flutter 3.44.2 app in `app/` (`app.hopin`, Android only, min SDK 26, English and Tamil through gen-l10n, a stand-in start page), CLAUDE.md, README, slim CI, release scripts and their tests, the Claude tooling in `.claude/`. Checked locally (analyze clean, 2 app tests, 15 tooling tests, debug APK), committed and published as a public repo on 2026-11-03.
  - [x] **M0b Firebase:** project `hopin-riders` on Spark under your account (`hopin-rides`, `hopin-app` and `hopin-bus` were taken), the Android app registered with this PC's debug key, Firestore (default) in asia-south1 with delete protection, Google sign-in shown as "Hopin" with the project's own support address. Rules v1: riders only (the `rider` claim), `people/{uid}` profiles, everything else closed; 12 tests on the emulator, each rule checked by breaking it on purpose. Created and the rules deployed on 2026-11-03 (PR #1). Your rider claim is set after your first sign-in, in M1a.
  - [x] **M0c Releases:** the signing key (outside the repo; GitHub's encrypted secrets for the workflow), the release key's fingerprints added to Firebase for Google sign-in, and `release.yml`: a push to main that ships a change builds the signed arm64 APK, checks its certificate and publishes a GitHub Release; a manual build-only run tests it without publishing. Checked locally (a 14.3 MB release APK carrying the release certificate), then proven by the real v0.1.0 release (checksum, certificate and key checked on the downloaded APK).
- [ ] **M1a Get-off guide:** pick a destination (saved place, search, map pin); a ride screen with your position on the map, the next town or stop, and distance and time to go; the vibration before your stop, working with the screen off; the optional spoken line. Started by hand in this step. Also Google sign-in (after which your rider claim is set), Settings with the language switch, and the update notice from GitHub Releases. In four pull requests, each a release:
  - [x] **M1a1 Shell and sign-in:** the Board theme (light and dark, bundled fonts, motion tokens), the app shell and routes, Google sign-in, your profile once you are a rider, and your rider claim set. Also the app icon (an amber H over three board lights) and a board-coloured launch. Checked on your phone with a debug build on 2026-11-03: sign-in, the rider claim, and the profile written. Released as v0.1.0 and installed on your phone.
  - [x] **M1a2 Home and places:** the MapLibre map with OpenFreeMap in the Board colours, your position (location while in use), Nominatim search with Sinhala and Tamil names, saved places and recents; the local database and sync start here. Checked on your phone on 2026-11-03, smooth in a profile build once the map rendered into a TextureView; the places rules are deployed. Ships as v0.2.0.
  - [ ] **M1a3 The guide:** the ride foreground service, the ride screen, alert stages with vibration patterns, auto-end and the missed-stop warning, the maker's battery guide.
  - [ ] **M1a4 Settings and updates:** language, the alert stages editor with "try it", the spoken line, battery guide, sign out, version, and the update notice.
- [ ] **M1b Ride detection:** activity recognition wakes GPS sampling only in a vehicle; bus logic scores the ride; the "On a bus?" notification with Yes and Not a bus; rides logged (private) and synced; corrections kept to tune the logic. Battery checked over a normal day.
- [ ] **M1c Sharing:** "Share this ride" shows the rider live on the other person's map until the ride ends; stops learned from rides (where buses keep halting) pooled between you.
- [ ] **M2 Which bus to take:** data check (NTC's Drive timetables and route map, OSM routes, the LMT feed), then grilling, then the screen: where you're going, the route numbers, where to board, and the board text in big Sinhala letters with English or Tamil beside it. Routes grow from logged rides and from what the riders add.
- [ ] **M3 Learned commute:** from the logged rides, when buses usually pass a stop and how long rides take by time of day; "leave now" suggestions for regular trips.
- [ ] **M4 Field test:** two weeks of real use by both of you, then fixes.

## Risks

- **Phone battery savers:** Xiaomi (MIUI or HyperOS) and Samsung (One UI) stop background apps beyond Android's own rules, and the riders use one of each. The app may need settings changed (Xiaomi: Autostart, battery saver "No restrictions"; Samsung: "Never sleeping apps", battery "Unrestricted"), with a one-time guide in the app.
- **Bus versus car or tuk:** the hybrid confirm covers mistakes; accuracy improves with corrections, not from day one.
- **Battery use:** GPS only during vehicle rides, sampled gently; measured in M1b.
- **M2 data:** NTC's files may be scans or hard to parse; the fallback is routes learned from rides plus the few the riders add by hand.

## Log

- 2026-11-03: Idea found and grilled (a live bus tracker reshaped into a personal bus companion for two riders). Plan written. Language changed to English by default with Tamil as a switch. Plan reviewed ("looks fine"). ARCHITECTURE.md drafted: the vehicle trigger is a native Kotlin receiver (Flutter's activity plugins only work while the app runs), rides run in a `flutter_foreground_task` service, and the Firebase project goes under your personal Google account (confirmed), with the second rider's account added later. Architecture reviewed ("fine"); the smooth UI, motion and colour requirement added; the Claude tooling installed for this project; M0 split into M0a, M0b and M0c, and M0a built and checked locally. The repo goes public: it holds nothing personal and no real GPS data, and the rules identify people by account ID.
- 2026-11-03: M0b. Firebase project `hopin-riders` created (the first three IDs were taken), with Firestore in Mumbai and Google sign-in. Setting up sign-in also created a "Default Web App", whose sign-in client Android's Google sign-in uses. Access changed from account IDs in the rules to a `rider` claim on the sign-in token, so the public repo holds no IDs at all and adding a rider needs no deploy. The App Distribution group moved to M0c, which now also decides between App Distribution and GitHub Releases.
- 2026-11-03: M0c. Installs go through GitHub Releases (your call, with the repo public): no cloud service account, no expiring builds, and the app offers updates itself from M1a. Signing key made and kept outside the repo; its fingerprints added to Firebase; `release.yml` checks every APK's certificate before publishing, and a build-only run tests the pipeline.
- 2026-11-03: M1a grilled (sign-in then use at once; map-first home; Nominatim search with Sinhala and Tamil names; alert stages with distances and vibration patterns, your call for "multiple options"; auto-end with a missed-stop warning; the ride screen). Look pass: three directions rendered from real widgets on real map data; you picked Board. The map moves to MapLibre with OpenFreeMap. M1a split into four releases.
- 2026-11-03: M1a1 built and checked on your phone: the Board theme with its bundled fonts, the app icon and board-coloured launch, Google sign-in, your rider claim set, and your profile written once a rider; 29 tests.
- 2026-11-03: The Firebase API key was in `firebase_options.dart` and GitHub's secret scanning flagged it in the public repo. Your call: no keys in the repo at all. The key was replaced (a new restricted key; the old one deleted), it now comes from the build (a git-ignored file here, the `FIREBASE_API_KEY` secret in Actions), the history was rewritten so no commit ever held a key, and the repo was deleted and published again (so pull request numbers start again at #1). v0.1.0 released from the clean repo and installed on your phone.
- 2026-11-03: M1a2 grilled (above), built and checked on your phone. The first try felt glitchy (the map stuttered and flickered when a sheet over it closed): the map's default Android view is embedded through a virtual display, so it now renders into a TextureView, its markers redraw one at a time and only when they move, and it loads on the Board's land colour.
