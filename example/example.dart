import 'package:geofence_haversine/geofence_haversine.dart';

void main() {
  const engine = HaversineGeofenceEngine();

  // 1. Point-to-point distance and bearing
  const lahore = GeoCoordinate(latitude: 31.5204, longitude: 74.3587);
  const islamabad = GeoCoordinate(latitude: 33.6844, longitude: 73.0479);

  final distanceKm = engine.distanceKilometers(lahore, islamabad);
  final bearing = engine.initialBearingDegrees(lahore, islamabad);

  print(
      'Distance between Lahore and Islamabad: ${distanceKm.toStringAsFixed(2)} km');
  print('Initial compass bearing: ${bearing.toStringAsFixed(2)} degrees');

  // 2. Destination projection
  final projectedPoint = engine.projectCoordinate(
    lahore,
    distanceMeters: 50000.0,
    bearingDegrees: bearing,
  );
  print(
    'Point 50 km along route: '
    'lat ${projectedPoint.latitude.toStringAsFixed(4)}, '
    'lon ${projectedPoint.longitude.toStringAsFixed(4)}',
  );

  // 3. Multi-stop route ETA calculation
  const rawalpindi = GeoCoordinate(latitude: 33.5651, longitude: 73.0169);
  final route = [lahore, projectedPoint, rawalpindi, islamabad];

  final etaSummary = engine.calculateRouteEta(route, speedKmh: 80.0);
  print(
      'Total route distance: ${etaSummary.totalDistanceKilometers.toStringAsFixed(2)} km');
  print(
      'Estimated travel duration at 80 km/h: ${etaSummary.estimatedDuration.inMinutes} minutes');

  // 4. Geofence evaluation and transitions
  const depotZone = GeofenceZone(
    id: 'zone_depot_01',
    label: 'Central Logistics Hub',
    center: GeoCoordinate(latitude: 31.5200, longitude: 74.3580),
    radiusMeters: 500.0,
  );

  // Outside position
  const outsidePosition = GeoCoordinate(latitude: 31.5300, longitude: 74.3580);
  final initialEval = engine.evaluateZone(
    depotZone,
    outsidePosition,
    wasPreviouslyInside: null,
  );
  print(
      'Initial state outside: ${initialEval.transition.name}, inside: ${initialEval.isInside}');

  // Approaching and entering the zone
  const insidePosition = GeoCoordinate(latitude: 31.5202, longitude: 74.3582);
  final entryEval = engine.evaluateZone(
    depotZone,
    insidePosition,
    wasPreviouslyInside: initialEval.isInside,
  );
  print(
      'Transition on entry: ${entryEval.transition.name}, offset: ${entryEval.signedBoundaryOffsetMeters.toStringAsFixed(1)} m');

  // Dwelling inside
  final dwellEval = engine.evaluateZone(
    depotZone,
    insidePosition,
    wasPreviouslyInside: entryEval.isInside,
  );
  print('Transition while dwelling: ${dwellEval.transition.name}');

  // Exiting the zone
  final exitEval = engine.evaluateZone(
    depotZone,
    outsidePosition,
    wasPreviouslyInside: dwellEval.isInside,
  );
  print('Transition on exit: ${exitEval.transition.name}');
}
