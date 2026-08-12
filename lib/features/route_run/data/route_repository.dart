import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/route_run.dart';

class RouteRepository {
  final Dio _dio;

  RouteRepository(this._dio);

  /// The server loads every unvisited+geocoded student in the zone itself —
  /// there's no student-id list to hand-pick here. 400s if none qualify.
  /// Its response leaves `orderedStudentIds` unpopulated; call
  /// [getRouteDetail] right after to get renderable stops.
  Future<RouteRun> optimizeRoute({required String zoneId, required double lat, required double lng}) async {
    try {
      final response = await _dio.post('/api/routes/optimize', data: {
        'zoneId': zoneId,
        'startPoint': {'lat': lat, 'lng': lng},
      });
      return RouteRun.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// The only call that populates `orderedStudentIds` into renderable stops.
  Future<RouteRun> getRouteDetail(String routeRunId) async {
    try {
      final response = await _dio.get('/api/routes/$routeRunId');
      return RouteRun.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<RouteRun> advanceStep(String routeRunId) async {
    try {
      final response = await _dio.patch('/api/routes/$routeRunId/advance');
      return RouteRun.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 409s if the route isn't currently `in_progress`.
  Future<RouteRun> abandonRoute(String routeRunId) async {
    try {
      final response = await _dio.patch('/api/routes/$routeRunId/abandon');
      return RouteRun.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
