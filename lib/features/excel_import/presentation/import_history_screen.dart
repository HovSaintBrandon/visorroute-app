import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../../../core/widgets/loading_state.dart';
import '../state/import_history_provider.dart';

class ImportHistoryScreen extends ConsumerWidget {
  const ImportHistoryScreen({super.key});

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final batchesAsync = ref.watch(importHistoryProvider);

    final navItems = [
      const NavItem(activeIcon: Icons.map, inactiveIcon: Icons.map_outlined, label: 'Zone Map', route: '/map'),
      const NavItem(activeIcon: Icons.file_upload, inactiveIcon: Icons.file_upload_outlined, label: 'Excel Import', route: '/import/history'),
      const NavItem(activeIcon: Icons.bar_chart, inactiveIcon: Icons.bar_chart_outlined, label: 'Reports', route: '/reports'),
      const NavItem(activeIcon: Icons.notifications, inactiveIcon: Icons.notifications_outlined, label: 'Alerts', route: '/notifications'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/map');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Import History')),
      body: Stack(
        children: [
          batchesAsync.when(
            loading: () => const LoadingState(message: 'Loading past uploads...'),
            error: (err, stack) => ErrorState(
              message: 'Failed to load import history',
              onRetry: () => ref.invalidate(importHistoryProvider),
            ),
            data: (batches) {
              if (batches.isEmpty) {
                return const Center(child: Text('No uploads yet. Tap "New Upload" to get started.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: batches.length,
                itemBuilder: (context, idx) {
                  final batch = batches[idx];
                  final canReview = batch.status == 'needs_review';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      title: Text(batch.originalFilename, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${batch.status} • ${batch.summary.ok} ok, ${batch.summary.needsReview} need review, ${batch.summary.error} errors',
                      ),
                      trailing: Text(_formatDate(batch.createdAt), style: theme.textTheme.bodySmall),
                      onTap: canReview ? () => context.push('/import/${batch.id}/review') : null,
                    ),
                  );
                },
              );
            },
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
                    context.go('/map');
                    break;
                  case 1:
                    context.go('/import/history');
                    break;
                  case 2:
                    context.go('/reports');
                    break;
                  case 3:
                    context.go('/notifications');
                    break;
                }
              },
              items: navItems,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/import/upload'),
        icon: const Icon(Icons.add),
        label: const Text('New Upload'),
      ),
    ));
  }
}
