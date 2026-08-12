import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared_models/supervisor.dart';
import '../data/supervisor_repository.dart';

final supervisorRepositoryProvider = Provider<SupervisorRepository>((ref) {
  return SupervisorRepository(ref.watch(dioClientProvider).dio);
});

final supervisorProfileProvider = FutureProvider<Supervisor>((ref) {
  return ref.watch(supervisorRepositoryProvider).getMe();
});

class SupervisorProfileUpdateState {
  final bool isSaving;
  final String? errorMessage;
  final String? emailFieldError;

  SupervisorProfileUpdateState({this.isSaving = false, this.errorMessage, this.emailFieldError});
}

class SupervisorProfileUpdateNotifier extends StateNotifier<SupervisorProfileUpdateState> {
  final SupervisorRepository _repository;
  final Ref _ref;

  SupervisorProfileUpdateNotifier(this._repository, this._ref) : super(SupervisorProfileUpdateState());

  Future<bool> save({String? phone, String? email}) async {
    state = SupervisorProfileUpdateState(isSaving: true);
    try {
      await _repository.updateMe(phone: phone, email: email);
      _ref.invalidate(supervisorProfileProvider);
      state = SupervisorProfileUpdateState();
      return true;
    } on ApiException catch (e) {
      state = SupervisorProfileUpdateState(
        errorMessage: e.statusCode == 409 ? null : e.message,
        emailFieldError: e.statusCode == 409 ? e.message : null,
      );
      return false;
    }
  }
}

final supervisorProfileUpdateProvider =
    StateNotifierProvider<SupervisorProfileUpdateNotifier, SupervisorProfileUpdateState>((ref) {
  return SupervisorProfileUpdateNotifier(ref.watch(supervisorRepositoryProvider), ref);
});
