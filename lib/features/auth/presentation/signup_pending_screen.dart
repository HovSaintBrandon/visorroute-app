import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// There is deliberately no status-polling endpoint — checking status *is*
/// attempting to log in. This screen never auto-refreshes; it just sets
/// expectations and points back to the login screen.
class SignupPendingScreen extends StatelessWidget {
  final String? signupRequestId;

  const SignupPendingScreen({super.key, this.signupRequestId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 64, color: theme.primaryColor),
              const SizedBox(height: 20),
              Text('Request Submitted', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                "Your request has been submitted for admin approval. Try logging in once you've been notified — there's no status page to check in the meantime.",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (signupRequestId != null && signupRequestId!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Reference: $signupRequestId',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
