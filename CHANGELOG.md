# Changelog

Notable changes to Road Safety Insights. All accident, road segment and rental
data in this release is mock data for development.

## [Unreleased] - 2026-09-12

Branch: `feature/safety-map-rentals-onboarding`

### Added

- **Map filters.** A filter button with an active-filter badge in the search
  bar opens a sheet:
  - show or hide accidents and road risk
  - filter accidents by severity and time period (last 12 months, last
    3 years, all time)
  - filter roads by risk level
  - Reset returns everything to the defaults

  Changes apply immediately and clusters recount. Road colours always use all
  recorded accidents.
- **Road risk classification.**
  - 24 road segments in central Athens and Ioannina are drawn green, yellow,
    orange or red for Low, Moderate, High and Very high risk.
  - The heuristic 0–100 score uses bands of 0–24, 25–49, 50–74 and 75–100.
  - Inputs: accidents within 75 m per km of road, severity, injuries,
    deaths, recency, and road features (speed limit, junction, lighting,
    pedestrian activity).
  - Tap a road for its level, "Risk Score: NN/100", accident counts, the
    period covered and its road features.
- **Accident points.**
  - 78 accidents (46 in Athens, 32 in Ioannina) are shown as points
    coloured by severity.
  - Nearby points group into clusters; tap a cluster to zoom in.
  - Tap a point for its date, location, severity, injured, deaths, accident
    type, likely cause and source, where available.
- **Car rentals.**
  - A draggable sheet on the map shows partner offers (discount badge,
    original price crossed out), then all cars.
  - A details page shows specs, rental terms and pick-up location, with a
    contact sheet.
  - Data covers 2 partner companies and 8 cars, with freely licensed photos
    (credits in `assets/images/rentals/CREDITS.md`).
- **First-launch onboarding.**
  - Three short intro pages, then a choice to share location.
  - Location permission is only requested when the user opts in.
  - The choice is saved on the device. If the user skips, the location
    button asks later.
- **Side drawer** with About, Terms & Conditions and Privacy Policy pages.
- **Terms & Conditions and Privacy Policy.** Full documents in
  `assets/legal/`, shown in the app.
  - Terms: 18 sections, covering safety while driving, accident data and risk
    estimates, third-party maps and routes, rentals and partner offers, and
    liability.
  - Privacy Policy: 13 sections, covering GDPR legal bases, service providers
    (Mapbox, routing, Google location services), your rights and the Hellenic
    Data Protection Authority.
  - Bracketed placeholders (company details, contact email, dates, routing
    provider) must be completed, and both texts reviewed by a lawyer, before
    release.
- **Map compass.** The needle follows the map's rotation, and tapping it
  resets the map to north. During navigation it switches between north-up
  and heading-up.
- **App identity.** Package `com.roadsafetyinsights.app`, name "Road Safety
  Insights", and a shield-and-road adaptive launcher icon.
- **Developer tool.** `tool/snap_road_segments.py` snaps the mock road
  segments onto real roads using OSRM map matching.
- **Tests.** 73 unit and widget tests (`flutter test`).

### Changed

- The map starts at Athens, then centres on the user after the first GPS fix.
- Map rotation gestures are enabled, and the location dot is smaller.
- Location updates only start after the user agrees to share location.
- The Mapbox logo and map buttons sit above the rentals sheet.
- Mock accidents and road segments follow real streets. Segments are map
  matched or traced from OpenStreetMap.

### Fixed

- Build error caused by an undeclared route index field.
- The location button no longer snaps the camera back to Athens. The map
  viewport was being recreated on every rebuild.
- Crash on launch after navigation had been started. The background service
  used a notification channel the app never created ("Bad notification for
  startForeground").
- Location updates could stay off after the first launch when they started
  before permission was granted.
- Road risk lines were hard to tap. Taps within about 20 dp of a line now
  select it. Accident points drawn on top still take priority.
