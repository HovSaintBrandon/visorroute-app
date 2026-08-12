import 'package:dio/dio.dart';

/// Normalizes the backend's uniform `{ error: { message, details? } }`
/// envelope into a typed exception every repository can throw/catch alike.
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? details;
  final int? statusCode;

  ApiException({required this.message, this.details, this.statusCode});

  factory ApiException.fromDioException(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final err = data['error'] as Map<String, dynamic>;
      return ApiException(
        message: err['message'] as String? ?? 'Something went wrong. Please try again.',
        details: err['details'] as Map<String, dynamic>?,
        statusCode: error.response?.statusCode,
      );
    }
    return ApiException(
      message: error.message ?? 'Network error. Please check your connection.',
      statusCode: error.response?.statusCode,
    );
  }

  @override
  String toString() => message;
}
