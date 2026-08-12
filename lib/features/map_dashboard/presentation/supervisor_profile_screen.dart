import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/loading_state.dart';
import '../state/supervisor_profile_provider.dart';

class SupervisorProfileScreen extends ConsumerStatefulWidget {
  const SupervisorProfileScreen({super.key});

  @override
  ConsumerState<SupervisorProfileScreen> createState() => _SupervisorProfileScreenState();
}

class _SupervisorProfileScreenState extends ConsumerState<SupervisorProfileScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    if (phone.isEmpty && email.isEmpty) return;

    final success = await ref.read(supervisorProfileUpdateProvider.notifier).save(
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(supervisorProfileProvider);
    final updateState = ref.watch(supervisorProfileUpdateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileAsync.when(
        loading: () => const LoadingState(message: 'Loading profile...'),
        error: (err, stack) => ErrorState(
          message: 'Failed to load profile',
          onRetry: () => ref.invalidate(supervisorProfileProvider),
        ),
        data: (supervisor) {
          if (!_prefilled) {
            _phoneController.text = supervisor.phone;
            _emailController.text = supervisor.email;
            _prefilled = true;
          }
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.primaryColor.withOpacity(0.15),
                      child: Icon(Icons.badge_outlined, size: 28, color: theme.primaryColor),
                    ),
                    const SizedBox(width: 14),
                    Text(supervisor.name, style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: updateState.emailFieldError,
                  ),
                ),
                if (updateState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(updateState.errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: updateState.isSaving ? null : _save,
                    child: updateState.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
