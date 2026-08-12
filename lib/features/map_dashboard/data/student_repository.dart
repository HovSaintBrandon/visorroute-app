import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../shared_models/student.dart';

class StudentRepository {
  final Dio _dio;

  StudentRepository(this._dio);

  Future<List<Student>> getZoneStudents(String zoneId, {String? status, int page = 1, int limit = 100}) async {
    try {
      final response = await _dio.get('/api/students', queryParameters: {
        'zoneId': zoneId,
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      });
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      final students = data.map((s) => Student.fromJson(s as Map<String, dynamic>)).toList();
      await _cacheStudents(zoneId, students);
      return students;
    } on DioException catch (e) {
      final cached = _readCachedStudents(zoneId);
      if (cached != null) return cached;
      throw ApiException.fromDioException(e);
    }
  }

  Future<MapPin> getMapPin(String studentId) async {
    try {
      final response = await _dio.get('/api/students/$studentId/map-pin');
      return MapPin.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> _cacheStudents(String zoneId, List<Student> students) async {
    await HiveBoxes.studentDataBox.put(zoneId, students.map((s) => s.toJson()).toList());
  }

  /// Offline-first fallback: render the last-known zone list rather than an
  /// error screen when the network call fails.
  List<Student>? _readCachedStudents(String zoneId) {
    final cached = HiveBoxes.studentDataBox.get(zoneId);
    if (cached == null) return null;
    return (cached as List)
        .map((s) => Student.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
  }
}
