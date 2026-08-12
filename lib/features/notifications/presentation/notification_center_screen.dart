import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/state/auth_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/widgets/loading_state.dart';
import '../state/push_provider.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  String _channelLabel(String channel) => channel == 'sms' ? 'SMS' : 'Push';

  Color _statusColor(String status) {
    switch (status) {
      case 'failed':
        return Colors.red;
      case 'delivered':
        return Colors.green;
      case 'sent':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifsState = ref.watch(notificationsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final role = ref.read(authProvider).role;
        context.go(role == UserRole.supervisor ? '/map' : '/student/status');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
      body: notifsState.when(
        loading: () => const LoadingState(message: 'Loading notification history...'),
        error: (err, stack) => ErrorState(
          message: 'Failed to load notifications',
          onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.items.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, idx) {
                if (idx == state.items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: state.isLoadingMore
                          ? const CircularProgressIndicator()
                          : TextButton(
                              onPressed: () => ref.read(notificationsProvider.notifier).loadMore(),
                              child: const Text('Load More'),
                            ),
                    ),
                  );
                }

                final item = state.items[idx];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.15),
                      child: Icon(Icons.notifications_active_rounded, color: theme.primaryColor),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.body),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _channelLabel(item.channel),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.primaryColor),
                        ),
                        Text(item.status, style: TextStyle(fontSize: 10, color: _statusColor(item.status))),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ));
  }
}
