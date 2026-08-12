import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/state/auth_provider.dart';
import '../../student_status/state/student_status_provider.dart';
import '../data/notification_repository.dart';

final notificationRepoProvider = Provider((ref) => NotificationRepository(ref.watch(dioClientProvider).dio));

class NotificationsState {
  final List<AppNotificationItem> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  NotificationsState({this.items = const [], this.page = 1, this.hasMore = true, this.isLoadingMore = false});
}

class NotificationsNotifier extends StateNotifier<AsyncValue<NotificationsState>> {
  static const _pageSize = 20;
  final NotificationRepository _repository;

  NotificationsNotifier(this._repository) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getNotifications(page: 1, limit: _pageSize);
      state = AsyncValue.data(NotificationsState(items: items, page: 1, hasMore: items.length == _pageSize));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncValue.data(NotificationsState(items: current.items, page: current.page, hasMore: true, isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final newItems = await _repository.getNotifications(page: nextPage, limit: _pageSize);
      state = AsyncValue.data(NotificationsState(
        items: [...current.items, ...newItems],
        page: nextPage,
        hasMore: newItems.length == _pageSize,
      ));
    } catch (_) {
      state = AsyncValue.data(NotificationsState(items: current.items, page: current.page, hasMore: current.hasMore));
    }
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, AsyncValue<NotificationsState>>((ref) {
  return NotificationsNotifier(ref.watch(notificationRepoProvider));
});

/// Handles real FCM registration + foreground/background display. Every
/// Firebase call is wrapped defensively — this repo has no platform
/// folders or `google-services.json`/`GoogleService-Info.plist` yet, so
/// Firebase can't actually initialize here. Push is a best-effort feature:
/// its absence shouldn't block login or crash the rest of the app.
class PushNotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  PushNotificationService(this._ref);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) await _registerToken(token);
      messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen(_showLocalNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _ref.invalidate(notificationsProvider));
    } catch (_) {
      // Firebase isn't configured in this environment yet — nothing to do.
    }
  }

  Future<void> _registerToken(String token) async {
    // PATCH /students/me/push-token is student-only.
    if (_ref.read(authProvider).role != UserRole.student) return;
    try {
      await _ref.read(studentStatusRepoProvider).registerPushToken(token);
    } catch (_) {
      // Best-effort — retried on the next app start / token refresh.
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails('visorroute_default', 'VisorRoute Notifications'),
        iOS: DarwinNotificationDetails(),
      ),
    );
    _ref.invalidate(notificationsProvider);
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) => PushNotificationService(ref));
