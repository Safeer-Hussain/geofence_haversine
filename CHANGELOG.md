## 0.1.0

- Initial stable release of geofence_haversine.
- Pure Dart, zero-dependency spherical Haversine distance computations in meters and kilometers.
- Compass forward azimuth / initial bearing calculations normalized to `[0.0, 360.0)`.
- Great-circle destination waypoint projection from range and bearing.
- Multi-waypoint polyline cumulative distance and route ETA duration estimation.
- Circular geofence state evaluation for `entered`, `exited`, `dwellingInside`, and `remainingOutside` transitions.
- Multi-zone fleet evaluation with automated proximity sorting.
- Immutable data structures with structural equality and JSON coordinate serialization.
