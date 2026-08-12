import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/student.dart';

class QueueStatus {
  final bool hasActiveRoute;
  final bool inQueue;
  final bool passed;
  final int? queuePosition;
  final int? totalRemaining;
  final int? etaMinutes;
  final double? distanceMeters;

  QueueStatus({
    required this.hasActiveRoute,
    required this.inQueue,
    required this.passed,
    this.queuePosition,
    this.totalRemaining,
    this.etaMinutes,
    this.distanceMeters,
  });

  /// `queuePosition`/`etaMinutes`/`distanceMeters` are null unless
  /// `inQueue && !passed` — and `etaMinutes`/`distanceMeters` stay null even
  /// then until the supervisor has pinged a location at least once.
  factory QueueStatus.fromJson(Map<String, dynamic> json) {
    return QueueStatus(
      hasActiveRoute: json['hasActiveRoute'] ?? false,
      inQueue: json['inQueue'] ?? false,
      passed: json['passed'] ?? false,
      queuePosition: json['queuePosition'] as int?,
      totalRemaining: json['totalRemaining'] as int?,
      etaMinutes: json['etaMinutes'] as int?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
    );
  }
}

class StudentStatusRepository {
  final Dio _dio;

  StudentStatusRepository(this._dio);

  Future<Student> getMyStatus() async {
    try {
      final response = await _dio.get('/api/students/me');
      return Student.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Student> updateMe({required String phone}) async {
    try {
      final response = await _dio.patch('/api/students/me', data: {'phone': phone});
      return Student.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Registering this is what makes push delivery work at all — without it
  /// every notification silently falls back to SMS.
  Future<void> registerPushToken(String token) async {
    try {
      await _dio.patch('/api/students/me/push-token', data: {'token': token});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<QueueStatus> getQueueStatus() async {
    try {
      final response = await _dio.get('/api/students/me/queue-status');
      return QueueStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
