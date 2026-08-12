import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared_models/route_run.dart';
import '../state/route_run_provider.dart';

class RoutePreviewScreen extends ConsumerWidget {
  const RoutePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stops = ref.watch(routeRunProvider).route?.stops ?? const <RouteStop>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview & Polyline'),
      ),
      body: Column(
        children: [
          // Polyline map preview mock container — HERE SDK rendering is out
          // of scope for this API-wiring pass.
          Container(
            height: 220,
            width: double.infinity,
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alt_route_rounded, size: 64, color: theme.primaryColor),
                  const SizedBox(height: 8),
                  const Text('HERE SDK Polyline Render Active', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Optimized Waypoints (${stops.length} Stops)', style: theme.textTheme.titleMedium),
                Chip(
                  label: const Text('Turn-by-Turn Ready'),
                  backgroundColor: theme.primaryColor.withOpacity(0.15),
                  labelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),

          Expanded(
            child: stops.isEmpty
                ? const Center(child: Text('No stops on this route.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stops.length,
                    itemBuilder: (context, idx) {
                      final stop = stops[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            child: Text('${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(stop.workstationName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Student: ${stop.name} (${stop.regNo})'),
                        ),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                // The route was already created by StartRouteSheet — this is
                // pure navigation, not another API call.
                onPressed: stops.isEmpty ? null : () => context.go('/route/active'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: isDark ? Colors.black87 : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.navigation_rounded),
                label: const Text('Start Active Turn-by-Turn Route', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
