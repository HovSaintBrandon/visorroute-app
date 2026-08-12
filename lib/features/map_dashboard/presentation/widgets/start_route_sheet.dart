import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../route_run/state/route_run_provider.dart';

/// The real API only needs a zone + a GPS start point (the server picks
/// every unvisited student in the zone itself) — the old two-button choice
/// ("GPS" vs "Optimize") was cosmetic; there's only one real action now.
class StartRouteSheet extends ConsumerStatefulWidget {
  final String zoneId;

  const StartRouteSheet({super.key, required this.zoneId});

  @override
  ConsumerState<StartRouteSheet> createState() => _StartRouteSheetState();
}

class _StartRouteSheetState extends ConsumerState<StartRouteSheet> {
  bool _isStarting = false;

  Future<void> _start() async {
    setState(() => _isStarting = true);
    final success = await ref.read(routeRunProvider.notifier).startRoute(widget.zoneId);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      context.push('/route/preview');
      return;
    }

    setState(() => _isStarting = false);
    final error = ref.read(routeRunProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Failed to start route.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_isStarting,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Start Route Supervision', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Optimizes the visiting order for every unvisited workstation in this zone, starting from your current location. This can take a few seconds.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isStarting ? null : _start,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: isDark ? Colors.black87 : Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isStarting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _isStarting ? 'Optimizing route...' : 'Use Current Location & Start Route',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
