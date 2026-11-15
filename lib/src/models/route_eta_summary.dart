/// Route summary model containing distance, duration, and bearing statistics.
library;

/// Represents an immutable summary of route distance, bearing, and estimated travel time.
class RouteEtaSummary {
  /// Cumulative route distance in meters.
  final double totalDistanceMeters;

  /// Cumulative route distance in kilometers.
  final double totalDistanceKilometers;

  /// Estimated transit duration calculated at the given travel speed.
  final Duration estimatedDuration;

  /// Initial compass bearing in degrees `[0.0, 360.0)` from the origin towards the next waypoint.
  final double initialBearingDegrees;

  /// Total count of waypoints comprising the route.
  final int waypointCount;

  /// Creates an immutable [RouteEtaSummary].
  const RouteEtaSummary({
    required this.totalDistanceMeters,
    required this.totalDistanceKilometers,
    required this.estimatedDuration,
    required this.initialBearingDegrees,
    required this.waypointCount,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteEtaSummary &&
        other.totalDistanceMeters == totalDistanceMeters &&
        other.totalDistanceKilometers == totalDistanceKilometers &&
        other.estimatedDuration == estimatedDuration &&
        other.initialBearingDegrees == initialBearingDegrees &&
        other.waypointCount == waypointCount;
  }

  @override
  int get hashCode => Object.hash(
        totalDistanceMeters,
        totalDistanceKilometers,
        estimatedDuration,
        initialBearingDegrees,
        waypointCount,
      );

  @override
  String toString() =>
      'RouteEtaSummary(totalDistanceMeters: $totalDistanceMeters, '
      'totalDistanceKilometers: $totalDistanceKilometers, '
      'estimatedDuration: $estimatedDuration, '
      'initialBearingDegrees: $initialBearingDegrees, '
      'waypointCount: $waypointCount)';
}
