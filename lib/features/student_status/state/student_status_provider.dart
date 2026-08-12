import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared_models/student.dart';
import '../data/student_status_repository.dart';

final studentStatusRepoProvider = Provider((ref) => StudentStatusRepository(ref.watch(dioClientProvider).dio));

final studentStatusProvider = FutureProvider<Student>((ref) async {
  final repo = ref.watch(studentStatusRepoProvider);
  return repo.getMyStatus();
});

final queueStatusProvider = FutureProvider<QueueStatus>((ref) {
  return ref.watch(studentStatusRepoProvider).getQueueStatus();
});

class StudentProfileUpdateState {
  final bool isSaving;
  final String? errorMessage;

  StudentProfileUpdateState({this.isSaving = false, this.errorMessage});
}

class StudentProfileUpdateNotifier extends StateNotifier<StudentProfileUpdateState> {
  final StudentStatusRepository _repository;
  final Ref _ref;

  StudentProfileUpdateNotifier(this._repository, this._ref) : super(StudentProfileUpdateState());

  Future<bool> updatePhone(String phone) async {
    state = StudentProfileUpdateState(isSaving: true);
    try {
      await _repository.updateMe(phone: phone);
      _ref.invalidate(studentStatusProvider);
      state = StudentProfileUpdateState();
      return true;
    } on ApiException catch (e) {
      state = StudentProfileUpdateState(errorMessage: e.message);
      return false;
    }
  }
}

final studentProfileUpdateProvider = StateNotifierProvider<StudentProfileUpdateNotifier, StudentProfileUpdateState>((ref) {
  return StudentProfileUpdateNotifier(ref.watch(studentStatusRepoProvider), ref);
});
