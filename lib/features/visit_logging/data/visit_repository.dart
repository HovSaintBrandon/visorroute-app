import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/visit.dart';

class VisitRepository {
  final Dio _dio;

  VisitRepository(this._dio);

  Future<Visit> createVisit({
    required String studentId,
    required String type,
    String outcome = '',
    double? score,
    String notes = '',
    required double supervisorLat,
    required double supervisorLng,
    int? durationMinutes,
  }) async {
    try {
      final response = await _dio.post('/api/visits', data: {
        'studentId': studentId,
        'type': type,
        'outcome': outcome,
        if (score != null) 'score': score,
        'notes': notes,
        'supervisorLocation': {'lat': supervisorLat, 'lng': supervisorLng},
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
      });
      return Visit.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Multipart field name is `photo` (image/jpeg|png|webp only, 8MB max —
  /// validate client-side before calling this to avoid a guaranteed 400).
  Future<Visit> attachPhoto(String visitId, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/api/visits/$visitId/photo', data: formData);
      return Visit.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Raw image bytes, not JSON/base64.
  Future<List<int>> getPhoto(String visitId) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/visits/$visitId/photo',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
