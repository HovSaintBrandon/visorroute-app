import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import 'auth_provider.dart';

final zoneOptionsProvider = FutureProvider<List<ZoneOption>>((ref) {
  return ref.watch(authRepositoryProvider).getZones();
});

final supervisorOptionsProvider = FutureProvider<List<SupervisorOption>>((ref) {
  return ref.watch(authRepositoryProvider).getSupervisors();
});

class SignupState {
  final bool isSubmitting;
  final String? errorMessage;
  final String? signupRequestId;

  SignupState({this.isSubmitting = false, this.errorMessage, this.signupRequestId});
}

class SignupNotifier extends StateNotifier<SignupState> {
  final AuthRepository _repository;

  SignupNotifier(this._repository) : super(SignupState());

  Future<bool> submitStudent({
    required String name,
    required String regNo,
    required String programme,
    required String zoneId,
    required String supervisorId,
    required String password,
    required String workStationName,
  }) async {
    state = SignupState(isSubmitting: true);
    try {
      final result = await _repository.signupStudent(
        name: name,
        regNo: regNo,
        programme: programme,
        zoneId: zoneId,
        supervisorId: supervisorId,
        password: password,
        workStationName: workStationName,
      );
      state = SignupState(signupRequestId: result.signupRequestId);
      return true;
    } on ApiException catch (e) {
      state = SignupState(errorMessage: e.message);
      return false;
    }
  }

  Future<bool> submitSupervisor({
    required String name,
    required String email,
    required String phone,
    required String staffId,
    required String zoneId,
    required String password,
  }) async {
    state = SignupState(isSubmitting: true);
    try {
      final result = await _repository.signupSupervisor(
        name: name,
        email: email,
        phone: phone,
        staffId: staffId,
        zoneId: zoneId,
        password: password,
      );
      state = SignupState(signupRequestId: result.signupRequestId);
      return true;
    } on ApiException catch (e) {
      state = SignupState(errorMessage: e.message);
      return false;
    }
  }
}

final signupProvider = StateNotifierProvider<SignupNotifier, SignupState>((ref) {
  return SignupNotifier(ref.watch(authRepositoryProvider));
});
