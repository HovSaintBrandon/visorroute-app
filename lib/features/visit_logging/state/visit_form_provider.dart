import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../data/visit_repository.dart';

final visitRepositoryProvider = Provider((ref) => VisitRepository(ref.watch(dioClientProvider).dio));

class VisitFormState {
  final bool isSubmitting;
  final bool isUploadingPhoto;
  final String? loggedVisitId;
  final String? errorMessage;
  final String? photoErrorMessage;

  VisitFormState({
    this.isSubmitting = false,
    this.isUploadingPhoto = false,
    this.loggedVisitId,
    this.errorMessage,
    this.photoErrorMessage,
  });
}

class VisitFormNotifier extends StateNotifier<VisitFormState> {
  final VisitRepository _repository;

  VisitFormNotifier(this._repository) : super(VisitFormState());

  /// Step one of two — logs the visit and returns its id. The photo (if
  /// any) is a separate follow-up call via [uploadPhoto]; its failure
  /// shouldn't roll back or re-block this already-saved visit.
  Future<bool> submitVisit({
    required String studentId,
    required String type,
    String outcome = '',
    double? score,
    String notes = '',
    required double supervisorLat,
    required double supervisorLng,
  }) async {
    state = VisitFormState(isSubmitting: true);
    try {
      final visit = await _repository.createVisit(
        studentId: studentId,
        type: type,
        outcome: outcome,
        score: score,
        notes: notes,
        supervisorLat: supervisorLat,
        supervisorLng: supervisorLng,
      );
      state = VisitFormState(loggedVisitId: visit.id);
      return true;
    } catch (e) {
      state = VisitFormState(errorMessage: e is ApiException ? e.message : 'Failed to log visit. Please try again.');
      return false;
    }
  }

  /// Independently retryable — a failed upload leaves [loggedVisitId] intact
  /// so the caller can call this again without re-logging the visit.
  Future<bool> uploadPhoto(String filePath) async {
    final visitId = state.loggedVisitId;
    if (visitId == null) return false;
    state = VisitFormState(loggedVisitId: visitId, isUploadingPhoto: true);
    try {
      await _repository.attachPhoto(visitId, filePath);
      state = VisitFormState(loggedVisitId: visitId);
      return true;
    } catch (e) {
      state = VisitFormState(
        loggedVisitId: visitId,
        photoErrorMessage: e is ApiException ? e.message : 'Failed to upload photo. You can retry.',
      );
      return false;
    }
  }

  void reset() => state = VisitFormState();
}

final visitFormProvider = StateNotifierProvider<VisitFormNotifier, VisitFormState>((ref) {
  return VisitFormNotifier(ref.watch(visitRepositoryProvider));
});
