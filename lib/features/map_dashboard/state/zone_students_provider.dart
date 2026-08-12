import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared_models/student.dart';
import '../data/student_repository.dart';

final studentRepositoryProvider = Provider((ref) => StudentRepository(ref.watch(dioClientProvider).dio));

final selectedZoneIdProvider = StateProvider<String>((ref) => 'zone_juja_main');

final zoneStudentsProvider = FutureProvider<List<Student>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final zoneId = ref.watch(selectedZoneIdProvider);
  return repo.getZoneStudents(zoneId);
});
