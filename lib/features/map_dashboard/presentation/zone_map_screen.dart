import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/loading_state.dart';
import '../../auth/state/auth_provider.dart';
import '../state/zone_students_provider.dart';
import 'widgets/student_pin.dart';
import 'widgets/zone_legend.dart';
import 'widgets/start_route_sheet.dart';

class ZoneMapScreen extends ConsumerStatefulWidget {
  const ZoneMapScreen({super.key});

  @override
  ConsumerState<ZoneMapScreen> createState() => _ZoneMapScreenState();
}

class _ZoneMapScreenState extends ConsumerState<ZoneMapScreen> {
  int _navIndex = 0;
  bool _isMapView = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final studentsAsync = ref.watch(zoneStudentsProvider);

    final navItems = [
      const NavItem(activeIcon: Icons.map, inactiveIcon: Icons.map_outlined, label: 'Zone Map', route: '/map'),
      const NavItem(activeIcon: Icons.file_upload, inactiveIcon: Icons.file_upload_outlined, label: 'Excel Import', route: '/import/history'),
      const NavItem(activeIcon: Icons.bar_chart, inactiveIcon: Icons.bar_chart_outlined, label: 'Reports', route: '/reports'),
      const NavItem(activeIcon: Icons.notifications, inactiveIcon: Icons.notifications_outlined, label: 'Alerts', route: '/notifications'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.near_me_rounded, color: Color(0xFF1E8F4B)),
            SizedBox(width: 8),
            Text('Juja Zone Supervision'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.format_list_bulleted : Icons.map_rounded),
            onPressed: () => setState(() => _isMapView = !_isMapView),
            tooltip: _isMapView ? 'Switch to List' : 'Switch to Map',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'My Profile',
            onPressed: () => context.push('/supervisor/profile'),
          ),
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
      body: Stack(
        children: [
          studentsAsync.when(
            loading: () => const LoadingState(message: 'Fetching zone workstation pins...'),
            error: (err, stack) => ErrorState(
              message: 'Failed to load workstation data',
              onRetry: () => ref.invalidate(zoneStudentsProvider),
            ),
            data: (students) {
              if (!_isMapView) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: students.length,
                  itemBuilder: (context, idx) {
                    final student = students[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.15),
                          child: Text('#${idx + 1}', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${student.regNo}\n${student.workstationName}'),
                        trailing: StatusBadge(status: student.status),
                      ),
                    );
                  },
                );
              }

              // Mock Map View Representation
              return Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                child: Stack(
                  children: [
                    // Grid / Map Background pattern
                    Center(
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(Icons.map_outlined, size: 280, color: theme.primaryColor),
                      ),
                    ),

                    // Positioned Student Pins
                    Positioned(
                      top: 120,
                      left: 60,
                      child: StudentPin(
                        student: students[0],
                        onTap: () => context.push('/route/active'),
                      ),
                    ),
                    Positioned(
                      top: 220,
                      right: 70,
                      child: StudentPin(
                        student: students[1],
                        onTap: () => context.push('/route/active'),
                      ),
                    ),
                    Positioned(
                      bottom: 240,
                      left: 100,
                      child: StudentPin(
                        student: students[2],
                        onTap: () => context.push('/route/active'),
                      ),
                    ),
                    Positioned(
                      bottom: 180,
                      right: 80,
                      child: StudentPin(
                        student: students[3],
                        onTap: () => context.push('/route/active'),
                      ),
                    ),

                    // Top Legend Bar
                    const Positioned(
                      top: 16,
                      left: 16,
                      child: ZoneLegend(),
                    ),
                  ],
                ),
              );
            },
          ),

          // Start Route Floating Action Pill Button
          Positioned(
            bottom: 95,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (_) => StartRouteSheet(zoneId: ref.read(selectedZoneIdProvider)),
                );
              },
              backgroundColor: theme.primaryColor,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Start Route', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          // VenueHub Custom Floating Pill Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: _navIndex,
              onTap: (index) {
                setState(() => _navIndex = index);
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
    );
  }
}
