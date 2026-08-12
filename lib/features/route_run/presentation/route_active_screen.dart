import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../visit_logging/presentation/visit_logging_sheet.dart';
import '../state/route_run_provider.dart';

class RouteActiveScreen extends ConsumerWidget {
  const RouteActiveScreen({super.key});

  Future<void> _confirmAbandon(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Route?'),
        content: const Text('This marks the route as abandoned. Any remaining stops will be left unvisited.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End Route')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(routeRunProvider.notifier).abandonRoute();
      if (context.mounted) context.go('/map');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to end route: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final route = ref.watch(routeRunProvider).route;
    final stops = route?.stops ?? const [];

    if (route == null || stops.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Turn-by-Turn Guidance')),
        body: const Center(child: Text('No active route. Start one from the zone map.')),
      );
    }

    final currentStopIndex = route.currentIndex;
    final currentStop = currentStopIndex < stops.length ? stops[currentStopIndex] : stops.last;
    final nextStop = (currentStopIndex + 1) < stops.length ? stops[currentStopIndex + 1] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Turn-by-Turn Guidance'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text('GPS Active', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Active Guidance Banner — turn-by-turn text is a HERE SDK
          // navigation concern, out of scope for this API-wiring pass.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: theme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.turn_right_rounded, color: Colors.white, size: 36),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Head to the next workstation', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: (currentStopIndex + 1) / stops.length,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Target Stop Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(
                          label: Text('Current Stop #${currentStopIndex + 1} of ${stops.length}'),
                          backgroundColor: theme.primaryColor.withOpacity(0.15),
                          labelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(currentStop.workstationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Student: ${currentStop.name} (${currentStop.regNo})', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Next Stop Indicator
                if (nextStop != null)
                  Card(
                    color: theme.canvasColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                      title: Text('Next Up: ${nextStop.workstationName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text('Student: ${nextStop.name}', style: const TextStyle(fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/map'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Exit Map'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmAbandon(context, ref),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End Route'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => VisitLoggingSheet(
                          studentId: currentStop.studentId,
                          studentName: currentStop.name,
                          workstationName: currentStop.workstationName,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: isDark ? Colors.black87 : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Log Visit / Assess', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
