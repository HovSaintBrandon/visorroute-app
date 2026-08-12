import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../map_dashboard/state/zone_students_provider.dart';
import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider((ref) => ReportsRepository(ref.watch(dioClientProvider).dio));

final zoneCoverageProvider = FutureProvider<ZoneCoverageReport>((ref) {
  final zoneId = ref.watch(selectedZoneIdProvider);
  return ref.watch(reportsRepositoryProvider).getZoneCoverage(zoneId);
});

final supervisorCompletionProvider = FutureProvider<SupervisorCompletionReport>((ref) {
  return ref.watch(reportsRepositoryProvider).getSupervisorCompletion();
});

final overdueReportProvider = FutureProvider<List<OverdueStudent>>((ref) {
  return ref.watch(reportsRepositoryProvider).getOverdue();
});

final timeToVisitProvider = FutureProvider<List<TimeToVisitEntry>>((ref) {
  final zoneId = ref.watch(selectedZoneIdProvider);
  return ref.watch(reportsRepositoryProvider).getTimeToVisit(zoneId);
});
