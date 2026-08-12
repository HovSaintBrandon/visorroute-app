/// Mongoose sometimes returns a ref field as a bare ObjectId string and
/// sometimes as a populated sub-document — this reads either shape.
String extractId(dynamic value) {
  if (value == null) return '';
  if (value is Map<String, dynamic>) return value['_id']?.toString() ?? '';
  return value.toString();
}

/// Every geo field from the API serializes as GeoJSON
/// `{type: "Point", coordinates: [lng, lat]}` — lng first. Returns null if
/// the point is absent (e.g. a workstation that hasn't been geocoded yet).
({double lat, double lng})? extractLatLng(dynamic geoPoint) {
  if (geoPoint is Map<String, dynamic>) {
    final coords = geoPoint['coordinates'];
    if (coords is List && coords.length == 2) {
      final lng = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      return (lat: lat, lng: lng);
    }
  }
  return null;
}

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
