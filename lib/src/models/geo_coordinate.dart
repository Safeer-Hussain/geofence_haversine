/// Geographic coordinate model for latitude and longitude representation.
library;

/// Represents an immutable geographic coordinate pair in decimal degrees.
class GeoCoordinate {
  /// The latitude in degrees, constrained between -90.0 and 90.0 inclusive.
  final double latitude;

  /// The longitude in degrees, constrained between -180.0 and 180.0 inclusive.
  final double longitude;

  /// Creates a validated [GeoCoordinate] instance.
  ///
  /// Throws an [AssertionError] if [latitude] is outside `[-90.0, 90.0]` or
  /// [longitude] is outside `[-180.0, 180.0]`.
  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
  })  : assert(
          latitude >= -90.0 && latitude <= 90.0,
          'Latitude must be between -90.0 and 90.0 degrees.',
        ),
        assert(
          longitude >= -180.0 && longitude <= 180.0,
          'Longitude must be between -180.0 and 180.0 degrees.',
        );

  /// Creates a copy of this [GeoCoordinate] with optional replacement fields.
  GeoCoordinate copyWith({
    double? latitude,
    double? longitude,
  }) {
    return GeoCoordinate(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Serializes this [GeoCoordinate] to a JSON-compatible map.
  Map<String, double> toJson() {
    return <String, double>{
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Deserializes a [GeoCoordinate] from a JSON map containing numeric
  /// `latitude` and `longitude` values.
  factory GeoCoordinate.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num).toDouble();
    final lon = (json['longitude'] as num).toDouble();
    return GeoCoordinate(latitude: lat, longitude: lon);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoCoordinate &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'GeoCoordinate(latitude: $latitude, longitude: $longitude)';
}
