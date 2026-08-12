import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/import_batch.dart';
import '../../../shared_models/import_row.dart';

class ImportUploadResult {
  final String importBatchId;
  final String status;

  ImportUploadResult({required this.importBatchId, required this.status});
}

class ImportCommitResult {
  final int studentsCreated;
  final int studentsUpdated;
  final List<Map<String, dynamic>> rowErrors;

  ImportCommitResult({required this.studentsCreated, required this.studentsUpdated, required this.rowErrors});

  factory ImportCommitResult.fromJson(Map<String, dynamic> json) {
    return ImportCommitResult(
      studentsCreated: json['studentsCreated'] ?? 0,
      studentsUpdated: json['studentsUpdated'] ?? 0,
      rowErrors: (json['rowErrors'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList(),
    );
  }
}

class ImportRepository {
  final Dio _dio;

  ImportRepository(this._dio);

  Future<List<ImportBatch>> listImports({String? scope, String? status, int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get('/api/imports', queryParameters: {
        if (scope != null) 'scope': scope,
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      });
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data.map((b) => ImportBatch.fromJson(b as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Multipart field name is `file` (the visits-photo endpoint uses `photo`
  /// — don't mix these up). Response is 202 with just `{importBatchId,
  /// status}`, not a full batch doc.
  Future<ImportUploadResult> uploadExcelFile({required String filePath, required String scope, String? zoneId}) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'scope': scope,
        if (zoneId != null) 'zoneId': zoneId,
      });
      final response = await _dio.post('/api/imports', data: formData);
      final data = response.data as Map<String, dynamic>;
      return ImportUploadResult(importBatchId: data['importBatchId'] as String, status: data['status'] as String);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ImportBatch> getBatchStatus(String batchId) async {
    try {
      final response = await _dio.get('/api/imports/$batchId');
      return ImportBatch.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<ImportRow>> getReviewRows(String batchId, {String? status}) async {
    try {
      final response = await _dio.get('/api/imports/$batchId/rows', queryParameters: {
        if (status != null) 'status': status,
      });
      final data = response.data as List<dynamic>;
      return data.map((r) => ImportRow.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ImportRow> correctRow(
    String batchId,
    String rowId, {
    String? zoneId,
    String? newZone,
    String? supervisorId,
    String? newSupervisor,
    double? lat,
    double? lng,
    String? address,
  }) async {
    try {
      final response = await _dio.patch('/api/imports/$batchId/rows/$rowId', data: {
        if (zoneId != null) 'zoneId': zoneId,
        if (newZone != null) 'newZone': newZone,
        if (supervisorId != null) 'supervisorId': supervisorId,
        if (newSupervisor != null) 'newSupervisor': newSupervisor,
        if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
        if (address != null) 'address': address,
      });
      return ImportRow.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Rows still `needs_review` are silently skipped, not rejected — the
  /// only 409 is on the batch's own status. Surface [rowErrors] to the
  /// supervisor either way.
  Future<ImportCommitResult> commitBatch(String batchId) async {
    try {
      final response = await _dio.post('/api/imports/$batchId/commit');
      return ImportCommitResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Pre-commit only — 409s if the batch was already committed.
  Future<void> discardBatch(String batchId) async {
    try {
      await _dio.delete('/api/imports/$batchId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
