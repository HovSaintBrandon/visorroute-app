import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/loading_state.dart';
import '../data/signup_request_repository.dart';
import '../state/signup_requests_provider.dart';

class AdminSignupRequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const AdminSignupRequestDetailScreen({super.key, required this.requestId});

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(signupRequestRepositoryProvider).approve(requestId);
      ref.invalidate(signupRequestDetailProvider(requestId));
      ref.invalidate(signupRequestsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject this request?'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Reason (optional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;

    try {
      await ref.read(signupRequestRepositoryProvider).reject(requestId, reason: reason.isEmpty ? null : reason);
      ref.invalidate(signupRequestDetailProvider(requestId));
      ref.invalidate(signupRequestsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Widget _row(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestAsync = ref.watch(signupRequestDetailProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Signup Request')),
      body: requestAsync.when(
        loading: () => const LoadingState(message: 'Loading request...'),
        error: (err, stack) => ErrorState(
          message: 'Failed to load request',
          onRetry: () => ref.invalidate(signupRequestDetailProvider(requestId)),
        ),
        data: (SignupRequest r) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.name, style: theme.textTheme.titleLarge),
                    const SizedBox(width: 12),
                    Chip(label: Text(r.status)),
                  ],
                ),
                const SizedBox(height: 16),
                _row('Role', r.role),
                _row('Zone', r.zoneName),
                _row('Reg No.', r.regNo),
                _row('Programme', r.programme),
                _row('Supervisor', r.supervisorName),
                _row('Workstation', r.workStationName),
                _row('Email', r.email),
                _row('Phone', r.phone),
                _row('Staff ID', r.staffId),
                if (r.status != 'pending') ...[
                  const Divider(height: 24),
                  _row('Reviewed By', r.reviewedBy),
                  _row('Reviewed At', r.reviewedAt?.toString()),
                  if (r.rejectionReason != null) _row('Reason', r.rejectionReason),
                ],
                const Spacer(),
                if (r.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _reject(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approve(context, ref),
                          style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor, foregroundColor: Colors.white),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
