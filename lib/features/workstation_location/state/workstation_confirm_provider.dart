import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../student_status/state/student_status_provider.dart';
import '../data/workstation_repository.dart';

final workstationRepoProvider = Provider((ref) => WorkstationRepository(ref.watch(dioClientProvider).dio));

class WorkstationSearchState {
  final bool isSearching;
  final List<WorkStationSearchResult> results;
  final String? errorMessage;

  WorkstationSearchState({this.isSearching = false, this.results = const [], this.errorMessage});
}

class WorkstationSearchNotifier extends StateNotifier<WorkstationSearchState> {
  final WorkstationRepository _repository;

  WorkstationSearchNotifier(this._repository) : super(WorkstationSearchState());

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = WorkstationSearchState();
      return;
    }
    state = WorkstationSearchState(isSearching: true, results: state.results);
    try {
      final results = await _repository.search(query);
      state = WorkstationSearchState(results: results);
    } on ApiException catch (e) {
      state = WorkstationSearchState(errorMessage: e.message);
    }
  }

  void clear() => state = WorkstationSearchState();
}

final workstationSearchProvider = StateNotifierProvider<WorkstationSearchNotifier, WorkstationSearchState>((ref) {
  return WorkstationSearchNotifier(ref.watch(workstationRepoProvider));
});

class WorkstationConfirmState {
  final bool isSaving;
  final String? errorMessage;

  WorkstationConfirmState({this.isSaving = false, this.errorMessage});
}

class WorkstationConfirmNotifier extends StateNotifier<WorkstationConfirmState> {
  final WorkstationRepository _repository;
  final Ref _ref;

  WorkstationConfirmNotifier(this._repository, this._ref) : super(WorkstationConfirmState());

  Future<bool> confirmLocation({required double lat, required double lng, String? address}) async {
    state = WorkstationConfirmState(isSaving: true);
    try {
      await _repository.confirmLocation(lat: lat, lng: lng, address: address);
      _ref.invalidate(studentStatusProvider);
      state = WorkstationConfirmState();
      return true;
    } on ApiException catch (e) {
      state = WorkstationConfirmState(errorMessage: e.message);
      return false;
    }
  }
}

final workstationConfirmProvider = StateNotifierProvider<WorkstationConfirmNotifier, WorkstationConfirmState>((ref) {
  return WorkstationConfirmNotifier(ref.watch(workstationRepoProvider), ref);
});
