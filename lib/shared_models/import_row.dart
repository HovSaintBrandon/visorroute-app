import 'json_helpers.dart';

class ImportRowParsed {
  final String? studentName;
  final String? regNo;
  final String? programme;
  final String? admissionType;
  final int? yearOfStudy;
  final String? phone;
  final String? zoneRaw;
  final String? supervisorRaw;
  final String? attachmentStationRaw;
  final int? durationWeeks;
  final DateTime? startDate;
  final DateTime? endDate;

  ImportRowParsed({
    this.studentName,
    this.regNo,
    this.programme,
    this.admissionType,
    this.yearOfStudy,
    this.phone,
    this.zoneRaw,
    this.supervisorRaw,
    this.attachmentStationRaw,
    this.durationWeeks,
    this.startDate,
    this.endDate,
  });

  factory ImportRowParsed.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ImportRowParsed();
    return ImportRowParsed(
      studentName: json['studentName'] as String?,
      regNo: json['regNo'] as String?,
      programme: json['programme'] as String?,
      admissionType: json['admissionType'] as String?,
      yearOfStudy: json['yearOfStudy'] as int?,
      phone: json['phone'] as String?,
      zoneRaw: json['zoneRaw'] as String?,
      supervisorRaw: json['supervisorRaw'] as String?,
      attachmentStationRaw: json['attachmentStationRaw'] as String?,
      durationWeeks: json['durationWeeks'] as int?,
      startDate: parseDateTime(json['startDate']),
      endDate: parseDateTime(json['endDate']),
    );
  }
}

class ImportRowGeocodeResult {
  final double? lat;
  final double? lng;
  final String? formattedAddress;
  final double? confidence;

  ImportRowGeocodeResult({this.lat, this.lng, this.formattedAddress, this.confidence});

  factory ImportRowGeocodeResult.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ImportRowGeocodeResult();
    final latLng = extractLatLng(json['location']);
    return ImportRowGeocodeResult(
      lat: latLng?.lat,
      lng: latLng?.lng,
      formattedAddress: json['formattedAddress'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class ImportRow {
  final String id;
  final String importBatchId;
  final int rowNumber;
  final Map<String, dynamic> rawData;
  final ImportRowParsed parsed;
  final String? resolvedZoneId;
  final String? resolvedSupervisorId;
  final String? supervisorResolutionNote;
  final ImportRowGeocodeResult? geocodeResult;
  final bool manuallyCorrected;

  /// 'ok' | 'needs_review' | 'error'
  final String status;
  final String? errorMessage;

  ImportRow({
    required this.id,
    required this.importBatchId,
    required this.rowNumber,
    required this.rawData,
    required this.parsed,
    this.resolvedZoneId,
    this.resolvedSupervisorId,
    this.supervisorResolutionNote,
    this.geocodeResult,
    this.manuallyCorrected = false,
    required this.status,
    this.errorMessage,
  });

  factory ImportRow.fromJson(Map<String, dynamic> json) {
    return ImportRow(
      id: json['_id'] ?? json['id'] ?? '',
      importBatchId: extractId(json['importBatchId']),
      rowNumber: json['rowNumber'] ?? 0,
      rawData: json['rawData'] as Map<String, dynamic>? ?? {},
      parsed: ImportRowParsed.fromJson(json['parsed'] as Map<String, dynamic>?),
      resolvedZoneId: json['resolvedZoneId'] != null ? extractId(json['resolvedZoneId']) : null,
      resolvedSupervisorId: json['resolvedSupervisorId'] != null ? extractId(json['resolvedSupervisorId']) : null,
      supervisorResolutionNote: json['supervisorResolutionNote'] as String?,
      geocodeResult: json['geocodeResult'] != null
          ? ImportRowGeocodeResult.fromJson(json['geocodeResult'] as Map<String, dynamic>)
          : null,
      manuallyCorrected: json['manuallyCorrected'] ?? false,
      status: json['status'] ?? 'needs_review',
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
