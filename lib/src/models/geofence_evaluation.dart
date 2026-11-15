/// Geofence boundary evaluation models and transition state enumerations.
library;

/// Represents state transitions relative to a circular geofence boundary.
enum GeofenceTransition {
  /// Position transitioned from outside to inside the zone radius.
  entered,

  /// Position transitioned from inside to outside the zone radius.
  exited,

  /// Position remained inside the zone radius across evaluations.
  dwellingInside,

  /// Position remained outside the zone radius across evaluations.
  remainingOutside,
}

/// An immutable evaluation snapshot of a position relative to a [GeofenceZone].
class GeofenceEvaluation {
  /// The unique identifier of the evaluated zone.
  final String zoneId;

  /// The human-readable label of the evaluated zone.
  final String zoneLabel;

  /// Whether the evaluated position is inside or on the circular boundary.
  final bool isInside;

  /// The state transition determined by comparing previous and current positions.
  final GeofenceTransition transition;

  /// Geodesic distance in meters from the zone center to the position.
  final double distanceFromCenterMeters;

  /// Signed radial distance to the geofence perimeter in meters.
  ///
  /// Negative when inside the boundary, and positive when outside.
  final double signedBoundaryOffsetMeters;

  /// Timestamp in UTC when this evaluation was calculated.
  final DateTime evaluatedAtUtc;

  /// Creates an immutable [GeofenceEvaluation] record.
  const GeofenceEvaluation({
    required this.zoneId,
    required this.zoneLabel,
    required this.isInside,
    required this.transition,
    required this.distanceFromCenterMeters,
    required this.signedBoundaryOffsetMeters,
    required this.evaluatedAtUtc,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeofenceEvaluation &&
        other.zoneId == zoneId &&
        other.zoneLabel == zoneLabel &&
        other.isInside == isInside &&
        other.transition == transition &&
        other.distanceFromCenterMeters == distanceFromCenterMeters &&
        other.signedBoundaryOffsetMeters == signedBoundaryOffsetMeters &&
        other.evaluatedAtUtc == evaluatedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
        zoneId,
        zoneLabel,
        isInside,
        transition,
        distanceFromCenterMeters,
        signedBoundaryOffsetMeters,
        evaluatedAtUtc,
      );

  @override
  String toString() =>
      'GeofenceEvaluation(zoneId: $zoneId, zoneLabel: $zoneLabel, '
      'isInside: $isInside, transition: $transition, '
      'distanceFromCenterMeters: $distanceFromCenterMeters, '
      'signedBoundaryOffsetMeters: $signedBoundaryOffsetMeters, '
      'evaluatedAtUtc: $evaluatedAtUtc)';
}
