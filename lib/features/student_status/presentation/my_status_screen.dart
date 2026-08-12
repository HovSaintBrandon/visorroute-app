import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../../../core/widgets/loading_state.dart';
import '../../auth/state/auth_provider.dart';
import '../state/student_status_provider.dart';

class MyStatusScreen extends ConsumerWidget {
  const MyStatusScreen({super.key});

  Future<void> _editPhone(BuildContext context, WidgetRef ref, String currentPhone) async {
    final controller = TextEditingController(text: currentPhone);
    final newPhone = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Phone'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (newPhone == null || newPhone.isEmpty || !context.mounted) return;

    final success = await ref.read(studentProfileUpdateProvider.notifier).updatePhone(newPhone);
    if (!success && context.mounted) {
      final error = ref.read(studentProfileUpdateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Failed to update phone.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusAsync = ref.watch(studentStatusProvider);

    final navItems = [
      const NavItem(activeIcon: Icons.person_pin_circle, inactiveIcon: Icons.person_pin_circle_outlined, label: 'My Status', route: '/student/status'),
      const NavItem(activeIcon: Icons.access_time_filled, inactiveIcon: Icons.access_time, label: 'Queue Pos', route: '/student/queue'),
      const NavItem(activeIcon: Icons.notifications, inactiveIcon: Icons.notifications_outlined, label: 'Notifications', route: '/notifications'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Workstation Supervision'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          )
        ],
      ),
      body: Stack(
        children: [
          statusAsync.when(
            loading: () => const LoadingState(message: 'Fetching supervisor route position...'),
            error: (err, stack) => ErrorState(message: 'Failed to fetch status'),
            data: (student) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Main Status Card with VenueHub rounded card aesthetic & logo watermark
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                            blurRadius: 20,
                          ),
                        ],
                        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: theme.primaryColor.withOpacity(0.15),
                            child: Icon(Icons.school_rounded, size: 40, color: theme.primaryColor),
                          ),
                          const SizedBox(height: 12),
                          Text(student.fullName, style: theme.textTheme.titleLarge),
                          Text(student.regNo, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Station: ${student.workstationName}',
                              style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Phone — the only editable field on this endpoint.
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: Consumer(
                        builder: (context, ref, _) {
                          final updateState = ref.watch(studentProfileUpdateProvider);
                          return ListTile(
                            leading: Icon(Icons.phone_outlined, color: theme.primaryColor),
                            title: const Text('Phone'),
                            subtitle: Text(student.phone.isEmpty ? 'Not set' : student.phone),
                            trailing: updateState.isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _editPhone(context, ref, student.phone),
                                  ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Live queue position and ETA are on the Queue Pos tab.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),

          // Custom Floating Pill Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: 0,
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
    );
  }
}
