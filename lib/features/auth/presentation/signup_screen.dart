import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../state/signup_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  UserRole _role = UserRole.student;
  String? _zoneId;
  String? _supervisorId;

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Student-only
  final _regNoController = TextEditingController();
  final _programmeController = TextEditingController();
  final _workStationController = TextEditingController();

  // Supervisor-only
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _staffIdController = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _regNoController.dispose();
    _programmeController.dispose();
    _workStationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_nameController.text.trim().isEmpty || _zoneId == null) {
      setState(() => _errorMessage = 'Please fill in your name and pick a zone.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    bool success;
    if (_role == UserRole.student) {
      if (_supervisorId == null || _regNoController.text.trim().isEmpty || _workStationController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please fill in reg no, supervisor, and workstation.');
        return;
      }
      success = await ref.read(signupProvider.notifier).submitStudent(
            name: _nameController.text.trim(),
            regNo: _regNoController.text.trim(),
            programme: _programmeController.text.trim(),
            zoneId: _zoneId!,
            supervisorId: _supervisorId!,
            password: _passwordController.text,
            workStationName: _workStationController.text.trim(),
          );
    } else {
      if (_emailController.text.trim().isEmpty || _staffIdController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please fill in email and staff ID.');
        return;
      }
      success = await ref.read(signupProvider.notifier).submitSupervisor(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            staffId: _staffIdController.text.trim(),
            zoneId: _zoneId!,
            password: _passwordController.text,
          );
    }

    if (!mounted) return;
    if (success) {
      final requestId = ref.read(signupProvider).signupRequestId;
      context.go('/signup/pending', extra: requestId);
    } else {
      setState(() => _errorMessage = ref.read(signupProvider).errorMessage ?? 'Signup failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final signupState = ref.watch(signupProvider);
    final zonesAsync = ref.watch(zoneOptionsProvider);
    final supervisorsAsync = ref.watch(supervisorOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Role Toggle Pills
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.canvasColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = UserRole.student),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _role == UserRole.student ? theme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Student',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _role == UserRole.student ? (isDark ? Colors.black87 : Colors.white) : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = UserRole.supervisor),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _role == UserRole.supervisor ? theme.primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Supervisor',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _role == UserRole.supervisor ? (isDark ? Colors.black87 : Colors.white) : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 14),

              // Zone dropdown — common to both roles
              zonesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => Text('Failed to load zones: $err', style: TextStyle(color: theme.colorScheme.error)),
                data: (zones) => DropdownButtonFormField<String>(
                  initialValue: _zoneId,
                  decoration: const InputDecoration(labelText: 'Zone', prefixIcon: Icon(Icons.map_outlined)),
                  items: zones.map((z) => DropdownMenuItem(value: z.id, child: Text(z.name))).toList(),
                  onChanged: (val) => setState(() {
                    _zoneId = val;
                    _supervisorId = null;
                  }),
                ),
              ),
              const SizedBox(height: 14),

              if (_role == UserRole.student) ...[
                TextField(
                  controller: _regNoController,
                  decoration: const InputDecoration(labelText: 'Reg No.', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _programmeController,
                  decoration: const InputDecoration(labelText: 'Programme', prefixIcon: Icon(Icons.school_outlined)),
                ),
                const SizedBox(height: 14),
                supervisorsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (err, stack) => Text('Failed to load supervisors: $err', style: TextStyle(color: theme.colorScheme.error)),
                  data: (supervisors) {
                    final filtered = _zoneId == null ? <SupervisorOption>[] : supervisors.where((s) => s.zoneId == _zoneId).toList();
                    return DropdownButtonFormField<String>(
                      initialValue: _supervisorId,
                      decoration: InputDecoration(
                        labelText: 'Supervisor',
                        prefixIcon: const Icon(Icons.supervisor_account_outlined),
                        helperText: _zoneId == null ? 'Pick a zone first' : null,
                      ),
                      items: filtered.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: _zoneId == null ? null : (val) => setState(() => _supervisorId = val),
                    );
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _workStationController,
                  decoration: const InputDecoration(labelText: 'Workstation Name', prefixIcon: Icon(Icons.business_outlined)),
                ),
              ] else ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _staffIdController,
                  decoration: const InputDecoration(labelText: 'Staff ID', prefixIcon: Icon(Icons.badge_outlined)),
                ),
              ],
              const SizedBox(height: 14),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (min. 6 characters)', prefixIcon: Icon(Icons.lock_outline)),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
              ],
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: signupState.isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: isDark ? Colors.black87 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: signupState.isSubmitting
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Submit for Approval', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
