import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/student.dart';

class WorkStationSearchResult {
  final String title;
  final String formattedAddress;
  final double lat;
  final double lng;

  WorkStationSearchResult({
    required this.title,
    required this.formattedAddress,
    required this.lat,
    required this.lng,
  });

  factory WorkStationSearchResult.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? {};
    return WorkStationSearchResult(
      title: json['title'] ?? '',
      formattedAddress: json['formattedAddress'] ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WorkstationRepository {
  final Dio _dio;

  WorkstationRepository(this._dio);

  /// Search-as-you-type for the student's own workplace — proxies HERE
  /// Autosuggest server-side (GET /students/me/workstation/search), biased
  /// toward the student's zone. Never throws on an empty query result set,
  /// only on an actual request failure.
  Future<List<WorkStationSearchResult>> search(String query) async {
    try {
      final response = await _dio.get('/api/students/me/workstation/search', queryParameters: {'q': query});
      final items = response.data as List<dynamic>;
      return items.map((item) => WorkStationSearchResult.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Submits the student's chosen point — either a tapped search result or a
  /// manually-adjusted map pin — as their real workplace location.
  Future<Student> confirmLocation({required double lat, required double lng, String? address}) async {
    try {
      final response = await _dio.patch('/api/students/me/workstation', data: {
        'lat': lat,
        'lng': lng,
        if (address != null) 'address': address,
      });
      return Student.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
