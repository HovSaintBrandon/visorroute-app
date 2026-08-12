import 'json_helpers.dart';

class ImportBatchSummary {
  final int ok;
  final int needsReview;
  final int error;

  ImportBatchSummary({this.ok = 0, this.needsReview = 0, this.error = 0});

  factory ImportBatchSummary.fromJson(Map<String, dynamic>? json) {
    return ImportBatchSummary(
      ok: json?['ok'] ?? 0,
      needsReview: json?['needsReview'] ?? 0,
      error: json?['error'] ?? 0,
    );
  }
}

class ImportBatch {
  final String id;
  final String originalFilename;

  /// 'full' | 'zone'
  final String scope;
  final String? zoneIdFilter;

  /// 'parsing' | 'geocoding' | 'needs_review' | 'committed' | 'failed'
  final String status;
  final int rowCount;
  final ImportBatchSummary summary;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? committedAt;

  ImportBatch({
    required this.id,
    required this.originalFilename,
    required this.scope,
    this.zoneIdFilter,
    required this.status,
    this.rowCount = 0,
    ImportBatchSummary? summary,
    this.failureReason,
    required this.createdAt,
    this.committedAt,
  }) : summary = summary ?? ImportBatchSummary();

  factory ImportBatch.fromJson(Map<String, dynamic> json) {
    return ImportBatch(
      id: json['_id'] ?? json['id'] ?? '',
      originalFilename: json['originalFilename'] ?? json['fileName'] ?? '',
      scope: json['scope'] ?? 'zone',
      zoneIdFilter: json['zoneIdFilter'] as String?,
      status: json['status'] ?? 'parsing',
      rowCount: json['rowCount'] ?? 0,
      summary: ImportBatchSummary.fromJson(json['summary'] as Map<String, dynamic>?),
      failureReason: json['failureReason'] as String?,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      committedAt: parseDateTime(json['committedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalFilename': originalFilename,
        'scope': scope,
        'zoneIdFilter': zoneIdFilter,
        'status': status,
        'rowCount': rowCount,
        'summary': {'ok': summary.ok, 'needsReview': summary.needsReview, 'error': summary.error},
        'failureReason': failureReason,
        'createdAt': createdAt.toIso8601String(),
        'committedAt': committedAt?.toIso8601String(),
      };
}
