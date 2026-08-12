import 'json_helpers.dart';

/// `photo.key` is an internal storage key, not a fetchable URL — the photo
/// bytes have to be pulled via `GET /visits/:visitId/photo`, never
/// constructed as an image URL from this key.
class VisitPhoto {
  final String key;
  final String mimeType;
  final DateTime uploadedAt;

  VisitPhoto({required this.key, required this.mimeType, required this.uploadedAt});

  factory VisitPhoto.fromJson(Map<String, dynamic> json) {
    return VisitPhoto(
      key: json['key'] ?? '',
      mimeType: json['mimeType'] ?? '',
      uploadedAt: parseDateTime(json['uploadedAt']) ?? DateTime.now(),
    );
  }
}

class Visit {
  final String id;
  final String studentId;
  final String supervisorId;

  /// 'visit' | 'assessment'
  final String type;
  final String outcome;
  final double? score;
  final String notes;
  final int? durationMinutes;
  final VisitPhoto? photo;
  final DateTime timestamp;

  Visit({
    required this.id,
    required this.studentId,
    required this.supervisorId,
    required this.type,
    this.outcome = '',
    this.score,
    this.notes = '',
    this.durationMinutes,
    this.photo,
    required this.timestamp,
  });

  /// The response echoes the submitted location back as
  /// `supervisorLocationAtVisit` (GeoJSON), not `supervisorLocation` — this
  /// model only needs the identifying/display fields, not that location.
  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: extractId(json['studentId']),
      supervisorId: extractId(json['supervisorId']),
      type: json['type'] ?? 'visit',
      outcome: json['outcome'] ?? '',
      score: (json['score'] as num?)?.toDouble(),
      notes: json['notes'] ?? '',
      durationMinutes: json['durationMinutes'] as int?,
      photo: json['photo'] != null ? VisitPhoto.fromJson(json['photo'] as Map<String, dynamic>) : null,
      timestamp: parseDateTime(json['createdAt']) ?? parseDateTime(json['timestamp']) ?? DateTime.now(),
    );
  }
}
