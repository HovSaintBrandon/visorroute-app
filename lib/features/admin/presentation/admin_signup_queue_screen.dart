import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/loading_state.dart';
import '../../auth/state/auth_provider.dart';
import '../data/signup_request_repository.dart';
import '../state/signup_requests_provider.dart';

class AdminSignupQueueScreen extends ConsumerWidget {
  const AdminSignupQueueScreen({super.key});

  static const _filters = [
    ('pending', 'Pending'),
    ('approved', 'Approved'),
    ('rejected', 'Rejected'),
    (null, 'All'),
  ];

  Future<void> _approve(BuildContext context, WidgetRef ref, SignupRequest request) async {
    final error = await ref.read(signupRequestsProvider.notifier).approve(request.id);
    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref, SignupRequest request) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject ${request.name}?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;

    final error = await ref.read(signupRequestsProvider.notifier).reject(request.id, reason: reason.isEmpty ? null : reason);
    if (context.mounted && error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedFilter = ref.watch(selectedStatusFilterProvider);
    final requestsAsync = ref.watch(signupRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              children: _filters.map((f) {
                final (value, label) = f;
                return ChoiceChip(
                  label: Text(label),
                  selected: selectedFilter == value,
                  onSelected: (_) => ref.read(selectedStatusFilterProvider.notifier).state = value,
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: requestsAsync.when(
              loading: () => const LoadingState(message: 'Loading requests...'),
              error: (err, stack) => ErrorState(
                message: 'Failed to load requests',
                onRetry: () => ref.read(signupRequestsProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.items.isEmpty) {
                  return const Center(child: Text('No requests here.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(signupRequestsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (context, idx) {
                      if (idx == state.items.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: state.isLoadingMore
                                ? const CircularProgressIndicator()
                                : TextButton(
                                    onPressed: () => ref.read(signupRequestsProvider.notifier).loadMore(),
                                    child: const Text('Load More'),
                                  ),
                          ),
                        );
                      }

                      final request = state.items[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push('/admin/requests/${request.id}'),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(request.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ),
                                    Chip(
                                      label: Text(request.role),
                                      backgroundColor: theme.primaryColor.withOpacity(0.15),
                                      labelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${request.zoneName ?? 'No zone'} • ${request.status}'),
                                if (request.status == 'pending') ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _reject(context, ref, request),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.colorScheme.error,
                                            side: BorderSide(color: theme.colorScheme.error),
                                          ),
                                          icon: const Icon(Icons.close, size: 18),
                                          label: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _approve(context, ref, request),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primaryColor,
                                            foregroundColor: Colors.white,
                                          ),
                                          icon: const Icon(Icons.check, size: 18),
                                          label: const Text('Approve'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
