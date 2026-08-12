import 'package:flutter/material.dart';
import '../../../../shared_models/import_row.dart';

/// No map SDK is wired into this app (see `frontend.md`'s HERE SDK note) —
/// this is a lat/lng + address entry form standing in for the "drag a pin"
/// interaction the mapping doc describes, without fabricating a fake
/// draggable map that isn't actually backed by a real map widget.
class ManualPinPicker extends StatefulWidget {
  final ImportRow row;

  const ManualPinPicker({super.key, required this.row});

  @override
  State<ManualPinPicker> createState() => _ManualPinPickerState();
}

class _ManualPinPickerState extends State<ManualPinPicker> {
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController(text: widget.row.geocodeResult?.lat?.toString() ?? '');
    _lngController = TextEditingController(text: widget.row.geocodeResult?.lng?.toString() ?? '');
    _addressController = TextEditingController(
      text: widget.row.geocodeResult?.formattedAddress ?? widget.row.parsed.attachmentStationRaw ?? '',
    );
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude and longitude.')),
      );
      return;
    }
    Navigator.pop(context, {
      'lat': lat,
      'lng': lng,
      'address': _addressController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set Workstation Location', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Row #${widget.row.rowNumber} • ${widget.row.parsed.studentName ?? 'Unknown student'}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Location', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
