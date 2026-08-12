import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_models/import_row.dart';
import 'import_batch_provider.dart';

final importReviewRowsProvider = FutureProvider.family<List<ImportRow>, String>((ref, batchId) {
  return ref.watch(importRepositoryProvider).getReviewRows(batchId);
});
