/// Circular geofence boundary configuration model.
library;

import 'geo_coordinate.dart';

/// Represents an immutable circular geofence perimeter centered at a [GeoCoordinate].
class GeofenceZone {
  /// Unique identifier for this geofence zone.
  final String id;

  /// Descriptive human-readable label for this zone.
  final String label;

  /// Geographic center point of the circular perimeter.
  final GeoCoordinate center;

  /// Radial distance in meters from [center], strictly greater than zero.
  final double radiusMeters;

  /// Creates a validated [GeofenceZone] instance.
  ///
  /// Throws an [AssertionError] if [radiusMeters] is less than or equal to zero.
  const GeofenceZone({
    required this.id,
    required this.label,
    required this.center,
    required this.radiusMeters,
  }) : assert(
          radiusMeters > 0,
          'Geofence radiusMeters must be strictly greater than zero.',
        );

  /// Creates a copy of this [GeofenceZone] with optional replacement fields.
  GeofenceZone copyWith({
    String? id,
    String? label,
    GeoCoordinate? center,
    double? radiusMeters,
  }) {
    return GeofenceZone(
      id: id ?? this.id,
      label: label ?? this.label,
      center: center ?? this.center,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeofenceZone &&
        other.id == id &&
        other.label == label &&
        other.center == center &&
        other.radiusMeters == radiusMeters;
  }

  @override
  int get hashCode => Object.hash(id, label, center, radiusMeters);

  @override
  String toString() =>
      'GeofenceZone(id: $id, label: $label, center: $center, radiusMeters: $radiusMeters)';
}
