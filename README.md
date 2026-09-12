# RSI — Road Safety Insights

Το **RSI (Road Safety Insights)** είναι μία εφαρμογή πλοήγησης σε Flutter με βασικό στόχο την ενίσχυση της οδικής ασφάλειας.

Η εφαρμογή λειτουργεί ως navigation app, αλλά επιπλέον χρησιμοποιεί δεδομένα ιστορικών τροχαίων ατυχημάτων ώστε να εντοπίζει επικίνδυνες περιοχές κατά μήκος της ενεργής διαδρομής και να προειδοποιεί τον οδηγό πριν τις προσεγγίσει.

Το project βρίσκεται ακόμη σε development / prototype stage.

---

## Core Concept

Η βασική λογική της εφαρμογής είναι:

```text
User Location
      ↓
Destination Search
      ↓
Route Calculation
      ↓
Route Geometry
      ↓
Historical Accident Data
      ↓
Route / Hazard Matching
      ↓
Hazard Ahead Detection
      ↓
Visual + Audio Safety Warning
```

Η εφαρμογή δεν ελέγχει απλώς αν ένα ατύχημα βρίσκεται κοντά στις GPS συντεταγμένες του χρήστη.

Αντίθετα:

1. Υπολογίζει την ενεργή διαδρομή.
2. Προβάλλει τη θέση του οδηγού πάνω στη διαδρομή.
3. Προβάλλει κάθε hazard πάνω στη διαδρομή.
4. Ελέγχει αν το hazard βρίσκεται πραγματικά πάνω ή πολύ κοντά στο route corridor.
5. Υπολογίζει αν βρίσκεται **μπροστά** από τον οδηγό.
6. Εμφανίζει προειδοποίηση πριν την είσοδο στην επικίνδυνη περιοχή.

Παράδειγμα:

```text
Driver
  │
  │ 420 m
  ▼
Risk Zone
  │
  ▼
Destination
```

Η εφαρμογή μπορεί επομένως να εμφανίσει:

```text
Safety Alert
Historical accident zone
420 m ahead
```

αντί για ένα απλό:

```text
Accident nearby
```

---

# Tech Stack

* Flutter
* Dart
* Riverpod
* Mapbox Maps Flutter SDK
* Mapbox Search
* OSRM Routing
* latlong2
* Flutter Background Service
* Local GeoJSON accident dataset

---

# Project Structure

```text
lib/
├── config/
│   └── app_config.dart
│
├── core/
│   └── geo/
│       └── route_geometry.dart
│
├── models/
│   └── hazard_model.dart
│
├── providers/
│   ├── navigation_provider.dart
│   └── location_provider.dart
│
├── screens/
│   └── live_tracking_screen.dart
│
├── services/
│   ├── background_navigation_service.dart
│   ├── hazard_db_service.dart
│   ├── location_service.dart
│   ├── mapbox_service.dart
│   └── osrm_service.dart
│
├── widgets/
│   ├── route_summary_sheet.dart
│   ├── safety_alert_card.dart
│   └── turn_by_turn_panel.dart
│
└── main.dart
```

Additional application data:

```text
assets/
└── data/
    └── naxos_hazards.geojson
```

---

# Requirements

Recommended:

```text
Flutter stable
Dart SDK bundled with Flutter
VS Code or Android Studio
Xcode for iOS development
CocoaPods for iOS
Android SDK for Android development
```

Check the Flutter installation with:

```bash
flutter doctor
```

---

# Installation

Clone the repository:

```bash
git clone <repository-url>
```

Enter the project:

```bash
cd <project-folder>
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run analyzer:

```bash
flutter analyze
```

Run the application:

```bash
flutter run
```

---

# Required Configuration / Secrets

The application requires a **Mapbox Access Token**.

The token is intentionally not stored in the public/shared source code.

Required variable:

```text
MAPBOX_ACCESS_TOKEN
```

Run the app with:

```bash
flutter run \
  --dart-define=MAPBOX_ACCESS_TOKEN=YOUR_MAPBOX_ACCESS_TOKEN
```

The actual Mapbox token should be shared separately through a private communication channel.

Do not commit real credentials to GitHub.

---

# Routing

Routing currently uses OSRM.

Default routing endpoint:

```text
https://router.project-osrm.org
```

The current public OSRM endpoint does not require authentication.

It is suitable for development/testing, but a production deployment should eventually use either:

* a dedicated OSRM instance,
* Mapbox Directions,
* HERE,
* TomTom,
* or another production-grade routing provider.

---

# Maps & Search

Map rendering is handled through Mapbox.

Destination search uses Mapbox Search services.

The application currently provides:

* destination search,
* route calculation,
* route preview,
* navigation mode,
* GPS mode,
* simulation mode,
* map camera following,
* 2D / 3D navigation view.

---

# Accident / Hazard Data

Historical accident information is currently loaded from:

```text
assets/data/naxos_hazards.geojson
```

Each GeoJSON feature is converted to a `HazardFeature`.

Relevant fields include:

```text
id
hazardType
locationDescription
nearestArea
severity
date
weatherFactor
totalAccidents
recentAccidents
radiusMeters
coordinates
```

GeoJSON coordinates follow:

```text
[longitude, latitude]
```

---

# Route Geometry

Route geometry utilities are implemented in:

```text
lib/core/geo/route_geometry.dart
```

The system calculates the shortest distance between each hazard and the **actual route segment**, rather than only comparing a hazard against individual polyline coordinates.

Example:

```text
            Accident
               X
               │
               │ distance
               ↓
A ──────────────●────────────── B
             route
```

This prevents hazards from being missed when they are located between two sampled OSRM route points.

---

# Route-Aware Safety Detection

During navigation the application calculates:

```text
Driver distance along route

Hazard distance along route

Hazard distance ahead =
Hazard route position - Driver route position
```

Hazards behind the driver are ignored.

Only hazards ahead and within the configured warning range can trigger an alert.

Current prototype warning range is approximately:

```text
300 m – 800 m
```

depending on the hazard radius.

---

# Safety Alerts

During active navigation an approaching risk area can trigger:

* visual safety card,
* hazard distance ahead,
* hazard information,
* optional audio alert.

Example:

```text
SAFETY ALERT

Historical accident zone
410 m ahead

7 recorded incidents
```

The application keeps track of already-displayed hazards so the same zone is not repeatedly announced during the same navigation session.

---

# Simulation Mode

Simulation mode exists for testing navigation without physically driving the route.

Simulation movement is calculated in **meters along the route** rather than simply jumping between OSRM polyline coordinates.

This provides smoother movement and more realistic hazard testing.

Available speed multipliers can include:

```text
1×
5×
20×
50×
```

For visual testing, `5×` is recommended.

---

# Navigation UI

The current UI is inspired by modern navigation applications such as Google Maps, without copying Google branding or proprietary assets.

The interface includes:

* full-screen map,
* floating destination search,
* blue highlighted route,
* route overview sheet,
* navigation maneuver banner,
* recenter control,
* 2D / 3D mode,
* remaining distance / ETA,
* integrated safety alerts.

The safety mechanism is intentionally integrated into the navigation interface rather than displayed as a separate debug-style popup.

---

# State Management

Riverpod is used for navigation state.

Main navigation state includes:

```text
isNavigating
isSimulating
simulationMultiplier
activeRouteDetails
activeVehiclePosition
currentTurnInstruction
distanceToNextTurnMeters
activeApproachingHazard
activeHazardDistanceMeters
```

Nullable navigation values are handled explicitly so active hazards and route states can be correctly cleared.

---

# Current Development Status

Implemented:

* Map display
* Mapbox place search
* OSRM route calculation
* route preview
* simulated navigation
* live GPS navigation foundation
* turn-by-turn instruction parsing
* historical hazard loading
* route-segment hazard matching
* hazard-ahead detection
* safety warning UI
* audio warning support
* route camera following
* route simulation
* remaining distance / ETA

---

# Planned Development

Important next steps include:

### Road Safety Index

Introduce an RSI score:

```text
0–24     Low
25–49    Moderate
50–74    High
75–100   Very High
```

Possible factors:

* historical accident frequency,
* recent accidents,
* severity,
* weather sensitivity,
* road characteristics,
* time of day,
* accident recency.

The first version should be considered a **heuristic risk score**, not a statistically validated crash probability.

---

### Background Navigation

Further work is required for reliable background / locked-screen navigation.

This includes native configuration for:

```text
Android
- location permissions
- background location
- foreground location service
- notifications

iOS
- location permissions
- background location mode
- BackgroundTasks
- notification configuration
```

---

### Production Routing

The public OSRM server should eventually be replaced by a production routing service or dedicated server.

---

### Accident Dataset Expansion

The current dataset should eventually be expanded beyond the initial testing region and cover Greece.

Potential future data sources may include:

* official accident statistics,
* road authorities,
* police/open-government data,
* historical datasets,
* additional verified road-safety sources.

---

# Native Platforms

Depending on the repository version being shared, the native:

```text
android/
ios/
```

folders may be maintained separately.

If they are not included in this repository, the Flutter/Dart source remains under:

```text
lib/
```

but native platform configuration will need to be integrated separately before production deployment.

---

# Security

Never commit:

```text
Mapbox private tokens
API secrets
private backend keys
Apple signing certificates
Android keystores
keystore passwords
App Store Connect credentials
Google Play credentials
service account credentials
.env files containing secrets
```

Secrets should be provided separately to authorized developers.

---

# Development Workflow

Before committing changes:

```bash
flutter pub get
flutter analyze
```

Then test:

```bash
flutter run
```

Recommended Git workflow:

```text
main
develop
feature/navigation
feature/safety-engine
feature/ui
feature/background-location
```

---

# Important Notes

This project is currently under active development.

The accident warning functionality should be treated as a **driver-assistance / informational feature** and not as a replacement for attentive driving, road signs, official traffic information, or emergency services.

Risk classifications and safety scores must not be presented as guaranteed predictions of future accidents unless they are supported by an appropriately validated statistical methodology.

---

# Project Goal

The long-term objective of RSI is to evolve from:

```text
Navigation + accident markers
```

into:

```text
Navigation
+
Historical Road Safety Intelligence
+
Context-Aware Driver Warnings
```

The key differentiator of the project is not simply displaying where accidents occurred, but understanding whether the driver is approaching a historically dangerous road segment **on their current route** and providing a useful warning before they enter that area.
