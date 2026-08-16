import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_models/import_row.dart';
import 'import_batch_provider.dart';

/// Re-fetches every time `importBatchProvider`'s state changes — that
/// provider already polls GET /imports/:id every 4s while status is
/// parsing/geocoding (see its `_pollUntilReady`), so watching it here is
/// what makes newly-resolved rows show up live on the review screen instead
/// of only once, whatever the row list looked like at first navigation.
final importReviewRowsProvider = FutureProvider.family<List<ImportRow>, String>((ref, batchId) {
  ref.watch(importBatchProvider);
  return ref.watch(importRepositoryProvider).getReviewRows(batchId);
});
