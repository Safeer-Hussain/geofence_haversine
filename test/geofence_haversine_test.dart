import 'package:geofence_haversine/geofence_haversine.dart';
import 'package:test/test.dart';

void main() {
  const engine = HaversineGeofenceEngine();

  group('GeoCoordinate', () {
    test('instantiates valid coordinates successfully', () {
      const coord = GeoCoordinate(latitude: 31.5204, longitude: 74.3587);
      expect(coord.latitude, equals(31.5204));
      expect(coord.longitude, equals(74.3587));
    });

    test('throws AssertionError on invalid latitude bounds', () {
      expect(
        () => GeoCoordinate(latitude: 90.001, longitude: 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GeoCoordinate(latitude: -90.001, longitude: 0.0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws AssertionError on invalid longitude bounds', () {
      expect(
        () => GeoCoordinate(latitude: 0.0, longitude: 180.001),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GeoCoordinate(latitude: 0.0, longitude: -180.001),
        throwsA(isA<AssertionError>()),
      );
    });

    test('supports copyWith, equality, hashCode, and toString', () {
      const a = GeoCoordinate(latitude: 10.0, longitude: 20.0);
      final b = a.copyWith(latitude: 15.0);
      final c = a.copyWith();

      expect(b.latitude, equals(15.0));
      expect(b.longitude, equals(20.0));
      expect(a == c, isTrue);
      expect(a == b, isFalse);
      expect(a.hashCode, equals(c.hashCode));
      expect(a.toString(),
          contains('GeoCoordinate(latitude: 10.0, longitude: 20.0)'));
    });

    test('serializes to and from JSON', () {
      const original = GeoCoordinate(latitude: -25.2744, longitude: 133.7751);
      final json = original.toJson();
      final reconstructed = GeoCoordinate.fromJson(json);

      expect(reconstructed, equals(original));
      expect(json['latitude'], equals(-25.2744));
      expect(json['longitude'], equals(133.7751));
    });
  });

  group('GeofenceZone', () {
    test('enforces positive radius constraint', () {
      expect(
        () => GeofenceZone(
          id: 'test_1',
          label: 'Test Zone',
          center: const GeoCoordinate(latitude: 0.0, longitude: 0.0),
          radiusMeters: 0.0,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => GeofenceZone(
          id: 'test_2',
          label: 'Negative Zone',
          center: const GeoCoordinate(latitude: 0.0, longitude: 0.0),
          radiusMeters: -50.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('supports copyWith, equality, hashCode, and toString', () {
      const zoneA = GeofenceZone(
        id: 'z1',
        label: 'Zone One',
        center: GeoCoordinate(latitude: 10.0, longitude: 20.0),
        radiusMeters: 500.0,
      );
      final zoneB = zoneA.copyWith(label: 'Updated Zone');
      final zoneC = zoneA.copyWith();

      expect(zoneB.label, equals('Updated Zone'));
      expect(zoneB.radiusMeters, equals(500.0));
      expect(zoneA == zoneC, isTrue);
      expect(zoneA == zoneB, isFalse);
      expect(zoneA.hashCode, equals(zoneC.hashCode));
      expect(zoneA.toString(), contains('GeofenceZone(id: z1'));
    });
  });

  group('Haversine Distance & Bearing Calculations', () {
    test('returns zero distance for identical coordinates', () {
      const coord = GeoCoordinate(latitude: 51.5074, longitude: -0.1278);
      expect(engine.distanceMeters(coord, coord), equals(0.0));
      expect(engine.distanceKilometers(coord, coord), equals(0.0));
      expect(engine.initialBearingDegrees(coord, coord), equals(0.0));
    });

    test('computes accurate great-circle distance between known landmarks', () {
      // Lahore (31.5204, 74.3587) to Islamabad (33.6844, 73.0479)
      const lahore = GeoCoordinate(latitude: 31.5204, longitude: 74.3587);
      const islamabad = GeoCoordinate(latitude: 33.6844, longitude: 73.0479);

      final distanceKm = engine.distanceKilometers(lahore, islamabad);
      final distanceM = engine.distanceMeters(lahore, islamabad);

      // Expected geodesic distance is roughly 270 km +/- 3 km
      expect(distanceKm, closeTo(270.8, 3.0));
      expect(distanceM, closeTo(270800.0, 3000.0));
    });

    test('computes exact cardinal bearings', () {
      const origin = GeoCoordinate(latitude: 0.0, longitude: 0.0);

      const north = GeoCoordinate(latitude: 10.0, longitude: 0.0);
      const east = GeoCoordinate(latitude: 0.0, longitude: 10.0);
      const south = GeoCoordinate(latitude: -10.0, longitude: 0.0);
      const west = GeoCoordinate(latitude: 0.0, longitude: -10.0);

      expect(engine.initialBearingDegrees(origin, north), closeTo(0.0, 0.001));
      expect(engine.initialBearingDegrees(origin, east), closeTo(90.0, 0.001));
      expect(
          engine.initialBearingDegrees(origin, south), closeTo(180.0, 0.001));
      expect(engine.initialBearingDegrees(origin, west), closeTo(270.0, 0.001));
    });

    test('projects coordinates with high round-trip accuracy', () {
      const start = GeoCoordinate(latitude: 31.5204, longitude: 74.3587);
      const distance = 15000.0; // 15 km
      const bearing = 45.0; // North-East

      final projected = engine.projectCoordinate(
        start,
        distanceMeters: distance,
        bearingDegrees: bearing,
      );

      final measuredDistance = engine.distanceMeters(start, projected);
      final measuredBearing = engine.initialBearingDegrees(start, projected);

      expect(measuredDistance, closeTo(distance, 0.01));
      expect(measuredBearing, closeTo(bearing, 0.01));
    });

    test('projectCoordinate with zero distance returns original coordinate',
        () {
      const start = GeoCoordinate(latitude: 12.34, longitude: 56.78);
      final result = engine.projectCoordinate(
        start,
        distanceMeters: 0.0,
        bearingDegrees: 180.0,
      );
      expect(result, equals(start));
    });
  });

  group('Polyline Length & Route ETA Estimation', () {
    test(
        'evaluates polyline length across empty, single, and multi-point routes',
        () {
      const p1 = GeoCoordinate(latitude: 0.0, longitude: 0.0);
      const p2 = GeoCoordinate(latitude: 1.0, longitude: 0.0);
      const p3 = GeoCoordinate(latitude: 1.0, longitude: 1.0);

      expect(engine.polylineLengthMeters([]), equals(0.0));
      expect(engine.polylineLengthMeters([p1]), equals(0.0));

      final seg1 = engine.distanceMeters(p1, p2);
      final seg2 = engine.distanceMeters(p2, p3);
      final total = engine.polylineLengthMeters([p1, p2, p3]);

      expect(total, closeTo(seg1 + seg2, 0.001));
    });

    test(
        'calculateRouteEta returns zero summary for empty and single waypoints',
        () {
      final emptyEta = engine.calculateRouteEta([]);
      expect(emptyEta.totalDistanceMeters, equals(0.0));
      expect(emptyEta.estimatedDuration, equals(Duration.zero));
      expect(emptyEta.waypointCount, equals(0));

      final singleEta = engine.calculateRouteEta([
        const GeoCoordinate(latitude: 10.0, longitude: 20.0),
      ]);
      expect(singleEta.totalDistanceMeters, equals(0.0));
      expect(singleEta.estimatedDuration, equals(Duration.zero));
      expect(singleEta.waypointCount, equals(1));
    });

    test('calculateRouteEta calculates accurate duration and initial bearing',
        () {
      const p1 = GeoCoordinate(latitude: 0.0, longitude: 0.0);
      // Project 100 km North
      final p2 = engine.projectCoordinate(
        p1,
        distanceMeters: 100000.0,
        bearingDegrees: 0.0,
      );

      // At 100 km/h, 100 km should take exactly 1 hour (3600 seconds)
      final summary = engine.calculateRouteEta([p1, p2], speedKmh: 100.0);

      expect(summary.totalDistanceKilometers, closeTo(100.0, 0.01));
      expect(summary.estimatedDuration.inSeconds, equals(3600));
      expect(summary.initialBearingDegrees, closeTo(0.0, 0.01));
      expect(summary.waypointCount, equals(2));
    });

    test('calculateRouteEta asserts strictly positive speed', () {
      expect(
        () => engine.calculateRouteEta(
          [const GeoCoordinate(latitude: 0.0, longitude: 0.0)],
          speedKmh: 0.0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => engine.calculateRouteEta(
          [const GeoCoordinate(latitude: 0.0, longitude: 0.0)],
          speedKmh: -10.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Geofence Evaluation & State Transitions', () {
    const center = GeoCoordinate(latitude: 31.5200, longitude: 74.3580);
    const zone = GeofenceZone(
      id: 'z_test',
      label: 'Test Depot',
      center: center,
      radiusMeters: 1000.0, // 1 km radius
    );

    // 500 meters away (inside)
    final insidePoint = engine.projectCoordinate(
      center,
      distanceMeters: 500.0,
      bearingDegrees: 90.0,
    );

    // 1500 meters away (outside)
    final outsidePoint = engine.projectCoordinate(
      center,
      distanceMeters: 1500.0,
      bearingDegrees: 90.0,
    );

    test('evaluates initial state with null previous state', () {
      final insideEval = engine.evaluateZone(
        zone,
        insidePoint,
        wasPreviouslyInside: null,
      );
      expect(insideEval.isInside, isTrue);
      expect(insideEval.transition, equals(GeofenceTransition.dwellingInside));

      final outsideEval = engine.evaluateZone(
        zone,
        outsidePoint,
        wasPreviouslyInside: null,
      );
      expect(outsideEval.isInside, isFalse);
      expect(
          outsideEval.transition, equals(GeofenceTransition.remainingOutside));
    });

    test(
        'evaluates entered transition when transitioning from outside to inside',
        () {
      final eval = engine.evaluateZone(
        zone,
        insidePoint,
        wasPreviouslyInside: false,
      );
      expect(eval.isInside, isTrue);
      expect(eval.transition, equals(GeofenceTransition.entered));
    });

    test(
        'evaluates exited transition when transitioning from inside to outside',
        () {
      final eval = engine.evaluateZone(
        zone,
        outsidePoint,
        wasPreviouslyInside: true,
      );
      expect(eval.isInside, isFalse);
      expect(eval.transition, equals(GeofenceTransition.exited));
    });

    test('evaluates dwellingInside when remaining inside across evaluations',
        () {
      final eval = engine.evaluateZone(
        zone,
        insidePoint,
        wasPreviouslyInside: true,
      );
      expect(eval.isInside, isTrue);
      expect(eval.transition, equals(GeofenceTransition.dwellingInside));
    });

    test('evaluates remainingOutside when remaining outside across evaluations',
        () {
      final eval = engine.evaluateZone(
        zone,
        outsidePoint,
        wasPreviouslyInside: false,
      );
      expect(eval.isInside, isFalse);
      expect(eval.transition, equals(GeofenceTransition.remainingOutside));
    });

    test('calculates correct signedBoundaryOffsetMeters', () {
      final insideEval = engine.evaluateZone(zone, insidePoint);
      // inside: distance is ~500m, radius is 1000m -> offset ~ -500m
      expect(insideEval.signedBoundaryOffsetMeters, closeTo(-500.0, 0.1));

      final outsideEval = engine.evaluateZone(zone, outsidePoint);
      // outside: distance is ~1500m, radius is 1000m -> offset ~ +500m
      expect(outsideEval.signedBoundaryOffsetMeters, closeTo(500.0, 0.1));
    });

    test(
        'evaluateFleetZones evaluates and sorts zones by nearest center distance',
        () {
      // 3 zones at 200m, 1000m, and 500m from current position
      const currentPos = GeoCoordinate(latitude: 31.5200, longitude: 74.3580);

      final zoneFar = GeofenceZone(
        id: 'far',
        label: 'Far Zone',
        center: engine.projectCoordinate(currentPos,
            distanceMeters: 1000.0, bearingDegrees: 0.0),
        radiusMeters: 200.0,
      );

      final zoneNear = GeofenceZone(
        id: 'near',
        label: 'Near Zone',
        center: engine.projectCoordinate(currentPos,
            distanceMeters: 200.0, bearingDegrees: 90.0),
        radiusMeters: 200.0,
      );

      final zoneMid = GeofenceZone(
        id: 'mid',
        label: 'Mid Zone',
        center: engine.projectCoordinate(currentPos,
            distanceMeters: 500.0, bearingDegrees: 180.0),
        radiusMeters: 200.0,
      );

      final evaluations = engine.evaluateFleetZones(
        [zoneFar, zoneNear, zoneMid],
        currentPos,
        previousInsideState: {'near': false, 'far': false, 'mid': false},
      );

      expect(evaluations.length, equals(3));
      expect(evaluations[0].zoneId, equals('near'));
      expect(evaluations[1].zoneId, equals('mid'));
      expect(evaluations[2].zoneId, equals('far'));

      expect(evaluations[0].distanceFromCenterMeters,
          lessThan(evaluations[1].distanceFromCenterMeters));
      expect(evaluations[1].distanceFromCenterMeters,
          lessThan(evaluations[2].distanceFromCenterMeters));
    });
  });

  group('Model Structural Equality & HashCode', () {
    test('GeofenceEvaluation equality and hashCode', () {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final eval1 = GeofenceEvaluation(
        zoneId: 'z1',
        zoneLabel: 'Zone 1',
        isInside: true,
        transition: GeofenceTransition.entered,
        distanceFromCenterMeters: 100.0,
        signedBoundaryOffsetMeters: -50.0,
        evaluatedAtUtc: now,
      );

      final eval2 = GeofenceEvaluation(
        zoneId: 'z1',
        zoneLabel: 'Zone 1',
        isInside: true,
        transition: GeofenceTransition.entered,
        distanceFromCenterMeters: 100.0,
        signedBoundaryOffsetMeters: -50.0,
        evaluatedAtUtc: now,
      );

      expect(eval1, equals(eval2));
      expect(eval1.hashCode, equals(eval2.hashCode));
      expect(eval1.toString(), contains('GeofenceEvaluation(zoneId: z1'));
    });

    test('RouteEtaSummary equality and hashCode', () {
      const s1 = RouteEtaSummary(
        totalDistanceMeters: 1000.0,
        totalDistanceKilometers: 1.0,
        estimatedDuration: Duration(minutes: 5),
        initialBearingDegrees: 45.0,
        waypointCount: 2,
      );

      const s2 = RouteEtaSummary(
        totalDistanceMeters: 1000.0,
        totalDistanceKilometers: 1.0,
        estimatedDuration: Duration(minutes: 5),
        initialBearingDegrees: 45.0,
        waypointCount: 2,
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1.toString(),
          contains('RouteEtaSummary(totalDistanceMeters: 1000.0'));
    });
  });
}
