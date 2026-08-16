import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../shared_models/import_row.dart';
import '../state/import_batch_provider.dart';
import '../state/import_review_provider.dart';
import 'widgets/manual_pin_picker.dart';

class ImportReviewScreen extends ConsumerWidget {
  final String batchId;

  const ImportReviewScreen({super.key, required this.batchId});

  Future<void> _openPinPicker(BuildContext context, WidgetRef ref, ImportRow row) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ManualPinPicker(row: row),
    );
    if (result == null) return;

    try {
      await ref.read(importRepositoryProvider).correctRow(
            batchId,
            row.id,
            lat: result['lat'] as double?,
            lng: result['lng'] as double?,
            address: result['address'] as String?,
          );
      ref.invalidate(importReviewRowsProvider(batchId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _commit(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref.read(importRepositoryProvider).commitBatch(batchId);
      if (!context.mounted) return;
      if (result.rowErrors.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Committed with row errors'),
            content: Text(result.rowErrors.map((e) => 'Row ${e['rowNumber']}: ${e['message']}').join('\n')),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
      }
      if (context.mounted) context.go('/map');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commit failed: $e')));
      }
    }
  }

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this batch?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(importRepositoryProvider).discardBatch(batchId);
      if (context.mounted) context.go('/import/history');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Discard failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rowsAsync = ref.watch(importReviewRowsProvider(batchId));
    final batch = ref.watch(importBatchProvider).batch;
    final stillProcessing = batch?.status == 'parsing' || batch?.status == 'geocoding';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Import Batch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Discard batch',
            onPressed: () => _discard(context, ref),
          ),
        ],
      ),
      body: rowsAsync.when(
        loading: () => const LoadingState(message: 'Loading rows for review...'),
        error: (err, stack) => ErrorState(
          message: 'Failed to load rows',
          onRetry: () => ref.invalidate(importReviewRowsProvider(batchId)),
        ),
        data: (rows) {
          final needsReview = rows.where((r) => r.status == 'needs_review').toList();
          final bannerColor = stillProcessing ? Colors.blue : Colors.amber;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bannerColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bannerColor.shade700),
                  ),
                  child: Row(
                    children: [
                      if (stillProcessing)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      else
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stillProcessing
                              ? 'Still processing — ${rows.length} of ${batch?.rowCount ?? rows.length} rows resolved so far. This updates automatically.'
                              : '${rows.length - needsReview.length} of ${rows.length} rows ready. ${needsReview.length} need manual review.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: needsReview.isEmpty
                      ? const Center(child: Text('All rows resolved — ready to commit.'))
                      : ListView.builder(
                          itemCount: needsReview.length,
                          itemBuilder: (context, idx) {
                            final row = needsReview[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Row #${row.rowNumber} • ${row.parsed.studentName ?? 'Unknown'}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        Chip(
                                          label: const Text('Needs Review'),
                                          backgroundColor: Colors.amber.withOpacity(0.2),
                                          labelStyle: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${row.parsed.regNo ?? '—'} — ${row.errorMessage ?? row.supervisorResolutionNote ?? 'Needs zone/supervisor/location review'}',
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: () => _openPinPicker(context, ref, row),
                                      icon: const Icon(Icons.pin_drop_outlined),
                                      label: const Text('Resolve Location'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    // Gated on !stillProcessing too, not just the currently-fetched
                    // rows having zero needs_review — while the batch is still
                    // resolving, "zero needs_review so far" can just mean later
                    // rows haven't been reached yet, not that the batch is clean.
                    onPressed: (needsReview.isEmpty && !stillProcessing) ? () => _commit(context, ref) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Commit Batch to Zone Map', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
