import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/json_helpers.dart';

class AppNotificationItem {
  final String id;
  final String studentId;
  final String? routeRunId;

  /// 'queue_position' | 'next_up' | 'visit_confirmed'
  final String type;

  /// 'push' | 'sms'
  final String channel;
  final Map<String, dynamic> payload;

  /// 'sent' | 'failed' | 'delivered' — 'delivered' is defined server-side
  /// but never actually emitted yet.
  final String status;
  final DateTime sentAt;

  AppNotificationItem({
    required this.id,
    required this.studentId,
    this.routeRunId,
    required this.type,
    required this.channel,
    required this.payload,
    required this.status,
    required this.sentAt,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {
    return AppNotificationItem(
      id: json['_id'] ?? json['id'] ?? '',
      studentId: extractId(json['studentId']),
      routeRunId: json['routeRunId'] != null ? extractId(json['routeRunId']) : null,
      type: json['type'] ?? '',
      channel: json['channel'] ?? 'push',
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      status: json['status'] ?? 'sent',
      sentAt: parseDateTime(json['sentAt']) ?? DateTime.now(),
    );
  }

  /// The API only gives `type` + a freeform `payload` — there's no
  /// title/body string from the server, so this synthesizes display text.
  String get title {
    switch (type) {
      case 'next_up':
        return "You're Next!";
      case 'visit_confirmed':
        return 'Visit Confirmed';
      case 'queue_position':
      default:
        return 'Queue Update';
    }
  }

  String get body {
    final queuePosition = payload['queuePosition'];
    final etaMinutes = payload['etaMinutes'];
    switch (type) {
      case 'next_up':
        return etaMinutes != null
            ? 'Your supervisor is heading your way — ETA ~$etaMinutes minutes.'
            : 'Your supervisor is heading your way next.';
      case 'visit_confirmed':
        return 'Your workstation visit has been logged.';
      case 'queue_position':
      default:
        if (queuePosition != null && etaMinutes != null) {
          return "You're #$queuePosition in the queue — ETA ~$etaMinutes minutes.";
        } else if (queuePosition != null) {
          return "You're #$queuePosition in the queue.";
        }
        return 'Your queue position was updated.';
    }
  }
}

class NotificationRepository {
  final Dio _dio;

  NotificationRepository(this._dio);

  Future<List<AppNotificationItem>> getNotifications({int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get('/api/notifications', queryParameters: {'page': page, 'limit': limit});
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data.map((n) => AppNotificationItem.fromJson(n as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
