# geofence_haversine

[![pub package](https://img.shields.io/pub/v/geofence_haversine.svg)](https://pub.dev/packages/geofence_haversine)
[![package publisher](https://img.shields.io/pub/publisher/geofence_haversine.svg)](https://pub.dev/packages/geofence_haversine/publisher)
[![Dart CI](https://github.com/Safeer-Hussain/geofence_haversine/actions/workflows/ci.yml/badge.svg)](https://github.com/Safeer-Hussain/geofence_haversine/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A zero-external-dependency, pure Dart geospatial calculation and circular geofencing library powered by the spherical Haversine formula. Engineered for high performance across all platforms including Flutter (Android, iOS, macOS, Windows, Linux, Web) and Dart server or CLI environments (including WebAssembly).

## Features

- Zero external dependencies: Built strictly with the Dart standard library (`dart:math`).
- Universal platform compatibility: 100% pure Dart, fully compatible with WebAssembly (Wasm), Flutter, server, and CLI runtimes.
- Spherical Haversine distance: High-precision great-circle distance calculations in meters and kilometers.
- Compass bearing: Initial forward azimuth calculation normalized to `[0.0, 360.0)` degrees.
- Coordinate projection: Project destination coordinates from a starting point, distance, and bearing.
- Polyline & Route ETA estimation: Cumulative multi-waypoint path length and travel time estimation based on target speed.
- Circular geofence state evaluation: Discrete detection of entry, exit, dwelling, and outside presence transitions.
- Multi-zone fleet monitoring: Single-pass batch geofence evaluation with automatic nearest-neighbor sorting.
- Immutable data structures: Full support for value equality, hash codes, and JSON serialization.

## Installation

Add `geofence_haversine` to your project dependencies:

### Dart CLI or Server

```bash
dart pub add geofence_haversine
```

### Flutter

```bash
flutter pub add geofence_haversine
```

Or add it directly to your `pubspec.yaml`:

```yaml
dependencies:
  geofence_haversine: ^0.1.0
```

## Geofence State Transitions

The library evaluates state transitions between consecutive location events:

| Previous State | Current State | Resulting Transition | Description |
|---|---|---|---|
| null (Initial) | Inside | `dwellingInside` | First evaluation discovered within the zone radius. |
| null (Initial) | Outside | `remainingOutside` | First evaluation discovered outside the zone radius. |
| Outside (`false`) | Inside (`true`) | `entered` | Position transitioned across the boundary from outside to inside. |
| Inside (`true`) | Outside (`false`) | `exited` | Position transitioned across the boundary from inside to outside. |
| Inside (`true`) | Inside (`true`) | `dwellingInside` | Position persisted inside the zone boundary. |
| Outside (`false`) | Outside (`false`) | `remainingOutside` | Position persisted outside the zone boundary. |

Each evaluation also yields `signedBoundaryOffsetMeters`:
- A negative value indicates that the position is inside the perimeter (e.g. `-250.0` meters from the boundary toward the center).
- A positive value indicates that the position is outside the perimeter (e.g. `+150.0` meters past the boundary).

## Usage

### Distance and Compass Bearing

```dart
import 'package:geofence_haversine/geofence_haversine.dart';

void main() {
  const engine = HaversineGeofenceEngine();

  const lahore = GeoCoordinate(latitude: 31.5204, longitude: 74.3587);
  const islamabad = GeoCoordinate(latitude: 33.6844, longitude: 73.0479);

  final distanceKm = engine.distanceKilometers(lahore, islamabad);
  final bearing = engine.initialBearingDegrees(lahore, islamabad);

  print('Distance: ${distanceKm.toStringAsFixed(2)} km');
  print('Initial Bearing: ${bearing.toStringAsFixed(2)} degrees');
}
```

### Destination Projection

```dart
import 'package:geofence_haversine/geofence_haversine.dart';

void main() {
  const engine = HaversineGeofenceEngine();
  const origin = GeoCoordinate(latitude: 31.5204, longitude: 74.3587);

  // Project 25 km forward along an azimuth of 45 degrees
  final target = engine.projectCoordinate(
    origin,
    distanceMeters: 25000.0,
    bearingDegrees: 45.0,
  );

  print('Projected point: ${target.latitude}, ${target.longitude}');
}
```

### Multi-Waypoint Route ETA Estimation

```dart
import 'package:geofence_haversine/geofence_haversine.dart';

void main() {
  const engine = HaversineGeofenceEngine();

  final routeWaypoints = [
    const GeoCoordinate(latitude: 31.5204, longitude: 74.3587),
    const GeoCoordinate(latitude: 32.1877, longitude: 74.1945),
    const GeoCoordinate(latitude: 32.9328, longitude: 73.7268),
    const GeoCoordinate(latitude: 33.6844, longitude: 73.0479),
  ];

  final eta = engine.calculateRouteEta(routeWaypoints, speedKmh: 65.0);

  print('Total Distance: ${eta.totalDistanceKilometers.toStringAsFixed(2)} km');
  print('Estimated Travel Duration: ${eta.estimatedDuration.inHours}h ${eta.estimatedDuration.inMinutes % 60}m');
}
```

### Single Zone and Fleet Geofence Evaluation

```dart
import 'package:geofence_haversine/geofence_haversine.dart';

void main() {
  const engine = HaversineGeofenceEngine();

  const depotZone = GeofenceZone(
    id: 'depot_alpha',
    label: 'Main Warehouse Depot',
    center: GeoCoordinate(latitude: 31.5200, longitude: 74.3580),
    radiusMeters: 500.0,
  );

  const vehiclePosition = GeoCoordinate(latitude: 31.5205, longitude: 74.3582);

  // Single zone evaluation
  final evaluation = engine.evaluateZone(
    depotZone,
    vehiclePosition,
    wasPreviouslyInside: false,
  );

  print('Zone: ${evaluation.zoneLabel}');
  print('Inside: ${evaluation.isInside}');
  print('Transition: ${evaluation.transition.name}');
  print('Distance from center: ${evaluation.distanceFromCenterMeters.toStringAsFixed(1)} m');

  // Multi-zone fleet monitoring (results returned sorted by nearest center distance)
  const deliveryHub = GeofenceZone(
    id: 'hub_beta',
    label: 'North Distribution Hub',
    center: GeoCoordinate(latitude: 31.5350, longitude: 74.3500),
    radiusMeters: 750.0,
  );

  final fleetEvaluations = engine.evaluateFleetZones(
    [depotZone, deliveryHub],
    vehiclePosition,
    previousInsideState: {'depot_alpha': false, 'hub_beta': false},
  );

  for (final item in fleetEvaluations) {
    print('${item.zoneLabel}: ${item.distanceFromCenterMeters.toStringAsFixed(1)} m away');
  }
}
```

## Repository & Bug Tracker

- Source Code: [GitHub Repository](https://github.com/Safeer-Hussain/geofence_haversine)
- Issue Tracker: [GitHub Issues](https://github.com/Safeer-Hussain/geofence_haversine/issues)

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/Safeer-Hussain/geofence_haversine/blob/main/LICENSE) file for details.
