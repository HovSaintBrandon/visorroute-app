import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared_models/import_batch.dart';
import 'import_batch_provider.dart';

final importHistoryProvider = FutureProvider<List<ImportBatch>>((ref) {
  return ref.watch(importRepositoryProvider).listImports();
});
