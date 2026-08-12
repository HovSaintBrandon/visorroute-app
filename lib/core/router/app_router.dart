import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/admin_signup_queue_screen.dart';
import '../../features/admin/presentation/admin_signup_request_detail_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/signup_pending_screen.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../features/map_dashboard/presentation/zone_map_screen.dart';
import '../../features/map_dashboard/presentation/supervisor_profile_screen.dart';
import '../../features/route_run/presentation/route_preview_screen.dart';
import '../../features/route_run/presentation/route_active_screen.dart';
import '../../features/excel_import/presentation/upload_screen.dart';
import '../../features/excel_import/presentation/import_history_screen.dart';
import '../../features/excel_import/presentation/import_review_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/student_status/presentation/my_status_screen.dart';
import '../../features/student_status/presentation/queue_position_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authState.isLoggedIn;
      final role = authState.role;
      final location = state.matchedLocation;

      final isPublicRoute = location == '/login' || location == '/signup' || location == '/signup/pending';

      if (!isLoggedIn) {
        return isPublicRoute ? null : '/login';
      }

      // Logged in and sitting on a public/auth route — send them home.
      if (isPublicRoute) {
        switch (role) {
          case UserRole.supervisor:
            return '/map';
          case UserRole.admin:
            return '/admin/requests';
          case UserRole.student:
            return '/student/status';
        }
      }

      // Admin is siloed to /admin/* — this is the only thing admin does in
      // this app right now (the signup approval queue), not a full console.
      if (role == UserRole.admin) {
        return location.startsWith('/admin') ? null : '/admin/requests';
      }

      // Guard supervisor vs student vs admin routes
      if (role == UserRole.supervisor && (location.startsWith('/student') || location.startsWith('/admin'))) {
        return '/map';
      }

      if (role == UserRole.student && !location.startsWith('/student') && location != '/notifications') {
        return '/student/status';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/signup/pending',
        builder: (context, state) => SignupPendingScreen(signupRequestId: state.extra as String?),
      ),
      GoRoute(
        path: '/admin/requests',
        builder: (context, state) => const AdminSignupQueueScreen(),
      ),
      GoRoute(
        path: '/admin/requests/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdminSignupRequestDetailScreen(requestId: id);
        },
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const ZoneMapScreen(),
      ),
      GoRoute(
        path: '/supervisor/profile',
        builder: (context, state) => const SupervisorProfileScreen(),
      ),
      GoRoute(
        path: '/route/preview',
        builder: (context, state) => const RoutePreviewScreen(),
      ),
      GoRoute(
        path: '/route/active',
        builder: (context, state) => const RouteActiveScreen(),
      ),
      GoRoute(
        path: '/import/history',
        builder: (context, state) => const ImportHistoryScreen(),
      ),
      GoRoute(
        path: '/import/upload',
        builder: (context, state) => const UploadScreen(),
      ),
      GoRoute(
        path: '/import/:id/review',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'batch_1';
          return ImportReviewScreen(batchId: id);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/student/status',
        builder: (context, state) => const MyStatusScreen(),
      ),
      GoRoute(
        path: '/student/queue',
        builder: (context, state) => const QueuePositionScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
  );
});
