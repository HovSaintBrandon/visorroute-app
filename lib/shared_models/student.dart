import 'json_helpers.dart';

enum VisitStatus { unvisited, inProgress, visited, assessed, overdue }

class Student {
  final String id;
  final String regNo;
  final String fullName;
  final String phone;
  final String workstationName;
  final double latitude;
  final double longitude;
  final VisitStatus status;
  final int queueIndex;
  final String estimatedTimeOfArrival;

  Student({
    required this.id,
    required this.regNo,
    required this.fullName,
    this.phone = '',
    required this.workstationName,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.queueIndex = 0,
    this.estimatedTimeOfArrival = '',
  });

  /// Reads the real `GET /students/me` / `GET /students` doc shape:
  /// `name` (not `fullName`), nested `workStation.rawName` +
  /// `workStation.location` (GeoJSON), and a `status{visited,assessed}`
  /// object rather than a single enum. `queueIndex`/`estimatedTimeOfArrival`
  /// aren't part of this doc at all — they come from the separate
  /// `GET /students/me/queue-status` endpoint, so they default here.
  factory Student.fromJson(Map<String, dynamic> json) {
    final workStation = json['workStation'] as Map<String, dynamic>?;
    final statusObj = json['status'] as Map<String, dynamic>?;
    final latLng = extractLatLng(workStation?['location']);

    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      regNo: json['regNo'] ?? '',
      fullName: json['name'] ?? json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      workstationName: workStation?['rawName'] ?? json['workstationName'] ?? '',
      latitude: latLng?.lat ?? (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: latLng?.lng ?? (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromDoc(statusObj) ?? VisitStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'unvisited'),
        orElse: () => VisitStatus.unvisited,
      ),
      queueIndex: json['queueIndex'] ?? 0,
      estimatedTimeOfArrival: json['estimatedTimeOfArrival'] ?? '',
    );
  }

  static VisitStatus? _statusFromDoc(Map<String, dynamic>? statusObj) {
    if (statusObj == null) return null;
    if (statusObj['assessed'] == true) return VisitStatus.assessed;
    if (statusObj['visited'] == true) return VisitStatus.visited;
    return VisitStatus.unvisited;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'regNo': regNo,
        'fullName': fullName,
        'phone': phone,
        'workstationName': workstationName,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.name,
        'queueIndex': queueIndex,
        'estimatedTimeOfArrival': estimatedTimeOfArrival,
      };
}

/// The slim projection returned by `GET /students/:id/map-pin` — distinct
/// from the full Student doc, used only to refresh a single pin without
/// refetching the whole zone list.
class MapPin {
  final double? latitude;
  final double? longitude;
  final bool visited;
  final bool assessed;
  final String workstationName;

  MapPin({
    this.latitude,
    this.longitude,
    required this.visited,
    required this.assessed,
    required this.workstationName,
  });

  factory MapPin.fromJson(Map<String, dynamic> json) {
    final latLng = extractLatLng(json['location']);
    final status = json['status'] as Map<String, dynamic>?;
    final workStation = json['workStation'] as Map<String, dynamic>?;
    return MapPin(
      latitude: latLng?.lat,
      longitude: latLng?.lng,
      visited: status?['visited'] ?? false,
      assessed: status?['assessed'] ?? false,
      workstationName: workStation?['rawName'] ?? '',
    );
  }
}
