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
4. Map: OpenStreetMap through `flutter_map`, with place names in English, Tamil and Sinhala from OSM where present.
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
  - [ ] **M0c Releases:** the signing key (outside the repo; GitHub's encrypted secrets for the workflow), the release key's fingerprints added to Firebase for Google sign-in, and `release.yml`: a push to main that ships a change builds the signed arm64 APK, checks its certificate and publishes a GitHub Release; a manual build-only run tests it without publishing. Checked locally (a 14.3 MB release APK carrying the release certificate). After merging: you add the four secrets, then one build-only run.
- [ ] **M1a Get-off guide:** pick a destination (saved place, search, map pin); a ride screen with your position on the map, the next town or stop, and distance and time to go; the vibration before your stop, working with the screen off; the optional spoken line. Started by hand in this step. Also Google sign-in (after which your rider claim is set), Settings with the language switch, and the update notice from GitHub Releases.
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
