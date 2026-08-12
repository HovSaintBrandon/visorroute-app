import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../shared_models/import_batch.dart';
import '../data/import_repository.dart';

final importRepositoryProvider = Provider((ref) => ImportRepository(ref.watch(dioClientProvider).dio));

class ImportUploadState {
  final bool isUploading;
  final ImportBatch? batch;
  final String? errorMessage;

  ImportUploadState({this.isUploading = false, this.batch, this.errorMessage});
}

class ImportBatchNotifier extends StateNotifier<ImportUploadState> {
  final ImportRepository _repository;
  Timer? _pollTimer;

  ImportBatchNotifier(this._repository) : super(ImportUploadState());

  Future<String?> startUpload({required String filePath, required String scope, String? zoneId}) async {
    state = ImportUploadState(isUploading: true);
    try {
      final result = await _repository.uploadExcelFile(filePath: filePath, scope: scope, zoneId: zoneId);
      final batch = await _repository.getBatchStatus(result.importBatchId);
      state = ImportUploadState(batch: batch);
      _pollUntilReady(result.importBatchId);
      return result.importBatchId;
    } catch (e) {
      state = ImportUploadState(errorMessage: e is ApiException ? e.message : 'Upload failed. Please try again.');
      return null;
    }
  }

  /// Polls while the batch is still parsing/geocoding, stopping once it
  /// resolves to needs_review/committed/failed.
  void _pollUntilReady(String batchId) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final batch = await _repository.getBatchStatus(batchId);
        state = ImportUploadState(batch: batch);
        if (batch.status != 'parsing' && batch.status != 'geocoding') {
          timer.cancel();
        }
      } catch (_) {
        // Transient network hiccup — keep polling until it resolves.
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final importBatchProvider = StateNotifierProvider<ImportBatchNotifier, ImportUploadState>((ref) {
  return ImportBatchNotifier(ref.watch(importRepositoryProvider));
});
