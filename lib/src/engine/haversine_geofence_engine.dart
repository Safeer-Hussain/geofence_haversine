/// Core computational engine for Haversine distances, bearings, and geofencing.
library;

import 'dart:math';

import '../models/geo_coordinate.dart';
import '../models/geofence_evaluation.dart';
import '../models/geofence_zone.dart';
import '../models/route_eta_summary.dart';

/// Pure Dart calculation engine for spherical geospatial trigonometry and geofence evaluation.
class HaversineGeofenceEngine {
  /// The mean Earth radius in meters used for spherical calculations.
  ///
  /// Defaults to 6,371,008.8 meters (IUGG recommended mean Earth radius).
  final double earthRadiusMeters;

  /// Creates a stateless [HaversineGeofenceEngine] instance with an optional Earth radius.
  const HaversineGeofenceEngine({
    this.earthRadiusMeters = 6371008.8,
  });

  /// Computes the great-circle geodesic distance in meters between [origin] and [destination]
  /// using the spherical Haversine formula.
  double distanceMeters(GeoCoordinate origin, GeoCoordinate destination) {
    if (origin == destination) return 0.0;

    final lat1 = _degreesToRadians(origin.latitude);
    final lon1 = _degreesToRadians(origin.longitude);
    final lat2 = _degreesToRadians(destination.latitude);
    final lon2 = _degreesToRadians(destination.longitude);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final sinHalfDLat = sin(dLat / 2.0);
    final sinHalfDLon = sin(dLon / 2.0);

    final a = sinHalfDLat * sinHalfDLat +
        cos(lat1) * cos(lat2) * sinHalfDLon * sinHalfDLon;

    final c = 2.0 * atan2(sqrt(a), sqrt(max(0.0, 1.0 - a)));
    return earthRadiusMeters * c;
  }

  /// Computes the great-circle geodesic distance in kilometers between [origin] and [destination].
  double distanceKilometers(GeoCoordinate origin, GeoCoordinate destination) {
    return distanceMeters(origin, destination) / 1000.0;
  }

  /// Computes the forward azimuth / initial compass bearing in degrees `[0.0, 360.0)`
  /// from [origin] towards [destination].
  double initialBearingDegrees(
    GeoCoordinate origin,
    GeoCoordinate destination,
  ) {
    if (origin == destination) return 0.0;

    final lat1 = _degreesToRadians(origin.latitude);
    final lat2 = _degreesToRadians(destination.latitude);
    final dLon = _degreesToRadians(destination.longitude - origin.longitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final radians = atan2(y, x);
    final degrees = _radiansToDegrees(radians);
    final normalized = (degrees + 360.0) % 360.0;
    return normalized == 360.0 ? 0.0 : normalized;
  }

  /// Calculates a destination coordinate by projecting [origin] along a forward
  /// great-circle track defined by [bearingDegrees] across [distanceMeters].
  GeoCoordinate projectCoordinate(
    GeoCoordinate origin, {
    required double distanceMeters,
    required double bearingDegrees,
  }) {
    if (distanceMeters == 0.0) {
      return origin;
    }

    final angularDistance = distanceMeters / earthRadiusMeters;
    final bearingRad = _degreesToRadians(bearingDegrees);
    final lat1 = _degreesToRadians(origin.latitude);
    final lon1 = _degreesToRadians(origin.longitude);

    final sinLat1 = sin(lat1);
    final cosLat1 = cos(lat1);
    final sinAngularDistance = sin(angularDistance);
    final cosAngularDistance = cos(angularDistance);

    final sinLat2 = sinLat1 * cosAngularDistance +
        cosLat1 * sinAngularDistance * cos(bearingRad);
    final clampedSinLat2 = sinLat2.clamp(-1.0, 1.0);
    final lat2 = asin(clampedSinLat2);

    final y = sin(bearingRad) * sinAngularDistance * cosLat1;
    final x = cosAngularDistance - sinLat1 * sin(lat2);
    final lon2 = lon1 + atan2(y, x);

    final latDeg = _radiansToDegrees(lat2).clamp(-90.0, 90.0);
    final lonDegRaw = _radiansToDegrees(lon2);
    final lonDeg = (((lonDegRaw + 180.0) % 360.0) + 360.0) % 360.0 - 180.0;

    return GeoCoordinate(
      latitude: latDeg,
      longitude: lonDeg.clamp(-180.0, 180.0),
    );
  }

  /// Computes cumulative polyline distance in meters across an ordered list of [waypoints].
  double polylineLengthMeters(Iterable<GeoCoordinate> waypoints) {
    final list = waypoints.toList(growable: false);
    if (list.length < 2) return 0.0;

    var totalDistance = 0.0;
    for (var i = 0; i < list.length - 1; i++) {
      totalDistance += distanceMeters(list[i], list[i + 1]);
    }
    return totalDistance;
  }

  /// Calculates route travel distance, initial bearing, and estimated duration for [waypoints]
  /// traveled at [speedKmh].
  ///
  /// Throws an [AssertionError] if [speedKmh] is less than or equal to zero.
  RouteEtaSummary calculateRouteEta(
    Iterable<GeoCoordinate> waypoints, {
    double speedKmh = 40.0,
  }) {
    assert(speedKmh > 0, 'speedKmh must be strictly greater than zero.');

    final list = waypoints.toList(growable: false);
    if (list.isEmpty) {
      return const RouteEtaSummary(
        totalDistanceMeters: 0.0,
        totalDistanceKilometers: 0.0,
        estimatedDuration: Duration.zero,
        initialBearingDegrees: 0.0,
        waypointCount: 0,
      );
    }

    if (list.length == 1) {
      return const RouteEtaSummary(
        totalDistanceMeters: 0.0,
        totalDistanceKilometers: 0.0,
        estimatedDuration: Duration.zero,
        initialBearingDegrees: 0.0,
        waypointCount: 1,
      );
    }

    final totalMeters = polylineLengthMeters(list);
    final totalKm = totalMeters / 1000.0;
    final speedMetersPerSecond = (speedKmh * 1000.0) / 3600.0;
    final totalSeconds = (totalMeters / speedMetersPerSecond).round();
    final initialBearing = initialBearingDegrees(list.first, list[1]);

    return RouteEtaSummary(
      totalDistanceMeters: totalMeters,
      totalDistanceKilometers: totalKm,
      estimatedDuration: Duration(seconds: totalSeconds),
      initialBearingDegrees: initialBearing,
      waypointCount: list.length,
    );
  }

  /// Evaluates the relationship between a [currentPosition] and a circular [zone].
  ///
  /// Evaluates containment against [GeofenceZone.radiusMeters] and calculates [GeofenceTransition]
  /// according to [wasPreviouslyInside].
  GeofenceEvaluation evaluateZone(
    GeofenceZone zone,
    GeoCoordinate currentPosition, {
    bool? wasPreviouslyInside,
    DateTime? evaluatedAtUtc,
  }) {
    final distance = distanceMeters(zone.center, currentPosition);
    final isInside = distance <= zone.radiusMeters;
    final signedOffset = distance - zone.radiusMeters;
    final timestamp = evaluatedAtUtc ?? DateTime.now().toUtc();

    final GeofenceTransition transition;
    if (wasPreviouslyInside == null) {
      transition = isInside
          ? GeofenceTransition.dwellingInside
          : GeofenceTransition.remainingOutside;
    } else if (!wasPreviouslyInside && isInside) {
      transition = GeofenceTransition.entered;
    } else if (wasPreviouslyInside && !isInside) {
      transition = GeofenceTransition.exited;
    } else {
      transition = isInside
          ? GeofenceTransition.dwellingInside
          : GeofenceTransition.remainingOutside;
    }

    return GeofenceEvaluation(
      zoneId: zone.id,
      zoneLabel: zone.label,
      isInside: isInside,
      transition: transition,
      distanceFromCenterMeters: distance,
      signedBoundaryOffsetMeters: signedOffset,
      evaluatedAtUtc: timestamp,
    );
  }

  /// Evaluates multiple geofence [zones] in a single pass, returning results sorted
  /// in ascending order of proximity to [currentPosition].
  List<GeofenceEvaluation> evaluateFleetZones(
    Iterable<GeofenceZone> zones,
    GeoCoordinate currentPosition, {
    Map<String, bool> previousInsideState = const {},
    DateTime? evaluatedAtUtc,
  }) {
    final timestamp = evaluatedAtUtc ?? DateTime.now().toUtc();
    final evaluations = <GeofenceEvaluation>[];

    for (final zone in zones) {
      final wasInside = previousInsideState[zone.id];
      evaluations.add(
        evaluateZone(
          zone,
          currentPosition,
          wasPreviouslyInside: wasInside,
          evaluatedAtUtc: timestamp,
        ),
      );
    }

    evaluations.sort(
      (a, b) =>
          a.distanceFromCenterMeters.compareTo(b.distanceFromCenterMeters),
    );

    return evaluations;
  }

  static double _degreesToRadians(double degrees) => degrees * (pi / 180.0);

  static double _radiansToDegrees(double radians) => radians * (180.0 / pi);
}
