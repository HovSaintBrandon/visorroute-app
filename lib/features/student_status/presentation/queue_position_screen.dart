import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../../../core/widgets/loading_state.dart';
import '../data/student_status_repository.dart';
import '../state/student_status_provider.dart';

class QueuePositionScreen extends ConsumerWidget {
  const QueuePositionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final queueAsync = ref.watch(queueStatusProvider);

    final navItems = [
      const NavItem(activeIcon: Icons.person_pin_circle, inactiveIcon: Icons.person_pin_circle_outlined, label: 'My Status', route: '/student/status'),
      const NavItem(activeIcon: Icons.access_time_filled, inactiveIcon: Icons.access_time, label: 'Queue Pos', route: '/student/queue'),
      const NavItem(activeIcon: Icons.notifications, inactiveIcon: Icons.notifications_outlined, label: 'Notifications', route: '/notifications'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/student/status');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Supervisor Queue ETA'),
        ),
      body: Stack(
        children: [
          queueAsync.when(
            loading: () => const LoadingState(message: 'Checking your queue position...'),
            error: (err, stack) => ErrorState(
              message: 'Failed to load queue status',
              onRetry: () => ref.invalidate(queueStatusProvider),
            ),
            data: (status) => _buildBody(theme, status),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: 1,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/student/status');
                    break;
                  case 1:
                    context.go('/student/queue');
                    break;
                  case 2:
                    context.go('/notifications');
                    break;
                }
              },
              items: navItems,
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildBody(ThemeData theme, QueueStatus status) {
    if (!status.hasActiveRoute) {
      return _emptyState(
        theme,
        icon: Icons.pause_circle_outline_rounded,
        title: 'No Active Route',
        subtitle: "Your supervisor hasn't started a route yet today. Check back soon.",
      );
    }

    if (status.passed) {
      return _emptyState(
        theme,
        icon: Icons.check_circle_outline_rounded,
        title: 'Already Visited',
        subtitle: 'Your supervisor has already passed your workstation on this route.',
        color: Colors.green,
      );
    }

    // inQueue && !passed — upcoming on the active route.
    final hasEta = status.etaMinutes != null;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: theme.primaryColor, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.queuePosition != null ? "You're #${status.queuePosition} in the queue" : "You're in the queue",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasEta ? 'Estimated Visit ETA: ~${status.etaMinutes} minutes' : 'Waiting for your supervisor to share a location update...',
                        style: TextStyle(
                          color: hasEta ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (status.totalRemaining != null) ...[
                        const SizedBox(height: 4),
                        Text('${status.totalRemaining} stops remaining on this route', style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme, {required IconData icon, required String title, required String subtitle, Color? color}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color ?? theme.primaryColor),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
