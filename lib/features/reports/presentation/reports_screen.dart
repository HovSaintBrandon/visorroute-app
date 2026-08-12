import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../../../core/widgets/loading_state.dart';
import '../state/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _exportReport(BuildContext context, WidgetRef ref, String type, String format) async {
    try {
      final bytes = await ref.read(reportsRepositoryProvider).exportReport(type, format);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$type.$format');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Widget _exportButton(BuildContext context, WidgetRef ref, String type) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.ios_share_rounded, size: 20),
      tooltip: 'Export',
      onSelected: (format) => _exportReport(context, ref, type, format),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'csv', child: Text('Export CSV')),
        PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
      ],
    );
  }

  Widget _sectionCard(ThemeData theme, {required String title, required Widget child, Widget? exportButton}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (exportButton != null) exportButton,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final zoneCoverageAsync = ref.watch(zoneCoverageProvider);
    final supervisorCompletionAsync = ref.watch(supervisorCompletionProvider);
    final overdueAsync = ref.watch(overdueReportProvider);
    final timeToVisitAsync = ref.watch(timeToVisitProvider);

    final navItems = [
      const NavItem(activeIcon: Icons.map, inactiveIcon: Icons.map_outlined, label: 'Zone Map', route: '/map'),
      const NavItem(activeIcon: Icons.file_upload, inactiveIcon: Icons.file_upload_outlined, label: 'Excel Import', route: '/import/history'),
      const NavItem(activeIcon: Icons.bar_chart, inactiveIcon: Icons.bar_chart_outlined, label: 'Reports', route: '/reports'),
      const NavItem(activeIcon: Icons.notifications, inactiveIcon: Icons.notifications_outlined, label: 'Alerts', route: '/notifications'),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/map');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supervision Analytics & Reports'),
        ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(zoneCoverageProvider);
              ref.invalidate(supervisorCompletionProvider);
              ref.invalidate(overdueReportProvider);
              ref.invalidate(timeToVisitProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionCard(
                    theme,
                    title: 'Zone Coverage',
                    exportButton: _exportButton(context, ref, 'zone-coverage'),
                    child: zoneCoverageAsync.when(
                      loading: () => const LoadingState(),
                      error: (err, stack) => Text('Failed to load: $err'),
                      data: (report) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Visited'),
                              Text(
                                '${report.visitedPercent.toStringAsFixed(1)}%',
                                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: report.visitedPercent / 100,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                            color: theme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${report.visited} of ${report.totalStudents} visited • ${report.assessed} assessed (${report.assessedPercent.toStringAsFixed(1)}%)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    theme,
                    title: 'My Completion',
                    exportButton: _exportButton(context, ref, 'supervisor-completion'),
                    child: supervisorCompletionAsync.when(
                      loading: () => const LoadingState(),
                      error: (err, stack) => Text('Failed to load: $err'),
                      data: (report) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${report.visited} of ${report.totalStudents} visited (${report.visitedPercent.toStringAsFixed(1)}%)'),
                          Text('${report.assessed} assessed (${report.assessedPercent.toStringAsFixed(1)}%)'),
                          Text('${report.visitsInRange} visits logged'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    theme,
                    title: 'Time to First Visit',
                    exportButton: _exportButton(context, ref, 'time-to-visit'),
                    child: timeToVisitAsync.when(
                      loading: () => const LoadingState(),
                      error: (err, stack) => Text('Failed to load: $err'),
                      data: (entries) => entries.isEmpty
                          ? const Text('No students in this zone.')
                          : Column(
                              children: entries
                                  .map((e) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(e.regNo),
                                        trailing: Text(
                                          e.daysToFirstVisit == null ? 'Not yet visited' : '${e.daysToFirstVisit} days',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: e.daysToFirstVisit == null ? Colors.grey : theme.primaryColor,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Overdue Workstation Visits', style: theme.textTheme.titleLarge),
                      _exportButton(context, ref, 'overdue'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  overdueAsync.when(
                    loading: () => const LoadingState(),
                    error: (err, stack) => Text('Failed to load: $err'),
                    data: (items) => items.isEmpty
                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No overdue students.'))
                        : Column(
                            children: items
                                .map((item) => Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      child: ListTile(
                                        leading: const CircleAvatar(
                                          backgroundColor: Color(0xFFFEE2E2),
                                          child: Icon(Icons.priority_high_rounded, color: Colors.red),
                                        ),
                                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text('${item.regNo} • ${item.zoneName ?? 'Unknown zone'} • ${item.supervisorName ?? 'Unassigned'}'),
                                        trailing: ElevatedButton(
                                          onPressed: () => context.go('/map'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: theme.primaryColor,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Visit Now', style: TextStyle(fontSize: 12)),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomNavBar(
              currentIndex: 2,
              onTap: (index) {
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
    ));
  }
}
